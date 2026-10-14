import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { completeOriginalStage1Story, startOriginalQuest, advanceOriginalQuestStory } from '../../packages/story/original-flow'
import { originalStory, restoreOriginalStoryState } from '../../packages/story/original'
import { originalQuestIncomingScene, originalQuestProgressionFlags } from '../../packages/story/original-quests'
import { ORIGINAL_STAGE1_END } from '../../packages/guild/routes'

function guild() {
  const initial = createNewGameSave()
  return completeOriginalStage1Story({ ...initial, progress: { ...initial.progress, checkpoint_id: ORIGINAL_STAGE1_END,
    flags: ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed', 'sub1_cleared', 'sub2_cleared', 'sub3_cleared'],
    random_battles_completed: 3 } })
}

test('guild quests start only original sequences and preserve the original home destination', () => {
  const home = guild()
  const expected = { subevent1: 'subevent1_pre', subevent2: 'subevent2_pre1', subevent3: 'subevent3_pre', subevent4: 'subevent4_pre' } as const
  for (const [id, sequence] of Object.entries(expected)) {
    const next = startOriginalQuest(home, id as keyof typeof expected)
    assert.equal(next.progress.checkpoint_id, `original:${sequence}:0`)
    assert.equal(next.progress.guild_return_checkpoint, undefined)
    assert.deepEqual(next.progress.original_quest, { id, origin_checkpoint: ORIGINAL_STAGE1_END, route: 'full' })
    assert.deepEqual(next.player, home.player)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(next))), next)
    assert.equal(next.progress.subevent1_jin_battle, undefined)
    assert.equal(next.progress.fixed_battle, undefined)
  }
  assert.equal(home.progress.checkpoint_id, 'guild.home')
})

test('original quest pre-scenes follow Main.gd, including the church rematch branch', () => {
  const start = startOriginalQuest(guild(), 'subevent1')
  const length = originalStory.sequences.find(s => s.id === 'subevent1_pre')!.commands.length
  assert.throws(() => advanceOriginalQuestStory(start), /complete/)
  const next = advanceOriginalQuestStory({ ...start, progress: { ...start.progress, checkpoint_id: `original:subevent1_pre:${length}` } })
  assert.equal(next.progress.checkpoint_id, 'original:subevent1_hideout:0')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(next))), next)
  const battleScene = originalStory.sequences.find(s => s.id === 'subevent1_hideout')!
  assert.throws(() => advanceOriginalQuestStory({ ...next, progress: { ...next.progress,
    checkpoint_id: `original:${battleScene.id}:${battleScene.commands.length}` } }), /battle settlement/)
  const home = guild()
  const rematch = startOriginalQuest({ ...home, progress: { ...home.progress,
    flags: [...home.progress.flags, 'encounter_sister_long_seen'] } }, 'subevent2')
  assert.equal(rematch.progress.checkpoint_id, 'original:subevent2_rematch:0')
  assert.equal(rematch.progress.original_quest?.route, 'rematch')
  assert.throws(() => parseSave({ ...start, progress: { ...start.progress, checkpoint_id: 'original:stage1:0' } }), /quest/)
  assert.throws(() => parseSave({ ...start, progress: { ...start.progress,
    original_quest: { ...start.progress.original_quest, id: 'unknown' } } }), /quest/)
})

test('original quest entry preserves the configured tutorial, random-battle and previous-quest gates', () => {
  const home = guild()
  const locked = { ...home, progress: { ...home.progress, flags: [], random_battles_completed: 2 } }
  for (const id of ['subevent1', 'subevent2', 'subevent3', 'subevent4'] as const) assert.throws(() => startOriginalQuest(locked, id), /unlock/)
  assert.throws(() => startOriginalQuest({ ...home, progress: { ...home.progress, checkpoint_id: ORIGINAL_STAGE1_END } }, 'subevent1'))
})

