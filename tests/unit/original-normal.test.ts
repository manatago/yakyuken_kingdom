import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalNormal, prepareOriginalNormal, stepOriginalNormal, continueOriginalNormal, chooseOriginalNormalCard, restoreOriginalNormal, finishOriginalNormalSave } from '../../packages/story/original-normal'
import { createOriginalJanken } from '../../packages/battle/original-janken'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'

test('normal battle replays each checkpoint from immutable action history and rejects forged HP', () => {
  let state = createOriginalNormal(createOriginalJanken().playerDeck)
  assert.equal(state.phase, 'deck')
  assert.throws(() => stepOriginalNormal(state, 0))
  state = prepareOriginalNormal(state, state.battle.playerDeck)
  const initial = structuredClone(state)
  for (let step = 0; step < 100 && state.phase !== 'finished'; step++) {
    assert.deepEqual(restoreOriginalNormal(JSON.parse(JSON.stringify(state))), state)
    if (state.phase === 'running') state = stepOriginalNormal(state, 0)
    else if (state.phase === 'selection') {
      const index = state.battle.playerDeck.findIndex((card, index) => card.hand === 'paper' && !state.battle.playerUsed[index])
      state = chooseOriginalNormalCard(state, index)
    } else state = continueOriginalNormal(state)
  }
  assert.equal(state.phase, 'finished')
  assert.equal(state.outcome, 'win')
  assert.equal(state.battle.rounds.length, 3)
  assert.deepEqual(restoreOriginalNormal(JSON.parse(JSON.stringify(state))), state)
  assert.deepEqual(initial.battle.rounds, [])
  assert.throws(() => restoreOriginalNormal({ ...state, battle: { ...state.battle, playerHp: 100 } }))
  assert.throws(() => stepOriginalNormal(state, 0))
})

test('normal settlement preserves cards, clamps loss to zero and cannot be paid twice', () => {
  for (const winning of [true, false]) {
    const initial = createNewGameSave()
    let state = prepareOriginalNormal(createOriginalNormal(initial.player.inventory, 7), initial.player.inventory)
    for (let step = 0; step < 120 && state.phase !== 'finished'; step++) {
      if (state.phase === 'running') state = stepOriginalNormal(state, 0)
      else if (state.phase === 'selection') {
        const index = state.battle.playerDeck.findIndex((card, index) => card.hand === (winning ? 'paper' : 'scissors') && !state.battle.playerUsed[index])
        state = chooseOriginalNormalCard(state, index)
      } else state = continueOriginalNormal(state)
    }
    assert.equal(state.outcome, winning ? 'win' : 'lose')
    const active = { ...initial, player: { ...initial.player, money: 7 }, progress: {
      ...initial.progress, checkpoint_id: 'original:prologue:234', original_normal: state } }
    const settled = finishOriginalNormalSave(parseSave(JSON.parse(JSON.stringify(active))))
    assert.equal(settled.player.money, winning ? 17 : 0)
    assert.deepEqual(settled.player.inventory, initial.player.inventory)
    assert.equal(settled.progress.checkpoint_id, winning ? 'original:prologue_battle_win:0' : 'original:prologue_battle_lose:0')
    assert.deepEqual(parseSave(settled), settled)
    assert.throws(() => finishOriginalNormalSave(settled))
    assert.throws(() => finishOriginalNormalSave({ ...active, player: { ...active.player, money: 100 } }))
  }
})

test('normal deck preparation and subsequent actions never mutate previous snapshots', () => {
  const initial = createOriginalNormal(createOriginalJanken().playerDeck)
  const cards = [...initial.battle.playerDeck].reverse()
  const prepared = prepareOriginalNormal(initial, cards)
  cards[0] = { hand: 'rock', grade: 5 }
  assert.equal(prepared.battle.playerDeck[0].hand, 'paper')
  assert.equal(initial.phase, 'deck')
  assert.equal(initial.actions.length, 0)
  assert.deepEqual(restoreOriginalNormal(JSON.parse(JSON.stringify(prepared))), prepared)
  assert.throws(() => prepareOriginalNormal(prepared, cards))
  assert.throws(() => prepareOriginalNormal(initial, []))
  assert.throws(() => restoreOriginalNormal({ ...prepared, actions: [{ type: 'unknown' }] }))
})
