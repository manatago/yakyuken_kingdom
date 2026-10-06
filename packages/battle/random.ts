import rawTown from '../../content/town/stage1.json'
import { getCardDefinition, getCardId } from '../domain/card-catalog'
import type { Card, Hand } from '../domain/card'
import { validateDeck } from '../domain/deck'
import { getGoldBonus, getItemDefinition, isBattleUsable, type ItemId } from '../domain/item-catalog'
import { parseSave, type SaveData } from '../domain/save'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { battleGoldDelta, opponentProbabilities, replayFixedBattle, selectOpponent, type FixedLedger } from './fixed'
import type { BattleContent } from '../content/schema'
import { TUTORIAL_COMPLETE } from './tutorial'
import { ADVENTURER_TUTORIAL_COMPLETE } from './adventurer-tutorial'
import { PROGRESSION_FLAGS, SUBEVENT_RANDOM_BATTLE_REQUIREMENT } from '../domain/progression'

export const townContent = rawTown
export const TOWN_CHECKPOINT = 'town.area'
export const TOWN_ENCOUNTER_CHECKPOINT = 'town.encounter'
export const RANDOM_BATTLE_CHECKPOINT = 'random.await'

type AreaId = keyof typeof townContent.areas
type OpponentId = keyof typeof townContent.opponents
type Encounter = { opponentId: OpponentId; weight: number; gradeMin: number; gradeMax: number }

export interface RandomBattleLedger extends FixedLedger {
  readonly area_id: AreaId
  readonly opponent_id: OpponentId
  readonly opponent_name: string
  readonly char_type: 'normal' | 'rare'
  readonly item_reward_id?: ItemId
  readonly historical_deck: readonly Card[]
  readonly opponent_deck: readonly Card[]
  readonly opponent_tendency: Partial<Record<Hand, number>>
  readonly dialogue_indexes?: { readonly greeting: number; readonly battle_start: number; readonly farewell_win: number; readonly farewell_lose: number }
  readonly gold_reward: { readonly min: number; readonly max: number }
  readonly loss_gold: number
  readonly bonus_capture_index?: number
  readonly inventory_before: readonly Card[]
  readonly items_before: readonly ItemId[]
}

export interface TownRolls {
  readonly encounter: number
  readonly opponent: number
  readonly cards: readonly [RandomCardRoll, RandomCardRoll, RandomCardRoll]
  readonly drop: number
  readonly dialogue?: readonly [number, number, number, number]
}

export interface RandomCardRoll { readonly hand: number; readonly grade: number }

function validRoll(value: number): void {
  if (!Number.isFinite(value) || value < 0 || value >= 1) throw new RangeError('Random rolls must be in [0, 1)')
}

const HANDS: readonly Hand[] = ['rock', 'scissors', 'paper']
const BASIC_DROPS: readonly ItemId[] = ['substitute_card', 'smoke_bomb']
const WHITE_DROPS: readonly ItemId[] = ['rock_attract_white', 'scissors_attract_white', 'paper_attract_white', 'rock_break_white', 'scissors_dull_white', 'paper_seal_white']
const CRIMSON_DROPS: readonly ItemId[] = ['rock_attract_crimson', 'scissors_attract_crimson', 'paper_attract_crimson', 'rock_break_crimson', 'scissors_dull_crimson', 'paper_seal_crimson']
const GOLD_DROPS: readonly ItemId[] = ['rock_attract_gold', 'scissors_attract_gold', 'paper_attract_gold', 'rock_break_gold', 'scissors_dull_gold', 'paper_seal_gold']

function randomBattleDropPool(flags: readonly string[], charType: 'normal' | 'rare'): readonly ItemId[] {
  const tier = flags.includes(PROGRESSION_FLAGS.stage4Cleared) ? 3 : flags.includes(PROGRESSION_FLAGS.subevent4Cleared) ? 2 : flags.includes(PROGRESSION_FLAGS.subevent1Cleared) ? 1 : 0
  if (charType === 'rare') {
    return tier === 0 ? BASIC_DROPS : tier === 1 ? WHITE_DROPS : tier === 2 ? [...CRIMSON_DROPS, 'iron_shield'] : [...GOLD_DROPS, 'rank_up_talisman']
  }
  return tier === 0 ? [] : tier === 1 ? BASIC_DROPS : tier === 2 ? WHITE_DROPS : [...CRIMSON_DROPS, 'iron_shield']
}

