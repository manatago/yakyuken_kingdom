import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { extractOriginalVisualStyle } from '../../scripts/original-visual-style-source.mjs'

test('automatic background filter is derived from the actual original shader and rejects unsupported changes', () => {
  const source = readFileSync(new URL('../../godot/game/StoryScene.gd', import.meta.url), 'utf8')
  const expected = JSON.parse(readFileSync(new URL('../../content/stories/godot-visual-style.json', import.meta.url), 'utf8'))
  assert.deepEqual(extractOriginalVisualStyle(source), expected)
  assert.throws(() => extractOriginalVisualStyle(source.replaceAll('desat * (1.0 - darken)', 'desat + darken')))
})
