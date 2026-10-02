import document from '../../content/stories/subevent1-jin.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { judgeCards, type Card, type Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData, type Subevent1BelkaLedger } from '../domain/save'
import { getItemDefinition, type ItemId } from '../domain/item-catalog'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent } from './fixed'

export const subevent1BelkaContent = document as ContentPack
export const SUBEVENT1_BELKA_CHECKPOINT = 'subevent1.belka.await'
export const SUBEVENT1_BELKA_BATTLE_ID = 'battle.subevent1.belka'
export const SUBEVENT1_BELKA_AFTER_CHECKPOINT = 'subevent1.belka.after'
const ORIGIN = 'matilda.normal.end'
const battle = subevent1BelkaContent.battles.find((entry) => entry.id === SUBEVENT1_BELKA_BATTLE_ID) as BattleContent & { hp: NonNullable<BattleContent['hp']> }

function opponentDeck(): Card[] {
  return battle.opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown Subevent 1 Belka card')
    return { hand: card.hand, grade: card.grade }
  })
}

function view(ledger: Subevent1BelkaLedger) { return replayFixedBattle(battle, ledger) }

export function subevent1BelkaView(save: SaveData) {
  const ledger = save.progress.subevent1_belka_battle
  if (!ledger) throw new Error('Subevent 1 Belka battle not started')
  return view(ledger)
}

export function subevent1BelkaProbabilities(save: SaveData, selected?: Card): Record<Hand, number> {
  const ledger = save.progress.subevent1_belka_battle
  if (!ledger) throw new Error('Subevent 1 Belka battle not started')
  const state = view(ledger)
  const remaining = opponentDeck().filter((_, index) => !state.usedOpponent.includes(index))
  if (!remaining.length) return { rock: 0, scissors: 0, paper: 0 }
  return opponentProbabilities(remaining, selected ?? { hand: 'rock', grade: 1 },
    selected ? battle.hp.grade_effect_passes : 0, battle.opponent_tendency)
}

function checkRoll(roll: number) {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

function settledInventory(ledger: Subevent1BelkaLedger, outcome: NonNullable<ReturnType<typeof view>['outcome']>): Card[] {
  const inventory = [...ledger.inventory_before]
  for (const round of ledger.rounds) {
    const player = ledger.player_deck[round.player_index]!, opponent = opponentDeck()[round.opponent_index]!
    const result = judgeCards(player, opponent)
    if (outcome === 'win' && result === 'win') inventory.push(opponent)
    if (outcome === 'lose' && result === 'lose') {
      const index = inventory.findIndex((card) => card.hand === player.hand && card.grade === player.grade)
      if (index < 0) throw new Error('Lost Belka card is not in inventory')
      inventory.splice(index, 1)
    }
  }
  return inventory
}

function settledItems(ledger: Subevent1BelkaLedger, outcome: NonNullable<ReturnType<typeof view>['outcome']>): ItemId[] {
  return outcome === 'win'
    ? [...ledger.items_before, ...(battle.item_reward_ids ?? []).filter((id) => !ledger.items_before.includes(id as ItemId)) as ItemId[]]
    : [...ledger.items_before]
}

export function startSubevent1Belka(save: SaveData): SaveData {
  parseSave(save)
  const checkpoint = save.progress.checkpoint_id
  const deck = save.player.prepared_deck ?? save.player.deck
  if (checkpoint !== 'subevent1.belka.challenge' || save.progress.subevent1_belka_battle ||
      !validateDeck(save.player.inventory, deck, battle.player_deck_size).valid) throw new Error('Nine owned cards required for Subevent 1 Belka')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: SUBEVENT1_BELKA_CHECKPOINT,
    subevent1_belka_battle: { battle_id: battle.id, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })),
      historical_deck: save.player.deck.map((card) => ({ ...card })), items_before: [...(save.player.items ?? [])],
      rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money } } })
}

export function playSubevent1BelkaRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateSubevent1BelkaState(save); checkRoll(roll)
  const ledger = save.progress.subevent1_belka_battle!
  if (ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Belka card')
  const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll)
  return parseSave({ ...save, progress: { ...save.progress, subevent1_belka_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }] } } })
}

