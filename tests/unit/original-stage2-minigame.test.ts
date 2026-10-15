import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'

test('Stage 2 expression game exports original scenes, instruction order and every response branch', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-stage2-minigame.json', import.meta.url), 'utf8'))
  assert.equal(source.scenes.length, 10)
  assert.equal(source.traces.length, 50)
  assert.equal(source.gauge_start, 100)
  assert.equal(source.pisuke_unlock_turn, 1)
  assert.deepEqual(source.choice_keys, ['shake', 'blush', 'sweat', 'panic'])
  for (const scene of source.scenes) assert.ok(source.choice_keys.includes(scene.expression))
  for (const trace of source.traces) {
    assert.equal(trace.delta, trace.pick === '_pisuke' || trace.pick === source.scenes[trace.scene].expression ? -40 : 5)
    assert.ok(trace.commands.some((command: {kind: string}) => command.kind === 'narrator_band'))
  }
})
