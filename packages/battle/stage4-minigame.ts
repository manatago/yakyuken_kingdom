import type { SaveData } from '../domain/save'

export const STAGE4_MINIGAME_CHECKPOINT = 'stage4.minigame'
export const STAGE4_MINIGAME_END_CHECKPOINT = 'stage4.minigame.end'
export const STAGE4_GAUGE_MAX = 130
export const STAGE4_CHOICES = ['calm', 'challenge', 'neutral', 'pisuke'] as const
export type Stage4Choice = typeof STAGE4_CHOICES[number]
export type Stage4Zone = 'red' | 'yellow' | 'green'
export interface Stage4Round { readonly selected: Stage4Choice; readonly zone: Stage4Zone; readonly delta: number; readonly gauge_after: number }
export interface Stage4MinigameLedger { readonly gauge: number; readonly rounds: readonly Stage4Round[]; readonly outcome?: 'win' | 'lose' }

export function stage4Zone(gauge: number): Stage4Zone {
  return gauge >= Math.floor(STAGE4_GAUGE_MAX * 0.77) ? 'red' : gauge >= Math.floor(STAGE4_GAUGE_MAX * 0.38) ? 'yellow' : 'green'
}

function deltaFor(selected: Stage4Choice, zone: Stage4Zone): number {
  if (selected === 'pisuke' || selected === 'calm' && zone === 'red' || selected === 'challenge' && zone !== 'red') return -40
  return 5
}

export function validateStage4Minigame(ledger: Stage4MinigameLedger): void {
  if (!Number.isSafeInteger(ledger.gauge) || ledger.gauge < 0 || ledger.gauge > STAGE4_GAUGE_MAX ||
      !Array.isArray(ledger.rounds) || ledger.rounds.length > 100) throw new Error('Invalid Stage 4 minigame ledger')
  let gauge = 110
  for (const round of ledger.rounds) {
    if (!STAGE4_CHOICES.includes(round.selected) || round.zone !== stage4Zone(gauge) || round.delta !== deltaFor(round.selected, round.zone)) {
      throw new Error('Invalid Stage 4 choice')
    }
    gauge = Math.max(0, Math.min(STAGE4_GAUGE_MAX, gauge + round.delta))
    if (gauge !== round.gauge_after) throw new Error('Stage 4 gauge does not match its history')
  }
  const outcome = gauge === 0 ? 'win' : gauge === STAGE4_GAUGE_MAX ? 'lose' : undefined
  if (ledger.gauge !== gauge || ledger.outcome !== outcome) throw new Error('Stage 4 result does not match its history')
}

export function beginStage4Minigame(save: SaveData): SaveData {
  if (save.progress.checkpoint_id !== 'stage4.minigame.ready' || !save.progress.flags.includes('stage4.started') ||
      save.progress.stage4_minigame) throw new Error('Stage 4 minigame is not ready')
  const ledger: Stage4MinigameLedger = { gauge: 110, rounds: [] }
  return { ...save, progress: { ...save.progress, checkpoint_id: STAGE4_MINIGAME_CHECKPOINT, stage4_minigame: ledger } }
}

export function chooseStage4Option(save: SaveData, selected: Stage4Choice): SaveData {
  const ledger = save.progress.stage4_minigame
  if (save.progress.checkpoint_id !== STAGE4_MINIGAME_CHECKPOINT || !ledger || ledger.outcome) throw new Error('Stage 4 is not accepting a choice')
  validateStage4Minigame(ledger)
  const zone = stage4Zone(ledger.gauge)
  const delta = deltaFor(selected, zone)
  const gauge = Math.max(0, Math.min(STAGE4_GAUGE_MAX, ledger.gauge + delta))
  const outcome = gauge === 0 ? 'win' : gauge === STAGE4_GAUGE_MAX ? 'lose' : undefined
  const round: Stage4Round = { selected, zone, delta, gauge_after: gauge }
  const next: Stage4MinigameLedger = { gauge, rounds: [...ledger.rounds, round], ...(outcome ? { outcome } : {}) }
  validateStage4Minigame(next)
  return { ...save, progress: { ...save.progress, checkpoint_id: outcome ? STAGE4_MINIGAME_END_CHECKPOINT : STAGE4_MINIGAME_CHECKPOINT,
    stage4_minigame: next } }
}

export function parseStage4Minigame(value: unknown): Stage4MinigameLedger {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Stage 4 minigame ledger')
  const item = value as Record<string, unknown>
  if (Reflect.ownKeys(item).some((key) => typeof key !== 'string' || !['gauge', 'rounds', 'outcome'].includes(key)) || !Array.isArray(item.rounds)) {
    throw new TypeError('Invalid Stage 4 minigame ledger')
  }
  const rounds = item.rounds.map((entry) => {
    if (entry === null || typeof entry !== 'object' || Array.isArray(entry)) throw new TypeError('Invalid Stage 4 round')
    const round = entry as Record<string, unknown>
    if (Reflect.ownKeys(round).some((key) => typeof key !== 'string' || !['selected', 'zone', 'delta', 'gauge_after'].includes(key))) {
      throw new TypeError('Invalid Stage 4 round')
    }
    return { selected: round.selected as Stage4Choice, zone: round.zone as Stage4Zone,
      delta: round.delta as number, gauge_after: round.gauge_after as number }
  })
  const parsed: Stage4MinigameLedger = { gauge: item.gauge as number, rounds,
    ...(item.outcome !== undefined ? { outcome: item.outcome as 'win' | 'lose' } : {}) }
  if (parsed.outcome !== undefined && parsed.outcome !== 'win' && parsed.outcome !== 'lose') throw new TypeError('Invalid Stage 4 outcome')
  validateStage4Minigame(parsed)
  return parsed
}

export function validateStage4MinigameState(save: SaveData): void {
  const ledger = save.progress.stage4_minigame
  const checkpoint = save.progress.checkpoint_id
  const active = [STAGE4_MINIGAME_CHECKPOINT, STAGE4_MINIGAME_END_CHECKPOINT].includes(checkpoint)
  const later = checkpoint.startsWith('stage4.rematch.') || checkpoint.startsWith('stage4.post.') || checkpoint === 'stage4.rematch.loss.end'
  if (!ledger) { if (active || later) throw new Error('Missing Stage 4 minigame ledger'); return }
  validateStage4Minigame(ledger)
  if (active && (checkpoint === STAGE4_MINIGAME_CHECKPOINT ? !!ledger.outcome : !ledger.outcome) || later && !ledger.outcome) {
    throw new Error('Stage 4 checkpoint does not match its minigame result')
  }
}

export function continueStage4Minigame(save: SaveData): SaveData {
  const ledger = save.progress.stage4_minigame
  if (save.progress.checkpoint_id !== STAGE4_MINIGAME_END_CHECKPOINT || !ledger?.outcome) throw new Error('Stage 4 minigame has not finished')
  return { ...save, progress: { ...save.progress, flags: save.progress.flags.includes('stage4_minigame_completed')
    ? [...save.progress.flags] : [...save.progress.flags, 'stage4_minigame_completed'], checkpoint_id: 'stage4.rematch.background' } }
}
