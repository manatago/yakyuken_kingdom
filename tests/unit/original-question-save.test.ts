import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalQuestionGame, chooseOriginalQuestion } from '../../packages/story/original-question-game'
import { finishOriginalQuestionSave } from '../../packages/story/original-question-save'

test('original question save validates location and finishes at the same original checkpoint', () => {
  const rolls = Array(7).fill(0)
  let game = createOriginalQuestionGame(rolls)
  const base = createNewGameSave()
  const draft = { ...base, progress: { ...base.progress, checkpoint_id: 'original:stage5_recover:65', original_question_game: { game, cursor: 0 } } }
  assert.deepEqual(parseSave(draft).progress.original_question_game, draft.progress.original_question_game)
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, checkpoint_id: 'original:stage5_recover:64' } }))
  assert.throws(() => finishOriginalQuestionSave(parseSave(draft)))
  for (let turn = 0; turn < 3; turn++) game = chooseOriginalQuestion(game, 1, rolls)
  const save = parseSave({ ...draft, progress: { ...draft.progress, original_question_game: { game, cursor: game.commands.length } } })
  const next = finishOriginalQuestionSave(save)
  assert.deepEqual(next.player, save.player)
  assert.equal(next.progress.checkpoint_id, draft.progress.checkpoint_id)
  assert.deepEqual(next.progress.original_completed_minigames, [draft.progress.checkpoint_id])
  assert.equal(next.progress.original_question_game, undefined)
  assert.throws(() => finishOriginalQuestionSave(next))
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, original_question_game: { game, cursor: -1 } } }))
})
