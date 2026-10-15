import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalQuestRuntime, stepOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, continueOriginalQuestRuntime, restoreOriginalQuestRuntime, originalQuestPreResultBattle } from '../../packages/story/original-quest-runtime'
import { originalQuestBattleChapters } from '../../packages/story/original-quest-battle'

test('each canonical quest battle uses real rounds, replays saved actions and retains raw effects', () => {
  for (const chapter of originalQuestBattleChapters) {
    const deck = Array.from({ length: chapter.player_deck_size }, () => ({ hand: 'paper' as const, grade: 5 as const }))
    let state = createOriginalQuestRuntime(chapter.opponent_id, deck)
    const initial = structuredClone(state)
    for (let count = 0; count < 300 && state.phase !== 'finished'; count++) {
      assert.deepEqual(restoreOriginalQuestRuntime(JSON.parse(JSON.stringify(state))), state)
      if (state.phase === 'running') state = stepOriginalQuestRuntime(state, 0)
      else if (state.phase === 'selection') state = chooseOriginalQuestRuntimeCard(state, state.battle.playerUsed.findIndex(used => !used))
      else state = continueOriginalQuestRuntime(state)
    }
    assert.equal(state.phase, 'finished')
    assert.equal(state.outcome, 'win')
    assert.equal(state.battle.rounds.length, chapter.opponent_hp)
    assert.deepEqual(initial.battle.rounds, [])
    assert.deepEqual(restoreOriginalQuestRuntime(JSON.parse(JSON.stringify(state))), state)
    assert.throws(() => restoreOriginalQuestRuntime({ ...state, battle: { ...state.battle, playerHp: 100 } }))
    assert.throws(() => stepOriginalQuestRuntime(state, 0))
    assert.throws(() => createOriginalQuestRuntime(chapter.opponent_id, []))
  }
})

test('showdown presentation replays the pre-result boundary without changing the saved result', () => {
  let state = createOriginalQuestRuntime('jin', Array.from({ length: 3 }, () => ({ hand: 'paper' as const, grade: 5 as const })))
  while (state.phase !== 'result') {
    if (state.phase === 'running') state = stepOriginalQuestRuntime(state, 0)
    else if (state.phase === 'selection') state = chooseOriginalQuestRuntimeCard(state, 0)
    else state = continueOriginalQuestRuntime(state)
  }
  const saved = structuredClone(state)
  const before = originalQuestPreResultBattle(state)
  assert.equal(before.opponentHp, 1)
  assert.equal(state.battle.opponentHp, 0)
  assert.equal(before.rounds.length, 0)
  assert.equal(before.playerUsed[0], true)
  assert.deepEqual(state, saved)
})

test('Jin loss and draw follow HP termination and refund rules without fixture forcing', () => {
  for (const [hand, outcome] of [['scissors', 'lose'], ['rock', undefined]] as const) {
    let state = createOriginalQuestRuntime('jin', Array.from({ length: 3 }, () => ({ hand, grade: 1 as const })))
    while (!state.battle.rounds.length) {
      if (state.phase === 'running') state = stepOriginalQuestRuntime(state, 0)
      else if (state.phase === 'selection') state = chooseOriginalQuestRuntimeCard(state, 0)
      else state = continueOriginalQuestRuntime(state)
    }
    while (state.phase !== 'finished' && !(state.phase === 'selection' && state.battle.rounds.length === 1)) {
      state = state.phase === 'running' ? stepOriginalQuestRuntime(state, 0) : continueOriginalQuestRuntime(state)
    }
    assert.equal(state.outcome, outcome)
    if (!outcome) {
      assert.equal(state.battle.rounds[0].result, 'draw')
      assert.equal(state.battle.playerUsed[0], false)
      assert.equal(state.battle.playerHp, 1)
      assert.equal(state.battle.opponentHp, 1)
    }
  }
})
