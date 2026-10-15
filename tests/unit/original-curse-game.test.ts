import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalCurseGame, playOriginalCurseChoice, restoreOriginalCurseGame } from '../../packages/story/original-curse-game'

const rolls = Array.from({ length: 8 }, () => 0)
test('original curse game uses all five Pisuke lines before weakening and never mutates prior state', () => {
  const initial = createOriginalCurseGame(rolls)
  const first = playOriginalCurseChoice(initial, 'pisuke', 0, rolls)
  const second = playOriginalCurseChoice(first, 'pisuke', 0, rolls)
  assert.equal(initial.gauge, 110)
  assert.equal(first.gauge, 60)
  assert.equal(second.gauge, 10)
  assert.deepEqual(second.pisukeUsed, [0, 1])
  const third = playOriginalCurseChoice(second, 'pisuke', 0, rolls)
  assert.equal(third.gauge, 0)
  assert.equal(third.outcome, 'win')
  assert.throws(() => playOriginalCurseChoice(third, 'pisuke', 0, rolls))
  assert.deepEqual(restoreOriginalCurseGame(third), third)
  assert.throws(() => restoreOriginalCurseGame({ ...second, gauge: 9 }))
})

test('original choices keep their raw labels, deltas and serialized command traces', () => {
  const initial = createOriginalCurseGame(rolls)
  assert.deepEqual(initial.choices, [0, 1, 2, 3])
  const next = playOriginalCurseChoice(initial, 0, 0, rolls)
  assert.equal(next.gauge, 110)
  assert.ok(next.commands.some(command => command.kind === 'narrator_band' && String(command.args[0]).includes('鎧、重くないですか')))
  assert.throws(() => playOriginalCurseChoice(initial, 17, 0, rolls))
  assert.throws(() => createOriginalCurseGame([NaN]))
})

test('Pisuke weakening begins only after the fifth distinct line, and repeated sets retry just once', () => {
  const withPositive = [7 / 18, 0, 0, 0, 7 / 18, 0, 0, 0]
  let game = createOriginalCurseGame(withPositive)
  for (let index = 0; index < 5; index++) {
    game = playOriginalCurseChoice(game, 'pisuke', 0, withPositive)
    assert.equal(game.pisukeCycle, 0)
    assert.equal(game.pisukeUsed.length, index + 1)
    for (let replenish = 0; replenish < 5; replenish++) game = playOriginalCurseChoice(game, 7, 0, withPositive)
  }
  const weakened = playOriginalCurseChoice(game, 'pisuke', 0, withPositive)
  assert.equal(weakened.gauge, 90)
  assert.equal(weakened.pisukeCycle, 1)
  assert.deepEqual(weakened.pisukeUsed, [0])
  assert.deepEqual(restoreOriginalCurseGame(weakened), weakened)
  const initial = createOriginalCurseGame(rolls)
  const replacement = playOriginalCurseChoice(initial, 0, 0, [0, 0, 0, 0, .99, .99, .99, .99])
  assert.deepEqual(replacement.choices, [17, 16, 15, 14])
  assert.deepEqual(playOriginalCurseChoice(initial, 0, 0, rolls).choices, initial.choices)
})
