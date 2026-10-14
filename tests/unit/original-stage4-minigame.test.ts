import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'

test('original strength minigame exports all zone-dependent choices and support responses', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-stage4-minigame.json', import.meta.url), 'utf8'))
  assert.equal(source.config.gauge_start, 100)
  assert.equal(source.intro_gauge, 110)
  assert.equal(source.traces.length, 30)
  assert.equal(source.pisuke_traces.length, 9)
  assert.equal(source.zones[99], 'yellow')
  assert.equal(source.zones[100], 'red')
  assert.equal(source.zones[48], 'green')
  assert.equal(source.zones[49], 'yellow')
  assert.equal(source.gauge_traces.length, 262)
  for (const trace of source.gauge_traces) {
    assert.equal(trace.final_gauge, Math.max(0, Math.min(130, trace.initial_gauge + trace.delta)))
    assert.ok(trace.commands.some((command: { kind: string }) => command.kind === 'gauge'))
  }
  for (const trace of source.traces) {
    const hit = trace.pool === (trace.zone === 'red' ? 'light' : 'strong')
    assert.equal(trace.final_gauge, Math.max(0, Math.min(130, trace.initial_gauge + (hit ? -40 : 5))))
    assert.ok(trace.commands.some((command: { kind: string }) => command.kind === 'narrator_band'))
  }
})
