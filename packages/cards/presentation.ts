import type { Card } from '../domain/card'
import { getCardDefinition, getCardId } from '../domain/card-catalog'

export const COMPACT_CROP = { x: 124, y: 250, width: 600, height: 900, sourceWidth: 848, sourceHeight: 1264 } as const
const hands = { rock: 'グー', scissors: 'チョキ', paper: 'パー' } as const
const grades = { 1: 'N', 2: 'B', 3: 'S', 4: 'G', 5: 'P' } as const

export function cardPresentation(card: Card) {
  const definition = getCardDefinition(getCardId(card))
  if (!definition) throw new Error('Unknown card')
  return { ...definition, handLabel: hands[card.hand], gradeLabel: grades[card.grade] }
}
