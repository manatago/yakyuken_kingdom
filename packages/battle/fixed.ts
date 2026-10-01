import document from '../../content/stories/matilda-normal.json'
import type { ContentPack, BattleContent } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { HANDS, judgeCards, type Card, type Hand, type BattleResult } from '../domain/card'
import { validateDeck } from '../domain/deck'
import type { SaveData } from '../domain/save'

export const fixedContent = document as ContentPack
export interface FixedLedger {
  readonly battle_id: string
  readonly player_deck: readonly Card[]
  readonly rounds: readonly { player_index: number; opponent_index: number }[]
  readonly acknowledged: number
  readonly settled: boolean
  readonly balance_before: number
  readonly gold_delta?: number
}

export function isFixedCheckpoint(id: string): boolean {
  return fixedContent.stories.some((story) => story.steps.some((step) => step.id === id &&
    (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end')))
}

function definition(save: SaveData): BattleContent & { hp: NonNullable<BattleContent['hp']> } {
  const battle = fixedContent.battles.find((entry) => entry.id === save.progress.fixed_battle?.battle_id)
  if (!battle?.hp) throw new Error('Unknown HP battle')
  return battle as BattleContent & { hp: NonNullable<BattleContent['hp']> }
}

export function opponents(battle: BattleContent): Card[] {
  return battle.opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown opponent card')
    return { hand: card.hand, grade: card.grade }
  })
}

// Preserve the actual Godot probability path, including its two grade-effect passes.
export function opponentProbabilities(remaining: readonly Card[], player: Card, passes: number,
  tendency: Partial<Record<Hand, number>> = {}): Record<Hand, number> {
  if (!remaining.length || !Number.isInteger(passes) || passes < 0 || passes > 2) throw new Error('Invalid probability input')
  const probability = Object.fromEntries(HANDS.map((hand) => [hand,
    remaining.filter((card) => card.hand === hand).length / remaining.length])) as Record<Hand, number>
  for (const hand of HANDS) probability[hand] = Math.max(0, probability[hand] + (tendency[hand] ?? 0))
  const total = HANDS.reduce((sum, hand) => sum + probability[hand], 0)
  if (total <= 0) throw new Error('Invalid opponent tendency')
  for (const hand of HANDS) probability[hand] /= total
  const loseHand: Record<Hand, Hand> = { rock: 'scissors', scissors: 'paper', paper: 'rock' }
  const winHand: Record<Hand, Hand> = { rock: 'paper', scissors: 'rock', paper: 'scissors' }
  const lose = loseHand[player.hand], win = winHand[player.hand], draw = player.hand
  const boost = [0, 0, .05, .10, 0, .15][player.grade]
  const reduction = player.grade >= 4 ? .15 : 0
  for (let i = 0; i < passes; i++) {
    if (boost > 0) {
      probability[lose] += boost
      const rest = probability[win] + probability[draw]
      if (rest > 0) {
        const ratio = (1 - probability[lose]) / rest
        probability[win] *= ratio; probability[draw] *= ratio
      }
    }
    if (reduction > 0) {
      probability[win] = Math.max(0, probability[win] - reduction)
      const rest = probability[lose] + probability[draw]
      if (rest > 0) {
        const ratio = (1 - probability[win]) / rest
        probability[lose] *= ratio; probability[draw] *= ratio
      }
    }
  }
  return probability
}

export function fixedView(save: SaveData) {
  const battle = definition(save), ledger = save.progress.fixed_battle!
  return replayFixedBattle(battle, ledger)
}

export function replayFixedBattle(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> }, ledger: FixedLedger) {
  const opponentDeck = opponents(battle)
  const usedPlayer: number[] = [], usedOpponent: number[] = []
  let playerHp = battle.hp.player, opponentHp = battle.hp.opponent
  let outcome: BattleResult | undefined
  let last: { player: Card; opponent: Card; result: BattleResult } | undefined
  for (const [index, round] of ledger.rounds.entries()) {
    const player = ledger.player_deck[round.player_index], opponent = opponentDeck[round.opponent_index]
    if (outcome || !Number.isSafeInteger(round.player_index) || !Number.isSafeInteger(round.opponent_index) ||
        !player || !opponent || usedPlayer.includes(round.player_index) || usedOpponent.includes(round.opponent_index)) {
      throw new Error('Invalid or reused battle card')
    }
    if (index === 0 && battle.hp.first_hand && opponent.hand !== battle.hp.first_hand) throw new Error('First hand mismatch')
    if (opponentDeck.findIndex((card, i) => !usedOpponent.includes(i) && card.hand === opponent.hand) !== round.opponent_index) {
      throw new Error('Opponent cards must be consumed in order')
    }
    const result = judgeCards(player, opponent)
    if (result !== 'draw') { usedPlayer.push(round.player_index); usedOpponent.push(round.opponent_index) }
    if (result === 'win') opponentHp--
    if (result === 'lose') playerHp--
    last = { player, opponent, result }
    if (opponentHp <= 0) outcome = 'win'
    else if (playerHp <= 0) outcome = 'lose'
    else if (usedPlayer.length === ledger.player_deck.length && usedOpponent.length === opponentDeck.length) outcome = 'draw'
    else if (usedPlayer.length === ledger.player_deck.length) outcome = 'lose'
    else if (usedOpponent.length === opponentDeck.length) outcome = 'win'
  }
  return { playerHp, opponentHp, usedPlayer, usedOpponent, outcome, last }
}

