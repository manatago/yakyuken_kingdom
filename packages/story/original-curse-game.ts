import document from '../../content/stories/godot-subevent3-minigame.json'

export interface CurseCommand { kind: string; args: unknown[] }
interface CurseAction { selected: number | 'pisuke'; pisukeRoll: number; nextRolls: number[] }
export interface OriginalCurseGame {
  initialRolls: number[]
  actions: CurseAction[]
  gauge: number
  choices: number[]
  pisukeUsed: number[]
  pisukeCycle: number
  commands: CurseCommand[]
  outcome?: 'win' | 'lose'
}
export const originalCurseSource = document
export interface OriginalCurseLedger { game: OriginalCurseGame; cursor: number }

export function restoreOriginalCurseLedger(value: unknown): OriginalCurseLedger {
  if (!value || typeof value !== 'object' || Object.keys(value).sort().join(',') !== 'cursor,game') throw new Error('Invalid original curse ledger')
  const ledger = value as OriginalCurseLedger
  const game = restoreOriginalCurseGame(ledger.game)
  if (!Number.isInteger(ledger.cursor) || ledger.cursor < 0 || ledger.cursor > game.commands.length) throw new Error('Invalid original curse cursor')
  return { game, cursor: ledger.cursor }
}

function validateRoll(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original minigame roll')
}
function deal(rolls: readonly number[], previous: readonly number[] = []): number[] {
  if (!Array.isArray(rolls) || rolls.length !== 8) throw new Error('Expected eight choice rolls')
  rolls.forEach(validateRoll)
  const pick = (start: number) => {
    const remaining = document.choices.map((_, index) => index)
    return rolls.slice(start, start + 4).map(roll => remaining.splice(Math.floor(roll * remaining.length), 1)[0])
  }
  const first = pick(0)
  // The source retries once, not until a different set is found.
  return previous.length === 4 && first.every(index => previous.includes(index)) ? pick(4) : first
}

export function createOriginalCurseGame(rolls: readonly number[]): OriginalCurseGame {
  return { initialRolls: [...rolls], actions: [], gauge: document.intro_gauge,
    choices: deal(rolls), pisukeUsed: [], pisukeCycle: 0,
    commands: [...structuredClone(document.intro) as CurseCommand[], { kind: 'narrator_band', args: [document.choice_prompt, '', ''] }] }
}

export function playOriginalCurseChoice(state: OriginalCurseGame, selected: number | 'pisuke',
  pisukeRoll: number, nextRolls: readonly number[]): OriginalCurseGame {
  if (state.outcome) throw new Error('Original minigame is complete')
  validateRoll(pisukeRoll)
  // Validate even unused terminal rolls to keep the serialized action schema bounded.
  const choices = deal(nextRolls, state.choices)
  const next = structuredClone(state)
  let trace
  if (selected === 'pisuke') {
    if (next.pisukeUsed.length === document.pisuke_lines.length) {
      next.pisukeUsed = []; next.pisukeCycle++
    }
    const available = document.pisuke_lines.map((_, index) => index).filter(index => !next.pisukeUsed.includes(index))
    const index = available[Math.floor(pisukeRoll * available.length)]
    next.pisukeUsed.push(index)
    trace = document.pisuke_traces.find(trace => trace.index === index && trace.cycle === Math.min(next.pisukeCycle, 2))!
  } else {
    if (!Number.isInteger(selected) || !state.choices.includes(selected)) throw new Error('Choice was not offered')
    trace = document.choice_traces.find(trace => trace.index === selected)!
  }
  next.gauge = Math.max(0, Math.min(document.gauge_max, state.gauge + trace.delta))
  next.commands = structuredClone(trace.commands) as CurseCommand[]
  for (const command of next.commands) {
    if (command.kind === 'gauge') command.args[1] = next.gauge
  }
  next.actions.push({ selected, pisukeRoll, nextRolls: [...nextRolls] })
  next.choices = choices
  if (next.gauge === 0 || next.gauge === document.gauge_max) {
    next.outcome = next.gauge === 0 ? 'win' : 'lose'; next.choices = []
    next.commands.push({ kind: 'narrator_band', args: [document.ending[next.outcome], '', ''] })
  }
  return next
}

function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}

export function restoreOriginalCurseGame(value: unknown): OriginalCurseGame {
  if (!value || typeof value !== 'object') throw new Error('Invalid original minigame')
  const saved = value as OriginalCurseGame
  if (!Array.isArray(saved.actions) || saved.actions.length > 1000) throw new Error('Invalid original minigame actions')
  let expected = createOriginalCurseGame(saved.initialRolls)
  for (const action of saved.actions) expected = playOriginalCurseChoice(expected, action.selected, action.pisukeRoll, action.nextRolls)
  if (canonical(saved) !== canonical(expected)) throw new Error('Original minigame does not match its replay')
  return expected
}
