import document from '../../content/stories/jin-verification.json'
import storyDocument from '../../content/stories/subevent1-jin.json'
import type { BattleContent, ContentPack } from '../content/schema'
import { getCardDefinition } from '../domain/card-catalog'
import type { Card, Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent, type FixedLedger } from './fixed'
import { BELKA_CHECKPOINT } from './belka'
import { type ItemId } from '../domain/item-catalog'

export const jinContent = document as ContentPack
export const subevent1JinContent = storyDocument as ContentPack
export const JIN_CHECKPOINT = 'jin.await'
export const SUBEVENT1_JIN_CHECKPOINT = 'subevent1.jin.await'
export const SUBEVENT1_JIN_BATTLE_ID = 'battle.subevent1.jin'
export const SUBEVENT1_JIN_STORY_ID = 'story.subevent1.jin'
export const SUBEVENT1_JIN_START_CHECKPOINT = 'subevent1.jin.intro'
export const SUBEVENT1_JIN_AFTER_CHECKPOINT = 'subevent1.jin.after'
export const SUBEVENT1_JIN_END_CHECKPOINT = 'subevent1.jin.end'
export const SUBEVENT1_MARCO_CHECKPOINT = 'subevent1.marco.await'
export const SUBEVENT1_MARCO_BATTLE_ID = 'battle.subevent1.marco'
export const SUBEVENT1_MARCO_AFTER_CHECKPOINT = 'subevent1.marco.after'
export const SUBEVENT1_MARCO_END_CHECKPOINT = 'subevent1.marco.end'
export const SUBEVENT1_GALD_CHECKPOINT = 'subevent1.gald.await'
export const SUBEVENT1_GALD_BATTLE_ID = 'battle.subevent1.gald'
export const SUBEVENT1_GALD_AFTER_CHECKPOINT = 'subevent1.gald.after'
export const SUBEVENT1_GALD_END_CHECKPOINT = 'subevent1.gald.end'
const ORIGIN = 'matilda.normal.end'
const verificationBattle = jinContent.battles[0] as BattleContent & { hp: NonNullable<BattleContent['hp']> }
const storyBattle = subevent1JinContent.battles.find((battle) => battle.id === SUBEVENT1_JIN_BATTLE_ID) as BattleContent & { hp: NonNullable<BattleContent['hp']> }
const marcoBattle = subevent1JinContent.battles.find((battle) => battle.id === SUBEVENT1_MARCO_BATTLE_ID) as BattleContent & { hp: NonNullable<BattleContent['hp']> }
const galdBattle = subevent1JinContent.battles.find((battle) => battle.id === SUBEVENT1_GALD_BATTLE_ID) as BattleContent & { hp: NonNullable<BattleContent['hp']> } & { item_reward_ids: ItemId[] }
const galdItemRewardIds: readonly string[] = galdBattle.item_reward_ids

export interface JinLedger extends FixedLedger {
  readonly origin_checkpoint: typeof ORIGIN
  readonly inventory_before: readonly Card[]
  readonly historical_deck: readonly Card[]
  readonly belka_preceded_jin: boolean
  readonly items_before?: readonly ItemId[]
}

type JinLedgerKey = 'jin_battle' | 'subevent1_jin_battle' | 'subevent1_marco_battle' | 'subevent1_gald_battle'

export function activeJinLedger(save: SaveData): JinLedger | undefined {
  const checkpoint = save.progress.checkpoint_id
  if (checkpoint === JIN_CHECKPOINT) return save.progress.jin_battle
  if (checkpoint === SUBEVENT1_JIN_CHECKPOINT) return save.progress.subevent1_jin_battle
  if (checkpoint === SUBEVENT1_MARCO_CHECKPOINT) return save.progress.subevent1_marco_battle
  if (checkpoint === SUBEVENT1_GALD_CHECKPOINT) return save.progress.subevent1_gald_battle
  const lastBattleId = save.progress.last_battle_id ?? save.progress.last_jin_battle_id
  return [save.progress.jin_battle, save.progress.subevent1_jin_battle, save.progress.subevent1_marco_battle, save.progress.subevent1_gald_battle]
    .find((ledger) => ledger?.battle_id === lastBattleId) ?? save.progress.subevent1_gald_battle ?? save.progress.subevent1_marco_battle ??
    save.progress.subevent1_jin_battle ?? save.progress.jin_battle
}

