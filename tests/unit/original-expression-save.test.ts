import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalExpressionGame, chooseOriginalExpression } from '../../packages/story/original-expression-game'
import { finishOriginalExpressionSave } from '../../packages/story/original-expression-save'

test('original expression ledger is bound to the raw battle and replays every saved action', () => {
  const base = createNewGameSave()
  const save = { ...base, progress: { ...base.progress, checkpoint_id: 'original:stage2_recover:30',
    original_expression_game: { game: createOriginalExpressionGame(0), cursor: 0 } } }
  assert.deepEqual(parseSave(save).progress.original_expression_game, save.progress.original_expression_game)
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'original:stage2_recover:29' } }))
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress,
    original_expression_game: { ...save.progress.original_expression_game, cursor: -1 } } }))
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress,
    original_expression_game: { game: { ...save.progress.original_expression_game.game, gauge: 0 }, cursor: 0 } } }))
  assert.throws(() => finishOriginalExpressionSave(parseSave(save)))
})

test('both expression outcomes resume the same raw story without rewards or duplicate replay', () => {
  for (const outcome of ['win', 'lose'] as const) {
    const base = createNewGameSave()
    let game = createOriginalExpressionGame(0)
    if (outcome === 'win') {
      game = chooseOriginalExpression(game, 'blush', 0)
      game = chooseOriginalExpression(game, '_pisuke', 0)
      game = chooseOriginalExpression(game, '_pisuke', 0)
    } else for (let count = 0; count < 6; count++) game = chooseOriginalExpression(game, 'panic', 0)
    const save = parseSave({ ...base, progress: { ...base.progress, checkpoint_id: 'original:stage2_recover:30',
      original_expression_game: { game, cursor: game.commands.length } } })
    const result = finishOriginalExpressionSave(save)
    assert.deepEqual(result.player, save.player)
    assert.equal(result.progress.checkpoint_id, save.progress.checkpoint_id)
    assert.equal(result.progress.original_expression_game, undefined)
    assert.deepEqual(result.progress.original_completed_minigames, [save.progress.checkpoint_id])
    assert.throws(() => finishOriginalExpressionSave(result))
    assert.throws(() => parseSave({ ...result, progress: { ...result.progress, original_completed_minigames: ['original:stage2_recover:29'] } }))
  }
})
