import data from '../../content/stories/belka-verification.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { HANDS, judgeCards, type BattleResult, type Card, type Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { opponentProbabilities, type FixedLedger } from './fixed'

export const belkaContent = data as ContentPack
export const BELKA_CHECKPOINT = 'belka.await'
const ORIGIN = 'matilda.normal.end'
const battle = belkaContent.battles[0] as BattleContent & { hp: NonNullable<BattleContent['hp']> }

export interface BelkaLedger extends FixedLedger {
  readonly origin_checkpoint: typeof ORIGIN
}

export function canStartBelka(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    save.progress.guild_return_checkpoint === ORIGIN && !save.progress.belka_battle
}

function opponentDeck(): Card[] {
  return battle.opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown Belka card')
    return { hand: card.hand, grade: card.grade }
  })
}

function replay(ledger: BelkaLedger) {
  const opponents = opponentDeck()
  const usedPlayer: number[] = [], usedOpponent: number[] = []
  let playerHp = battle.hp.player, opponentHp = battle.hp.opponent
  let outcome: BattleResult | undefined
  let last: { player: Card; opponent: Card; result: BattleResult } | undefined
  for (const round of ledger.rounds) {
    const player = ledger.player_deck[round.player_index], opponent = opponents[round.opponent_index]
    if (outcome || !Number.isSafeInteger(round.player_index) || !Number.isSafeInteger(round.opponent_index) ||
      !player || !opponent || usedPlayer.includes(round.player_index) || usedOpponent.includes(round.opponent_index)) {
      throw new Error('Invalid Belka round')
    }
    const first = opponents.findIndex((card, index) => !usedOpponent.includes(index) && card.hand === opponent.hand)
    if (first !== round.opponent_index) throw new Error('Belka cards must be consumed in order')
    const result = judgeCards(player, opponent)
    if (result !== 'draw') { usedPlayer.push(round.player_index); usedOpponent.push(round.opponent_index) }
    if (result === 'win') opponentHp--
    if (result === 'lose') playerHp--
    last = { player, opponent, result }
    if (opponentHp <= 0) outcome = 'win'
    else if (playerHp <= 0) outcome = 'lose'
    else if (usedPlayer.length === ledger.player_deck.length && usedOpponent.length === opponents.length) outcome = 'draw'
    else if (usedPlayer.length === ledger.player_deck.length) outcome = 'lose'
    else if (usedOpponent.length === opponents.length) outcome = 'win'
  }
  return { playerHp, opponentHp, usedPlayer, usedOpponent, outcome, last }
}

export function belkaView(save: SaveData) {
  if (!save.progress.belka_battle) throw new Error('Belka battle not started')
  return replay(save.progress.belka_battle)
}

function probabilities(save: SaveData, selected: Card | undefined, gradePasses: number): Record<Hand, number> {
  const view = belkaView(save)
  const remaining = opponentDeck().filter((_, index) => !view.usedOpponent.includes(index))
  if (!remaining.length) return { rock: 0, scissors: 0, paper: 0 }
  return opponentProbabilities(remaining, selected ?? { hand: 'rock', grade: 1 },
    selected ? gradePasses : 0, battle.opponent_tendency)
}

export function belkaProbabilities(save: SaveData, selected?: Card): Record<Hand, number> {
  return probabilities(save, selected, battle.hp.grade_effect_passes)
}

export function belkaBayesProbabilities(save: SaveData, selected?: Card): Record<Hand, number> {
  return probabilities(save, selected, 1)
}