function generatedOpponentDeck(encounter: Encounter, rolls: TownRolls): Card[] {
  if (rolls.cards.length !== 3) throw new RangeError('A random encounter requires three card rolls')
  return rolls.cards.map(({ hand, grade }) => {
    validRoll(hand); validRoll(grade)
    return { hand: HANDS[Math.floor(hand * HANDS.length)]!, grade: encounter.gradeMin + Math.floor(grade * (encounter.gradeMax - encounter.gradeMin + 1)) as Card['grade'] }
  })
}

function area(id: string) {
  if (!Object.hasOwn(townContent.areas, id)) throw new Error(`Unknown town area: ${id}`)
  return townContent.areas[id as AreaId]
}

function opponent(id: string) {
  const profile = townContent.opponents[id as OpponentId]
  if (!profile) throw new Error(`Unknown random opponent: ${id}`)
  return profile
}

function weightedEncounter(entries: readonly Encounter[], roll: number): Encounter {
  validRoll(roll)
  const total = entries.reduce((sum, entry) => sum + entry.weight, 0)
  if (entries.length === 0 || !Number.isFinite(total) || total <= 0) throw new Error('Town area has no valid encounters')
  let selected = roll * total
  for (const entry of entries) {
    selected -= entry.weight
    if (selected < 0) return entry
  }
  return entries.at(-1)!
}

function toBattle(ledger: RandomBattleLedger): BattleContent & { hp: NonNullable<BattleContent['hp']> } {
  return { id: ledger.battle_id, opponent_id: ledger.opponent_id, background_asset_id: '',
    player_deck_size: 3, opponent_deck_size: 3, opponent_card_ids: ledger.opponent_deck.map(getCardId),
    gold_reward: ledger.gold_reward, transfer_cards: true, phases: [{ id: `${ledger.battle_id}.phase`, rules: [] }],
    hp: { player: 1, opponent: 1, grade_effect_passes: 2, lose_gold: ledger.loss_gold },
    opponent_tendency: ledger.opponent_tendency, bayes_eye: true }
}

