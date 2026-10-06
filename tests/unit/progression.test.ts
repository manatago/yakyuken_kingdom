import assert from 'node:assert/strict'
import test from 'node:test'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS, SUBEVENT_RANDOM_BATTLE_REQUIREMENT } from '../../packages/domain/progression'

test('subevent board rules use cumulative random battle experience and the previous subevent', () => {
  assert.equal(SUBEVENT_RANDOM_BATTLE_REQUIREMENT, 3)
  assert.deepEqual(getSubeventUnlockState('subevent1', [], 0).reasons,
    ['冒険者チュートリアルを完了', 'ランダム戦をあと3回経験'])
  assert.equal(getSubeventUnlockState('subevent1', ['adventurer.tutorial.completed'], 2).unlocked, false)
  assert.equal(getSubeventUnlockState('subevent1', ['adventurer.tutorial.completed'], 3).unlocked, true)

  const afterSubevent1 = [SUBEVENT_COMPLETION_FLAGS.subevent1]
  assert.deepEqual(getSubeventUnlockState('subevent2', afterSubevent1, 2).reasons, ['ランダム戦をあと1回経験'])
  assert.equal(getSubeventUnlockState('subevent2', afterSubevent1, 3).unlocked, true)
  assert.deepEqual(getSubeventUnlockState('subevent3', afterSubevent1, 3).reasons, ['サブイベント2を完了'])
  assert.equal(getSubeventUnlockState('subevent3', [...afterSubevent1, SUBEVENT_COMPLETION_FLAGS.subevent2], 3).unlocked, true)
  assert.deepEqual(getSubeventUnlockState('subevent4', [...afterSubevent1, SUBEVENT_COMPLETION_FLAGS.subevent2], 3).reasons,
    ['サブイベント3を完了'])
  assert.equal(getSubeventUnlockState('subevent4', [
    ...afterSubevent1, SUBEVENT_COMPLETION_FLAGS.subevent2, SUBEVENT_COMPLETION_FLAGS.subevent3
  ], 3).unlocked, true)
  assert.deepEqual(getSubeventUnlockState('subevent4', [
    ...afterSubevent1, SUBEVENT_COMPLETION_FLAGS.subevent2, SUBEVENT_COMPLETION_FLAGS.subevent3
  ], 0).reasons, ['ランダム戦をあと3回経験'])
})
