import data from '../../content/stories/belka-verification.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import type { Card, Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { getGoldBonus, type ItemId } from '../domain/item-catalog'
import { appendBattleItem, assertBattleItemAvailable, battleItemAdjustment, consumeBattleItems, validateBattleItemUsage } from './items'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent, type FixedLedger } from './fixed'

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
  return replayFixedBattle(battle, ledger)
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
  if (!validateBattleItemUsage(ledger, ledger.rounds.length)) throw new Error('Invalid Belka battle item use')
  if (!ledger.settled && (JSON.stringify(save.player.equipment ?? []) !== JSON.stringify(ledger.equipment_before ?? []) ||
      ledger.items_before && JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before))) throw new Error('Belka equipment or items changed during battle')
  const view = replay(ledger)
  if (!ledger.settled) {
    if (checkpoint !== BELKA_CHECKPOINT || save.progress.guild_return_checkpoint !== undefined ||
      ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
      ledger.items_before && JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before) ||
      view.outcome && ledger.acknowledged === ledger.rounds.length) throw new Error('Unsettled Belka checkpoint mismatch')
  } else {
    if (!view.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) {
      throw new Error('Invalid Belka settlement')
    }
    const delta = ledger.gold_delta!
    const bonus = view.outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0
    if (view.outcome === 'win' && (delta < battle.gold_reward.min + bonus || delta > battle.gold_reward.max + bonus) ||
      view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
      view.outcome === 'draw' && delta !== 0 || save.player.money !== ledger.balance_before + delta ||
      ![BELKA_CHECKPOINT, GUILD_CHECKPOINT, ORIGIN].includes(checkpoint) ||
      checkpoint === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint !== ORIGIN) throw new Error('Invalid Belka settlement route')
    if (checkpoint === BELKA_CHECKPOINT && JSON.stringify(save.player.equipment ?? []) === JSON.stringify(ledger.equipment_before ?? []) &&
        JSON.stringify(save.player.items ?? []) !==
        JSON.stringify(consumeBattleItems(ledger.items_before, ledger.round_item_ids) ?? save.player.items ?? [])) {
      throw new Error('Invalid Belka item settlement')
    }
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
      rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money,
      equipment_before: [...(save.player.equipment ?? [])], items_before: [...(save.player.items ?? [])], round_item_ids: [] } } })
}

function rollCheck(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playBelkaRound(save: SaveData, playerIndex: number, roll: number, itemId?: string): SaveData {
  validateBelkaState(save); rollCheck(roll)
  const ledger = save.progress.belka_battle
  if (!ledger || ledger.settled || save.progress.checkpoint_id !== BELKA_CHECKPOINT ||
    ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Belka card')
  const selected = itemId === undefined ? undefined : itemId as ItemId
  assertBattleItemAvailable(ledger, selected)
  const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll, battleItemAdjustment(selected, ledger.player_deck[playerIndex]))
  return { ...save, progress: { ...save.progress, belka_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }],
    round_item_ids: appendBattleItem(ledger, ledger.rounds.length, selected) } } }
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
  const delta = battleGoldDelta(battle, outcome, ledger.balance_before, roll) +
    (outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0)
  if (!Number.isSafeInteger(save.player.money + delta)) throw new Error('Money overflow')
  const items = consumeBattleItems(ledger.items_before, ledger.round_item_ids)
  return { ...save, player: { ...save.player, money: save.player.money + delta, ...(items !== undefined ? { items } : {}) }, progress: { ...save.progress,
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
