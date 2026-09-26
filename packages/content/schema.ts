import type { Hand } from '../domain/card'

export interface AssetContent {
  id: string
  path: string
}

export interface LayoutContent {
  id: string
  x: number
  y: number
  scale: number
  flipped: boolean
}

export type BattleRule =
  | { kind: 'fixed_opponent_hand'; hand: Hand }
  | { kind: 'player_win_rate'; value: number }

export interface BattlePhase {
  id: string
  rules: BattleRule[]
}

export interface BattleContent {
  id: string
  opponent_id: string
  background_asset_id: string
  player_deck_size: number
  opponent_deck_size: number
  opponent_card_ids: string[]
  gold_reward: { min: number; max: number }
  transfer_cards: boolean
  phases: BattlePhase[]
}

export type StoryStep =
  | { id: string; kind: 'line'; speaker_id?: string; text: string; next_id: string }
  | { id: string; kind: 'background'; asset_id: string; next_id: string }
  | { id: string; kind: 'show_portrait'; slot_id: string; asset_id: string; layout_id: string; next_id: string }
  | { id: string; kind: 'hide_portrait'; slot_id: string; next_id: string }
  | { id: string; kind: 'choice'; options: { label: string; next_id: string }[] }
  | { id: string; kind: 'goto'; target_id: string }
  | { id: string; kind: 'battle'; battle_id: string; next_id: string }
  | { id: string; kind: 'end' }

export interface StoryContent {
  id: string
  start_id: string
  steps: StoryStep[]
}

export interface ContentPack {
  assets: AssetContent[]
  layouts: LayoutContent[]
  battles: BattleContent[]
  stories: StoryContent[]
}
