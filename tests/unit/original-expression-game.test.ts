import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalExpressionGame, chooseOriginalExpression, restoreOriginalExpressionGame, originalExpressionSource } from '../../packages/story/original-expression-game'

test('original Stage 2 enforces the first-turn support lock and selects unused scenes', () => {
  let game = createOriginalExpressionGame(0)
  assert.equal(game.scene, 0)
  assert.equal(game.gauge, 100)
  assert.throws(() => chooseOriginalExpression(game, '_pisuke', 0))
  const first = chooseOriginalExpression(game, 'blush', 0)
  assert.equal(first.gauge, 60)
  assert.equal(first.scene, 1)
  assert.equal(game.gauge, 100)
  game = chooseOriginalExpression(first, '_pisuke', 0)
  assert.equal(game.gauge, 20)
  assert.equal(game.scene, 2)
  game = chooseOriginalExpression(game, '_pisuke', 0)
  assert.equal(game.outcome, 'win')
  assert.equal(game.gauge, 0)
  assert.deepEqual(restoreOriginalExpressionGame(game), game)
  assert.throws(() => restoreOriginalExpressionGame({ ...game, gauge: 1 }))
  assert.throws(() => chooseOriginalExpression(game, 'shake', 0))
})

test('original Stage 2 terminates immediately at 130 and resets a fully consumed scene pool', () => {
  let losing = createOriginalExpressionGame(0)
  for (let index = 0; index < 6; index++) losing = chooseOriginalExpression(losing, 'panic', 0)
  assert.equal(losing.gauge, 130)
  assert.equal(losing.outcome, 'lose')
  let game = createOriginalExpressionGame(0)
  for (let index = 0; index < 10; index++) {
    const pick = index === 0 || index === 7 ? originalExpressionSource.scenes[game.scene].expression : 'panic'
    game = chooseOriginalExpression(game, pick, 0)
  }
  assert.equal(game.outcome, undefined)
  assert.equal(game.scene, 0)
  assert.deepEqual(game.usedScenes, [0])
  assert.deepEqual(restoreOriginalExpressionGame(game), game)
})
