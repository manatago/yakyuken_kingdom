import document from '../../content/stories/godot-stage4-minigame.json'
import type { CurseCommand } from './original-curse-game'

export const originalStrengthSource = document
type Pool = 'light' | 'strong' | 'miss'
export interface StrengthChoice { pool: Pool; index: number }
interface Action { pick: StrengthChoice | '_pisuke'; supportRoll: number; nextRolls: number[] }
export interface OriginalStrengthGame {
  initialRolls: number[]
  actions: Action[]
  used: Record<Pool, number[]>
  choices: StrengthChoice[]
  gauge: number
  commands: CurseCommand[]
  outcome?: 'win' | 'lose'
}
const pools = { light: document.light_pool, strong: document.strong_pool, miss: document.miss_pool }
function roll(value: number) {
  if (!Number.isFinite(value) || value < 0 || value >= 1) throw new Error('Invalid original strength roll')
}
function available(game: OriginalStrengthGame, pool: Pool) {
  if (game.used[pool].length === pools[pool].length) game.used[pool] = []
  return pools[pool].map((_, index) => index).filter(index => !game.used[pool].includes(index))
}
function pickChoices(game: OriginalStrengthGame, values: number[]) {
  if (!Array.isArray(values) || values.length !== 5) throw new Error('Invalid original strength choices rolls')
  values.forEach(roll)
  game.choices = (['light', 'strong', 'miss'] as Pool[]).map((pool, position) => {
    const indices = available(game, pool)
    return { pool, index: indices[Math.floor(values[position] * indices.length)] }
  })
  for (let index = 2; index > 0; index--) {
    const other = Math.floor(values[5 - index] * (index + 1))
    ;[game.choices[index], game.choices[other]] = [game.choices[other], game.choices[index]]
  }
}
export function createOriginalStrengthGame(values: number[]): OriginalStrengthGame {
  const game: OriginalStrengthGame = { initialRolls: [...values], actions: [], used: { light: [], strong: [], miss: [] },
    choices: [], gauge: document.intro_gauge, commands: structuredClone(document.intro) as CurseCommand[] }
  pickChoices(game, values)
  return game
}
export function chooseOriginalStrength(game: OriginalStrengthGame, pick: StrengthChoice | '_pisuke', supportRoll: number, nextRolls: number[]): OriginalStrengthGame {
  if (game.outcome) throw new Error('Original strength game is complete')
  roll(supportRoll)
  if (!Array.isArray(nextRolls) || nextRolls.length !== 5) throw new Error('Invalid original strength choices rolls')
  nextRolls.forEach(roll)
  const next = structuredClone(game)
  const zone = document.zones[game.gauge]
  let selected: StrengthChoice
  if (pick === '_pisuke') {
    const pool = zone === 'red' ? 'light' : 'strong'
    const indices = available(next, pool)
    selected = { pool, index: indices[Math.floor(supportRoll * indices.length)] }
  } else {
    if (!game.choices.some(choice => choice.pool === pick.pool && choice.index === pick.index)) throw new Error('Unknown original strength choice')
    selected = { pool: pick.pool, index: pick.index }
  }
  const trace = pick === '_pisuke'
    ? document.pisuke_traces.find(trace => trace.zone === zone && trace.index === selected.index)
    : document.traces.find(trace => trace.zone === zone && trace.pool === selected.pool && trace.index === selected.index)
  if (!trace) throw new Error('Missing original strength trace')
  const delta = trace.final_gauge - trace.initial_gauge < 0 ? -40 : 5
  const gaugeTrace = document.gauge_traces.find(trace => trace.initial_gauge === game.gauge && trace.delta === delta)
  if (!gaugeTrace) throw new Error('Missing original strength gauge transition')
  const gaugeIndex = trace.commands.findIndex(command => command.kind === 'gauge')
  if (gaugeIndex < 0) throw new Error('Missing original strength gauge command')
  next.commands = [...structuredClone(trace.commands.slice(0, gaugeIndex)), ...structuredClone(gaugeTrace.commands)] as CurseCommand[]
  next.gauge = gaugeTrace.final_gauge
  next.used[selected.pool].push(selected.index)
  next.actions.push({ pick: pick === '_pisuke' ? pick : selected, supportRoll, nextRolls: [...nextRolls] })
  if (next.gauge === 0 || next.gauge === document.config.gauge_max) {
    next.outcome = next.gauge === 0 ? 'win' : 'lose'
    next.commands.push({ kind: 'dialogue_band', args: ['narrator', next.outcome === 'win' ? document.config.win_narration : document.config.lose_narration, true] },
      { kind: 'wait', args: [0] }, { kind: 'hide_dialogue_band', args: [] }, { kind: 'wait', args: [0] })
  } else pickChoices(next, nextRolls)
  return next
}
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}
export function restoreOriginalStrengthGame(value: unknown): OriginalStrengthGame {
  if (!value || typeof value !== 'object') throw new Error('Invalid original strength game')
  const saved = value as OriginalStrengthGame
  if (!Array.isArray(saved.actions) || saved.actions.length > 1000) throw new Error('Invalid original strength history')
  let expected = createOriginalStrengthGame(saved.initialRolls)
  for (const action of saved.actions) expected = chooseOriginalStrength(expected, action.pick, action.supportRoll, action.nextRolls)
  if (canonical(expected) !== canonical(saved)) throw new Error('Original strength game does not match replay')
  return expected
}

export interface OriginalStrengthLedger { game: OriginalStrengthGame; cursor: number }
export function restoreOriginalStrengthLedger(value: unknown): OriginalStrengthLedger {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original strength ledger')
  const ledger = value as OriginalStrengthLedger
  if (Object.keys(ledger).some(key => key !== 'game' && key !== 'cursor')) throw new Error('Unknown original strength ledger field')
  const game = restoreOriginalStrengthGame(ledger.game)
  if (!Number.isSafeInteger(ledger.cursor) || ledger.cursor < 0 || ledger.cursor > game.commands.length) throw new Error('Invalid original strength cursor')
  return { game, cursor: ledger.cursor }
}
