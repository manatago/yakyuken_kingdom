import assert from 'node:assert/strict'
import test from 'node:test'
import content from '../../content/stories/matilda-tutorial.json'
import { cardLayout, layoutStyle, moveLayout, originalCardLayout, originalEditedPortraitLayout } from '../../packages/content/layout'

test('original card geometry preserves Godot anchors and applies only editor deltas', () => {
  const pack = { layouts: [] }
  assert.equal(originalCardLayout(pack, 'layout.cards.box').x, 1497.6)
  assert.equal(originalCardLayout(pack, 'layout.cards.box').y, 58)
  assert.equal(originalCardLayout(pack, 'layout.cards.deck').y, 930)
  const edited = { ...cardLayout(pack, 'layout.cards.box'), x: 1510, scale: .9 }
  const result = originalCardLayout({ layouts: [edited] }, 'layout.cards.box')
  assert.ok(Math.abs(result.x - 1453.6) < 1e-9)
  assert.equal(result.scale, .9)
  assert.equal(edited.x, 1510)
})

test('layout movement converts viewport deltas to FHD coordinates without changing the source', () => {
  const source = { id: 'layout.matilda.intro', x: 960, y: 440, scale: .8, flipped: true }
  const moved = moveLayout(source, 20, -10, .5)
  assert.deepEqual(moved, { ...source, x: 1000, y: 420 })
  assert.equal(source.x, 960)
  for (const scale of [0, -1, NaN, Infinity]) assert.throws(() => moveLayout(source, 0, 0, scale))
  assert.throws(() => moveLayout(source, NaN, 0, 1))
})

test('showdown editing offsets the Godot FHD card group while preserving the stored relative baseline', () => {
  assert.equal(originalCardLayout({ layouts: [] }, 'layout.cards.showdown').x, 650)
  assert.equal(originalCardLayout({ layouts: [] }, 'layout.cards.showdown').y, 250)
  const edited = { ...cardLayout({ layouts: [] }, 'layout.cards.showdown'), x: 380, y: 190, scale: .8 }
  assert.deepEqual(originalCardLayout({ layouts: [edited] }, 'layout.cards.showdown'), { ...edited, x: 680, y: 270 })
})

test('portrait editing keeps canonical geometry at defaults and applies relative offsets, scale and flip', () => {
  const source = { x: 1234, y: 20, scale: .98, flipped: true }
  assert.deepEqual(originalEditedPortraitLayout(source, content, 'layout.matilda.intro'), source)
  const pack = { layouts: [{ ...content.layouts[0], x: 990, y: 430, scale: .4, flipped: true }] }
  assert.deepEqual(originalEditedPortraitLayout(source, pack, 'layout.matilda.intro'),
    { x: 1264, y: 10, scale: .49, flipped: false })
  assert.deepEqual(source, { x: 1234, y: 20, scale: .98, flipped: true })
})

test('card layouts retain baseline geometry and styles come from the selected record', () => {
  const box = cardLayout(content, 'layout.cards.box')
  assert.equal(box.x, 1554)
  assert.equal(box.y, 190)
  const legacy = { ...content, layouts: [] }
  assert.deepEqual(cardLayout(legacy, 'layout.cards.deck'), {
    id: 'layout.cards.deck', x: 350, y: 884, scale: 1, flipped: false
  })
  assert.deepEqual(layoutStyle({ ...box, x: 1500, y: 210, scale: .75 }), {
    left: 1500, top: 210, right: 'auto', bottom: 'auto',
    transform: 'scale(0.75, 0.75)', transformOrigin: 'top left'
  })
})