function startEncounter(save: SaveData, areaId: AreaId, rolls: TownRolls): SaveData {
  const destination = area(areaId)
  validRoll(rolls.encounter)
  const { random_battle: _previousBattle, guild_return_checkpoint: _guildReturn, ...previousProgress } = save.progress
  const entered = { ...save, progress: { ...previousProgress, checkpoint_id: TOWN_CHECKPOINT, town_area: areaId } }
  if (rolls.encounter > destination.battleRate) return parseSave(entered)
  const selected = weightedEncounter(destination.encounters as readonly Encounter[], rolls.opponent)
  const profile = opponent(selected.opponentId)
  if (profile.charType !== 'normal' && profile.charType !== 'rare') throw new Error(`Invalid random opponent type: ${selected.opponentId}`)
  const charType = profile.charType
  const opponentDeck = generatedOpponentDeck(selected, rolls)
  const dialogueProfile = profile.dialogues as Record<'greetings' | 'battleStart' | 'farewellsWin' | 'farewellsLose', readonly string[]>
  const dialogueRolls = rolls.dialogue ?? [rolls.opponent, rolls.opponent, rolls.opponent, rolls.opponent]
  const dialogueTypes: readonly [
    readonly ['greeting', 'greetings'], readonly ['battle_start', 'battleStart'],
    readonly ['farewell_win', 'farewellsWin'], readonly ['farewell_lose', 'farewellsLose']
  ] = [['greeting', 'greetings'], ['battle_start', 'battleStart'], ['farewell_win', 'farewellsWin'], ['farewell_lose', 'farewellsLose']]
  const dialogue_indexes = Object.fromEntries(dialogueTypes.map(([indexKey, lineKey], index) => {
    const roll = dialogueRolls[index]!
    validRoll(roll)
    return [indexKey, Math.floor(roll * dialogueProfile[lineKey].length)]
  })) as NonNullable<RandomBattleLedger['dialogue_indexes']>
  const dropPool = randomBattleDropPool(save.progress.flags, charType)
  validRoll(rolls.drop)
  const itemRewardId = dropPool.length ? dropPool[Math.floor(rolls.drop * dropPool.length)] : undefined
  if (save.player.inventory.length < 3) {
    throw new Error('At least three owned cards are required to explore the town')
  }
  const randomBattle: RandomBattleLedger = {
    battle_id: `random.${areaId}.${save.progress.random_battles_completed ?? 0}.${selected.opponentId}`,
    area_id: areaId, opponent_id: selected.opponentId, opponent_name: profile.name, char_type: charType,
    ...(itemRewardId ? { item_reward_id: itemRewardId } : {}),
    player_deck: [], historical_deck: save.player.deck.map((card) => ({ ...card })),
    opponent_deck: opponentDeck,
    opponent_tendency: profile.tendency, gold_reward: profile.goldReward,
    dialogue_indexes,
    loss_gold: Math.floor((profile.goldReward.min + profile.goldReward.max) / 4),
    inventory_before: save.player.inventory.map((card) => ({ ...card })),
    items_before: [...(save.player.items ?? [])], equipment_before: [...(save.player.equipment ?? [])],
    rounds: [], round_item_ids: [], acknowledged: 0, settled: false, balance_before: save.player.money
  }
  return parseSave({ ...entered, progress: { ...entered.progress, checkpoint_id: TOWN_ENCOUNTER_CHECKPOINT, random_battle: randomBattle } })
}

export function randomBattleDialogue(save: SaveData, kind: 'greeting' | 'battle_start' | 'farewell_win' | 'farewell_lose'): string {
  const ledger = save.progress.random_battle
  if (!ledger) throw new Error('Random battle not started')
  const profile = opponent(ledger.opponent_id)
  const key = ({ greeting: 'greetings', battle_start: 'battleStart', farewell_win: 'farewellsWin', farewell_lose: 'farewellsLose' } as const)[kind]
  const dialogue = profile.dialogues as Record<'greetings' | 'battleStart' | 'farewellsWin' | 'farewellsLose', readonly string[]>
  const lines = dialogue[key]
  const index = ledger.dialogue_indexes?.[kind] ?? 0
  return lines[index] ?? lines[0]!
}

export function enterTown(save: SaveData, areaId: string, rolls: TownRolls): SaveData {
  parseSave(save)
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !save.progress.guild_return_checkpoint ||
      !townContent.homeConnections.includes(areaId as AreaId)) throw new Error('Town entry requires an available guild connection')
  if (!save.progress.flags.includes(TUTORIAL_COMPLETE) ||
      !save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE)) throw new Error('Complete both tutorials before exploring')
  const { guild_return_checkpoint: origin, ...progress } = save.progress
  return startEncounter({ ...save, progress: { ...progress, town_origin_checkpoint: origin } }, areaId as AreaId, rolls)
}

export function canEnterTown(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && !!save.progress.guild_return_checkpoint &&
    save.progress.flags.includes(TUTORIAL_COMPLETE) &&
    save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE) && !save.progress.random_battle
}

export function travelTown(save: SaveData, areaId: string, rolls: TownRolls): SaveData {
  parseSave(save)
  const current = save.progress.town_area
  if (save.progress.checkpoint_id !== TOWN_CHECKPOINT || !current || !area(current).connections.includes(areaId)) {
    throw new Error('Town travel must follow a connected route')
  }
  return startEncounter(save, areaId as AreaId, rolls)
}

