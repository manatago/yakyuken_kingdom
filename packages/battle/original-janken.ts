import { HANDS, GRADES, judgeCards, type Card, type BattleResult, type Hand } from '../domain/card'
import { applyProbabilityAdjustment, getItemDefinition, type ItemId } from '../domain/item-catalog'

export interface OriginalJankenRound {
  playerIndex: number; opponentIndex: number; player: Card; opponent: Card; result: BattleResult
  extraOpponent?: Card
  protectedCard?: true
}
export interface OriginalJanken {
  playerDeck: Card[]; opponentDeck: Card[]
  playerUsed: boolean[]; opponentUsed: boolean[]
  playerHp: number; opponentHp: number
  selection: number | null; rounds: OriginalJankenRound[]
}

/** BattleScene._run_battle's normal-battle termination order (not the tutorial's forced final win). */
export function originalMatildaOutcome(state: OriginalJanken): BattleResult | undefined {
  if (state.opponentHp <= 0) return 'win'
  if (state.playerHp <= 0) return 'lose'
  const playerEmpty = state.playerUsed.every(Boolean)
  const opponentEmpty = state.opponentUsed.every(Boolean)
  if (playerEmpty && opponentEmpty) return 'draw'
  if (playerEmpty) return 'lose'
  if (opponentEmpty) return 'win'
  return undefined
}

export function originalAutoDeckIndices(inventory: readonly Card[]): number[] {
  const byHand = HANDS.map(hand => inventory.map((card, index) => ({ card, index }))
    .filter(entry => entry.card.hand === hand).sort((a, b) => b.card.grade - a.card.grade))
  const indices: number[] = []
  for (let round = 0; indices.length < 9; round++) {
    const before = indices.length
    for (const cards of byHand) if (cards[round] && indices.length < 9) indices.push(cards[round].index)
    if (indices.length === before) break
  }
  return indices
}

/** Matilda's initial nine Normal cards, in the original chapter's order. */
export function createOriginalJanken(deck?: readonly Card[]): OriginalJanken {
  const defaults = HANDS.flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 as const })))
  const playerDeck = structuredClone(deck ? [...deck] : defaults)
  if (playerDeck.length !== 9 || playerDeck.some(card => !HANDS.includes(card.hand) || card.grade !== 1)) {
    throw new Error('Original Matilda tutorial requires nine Normal cards')
  }
  return createOriginalNormalJanken(playerDeck)
}

/** Normal Matilda battles use the player's chosen grades and the chapter's nine Normal opponent cards. */
export function createOriginalNormalJanken(deck: readonly Card[]): OriginalJanken {
  if (deck.length !== 9 || deck.some(card => !HANDS.includes(card.hand) || !GRADES.includes(card.grade))) {
    throw new Error('Original Matilda battle requires nine valid cards')
  }
  const playerDeck = structuredClone([...deck])
  const defaults = HANDS.flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 as const })))
  return createOriginalBattleCards(playerDeck, defaults, 3, 3)
}

export function createOriginalBattleCards(playerDeck: readonly Card[], opponentDeck: readonly Card[], playerHp: number, opponentHp: number): OriginalJanken {
  for (const deck of [playerDeck, opponentDeck]) {
    if (!Array.isArray(deck) || deck.length < 1 || deck.length > 9 || deck.some(card => !card || !HANDS.includes(card.hand) || !GRADES.includes(card.grade))) throw new Error('Invalid original battle deck')
  }
  if (![playerHp, opponentHp].every(hp => Number.isInteger(hp) && hp > 0 && hp <= 3)) throw new Error('Invalid original battle HP')
  return { playerDeck: structuredClone([...playerDeck]), opponentDeck: structuredClone([...opponentDeck]),
    playerUsed: Array(playerDeck.length).fill(false), opponentUsed: Array(opponentDeck.length).fill(false),
    playerHp, opponentHp, selection: null, rounds: [] }
}

export function selectOriginalCard(state: OriginalJanken, index: number): OriginalJanken {
  if (state.selection !== null || !Number.isInteger(index) || index < 0 ||
      index >= state.playerDeck.length || state.playerUsed[index]) throw new Error('Invalid original card selection')
  const next = structuredClone(state)
  next.selection = index
  next.playerUsed[index] = true
  return next
}

function refund(deck: Card[], used: boolean[], card: Card) {
  for (let index = deck.length - 1; index >= 0; index--) {
    if (used[index] && deck[index].hand === card.hand && deck[index].grade === card.grade) {
      used[index] = false
      break
    }
  }
}

