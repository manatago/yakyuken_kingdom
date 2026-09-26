export const HANDS = ['rock', 'scissors', 'paper'] as const
export type Hand = (typeof HANDS)[number]

export const GRADES = [1, 2, 3, 4, 5] as const
export type Grade = (typeof GRADES)[number]

export interface Card {
  readonly hand: Hand
  readonly grade: Grade
}

export type BattleResult = 'win' | 'lose' | 'draw'

const defeatedHand: Record<Hand, Hand> = {
  rock: 'scissors',
  scissors: 'paper',
  paper: 'rock'
}

export function judgeCards(player: Card, opponent: Card): BattleResult {
  if (player.hand === opponent.hand) {
    if (player.grade === opponent.grade) return 'draw'
    return player.grade > opponent.grade ? 'win' : 'lose'
  }
  return defeatedHand[player.hand] === opponent.hand ? 'win' : 'lose'
}