export function validateBelkaState(save: SaveData): void {
  const ledger = save.progress.belka_battle, checkpoint = save.progress.checkpoint_id
  if (!ledger) {
    if (checkpoint === BELKA_CHECKPOINT) throw new Error('Missing Belka ledger')
    return
  }
  if (ledger.battle_id !== battle.id || ledger.origin_checkpoint !== ORIGIN ||
    !save.progress.fixed_battle?.settled || !validateDeck(save.player.inventory, ledger.player_deck, battle.player_deck_size).valid ||
    !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
    ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
    !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0) throw new Error('Invalid Belka ledger')
  const view = replay(ledger)
  if (!ledger.settled) {
    if (checkpoint !== BELKA_CHECKPOINT || save.progress.guild_return_checkpoint !== undefined ||
      ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
      view.outcome && ledger.acknowledged === ledger.rounds.length) throw new Error('Unsettled Belka checkpoint mismatch')
  } else {
    if (!view.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) {
      throw new Error('Invalid Belka settlement')
    }
    const delta = ledger.gold_delta!
    if (view.outcome === 'win' && (delta < battle.gold_reward.min || delta > battle.gold_reward.max) ||
      view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
      view.outcome === 'draw' && delta !== 0 || save.player.money !== ledger.balance_before + delta ||
      ![BELKA_CHECKPOINT, GUILD_CHECKPOINT, ORIGIN].includes(checkpoint) ||
      checkpoint === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint !== ORIGIN) throw new Error('Invalid Belka settlement route')
  }
}

export function startBelka(save: SaveData): SaveData {
  parseSave(save)
  if (!canStartBelka(save)) throw new Error('Belka verification requires a completed normal battle at guild home')
  const deck = save.player.prepared_deck ?? save.player.deck
  if (!validateDeck(save.player.inventory, deck, battle.player_deck_size).valid) throw new Error('Owned Belka deck required')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: BELKA_CHECKPOINT,
    belka_battle: { battle_id: battle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money } } })
}

function rollCheck(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playBelkaRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateBelkaState(save); rollCheck(roll)
  const ledger = save.progress.belka_battle
  if (!ledger || ledger.settled || save.progress.checkpoint_id !== BELKA_CHECKPOINT ||
    ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Belka card')
  const view = replay(ledger), player = ledger.player_deck[playerIndex]
  if (view.outcome || !Number.isSafeInteger(playerIndex) || !player || view.usedPlayer.includes(playerIndex)) {
    throw new Error('Invalid Belka selection')
  }
  const probabilities = belkaProbabilities(save, player)
  let cumulative = 0, hand: Hand = 'rock'
  for (const candidate of HANDS) {
    cumulative += probabilities[candidate]
    if (roll <= cumulative) { hand = candidate; break }
  }
  const opponents = opponentDeck()
  const available = opponents.map((card, index) => ({ card, index })).filter(({ index }) => !view.usedOpponent.includes(index))
  const opponentIndex = (available.find(({ card }) => card.hand === hand) ?? available[0]).index
  return { ...save, progress: { ...save.progress, belka_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }] } } }
}

export function acknowledgeBelkaRound(save: SaveData): SaveData {
  validateBelkaState(save)
  const ledger = save.progress.belka_battle
  if (!ledger || ledger.settled || belkaView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) {
    throw new Error('No pending Belka result')
  }
  return { ...save, progress: { ...save.progress, belka_battle: { ...ledger, acknowledged: ledger.rounds.length } } }
}

export function settleBelka(save: SaveData, roll: number): SaveData {
  validateBelkaState(save); rollCheck(roll)
  const ledger = save.progress.belka_battle
  const outcome = belkaView(save).outcome
  if (!ledger || ledger.settled || !outcome) throw new Error('No terminal Belka result')
  const delta = outcome === 'win' ? battle.gold_reward.min + Math.floor(roll * (battle.gold_reward.max - battle.gold_reward.min + 1))
    : outcome === 'lose' ? -Math.min(save.player.money, battle.hp.lose_gold) : 0
  if (!Number.isSafeInteger(save.player.money + delta)) throw new Error('Money overflow')
  return { ...save, player: { ...save.player, money: save.player.money + delta }, progress: { ...save.progress,
    belka_battle: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } }
}

export function returnBelkaToGuild(save: SaveData): SaveData {
  validateBelkaState(save)
  if (save.progress.checkpoint_id !== BELKA_CHECKPOINT || !save.progress.belka_battle?.settled) {
    throw new Error('Belka result not settled')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT,
    guild_return_checkpoint: ORIGIN } })
}
