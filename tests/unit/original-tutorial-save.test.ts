import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalTutorial } from '../../packages/story/original-tutorial'

test('original tutorial progress is saved only at its actual Godot battle command', () => {
  const initial = createNewGameSave()
  const saved = { ...initial, progress: { ...initial.progress, checkpoint_id: 'original:prologue:198',
    original_tutorial: createOriginalTutorial() } }
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(saved))), saved)
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress, checkpoint_id: 'original:prologue:6' } }))
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress,
    original_tutorial: { ...saved.progress.original_tutorial, gold: 30 } } }))
})
