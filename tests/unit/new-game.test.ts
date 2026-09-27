import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave, MATILDA_START_CHECKPOINT } from '../../packages/domain/new-game'

test('new game begins at Matilda with the Godot default Normal cards', () => {
  const save = createInitialGameSave()
  assert.equal(save.progress.checkpoint_id, MATILDA_START_CHECKPOINT)
  assert.deepEqual(save.progress.flags, [])
  assert.equal(save.player.money, 0)
  assert.deepEqual(save.player.deck, [])
  assert.deepEqual(save.player.inventory, [
    ...Array.from({ length: 3 }, () => ({ hand: 'rock', grade: 1 })),
    ...Array.from({ length: 3 }, () => ({ hand: 'scissors', grade: 1 })),
    ...Array.from({ length: 3 }, () => ({ hand: 'paper', grade: 1 }))
  ])
})
