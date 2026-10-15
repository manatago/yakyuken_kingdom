import document from '../../content/stories/subevent1-jin.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import { judgeCards, type Card, type Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData, type Subevent1BelkaLedger } from '../domain/save'
import { getCaptureCount, getGoldBonus, getItemDefinition, type ItemId } from '../domain/item-catalog'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent } from './fixed'
import { PROGRESSION_FLAGS } from '../domain/progression'
import { appendBattleItem, assertBattleItemAvailable, battleItemAdjustment, consumeBattleItems, validateBattleItemUsage } from './items'

export const subevent1BelkaContent = document as ContentPack
export const SUBEVENT1_BELKA_CHECKPOINT = 'subevent1.belka.await'
export const SUBEVENT1_BELKA_BATTLE_ID = 'battle.subevent1.belka'
export const SUBEVENT1_BELKA_AFTER_CHECKPOINT = 'subevent1.belka.after'
export const SUBEVENT1_BELKA_REPORT_CHECKPOINT = 'subevent1.belka.report'
export const SUBEVENT1_BELKA_END_CHECKPOINT = 'subevent1.belka.end'
const victoryStoryCheckpoints = [
  SUBEVENT1_BELKA_AFTER_CHECKPOINT,
  'subevent1.belka.disband',
  'subevent1.belka.guard-arrives',
  'subevent1.belka.guard-recognizes',
  'subevent1.belka.guard-report',
  SUBEVENT1_BELKA_REPORT_CHECKPOINT
]
const settledVictoryCheckpoints = [SUBEVENT1_BELKA_REPORT_CHECKPOINT, 'subevent1.belka.reception-records',
  'subevent1.belka.reception-response', 'subevent1.belka.reception-close', SUBEVENT1_BELKA_END_CHECKPOINT]
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
  for (const [index, round] of ledger.rounds.entries()) {
    const player = ledger.player_deck[round.player_index]!, opponent = opponentDeck()[round.opponent_index]!
    const result = judgeCards(player, opponent)
    if (outcome === 'win' && result === 'win') {
      inventory.push(opponent)
      if (round.bonus_capture_index !== undefined) inventory.push(opponentDeck()[round.bonus_capture_index]!)
    }
    if (outcome === 'lose' && result === 'lose' &&
        getItemDefinition(ledger.round_item_ids?.[index] ?? '')?.effect !== 'protect_card') {
      const index = inventory.findIndex((card) => card.hand === player.hand && card.grade === player.grade)
      if (index < 0) throw new Error('Lost Belka card is not in inventory')
      inventory.splice(index, 1)
    }
  }
  return inventory
}

function settledItems(ledger: Subevent1BelkaLedger, outcome: NonNullable<ReturnType<typeof view>['outcome']>): ItemId[] {
  const afterUse = consumeBattleItems(ledger.items_before, ledger.round_item_ids) ?? [...ledger.items_before]
  const rewards = ledger.item_rewards ?? battle.item_reward_ids ?? []
  return outcome === 'win'
    ? [...afterUse, ...rewards.filter((id) => !afterUse.includes(id as ItemId)) as ItemId[]]
    : afterUse
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
      item_rewards: [...(battle.item_reward_ids ?? [])], card_reward: battle.card_reward ? { ...battle.card_reward } : null,
      rounds: [], round_item_ids: [], acknowledged: 0, settled: false, balance_before: save.player.money,
      equipment_before: [...(save.player.equipment ?? [])],
      capture_bonus_enabled: battle.transfer_cards && getCaptureCount((save.player.equipment ?? []).map((id) => ({ id }))) > 1 } } })
}

export function playSubevent1BelkaRound(save: SaveData, playerIndex: number, roll: number, itemId?: string, bonusRoll = 0.5): SaveData {
  validateSubevent1BelkaState(save); checkRoll(roll)
  const ledger = save.progress.subevent1_belka_battle!
  if (ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Belka card')
  const selected = itemId === undefined ? undefined : itemId as ItemId
  assertBattleItemAvailable(ledger, selected)
  const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll,
    battleItemAdjustment(selected, ledger.player_deck[playerIndex]))
  const before = view(ledger)
  const won = judgeCards(ledger.player_deck[playerIndex]!, opponentDeck()[opponentIndex]!) === 'win'
  let bonusCaptureIndex: number | undefined
  if (won && ledger.capture_bonus_enabled) {
    checkRoll(bonusRoll)
    const candidates = opponentDeck().map((_, index) => index)
      .filter((index) => !before.usedOpponent.includes(index) && index !== opponentIndex)
    if (candidates.length) bonusCaptureIndex = candidates[Math.floor(bonusRoll * candidates.length)]
  }
  return parseSave({ ...save, progress: { ...save.progress, subevent1_belka_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex,
      ...(bonusCaptureIndex !== undefined ? { bonus_capture_index: bonusCaptureIndex } : {}) }],
    round_item_ids: appendBattleItem(ledger, ledger.rounds.length, selected) } } })
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
  if (outcome === 'win' ? save.progress.checkpoint_id !== SUBEVENT1_BELKA_REPORT_CHECKPOINT
    : save.progress.checkpoint_id !== SUBEVENT1_BELKA_CHECKPOINT) {
    throw new Error('Belka battle settlement is not at its designated checkpoint')
  }
  const delta = battleGoldDelta(battle, outcome, ledger.balance_before, roll) +
    (outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0)
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
  if (view(ledger).outcome !== 'win' || save.progress.checkpoint_id !== SUBEVENT1_BELKA_CHECKPOINT ||
      (ledger.rounds.length !== ledger.acknowledged + 1 && !(ledger.settled && ledger.rounds.length === ledger.acknowledged))) {
    throw new Error('Subevent 1 Belka victory is not ready to continue')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_BELKA_AFTER_CHECKPOINT,
    subevent1_belka_battle: { ...ledger, acknowledged: ledger.rounds.length } } })
}

