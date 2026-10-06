import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS } from '../../packages/domain/progression'
import { completeSubevent2, canRetrySubevent2, canStartSubevent2, startSubevent2, subevent2StoryForCheckpoint } from '../../packages/battle/subevent2'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView, fixedContent, opponents, selectOpponent, returnFromFixedBattle, retryFixedBattle } from '../../packages/battle/fixed'
import { judgeCards } from '../../packages/domain/card'
import { enterGuildHome } from '../../packages/guild/home'
import { validateContent } from '../../packages/content/validate'
import { subevent2Content } from '../../packages/battle/subevent2'
import { existsSync } from 'node:fs'
import { resolve } from 'node:path'
import { startStory, nextStoryCheckpoint } from '../../packages/story/runner'
import { canStartStage2 } from '../../packages/battle/stage2'

const projectRoot = process.cwd()

test('Subevent 2 content has valid battle, checkpoints, story graph and existing image paths', () => {
  assert.deepEqual(validateContent(subevent2Content, (path) => existsSync(resolve(projectRoot, path))), { valid: true, issues: [] })
})

function readyForSubevent2() {
  const initial = createInitialGameSave()
  let save = prepareTutorial({ ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end',
    random_battles_completed: 3,
    flags: [...save.progress.flags, 'adventurer.tutorial.completed', SUBEVENT_COMPLETION_FLAGS.subevent1] } }))
}

function winSubevent2Battle(source: ReturnType<typeof readyForSubevent2>) {
  const started = startSubevent2(source)
  let save = { ...started, progress: { ...started.progress, checkpoint_id: 'subevent2.battle.start' } }
  save = prepareFixedBattle(save)
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent2.sister-head')!
  for (let attempt = 0; attempt < 9 && !fixedView(save).outcome; attempt++) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    let choice: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !choice; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponentIndex = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, index, roll)
        if (judgeCards(ledger.player_deck[index]!, opponents(battle)[opponentIndex]!) === 'win') {
          choice = { index, roll }; break
        }
      }
    }
    if (!choice) throw new Error('No winning card is available in the Sister Head battle')
    save = playFixedRound(save, choice.index, choice.roll)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  if (!fixedView(save).outcome) throw new Error('Sister Head battle did not finish')
  if (fixedView(save).outcome !== 'win') throw new Error('Expected to win the Sister Head battle')
  return returnFromFixedBattle(settleFixedBattle(save, 0))
}

function loseSubevent2Battle(source: ReturnType<typeof readyForSubevent2>) {
  const started = startSubevent2(source)
  let save = prepareFixedBattle({ ...started, progress: { ...started.progress, checkpoint_id: 'subevent2.battle.start' } })
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent2.sister-head')!
  for (let attempt = 0; attempt < 9 && !fixedView(save).outcome; attempt++) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    let choice: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !choice; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponentIndex = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, index, roll)
        if (judgeCards(ledger.player_deck[index]!, opponents(battle)[opponentIndex]!) === 'lose') {
          choice = { index, roll }; break
        }
      }
    }
    if (!choice) throw new Error('No losing card is available in the Sister Head battle')
    save = playFixedRound(save, choice.index, choice.roll)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  return returnFromFixedBattle(settleFixedBattle(save, 0))
}

test('Subevent 2 is available only after Sub-event 1 and the cumulative random battle requirement', () => {
  assert.equal(getSubeventUnlockState('subevent2', [], 3).unlocked, false)
  assert.equal(getSubeventUnlockState('subevent2', [SUBEVENT_COMPLETION_FLAGS.subevent1], 2).unlocked, false)
  assert.equal(canStartSubevent2(readyForSubevent2()), true)
})

test('Subevent 2 starts from Guild Home and its story checkpoint survives save reload', () => {
  const started = startSubevent2(readyForSubevent2())
  assert.equal(started.progress.checkpoint_id, 'subevent2.pre.background')
  assert.ok(started.progress.flags.includes('subevent2.started'))
  assert.equal(subevent2StoryForCheckpoint(started.progress.checkpoint_id), 'story.subevent2.pre')
  assert.equal(parseSave(JSON.parse(JSON.stringify(started))).progress.checkpoint_id, started.progress.checkpoint_id)
  assert.throws(() => startSubevent2(started))
})

test('Subevent 2 completion requires the fixed battle victory and returns to Guild Home once', () => {
  let post = winSubevent2Battle(readyForSubevent2())
  assert.equal(post.progress.checkpoint_id, 'subevent2.post.background')
  while (post.progress.checkpoint_id !== 'subevent2.post.end') {
    const story = startStory(subevent2Content, 'story.subevent2.post', post.progress.checkpoint_id)
    post = parseSave({ ...post, progress: { ...post.progress,
      checkpoint_id: nextStoryCheckpoint(subevent2Content, 'story.subevent2.post', story) } })
  }
  const home = completeSubevent2(post)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.equal(home.progress.guild_return_checkpoint, 'subevent2.post.end')
  assert.ok(home.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2))
  assert.equal(canStartStage2(home), true)
  assert.throws(() => completeSubevent2(home))
})

test('Subevent 2 defeat settles once, returns to Guild Home, and does not falsely complete the event', () => {
  const home = parseSave(JSON.parse(JSON.stringify(loseSubevent2Battle(readyForSubevent2()))))
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.equal(home.progress.guild_return_checkpoint, 'subevent2.loss.end')
  assert.equal(home.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2), false)
  assert.equal(canRetrySubevent2(home), true)
  assert.equal(home.player.inventory.length, 6)
  const unchanged = JSON.stringify(home)
  assert.throws(() => retryFixedBattle(home))
  assert.equal(JSON.stringify(home), unchanged)
})
