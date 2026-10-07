import assert from 'node:assert/strict'
import test from 'node:test'
import stage2Content from '../../content/stories/stage2.json'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { SUBEVENT_COMPLETION_FLAGS } from '../../packages/domain/progression'
import { enterGuildHome } from '../../packages/guild/home'
import { parseSave } from '../../packages/domain/save'
import { canStartStage2, startStage2, finishStage2Story, stage2StoryForCheckpoint } from '../../packages/battle/stage2'
import { chooseStage2Expression, continueToStage2Rematch, STAGE2_MINIGAME_SCENES } from '../../packages/battle/stage2-minigame'
import { acknowledgeFixedRound, fixedContent, fixedView, opponents, playFixedRound, prepareFixedBattle,
  returnFromFixedBattle, selectOpponent, settleFixedBattle } from '../../packages/battle/fixed'
import { judgeCards } from '../../packages/domain/card'

test('Stage 2 story, asset, battle and checkpoint references form valid content', () => {
  assert.deepEqual(validateContent(stage2Content, () => true), { valid: true, issues: [] })
})

const freshSave = () => {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = { ...save, player: { ...save.player, inventory: [...save.player.inventory,
    ...Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const }))] } }
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
}

test('Stage 2 unlocks from the guild after sub-event 2 and resolves each story handoff', () => {
  const baseline = freshSave()
  const unlocked = { ...baseline, progress: { ...baseline.progress,
    flags: [...baseline.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent2] } }
  assert.equal(canStartStage2(unlocked), true)
  assert.equal(canStartStage2({ ...unlocked, progress: { ...unlocked.progress, checkpoint_id: 'stage2.pre.end' } }), false)
  assert.throws(() => startStage2({ ...unlocked, progress: { ...unlocked.progress, checkpoint_id: 'stage2.pre.end' } }),
    /Stage 2 is not unlocked/)
  assert.equal(stage2StoryForCheckpoint('stage2.pre.guild.background'), 'story.stage2.pre')
  assert.equal(stage2StoryForCheckpoint('stage2.battle2.loss.end'), 'story.stage2.loss')
  assert.equal(stage2StoryForCheckpoint('not-a-stage2-checkpoint'), undefined)

  const started = startStage2(unlocked)
  assert.equal(started.progress.checkpoint_id, 'stage2.pre.guild.background')
  const pre = { ...started, progress: { ...started.progress, checkpoint_id: 'stage2.pre.end' } }
  assert.equal(finishStage2Story(pre, 'story.stage2.pre').progress.checkpoint_id, 'stage2.meet.background')

  const meet = { ...started, progress: { ...started.progress, checkpoint_id: 'stage2.first.end',
    flags: [...started.progress.flags, 'stage2_first_battle_completed'] } }
  assert.equal(finishStage2Story(meet, 'story.stage2.meet').progress.checkpoint_id, 'stage2.recover.background')
  const recover = { ...started, progress: { ...started.progress, checkpoint_id: 'stage2.recover.end',
    flags: [...started.progress.flags, 'stage2_first_battle_completed'] } }
  const order = [...STAGE2_MINIGAME_SCENES.keys()].reverse()
  const minigame = finishStage2Story(recover, 'story.stage2.recover', order)
  assert.equal(minigame.progress.checkpoint_id, 'stage2.minigame')
  assert.deepEqual(minigame.progress.stage2_minigame?.scene_order, order)
})

test('Stage 2 rematch and closing stories only complete through their valid terminal checkpoints', () => {
  const baseline = freshSave()
  const started = startStage2({ ...baseline, progress: { ...baseline.progress,
    flags: [...baseline.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent2] } })
  const recovering = { ...started, progress: { ...started.progress, checkpoint_id: 'stage2.recover.end',
    flags: [...started.progress.flags, 'stage2_first_battle_completed'] } }
  let save = continueToStage2Rematch(STAGE2_MINIGAME_SCENES.slice(0, 3).reduce(
    (current, scene) => chooseStage2Expression(current, scene),
    finishStage2Story(recovering, 'story.stage2.recover', [...STAGE2_MINIGAME_SCENES.keys()])
  ))
  save = prepareFixedBattle(save)
  for (let round = 0; round < 3; round++) {
    const view = fixedView(save)
    const ledger = save.progress.fixed_battle!
    const battle = fixedContent.battles.find((entry) => entry.id === ledger.battle_id)!
    const opponentDeck = opponents(battle)
    const roll = 0.99
    const playerIndex = ledger.player_deck.findIndex((card, index) => !view.usedPlayer.includes(index) &&
      judgeCards(card, opponentDeck[selectOpponent(battle, ledger, index, roll)]!) === 'win')
    assert.notEqual(playerIndex, -1)
    save = playFixedRound(save, playerIndex, roll)
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0.5)
    else save = acknowledgeFixedRound(save)
  }
  save = returnFromFixedBattle(save)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.battle2.end' } }
  assert.equal(finishStage2Story(save, 'story.stage2.rematch').progress.checkpoint_id, 'stage2.post.start')
  const post = { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.post.end' } }
  const closing = finishStage2Story(post, 'story.stage2.post')
  assert.equal(closing.progress.checkpoint_id, 'stage2.close.start')
  const closeEnd = { ...closing, progress: { ...closing.progress, checkpoint_id: 'stage2.close.end' } }
  const home = finishStage2Story(closeEnd, 'story.stage2.close')
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.ok(home.progress.flags.includes('stage2_complete'))
  assert.throws(() => finishStage2Story(save, 'story.stage2.close'))
})
