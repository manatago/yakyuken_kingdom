import type { Card } from './card'
import { validateDeck } from './deck'
import { parseSave, type SaveData } from './save'

export const PREPARED_DECK_SIZE = 9

export function addDeckCard(inventory: readonly Card[], draft: readonly Card[], card: Card): Card[] {
  const next = [...draft, { ...card }]
  if (next.length > PREPARED_DECK_SIZE || !validateDeck(inventory, next, next.length).valid) {
    throw new Error('Card unavailable or lineup full')
  }
  return next
}

export function removeDeckCard(draft: readonly Card[], index: number): Card[] {
  if (!Number.isSafeInteger(index) || index < 0 || index >= draft.length) throw new RangeError('Invalid card index')
  return draft.filter((_, i) => i !== index).map((card) => ({ ...card }))
}

export function savePreparedDeck(save: SaveData, draft: readonly Card[]): SaveData {
  if (!validateDeck(save.player.inventory, draft, PREPARED_DECK_SIZE).valid) {
    throw new Error('Nine owned cards required')
  }
  return parseSave({ ...save, player: { ...save.player, prepared_deck: draft } })
}