export function acceptTownEncounter(save: SaveData, playerDeck: readonly Card[]): SaveData {
  validateRandomBattleState(save)
  if (save.progress.checkpoint_id !== TOWN_ENCOUNTER_CHECKPOINT || !save.progress.random_battle ||
      !validateDeck(save.player.inventory, playerDeck, 3).valid) throw new Error('Select three owned cards before accepting the encounter')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: RANDOM_BATTLE_CHECKPOINT,
    random_battle: { ...save.progress.random_battle, player_deck: playerDeck.map((card) => ({ ...card })) } } })
}

export function declineTownEncounter(save: SaveData): SaveData {
  validateRandomBattleState(save)
  if (save.progress.checkpoint_id !== TOWN_ENCOUNTER_CHECKPOINT) throw new Error('No pending encounter')
  const { random_battle: _battle, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: TOWN_CHECKPOINT } })
}

export function randomBattleView(save: SaveData) {
  const ledger = save.progress.random_battle
  if (!ledger) throw new Error('Random battle not started')
  return replayFixedBattle(toBattle(ledger), ledger)
}

function adjustmentFor(itemId: ItemId | undefined, player?: Card): { targetHand: Hand; delta: number } | undefined {
  if (!itemId) return undefined
  const item = getItemDefinition(itemId)
  if (!item) return undefined
  if (item.effect === 'adjust_probability' && item.targetHand && item.probabilityDelta !== undefined) {
    return { targetHand: item.targetHand, delta: item.probabilityDelta }
  }
  if (item.effect === 'intimidate' && player) {
    const losesTo: Record<Hand, Hand> = { rock: 'scissors', scissors: 'paper', paper: 'rock' }
    return { targetHand: losesTo[player.hand], delta: .2 }
  }
  return undefined
}

export function randomBattleProbabilities(save: SaveData, selected?: Card, itemId?: ItemId) {
  const ledger = save.progress.random_battle
  if (!ledger) throw new Error('Random battle not started')
  const view = randomBattleView(save)
  const remaining = ledger.opponent_deck.filter((_, index) => !view.usedOpponent.includes(index))
  const player = selected ?? { hand: 'rock', grade: 1 }
  const adjustment = adjustmentFor(itemId, selected)
  return remaining.length ? opponentProbabilities(remaining, player, selected ? 2 : 0, ledger.opponent_tendency, adjustment)
    : { rock: 0, scissors: 0, paper: 0 }
}

export function playRandomBattleRound(save: SaveData, playerIndex: number, roll: number, itemId?: string): SaveData {
  validateRandomBattleState(save); validRoll(roll)
  const ledger = save.progress.random_battle
  if (!ledger || ledger.settled || save.progress.checkpoint_id !== RANDOM_BATTLE_CHECKPOINT || ledger.rounds.length !== ledger.acknowledged) {
    throw new Error('Random battle is not accepting a card')
  }
  const selected = itemId === undefined ? undefined : itemId as ItemId
  const alreadyUsed = (ledger.round_item_ids ?? []).filter((entry) => entry !== null)
  if (selected) {
    const definition = getItemDefinition(selected)
    const owned = (ledger.items_before ?? []).filter((id) => id === selected).length
    const used = alreadyUsed.filter((id) => id === selected).length
    if (!definition || !isBattleUsable(definition) || used >= owned) throw new Error('Selected battle item is unavailable')
  }
  const adjustment = adjustmentFor(selected, ledger.player_deck[playerIndex])
  const opponentIndex = selectOpponent(toBattle(ledger), ledger, playerIndex, roll, adjustment)
  return parseSave({ ...save, progress: { ...save.progress, random_battle: { ...ledger,
    rounds: [...ledger.rounds, { player_index: playerIndex, opponent_index: opponentIndex }],
    round_item_ids: [...(ledger.round_item_ids ?? Array.from({ length: ledger.rounds.length }, () => null)), selected ?? null] } } })
}

export function acknowledgeRandomBattleRound(save: SaveData): SaveData {
  validateRandomBattleState(save)
  const ledger = save.progress.random_battle
  if (!ledger || ledger.settled || randomBattleView(save).outcome || ledger.rounds.length !== ledger.acknowledged + 1) {
    throw new Error('No random battle result is pending')
  }
  return parseSave({ ...save, progress: { ...save.progress, random_battle: { ...ledger, acknowledged: ledger.rounds.length } } })
}