test('all original hideout battles must settle before reporting, then the raw post-scene returns to Guild', () => {
  const initial = guild()
  const started = startOriginalQuest({ ...initial, progress: { ...initial.progress,
    flags: ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed'] } }, 'subevent1')
  const hideout = originalStory.sequences.find(s => s.id === 'subevent1_hideout')!
  const completed = hideout.commands.flatMap((command, index) => command.kind === 'battle' ? [`original:${hideout.id}:${index + 1}`] : [])
  const finished = { ...started, progress: { ...started.progress, checkpoint_id: `original:${hideout.id}:${hideout.commands.length}`,
    original_quest: { ...started.progress.original_quest!, completed_battles: completed } } }
  assert.throws(() => parseSave({ ...finished, progress: { ...finished.progress,
    original_quest: { ...finished.progress.original_quest, completed_battles: [completed[1]] } } }))
  const post = advanceOriginalQuestStory(finished)
  assert.equal(post.progress.checkpoint_id, 'original:subevent1_post:0')
  const length = originalStory.sequences.find(s => s.id === 'subevent1_post')!.commands.length
  const home = advanceOriginalQuestStory({ ...post, progress: { ...post.progress, checkpoint_id: `original:subevent1_post:${length}` } })
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.equal(home.progress.guild_return_checkpoint, ORIGINAL_STAGE1_END)
  assert.equal(home.progress.original_quest, undefined)
  assert.deepEqual(home.player, finished.player)
  assert.deepEqual(home.progress.flags, finished.progress.flags)
  assert.deepEqual(home.progress.original_completed_quests, ['subevent1'])
  assert.equal(startOriginalQuest(home, 'subevent2').progress.original_quest?.id, 'subevent2')
  assert.equal(home.progress.flags.includes('sub1_cleared'), false)
})

test('original quest sequence boundaries reconstruct retained StoryScene visuals after JSON reload', () => {
  const started = startOriginalQuest(guild(), 'subevent1')
  const before = restoreOriginalStoryState('subevent1_pre', originalStory.sequences.find(s => s.id === 'subevent1_pre')!.commands.length)
  const next = { ...started, progress: { ...started.progress, checkpoint_id: 'original:subevent1_hideout:0' } }
  const incoming = originalQuestIncomingScene(parseSave(JSON.parse(JSON.stringify(next))))!
  assert.deepEqual(incoming.portraits, before.portraits)
  assert.equal(incoming.text, before.text)
  assert.equal(incoming.background, before.background)
  const hideout = originalStory.sequences.find(s => s.id === 'subevent1_hideout')!
  const post = { ...next, progress: { ...next.progress, checkpoint_id: 'original:subevent1_post:0',
    original_quest: { ...next.progress.original_quest!, completed_battles: hideout.commands.flatMap((c, i) => c.kind === 'battle' ? [`original:subevent1_hideout:${i + 1}`] : []) } } }
  const retained = originalQuestIncomingScene(parseSave(JSON.parse(JSON.stringify(post))))!
  const firstBelka = restoreOriginalStoryState('subevent1_post', 6, retained.flags, retained)
  assert.equal(firstBelka.portraits.main.visible, true)
  assert.equal(firstBelka.portraits.belka.visible, true)
  incoming.portraits.main.visible = false
  assert.equal(originalQuestIncomingScene(next)!.portraits.main.visible, true)
})

test('completed quests unlock successors without altering original story flags and reject corrupt records', () => {
  const home = guild()
  const flags = ['adventurer.tutorial.completed']
  const completed = { ...home, progress: { ...home.progress, flags, original_completed_quests: ['subevent1'] } }
  assert.equal(originalQuestProgressionFlags(parseSave(completed)).includes('sub1_cleared'), true)
  assert.deepEqual(parseSave(completed).progress.flags, flags)
  assert.equal(startOriginalQuest(completed, 'subevent2').progress.original_quest?.id, 'subevent2')
  for (const invalid of [['unknown'], ['subevent1', 'subevent1'], [1]]) {
    assert.throws(() => parseSave({ ...home, progress: { ...home.progress, original_completed_quests: invalid } }))
  }
})
