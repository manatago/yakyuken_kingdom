import type { SaveData } from '../domain/save'

export const STAGE5_MINIGAME_CHECKPOINT = 'stage5.minigame'
export const STAGE5_MINIGAME_END_CHECKPOINT = 'stage5.minigame.end'
export const STAGE5_GAUGE_MAX = 130
export const STAGE5_CHOICES = ['source_record', 'repeat_question', 'accept_conclusion', 'pisuke'] as const
export type Stage5Choice = typeof STAGE5_CHOICES[number]
export interface Stage5Round { readonly selected: Stage5Choice; readonly hit: boolean; readonly delta: number; readonly gauge_after: number }
export interface Stage5MinigameLedger { readonly gauge: number; readonly hits: number; readonly misses: number; readonly rounds: readonly Stage5Round[]; readonly outcome?: 'win' | 'lose' }

function deltaFor(hit: boolean): number { return hit ? -40 : 5 }

export function validateStage5Minigame(ledger: Stage5MinigameLedger): void {
  if (!Number.isSafeInteger(ledger.gauge) || ledger.gauge < 0 || ledger.gauge > STAGE5_GAUGE_MAX ||
      !Number.isSafeInteger(ledger.hits) || ledger.hits < 0 || !Number.isSafeInteger(ledger.misses) || ledger.misses < 0 ||
      !Array.isArray(ledger.rounds) || ledger.rounds.length > 100) throw new Error('Invalid Stage 5 record-review state')
  let gauge = 100, hits = 0, misses = 0
  for (const round of ledger.rounds) {
    if (!STAGE5_CHOICES.includes(round.selected)) throw new Error('Invalid Stage 5 response')
    const hit = round.selected === 'source_record' || round.selected === 'pisuke'
    if (round.hit !== hit || round.delta !== deltaFor(hit)) throw new Error('Invalid Stage 5 review result')
    gauge = Math.max(0, Math.min(STAGE5_GAUGE_MAX, gauge + round.delta))
    if (round.gauge_after !== gauge) throw new Error('Stage 5 gauge does not match its history')
    if (hit) hits++; else misses++
  }
  const outcome = hits >= 3 || gauge === 0 ? 'win' : misses >= 6 || gauge === STAGE5_GAUGE_MAX ? 'lose' : undefined
  if (ledger.gauge !== gauge || ledger.hits !== hits || ledger.misses !== misses || ledger.outcome !== outcome) {
    throw new Error('Stage 5 review state does not match its history')
  }
}

export function beginStage5Minigame(save: SaveData): SaveData {
  if (save.progress.checkpoint_id !== 'stage5.minigame.ready' || !save.progress.flags.includes('stage5.started') || save.progress.stage5_minigame) {
    throw new Error('Stage 5 record review is not ready')
  }
  const ledger: Stage5MinigameLedger = { gauge: 100, hits: 0, misses: 0, rounds: [] }
  return { ...save, progress: { ...save.progress, checkpoint_id: STAGE5_MINIGAME_CHECKPOINT, stage5_minigame: ledger } }
}

export function chooseStage5Response(save: SaveData, selected: Stage5Choice): SaveData {
  const ledger = save.progress.stage5_minigame
  if (save.progress.checkpoint_id !== STAGE5_MINIGAME_CHECKPOINT || !ledger || ledger.outcome || !STAGE5_CHOICES.includes(selected)) {
    throw new Error('Stage 5 review is not accepting a response')
  }
  validateStage5Minigame(ledger)
  const hit = selected === 'source_record' || selected === 'pisuke'
  const delta = deltaFor(hit)
  const gauge = Math.max(0, Math.min(STAGE5_GAUGE_MAX, ledger.gauge + delta))
  const hits = ledger.hits + Number(hit), misses = ledger.misses + Number(!hit)
  const outcome = hits >= 3 || gauge === 0 ? 'win' : misses >= 6 || gauge === STAGE5_GAUGE_MAX ? 'lose' : undefined
  const round: Stage5Round = { selected, hit, delta, gauge_after: gauge }
  const next: Stage5MinigameLedger = { gauge, hits, misses, rounds: [...ledger.rounds, round], ...(outcome ? { outcome } : {}) }
  validateStage5Minigame(next)
  return { ...save, progress: { ...save.progress, checkpoint_id: outcome ? STAGE5_MINIGAME_END_CHECKPOINT : STAGE5_MINIGAME_CHECKPOINT,
    stage5_minigame: next } }
}

export function parseStage5Minigame(value: unknown): Stage5MinigameLedger {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Stage 5 record-review state')
  const item = value as Record<string, unknown>
  if (Reflect.ownKeys(item).some((key) => typeof key !== 'string' || !['gauge', 'hits', 'misses', 'rounds', 'outcome'].includes(key)) ||
      !Array.isArray(item.rounds)) throw new TypeError('Invalid Stage 5 record-review state')
  const rounds = item.rounds.map((value) => {
    if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Stage 5 response')
    const round = value as Record<string, unknown>
    if (Reflect.ownKeys(round).some((key) => typeof key !== 'string' || !['selected', 'hit', 'delta', 'gauge_after'].includes(key))) {
      throw new TypeError('Invalid Stage 5 response')
    }
    return { selected: round.selected as Stage5Choice, hit: round.hit as boolean, delta: round.delta as number, gauge_after: round.gauge_after as number }
  })
  const parsed: Stage5MinigameLedger = { gauge: item.gauge as number, hits: item.hits as number, misses: item.misses as number, rounds,
    ...(item.outcome !== undefined ? { outcome: item.outcome as 'win' | 'lose' } : {}) }
  if (parsed.outcome !== undefined && parsed.outcome !== 'win' && parsed.outcome !== 'lose') throw new TypeError('Invalid Stage 5 result')
  validateStage5Minigame(parsed)
  return parsed
}

export function validateStage5MinigameState(save: SaveData): void {
  const ledger = save.progress.stage5_minigame, checkpoint = save.progress.checkpoint_id
  const active = checkpoint === STAGE5_MINIGAME_CHECKPOINT || checkpoint === STAGE5_MINIGAME_END_CHECKPOINT
  const later = checkpoint.startsWith('stage5.rematch.') || checkpoint.startsWith('stage5.post.') || checkpoint === 'stage5.rematch.loss.end'
  if (!ledger) { if (active || later) throw new Error('Missing Stage 5 record-review ledger'); return }
  validateStage5Minigame(ledger)
  if (active && (checkpoint === STAGE5_MINIGAME_CHECKPOINT ? !!ledger.outcome : !ledger.outcome) || later && !ledger.outcome) {
    throw new Error('Stage 5 checkpoint does not match record-review result')
  }
}

export function continueStage5Minigame(save: SaveData): SaveData {
  if (save.progress.checkpoint_id !== STAGE5_MINIGAME_END_CHECKPOINT || !save.progress.stage5_minigame?.outcome) {
    throw new Error('Stage 5 record review has not ended')
  }
  const flags = save.progress.flags.includes('stage5_minigame_completed') ? [...save.progress.flags] : [...save.progress.flags, 'stage5_minigame_completed']
  return { ...save, progress: { ...save.progress, flags, checkpoint_id: 'stage5.rematch.background' } }
}
