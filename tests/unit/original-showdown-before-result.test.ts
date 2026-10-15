import assert from 'node:assert/strict'
import test from 'node:test'
import * as tutorial from '../../packages/story/original-tutorial'
import * as normal from '../../packages/story/original-normal'
import * as adventurer from '../../packages/story/original-adventurer'

test('Matilda tutorial showdown replays the exact pre-result battle', () => {
  let state = tutorial.createOriginalTutorial()
  let before = state.battle
  while (state.phase !== 'result') {
    before = state.battle
    if (state.phase === 'running') state = tutorial.stepOriginalTutorial(state, 0)
    else if (state.phase === 'deck') state = tutorial.prepareOriginalTutorial(state, state.battle.playerDeck)
    else if (state.phase === 'selection') state = tutorial.chooseOriginalTutorialCard(state, 0)
    else state = tutorial.continueOriginalTutorial(state)
  }
  const saved = structuredClone(state)
  assert.deepEqual(tutorial.originalTutorialPreResultBattle(state), before)
  assert.deepEqual(state, saved)
})

test('normal Matilda showdown replays HP and selected card before the outcome', () => {
  const deck = Array.from({ length: 9 }, () => ({ hand: 'paper' as const, grade: 1 as const }))
  let state = normal.prepareOriginalNormal(normal.createOriginalNormal(deck), deck)
  let before = state.battle
  while (state.phase !== 'result') {
    before = state.battle
    if (state.phase === 'running') state = normal.stepOriginalNormal(state, 0)
    else if (state.phase === 'selection') state = normal.chooseOriginalNormalCard(state, 0)
    else state = normal.continueOriginalNormal(state)
  }
  const saved = structuredClone(state)
  assert.deepEqual(normal.originalNormalPreResultBattle(state), before)
  assert.deepEqual(state, saved)
})

test('adventurer showdown retains the forced selected hand but not premature HP loss', () => {
  let state = adventurer.createOriginalAdventurer()
  let before = state.battle
  while (state.phase !== 'result') {
    before = state.battle
    state = state.phase === 'running' ? adventurer.stepOriginalAdventurer(state, 0) : adventurer.continueOriginalAdventurer(state)
  }
  const saved = structuredClone(state)
  assert.deepEqual(adventurer.originalAdventurerPreResultBattle(state), before)
  assert.deepEqual(state, saved)
})
