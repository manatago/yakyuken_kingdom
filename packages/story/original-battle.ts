import document from '../../content/stories/godot-prologue-battle.json'
import { originalMatildaOutcome, type OriginalJanken } from '../battle/original-janken'

export type OriginalBattleResult = 'win' | 'lose' | 'draw'
export interface BattleTraceCommand { kind: string; args: unknown[] }
export interface OriginalBattleTrace {
  method: string
  outcomes: OriginalBattleResult[]
  repeated?: boolean
  commands: BattleTraceCommand[]
}
export const originalPrologueBattleTraces = document.traces as OriginalBattleTrace[]
export interface OriginalBattlePlayback {
  method: string
  repeated: boolean
  cursor: number
  results: OriginalBattleResult[]
}

/** BattleScene chooses the chapter method from remaining opponent HP, not player HP. */
export function createOriginalMatildaRoundPlayback(battle: OriginalJanken): OriginalBattlePlayback | undefined {
  if (originalMatildaOutcome(battle)) return undefined
  if (!Number.isInteger(battle.opponentHp) || battle.opponentHp < 1 || battle.opponentHp > 3 || battle.selection !== null) {
    throw new Error('Invalid original Matilda round start')
  }
  const previous = battle.rounds.at(-1)
  return createOriginalBattlePlayback(`outfit_${battle.opponentHp}`, previous !== undefined && previous.result !== 'win')
}

export function createOriginalBattlePlayback(method: string, repeated = false, traces: readonly OriginalBattleTrace[] = originalPrologueBattleTraces): OriginalBattlePlayback {
  if (!traces.some(t => t.method === method && (t.repeated ?? false) === repeated)) {
    throw new Error(`Unknown original battle method: ${method}`)
  }
  return { method, repeated, cursor: 0, results: [] }
}

function candidates(state: OriginalBattlePlayback, source: readonly OriginalBattleTrace[]) {
  const traces = source.filter(t => t.method === state.method &&
    (t.repeated ?? false) === state.repeated && state.results.every((result, i) => t.outcomes[i] === result))
  if (!traces.length || !Number.isInteger(state.cursor) || state.cursor < 0 ||
      traces.some(t => state.cursor > t.commands.length)) throw new Error('Invalid original battle trace state')
  const recordedResults = traces[0].commands.slice(0, state.cursor).filter(c => c.kind === 'janken').length
  if (recordedResults !== state.results.length) throw new Error('Original battle result history mismatch')
  return traces
}

function runtimeCommand(command?: BattleTraceCommand): BattleTraceCommand | undefined {
  if (!command) return undefined
  // The exported third janken argument is a fixture outcome, NOT a game rule.
  return structuredClone(command.kind === 'janken' ? { ...command, args: command.args.slice(0, 2) } : command)
}

export function nextOriginalBattleCommand(state: OriginalBattlePlayback, source: readonly OriginalBattleTrace[] = originalPrologueBattleTraces): BattleTraceCommand | undefined {
  const traces = candidates(state, source)
  const command = runtimeCommand(traces[0].commands[state.cursor])
  if (traces.some(t => JSON.stringify(runtimeCommand(t.commands[state.cursor])) !== JSON.stringify(command))) {
    throw new Error('Unresolved original battle branch')
  }
  return command
}

export function advanceOriginalBattleCommand(state: OriginalBattlePlayback, result?: OriginalBattleResult, source: readonly OriginalBattleTrace[] = originalPrologueBattleTraces): OriginalBattlePlayback {
  const command = nextOriginalBattleCommand(state, source)
  if (!command) throw new Error('Original battle trace is complete')
  if (command.kind === 'janken' ? !result || !['win', 'lose', 'draw'].includes(result) : result !== undefined) {
    throw new Error('Unexpected or missing original battle result')
  }
  const next = { ...state, cursor: state.cursor + 1,
    results: result ? [...state.results, result] : [...state.results] }
  candidates(next, source)
  return next
}
