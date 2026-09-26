import type { BattleResult, Card } from './card'

export interface PlayerCardState {
  readonly inventory: readonly Card[]
  readonly money: number
}

export interface BattlePayout {
  readonly cards: readonly Card[]
  readonly gold: number
  readonly canTransferCards: boolean
}

export function applyBattlePayout(
  state: PlayerCardState,
  result: BattleResult,
  payout: BattlePayout
): PlayerCardState {
  const inventory = state.inventory.map((card) => ({ ...card }))
  if (result === 'draw') return { inventory, money: state.money }

  if (result === 'win') {
    if (payout.canTransferCards) inventory.push(...payout.cards.map((card) => ({ ...card })))
    return { inventory, money: state.money + payout.gold }
  }

  if (payout.canTransferCards) {
    for (const card of payout.cards) {
      const index = inventory.findIndex(
        (owned) => owned.hand === card.hand && owned.grade === card.grade
      )
      if (index !== -1) inventory.splice(index, 1)
    }
  }
  return { inventory, money: Math.max(state.money - payout.gold, 0) }
}
