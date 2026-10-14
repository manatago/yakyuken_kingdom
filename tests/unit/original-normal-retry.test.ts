import assert from 'node:assert/strict'
import test from 'node:test'
import * as normal from '../../packages/story/original-normal'
import traces from '../../content/stories/godot-prologue-battle.json'
import { parseSave } from '../../packages/domain/save'

test('same-chapter Matilda retry retains first-call flags and replays the immutable attempt history', () => {
  const deck = Array.from({ length: 9 }, (_, index) => ({ hand: index < 6 ? 'paper' as const : 'scissors' as const, grade: 1 as const }))
  let state = normal.prepareOriginalNormal(normal.createOriginalNormal(deck, 20), deck)
  for (let step = 0; step < 300 && state.phase !== 'finished'; step++) {
    if (state.phase === 'running') state = normal.stepOriginalNormal(state, 0)
    else if (state.phase === 'selection') {
      const opponent = state.battle.opponentDeck.find((_, index) => !state.battle.opponentUsed[index])!
      const hand = state.battle.opponentHp > 1 ? 'paper' : { rock: 'scissors', scissors: 'paper', paper: 'rock' }[opponent.hand]
      state = normal.chooseOriginalNormalCard(state, state.battle.playerDeck.findIndex((card, index) => card.hand === hand && !state.battle.playerUsed[index]))
    } else state = normal.continueOriginalNormal(state)
  }
  assert.equal(state.outcome, 'lose')
  assert.equal(state.battle.opponentHp, 1)
  const previous = structuredClone(state)
  let retry = normal.retryOriginalNormalBattle(state, 10)
  assert.equal(retry.phase, 'deck')
  assert.equal(retry.battle.rounds.length, 0)
  assert.equal(retry.balanceBefore, 10)
  assert.equal(retry.playback.repeated, true)
  assert.deepEqual(normal.restoreOriginalNormal(retry), retry)
  const savedRetry = parseSave({ save_version: 1, player: { money: 10, deck: [], items: [], inventory: deck },
    progress: { checkpoint_id: 'original:prologue:234', flags: [], original_normal: retry } })
  assert.deepEqual(savedRetry.progress.original_normal, retry)
  retry = normal.prepareOriginalNormal(retry, deck)
  for (let step = 0; step < 100 && retry.playback.method !== 'outfit_2'; step++) {
    if (retry.phase === 'running') retry = normal.stepOriginalNormal(retry, 0)
    else if (retry.phase === 'selection') retry = normal.chooseOriginalNormalCard(retry, 0)
    else retry = normal.continueOriginalNormal(retry)
  }
  assert.equal(retry.playback.method, 'outfit_2')
  assert.equal(retry.playback.repeated, true)
  while (retry.phase === 'running') retry = normal.stepOriginalNormal(retry, 0)
  assert.ok(traces.traces.some(trace => trace.method === 'outfit_2' && trace.repeated && trace.commands.some(command =>
    command.kind === 'band' && command.args[1] === retry.text || command.kind === 'bubble' && command.args[0] === retry.text)))
  assert.deepEqual(normal.restoreOriginalNormal(retry), retry)
  assert.deepEqual(state, previous)
  assert.throws(() => normal.restoreOriginalNormal({ ...retry, seenOutfits: [] }))
  assert.throws(() => normal.retryOriginalNormalBattle(retry, 10))
})
