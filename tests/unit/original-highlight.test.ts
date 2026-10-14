import assert from 'node:assert/strict'
import test from 'node:test'
import source from '../../content/stories/godot-battle-highlight.json'
import { originalHighlightPlacement, originalHighlightPulse, originalTutorialHighlightOptions } from '../../packages/story/original-highlight'
import { originalPrologueBattleTraces } from '../../packages/story/original-battle'

test('highlight placement and pulse reproduce actual Godot implementation', () => {
  for (const entry of source.cases) {
    const actual = originalHighlightPlacement(entry.target, entry.rect, entry.options)
    assert.deepEqual(actual.position, entry.position)
    assert.deepEqual(actual.size, entry.size)
    assert.deepEqual(actual.pivot, entry.pivot)
    assert.equal(actual.flip, entry.flip_h)
    assert.ok(Math.abs(actual.rotation - entry.rotation) < 1e-6)
  }
  source.pulse_samples.forEach((scale, index) => assert.ok(Math.abs(originalHighlightPulse(index / 100) - scale) < 1e-6))
})

test('highlight source options survive playback restoration without modifying a save', () => {
  const trace = originalPrologueBattleTraces.find(trace => trace.method === 'tutorial')!
  const index = trace.commands.findIndex(command => command.kind === 'highlight' && command.args[0] === 'hand_panel')
  const state = { method: 'tutorial', repeated: false, cursor: index + 1, results: [] }
  const before = structuredClone(state)
  assert.deepEqual(originalTutorialHighlightOptions(state), { offset_x: 50 })
  const options = originalTutorialHighlightOptions(state)
  options.offset_x = 999
  assert.deepEqual(originalTutorialHighlightOptions(state), { offset_x: 50 })
  assert.deepEqual(state, before)
})
