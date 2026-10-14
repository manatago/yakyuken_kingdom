import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalNormal, prepareOriginalNormal, stepOriginalNormal, continueOriginalNormal,
  chooseOriginalNormalCard, originalNormalBackgroundBlurred } from '../../packages/story/original-normal'

test('battle blur remains cleared after the original UI is shown again and after resume', () => {
  const deck = Array.from({ length: 9 }, () => ({ hand: 'paper' as const, grade: 1 as const }))
  let state = prepareOriginalNormal(createOriginalNormal(deck), deck)
  let hidden = false, checked = false
  for (let index = 0; index < 700 && state.phase !== 'finished'; index++) {
    if (state.phase === 'running') state = stepOriginalNormal(state, 0)
    else if (state.phase === 'dialogue' || state.phase === 'result') state = continueOriginalNormal(state)
    else if (state.phase === 'selection') state = chooseOriginalNormalCard(state, state.battle.playerUsed.findIndex(used => !used))
    if (!state.uiVisible) hidden = true
    if (hidden && state.uiVisible) {
      const before = structuredClone(state)
      assert.equal(originalNormalBackgroundBlurred(state), false)
      assert.equal(originalNormalBackgroundBlurred(JSON.parse(JSON.stringify(state))), false)
      assert.deepEqual(state, before)
      checked = true
      break
    }
  }
  assert.equal(hidden, true)
  assert.equal(checked, true)
})
