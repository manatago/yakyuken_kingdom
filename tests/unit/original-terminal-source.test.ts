import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { extractOriginalTerminalTimings } from '../../scripts/original-terminal-source.mjs'
import source from '../../content/stories/godot-terminal-effect.json'

test('terminal timings, input protocol and bounds use the original handler and actual Godot capture', () => {
  const script = readFileSync(new URL('../../godot/game/StoryScene.gd', import.meta.url), 'utf8')
  assert.equal(createHash('sha256').update(script).digest('hex'), source.source_hash)
  assert.deepEqual(extractOriginalTerminalTimings(script), source.timings)
  assert.equal(source.first_wait_accept_stays_open, true)
  assert.equal(source.second_wait_accept_closes, true)
  assert.deepEqual(source.style.rect, [60, 40, 1800, 1000])
  assert.equal(source.style.font_size, 18)
  assert.throws(() => extractOriginalTerminalTimings(script.replace('await _wait_terminal_click()', 'await get_tree().create_timer(entry.hold_time).timeout')))
})
