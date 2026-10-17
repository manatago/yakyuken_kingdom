import assert from 'node:assert/strict'
import test from 'node:test'
import { developerTools, developerJumpTarget, createDeveloperJumpSave } from '../../packages/developer/jump'
import { parseSave } from '../../packages/domain/save'
import { originalStory } from '../../packages/story/original'
import { advanceOriginalQuestStory } from '../../packages/story/original-flow'

test('jump states use original money, flags and cards without sharing arrays', () => {
  const index = developerTools.jump_points.findIndex(point => point.label === 'subevent1_jin_battle')
  const save = createDeveloperJumpSave(index)
  assert.equal(save.player.money, 100)
  assert.equal(save.player.inventory.length, 9)
  assert.equal(save.progress.original_quest?.id, 'subevent1')
  assert.match(save.progress.checkpoint_id, /^original:subevent1_hideout:/)
  const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
  assert.equal(originalStory.sequences.find(scene => scene.id === sequence)!.commands[Number(cursor) - 1].parameters.label_name, 'subevent1_jin_battle')
  assert.deepEqual(parseSave(save), save)
  save.player.inventory.pop()
  assert.equal(createDeveloperJumpSave(index).player.inventory.length, 9)
})

test('every original entry is resolved or explicitly unavailable, never silently starts prologue', () => {
  assert.equal(developerTools.jump_points.length, 108)
  for (let i = 0; i < developerTools.jump_points.length; i++) {
    const target = developerJumpTarget(i)
    if (target.available) assert.doesNotThrow(() => parseSave(createDeveloperJumpSave(i)))
    else assert.throws(() => createDeveloperJumpSave(i))
  }
  for (const value of [-1, 108, 0.5, NaN, '../main']) assert.throws(() => developerJumpTarget(value))
})

test('guild and minigame starts remain separate from normal save data', () => {
  const guild = createDeveloperJumpSave(developerTools.jump_points.findIndex(point => point.label === '_guild_home'))
  assert.equal(guild.progress.checkpoint_id, 'guild.home')
  assert.ok(guild.progress.guild_return_checkpoint)
  const mini = developerJumpTarget(developerTools.jump_points.findIndex(point => point.label === '_minigame:minigame_stage5'))
  assert.equal(mini.available, true)
  if (mini.available) {
    assert.equal(mini.sequence, 'stage5_recover')
    assert.equal(originalStory.sequences.find(scene => scene.id === mini.sequence)!.commands[mini.cursor - 1].kind, 'battle')
  }
})

test('late quest starts seed only prior settlements and can finish without weakening normal guards', () => {
  const save = createDeveloperJumpSave(developerTools.jump_points.findIndex(point => point.label === '_subevent_post:subevent1'))
  assert.equal(save.progress.original_quest?.completed_battles?.length, 4)
  const commands = originalStory.sequences.find(scene => scene.id === 'subevent1_post')!.commands
  const finished = { ...save, progress: { ...save.progress, checkpoint_id: `original:subevent1_post:${commands.length}` } }
  assert.equal(advanceOriginalQuestStory(finished).progress.checkpoint_id, 'guild.home')
  const beforeJin = createDeveloperJumpSave(developerTools.jump_points.findIndex(point => point.label === 'subevent1_jin_battle'))
  assert.deepEqual(beforeJin.progress.original_quest?.completed_battles, [])
})