function settledInventory(ledger: RandomBattleLedger, outcome: 'win' | 'lose' | 'draw'): Card[] {
  const inventory = ledger.inventory_before.map((card) => ({ ...card }))
  const view = replayFixedBattle(toBattle(ledger), ledger), last = view.last
  if (outcome === 'win' && last) inventory.push({ ...last.opponent })
  if (outcome === 'win' && ledger.bonus_capture_index !== undefined) {
    const bonus = ledger.opponent_deck[ledger.bonus_capture_index]
    if (!bonus || view.usedOpponent.includes(ledger.bonus_capture_index)) throw new Error('Invalid bonus capture card')
    inventory.push({ ...bonus })
  }
  if (outcome === 'lose' && last) {
    const lastItemId = ledger.round_item_ids?.[ledger.rounds.length - 1] ?? null
    if (getItemDefinition(lastItemId ?? '')?.effect === 'protect_card') return inventory
    // A three-card inventory is the minimum usable town deck. Do not make a
    // loss permanently strand the player outside every card-awarding battle.
    if (inventory.length <= 3) return inventory
    const index = inventory.findIndex((card) => card.hand === last.player.hand && card.grade === last.player.grade)
    if (index < 0) throw new Error('Lost random battle card is not in inventory')
    inventory.splice(index, 1)
  }
  return inventory
}

function settledItems(ledger: RandomBattleLedger, outcome: 'win' | 'lose' | 'draw'): ItemId[] {
  const items = [...ledger.items_before]
  for (const usedItemId of ledger.round_item_ids ?? []) {
    if (!usedItemId) continue
    const index = items.indexOf(usedItemId)
    if (index < 0) throw new Error('Used battle item is not in the inventory snapshot')
    items.splice(index, 1)
  }
  if (outcome === 'win' && ledger.item_reward_id) items.push(ledger.item_reward_id)
  return items
}

export function settleRandomBattle(save: SaveData, goldRoll: number, captureRoll = 0): SaveData {
  validateRandomBattleState(save); validRoll(goldRoll); validRoll(captureRoll)
  const ledger = save.progress.random_battle, outcome = randomBattleView(save).outcome
  if (!ledger || ledger.settled || !outcome) throw new Error('No terminal random battle result')
  const base = battleGoldDelta(toBattle(ledger), outcome, ledger.balance_before, goldRoll)
  const loss = Math.min(ledger.balance_before, ledger.loss_gold)
  const delta = outcome === 'win' ? base + getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id })))
    : outcome === 'lose' ? loss === 0 ? 0 : -loss : 0
  const usedOpponent = randomBattleView(save).usedOpponent
  const captureCandidates = outcome === 'win' && (ledger.equipment_before ?? []).includes('greed_ring')
    ? ledger.opponent_deck.map((_, index) => index).filter((index) => !usedOpponent.includes(index)) : []
  const bonusCaptureIndex = captureCandidates.length ? captureCandidates[Math.floor(captureRoll * captureCandidates.length)] : undefined
  const settledLedger = { ...ledger, acknowledged: ledger.rounds.length, settled: true, gold_delta: delta,
    ...(bonusCaptureIndex !== undefined ? { bonus_capture_index: bonusCaptureIndex } : {}) }
  const inventory = settledInventory(settledLedger, outcome)
  const counts = new Map<string, number>()
  for (const card of inventory) { const key = `${card.hand}:${card.grade}`; counts.set(key, (counts.get(key) ?? 0) + 1) }
  const deck = save.player.deck.filter((card) => {
    const key = `${card.hand}:${card.grade}`, count = counts.get(key) ?? 0
    if (!count) return false
    counts.set(key, count - 1); return true
  })
  const prepared = save.player.prepared_deck
  const { prepared_deck: _oldPrepared, ...playerWithoutPrepared } = save.player
  return parseSave({ ...save, player: { ...playerWithoutPrepared, inventory, deck, items: settledItems(ledger, outcome), money: save.player.money + delta,
    ...(prepared && validateDeck(inventory, prepared, 9).valid ? { prepared_deck: prepared } : {}) }, progress: { ...save.progress,
    checkpoint_id: TOWN_CHECKPOINT, random_battles_completed: (save.progress.random_battles_completed ?? 0) + 1,
    random_battle: settledLedger } })
}