function ledgerKey(ledger: JinLedger): JinLedgerKey {
  if (ledger.battle_id === storyBattle.id) return 'subevent1_jin_battle'
  if (ledger.battle_id === marcoBattle.id) return 'subevent1_marco_battle'
  if (ledger.battle_id === galdBattle.id) return 'subevent1_gald_battle'
  return 'jin_battle'
}

function battleFor(save: SaveData, ledger = activeJinLedger(save)): BattleContent & { hp: NonNullable<BattleContent['hp']> } {
  const id = ledger?.battle_id
  const found = [verificationBattle, storyBattle, marcoBattle, galdBattle].find((entry) => entry.id === id)
  if (!found) throw new Error('Unknown Jin battle')
  return found
}

function opponentDeckFor(save: SaveData): Card[] {
  return battleFor(save).opponent_card_ids.map((id) => {
    const card = getCardDefinition(id)
    if (!card) throw new Error('Unknown Jin card')
    return { hand: card.hand, grade: card.grade }
  })
}

export function canStartJin(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    save.progress.guild_return_checkpoint === ORIGIN && !save.progress.jin_battle
}

export function canStartSubevent1Jin(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === ORIGIN &&
    !save.progress.subevent1_jin_battle && (!save.progress.jin_battle || save.progress.jin_battle.settled)
}

export function isSubevent1JinStoryCheckpoint(id: string): boolean {
  return subevent1JinContent.stories[0].steps.some((step) => step.id === id &&
    (step.kind === 'line' || step.kind === 'battle' || step.kind === 'end'))
}

export function startSubevent1JinStory(save: SaveData, deck: readonly Card[]): SaveData {
  parseSave(save)
  if (!canStartSubevent1Jin(save) || !validateDeck(save.player.inventory, deck, 3).valid) {
    throw new Error('Three owned cards required to start Subevent 1')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_JIN_START_CHECKPOINT,
    jin_draft: deck.map((card) => ({ ...card })) } })
}

export function prepareSubevent1Jin(save: SaveData): SaveData {
  parseSave(save)
  const deck = save.progress.jin_draft ?? []
  if (save.progress.checkpoint_id !== 'subevent1.jin.challenge' || save.progress.subevent1_jin_battle ||
      !validateDeck(save.player.inventory, deck, 3).valid) throw new Error('Invalid Subevent 1 Jin setup')
  const { jin_draft: _draft, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: SUBEVENT1_JIN_CHECKPOINT,
    last_battle_id: storyBattle.id,
    subevent1_jin_battle: { battle_id: storyBattle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })), historical_deck: save.player.deck.map((card) => ({ ...card })),
      belka_preceded_jin: !!save.progress.belka_battle?.settled, rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money }
  } })
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
    last_battle_id: verificationBattle.id,
    jin_battle: { battle_id: verificationBattle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })), historical_deck: save.player.deck.map((card) => ({ ...card })), rounds: [], acknowledged: 0,
      belka_preceded_jin: !!save.progress.belka_battle?.settled,
      settled: false, balance_before: save.player.money } } })
}

export function prepareSubevent1Marco(save: SaveData): SaveData {
  parseSave(save)
  const jin = save.progress.subevent1_jin_battle
  const deck = jin?.player_deck ?? []
  if (save.progress.checkpoint_id !== 'subevent1.marco.challenge' || save.progress.subevent1_marco_battle ||
      !jin?.settled || jin.battle_id !== storyBattle.id || jinView(save).outcome !== 'win' ||
      !validateDeck(save.player.inventory, deck, 3).valid) throw new Error('Invalid Subevent 1 Marco setup')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_MARCO_CHECKPOINT,
    last_battle_id: marcoBattle.id,
    subevent1_marco_battle: { battle_id: marcoBattle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })), historical_deck: save.player.deck.map((card) => ({ ...card })),
      belka_preceded_jin: !!save.progress.belka_battle?.settled, rounds: [], acknowledged: 0, settled: false, balance_before: save.player.money }
  } })
}

