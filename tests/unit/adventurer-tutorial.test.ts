import assert from 'node:assert/strict'
import test from 'node:test'
import { advanceAdventurerTutorial, buildAdventurerTutorialDeck, canStartAdventurerTutorial,
  completeAdventurerTutorial, playAdventurerTutorialBattle, startAdventurerTutorial,
  ADVENTURER_TUTORIAL_COMPLETE } from '../../packages/battle/adventurer-tutorial'
import { canStartSubevent1Jin } from '../../packages/battle/jin'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial, TUTORIAL_COMPLETE } from '../../packages/battle/tutorial'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { enterGuildHome } from '../../packages/guild/home'

function guild(): SaveData {
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
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
}

test('Adventurer tutorial saves every step, teaches its fixed Rock counter and preserves the current deck', () => {
  const home = guild()
  const originalDeck = home.player.deck
  assert.equal(home.progress.flags.includes(TUTORIAL_COMPLETE), true)
  assert.equal(canStartAdventurerTutorial(home), true)

  let save = startAdventurerTutorial(home)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  save = advanceAdventurerTutorial(save)
  save = buildAdventurerTutorialDeck(save)
  assert.deepEqual(save.player.deck, originalDeck)
  save = playAdventurerTutorialBattle(save)
  assert.equal(save.progress.adventurer_tutorial?.step, 3)
  save = completeAdventurerTutorial(save)

  assert.deepEqual(save.player.deck, originalDeck)
  assert.equal(save.progress.adventurer_tutorial, undefined)
  assert.ok(save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.throws(() => completeAdventurerTutorial(save))
})

test('Subevent 1 remains locked until the Adventurer tutorial and three random battles are complete', () => {
  const home = guild()
  assert.equal(canStartSubevent1Jin(home), false)
  let tutored = startAdventurerTutorial(home)
  tutored = advanceAdventurerTutorial(tutored)
  tutored = buildAdventurerTutorialDeck(tutored)
  tutored = playAdventurerTutorialBattle(tutored)
  tutored = completeAdventurerTutorial(tutored)
  const twice = parseSave({ ...tutored, progress: { ...tutored.progress, random_battles_completed: 2 } })
  assert.equal(canStartSubevent1Jin(twice), false)
  const three = parseSave({ ...twice, progress: { ...twice.progress, random_battles_completed: 3 } })
  assert.equal(canStartSubevent1Jin(three), true)
})
