import rawCatalog from '../../content/catalog/cards.json'
import { GRADES, HANDS, type Card, type Grade, type Hand } from './card'

export interface CardDefinition extends Card {
  readonly id: string
  readonly imagePath: string
}

const gradeSuffix: Record<Grade, string> = {
  1: 'normal',
  2: 'bronze',
  3: 'silver',
  4: 'gold',
  5: 'platinum'
}

export function getCardId(card: Card): string {
  return `${card.hand}_${gradeSuffix[card.grade]}`
}

function isHand(value: string): value is Hand {
  return HANDS.includes(value as Hand)
}

function isGrade(value: number): value is Grade {
  return GRADES.includes(value as Grade)
}

export const CARD_CATALOG: readonly CardDefinition[] = rawCatalog.map((entry) => {
  if (!isHand(entry.hand) || !isGrade(entry.grade) || entry.id !== getCardId(entry as Card)) {
    throw new Error(`Invalid card catalog entry: ${entry.id}`)
  }
  return entry as CardDefinition
})

const definitions = new Map(CARD_CATALOG.map((entry) => [entry.id, entry]))

export function getCardDefinition(id: string): CardDefinition | undefined {
  return definitions.get(id)
}
