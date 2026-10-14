import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { originalStory } from '../../packages/story/original'

test('all original sequences accept bounded saved cursors; unknown or malformed originals are rejected', () => {
  const initial = createNewGameSave()
  const saved = (checkpoint_id: string) => ({ ...initial, progress: { ...initial.progress, checkpoint_id } })
  for (const sequence of originalStory.sequences) {
    for (const cursor of [0, sequence.commands.length]) {
      assert.deepEqual(parseSave(saved(`original:${sequence.id}:${cursor}`)), saved(`original:${sequence.id}:${cursor}`))
    }
  }
  for (const checkpoint of ['original:unknown:0', 'original:prologue:-1', 'original:prologue:1.5',
    'original:prologue:9999', 'original:prologue:NaN', 'original:prologue:6:extra']) {
    assert.throws(() => parseSave(saved(checkpoint)), checkpoint)
  }
})