export function selectOpponent(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> },
  ledger: FixedLedger, playerIndex: number, roll: number): number {
  rollCheck(roll)
  const view = replayFixedBattle(battle, ledger), player = ledger.player_deck[playerIndex]
  if (view.outcome || !Number.isSafeInteger(playerIndex) || !player || view.usedPlayer.includes(playerIndex)) {
    throw new Error('Invalid battle selection')
  }
  const available = opponents(battle).map((card, index) => ({ card, index }))
    .filter((entry) => !view.usedOpponent.includes(entry.index))
  let hand = battle.hp.first_hand
  if (ledger.rounds.length > 0 || !hand) {
    const probability = opponentProbabilities(available.map((entry) => entry.card), player,
      battle.hp.grade_effect_passes, battle.opponent_tendency)
    let cumulative = 0
    hand = 'rock'
    for (const candidate of HANDS) {
      cumulative += probability[candidate]
      if (roll <= cumulative) { hand = candidate; break }
    }
  }
  return (available.find((entry) => entry.card.hand === hand) ?? available[0]).index
}

export function battleGoldDelta(battle: BattleContent & { hp: NonNullable<BattleContent['hp']> },
  outcome: BattleResult, balance: number, roll: number): number {
  rollCheck(roll)
  return outcome === 'win' ? battle.gold_reward.min + Math.floor(roll * (battle.gold_reward.max - battle.gold_reward.min + 1))
    : outcome === 'lose' ? -Math.min(balance, battle.hp.lose_gold) : 0
}

export function validateFixedState(save: SaveData): void {
  const ledger = save.progress.fixed_battle, checkpoint = save.progress.checkpoint_id
  const started = save.progress.flags.includes('matilda.normal.started')
  if (!ledger) {
    if (started || ['matilda.normal.complete', 'matilda.normal.end'].includes(checkpoint)) throw new Error('Missing fixed battle ledger')
    if (isFixedCheckpoint(checkpoint) && !save.progress.flags.includes('matilda.tutorial.completed')) throw new Error('Tutorial not complete')
    return
  }
  const battle = definition(save)
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.kind === 'battle' && step.battle_id === battle.id)
  if (!step || step.kind !== 'battle' || !started || !save.progress.flags.includes('matilda.tutorial.completed') ||
      !isFixedCheckpoint(checkpoint) || !validateDeck(save.player.inventory, ledger.player_deck, battle.player_deck_size).valid ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0) throw new Error('Invalid fixed battle progress')
  const view = fixedView(save)
  if (!ledger.settled) {
    if (checkpoint !== step.id || ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
        view.outcome && ledger.acknowledged === ledger.rounds.length) throw new Error('Unsettled checkpoint mismatch')
  } else {
    if (!view.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) throw new Error('Invalid settlement')
    const delta = ledger.gold_delta!
    if (view.outcome === 'win' && (delta < battle.gold_reward.min || delta > battle.gold_reward.max) ||
        view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
        view.outcome === 'draw' && delta !== 0 || save.player.money !== ledger.balance_before + delta ||
        ![step.id, step.next_id, 'matilda.normal.end'].includes(checkpoint)) throw new Error('Settlement mismatch')
  }
}

