import progression from '../../content/progression.json'

export const PROGRESSION_FLAGS = {
  subevent1Cleared: progression.subeventCompleteFlags.subevent1,
  subevent4Cleared: progression.subeventCompleteFlags.subevent4,
  stage4Cleared: 'stage4_cleared'
} as const

// Godot's current stories do not consistently set completion flags for every
// subevent. Keep the proposed guild-board progression explicit and editable.
export const SUBEVENT_RANDOM_BATTLE_REQUIREMENT = progression.subeventRandomBattleRequirement
export const SUBEVENT_COMPLETION_FLAGS = progression.subeventCompleteFlags

export type SubeventId = keyof typeof SUBEVENT_COMPLETION_FLAGS

export interface SubeventUnlockState {
  readonly unlocked: boolean
  readonly reasons: readonly string[]
  readonly randomBattles: number
  readonly requiredRandomBattles: number
}

/**
 * Provisional guild-board rules recorded from the user's direction:
 * Subevent 1 requires the Adventurer tutorial; each later event requires the
 * previous event. All require three cumulative settled random battles.
 */
export function getSubeventUnlockState(
  id: SubeventId,
  flags: readonly string[],
  randomBattles: number,
): SubeventUnlockState {
  const reasons: string[] = []
  const previous: Record<SubeventId, SubeventId | undefined> = {
    subevent1: undefined,
    subevent2: 'subevent1',
    subevent3: 'subevent2',
    subevent4: 'subevent3'
  }
  if (id === 'subevent1' && !flags.includes('adventurer.tutorial.completed')) {
    reasons.push('冒険者チュートリアルを完了')
  }
  const previousId = previous[id]
  if (previousId && !flags.includes(SUBEVENT_COMPLETION_FLAGS[previousId])) {
    reasons.push(`サブイベント${previousId.slice(-1)}を完了`)
  }
  if (randomBattles < SUBEVENT_RANDOM_BATTLE_REQUIREMENT) {
    reasons.push(`ランダム戦をあと${SUBEVENT_RANDOM_BATTLE_REQUIREMENT - randomBattles}回経験`)
  }
  return { unlocked: reasons.length === 0, reasons, randomBattles,
    requiredRandomBattles: SUBEVENT_RANDOM_BATTLE_REQUIREMENT }
}
