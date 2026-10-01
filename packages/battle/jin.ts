import document from '../../content/stories/jin-verification.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import type { Card, Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent, type FixedLedger } from './fixed'
import { BELKA_CHECKPOINT } from './belka'

export const jinContent = document as ContentPack
export const JIN_CHECKPOINT = 'jin.await'
const ORIGIN = 'matilda.normal.end'
const battle = jinContent.battles[0] as BattleContent & { hp: NonNullable<BattleContent['hp']> }

export interface JinLedger extends FixedLedger {
  readonly origin_checkpoint: typeof ORIGIN
  readonly inventory_before: readonly Card[]
  readonly historical_deck: readonly Card[]
}

function opponentDeck(): Card[] {
  return battle.opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown Jin card')
    return { hand: card.hand, grade: card.grade }
  })
}

export function canStartJin(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    save.progress.guild_return_checkpoint === ORIGIN && !save.progress.jin_battle
}

export function setJinDraft(save: SaveData, draft: readonly Card[]): SaveData {
  if (!canStartJin(save) || draft.length > 3 || (draft.length > 0 && !validateDeck(save.player.inventory, draft, draft.length).valid)) {
    throw new Error('Invalid Jin draft')
  }
  return parseSave({ ...save, progress: { ...save.progress, jin_draft: draft.map((card) => ({ ...card })) } })
}

export function startJin(save: SaveData, deck = save.progress.jin_draft ?? []): SaveData {
  parseSave(save)
  if (!canStartJin(save) || !validateDeck(save.player.inventory, deck, 3).valid) throw new Error('Three owned Jin cards required')
  const { jin_draft: _draft, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: JIN_CHECKPOINT,
    jin_battle: { battle_id: battle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })), historical_deck: save.player.deck.map((card) => ({ ...card })), rounds: [], acknowledged: 0,
      settled: false, balance_before: save.player.money } } })
}

export function jinView(save: SaveData) {
  if (!save.progress.jin_battle) throw new Error('Jin battle not started')
  return replayFixedBattle(battle, save.progress.jin_battle)
}

export function jinProbabilities(save: SaveData, selected?: Card): Record<Hand, number> {
  const view = jinView(save)
  const remaining = opponentDeck().filter((_, index) => !view.usedOpponent.includes(index))
  return remaining.length ? opponentProbabilities(remaining, selected ?? { hand: 'rock', grade: 1 },
    selected ? battle.hp.grade_effect_passes : 0, battle.opponent_tendency) : { rock: 0, scissors: 0, paper: 0 }
}

function checkRoll(roll: number): void {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playJinRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateJinState(save); checkRoll(roll)
  const ledger = save.progress.jin_battle
  if (!ledger || ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Jin card')
  const opponentIndex = selectOpponent(battle, ledger, playerIndex, roll)
  return parseSave({ ...save, progress: { ...save.progress, jin_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }] } } })
}

