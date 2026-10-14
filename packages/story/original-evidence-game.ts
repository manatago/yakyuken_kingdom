import source from '../../content/stories/godot-stage3-minigame.json'
import type { CurseCommand } from './original-curse-game'

export const originalEvidenceSource = source
type Pair = { chapter: string; evidence: string }
type Pick = Pair | '_pisuke'
interface Action { pick: Pick; supportRoll: number; nextRolls: number[] }
export interface OriginalEvidenceGame {
  initialRolls: number[]; actions: Action[]; chapters: string[]; evidences: string[]
  used: string[]; gauge: number; commands: CurseCommand[]; outcome?: 'win' | 'lose'
}
function validRoll(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid original evidence roll')
}
function grid(used: readonly string[], rolls: readonly number[]) {
  if (rolls.length !== 13) throw new Error('Original evidence grid requires thirteen rolls')
  rolls.forEach(validRoll)
  let cursor = 0
  const unused = source.valid_combos.filter(combo => !used.includes(`${combo.chapter}|${combo.evidence}`))
  const pool = unused.length ? unused : source.valid_combos
  const hit = pool[Math.floor(rolls[cursor++] * pool.length)]
  function sample(values: readonly string[], count: number) {
    const available = [...values]; const selected: string[] = []
    while (selected.length < count) selected.push(available.splice(Math.floor(rolls[cursor++] * available.length), 1)[0])
    return selected
  }
  const books = [hit.chapter, ...sample(source.miss_chapter_keys, 3)]
  const evidence = [hit.evidence, ...sample(source.miss_evidence_keys, 3)]
  // Draw three positions without replacement; the final position needs no roll.
  function arrange(values: string[]) {
    const available = [...values]; const result: string[] = []
    while (available.length > 1) result.push(available.splice(Math.floor(rolls[cursor++] * available.length), 1)[0])
    return [...result, available[0]]
  }
  return { chapters: arrange(books), evidences: arrange(evidence) }
}
export function createOriginalEvidenceGame(rolls: readonly number[]): OriginalEvidenceGame {
  return { initialRolls: [...rolls], actions: [], ...grid([], rolls), used: [], gauge: source.gauge_start,
    commands: structuredClone(source.intro) as CurseCommand[] }
}
export function chooseOriginalEvidence(state: OriginalEvidenceGame, pick: Pick, supportRoll: number, nextRolls: readonly number[]): OriginalEvidenceGame {
  if (state.outcome) throw new Error('Original evidence game is complete')
  validRoll(supportRoll)
  grid(state.used, nextRolls)
  if (pick === '_pisuke' && state.actions.length < 1) throw new Error('Pisuke support is locked')
  const unused = source.valid_combos.filter(combo => !state.used.includes(`${combo.chapter}|${combo.evidence}`))
  const pair = pick === '_pisuke' ? unused[Math.floor(supportRoll * unused.length)] : pick
  if (pick !== '_pisuke' && (!pair || !state.chapters.includes(pair.chapter) || !state.evidences.includes(pair.evidence))) throw new Error('Original evidence choice is not in the current grid')
  const key = pair ? `${pair.chapter}|${pair.evidence}` : ''
  const hit = pair && source.valid_combos.some(combo => combo.chapter === pair.chapter && combo.evidence === pair.evidence)
  const trace = !pair ? undefined : (pick === '_pisuke' ? source.pisuke_traces : hit && state.used.includes(key) ? source.repeat_traces : source.traces)
    .find(trace => trace.chapter === pair.chapter && trace.evidence === pair.evidence)
  if (pair && !trace) throw new Error('Original evidence trace is missing')
  const next = structuredClone(state)
  next.actions.push({ pick: pick === '_pisuke' ? pick : { chapter: pick.chapter, evidence: pick.evidence }, supportRoll, nextRolls: [...nextRolls] })
  const delta = trace?.delta ?? 0
  next.gauge = Math.max(0, Math.min(source.gauge_max, state.gauge + delta))
  if (hit && !state.used.includes(key)) next.used.push(key)
  next.commands = [...structuredClone(trace?.commands ?? []) as CurseCommand[], { kind: 'gauge', args: [delta, next.gauge] }]
  if (next.gauge === 0 || next.gauge === source.gauge_max) {
    next.outcome = next.gauge === 0 ? 'win' : 'lose'
    next.commands.push({ kind: 'dialogue_band', args: ['narrator', source.ending[next.outcome], true] },
      { kind: 'wait', args: [0] }, { kind: 'hide_dialogue_band', args: [] }, { kind: 'wait', args: [0] })
  } else Object.assign(next, grid(next.used, nextRolls))
  return next
}
function canonical(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonical).join(',')}]`
  if (value && typeof value === 'object') return `{${Object.keys(value).sort().map(key =>
    `${JSON.stringify(key)}:${canonical((value as Record<string, unknown>)[key])}`).join(',')}}`
  return JSON.stringify(value)
}
export function restoreOriginalEvidenceGame(value: unknown): OriginalEvidenceGame {
  if (!value || typeof value !== 'object') throw new Error('Invalid original evidence game')
  const saved = value as OriginalEvidenceGame
  if (!Array.isArray(saved.actions) || saved.actions.length > 1000) throw new Error('Invalid original evidence history')
  let expected = createOriginalEvidenceGame(saved.initialRolls)
  for (const action of saved.actions) expected = chooseOriginalEvidence(expected, action.pick, action.supportRoll, action.nextRolls)
  if (canonical(expected) !== canonical(saved)) throw new Error('Original evidence game does not match replay')
  return expected
}
export interface OriginalEvidenceLedger { game: OriginalEvidenceGame; cursor: number }
export function restoreOriginalEvidenceLedger(value: unknown): OriginalEvidenceLedger {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original evidence ledger')
  const ledger = value as OriginalEvidenceLedger
  if (Object.keys(ledger).some(key => key !== 'game' && key !== 'cursor')) throw new Error('Unknown original evidence ledger field')
  const game = restoreOriginalEvidenceGame(ledger.game)
  if (!Number.isSafeInteger(ledger.cursor) || ledger.cursor < 0 || ledger.cursor > game.commands.length) throw new Error('Invalid original evidence cursor')
  return { game, cursor: ledger.cursor }
}