export function prepareSubevent1Gald(save: SaveData): SaveData {
  parseSave(save)
  const marco = save.progress.subevent1_marco_battle
  const deck = marco?.player_deck ?? []
  if (save.progress.checkpoint_id !== 'subevent1.gald.warning' || save.progress.subevent1_gald_battle ||
      !marco?.settled || marco.battle_id !== marcoBattle.id || jinView(save).outcome !== 'win' ||
      !validateDeck(save.player.inventory, deck, 3).valid) throw new Error('Invalid Subevent 1 Gald setup')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_GALD_CHECKPOINT,
    last_battle_id: galdBattle.id,
    subevent1_gald_battle: { battle_id: galdBattle.id, origin_checkpoint: ORIGIN, player_deck: deck.map((card) => ({ ...card })),
      inventory_before: save.player.inventory.map((card) => ({ ...card })), historical_deck: save.player.deck.map((card) => ({ ...card })),
      belka_preceded_jin: !!save.progress.belka_battle?.settled, rounds: [], acknowledged: 0, settled: false,
      balance_before: save.player.money, items_before: [...(save.player.items ?? [])] }
  } })
}

export function jinView(save: SaveData) {
  const ledger = activeJinLedger(save)
  if (!ledger) throw new Error('Jin battle not started')
  return replayFixedBattle(battleFor(save, ledger), ledger)
}

export function jinProbabilities(save: SaveData, selected?: Card): Record<Hand, number> {
  const view = jinView(save)
  const battle = battleFor(save)
  const remaining = opponentDeckFor(save).filter((_, index) => !view.usedOpponent.includes(index))
  return remaining.length ? opponentProbabilities(remaining, selected ?? { hand: 'rock', grade: 1 },
    selected ? battle.hp.grade_effect_passes : 0, battle.opponent_tendency) : { rock: 0, scissors: 0, paper: 0 }
}

function checkRoll(roll: number): void {
  if (!Number.isFinite(roll) || roll < 0 || roll >= 1) throw new Error('Invalid random roll')
}

export function playJinRound(save: SaveData, playerIndex: number, roll: number): SaveData {
  validateJinState(save); checkRoll(roll)
  const ledger = activeJinLedger(save)
  if (!ledger || ledger.settled || ledger.rounds.length !== ledger.acknowledged) throw new Error('Not selecting a Jin card')
  const opponentIndex = selectOpponent(battleFor(save), ledger, playerIndex, roll)
  return parseSave({ ...save, progress: { ...save.progress, [ledgerKey(ledger)]: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }] } } })
}

export function acknowledgeJinRound(save: SaveData): SaveData {
  validateJinState(save)
  const ledger = activeJinLedger(save)
  if (!ledger || ledger.settled || jinView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) throw new Error('No pending Jin result')
  return parseSave({ ...save, progress: { ...save.progress, [ledgerKey(ledger)]: { ...ledger, acknowledged: ledger.rounds.length } } })
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
  const ledger = activeJinLedger(save), outcome = jinView(save).outcome
  if (!ledger || ledger.settled || !outcome) throw new Error('No terminal Jin result')
  const battle = battleFor(save)
  const delta = battleGoldDelta(battle, outcome, ledger.balance_before, roll)
  const last = jinView(save).last
  let inventory = ledger.inventory_before.map((card) => ({ ...card }))
  if (outcome === 'win' && last) inventory.push({ ...last.opponent })
  if (outcome === 'lose' && last) {
    const index = inventory.findIndex((card) => card.hand === last.player.hand && card.grade === last.player.grade)
    if (index < 0) throw new Error('Lost Jin card is not in inventory')
    inventory.splice(index, 1)
  }
  const items = ledger.battle_id === galdBattle.id && outcome === 'win'
    ? [...(save.player.items ?? []), ...galdItemRewardIds.filter((id) => !(save.player.items ?? []).some((item) => item === id))]
    : save.player.items ?? []
  const prepared = save.player.prepared_deck
  const { prepared_deck: _oldPrepared, ...playerWithoutPrepared } = save.player
  const nextPlayer = { ...playerWithoutPrepared, inventory, money: save.player.money + delta, items,
    deck: adjustDeck(save.player.deck, inventory),
    ...(prepared && validateDeck(inventory, prepared, 9).valid ? { prepared_deck: prepared } : {}) }
  return parseSave({ ...save, player: nextPlayer, progress: { ...save.progress,
    [ledgerKey(ledger)]: { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta } } })
}

