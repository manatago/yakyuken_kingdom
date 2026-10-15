import assert from 'node:assert/strict'
import test from 'node:test'
import controls from '../../content/stories/godot-farewell-controls.json'
import { originalPortraitLayout, originalStory } from '../../packages/story/original'

test('Main farewell preserves actual hidden body controls and unflipped raw portrait layout', () => {
  assert.equal(controls.cases.length, 19)
  const jin = controls.cases.find(entry => entry.checkpoint === 'original:subevent1_hideout:24')!
  assert.equal(jin.frames.length, 2)
  for (const frame of jin.frames) {
    assert.equal(frame.band_y, 860)
    assert.equal(frame.body_visible, false)
    assert.equal(frame.speaker_visible, false)
    assert.equal(frame.right_flip, false)
  }
  const id = Object.keys(originalStory.portrait_layouts)[0]
  const raw = originalPortraitLayout({ portrait_id: id, portrait_scale: .5, side_override: 'right', flip: 0 }, 1000, 2000, false)
  assert.deepEqual(raw, { x: 1320, y: 80, scale: .5, flipped: false })
})
