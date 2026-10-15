import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { ORIGINAL_STAGE1_END } from '../../packages/guild/routes'
import { createOriginalCurseGame, playOriginalCurseChoice } from '../../packages/story/original-curse-game'
import { finishOriginalCurseSave } from '../../packages/story/original-curse-save'

test('actual Godot minigame return continues the same story without rewards or a fabricated defeat redirect', () => {
  const rolls = Array(8).fill(0)
  const initial = createOriginalCurseGame(rolls)
  const win = Array.from({length: 3}).reduce(game => playOriginalCurseChoice(game, 'pisuke', 0, rolls), initial)
  const positiveRolls = [7 / 18, 0, 0, 0, 7 / 18, 0, 0, 0]
  const start = createOriginalCurseGame(positiveRolls)
  const lose = playOriginalCurseChoice(playOriginalCurseChoice(start, 7, 0, positiveRolls), 7, 0, positiveRolls)
  for (const game of [win, lose]) {
    const base = createNewGameSave()
    const save = { ...base, progress: { ...base.progress, checkpoint_id: 'original:subevent3_visit:71',
      original_quest: { id: 'subevent3' as const, route: 'full' as const, origin_checkpoint: ORIGINAL_STAGE1_END },
      original_curse_game: { game, cursor: game.commands.length } } }
    const finished = finishOriginalCurseSave(save)
    assert.equal(finished.progress.checkpoint_id, save.progress.checkpoint_id)
    assert.deepEqual(finished.player, base.player)
    assert.deepEqual(finished.progress.original_quest?.completed_battles, ['original:subevent3_visit:71'])
    assert.equal(finished.progress.original_curse_game, undefined)
    assert.throws(() => finishOriginalCurseSave(finished))
    assert.throws(() => finishOriginalCurseSave({ ...save, progress: { ...save.progress, original_curse_game: { game, cursor: 0 } } }))
  }
})
