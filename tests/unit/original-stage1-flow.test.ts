import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { completeOriginalStage1Story } from '../../packages/story/original-flow'
import { originalStory } from '../../packages/story/original'
import { leaveGuildHome } from '../../packages/guild/home'

test('Godot main scenario enters Guild only after the original Stage 1 ending and preserves its save', () => {
  const initial = createNewGameSave()
  const count = originalStory.sequences.find(sequence => sequence.id === 'stage1')!.commands.length
  const completed = { ...initial, progress: { ...initial.progress, checkpoint_id: `original:stage1:${count}`,
    flags: ['adventurer.tutorial.completed'] } }
  const home = completeOriginalStage1Story(completed)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.equal(home.progress.guild_return_checkpoint, completed.progress.checkpoint_id)
  assert.deepEqual(home.player, completed.player)
  assert.deepEqual(home.progress.flags, completed.progress.flags)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(home))), home)
  assert.deepEqual(leaveGuildHome(home), completed)
  assert.throws(() => completeOriginalStage1Story(initial))
  assert.throws(() => completeOriginalStage1Story({ ...completed, progress: { ...completed.progress,
    checkpoint_id: `original:stage1:${count - 1}` } }))
  assert.throws(() => parseSave({ ...home, progress: { ...home.progress, guild_return_checkpoint: 'original:stage1:0' } }))
})
