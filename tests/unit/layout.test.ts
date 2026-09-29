import assert from 'node:assert/strict'
import test from 'node:test'
import content from '../../content/stories/matilda-tutorial.json'
import { cardLayout, layoutStyle, moveLayout } from '../../packages/content/layout'

test('layout movement converts viewport deltas to FHD coordinates without changing the source', () => {
  const source = { id: 'layout.matilda.intro', x: 960, y: 440, scale: .8, flipped: true }
  const moved = moveLayout(source, 20, -10, .5)
  assert.deepEqual(moved, { ...source, x: 1000, y: 420 })
  assert.equal(source.x, 960)
  for (const scale of [0, -1, NaN, Infinity]) assert.throws(() => moveLayout(source, 0, 0, scale))
  assert.throws(() => moveLayout(source, NaN, 0, 1))
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
