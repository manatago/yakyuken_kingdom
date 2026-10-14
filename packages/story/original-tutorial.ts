import type { Card } from '../domain/card'
import { createOriginalJanken, resolveOriginalJanken, selectOriginalCard, type OriginalJanken } from '../battle/original-janken'
import { advanceOriginalBattleCommand, createOriginalBattlePlayback, nextOriginalBattleCommand, type OriginalBattlePlayback } from './original-battle'

type TutorialAction = { type: 'step'; roll: number } | { type: 'continue' } |
  { type: 'deck'; cards: Card[] } | { type: 'select'; index: number }
export interface OriginalTutorial {
  playback: OriginalBattlePlayback
  battle: OriginalJanken
  phase: 'running' | 'dialogue' | 'deck' | 'selection' | 'result' | 'reward'
  text: string
  portrait: string
  portraitOptions: Record<string, unknown>
  highlight: string
  gold: number
  actions: TutorialAction[]
}

export function createOriginalTutorial(): OriginalTutorial {
  return { playback: createOriginalBattlePlayback('tutorial'), battle: createOriginalJanken(), phase: 'running',
    text: '', portrait: '', portraitOptions: {}, highlight: '', gold: 0, actions: [] }
}

export function stepOriginalTutorial(state: OriginalTutorial, roll: number): OriginalTutorial {
  if (state.phase !== 'running') throw new Error('Original tutorial is waiting for input')
  const next = structuredClone(state)
  const command = nextOriginalBattleCommand(state.playback)
  next.actions.push({ type: 'step', roll })
  if (!command) { next.phase = 'reward'; next.gold = 10 + Math.floor(roll * 21); return next }
  const args = command.args
  let result
  switch (command.kind) {
    case 'set_portrait': next.portrait = String(args[1]); next.portraitOptions = structuredClone(args[2] as Record<string, unknown>); break
    case 'band': next.text = String(args[1]); next.phase = 'dialogue'; break
    case 'highlight': next.highlight = String(args[0]); break
    case 'unhighlight': next.highlight = ''; break
    case 'set_bubble_side': break // Character bands use the original StoryScene speaker slot.
    case 'build_deck': next.phase = 'deck'; return next
    case 'select_hand': next.phase = 'selection'; return next
    case 'janken':
      next.battle = resolveOriginalJanken(state.battle, args[1] as Parameters<typeof resolveOriginalJanken>[1], roll)
      result = next.battle.rounds.at(-1)!.result
      next.phase = 'result'
      break
    default: throw new Error(`Unsupported original tutorial command: ${command.kind}`)
  }
  next.playback = advanceOriginalBattleCommand(state.playback, result)
  return next
}

export function continueOriginalTutorial(state: OriginalTutorial): OriginalTutorial {
  if (!['dialogue', 'result'].includes(state.phase)) throw new Error('Original tutorial cannot continue here')
  return { ...structuredClone(state), phase: 'running', actions: [...structuredClone(state.actions), { type: 'continue' }] }
}

export function prepareOriginalTutorial(state: OriginalTutorial, cards: readonly Card[]): OriginalTutorial {
  if (state.phase !== 'deck') throw new Error('Original tutorial is not building a deck')
  return { ...structuredClone(state), battle: createOriginalJanken(cards), phase: 'running',
    playback: advanceOriginalBattleCommand(state.playback), actions: [...structuredClone(state.actions), { type: 'deck', cards: structuredClone([...cards]) }] }
}

export function chooseOriginalTutorialCard(state: OriginalTutorial, index: number): OriginalTutorial {
  if (state.phase !== 'selection') throw new Error('Original tutorial is not selecting a card')
  return { ...structuredClone(state), battle: selectOriginalCard(state.battle, index), phase: 'running',
    playback: advanceOriginalBattleCommand(state.playback), actions: [...structuredClone(state.actions), { type: 'select', index }] }
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

/** Re-execute persisted actions; reject a forged state instead of trusting its HP/results/cursor. */
export function restoreOriginalTutorial(value: unknown): OriginalTutorial {
  if (!value || typeof value !== 'object') throw new Error('Invalid original tutorial save')
  const actions = (value as OriginalTutorial).actions
  if (!Array.isArray(actions) || actions.length > 300) throw new Error('Invalid original tutorial actions')
  const state = replayOriginalTutorialActions(actions)
  if (canonical(state) !== canonical(value)) throw new Error('Original tutorial state does not match its action history')
  return state
}

function replayOriginalTutorialActions(actions: readonly TutorialAction[]) {
  let state = createOriginalTutorial()
  for (const action of actions) {
    if (!action || typeof action !== 'object') throw new Error('Invalid original tutorial action')
    switch (action.type) {
      case 'step':
        if (!Number.isFinite(action.roll) || action.roll < 0 || action.roll >= 1) throw new Error('Invalid original tutorial roll')
        state = stepOriginalTutorial(state, action.roll); break
      case 'continue': state = continueOriginalTutorial(state); break
      case 'deck': state = prepareOriginalTutorial(state, action.cards); break
      case 'select': state = chooseOriginalTutorialCard(state, action.index); break
      default: throw new Error('Unknown original tutorial action')
    }
  }
  return state
}

export function originalTutorialPreResultBattle(saved: OriginalTutorial) {
  if (saved.phase !== 'result' || saved.actions.at(-1)?.type !== 'step') throw new Error('Missing original result boundary')
  return replayOriginalTutorialActions(saved.actions.slice(0, -1)).battle
}
