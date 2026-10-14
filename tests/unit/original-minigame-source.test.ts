import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

test('Subevent 3 minigame uses all original choices and traces every Pisuke cycle', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-subevent3-minigame.json', import.meta.url), 'utf8'))
  assert.equal(source.choices.length, 18)
  assert.equal(source.pisuke_lines.length, 5)
  assert.equal(source.choice_traces.length, 18)
  assert.equal(source.pisuke_traces.length, 15)
  assert.equal(source.gauge_start, 100)
  assert.equal(source.intro_gauge, 110)
  assert.equal(source.gauge_max, 130)
  for (const trace of source.pisuke_traces) {
    assert.equal(trace.delta, [-50, -20, -5][trace.cycle])
    assert.ok(trace.commands.some((command: { kind: string }) => command.kind === 'narrator_band'))
  }
})
