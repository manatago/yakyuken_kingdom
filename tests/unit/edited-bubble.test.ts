import assert from 'node:assert/strict'
import test from 'node:test'
import { originalBubbleLayout, wrapOriginalBubble } from '../../packages/story/original-bubble'
import source from '../../content/stories/godot-battle-bubbles.json'
import { commandTraceTargets, replaceTraceCommand } from '../../packages/developer/traces'

test('all captured original bubble layouts remain byte-for-byte equivalent', () => {
  for (const entry of source.cases) assert.deepEqual(originalBubbleLayout(entry.text, entry.side), entry)
})

test('newly edited bubble text uses original wrap and bounded anchors without a missing-layout crash', () => {
  const text = 'エディタで新しく入力した文章です。続きの言葉も安全に折り返して表示します。'
  assert.throws(() => originalBubbleLayout(text, 'bottom-right', 42))
  const layout = originalBubbleLayout(text, 'bottom-right', 42, undefined, true)
  assert.equal(layout.font_size, 42)
  assert.equal(layout.wrapped, wrapOriginalBubble(text))
  assert.ok(layout.rect[3] <= 1080 * .62)
  assert.ok(Math.abs(layout.rect[1] + layout.rect[3] - 1080 * .82) < .001)
  assert.ok(layout.body[2] > 0)
  assert.throws(() => originalBubbleLayout(text, '../invalid', 0, undefined, true))
})

test('bubble edits may add a supported font override, but not arbitrary options or sides', () => {
  const source = { traces: [{ method: 'outfit_1', outcomes: [], commands: [{ kind: 'bubble', args: ['元の文章', { side: 'right' }] }] }] }
  const id = commandTraceTargets(source)[0].id
  assert.equal(replaceTraceCommand(source, id, 0, ['新しい文章', { side: 'left', font_size: 42 }]).affected, 1)
  assert.throws(() => replaceTraceCommand(source, id, 0, ['新しい文章', { side: 'elsewhere' }]))
  assert.throws(() => replaceTraceCommand(source, id, 0, ['新しい文章', { side: 'right', font_size: -42 }]))
  assert.throws(() => replaceTraceCommand(source, id, 0, ['新しい文章', { side: 'right', execute: 'code' }]))
})
