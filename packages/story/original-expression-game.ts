import document from '../../content/stories/godot-stage2-minigame.json'
import type { CurseCommand } from './original-curse-game'

export const originalExpressionSource = document
interface ExpressionAction { pick: string; nextRoll: number }
export interface OriginalExpressionGame {
  initialRoll: number
  actions: ExpressionAction[]
  scene: number
  usedScenes: number[]
  gauge: number
  commands: CurseCommand[]
  outcome?: 'win' | 'lose'
}

function validRoll(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original expression roll')
}
function nextScene(used: readonly number[], roll: number) {
  validRoll(roll)
  const history = used.length === document.scenes.length ? [] : [...used]
  const available = document.scenes.map((_, index) => index).filter(index => !history.includes(index))
  const scene = available[Math.floor(roll * available.length)]
  return { scene, usedScenes: [...history, scene] }
}
export function createOriginalExpressionGame(roll: number): OriginalExpressionGame {
  const { scene, usedScenes } = nextScene([], roll)
  return { initialRoll: roll, actions: [], scene, usedScenes, gauge: document.gauge_start,
    commands: [...structuredClone(document.intro), ...structuredClone(document.questions[scene])] as CurseCommand[] }
}

export function chooseOriginalExpression(state: OriginalExpressionGame, pick: string, nextRoll: number): OriginalExpressionGame {
  if (state.outcome) throw new Error('Original expression game is complete')
  validRoll(nextRoll)
  if (pick === '_pisuke' && state.actions.length < document.pisuke_unlock_turn) throw new Error('Pisuke support is locked')
  const trace = document.traces.find(trace => trace.scene === state.scene && trace.pick === pick)
  if (!trace) throw new Error('Unknown original expression choice')
  const next = structuredClone(state)
  next.gauge = Math.max(0, Math.min(document.gauge_max, state.gauge + trace.delta))
  next.actions.push({ pick, nextRoll })
  next.commands = [...structuredClone(trace.commands) as CurseCommand[], { kind: 'gauge', args: [trace.delta, next.gauge] }]
  if (next.gauge === 0 || next.gauge === document.gauge_max) {
    next.outcome = next.gauge === 0 ? 'win' : 'lose'
    next.commands.push({ kind: 'dialogue_band', args: ['narrator', document.ending[next.outcome], true] })
    next.commands.push({ kind: 'wait', args: [0] }, { kind: 'hide_dialogue_band', args: [] }, { kind: 'wait', args: [0] })
  } else {
    Object.assign(next, nextScene(state.usedScenes, nextRoll))
    next.commands.push(...structuredClone(document.questions[next.scene]) as CurseCommand[])
  }
  return next
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}
export function restoreOriginalExpressionGame(value: unknown): OriginalExpressionGame {
  if (!value || typeof value !== 'object') throw new Error('Invalid original expression game')
  const saved = value as OriginalExpressionGame
  if (!Array.isArray(saved.actions) || saved.actions.length > 1000) throw new Error('Invalid original expression actions')
  let expected = createOriginalExpressionGame(saved.initialRoll)
  for (const action of saved.actions) expected = chooseOriginalExpression(expected, action.pick, action.nextRoll)
  if (canonical(expected) !== canonical(saved)) throw new Error('Original expression game does not match replay')
  return expected
}

export interface OriginalExpressionLedger { game: OriginalExpressionGame; cursor: number }
export function restoreOriginalExpressionLedger(value: unknown): OriginalExpressionLedger {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original expression ledger')
  const ledger = value as OriginalExpressionLedger
  if (Object.keys(ledger).some(key => key !== 'game' && key !== 'cursor')) throw new Error('Unknown original expression ledger field')
  const game = restoreOriginalExpressionGame(ledger.game)
  if (!Number.isSafeInteger(ledger.cursor) || ledger.cursor < 0 || ledger.cursor > game.commands.length) throw new Error('Invalid original expression cursor')
  return { game, cursor: ledger.cursor }
}
