import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalBattleCards, createOriginalJanken, selectOriginalCard, resolveOriginalJanken } from '../../packages/battle/original-janken'

test('original greed ring consumes one randomly selected remaining opponent copy only on a win', () => {
  const initial = selectOriginalCard(createOriginalBattleCards([{ hand: 'paper', grade: 1 }],
    [{ hand: 'rock', grade: 1 }, { hand: 'scissors', grade: 2 }, { hand: 'paper', grade: 3 }], 1, 1), 0)
  const result = resolveOriginalJanken(initial, { fixed: 'rock', doubleCapture: true, captureRoll: .99 }, 0)
  assert.deepEqual(result.opponentUsed, [true, false, true])
  assert.deepEqual(result.rounds[0].extraOpponent, { hand: 'paper', grade: 3 })
  assert.equal(result.opponentHp, 0)
  assert.deepEqual(initial.opponentUsed, [false, false, false])
  const empty = selectOriginalCard(createOriginalBattleCards([{ hand: 'paper', grade: 1 }], [{ hand: 'rock', grade: 1 }], 1, 1), 0)
  assert.equal(resolveOriginalJanken(empty, { doubleCapture: true, captureRoll: 0 }, 0).rounds[0].extraOpponent, undefined)
  assert.equal(resolveOriginalJanken(initial, { fixed: 'scissors', doubleCapture: true, captureRoll: 0 }, 0).rounds[0].extraOpponent, undefined)
})

test('original shield preserves HP but not lost cards; substitute protects cards but not HP', () => {
  const state = selectOriginalCard(createOriginalJanken(), 0)
  const shield = resolveOriginalJanken(state, { fixed: 'paper', item: 'iron_shield' }, 0)
  assert.equal(shield.playerHp, 3)
  assert.equal(shield.rounds[0].protectedCard, undefined)
  const substitute = resolveOriginalJanken(state, { fixed: 'paper', item: 'substitute_card' }, 0)
  assert.equal(substitute.playerHp, 2)
  assert.equal(substitute.rounds[0].protectedCard, true)
  assert.equal(substitute.playerUsed[0], true)
})

test('original probability items apply before grade correction, and fixed opponent hands bypass them', () => {
  const state = selectOriginalCard(createOriginalJanken(), 0)
  assert.equal(resolveOriginalJanken(state, { item: 'intimidation' }, .3).rounds[0].opponent.hand, 'scissors')
  assert.equal(resolveOriginalJanken(state, { item: 'paper_attract_gold' }, .6).rounds[0].opponent.hand, 'paper')
  assert.equal(resolveOriginalJanken(state, { fixed: 'rock', item: 'paper_attract_gold' }, .99).rounds[0].opponent.hand, 'rock')
})
