import { GRADES, HANDS, type Card } from './card'
import { validateDeck } from './deck'

export const SAVE_VERSION = 1 as const

export interface SavePlayer {
  readonly inventory: readonly Card[]
  readonly deck: readonly Card[]
  readonly money: number
}

export interface SaveData {
  readonly save_version: typeof SAVE_VERSION
  readonly player: SavePlayer
  readonly progress: {
    readonly checkpoint_id: string
    readonly flags: readonly string[]
  }
}

function record(value: unknown, fields: readonly string[]): Record<string, unknown> {
  if (value === null || typeof value !== 'object' || Array.isArray(value)) {
    throw new TypeError('Save field must be an object')
  }
  const prototype = Object.getPrototypeOf(value)
  if (prototype !== Object.prototype && prototype !== null) {
    throw new TypeError('Save field must be a plain object')
  }
  const keys = Reflect.ownKeys(value)
  if (keys.length !== fields.length || keys.some((key) => typeof key !== 'string' || !fields.includes(key))) {
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

  const player = record(root.player, ['inventory', 'deck', 'money'])
  const inventory = cards(player.inventory)
  const deck = cards(player.deck)
  if (!Number.isSafeInteger(player.money) || (player.money as number) < 0) {
    throw new RangeError('Save money must be a non-negative safe integer')
  }
  if (deck.length > 0 && !validateDeck(inventory, deck, deck.length).valid) {
    throw new RangeError('Save deck contains cards not owned by the player')
  }

  const progress = record(root.progress, ['checkpoint_id', 'flags'])
  if (!Array.isArray(progress.flags)) throw new TypeError('Save flags must be an array')
  const flags = Array.from(progress.flags, identifier)
  if (new Set(flags).size !== flags.length) throw new TypeError('Save flags must be unique')

  return {
    save_version: SAVE_VERSION,
    player: { inventory, deck, money: player.money as number },
    progress: { checkpoint_id: identifier(progress.checkpoint_id), flags }
  }
}

export function createNewSave(checkpointId: string, player: SavePlayer): SaveData {
  return parseSave({
    save_version: SAVE_VERSION,
    player,
    progress: { checkpoint_id: checkpointId, flags: [] }
  })
}
