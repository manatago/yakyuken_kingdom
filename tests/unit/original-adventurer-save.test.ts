import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalAdventurer } from '../../packages/story/original-adventurer'

test('adventurer tutorial ledger belongs only to its original battle command', () => {
  const initial = createNewGameSave()
  const saved = { ...initial, progress: { ...initial.progress, checkpoint_id: 'original:stage1:113', original_adventurer: createOriginalAdventurer() } }
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(saved))), saved)
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress, checkpoint_id: 'original:stage1:112' } }))
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress, original_adventurer: { ...saved.progress.original_adventurer, gold: 100 } } }))
})
