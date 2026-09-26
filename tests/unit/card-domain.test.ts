import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { CARD_CATALOG, getCardDefinition, getCardId } from '../../packages/domain/card-catalog'
import { judgeCards, type Card, type Hand } from '../../packages/domain/card'
import { validateDeck } from '../../packages/domain/deck'
import { applyBattlePayout } from '../../packages/domain/player-state'

const normal = (hand: Hand): Card => ({ hand, grade: 1 })

test('all nine hand combinations use rock-paper-scissors rules', () => {
  const expected = {
    rock: { rock: 'draw', scissors: 'win', paper: 'lose' },
    scissors: { rock: 'lose', scissors: 'draw', paper: 'win' },
    paper: { rock: 'win', scissors: 'lose', paper: 'draw' }
  } as const
  for (const player of ['rock', 'scissors', 'paper'] as const) {
    for (const opponent of ['rock', 'scissors', 'paper'] as const) {
      assert.equal(judgeCards(normal(player), normal(opponent)), expected[player][opponent])
    }
  }
})

test('grade matters only when both cards show the same hand', () => {
  assert.equal(judgeCards({ hand: 'rock', grade: 5 }, { hand: 'rock', grade: 4 }), 'win')
  assert.equal(judgeCards({ hand: 'rock', grade: 1 }, { hand: 'rock', grade: 2 }), 'lose')
  assert.equal(judgeCards({ hand: 'rock', grade: 3 }, { hand: 'rock', grade: 3 }), 'draw')
  assert.equal(judgeCards({ hand: 'rock', grade: 1 }, { hand: 'scissors', grade: 5 }), 'win')
})

test('deck requires the configured size and cannot exceed owned copies', () => {
  const inventory = [normal('rock'), normal('rock'), normal('paper')]
  const before = structuredClone(inventory)
  assert.deepEqual(validateDeck(inventory, [normal('rock'), normal('paper')], 2), { valid: true })
  assert.deepEqual(validateDeck(inventory, [normal('rock')], 2), { valid: false, reason: 'size' })
  assert.deepEqual(validateDeck(inventory, [normal('rock'), normal('rock'), normal('rock')], 3), {
    valid: false,
    reason: 'not_owned'
  })
  assert.deepEqual(validateDeck(inventory, [{ hand: 'rock', grade: 2 }], 1), {
    valid: false,
    reason: 'not_owned'
  })
  assert.deepEqual(inventory, before)
})

test('battle payout adds captured cards and gold only on victory without mutating input', () => {
  const state = { inventory: [normal('rock')], money: 10 }
  const payout = { cards: [{ hand: 'paper', grade: 2 } as Card], gold: 7, canTransferCards: true }
  assert.deepEqual(applyBattlePayout(state, 'win', payout), {
    inventory: [normal('rock'), { hand: 'paper', grade: 2 }],
    money: 17
  })
  assert.deepEqual(state, { inventory: [normal('rock')], money: 10 })
  assert.deepEqual(applyBattlePayout(state, 'win', { ...payout, canTransferCards: false }), {
    inventory: [normal('rock')],
    money: 17
  })
})

test('battle loss removes matching copies and never makes money negative', () => {
  const state = { inventory: [normal('rock'), normal('rock'), normal('paper')], money: 3 }
  const payout = { cards: [normal('rock'), normal('rock')], gold: 10, canTransferCards: true }
  assert.deepEqual(applyBattlePayout(state, 'lose', payout), {
    inventory: [normal('paper')],
    money: 0
  })
  assert.deepEqual(applyBattlePayout(state, 'lose', { ...payout, canTransferCards: false }), {
    inventory: state.inventory,
    money: 0
  })
  assert.deepEqual(state.inventory, [normal('rock'), normal('rock'), normal('paper')])
})

test('draw leaves inventory and money unchanged', () => {
  const state = { inventory: [normal('scissors')], money: 4 }
  const payout = { cards: [normal('rock')], gold: 9, canTransferCards: true }
  assert.deepEqual(applyBattlePayout(state, 'draw', payout), state)
})

test('catalog maps all fifteen card IDs to existing images', () => {
  const root = fileURLToPath(new URL('../..', import.meta.url))
  assert.equal(CARD_CATALOG.length, 15)
  assert.equal(new Set(CARD_CATALOG.map((entry) => entry.id)).size, 15)
  for (const entry of CARD_CATALOG) {
    assert.equal(getCardId(entry), entry.id)
    assert.deepEqual(getCardDefinition(entry.id), entry)
    assert.equal(existsSync(join(root, entry.imagePath)), true, entry.imagePath)
  }
  assert.equal(getCardDefinition('unknown'), undefined)
})
