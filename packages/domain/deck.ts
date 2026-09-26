import type { Card } from './card'

export type DeckValidation = { valid: true } | { valid: false; reason: 'size' | 'not_owned' }

function cardKey(card: Card): string {
  return `${card.hand}:${card.grade}`
}

export function validateDeck(
  inventory: readonly Card[],
  deck: readonly Card[],
  requiredSize: number
): DeckValidation {
  if (!Number.isSafeInteger(requiredSize) || requiredSize < 1 || deck.length !== requiredSize) {
    return { valid: false, reason: 'size' }
  }

  const available = new Map<string, number>()
  for (const card of inventory) {
    const key = cardKey(card)
    available.set(key, (available.get(key) ?? 0) + 1)
  }
  for (const card of deck) {
    const key = cardKey(card)
    const remaining = available.get(key) ?? 0
    if (remaining === 0) return { valid: false, reason: 'not_owned' }
    available.set(key, remaining - 1)
  }
  return { valid: true }
}