export function returnToGuildFromTown(save: SaveData): SaveData {
  validateRandomBattleState(save)
  if (save.progress.checkpoint_id !== TOWN_CHECKPOINT || !save.progress.town_origin_checkpoint ||
      save.progress.random_battle && !save.progress.random_battle.settled) throw new Error('Town journey is not ready to end')
  const { town_area: _area, town_origin_checkpoint: origin, random_battle: _battle, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: origin } })
}

export function continueTownAfterBattle(save: SaveData): SaveData {
  validateRandomBattleState(save)
  if (save.progress.checkpoint_id !== TOWN_CHECKPOINT || !save.progress.random_battle?.settled) {
    throw new Error('There is no completed random encounter to dismiss')
  }
  const { random_battle: _battle, ...progress } = save.progress
  return parseSave({ ...save, progress })
}

export function validateRandomBattleState(save: SaveData): void {
  const { checkpoint_id: checkpoint, town_area: townArea, town_origin_checkpoint: origin, random_battle: ledger } = save.progress
  const townScreen = checkpoint === TOWN_CHECKPOINT || checkpoint === TOWN_ENCOUNTER_CHECKPOINT || checkpoint === RANDOM_BATTLE_CHECKPOINT
  if (townScreen !== !!townArea || townScreen !== !!origin || townScreen && save.progress.guild_return_checkpoint !== undefined) {
    throw new Error('Town route and checkpoint do not match')
  }
  if (!townScreen && (townArea !== undefined || origin !== undefined || ledger !== undefined)) throw new Error('Stale town state outside town')
  if (townScreen) area(townArea!)
  if ((checkpoint === TOWN_ENCOUNTER_CHECKPOINT || checkpoint === RANDOM_BATTLE_CHECKPOINT) !== !!ledger) {
    if (checkpoint === TOWN_CHECKPOINT && ledger?.settled) { /* completed encounter result remains visible until leaving */ }
    else throw new Error('Random encounter state does not match its checkpoint')
  }
  if (!ledger) return
  const profile = opponent(ledger.opponent_id)
  const encounter = area(ledger.area_id).encounters.find((entry) => entry.opponentId === ledger.opponent_id)
  const validDrops = randomBattleDropPool(save.progress.flags, ledger.char_type)
  const lines = profile.dialogues as Record<'greetings' | 'battleStart' | 'farewellsWin' | 'farewellsLose', readonly string[]>
  const roundItemIds = ledger.round_item_ids ?? Array.from({ length: ledger.rounds.length }, () => null)
  const usedItemIds = roundItemIds.filter((id): id is ItemId => id !== null)
  const validItemUsage = roundItemIds.length === ledger.rounds.length && roundItemIds.every((id) => id === null ||
    !!getItemDefinition(id) && isBattleUsable(getItemDefinition(id)!)) &&
    usedItemIds.every((id) => usedItemIds.filter((used) => used === id).length <= ledger.items_before.filter((owned) => owned === id).length)
  if (ledger.area_id !== townArea || !profile || !encounter || ledger.opponent_name !== profile.name ||
      !['normal', 'rare'].includes(ledger.char_type) || ledger.char_type !== profile.charType ||
      ledger.item_reward_id !== undefined && !validDrops.includes(ledger.item_reward_id) ||
      !validItemUsage ||
      ledger.dialogue_indexes && [
        [ledger.dialogue_indexes.greeting, lines.greetings.length],
        [ledger.dialogue_indexes.battle_start, lines.battleStart.length],
        [ledger.dialogue_indexes.farewell_win, lines.farewellsWin.length],
        [ledger.dialogue_indexes.farewell_lose, lines.farewellsLose.length]
      ].some(([index, count]) => !Number.isSafeInteger(index) || index < 0 || index >= count) ||
      ![0, 3].includes(ledger.player_deck.length) || ledger.opponent_deck.length !== 3 ||
      ledger.opponent_deck.some((card) => card.grade < encounter.gradeMin || card.grade > encounter.gradeMax) ||
      ledger.player_deck.length === 3 && !validateDeck(ledger.inventory_before, ledger.player_deck, 3).valid ||
      ledger.player_deck.length === 0 && checkpoint !== TOWN_ENCOUNTER_CHECKPOINT ||
      ledger.player_deck.length === 3 && checkpoint === TOWN_ENCOUNTER_CHECKPOINT ||
      !validateDeck(ledger.inventory_before, ledger.historical_deck, ledger.historical_deck.length).valid ||
      ledger.opponent_deck.some((card) => !getCardDefinition(getCardId(card))) ||
      !Number.isSafeInteger(ledger.gold_reward.min) || !Number.isSafeInteger(ledger.gold_reward.max) || ledger.gold_reward.min < 0 || ledger.gold_reward.max < ledger.gold_reward.min ||
      ledger.loss_gold !== Math.floor((ledger.gold_reward.min + ledger.gold_reward.max) / 4) ||
      !Number.isSafeInteger(ledger.acknowledged) || ledger.acknowledged < 0 || ledger.acknowledged > ledger.rounds.length ||
      ledger.rounds.length - ledger.acknowledged > 1 || typeof ledger.settled !== 'boolean' ||
      !Number.isSafeInteger(ledger.balance_before) || ledger.balance_before < 0 ||
      !ledger.settled && JSON.stringify(save.player.equipment ?? []) !== JSON.stringify(ledger.equipment_before ?? [])) {
    throw new Error('Invalid random battle ledger')
  }
  const view = randomBattleView(save)
  if (!ledger.settled) {
    if (![TOWN_ENCOUNTER_CHECKPOINT, RANDOM_BATTLE_CHECKPOINT].includes(checkpoint) || ledger.gold_delta !== undefined || ledger.bonus_capture_index !== undefined ||
        save.player.money !== ledger.balance_before || JSON.stringify(save.player.inventory) !== JSON.stringify(ledger.inventory_before) ||
        JSON.stringify(save.player.items ?? []) !== JSON.stringify(ledger.items_before) ||
        checkpoint === RANDOM_BATTLE_CHECKPOINT && view.outcome && ledger.acknowledged === ledger.rounds.length) {
      throw new Error('Unsettled random battle state mismatch')
    }
  } else {
    const outcome = view.outcome
    if (checkpoint !== TOWN_CHECKPOINT || outcome === undefined || ledger.acknowledged !== ledger.rounds.length || !Number.isSafeInteger(ledger.gold_delta)) {
      throw new Error('Invalid random battle settlement')
    }
    const delta = ledger.gold_delta!
    const bonusCandidates = outcome === 'win' && (ledger.equipment_before ?? []).includes('greed_ring')
      ? ledger.opponent_deck.map((_, index) => index).filter((index) => !view.usedOpponent.includes(index)) : []
    const min = outcome === 'win' ? ledger.gold_reward.min + getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id })))
      : outcome === 'lose' ? -Math.min(ledger.balance_before, ledger.loss_gold) : 0
    const max = outcome === 'win' ? ledger.gold_reward.max + getGoldBonus((ledger.equipment_before ?? []).map((id) => ({ id }))) : min
    if (delta < min || delta > max || save.player.money !== ledger.balance_before + delta ||
        JSON.stringify(save.player.inventory) !== JSON.stringify(settledInventory(ledger, outcome)) ||
        JSON.stringify(save.player.items ?? []) !== JSON.stringify(settledItems(ledger, outcome)) ||
        (bonusCandidates.length > 0 && (!Number.isSafeInteger(ledger.bonus_capture_index) ||
          !bonusCandidates.includes(ledger.bonus_capture_index!))) ||
        (bonusCandidates.length === 0 && ledger.bonus_capture_index !== undefined)) {
      throw new Error('Random battle reward does not match its ledger')
    }
  }
}
