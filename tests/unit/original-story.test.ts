import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/godot-original.json'
import { createOriginalStoryState, executeOriginalCommand, originalPortraitLayout, originalPortraitSlots, originalStory,
  restoreOriginalStoryState } from '../../packages/story/original'

test('original export retains all 47 sequences and 2586 ordered commands', () => {
  assert.equal(originalStory.sequences.length, 47)
  assert.equal(originalStory.sequences.reduce((n, s) => n + s.commands.length, 0), 2586)
  assert.deepEqual(originalStory, document)
  const prologue = originalStory.sequences.find(s => s.id === 'prologue')!
  assert.equal(prologue.commands[0].kind, 'band_color')
  assert.equal(prologue.commands[5].parameters.text, '5月の大学キャンパス。')
})

test('single-command playback preserves dialogue, visuals and source without mutation', () => {
  const before = structuredClone(originalStory)
  let state = createOriginalStoryState('prologue')
  for (let i = 0; i < 6; i++) state = executeOriginalCommand(state).state
  assert.equal(state.text, '5月の大学キャンパス。')
  assert.equal(state.background, 'res://assets/backgrounds/prologue/bg01_university.png')
  assert.ok(state.portraits.main)
  const restored = JSON.parse(JSON.stringify(state))
  assert.deepEqual(executeOriginalCommand(restored), executeOriginalCommand(state))
  assert.deepEqual(originalStory, before)
})

test('portrait renderers follow the original side slots through different-character replacements', () => {
  const before = restoreOriginalStoryState('subevent3_visit', 53)
  assert.equal(originalPortraitSlots(before).find(slot => slot.side === 'right')?.id, 'sebas')
  const after = executeOriginalCommand(before).state
  assert.equal(originalPortraitSlots(after).find(slot => slot.side === 'right')?.id, 'fiona')
  assert.equal(before.portraits.sebas.visible, true)
  assert.equal(after.portraits.sebas.visible, false)
  assert.equal(originalPortraitSlots(after).filter(slot => slot.side === 'right').length, 1)
  // Preserve the actual last occupant, not the last character inserted into the cache.
  const hidden = structuredClone(after)
  for (const portrait of Object.values(hidden.portraits)) portrait.visible = false
  assert.equal(originalPortraitSlots(hidden).find(slot => slot.side === 'right')?.id, 'fiona')
  const sebasAgain = restoreOriginalStoryState('subevent3_visit', 56)
  for (const portrait of Object.values(sebasAgain.portraits)) portrait.visible = false
  assert.equal(originalPortraitSlots(sebasAgain).find(slot => slot.side === 'right')?.id, 'sebas')
})

test('every original command executes in order; battle and temporal effects remain explicit', () => {
  for (const sequence of originalStory.sequences) {
    let state = createOriginalStoryState(sequence.id)
    for (let i = 0; i < sequence.commands.length; i++) {
      const result = executeOriginalCommand(state)
      assert.deepEqual(result.command, sequence.commands[i])
      assert.equal(result.state.cursor, i + 1)
      state = result.state
    }
    assert.equal(executeOriginalCommand(state).command, undefined)
  }
})

test('retry flags select the original variant without rewriting the exported command', () => {
  const sequence = originalStory.sequences.find(s => s.commands.some(c => c.parameters.retry_flag_key))!
  const index = sequence.commands.findIndex(c => c.parameters.retry_flag_key)
  const command = sequence.commands[index]
  const state = { ...createOriginalStoryState(sequence.id), cursor: index }
  assert.equal(executeOriginalCommand(state).state.text, command.parameters.text)
  state.flags[String(command.parameters.retry_flag_key)] = true
  assert.equal(executeOriginalCommand(state).state.text, command.parameters.retry_text)
})

test('hide character keeps its outgoing image for animation but invalidates Godot character caches', () => {
  const sequence = originalStory.sequences.find(s => s.id === 'prologue')!
  let state = createOriginalStoryState(sequence.id)
  const index = sequence.commands.findIndex(c => c.kind === 'hide_character')
  for (let i = 0; i <= index; i++) state = executeOriginalCommand(state).state
  assert.equal(state.portraits.main.visible, false)
  assert.ok(state.portraits.main.portrait_id)
  assert.equal(state.portraits.main.cache_valid, false)
})

