import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalQuestionGame, chooseOriginalQuestion, restoreOriginalQuestionGame } from '../../packages/story/original-question-game'
test('original question game changes question pool by gauge and replays support victory', () => {
  const rolls = Array(7).fill(0)
  const initial = createOriginalQuestionGame(rolls)
  assert.equal(initial.gauge, 100)
  assert.equal(initial.pool, 'red')
  assert.equal(initial.choices.length, 4)
  assert.equal(initial.commands.at(-2)?.kind, 'narrator_band')
  let game = chooseOriginalQuestion(initial, 1, rolls)
  assert.equal(game.gauge, 60)
  assert.equal(game.pool, 'strong')
  game = chooseOriginalQuestion(game, 1, rolls)
  assert.equal(game.gauge, 20)
  game = chooseOriginalQuestion(game, 1, rolls)
  assert.equal(game.outcome, 'win')
  assert.deepEqual(restoreOriginalQuestionGame(game), game)
  assert.equal(initial.gauge, 100)
  assert.throws(() => restoreOriginalQuestionGame({ ...game, gauge: 1 }))
})
test('original question game misses preserve question cycling and reach loss', () => {
  const rolls = Array(7).fill(0)
  let game = createOriginalQuestionGame(rolls)
  for (let turn = 0; turn < 6; turn++) game = chooseOriginalQuestion(game, game.choices.find(pick => pick >= 2)!, rolls)
  assert.equal(game.outcome, 'lose')
  assert.equal(game.gauge, 130)
  assert.deepEqual(restoreOriginalQuestionGame(game), game)
})
