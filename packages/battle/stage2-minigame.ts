import type { SaveData } from '../domain/save'

export const STAGE2_MINIGAME_CHECKPOINT = 'stage2.minigame'
export const STAGE2_MINIGAME_END_CHECKPOINT = 'stage2.minigame.end'
export const STAGE2_REMATCH_CHECKPOINT = 'stage2.battle2.start'

export const STAGE2_EXPRESSIONS = ['shake', 'blush', 'sweat', 'panic'] as const
export type Stage2Expression = (typeof STAGE2_EXPRESSIONS)[number]
export type Stage2Pick = Stage2Expression | 'ask_pisuke'

export const STAGE2_MINIGAME_SCENES: readonly Stage2Expression[] = [
  'blush', 'blush', 'shake', 'sweat', 'shake', 'sweat', 'shake', 'shake', 'blush', 'sweat'
]

export function isStage2PickCorrect(sceneIndex: number, pick: Stage2Pick): boolean {
  return pick === 'ask_pisuke' || STAGE2_MINIGAME_SCENES[sceneIndex] === pick
}

export interface Stage2MinigameLedger {
  readonly scene_order: readonly number[]
  readonly current_scene: number
  readonly gauge: number
  readonly picks: readonly Stage2Pick[]
  readonly outcome?: 'win' | 'lose'
}

export function validateStage2Minigame(ledger: Stage2MinigameLedger): void {
  if (ledger.scene_order.length !== STAGE2_MINIGAME_SCENES.length ||
      new Set(ledger.scene_order).size !== ledger.scene_order.length ||
      ledger.scene_order.some((index) => !Number.isSafeInteger(index) || index < 0 || index >= STAGE2_MINIGAME_SCENES.length)) {
    throw new Error('Invalid Stage 2 minigame scene order')
  }
  if (!Number.isSafeInteger(ledger.current_scene) || ledger.current_scene < 0 || ledger.current_scene > ledger.scene_order.length ||
      ledger.picks.length !== ledger.current_scene || ledger.picks.some((pick) => pick !== 'ask_pisuke' && !STAGE2_EXPRESSIONS.includes(pick)) ||
      !Number.isSafeInteger(ledger.gauge) || ledger.gauge < 0 || ledger.gauge > 130) {
    throw new Error('Invalid Stage 2 minigame progress')
  }
  const expectedGauge = Math.max(0, Math.min(130, 100 + ledger.picks.reduce((gauge, pick, index) =>
    gauge + (pick === 'ask_pisuke' || pick === STAGE2_MINIGAME_SCENES[ledger.scene_order[index]!] ? -40 : 5), 0)))
  if (ledger.gauge !== expectedGauge) throw new Error('Stage 2 minigame gauge does not match recorded choices')
  const expectedOutcome = ledger.gauge <= 0 ? 'win' : ledger.gauge >= 130 ? 'lose' : undefined
  if (ledger.outcome !== expectedOutcome) throw new Error('Stage 2 minigame outcome does not match gauge')
}

export function startStage2Minigame(save: SaveData, sceneOrder: readonly number[]): SaveData {
  const firstBattleSettled = save.progress.fixed_battle?.battle_id === 'battle.stage2.first' &&
    save.progress.fixed_battle.settled && save.progress.checkpoint_id === 'stage2.recover.end'
  if (!save.progress.flags.includes('stage2.started') ||
      !save.progress.flags.includes('stage2_first_battle_completed') && !firstBattleSettled) {
    throw new Error('Stage 2 first battle is not complete')
  }
  if (save.progress.stage2_minigame) throw new Error('Stage 2 minigame already started')
  const ledger: Stage2MinigameLedger = { scene_order: [...sceneOrder], current_scene: 0, gauge: 100, picks: [] }
  validateStage2Minigame(ledger)
  const { guild_return_checkpoint: _guildReturnCheckpoint, ...progress } = save.progress
  const flags = progress.flags.includes('stage2_first_battle_completed')
    ? [...progress.flags] : [...progress.flags, 'stage2_first_battle_completed']
  return { ...save, progress: { ...progress, flags, checkpoint_id: STAGE2_MINIGAME_CHECKPOINT, stage2_minigame: ledger } }
}

