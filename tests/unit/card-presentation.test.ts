import assert from 'node:assert/strict'
import test from 'node:test'
import { cardPresentation, COMPACT_CROP } from '../../packages/cards/presentation'

test('card presentation maps all hands and grades without mislabelling', () => {
  for (const [hand, label] of [['rock', 'グー'], ['scissors', 'チョキ'], ['paper', 'パー']] as const) {
    const view = cardPresentation({ hand, grade: 1 })
    assert.equal(view.id, `${hand}_normal`)
    assert.equal(view.handLabel, label)
    assert.equal(view.gradeLabel, 'N')
    assert.equal(view.imagePath, `godot/assets/battle/cards/${hand}_normal.png`)
  }
  for (const [grade, label] of [[1, 'N'], [2, 'B'], [3, 'S'], [4, 'G'], [5, 'P']] as const) {
    assert.equal(cardPresentation({ hand: 'rock', grade }).gradeLabel, label)
  }
  assert.throws(() => cardPresentation({ hand: 'invalid', grade: 1 } as any))
})

test('compact crop preserves the Godot hand and diamond region at 2:3', () => {
  assert.deepEqual(COMPACT_CROP, { x: 124, y: 250, width: 600, height: 900, sourceWidth: 848, sourceHeight: 1264 })
  assert.equal(COMPACT_CROP.width / COMPACT_CROP.height, 2 / 3)
  assert.ok(COMPACT_CROP.x + COMPACT_CROP.width <= COMPACT_CROP.sourceWidth)
  assert.ok(COMPACT_CROP.y + COMPACT_CROP.height <= COMPACT_CROP.sourceHeight)
})