function originalGradeProbabilities(player: Card, available: readonly Card[], tendency: Partial<Record<Hand, number>> = {}, item?: ItemId): Record<Hand, number> {
  let probability = Object.fromEntries(HANDS.map(hand => [hand, available.length
    ? available.filter(card => card.hand === hand).length / available.length
    : hand === 'paper' ? .34 : .33])) as Record<Hand, number>
  // Godot returns early for an exhausted opponent deck, before tendency adjustments.
  if (available.length && Object.keys(tendency).length) {
    for (const hand of HANDS) probability[hand] = Math.max(0, probability[hand] + (tendency[hand] ?? 0))
    const sum = HANDS.reduce((total, hand) => total + probability[hand], 0)
    if (sum > 0) for (const hand of HANDS) probability[hand] /= sum
  }
  const lose = { rock: 'scissors', scissors: 'paper', paper: 'rock' }[player.hand] as Hand
  const win = { rock: 'paper', scissors: 'rock', paper: 'scissors' }[player.hand] as Hand
  // The empty-deck return in get_bayes_probability also bypasses item adjustments.
  const definition = item ? getItemDefinition(item) : undefined
  if (available.length && definition?.effect === 'intimidate') probability = applyProbabilityAdjustment(probability, lose, .2)
  if (available.length && definition?.effect === 'adjust_probability') probability = applyProbabilityAdjustment(probability,
    definition.targetHand!, definition.probabilityDelta!)
  const boost = [0, 0, .05, .10, 0, .15][player.grade]
  const reduction = player.grade >= 4 ? .15 : 0
  // BattleScene applies Card.apply_grade_effect in get_bayes_probability and again in _pick_by_probability.
  // Its empty-deck early return skips the first application.
  for (let pass = 0; pass < (available.length ? 2 : 1); pass++) {
    if (boost > 0) {
      probability[lose] += boost
      const remaining = probability[win] + probability[player.hand]
      if (remaining > 0) {
        const ratio = (1 - probability[lose]) / remaining
        probability[win] *= ratio
        probability[player.hand] *= ratio
      }
    }
    if (reduction > 0) {
      probability[win] = Math.max(0, probability[win] - reduction)
      const remaining = probability[lose] + probability[player.hand]
      if (remaining > 0) {
        const ratio = (1 - probability[win]) / remaining
        probability[lose] *= ratio
        probability[player.hand] *= ratio
      }
    }
  }
  return probability
}

/** Port of BattleScene._pick_opponent_card / janken, including round effects. */
export function resolveOriginalJanken(state: OriginalJanken,
  options: { fixed?: Hand; win_rate?: number; tendency?: Partial<Record<Hand, number>>; item?: ItemId; doubleCapture?: boolean; captureRoll?: number }, roll: number): OriginalJanken {
  if (state.selection === null || !Number.isFinite(roll) || roll < 0 || roll >= 1) {
    throw new Error('Missing selection or invalid random roll')
  }
  const next = structuredClone(state)
  if (options.captureRoll !== undefined && (!Number.isFinite(options.captureRoll) || options.captureRoll < 0 || options.captureRoll >= 1)) throw new Error('Invalid extra capture roll')
  const playerIndex = state.selection
  const player = next.playerDeck[playerIndex]
  const available = next.opponentDeck.map((card, index) => ({ card, index })).filter(entry => !next.opponentUsed[entry.index])
  let target = options.fixed
  if (!target) {
    const probability = originalGradeProbabilities(player, available.map(entry => entry.card), options.tendency, options.item)
    let cumulative = 0
    for (const hand of HANDS) {
      cumulative += probability[hand]
      if (roll <= cumulative) { target = hand; break }
    }
  }
  const entry = available.find(entry => entry.card.hand === (target || 'rock')) || available[0]
  const opponent: Card = entry?.card || { hand: 'rock', grade: 1 }
  if (entry) next.opponentUsed[entry.index] = true
  const result = judgeCards(player, opponent)
  const effect = options.item ? getItemDefinition(options.item)?.effect : undefined
  let extraOpponent: Card | undefined
  if (result === 'win') {
    next.opponentHp--
    if (options.doubleCapture) {
      const remaining = available.filter(candidate => !next.opponentUsed[candidate.index])
      const extra = remaining[Math.floor((options.captureRoll ?? roll) * remaining.length)]
      if (extra) { next.opponentUsed[extra.index] = true; extraOpponent = structuredClone(extra.card) }
    }
  } else if (result === 'lose') { if (effect !== 'protect_hp') next.playerHp-- }
  else {
    refund(next.playerDeck, next.playerUsed, player)
    refund(next.opponentDeck, next.opponentUsed, opponent)
  }
  next.selection = null
  next.rounds.push({ playerIndex, opponentIndex: entry?.index ?? -1, player, opponent, result,
    ...(extraOpponent ? { extraOpponent } : {}), ...(result === 'lose' && effect === 'protect_card' ? { protectedCard: true as const } : {}) })
  return next
}
