import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalStrengthGame, chooseOriginalStrength } from '../../packages/story/original-strength-game'
import { finishOriginalStrengthSave } from '../../packages/story/original-strength-save'

test('original strength save validates location and finishes at the same original checkpoint', () => {
  const rolls = Array(5).fill(0)
  let game = createOriginalStrengthGame(rolls)
  const base = createNewGameSave()
  const draft = { ...base, progress: { ...base.progress, checkpoint_id: 'original:stage4_recover:18', original_strength_game: { game, cursor: 0 } } }
  assert.deepEqual(parseSave(draft).progress.original_strength_game, draft.progress.original_strength_game)
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, checkpoint_id: 'original:stage4_recover:17' } }))
  assert.throws(() => finishOriginalStrengthSave(parseSave(draft)))
  for (let turn = 0; turn < 3; turn++) game = chooseOriginalStrength(game, '_pisuke', 0, rolls)
  const save = parseSave({ ...draft, progress: { ...draft.progress, original_strength_game: { game, cursor: game.commands.length } } })
  const next = finishOriginalStrengthSave(save)
  assert.deepEqual(next.player, save.player)
  assert.equal(next.progress.checkpoint_id, draft.progress.checkpoint_id)
  assert.deepEqual(next.progress.original_completed_minigames, [draft.progress.checkpoint_id])
  assert.equal(next.progress.original_strength_game, undefined)
  assert.throws(() => finishOriginalStrengthSave(next))
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, original_strength_game: { game, cursor: -1 } } }))
})
