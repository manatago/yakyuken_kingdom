import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
test('original Stage 5 exports questions, all responses, gauge transitions and victory evidence', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-stage5-minigame.json', import.meta.url), 'utf8'))
  assert.equal(source.questions.length, 12)
  assert.equal(source.gauge_traces.length, 262)
  assert.equal(source.traces.length, 72)
  assert.ok(source.win.some((command: { kind: string }) => command.kind === 'narrator_band'))
  assert.equal(source.intro_gauge, source.config.gauge_start)
})
