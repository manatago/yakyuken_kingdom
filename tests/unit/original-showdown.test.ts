import assert from 'node:assert/strict'
import test from 'node:test'
import { originalShowdownGeometry, originalShowdownTimeline, originalShowdownGradeReason, originalShowdownCardFrames } from '../../packages/story/original-showdown'

test('original showdown scales only for short viewports and centers 280x420 cards at FHD', () => {
  assert.deepEqual(originalShowdownGeometry(1920, 1080), { width: 280, height: 420, y: 250,
    playerStartX: -330, playerEndX: 650, opponentStartX: 1970, opponentEndX: 990 })
  assert.equal(originalShowdownGeometry(800, 500).height, 300)
})

test('original showdown preserves asynchronous pop, flip order and sampled BACK overshoot', () => {
  const timeline = originalShowdownTimeline()
  assert.equal(timeline.duration, 7200)
  assert.deepEqual(timeline.playerSlide, [1800, 3300])
  assert.deepEqual(timeline.playerFlip, [3800, 4100, 4400])
  assert.deepEqual(timeline.opponentFlip, [4800, 5100, 5400])
  assert.deepEqual(timeline.resultPop, [5400, 5800])
  assert.deepEqual(timeline.fade, [6900, 7200])
  assert.equal(timeline.backOut[0], 0)
  assert.equal(timeline.backOut.at(-1), 1)
  assert.ok(Math.max(...timeline.backOut) > 1)
})

test('same-hand explanation uses original Card formatter and other hands have none', () => {
  assert.equal(originalShowdownGradeReason({ hand: 'rock', grade: 1 }, { hand: 'rock', grade: 1 }), '同じグー・同じノーマル: 引き分け')
  assert.equal(originalShowdownGradeReason({ hand: 'paper', grade: 5 }, { hand: 'paper', grade: 2 }), '同じパー: 自分のプラチナ > 相手のブロンズ')
  assert.equal(originalShowdownGradeReason({ hand: 'rock', grade: 1 }, { hand: 'paper', grade: 1 }), '')
})

test('card frame tracks reveal opponent first, swap only at zero width and retain overshoot', () => {
  const opponentBack = originalShowdownCardFrames('opponent', false, 1920, 1080)
  const playerBack = originalShowdownCardFrames('player', false, 1920, 1080)
  const playerFront = originalShowdownCardFrames('player', true, 1920, 1080)
  assert.equal(opponentBack[0].opacity, 1)
  assert.equal(playerBack[0].opacity, 0)
  assert.equal(playerBack.filter(frame => frame.offset === 1800 / 7200).at(-1)!.opacity, 1)
  assert.equal(playerFront.filter(frame => frame.offset === 4100 / 7200).at(-1)!.transform, 'translateX(650px) scaleX(0)')
  assert.equal(playerFront.filter(frame => frame.offset === 4100 / 7200).at(-1)!.opacity, 1)
  assert.equal(playerBack.at(-1)!.opacity, 0)
  assert.ok(opponentBack.some(frame => Number(String(frame.transform).match(/translateX\(([-\d.]+)px\)/)?.[1]) < 990))
})
