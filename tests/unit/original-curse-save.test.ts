import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalCurseGame } from '../../packages/story/original-curse-game'

test('canonical curse minigame is saved only at its own raw quest battle and rejects forged playback', () => {
  const base = createNewGameSave()
  const save = { ...base, progress: { ...base.progress, checkpoint_id: 'original:subevent3_visit:71',
    original_quest: { id: 'subevent3', route: 'full', origin_checkpoint: 'original:stage1:189' },
    original_curse_game: { game: createOriginalCurseGame(Array(8).fill(0)), cursor: 0 } } }
  // Use the mechanically exported route endpoint, not a handwritten chapter length.
  const source = require('../../content/stories/godot-original.json')
  save.progress.original_quest.origin_checkpoint = `original:stage1:${source.sequences.find((entry: {id: string}) => entry.id === 'stage1').commands.length}`
  assert.deepEqual(parseSave(save).progress.original_curse_game, save.progress.original_curse_game)
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress, original_curse_game: { ...save.progress.original_curse_game, cursor: -1 } } }))
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'original:subevent3_visit:72' } }))
})