export function prepareFixedBattle(save: SaveData): SaveData {
  validateFixedState(save)
  if (save.progress.fixed_battle) throw new Error('Battle already started')
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.id === save.progress.checkpoint_id)
  if (step?.kind !== 'battle') throw new Error('Not at a battle checkpoint')
  const battle = fixedContent.battles.find((entry) => entry.id === step.battle_id)!
  const deck = save.player.prepared_deck ?? save.player.deck
  if (!validateDeck(save.player.inventory, deck, battle.player_deck_size).valid) throw new Error('Owned battle deck required')
  const next: SaveData = { ...save, progress: { ...save.progress,
    flags: [...save.progress.flags, 'matilda.normal.started'],
    fixed_battle: { battle_id: battle.id, player_deck: deck.map((card) => ({ ...card })),
      rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money }
  } }
  validateFixedState(next)
  return next
}

function rollCheck(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playFixedRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateFixedState(save); rollCheck(roll)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a card')
  const opponentIndex = selectOpponent(definition(save), ledger, playerIndex, roll)
  return { ...save, progress: { ...save.progress, fixed_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }] } } }
}

export function acknowledgeFixedRound(save: SaveData): SaveData {
  validateFixedState(save)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled || fixedView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No ongoing pending result')
  return { ...save, progress: { ...save.progress, fixed_battle: { ...ledger, acknowledged: ledger.rounds.length } } }
}

export function settleFixedBattle(save: SaveData, roll: number): SaveData {
  validateFixedState(save); rollCheck(roll)
  const ledger = save.progress.fixed_battle
  if (!ledger || ledger.settled) throw new Error('No terminal result to settle')
  const battle = definition(save), outcome = fixedView(save).outcome
  if (!outcome) throw new Error('No terminal result to settle')
  const delta = battleGoldDelta(battle, outcome, save.player.money, roll)
  if (!Number.isSafeInteger(save.player.money + delta)) throw new Error('Money overflow')
  return { ...save, player: { ...save.player, money: save.player.money + delta }, progress: { ...save.progress,
    fixed_battle: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } }
}

export function retryFixedBattle(save: SaveData): SaveData {
  validateFixedState(save)
  const ledger = save.progress.fixed_battle
  if (!ledger?.settled || fixedView(save).outcome !== 'lose' || save.progress.checkpoint_id !== 'matilda.normal.await') throw new Error('Not retrying a loss')
  const { fixed_battle: _ledger, ...progress } = save.progress
  return prepareFixedBattle({ ...save, progress: { ...progress, flags: progress.flags.filter((flag) => flag !== 'matilda.normal.started') } })
}

export function returnFromFixedBattle(save: SaveData): SaveData {
  validateFixedState(save)
  if (!save.progress.fixed_battle?.settled || save.progress.checkpoint_id !== 'matilda.normal.await') throw new Error('Battle not settled')
  const step = fixedContent.stories.flatMap((story) => story.steps).find((step) => step.kind === 'battle' && step.battle_id === save.progress.fixed_battle!.battle_id)!
  if (step.kind !== 'battle') throw new Error('Missing return checkpoint')
  return { ...save, progress: { ...save.progress, checkpoint_id: step.next_id } }
}
