import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'

test('original book/evidence minigame captures every pair, repeats and support branch', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-stage3-minigame.json', import.meta.url), 'utf8'))
  assert.equal(Object.keys(source.chapters).length, 15)
  assert.equal(Object.keys(source.evidences).length, 15)
  assert.equal(source.valid_combos.length, 7)
  assert.equal(source.traces.length, 225)
  assert.equal(source.repeat_traces.length, 7)
  assert.equal(source.pisuke_traces.length, 7)
  for (const trace of source.traces) {
    const hit = source.valid_combos.some((combo: { chapter: string; evidence: string }) => combo.chapter === trace.chapter && combo.evidence === trace.evidence)
    assert.equal(trace.delta, hit ? -40 : 5)
    assert.ok(trace.commands.some((command: { kind: string }) => command.kind === 'narrator_band'))
  }
  for (const trace of source.repeat_traces) assert.equal(trace.delta, 5)
  for (const trace of source.pisuke_traces) assert.equal(trace.delta, -40)
})