export function acknowledgeJinRound(save: SaveData): SaveData {
  validateJinState(save)
  const ledger = save.progress.jin_battle
  if (!ledger || ledger.settled || jinView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No pending Jin result')
  return parseSave({ ...save, progress: { ...save.progress, jin_battle: { ...ledger, acknowledged: ledger.rounds.length } } })
}

function adjustDeck(deck: readonly Card[], inventory: readonly Card[]): Card[] {
  const counts = new Map<string, number>()
  for (const card of inventory) {
    const key = `${card.hand}:${card.grade}`
    counts.set(key, (counts.get(key) ?? 0) + 1)
  }
  return deck.filter((card) => {
    const key = `${card.hand}:${card.grade}`, remaining = counts.get(key) ?? 0
    if (!remaining) return false
    counts.set(key, remaining - 1)
    return true
  })
}

export function settleJin(save: SaveData, roll: number): SaveData {
  validateJinState(save); checkRoll(roll)
  const ledger = save.progress.jin_battle, outcome = jinView(save).outcome
  if (!ledger || ledger.settled || !outcome) throw new Error('No terminal Jin result')
  const delta = battleGoldDelta(battle, outcome, ledger.balance_before, roll)
  const last = jinView(save).last
  let inventory = ledger.inventory_before.map((card) => ({ ...card }))
  if (outcome === 'win' && last) inventory.push({ ...last.opponent })
  if (outcome === 'lose' && last) {
    const index = inventory.findIndex((card) => card.hand === last.player.hand && card.grade === last.player.grade)
    if (index < 0) throw new Error('Lost Jin card is not in inventory')
    inventory.splice(index, 1)
  }
  const prepared = save.player.prepared_deck
  const { prepared_deck: _oldPrepared, ...playerWithoutPrepared } = save.player
  const nextPlayer = { ...playerWithoutPrepared, inventory, money: save.player.money + delta,
    deck: adjustDeck(save.player.deck, inventory),
    ...(prepared && validateDeck(inventory, prepared, 9).valid ? { prepared_deck: prepared } : {}) }
  return parseSave({ ...save, player: nextPlayer, progress: { ...save.progress,
    jin_battle: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } })
}

export function returnJinToGuild(save: SaveData): SaveData {
  validateJinState(save)
  if (!save.progress.jin_battle?.settled || save.progress.checkpoint_id !== JIN_CHECKPOINT) throw new Error('Jin result not settled')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: ORIGIN } })
}

export function validateJinState(save: SaveData): void {
  const ledger = save.progress.jin_battle, checkpoint = save.progress.checkpoint_id
  if (!ledger) {
    if (checkpoint === JIN_CHECKPOINT) throw new Error('Missing Jin ledger')
    if (save.progress.jin_draft && (!canStartJin(save) || save.progress.jin_draft.length > 3 ||
      !validateDeck(save.player.inventory, save.progress.jin_draft, save.progress.jin_draft.length || 1).valid && save.progress.jin_draft.length > 0)) {
      throw new Error('Invalid Jin draft')
    }
    return
  }
  if (save.progress.jin_draft || ledger.battle_id !== battle.id || ledger.origin_checkpoint !== ORIGIN ||
    !validateDeck(ledger.inventory_before, ledger.player_deck, 3).valid ||
    !validateDeck(ledger.inventory_before, ledger.historical_deck, ledger.historical_deck.length).valid ||
    !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
    ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
    !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0) throw new Error('Invalid Jin ledger')
  const view = jinView(save)
  if (!ledger.settled) {
    if (checkpoint !== JIN_CHECKPOINT || ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
      JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) || view.outcome && ledger.acknowledged === ledger.rounds.length) {
      throw new Error('Unsettled Jin checkpoint mismatch')
    }
    return
  }
  if (!view.outcome || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) throw new Error('Invalid Jin settlement')
  const delta = ledger.gold_delta!, last = view.last
  const expected = ledger.inventory_before.map((card) => ({ ...card }))
  if (view.outcome === 'win' && last) expected.push(last.opponent)
  if (view.outcome === 'lose' && last) {
    const index = expected.findIndex((card) => card.hand === last.player.hand && card.grade === last.player.grade)
    if (index < 0) throw new Error('Invalid lost Jin card')
    expected.splice(index, 1)
  }
  const laterBelka = !!save.progress.belka_battle && save.progress.belka_battle.balance_before === ledger.balance_before + delta
  const expectedMoney = laterBelka ? save.progress.belka_battle!.balance_before + (save.progress.belka_battle!.gold_delta ?? 0) : ledger.balance_before + delta
  if (view.outcome === 'win' && (delta < battle.gold_reward.min || delta > battle.gold_reward.max) ||
    view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) || view.outcome === 'draw' && delta !== 0 ||
    expectedMoney !== save.player.money || JSON.stringify(expected) !== JSON.stringify(save.player.inventory) ||
    ![JIN_CHECKPOINT, GUILD_CHECKPOINT, BELKA_CHECKPOINT].includes(checkpoint)) throw new Error('Invalid Jin settlement')
}
