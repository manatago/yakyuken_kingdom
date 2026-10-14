import document from '../../content/stories/godot-quest-battles.json'
import campaign from '../../content/stories/godot-campaign-battles.json'
import type { Card, Hand } from '../domain/card'
import { createOriginalBattlePlayback, nextOriginalBattleCommand, advanceOriginalBattleCommand,
  type OriginalBattlePlayback, type OriginalBattleTrace, type OriginalBattleResult, type BattleTraceCommand } from './original-battle'

export interface OriginalQuestBattleChapter {
  chapter_path: string
  opponent_id: string
  opponent_name: string
  background: string
  opponent_deck: Card[]
  player_deck_size: number
  opponent_deck_size: number
  player_hp: number
  opponent_hp: number
  opponent_tendency: Partial<Record<Hand, number>>
  bayes_eye: boolean
  gold_reward: { min: number; max: number }
  item_rewards: string[]
  card_reward?: Partial<Card>
  can_lose_cards: boolean
  can_gain_cards: boolean
  lose_behavior: string
  lose_redirect: Record<string, unknown>
  farewell: Record<OriginalBattleResult, Record<string, unknown>>
  setup: BattleTraceCommand[]
  traces: OriginalBattleTrace[]
}

/** Mechanically exported from the current Godot reference, never rewritten dialogue. */
export const originalQuestBattleChapters = document.chapters as OriginalQuestBattleChapter[]

export function originalCampaignChapterId(path: string, flags: readonly string[]): string {
  const value = campaign.chapters.find(chapter => chapter.chapter_path === path && chapter.first_battle === !flags.includes(chapter.flag_key))
  if (!value) throw new Error('Unknown original campaign battle')
  return `campaign:${value.opponent_id}:${value.first_battle ? 'initial' : 'rematch'}`
}

export function originalBattleChapter(id: string): OriginalQuestBattleChapter {
  const value = id.startsWith('campaign:')
    ? campaign.chapters.find(chapter => id === `campaign:${chapter.opponent_id}:${chapter.first_battle ? 'initial' : 'rematch'}`)
    : originalQuestBattleChapters.find(chapter => chapter.opponent_id === id)
  if (!value) throw new Error(`Unknown original quest battle: ${id}`)
  return value as OriginalQuestBattleChapter
}

export function createOriginalQuestBattle(id: string, opponentHp: number): OriginalBattlePlayback {
  return createOriginalBattlePlayback(`outfit_${opponentHp}`, false, originalBattleChapter(id).traces)
}

export function nextOriginalQuestBattleCommand(id: string, state: OriginalBattlePlayback): BattleTraceCommand | undefined {
  return nextOriginalBattleCommand(state, originalBattleChapter(id).traces)
}

export function advanceOriginalQuestBattleCommand(id: string, state: OriginalBattlePlayback, result?: OriginalBattleResult): OriginalBattlePlayback {
  return advanceOriginalBattleCommand(state, result, originalBattleChapter(id).traces)
}