export function returnSubevent1BelkaToGuild(save: SaveData): SaveData {
  validateSubevent1BelkaState(save)
  const ledger = save.progress.subevent1_belka_battle
  const won = save.progress.checkpoint_id === SUBEVENT1_BELKA_END_CHECKPOINT && ledger?.settled && view(ledger).outcome === 'win'
  const lost = save.progress.checkpoint_id === SUBEVENT1_BELKA_CHECKPOINT && ledger?.settled && view(ledger).outcome !== 'win'
  if (!won && !lost) throw new Error('Subevent 1 Belka encounter is not complete')
  const flags = won && !save.progress.flags.includes(PROGRESSION_FLAGS.subevent1Cleared)
    ? [...save.progress.flags, PROGRESSION_FLAGS.subevent1Cleared] : save.progress.flags
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT,
    guild_return_checkpoint: ORIGIN, flags } })
}

export function validateSubevent1BelkaState(save: SaveData): void {
  const ledger = save.progress.subevent1_belka_battle, checkpoint = save.progress.checkpoint_id
  const active = checkpoint === SUBEVENT1_BELKA_CHECKPOINT
  if (!ledger) {
    if (active || checkpoint === SUBEVENT1_BELKA_AFTER_CHECKPOINT || checkpoint === SUBEVENT1_BELKA_END_CHECKPOINT) throw new Error('Missing Subevent 1 Belka ledger')
    return
  }
  if (ledger.battle_id !== battle.id || !validateDeck(ledger.inventory_before, ledger.player_deck, battle.player_deck_size).valid ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0 ||
      !validateBattleItemUsage(ledger, ledger.rounds.length) ||
      !ledger.settled && JSON.stringify(save.player.equipment ?? []) !== JSON.stringify(ledger.equipment_before ?? []) ||
      !ledger.items_before.every((id) => !!getItemDefinition(id))) throw new Error('Invalid Subevent 1 Belka ledger')
  if (ledger.capture_bonus_enabled !== undefined && ledger.capture_bonus_enabled !==
      (battle.transfer_cards && getCaptureCount((ledger.equipment_before ?? []).map((id) => ({ id }))) > 1)) {
    throw new Error('Invalid Subevent 1 Belka Greed Ring snapshot')
  }
  const state = view(ledger)
  if (!ledger.settled) {
    const victoryStory = state.outcome === 'win' && ledger.acknowledged === ledger.rounds.length && victoryStoryCheckpoints.includes(checkpoint)
    if ((!active && !victoryStory) || (active && state.outcome && ledger.acknowledged === ledger.rounds.length) ||
        ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
        JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) ||
        JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before)) throw new Error('Unsettled Subevent 1 Belka checkpoint mismatch')
    return
  }
  if (!state.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) throw new Error('Invalid Subevent 1 Belka settlement')
  const bonus = state.outcome === 'win' ? getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : 0
  if (state.outcome === 'win' && (ledger.gold_delta! < battle.gold_reward.min + bonus || ledger.gold_delta! > battle.gold_reward.max + bonus) ||
      state.outcome === 'lose' && ledger.gold_delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) ||
      state.outcome === 'draw' && ledger.gold_delta !== 0 || !(state.outcome === 'win'
        ? [SUBEVENT1_BELKA_CHECKPOINT, ...victoryStoryCheckpoints, ...settledVictoryCheckpoints, GUILD_CHECKPOINT].includes(checkpoint)
        : [SUBEVENT1_BELKA_CHECKPOINT, GUILD_CHECKPOINT].includes(checkpoint)) ||
      checkpoint !== GUILD_CHECKPOINT && (save.player.money !== ledger.balance_before + ledger.gold_delta! ||
      JSON.stringify(save.player.inventory) !== JSON.stringify(settledInventory(ledger, state.outcome)) ||
      JSON.stringify(save.player.items ?? []) !== JSON.stringify(settledItems(ledger, state.outcome)))) {
    throw new Error('Invalid Subevent 1 Belka settlement')
  }
}
