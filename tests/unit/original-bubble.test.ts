import assert from 'node:assert/strict'
import test from 'node:test'
import source from '../../content/stories/godot-battle-bubbles.json'
import { originalBubbleLayout, originalBattleTypingText } from '../../packages/story/original-bubble'

test('every explicit battle bubble uses actual wrapped text and native controls', () => {
  assert.equal(source.cases.length, 113)
  for (const entry of source.cases) {
    assert.deepEqual(originalBubbleLayout(entry.text, entry.side), entry)
    assert.equal(originalBattleTypingText(entry.text, entry.side), entry.wrapped)
    assert.ok(entry.rect[2] > 400 && entry.rect[3] >= 194)
    assert.equal(entry.font_size, 34)
  }
  const first = source.cases[0]
  originalBubbleLayout(first.text, first.side).rect[0] = -999
  assert.deepEqual(originalBubbleLayout(first.text, first.side), first)
  assert.throws(() => originalBubbleLayout('unknown source text', 'left'))
  assert.equal(originalBattleTypingText('original central text', ''), 'original central text')
})
