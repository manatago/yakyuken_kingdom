import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalNormal } from '../../packages/story/original-normal'

test('normal Matilda ledger is accepted only at the original normal battle with nine owned cards', () => {
  const initial = createNewGameSave()
  const saved = { ...initial, progress: { ...initial.progress, checkpoint_id: 'original:prologue:234',
    original_normal: createOriginalNormal(initial.player.inventory) } }
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(saved))), saved)
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress, checkpoint_id: 'original:prologue:198' } }))
  assert.throws(() => parseSave({ ...saved, player: { ...saved.player, inventory: [] } }))
  assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress,
    original_normal: { ...saved.progress.original_normal, outcome: 'win' } } }))
})
