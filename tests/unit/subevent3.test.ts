import assert from 'node:assert/strict'
import test from 'node:test'
import { existsSync } from 'node:fs'
import { resolve } from 'node:path'
import document from '../../content/stories/subevent3.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { SUBEVENT_COMPLETION_FLAGS, getSubeventUnlockState } from '../../packages/domain/progression'
import { enterGuildHome } from '../../packages/guild/home'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { fixedContent, prepareFixedBattle, selectOpponent, playFixedRound, acknowledgeFixedRound, fixedView,
  settleFixedBattle, returnFromFixedBattle, retryFixedBattle } from '../../packages/battle/fixed'
import { judgeCards } from '../../packages/domain/card'
import { chooseSubevent3Option, beginSubevent3Minigame, validateSubevent3Minigame } from '../../packages/battle/subevent3-minigame'
import { canRetrySubevent3Minigame, canStartSubevent3, completeSubevent3, finishSubevent3Story, startSubevent3,
  subevent3Content, subevent3StoryForCheckpoint, continueSubevent3ToBattle,
  retrySubevent3Minigame, canRetrySubevent3Battle } from '../../packages/battle/subevent3'
import { startStory, nextStoryCheckpoint } from '../../packages/story/runner'
import { GUILD_CHECKPOINT } from '../../packages/guild/routes'

const content = document as ContentPack
const projectRoot = process.cwd()

function readyForSubevent3() {
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
      SUBEVENT_COMPLETION_FLAGS.subevent2] } }))
}

function finishStory(save: ReturnType<typeof startSubevent3>, storyId: string) {
  let result = save
  while (subevent3StoryForCheckpoint(result.progress.checkpoint_id) === storyId) {
    const frame = startStory(subevent3Content, storyId, result.progress.checkpoint_id)
    if (frame.step.kind === 'end') break
    result = parseSave({ ...result, progress: { ...result.progress,
      checkpoint_id: nextStoryCheckpoint(subevent3Content, storyId, frame) } })
  }
  return result
}

function deterministicRolls() { return [0.99, 0.99, 0.99, 0.99] }

function winMinigame(save: ReturnType<typeof beginSubevent3Minigame>) {
  let next = save
  let first = true
  while (next.progress.checkpoint_id === 'subevent3.minigame') {
    const ledger = next.progress.subevent3_minigame!
    const selected = first ? 'pisuke' : ledger.choices!.find((id) => id === 'challenge_rune' || id === 'challenge_curse') ?? 'pisuke'
    first = false
    next = chooseSubevent3Option(next, selected, deterministicRolls())
  }
  return next
}

function winFionaBattle(save: ReturnType<typeof prepareFixedBattle>) {
  let next = save
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent3.fiona')!
  for (let attempt = 0; attempt < 9 && !fixedView(next).outcome; attempt++) {
    const ledger = next.progress.fixed_battle!
    const view = fixedView(next)
    let selection: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !selection; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponent = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, index, roll)
        const cardId = battle.opponent_card_ids[opponent]!
        const hand = cardId.startsWith('rock_') ? 'rock' : cardId.startsWith('scissors_') ? 'scissors' : 'paper'
        const card = { hand, grade: cardId.endsWith('_gold') ? 3 : 2 } as const
        if (judgeCards(ledger.player_deck[index]!, card) === 'win') { selection = { index, roll }; break }
      }
    }
    if (!selection) throw new Error('Could not find a winning card for Fiona battle')
    next = playFixedRound(next, selection.index, selection.roll)
    if (!fixedView(next).outcome) next = acknowledgeFixedRound(next)
  }
  assert.equal(fixedView(next).outcome, 'win')
  return returnFromFixedBattle(settleFixedBattle(next, 0))
}

test('Subevent 3 content validates and its three new image assets are declared', () => {
  assert.deepEqual(validateContent(content, (path) => existsSync(resolve(projectRoot, path))), { valid: true, issues: [] })
  assert.equal(content.battles[0]?.item_reward_ids?.length, 2)
})

test('Subevent 3 unlock requires Sub-event 2 and the configured cumulative random battle count', () => {
  const initial = createInitialGameSave()
  assert.equal(getSubeventUnlockState('subevent3', initial.progress.flags, 3).unlocked, false)
  assert.equal(canStartSubevent3(readyForSubevent3()), true)
  assert.throws(() => startSubevent3(createInitialGameSave()))
})

