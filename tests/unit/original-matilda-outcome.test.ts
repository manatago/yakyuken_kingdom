import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalJanken, originalMatildaOutcome, selectOriginalCard, resolveOriginalJanken } from '../../packages/battle/original-janken'
import { createOriginalMatildaRoundPlayback, nextOriginalBattleCommand } from '../../packages/story/original-battle'

test('normal Matilda trace changes outfit on a win and preserves repeat state after a draw or loss', () => {
  let state = createOriginalJanken()
  assert.deepEqual(createOriginalMatildaRoundPlayback(state), { method: 'outfit_3', repeated: false, cursor: 0, results: [] })
  state = resolveOriginalJanken(selectOriginalCard(state, 3), { fixed: 'rock' }, 0)
  assert.equal(createOriginalMatildaRoundPlayback(state)?.repeated, true)
  state = resolveOriginalJanken(selectOriginalCard(state, 6), { fixed: 'rock' }, 0)
  assert.deepEqual(createOriginalMatildaRoundPlayback(state), { method: 'outfit_2', repeated: false, cursor: 0, results: [] })
  state = resolveOriginalJanken(selectOriginalCard(state, 0), { fixed: 'rock' }, 0)
  const repeated = createOriginalMatildaRoundPlayback(state)!
  assert.equal(repeated.method, 'outfit_2')
  assert.equal(repeated.repeated, true)
  assert.ok(nextOriginalBattleCommand(repeated))
  assert.equal(createOriginalMatildaRoundPlayback({ ...state, playerHp: 0 }), undefined)
  assert.equal(createOriginalMatildaRoundPlayback({ ...state, opponentHp: 0 }), undefined)
})

test('original normal Matilda battle finishes by HP first, then original deck exhaustion order', () => {
  const state = createOriginalJanken()
  assert.equal(originalMatildaOutcome(state), undefined)
  assert.equal(originalMatildaOutcome({ ...state, opponentHp: 0, playerHp: 0 }), 'win')
  assert.equal(originalMatildaOutcome({ ...state, playerHp: 0 }), 'lose')
  const exhausted = Array(9).fill(true)
  assert.equal(originalMatildaOutcome({ ...state, playerUsed: exhausted, opponentUsed: exhausted }), 'draw')
  assert.equal(originalMatildaOutcome({ ...state, playerUsed: exhausted }), 'lose')
  assert.equal(originalMatildaOutcome({ ...state, opponentUsed: exhausted }), 'win')
})