export function returnJinToGuild(save: SaveData): SaveData {
  validateJinState(save)
  const ledger = activeJinLedger(save)
  if (!ledger?.settled || ![JIN_CHECKPOINT, SUBEVENT1_JIN_CHECKPOINT, SUBEVENT1_MARCO_CHECKPOINT].includes(save.progress.checkpoint_id)) {
    throw new Error('Jin result not settled')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: ORIGIN } })
}

export function continueSubevent1Marco(save: SaveData): SaveData {
  validateJinState(save)
  if (save.progress.subevent1_marco_battle?.battle_id !== marcoBattle.id || !save.progress.subevent1_marco_battle.settled ||
      jinView(save).outcome !== 'win' || save.progress.checkpoint_id !== SUBEVENT1_MARCO_CHECKPOINT) {
    throw new Error('Subevent 1 Marco victory is not ready to continue')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_MARCO_AFTER_CHECKPOINT } })
}

export function continueSubevent1Gald(save: SaveData): SaveData {
  validateJinState(save)
  if (save.progress.subevent1_gald_battle?.battle_id !== galdBattle.id || !save.progress.subevent1_gald_battle.settled ||
      jinView(save).outcome !== 'win' || save.progress.checkpoint_id !== SUBEVENT1_GALD_CHECKPOINT) {
    throw new Error('Subevent 1 Gald victory is not ready to continue')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_GALD_AFTER_CHECKPOINT } })
}

export function returnSubevent1GaldToGuild(save: SaveData): SaveData {
  validateJinState(save)
  const ledger = save.progress.subevent1_gald_battle
  const finished = save.progress.checkpoint_id === SUBEVENT1_GALD_END_CHECKPOINT && ledger?.settled && jinView(save).outcome === 'win'
  const lost = save.progress.checkpoint_id === SUBEVENT1_GALD_CHECKPOINT && ledger?.settled && jinView(save).outcome !== 'win'
  if (!finished && !lost) throw new Error('Subevent 1 Gald encounter is not complete')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: ORIGIN } })
}

export const galdView = jinView
export const playGaldRound = playJinRound
export const settleGald = settleJin

export function continueSubevent1Jin(save: SaveData): SaveData {
  validateJinState(save)
  if (save.progress.subevent1_jin_battle?.battle_id !== storyBattle.id || !save.progress.subevent1_jin_battle.settled ||
      jinView(save).outcome !== 'win' || save.progress.checkpoint_id !== SUBEVENT1_JIN_CHECKPOINT) {
    throw new Error('Subevent 1 Jin victory is not ready to continue')
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT1_JIN_AFTER_CHECKPOINT } })
}

export function returnSubevent1JinToGuild(save: SaveData): SaveData {
  validateJinState(save)
  const legacyEnd = save.progress.checkpoint_id === SUBEVENT1_JIN_END_CHECKPOINT && save.progress.subevent1_jin_battle?.settled
  const marcoEnd = save.progress.checkpoint_id === SUBEVENT1_MARCO_END_CHECKPOINT && save.progress.subevent1_marco_battle?.settled &&
    jinView(save).outcome === 'win'
  if (!legacyEnd && !marcoEnd) throw new Error('Subevent 1 story is not complete')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: ORIGIN } })
}