export function acknowledgeSubevent1BelkaRound(save: SaveData): SaveData {
  validateSubevent1BelkaState(save)
  const ledger = save.progress.subevent1_belka_battle!
  if (ledger.settled || view(ledger).outcome || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No pending Belka result')
  return parseSave({ ...save, progress: { ...save.progress, subevent1_belka_battle: { ...ledger, acknowledged: ledger.rounds.length } } })
}

export function settleSubevent1Belka(save: SaveData, roll: number): SaveData {
  validateSubevent1BelkaState(save); checkRoll(roll)
  const ledger = save.progress.subevent1_belka_battle!, state = view(ledger), outcome = state.outcome
  if (ledger.settled || !outcome) throw new Error('No terminal Belka result')
  const delta = battleGoldDelta(battle, outcome, ledger.balance_before, roll)
  if (!Number.isSafeInteger(save.player.money + delta)) throw new Error('Money overflow')
  const inventory = settledInventory(ledger, outcome)
  const items = settledItems(ledger, outcome)
  const counts = new Map<string, number>()
  for (const card of inventory) { const key = `${card.hand}:${card.grade}`; counts.set(key, (counts.get(key) ?? 0) + 1) }
  const deck = save.player.deck.filter((card) => {
    const key = `${card.hand}:${card.grade}`, count = counts.get(key) ?? 0
    if (!count) return false
    counts.set(key, count - 1)
    return true
  })
  const prepared = save.player.prepared_deck
  const { prepared_deck: _prepared, ...player } = save.player
  return parseSave({ ...save, player: { ...player, inventory, deck, items, money: save.player.money + delta,
    ...(prepared && validateDeck(inventory, prepared, 9).valid ? { prepared_deck: prepared } : {}) },
    progress: { ...save.progress, subevent1_belka_battle: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } })
}

export function continueSubevent1Belka(save: SaveData): SaveData {
  validateSubevent1BelkaState(save)
  const ledger = save.progress.subevent1_belka_battle!
  if (!ledger.settled || view(ledger).outcome !== 'win' || save.progress.checkpoint_id !== SUBEVENT1_BELKA_CHECKPOINT) {
    throw new Error('Subevent 1 Belka victory is not ready to continue')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_BELKA_AFTER_CHECKPOINT } })
}

export function returnSubevent1BelkaToGuild(save: SaveData): SaveData {
  validateSubevent1BelkaState(save)
  const ledger = save.progress.subevent1_belka_battle
  const won = save.progress.checkpoint_id === 'subevent1.belka.end' && ledger?.settled && view(ledger).outcome === 'win'
  const lost = save.progress.checkpoint_id === SUBEVENT1_BELKA_CHECKPOINT && ledger?.settled && view(ledger).outcome !== 'win'
  if (!won && !lost) throw new Error('Subevent 1 Belka encounter is not complete')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: ORIGIN } })
}

export function validateSubevent1BelkaState(save: SaveData): void {
  const ledger = save.progress.subevent1_belka_battle, checkpoint = save.progress.checkpoint_id
  const active = checkpoint === SUBEVENT1_BELKA_CHECKPOINT
  if (!ledger) {
    if (active || checkpoint === SUBEVENT1_BELKA_AFTER_CHECKPOINT || checkpoint === 'subevent1.belka.end') throw new Error('Missing Subevent 1 Belka ledger')
    return
  }
  if (ledger.battle_id !== battle.id || !validateDeck(ledger.inventory_before, ledger.player_deck, battle.player_deck_size).valid ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0 ||
      !ledger.items_before.every((id) => !!getItemDefinition(id))) throw new Error('Invalid Subevent 1 Belka ledger')
  const state = view(ledger)
  if (!ledger.settled) {
    if (!active || ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
        JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) ||
        JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before) || state.outcome && ledger.acknowledged === ledger.rounds.length) {
      throw new Error('Unsettled Subevent 1 Belka checkpoint mismatch')
    }
    return
  }
  if (!state.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) throw new Error('Invalid Subevent 1 Belka settlement')
  if (state.outcome === 'win' && (ledger.gold_delta! < battle.gold_reward.min || ledger.gold_delta! > battle.gold_reward.max) ||
      state.outcome === 'lose' && ledger.gold_delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
      state.outcome === 'draw' && ledger.gold_delta !== 0 || ![SUBEVENT1_BELKA_CHECKPOINT, SUBEVENT1_BELKA_AFTER_CHECKPOINT,
        'subevent1.belka.report', 'subevent1.belka.end', GUILD_CHECKPOINT].includes(checkpoint) ||
      save.player.money !== ledger.balance_before + ledger.gold_delta! ||
      JSON.stringify(save.player.inventory) !== JSON.stringify(settledInventory(ledger, state.outcome)) ||
      JSON.stringify(save.player.items ?? []) !== JSON.stringify(settledItems(ledger, state.outcome))) {
    throw new Error('Invalid Subevent 1 Belka settlement')
  }
}
