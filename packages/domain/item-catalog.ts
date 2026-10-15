export type ItemCategory = 'consumable' | 'equipment'
export type ItemEffect =
  | 'protect_card' | 'protect_hp' | 'intimidate' | 'adjust_probability'
  | 'rank_up' | 'escape' | 'double_capture' | 'gold_bonus'
  | 'rare_encounter' | 'crystal_fragment'
export type Hand = 'rock' | 'scissors' | 'paper'

export interface ItemDefinition {
  readonly id: string
  readonly name: string
  readonly description: string
  readonly category: ItemCategory
  readonly effect: ItemEffect
  readonly battleUsable?: boolean
  readonly targetHand?: Hand
  readonly probabilityDelta?: number
  readonly goldBonusAmount?: number
}

const hands = (hand: Hand, attract: string, sealId: string, sealName: string, symbol: string) => [
  { id: `${hand}_attract_white`, name: `${attract}・白紋`, description: `相手が${symbol}を出す確率+5%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: 0.05 },
  { id: `${hand}_attract_crimson`, name: `${attract}・朱紋`, description: `相手が${symbol}を出す確率+10%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: 0.10 },
  { id: `${hand}_attract_gold`, name: `${attract}・金紋`, description: `相手が${symbol}を出す確率+15%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: 0.15 },
  { id: `${sealId}_white`, name: `${sealName}・白紋`, description: `相手が${symbol}を出す確率-5%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: -0.05 },
  { id: `${sealId}_crimson`, name: `${sealName}・朱紋`, description: `相手が${symbol}を出す確率-10%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: -0.10 },
  { id: `${sealId}_gold`, name: `${sealName}・金紋`, description: `相手が${symbol}を出す確率-15%（1回）`, category: 'consumable', effect: 'adjust_probability', targetHand: hand, probabilityDelta: -0.15 },
] as const

export const ITEM_CATALOG = [
  { id: 'substitute_card', name: '身代わりカード', description: '負けてもカードを取られない（1回）', category: 'consumable', effect: 'protect_card', battleUsable: true },
  { id: 'iron_shield', name: '鉄の盾', description: '負けてもHPが減らない（1回）', category: 'consumable', effect: 'protect_hp', battleUsable: true },
  { id: 'intimidation', name: '威圧の札', description: '相手が負ける手の確率+20%（1回）', category: 'consumable', effect: 'intimidate', battleUsable: true },
  ...hands('rock', '岩寄せの玉', 'rock_break', '岩砕きの札', 'グー'),
  ...hands('scissors', '刃招きの珠', 'scissors_dull', '刃鈍りの符', 'チョキ'),
  ...hands('paper', '紙招きの毬', 'paper_seal', '紙封じの栞', 'パー'),
  { id: 'rank_up_talisman', name: '格上げの札', description: '選んだカードの格を上げる（効果調整中）', category: 'consumable', effect: 'rank_up', battleUsable: false },
  { id: 'smoke_bomb', name: '逃げ足の煙玉', description: '戦闘から離脱する（効果調整中）', category: 'consumable', effect: 'escape', battleUsable: false },
  { id: 'greed_ring', name: '強欲の指輪', description: '勝利時にカードを2枚取得', category: 'equipment', effect: 'double_capture', battleUsable: false },
  { id: 'gold_charm', name: '金運のお守り', description: 'バトル勝利時にゴールドを20追加で獲得', category: 'equipment', effect: 'gold_bonus', battleUsable: false, goldBonusAmount: 20 },
  { id: 'rare_find_pendant', name: '掘り出し物のペンダント', description: '珍しい相手を見つけやすくなる（効果調整中）', category: 'equipment', effect: 'rare_encounter', battleUsable: false },
  { id: 'crystal_fragment', name: '水晶の破片', description: '砕けた真言の水晶球の欠片（効果調整中）', category: 'equipment', effect: 'crystal_fragment', battleUsable: false },
  { id: 'rank_up_bracelet', name: '昇格の腕輪', description: 'バトル中1回、カードのグレードを1段上げる（毎バトルリセット）', category: 'equipment', effect: 'rank_up', battleUsable: false },
] as const satisfies readonly ItemDefinition[]

export type ItemId = (typeof ITEM_CATALOG)[number]['id']

const definitions = new Map<string, ItemDefinition>(ITEM_CATALOG.map((item) => [item.id, item]))

export function getItemDefinition(id: string): ItemDefinition | undefined {
  return definitions.get(id)
}

export function isBattleUsable(item: ItemDefinition): boolean {
  return item.battleUsable ?? item.category === 'consumable'
}

export function applyProbabilityAdjustment(
  probabilities: Readonly<Record<Hand, number>>,
  targetHand: Hand,
  delta: number,
): Record<Hand, number> {
  const oldValue = probabilities[targetHand]
  const newValue = Math.max(0, Math.min(1, oldValue + delta))
  const remainingOld = 1 - oldValue
  const ratio = remainingOld > 0 ? (1 - newValue) / remainingOld : 1
  return {
    rock: targetHand === 'rock' ? newValue : probabilities.rock * ratio,
    scissors: targetHand === 'scissors' ? newValue : probabilities.scissors * ratio,
    paper: targetHand === 'paper' ? newValue : probabilities.paper * ratio,
  }
}

export function getCaptureCount(equipment: readonly Pick<ItemDefinition, 'id'>[]): number {
  return equipment.some((item) => item.id === 'greed_ring') ? 2 : 1
}

export function getGoldBonus(equipment: readonly Pick<ItemDefinition, 'id'>[]): number {
  return equipment.some((item) => item.id === 'gold_charm') ? 20 : 0
}
