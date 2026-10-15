import { getItemDefinition, isBattleUsable, type ItemId } from '../domain/item-catalog'
import type { Card, Hand } from '../domain/card'

export interface BattleItemSnapshot {
  readonly items_before?: readonly ItemId[]
  readonly round_item_ids?: readonly (ItemId | null)[]
}

export function battleItemAdjustment(itemId: ItemId | undefined, player: Card | undefined):
  { targetHand: Hand; delta: number } | undefined {
  if (!itemId) return undefined
  const item = getItemDefinition(itemId)
  if (item?.effect === 'adjust_probability' && item.targetHand && item.probabilityDelta !== undefined) {
    return { targetHand: item.targetHand, delta: item.probabilityDelta }
  }
  if (item?.effect === 'intimidate' && player) {
    const losesTo: Record<Hand, Hand> = { rock: 'scissors', scissors: 'paper', paper: 'rock' }
    return { targetHand: losesTo[player.hand], delta: .2 }
  }
  return undefined
}

export function validateBattleItemUsage(ledger: BattleItemSnapshot, roundsLength: number): boolean {
  const ids = ledger.round_item_ids ?? Array.from({ length: roundsLength }, () => null)
  const used = ids.filter((id): id is ItemId => id !== null)
  return ids.length === roundsLength && ids.every((id) => id === null ||
    !!getItemDefinition(id) && isBattleUsable(getItemDefinition(id)!)) &&
    used.every((id) => used.filter((candidate) => candidate === id).length <=
      (ledger.items_before ?? []).filter((owned) => owned === id).length)
}

export function assertBattleItemAvailable(ledger: BattleItemSnapshot, itemId: string | undefined): asserts itemId is ItemId | undefined {
  if (!itemId) return
  const item = getItemDefinition(itemId)
  const owned = (ledger.items_before ?? []).filter((id) => id === itemId).length
  const used = (ledger.round_item_ids ?? []).filter((id) => id === itemId).length
  if (!item || !isBattleUsable(item) || used >= owned) throw new Error('Selected battle item is unavailable')
}

export function appendBattleItem(ledger: BattleItemSnapshot, roundsLength: number, itemId: ItemId | undefined): (ItemId | null)[] {
  return [...(ledger.round_item_ids ?? Array.from({ length: roundsLength }, () => null)), itemId ?? null]
}

export function consumeBattleItems(snapshot: readonly ItemId[] | undefined,
  roundItemIds: readonly (ItemId | null)[] | undefined): ItemId[] | undefined {
  if (!snapshot) return undefined
  const items = [...snapshot]
  for (const itemId of roundItemIds ?? []) {
    if (!itemId) continue
    const index = items.indexOf(itemId)
    if (index < 0) throw new Error('Used battle item is not in the inventory snapshot')
    items.splice(index, 1)
  }
  return items
}
