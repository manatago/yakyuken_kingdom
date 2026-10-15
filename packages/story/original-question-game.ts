import document from '../../content/stories/godot-stage5-minigame.json'
import type { CurseCommand } from './original-curse-game'
export const originalQuestionSource = document
type Pool = 'red' | 'strong'
interface Action { pick: number; nextRolls: number[] }
export interface OriginalQuestionGame {
  initialRolls: number[]; actions: Action[]; used: Record<Pool, number[]>
  pool: Pool; question: number; choices: number[]; gauge: number
  commands: CurseCommand[]; outcome?: 'win' | 'lose'
}
function validateRolls(values: number[]) {
  if (!Array.isArray(values) || values.length !== 7 || values.some(value => !Number.isFinite(value) || value < 0 || value >= 1)) throw new Error('Invalid original question rolls')
}
function nextQuestion(game: OriginalQuestionGame, values: number[]) {
  validateRolls(values)
  game.pool = document.zones[game.gauge] === 'red' ? 'red' : 'strong'
  const questions = document.questions.filter(question => question.pool === game.pool)
  if (game.used[game.pool].length === questions.length) game.used[game.pool] = []
  const available = questions.filter(question => !game.used[game.pool].includes(question.index))
  const question = available[Math.floor(values[0] * available.length)]
  game.question = question.index
  game.used[game.pool].push(question.index)
  const misses = question.data.misses.map((_, index) => index + 2)
  for (let index = 3; index > 0; index--) {
    const other = Math.floor(values[4 - index] * (index + 1))
    ;[misses[index], misses[other]] = [misses[other], misses[index]]
  }
  game.choices = [0, ...misses.slice(0, 3)]
  for (let index = 3; index > 0; index--) {
    const other = Math.floor(values[7 - index] * (index + 1))
    ;[game.choices[index], game.choices[other]] = [game.choices[other], game.choices[index]]
  }
  game.commands.push(...structuredClone(question.commands) as CurseCommand[])
}
export function createOriginalQuestionGame(values: number[]): OriginalQuestionGame {
  const game: OriginalQuestionGame = { initialRolls: [...values], actions: [], used: { red: [], strong: [] },
    pool: 'red', question: 0, choices: [], gauge: document.intro_gauge, commands: structuredClone(document.intro) as CurseCommand[] }
  nextQuestion(game, values)
  return game
}
export function chooseOriginalQuestion(game: OriginalQuestionGame, pick: number, nextRolls: number[]): OriginalQuestionGame {
  if (game.outcome || (pick !== 1 && !game.choices.includes(pick))) throw new Error('Invalid original question choice')
  validateRolls(nextRolls)
  const trace = document.traces.find(trace => trace.pool === game.pool && trace.question === game.question && trace.pick === pick)
  if (!trace) throw new Error('Missing original question trace')
  const delta = pick < 2 ? -40 : 5
  const gauge = document.gauge_traces.find(trace => trace.initial_gauge === game.gauge && trace.delta === delta)
  if (!gauge) throw new Error('Missing original question gauge transition')
  const gaugeIndex = trace.commands.findIndex(command => command.kind === 'gauge')
  if (gaugeIndex < 0) throw new Error('Missing original question gauge command')
  const next = structuredClone(game)
  next.commands = [...structuredClone(trace.commands.slice(0, gaugeIndex)), ...structuredClone(gauge.commands)] as CurseCommand[]
  next.gauge = gauge.final_gauge
  next.actions.push({ pick, nextRolls: [...nextRolls] })
  if (next.gauge === 0 || next.gauge === document.config.gauge_max) {
    next.outcome = next.gauge === 0 ? 'win' : 'lose'
    next.commands.push(...structuredClone(document[next.outcome]) as CurseCommand[])
  } else nextQuestion(next, nextRolls)
  return next
}
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}
export function restoreOriginalQuestionGame(value: unknown): OriginalQuestionGame {
  if (!value || typeof value !== 'object') throw new Error('Invalid original question game')
  const saved = value as OriginalQuestionGame
  if (!Array.isArray(saved.actions) || saved.actions.length > 1000) throw new Error('Invalid original question history')
  let expected = createOriginalQuestionGame(saved.initialRolls)
  for (const action of saved.actions) expected = chooseOriginalQuestion(expected, action.pick, action.nextRolls)
  if (canonical(saved) !== canonical(expected)) throw new Error('Original question game does not match replay')
  return expected
}

export interface OriginalQuestionLedger { game: OriginalQuestionGame; cursor: number }
export function restoreOriginalQuestionLedger(value: unknown): OriginalQuestionLedger {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original question ledger')
  const ledger = value as OriginalQuestionLedger
  if (Object.keys(ledger).some(key => key !== 'game' && key !== 'cursor')) throw new Error('Unknown original question ledger field')
  const game = restoreOriginalQuestionGame(ledger.game)
  if (!Number.isSafeInteger(ledger.cursor) || ledger.cursor < 0 || ledger.cursor > game.commands.length) throw new Error('Invalid original question cursor')
  return { game, cursor: ledger.cursor }
}
