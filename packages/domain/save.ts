import { GRADES, HANDS, type Card } from './card'
import { validateDeck } from './deck'
import { validateTutorialState, type TutorialLedger } from '../battle/tutorial'
import { validateFixedState, type FixedLedger } from '../battle/fixed'
import { BELKA_CHECKPOINT, validateBelkaState, type BelkaLedger } from '../battle/belka'
import { guildValidationSave } from '../guild/routes'

export const SAVE_VERSION = 1 as const

export interface SavePlayer {
  readonly inventory: readonly Card[]
  readonly deck: readonly Card[]
  readonly prepared_deck?: readonly Card[]
  readonly money: number
}

export interface SaveData {
  readonly save_version: typeof SAVE_VERSION
  readonly player: SavePlayer
  readonly progress: {
    readonly checkpoint_id: string
    readonly flags: readonly string[]
    readonly tutorial?: TutorialLedger
    readonly fixed_battle?: FixedLedger
    readonly belka_battle?: BelkaLedger
    readonly guild_return_checkpoint?: string
  }
}

function record(value: unknown, fields: readonly string[], optional: readonly string[] = []): Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError('Save field must be an object')
  }
  const prototype = Object.getPrototypeOf(value)
  if (prototype !== Object.prototype && prototype !== null) {
    throw new TypeError('Save field must be a plain object')
  }
  const keys = Reflect.ownKeys(value)
  if (fields.some((key) => !Object.hasOwn(value, key)) ||
      keys.some((key) => typeof key !== 'string' || ![...fields, ...optional].includes(key))) {
    throw new TypeError('Save field has missing or unknown keys')
  }
  for (const key of keys) {
    const descriptor = Object.getOwnPropertyDescriptor(value, key)
    if (!descriptor || !('value' in descriptor)) throw new TypeError('Save field has an accessor')
  }
  return value as Record<string, unknown>
}

function identifier(value: unknown): string {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new TypeError('Save identifier must be a non-empty string')
  }
  return value
}

function cards(value: unknown): Card[] {
  if (!Array.isArray(value)) throw new TypeError('Save cards must be an array')
  return Array.from(value, (entry) => {
    const card = record(entry, ['hand', 'grade'])
    if (!HANDS.includes(card.hand as Card['hand']) || !GRADES.includes(card.grade as Card['grade'])) {
      throw new TypeError('Save card has an invalid hand or grade')
    }
    return { hand: card.hand as Card['hand'], grade: card.grade as Card['grade'] }
  })
}

export function parseSave(value: unknown): SaveData {
  const root = record(value, ['save_version', 'player', 'progress'])
  if (root.save_version !== SAVE_VERSION) throw new RangeError('Unsupported save version')

  const player = record(root.player, ['inventory', 'deck', 'money'], ['prepared_deck'])
  const inventory = cards(player.inventory)
  const deck = cards(player.deck)
  const prepared = Object.hasOwn(player, 'prepared_deck') ? cards(player.prepared_deck) : undefined
  if (prepared && !validateDeck(inventory, prepared, 9).valid) {
    throw new RangeError('Prepared deck must contain nine owned cards')
  }
  if (!Number.isSafeInteger(player.money) || (player.money as number) < 0) {
    throw new RangeError('Save money must be a non-negative safe integer')
  }
  if (deck.length > 0 && !validateDeck(inventory, deck, deck.length).valid) {
    throw new RangeError('Save deck contains cards not owned by the player')
  }

  const progress = record(root.progress, ['checkpoint_id', 'flags'], ['tutorial', 'fixed_battle', 'belka_battle', 'guild_return_checkpoint'])
  if (!Array.isArray(progress.flags)) throw new TypeError('Save flags must be an array')
  const flags = Array.from(progress.flags, identifier)
  if (new Set(flags).size !== flags.length) throw new TypeError('Save flags must be unique')

  let tutorial: TutorialLedger | undefined
  if (Object.hasOwn(progress, 'tutorial')) {
    const ledger = record(progress.tutorial, ['battle_id', 'rounds', 'acknowledged'])
    if (!Array.isArray(ledger.rounds) || ledger.rounds.length > 2) throw new TypeError('Invalid tutorial rounds')
    tutorial = {
      battle_id: identifier(ledger.battle_id), acknowledged: ledger.acknowledged as number,
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      })
    }
  }
  let fixed: FixedLedger | undefined
  if (Object.hasOwn(progress, 'fixed_battle')) {
    const ledger = record(progress.fixed_battle, ['battle_id', 'player_deck', 'rounds', 'acknowledged', 'settled', 'balance_before'], ['gold_delta'])
    if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid fixed battle rounds')
    fixed = {
      battle_id: identifier(ledger.battle_id), player_deck: cards(ledger.player_deck),
      acknowledged: ledger.acknowledged as number, settled: ledger.settled as boolean,
      balance_before: ledger.balance_before as number,
      ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      })
    }
  }
  let belka: BelkaLedger | undefined
  if (Object.hasOwn(progress, 'belka_battle')) {
    const ledger = record(progress.belka_battle, ['battle_id', 'origin_checkpoint', 'player_deck', 'rounds', 'acknowledged', 'settled', 'balance_before'], ['gold_delta'])
    if (!Array.isArray(ledger.rounds)) throw new TypeError('Invalid Belka rounds')
    belka = {
      battle_id: identifier(ledger.battle_id), origin_checkpoint: identifier(ledger.origin_checkpoint) as BelkaLedger['origin_checkpoint'],
      player_deck: cards(ledger.player_deck), acknowledged: ledger.acknowledged as number,
      settled: ledger.settled as boolean, balance_before: ledger.balance_before as number,
      ...(Object.hasOwn(ledger, 'gold_delta') ? { gold_delta: ledger.gold_delta as number } : {}),
      rounds: Array.from(ledger.rounds, (entry) => {
        const round = record(entry, ['player_index', 'opponent_index'])
        return { player_index: round.player_index as number, opponent_index: round.opponent_index as number }
      })
    }
  }
  const save: SaveData = {
    save_version: SAVE_VERSION,
    player: { inventory, deck, money: player.money as number, ...(prepared ? { prepared_deck: prepared } : {}) },
    progress: { checkpoint_id: identifier(progress.checkpoint_id), flags, ...(tutorial ? { tutorial } : {}), ...(fixed ? { fixed_battle: fixed } : {}),
      ...(belka ? { belka_battle: belka } : {}),
      ...(Object.hasOwn(progress, 'guild_return_checkpoint') ? { guild_return_checkpoint: identifier(progress.guild_return_checkpoint) } : {}) }
  }
  const historicalCheckpoint = save.progress.checkpoint_id === BELKA_CHECKPOINT
    ? { ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }
    : guildValidationSave(save)
  const validationSave = belka
    ? { ...historicalCheckpoint, player: { ...historicalCheckpoint.player, money: belka.balance_before } }
    : historicalCheckpoint
  validateTutorialState(validationSave)
  validateFixedState(validationSave)
  validateBelkaState(save)
  return save
}

export function createNewSave(checkpointId: string, player: SavePlayer): SaveData {
  return parseSave({
    save_version: SAVE_VERSION,
    player,
    progress: { checkpoint_id: checkpointId, flags: [] }
  })
}
