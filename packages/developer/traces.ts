import type { BattleTraceCommand } from '../story/original-battle'
import bubbleRules from '../../content/stories/godot-bubble-rules.json'

type Key = string | number
export interface CommandTraceTarget {
  id: string
  label: string
  commands: BattleTraceCommand[]
  path: Key[]
  family: string
  metadata: string
}
const editable = new Set(['set_portrait', 'deck', 'background', 'band', 'narrator_band', 'bubble', 'wait',
  'set_bubble_side', 'set_battle_ui_visible', 'highlight', 'unhighlight', 'leave'])
const object = (value: unknown): value is Record<string, unknown> => !!value && typeof value === 'object' && !Array.isArray(value)

/** Enumerate actual command arrays, not arbitrary renderer-supplied JSON paths. */
export function commandTraceTargets(document: unknown): CommandTraceTarget[] {
  const targets: CommandTraceTarget[] = []
  function visit(value: unknown, path: Key[], parentLabel: string) {
    if (Array.isArray(value)) { value.forEach((child, index) => visit(child, [...path, index], parentLabel)); return }
    if (!object(value)) return
    const name = [value.opponent_name, value.method, value.scene, value.pick,
      Array.isArray(value.outcomes) ? value.outcomes.join('/') : undefined].filter(entry => entry !== undefined).join(' · ')
    const label = [parentLabel, name].filter(Boolean).join(' / ')
    for (const [key, child] of Object.entries(value)) {
      const childPath = [...path, key]
      if (Array.isArray(child) && child.length > 0 && child.every(command => object(command) && typeof command.kind === 'string' && Array.isArray(command.args))) {
        const branching = key === 'commands' && Array.isArray(value.outcomes)
        targets.push({ id: JSON.stringify(childPath), path: childPath, label: `${label || childPath.join('/')}: ${key}`,
          commands: child as BattleTraceCommand[], family: JSON.stringify(branching ? path.slice(0, -1) : childPath),
          metadata: branching ? JSON.stringify(Object.entries(value).filter(([key]) => !['commands', 'outcomes'].includes(key)).sort(([a], [b]) => a.localeCompare(b))) : '' })
      } else visit(child, childPath, label)
    }
  }
  visit(document, [], '')
  return targets
}

function shape(previous: unknown, replacement: unknown): boolean {
  if (previous === null) return replacement === null
  if (Array.isArray(previous)) return Array.isArray(replacement) && previous.length === replacement.length && previous.every((value, index) => shape(value, replacement[index]))
  if (object(previous)) return object(replacement) && Object.keys(previous).sort().join(',') === Object.keys(replacement).sort().join(',') &&
    Object.entries(previous).every(([key, value]) => shape(value, replacement[key]))
  return typeof previous === typeof replacement && (typeof replacement !== 'number' || Number.isFinite(replacement))
}

function validArgs(command: BattleTraceCommand, args: unknown[]) {
  if (command.kind !== 'bubble') return shape(command.args, args)
  if (!Array.isArray(args) || !object(args[1]) || !object(command.args[1])) return false
  const previous = structuredClone(command.args), options = previous[1] as Record<string, unknown>
  if (Object.hasOwn(args[1], 'font_size') && !Object.hasOwn(options, 'font_size')) options.font_size = 0
  const size = args[1].font_size
  return shape(previous, args) && Object.hasOwn(bubbleRules.anchors, String(args[1].side ?? 'center')) &&
    (size === undefined || typeof size === 'number' && Number.isSafeInteger(size) && size >= 0 && size <= 256)
}

/** Preserve the runtime trace candidate invariant before the next recorded janken branch. */
export function replaceTraceCommand<T>(document: T, targetId: string, index: number, args: unknown[]): { document: T; affected: number } {
  const replacement = structuredClone(document), targets = commandTraceTargets(replacement)
  const selected = targets.find(target => target.id === targetId)
  if (!selected || !Number.isSafeInteger(index) || index < 0 || index >= selected.commands.length) throw new Error('Unknown trace command')
  const command = selected.commands[index]
  if (!editable.has(command.kind) || !validArgs(command, args)) throw new Error('Invalid visual command edit')
  const prefix = JSON.stringify(selected.commands.slice(0, index)), original = JSON.stringify(command)
  let affected = 0
  for (const target of targets) {
    if (target.family !== selected.family || target.metadata !== selected.metadata ||
        JSON.stringify(target.commands.slice(0, index)) !== prefix || JSON.stringify(target.commands[index]) !== original) continue
    target.commands[index] = { ...target.commands[index], args: structuredClone(args) }
    affected++
  }
  if (!affected) throw new Error('Trace command not found')
  return { document: replacement, affected }
}