export function validateJinState(save: SaveData): void {
  const { jin_battle: verification, subevent1_jin_battle: story, subevent1_marco_battle: marco, subevent1_gald_battle: gald } = save.progress
  const checkpoint = save.progress.checkpoint_id
  const active = activeJinLedger(save)
  if (checkpoint === JIN_CHECKPOINT && !verification || checkpoint === SUBEVENT1_JIN_CHECKPOINT && !story ||
      checkpoint === SUBEVENT1_MARCO_CHECKPOINT && !marco || checkpoint === SUBEVENT1_GALD_CHECKPOINT && !gald) {
    throw new Error('Missing Jin ledger')
  }
  const ledgers = [verification, story, marco, gald]
  const knownIds = [verificationBattle.id, storyBattle.id, marcoBattle.id, galdBattle.id]
  if (save.progress.last_jin_battle_id && !knownIds.includes(save.progress.last_jin_battle_id) ||
      save.progress.last_battle_id && !knownIds.includes(save.progress.last_battle_id) ||
      [save.progress.last_jin_battle_id, save.progress.last_battle_id].some((id) => id && !ledgers.some((ledger) => ledger?.battle_id === id))) {
    throw new Error('Unknown last Jin battle')
  }
  if (save.progress.jin_draft && (!(canStartSubevent1Jin(save) || canStartJin(save) || isSubevent1JinStoryCheckpoint(checkpoint)) ||
    save.progress.jin_draft.length > 3 || save.progress.jin_draft.length > 0 &&
    !validateDeck(save.player.inventory, save.progress.jin_draft, save.progress.jin_draft.length).valid)) throw new Error('Invalid Jin draft')

  for (const ledger of ledgers) {
    if (!ledger) continue
    const isActive = ledger === active
    const battle = battleFor(save, ledger)
    if ((ledger === verification && ledger.battle_id !== verificationBattle.id) || (ledger === story && ledger.battle_id !== storyBattle.id) ||
      (ledger === marco && ledger.battle_id !== marcoBattle.id) || (ledger === gald && ledger.battle_id !== galdBattle.id) || ledger.origin_checkpoint !== ORIGIN ||
      typeof ledger.belka_preceded_jin !== 'boolean' || !validateDeck(ledger.inventory_before, ledger.player_deck, 3).valid ||
      !validateDeck(ledger.inventory_before, ledger.historical_deck, ledger.historical_deck.length).valid ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0) throw new Error('Invalid Jin ledger')
    const view = replayFixedBattle(battle, ledger)
    if (!ledger.settled) {
      const expectedCheckpoint = ledger === gald ? SUBEVENT1_GALD_CHECKPOINT : ledger === story ? SUBEVENT1_JIN_CHECKPOINT : ledger === marco ? SUBEVENT1_MARCO_CHECKPOINT : JIN_CHECKPOINT
      if (!isActive || checkpoint !== expectedCheckpoint || ledger.gold_delta !== undefined || save.player.money !== ledger.balance_before ||
        JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) || ledger === gald && JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before) || view.outcome && ledger.acknowledged === ledger.rounds.length) {
        throw new Error('Unsettled Jin checkpoint mismatch')
      }
      continue
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
    if (view.outcome === 'win' && (delta < battle.gold_reward.min || delta > battle.gold_reward.max) ||
      view.outcome === 'lose' && delta !== -Math.min(ledger.balance_before, battle.hp.lose_gold) || view.outcome === 'draw' && delta !== 0) {
      throw new Error('Invalid Jin settlement')
    }
    if (isActive) {
      const belka = save.progress.belka_battle
      if (ledger.belka_preceded_jin && (!belka?.settled || belka.balance_before + (belka.gold_delta ?? 0) !== ledger.balance_before)) {
        throw new Error('Invalid Jin/Belka encounter order')
      }
      const laterBelka = !!belka && !ledger.belka_preceded_jin
      const expectedMoney = laterBelka ? belka!.balance_before + (belka!.settled ? (belka!.gold_delta ?? 0) : 0) : ledger.balance_before + delta
      const expectedItems = ledger === gald
        ? view.outcome === 'win'
          ? [...(ledger.items_before ?? []), ...galdItemRewardIds.filter((id) => !(ledger.items_before ?? []).some((item) => item === id))]
          : ledger.items_before ?? []
        : save.player.items ?? []
      if (expectedMoney !== save.player.money || JSON.stringify(expected) !== JSON.stringify(save.player.inventory) ||
        ledger === gald && JSON.stringify(expectedItems) !== JSON.stringify(save.player.items ?? []) ||
        ![JIN_CHECKPOINT, SUBEVENT1_JIN_CHECKPOINT, SUBEVENT1_JIN_AFTER_CHECKPOINT, SUBEVENT1_JIN_END_CHECKPOINT,
          SUBEVENT1_MARCO_CHECKPOINT, SUBEVENT1_MARCO_AFTER_CHECKPOINT, SUBEVENT1_MARCO_END_CHECKPOINT,
          SUBEVENT1_GALD_CHECKPOINT, SUBEVENT1_GALD_AFTER_CHECKPOINT, SUBEVENT1_GALD_END_CHECKPOINT,
          GUILD_CHECKPOINT, BELKA_CHECKPOINT].includes(checkpoint) && !isSubevent1JinStoryCheckpoint(checkpoint)) {
        throw new Error('Invalid Jin settlement')
      }
    }
  }
}
