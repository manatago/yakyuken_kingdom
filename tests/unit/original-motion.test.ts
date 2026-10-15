import assert from 'node:assert/strict'
import test from 'node:test'
import { originalMotionFrames } from '../../packages/story/original-motion'

test('Godot slide entry decelerates with sine-out while alpha stays linear', () => {
  const frames = originalMotionFrames('fade_slide', false, 'top', 300, { x: 100, y: 70, scale: .2 }, 2048, 2048)
  assert.equal(frames[0].translate, '0px -300px')
  const half = frames.find(frame => frame.offset === .5)!
  assert.ok(Math.abs(Number(String(half.translate).split(' ')[1].slice(0, -2)) + 300 * (1 - Math.SQRT1_2)) < 1e-8)
  assert.equal(half.opacity, .5)
  assert.equal(frames.at(-1)!.translate, '0px 0px')
})

test('Godot shrink exits toward the visual center with cubic-in scale', () => {
  const frames = originalMotionFrames('shrink', true, 'left', 200, { x: 100, y: 70, scale: .5 }, 1000, 2000)
  assert.equal(frames.find(frame => frame.offset === .5)!.transform, 'scale(0.4375)')
  assert.equal(frames.at(-1)!.transform, 'scale(0)')
  assert.equal(frames.at(-1)!.left, '350px')
  assert.equal(frames.at(-1)!.top, '570px')
})

test('Godot slide exits accelerate with sine-in and accepts up/down aliases', () => {
  const frames = originalMotionFrames('slide', true, 'down', 200, { x: 0, y: 0, scale: 1 }, 1, 1)
  const half = frames.find(frame => frame.offset === .5)!
  assert.ok(Math.abs(Number(String(half.translate).split(' ')[1].slice(0, -2)) - 200 * (1 - Math.SQRT1_2)) < 1e-8)
  assert.equal(frames.at(-1)!.translate, '0px 200px')
})
