import test from 'node:test'
import assert from 'node:assert/strict'
import { createNewGameSave } from '../../packages/domain/new-game'
import { completeOriginalMatildaStory } from '../../packages/story/original-flow'
import { originalStory } from '../../packages/story/original'

test('original victory advances to Stage 1 only after its final dialogue and explicit Next', () => {
  const initial = createNewGameSave()
  const length = originalStory.sequences.find(s => s.id === 'prologue_battle_win')!.commands.length
  const saved = { ...initial, progress: { ...initial.progress, checkpoint_id: `original:prologue_battle_win:${length}` } }
  assert.equal(completeOriginalMatildaStory(saved, 'next').progress.checkpoint_id, 'original:stage1:0')
  assert.throws(() => completeOriginalMatildaStory({ ...saved, progress: { ...saved.progress, checkpoint_id: 'original:prologue_battle_win:0' } }, 'next'))
  assert.throws(() => completeOriginalMatildaStory(saved, 'retry'))
})

test('original loss retry returns to battle_start without repeating tutorial or altering money', () => {
  const initial = createNewGameSave()
  const length = originalStory.sequences.find(s => s.id === 'prologue_battle_lose')!.commands.length
  const saved = { ...initial, progress: { ...initial.progress, checkpoint_id: `original:prologue_battle_lose:${length}` } }
  const retried = completeOriginalMatildaStory(saved, 'retry')
  assert.equal(retried.progress.checkpoint_id, 'original:prologue:234')
  assert.equal(retried.progress.original_normal?.phase, 'deck')
  assert.equal(retried.player.money, saved.player.money)
  assert.deepEqual(retried.player.inventory, saved.player.inventory)
})