test('invalid sequence and cursor fail instead of silently omitting content', () => {
  assert.throws(() => createOriginalStoryState('missing'), /Unknown/)
  assert.throws(() => executeOriginalCommand({ ...createOriginalStoryState('prologue'), cursor: -1 }), /cursor/)
})

test('nested original scenes preserve the incoming scene visuals without mutating their caller', () => {
  const incoming = restoreOriginalStoryState('subevent2_pre2', 76)
  const before = structuredClone(incoming)
  const nested = restoreOriginalStoryState('subevent2_battle_lose', 13, incoming.flags, incoming)
  assert.equal(nested.background, 'res://assets/backgrounds/subevent2/bg06_church_dungeon.png')
  assert.equal(nested.sequenceId, 'subevent2_battle_lose')
  assert.equal(nested.cursor, 13)
  assert.equal(nested.portraits.sister_head.portrait_id, incoming.portraits.sister_head.portrait_id)
  assert.deepEqual(incoming, before)
})

test('restoring a story retains completed tutorial flags without making original false updates sticky', () => {
  const flags = { 'original.matilda.tutorial.completed': true, 'adventurer.tutorial.completed': true }
  const state = restoreOriginalStoryState('prologue', 201, flags)
  assert.deepEqual(state.flags, flags)
  assert.notEqual(state.flags, flags)
  const key = 'test.cleared'
  const sequence = { id: 'test-flags', commands: [
    { kind: 'set_flag', parameters: { flag_key: key, value: false } }
  ] }
  originalStory.sequences.push(sequence)
  try {
    const restored = restoreOriginalStoryState(sequence.id, 1, { ...flags, [key]: true })
    assert.equal(restored.flags[key], false)
    assert.equal(restored.flags['original.matilda.tutorial.completed'], true)
  } finally {
    originalStory.sequences.splice(originalStory.sequences.indexOf(sequence), 1)
  }
  assert.deepEqual(flags, { 'original.matilda.tutorial.completed': true, 'adventurer.tutorial.completed': true })
})

test('original dialogue checkpoints reconstruct identical state, including flags and hidden portraits', () => {
  for (const sequence of originalStory.sequences) {
    let state = createOriginalStoryState(sequence.id)
    while (state.cursor < sequence.commands.length) {
      const result = executeOriginalCommand(state)
      state = result.state
      if (result.command?.kind === 'band' && result.command.parameters.wait_for_input) {
        assert.deepEqual(restoreOriginalStoryState(sequence.id, state.cursor), state)
      }
    }
  }
})

test('original FHD geometry uses natural image dimensions, original registry and right-side flipping', () => {
  const left = { portrait_id: 'res://assets/characters/main/satoshi/modern/satoshi_modern_001.png', side_override: 'left', flip: -1 }
  const registry = originalStory.portrait_layouts[left.portrait_id]
  const actual = originalPortraitLayout(left, 848, 2528)
  assert.deepEqual(actual, { x: 100 + registry.position[0], y: 1080 - 2528 * registry.scale + registry.position[1], scale: registry.scale, flipped: false })
  assert.equal(originalPortraitLayout({ ...left, side_override: 'right' }, 848, 2528).flipped, true)
})

test('character bubbles enable the original automatic background filter, narrator restores it and hidden band preserves it', () => {
  const sequence = originalStory.sequences.find(sequence => sequence.id === 'prologue')!
  const characterIndex = sequence.commands.findIndex(command => command.kind === 'band' && command.parameters.speaker_id === 'main')
  const character = restoreOriginalStoryState('prologue', characterIndex + 1)
  assert.equal(character.backgroundFiltered, true)
  const narratorIndex = sequence.commands.findIndex((command, index) => index > characterIndex && command.kind === 'band' && command.parameters.speaker_id === 'narrator')
  assert.equal(restoreOriginalStoryState('prologue', narratorIndex + 1).backgroundFiltered, false)
  const invisibleIndex = sequence.commands.findIndex((command, index) => index > characterIndex && command.kind === 'band' && command.parameters.visible === false)
  const before = restoreOriginalStoryState('prologue', invisibleIndex)
  assert.equal(executeOriginalCommand(before).state.backgroundFiltered, before.backgroundFiltered)
})