export function continueToStage2Rematch(save: SaveData): SaveData {
  const ledger = save.progress.stage2_minigame
  if (!ledger?.outcome || save.progress.checkpoint_id !== STAGE2_MINIGAME_END_CHECKPOINT) {
    throw new Error('Stage 2 minigame has not finished')
  }
  const flags = [...save.progress.flags]
  if (!flags.includes('stage2_minigame_completed')) flags.push('stage2_minigame_completed')
  if (!flags.includes('stage2_first_battle_done')) flags.push('stage2_first_battle_done')
  return { ...save, progress: { ...save.progress, flags, checkpoint_id: STAGE2_REMATCH_CHECKPOINT } }
}

function recordStage2Pick(save: SaveData, pick: Stage2Pick): SaveData {
  const ledger = save.progress.stage2_minigame
  if (!ledger) throw new Error('Stage 2 minigame has not started')
  validateStage2Minigame(ledger)
  if (ledger.outcome) throw new Error('Stage 2 minigame has already ended')
  if (pick !== 'ask_pisuke' && !STAGE2_EXPRESSIONS.includes(pick)) throw new Error('Invalid expression choice')
  const correct = isStage2PickCorrect(ledger.scene_order[ledger.current_scene]!, pick)
  const gauge = Math.max(0, Math.min(130, ledger.gauge + (correct ? -40 : 5)))
  const current_scene = ledger.current_scene + 1
  const outcome = gauge <= 0 ? 'win' : gauge >= 130 ? 'lose' : undefined
  const nextLedger: Stage2MinigameLedger = { ...ledger, current_scene, gauge, picks: [...ledger.picks, pick], ...(outcome ? { outcome } : {}) }
  validateStage2Minigame(nextLedger)
  return { ...save, progress: { ...save.progress,
    checkpoint_id: outcome ? STAGE2_MINIGAME_END_CHECKPOINT : STAGE2_MINIGAME_CHECKPOINT,
    stage2_minigame: nextLedger } }
}

export function chooseStage2Expression(save: SaveData, pick: Stage2Expression): SaveData {
  return recordStage2Pick(save, pick)
}

export function askPisukeForStage2Minigame(save: SaveData): SaveData {
  return recordStage2Pick(save, 'ask_pisuke')
}

export function parseStage2Minigame(value: unknown): Stage2MinigameLedger {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) throw new TypeError('Invalid Stage 2 minigame ledger')
  const prototype = Object.getPrototypeOf(value)
  if (prototype !== Object.prototype && prototype !== null) throw new TypeError('Invalid Stage 2 minigame ledger')
  const ledger = value as Record<string, unknown>
  const keys = Reflect.ownKeys(value)
  if (keys.some((key) => typeof key !== 'string' || !['scene_order', 'current_scene', 'gauge', 'picks', 'outcome'].includes(key)) ||
      keys.some((key) => { const descriptor = Object.getOwnPropertyDescriptor(value, key); return !descriptor || !('value' in descriptor) }) ||
      !Array.isArray(ledger.scene_order) || !Array.isArray(ledger.picks) ||
      ledger.scene_order.some((index) => !Number.isSafeInteger(index)) ||
      ledger.picks.some((pick) => typeof pick !== 'string') ||
      (ledger.outcome !== undefined && ledger.outcome !== 'win' && ledger.outcome !== 'lose')) {
    throw new TypeError('Invalid Stage 2 minigame ledger')
  }
  const parsed: Stage2MinigameLedger = {
    scene_order: ledger.scene_order as number[], current_scene: ledger.current_scene as number,
    gauge: ledger.gauge as number, picks: ledger.picks as Stage2Pick[],
    ...(ledger.outcome ? { outcome: ledger.outcome as 'win' | 'lose' } : {})
  }
  validateStage2Minigame(parsed)
  return parsed
}