test('Subevent 3 story and minigame preserve offered choices and exact progress through reload', () => {
  let save = startSubevent3(readyForSubevent3())
  for (const storyId of ['story.subevent3.pre', 'story.subevent3.blacksmith', 'story.subevent3.visit']) {
    save = finishStory(save, storyId)
    save = finishSubevent3Story(save, storyId, deterministicRolls())
  }
  assert.equal(save.progress.checkpoint_id, 'subevent3.minigame')
  const afterOne = chooseSubevent3Option(save, 'pisuke', deterministicRolls())
  const reloaded = parseSave(JSON.parse(JSON.stringify(afterOne)))
  assert.deepEqual(reloaded.progress.subevent3_minigame, afterOne.progress.subevent3_minigame)
  assert.throws(() => chooseSubevent3Option(reloaded, 'neutral_weather', deterministicRolls()))
  const won = winMinigame(reloaded)
  assert.equal(won.progress.checkpoint_id, 'subevent3.minigame.end')
  assert.equal(won.progress.subevent3_minigame?.outcome, 'win')
  assert.throws(() => validateSubevent3Minigame({ ...won.progress.subevent3_minigame!, gauge: 1 }))
  assert.equal(continueSubevent3ToBattle(won).progress.checkpoint_id, 'subevent3.battle.start')
})

test('Subevent 3 minigame failure returns to Guild Home and retry archives its completed attempt', () => {
  let save = startSubevent3(readyForSubevent3())
  for (const storyId of ['story.subevent3.pre', 'story.subevent3.blacksmith', 'story.subevent3.visit']) {
    save = finishStory(save, storyId)
    save = finishSubevent3Story(save, storyId, storyId === 'story.subevent3.visit' ? [0, 0, 0, 0] : deterministicRolls())
  }
  while (save.progress.checkpoint_id === 'subevent3.minigame') {
    save = chooseSubevent3Option(save, 'reassure_family', [0, 0, 0, 0])
  }
  assert.equal(save.progress.subevent3_minigame?.outcome, 'lose')
  save = parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'subevent3.minigame.loss.end' } })
  const home = finishSubevent3Story(save, 'story.subevent3.minigame-loss')
  assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.equal(canRetrySubevent3Minigame(home), true)
  const retried = parseSave(JSON.parse(JSON.stringify(retrySubevent3Minigame(home, deterministicRolls()))))
  assert.equal(retried.progress.subevent3_minigame_history?.length, 1)
  assert.equal(retried.progress.subevent3_minigame_history?.[0]?.outcome, 'lose')
})

test('Subevent 3 victory settles Fiona rewards and unlocks Sub-event 4 from Guild Home', () => {
  let save = startSubevent3(readyForSubevent3())
  for (const storyId of ['story.subevent3.pre', 'story.subevent3.blacksmith', 'story.subevent3.visit']) {
    save = finishStory(save, storyId)
    save = finishSubevent3Story(save, storyId, deterministicRolls())
  }
  save = winMinigame(save)
  save = prepareFixedBattle(continueSubevent3ToBattle(save))
  save = winFionaBattle(save)
  assert.ok(save.player.items?.includes('crystal_fragment'))
  assert.ok(save.player.items?.includes('paper_attract_crimson'))
  assert.equal(save.progress.checkpoint_id, 'subevent3.post.background')
  save = finishStory(save, 'story.subevent3.post')
  assert.equal(save.progress.checkpoint_id, 'subevent3.post.end')
  const home = completeSubevent3(save)
  assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.ok(home.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3))
  assert.equal(getSubeventUnlockState('subevent4', home.progress.flags, 3).unlocked, true)
  assert.throws(() => completeSubevent3(home))
})

test('Subevent 3 battle loss returns to Guild without rewards and requires a rebuilt deck before retry', () => {
  let save = startSubevent3(readyForSubevent3())
  for (const storyId of ['story.subevent3.pre', 'story.subevent3.blacksmith', 'story.subevent3.visit']) {
    save = finishStory(save, storyId)
    save = finishSubevent3Story(save, storyId, deterministicRolls())
  }
  save = winMinigame(save)
  save = prepareFixedBattle(continueSubevent3ToBattle(save))
  const battle = fixedContent.battles.find((entry) => entry.id === 'battle.subevent3.fiona')!
  for (let attempt = 0; attempt < 9 && !fixedView(save).outcome; attempt++) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    let selection: { index: number; roll: number } | undefined
    for (let index = 0; index < ledger.player_deck.length && !selection; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const roll = step / 1000
        const opponent = selectOpponent(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, ledger, index, roll)
        const cardId = battle.opponent_card_ids[opponent]!
        const hand = cardId.startsWith('rock_') ? 'rock' : cardId.startsWith('scissors_') ? 'scissors' : 'paper'
        const opponentCard = { hand, grade: cardId.endsWith('_gold') ? 3 : 2 } as const
        if (judgeCards(ledger.player_deck[index]!, opponentCard) === 'lose') { selection = { index, roll }; break }
      }
    }
    if (!selection) throw new Error('Could not find a losing card for Fiona battle')
    save = playFixedRound(save, selection.index, selection.roll)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  const home = parseSave(returnFromFixedBattle(settleFixedBattle(save, 0)))
  assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
  assert.equal(canRetrySubevent3Battle(home), true)
  assert.equal(home.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3), false)
  assert.equal(home.player.inventory.length, 6)
  assert.equal(home.player.items?.includes('crystal_fragment') ?? false, false)
  assert.throws(() => retryFixedBattle(home), /Owned battle deck required/)
})
