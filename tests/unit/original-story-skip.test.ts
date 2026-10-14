import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { beginOriginalStorySkip, executeOriginalCommand, originalStory, restoreOriginalStoryState } from '../../packages/story/original'

const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-skip.json', import.meta.url), 'utf8'))
test('Skip cleanup and command replay match six actual Godot prebattle boundaries', () => {
  assert.equal(source.cases.length, 6)
  for (const sample of source.cases) {
    const before = restoreOriginalStoryState(sample.sequence, sample.cursor)
    const unchanged = structuredClone(before)
    let state = beginOriginalStorySkip(before)
    while (state.cursor < sample.end_cursor) state = executeOriginalCommand(state).state
    assert.deepEqual(before, unchanged)
    assert.equal(state.background, sample.background)
    const dialogue = sample.dialogue
    assert.equal(state.text, dialogue.l_visible ? dialogue.l_body : dialogue.r_visible ? dialogue.r_body : dialogue.n_body)
    assert.deepEqual(Object.fromEntries(Object.entries(state.portraits).filter(([, p]) => p.cache_valid !== false)
      .map(([id, p]) => [id, p.side_override])), sample.side_cache)
    assert.deepEqual(restoreOriginalStoryState(sample.sequence, sample.end_cursor, {}, undefined, [sample.cursor]), state)
  }
})

test('Skip preserves battle commands and flags instead of jumping over their execution', () => {
  let state = beginOriginalStorySkip(restoreOriginalStoryState('prologue', 190))
  const before = structuredClone(originalStory)
  const commands = []
  while (state.cursor < 198) {
    const result = executeOriginalCommand(state)
    commands.push(result.command?.kind)
    state = result.state
  }
  assert.equal(commands.at(-1), 'battle')
  assert.equal(state.cursor, 198)
  assert.equal(state.skipping, true)
  assert.deepEqual(originalStory, before)
  assert.throws(() => restoreOriginalStoryState('prologue', 15, {}, undefined, [16]), /Skip/)
  assert.throws(() => restoreOriginalStoryState('prologue', 15, {}, undefined, [15, 15]), /Skip/)
  assert.deepEqual(beginOriginalStorySkip(beginOriginalStorySkip(restoreOriginalStoryState('prologue', 15))).skipCursors, [15])
  assert.throws(() => beginOriginalStorySkip(restoreOriginalStoryState('prologue', 0)), /Skip/)
  const incoming = restoreOriginalStoryState('stage1', 0, {}, state)
  assert.equal(incoming.skipping, undefined)
  assert.equal(incoming.skipCursors, undefined)
})

test('actual Main bridge receives both tutorial and normal battle requests before either held result completes', () => {
  const sample = source.battle_boundary
  assert.equal(sample.scope, 'actual-story-loop-main-bridge-with-pending-battle-io')
  assert.deepEqual(sample.action_details.pending_battles, [
    { kind: 'pending_battle', minigame: false, tutorial: true },
    { kind: 'pending_battle', minigame: false, tutorial: false }
  ])
  assert.equal(sample.action_details.story_visible, false)
  let state = beginOriginalStorySkip(restoreOriginalStoryState(sample.sequence, sample.cursor))
  const battles = []
  while (state.cursor < sample.end_cursor) {
    const result = executeOriginalCommand(state)
    if (result.command?.kind === 'battle') battles.push(result.command.parameters.is_tutorial)
    state = result.state
  }
  assert.deepEqual(battles, [true, false])
  assert.ok(Object.values(state.portraits).every(portrait => !portrait.visible && portrait.cache_valid === false))
})
