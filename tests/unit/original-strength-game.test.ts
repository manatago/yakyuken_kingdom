import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalStrengthGame, chooseOriginalStrength, restoreOriginalStrengthGame } from '../../packages/story/original-strength-game'

test('original strength support is available immediately and preserves replay', () => {
  const initial = createOriginalStrengthGame([0, 0, 0, 0, 0])
  assert.equal(initial.gauge, 110)
  assert.equal(initial.choices.length, 3)
  const second = chooseOriginalStrength(initial, '_pisuke', 0, [0, 0, 0, 0, 0])
  assert.equal(second.gauge, 70)
  assert.equal(initial.gauge, 110)
  assert.deepEqual(restoreOriginalStrengthGame(second), second)
  const third = chooseOriginalStrength(second, '_pisuke', 0, [0, 0, 0, 0, 0])
  assert.equal(third.gauge, 30)
  const last = chooseOriginalStrength(third, '_pisuke', 0, [0, 0, 0, 0, 0])
  assert.equal(last.outcome, 'win')
  assert.throws(() => restoreOriginalStrengthGame({ ...second, gauge: 71 }))
})

test('original strength wrong intensity and misses lose after four choices', () => {
  let game = createOriginalStrengthGame([0, 0, 0, 0, 0])
  for (let i = 0; i < 4; i++) {
    const choice = game.choices.find(choice => choice.pool === 'miss')!
    game = chooseOriginalStrength(game, choice, 0, [0, 0, 0, 0, 0])
  }
  assert.equal(game.gauge, 130)
  assert.equal(game.outcome, 'lose')
  assert.deepEqual(restoreOriginalStrengthGame(game), game)
  assert.throws(() => chooseOriginalStrength(game, '_pisuke', 0, [0, 0, 0, 0, 0]))
})
