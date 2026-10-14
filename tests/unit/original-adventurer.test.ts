import test from 'node:test'
import assert from 'node:assert/strict'
import { createOriginalAdventurer, stepOriginalAdventurer, continueOriginalAdventurer, restoreOriginalAdventurer } from '../../packages/story/original-adventurer'

test('original adventurer tutorial forces three Normal cards and Paper against Rock, preserving every checkpoint', () => {
  let state = createOriginalAdventurer()
  for (let step = 0; step < 80 && state.phase !== 'reward'; step++) {
    assert.deepEqual(restoreOriginalAdventurer(JSON.parse(JSON.stringify(state))), state)
    state = state.phase === 'running' ? stepOriginalAdventurer(state, 0) : continueOriginalAdventurer(state)
  }
  assert.equal(state.phase, 'reward')
  assert.equal(state.battle.playerDeck.length, 3)
  assert.equal(state.battle.rounds.length, 1)
  assert.equal(state.battle.rounds[0].player.hand, 'paper')
  assert.equal(state.battle.rounds[0].opponent.hand, 'rock')
  assert.equal(state.battle.rounds[0].result, 'win')
  assert.equal(state.gold, 5)
  assert.equal(state.bayesVisible, false)
  assert.throws(() => restoreOriginalAdventurer({ ...state, gold: 999 }))
})
