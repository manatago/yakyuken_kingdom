import assert from 'node:assert/strict'
import test from 'node:test'
import { existsSync } from 'node:fs'
import { resolve } from 'node:path'
import document from '../../content/stories/subevent4.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { SUBEVENT_COMPLETION_FLAGS, getSubeventUnlockState } from '../../packages/domain/progression'
import { enterGuildHome } from '../../packages/guild/home'
import { GUILD_CHECKPOINT } from '../../packages/guild/routes'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { fixedContent, prepareFixedBattle, selectOpponent, playFixedRound, acknowledgeFixedRound, fixedView,
  settleFixedBattle, returnFromFixedBattle } from '../../packages/battle/fixed'
import { judgeCards } from '../../packages/domain/card'
import { startStory, nextStoryCheckpoint } from '../../packages/story/runner'
import { canStartSubevent4, completeSubevent4, finishSubevent4Story, startSubevent4, subevent4Content,
  subevent4StoryForCheckpoint } from '../../packages/battle/subevent4'

const content = document as ContentPack
const projectRoot = process.cwd()

function readyForSubevent4() {
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
    flags: [...save.progress.flags, 'adventurer.tutorial.completed', SUBEVENT_COMPLETION_FLAGS.subevent1,
      SUBEVENT_COMPLETION_FLAGS.subevent2, SUBEVENT_COMPLETION_FLAGS.subevent3] } }))
}

function finishStory(save: ReturnType<typeof startSubevent4>, storyId: string) {
  let result = save
  while (subevent4StoryForCheckpoint(result.progress.checkpoint_id) === storyId) {
    const frame = startStory(subevent4Content, storyId, result.progress.checkpoint_id)
    if (frame.step.kind === 'end') break
    result = parseSave({ ...result, progress: { ...result.progress,
      checkpoint_id: nextStoryCheckpoint(subevent4Content, storyId, frame) } })
  }
  return result
}

function winBattle(save: ReturnType<typeof prepareFixedBattle>) {
  let next = save
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent4.receptionist')!
  for (let attempt = 0; attempt < 9 && !fixedView(next).outcome; attempt++) {
    const ledger = next.progress.fixed_battle!
    const view = fixedView(next)
    let selection: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !selection; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponentIndex = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, index, roll)
        const id = battle.opponent_card_ids[opponentIndex]!
        const hand = id.startsWith('rock_') ? 'rock' : id.startsWith('scissors_') ? 'scissors' : 'paper'
        const opponent = { hand, grade: id.endsWith('_bronze') ? 2 : 1 } as const
        if (judgeCards(ledger.player_deck[index]!, opponent) === 'win') { selection = { index, roll }; break }
      }
    }
    if (!selection) throw new Error('Could not find a winning card for Receptionist battle')
    next = playFixedRound(next, selection.index, selection.roll)
    if (!fixedView(next).outcome) next = acknowledgeFixedRound(next)
  }
  assert.equal(fixedView(next).outcome, 'win')
  return returnFromFixedBattle(settleFixedBattle(next, 0))
}

test('Subevent 4 content validates its battle, story references, and existing portrait', () => {
  assert.deepEqual(validateContent(content, (path) => existsSync(resolve(projectRoot, path))), { valid: true, issues: [] })
  assert.deepEqual(content.battles[0]?.item_reward_ids, ['rare_find_pendant', 'rank_up_talisman'])
})

test('Subevent 4 unlock requires Sub-event 3 and the cumulative random battle requirement', () => {
  assert.equal(getSubeventUnlockState('subevent4', [SUBEVENT_COMPLETION_FLAGS.subevent3], 2).unlocked, false)
  assert.equal(canStartSubevent4(readyForSubevent4()), true)
  assert.throws(() => startSubevent4(createInitialGameSave()))
})

test('Subevent 4 connects its public-review adaptation, fixed battle, rewards, and Guild return', () => {
  let save = startSubevent4(readyForSubevent4())
  assert.equal(save.progress.checkpoint_id, 'subevent4.pre.background')
  save = finishStory(save, 'story.subevent4.pre')
  save = finishSubevent4Story(save, 'story.subevent4.pre')
  assert.equal(save.progress.checkpoint_id, 'subevent4.battle.start')
  save = winBattle(prepareFixedBattle(save))
  assert.ok(save.player.items?.includes('rare_find_pendant'))
  assert.ok(save.player.items?.includes('rank_up_talisman'))
  save = finishStory(save, 'story.subevent4.post')
  const home = finishSubevent4Story(save, 'story.subevent4.post')
  assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.ok(home.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent4))
  assert.throws(() => completeSubevent4(home))
})
