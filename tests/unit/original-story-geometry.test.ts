import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { createOriginalStoryState, executeOriginalCommand, originalStory, originalPortraitLayout, originalPortraitSlots } from '../../packages/story/original'

interface Slot { side: string; path: string; position: number[]; scale: number; size: number[]; rect_size: number[]; flipped: boolean }
const geometry: { sequences: { id: string; frames: { cursor: number; slots: Slot[] }[] }[] } =
  JSON.parse(readFileSync(new URL('../../content/stories/godot-story-geometry.json', import.meta.url), 'utf8'))
const dimensions = new Map<string, [number, number]>()
function size(path: string): [number, number] {
  if (!dimensions.has(path)) {
    const png = readFileSync(new URL(`../../godot/${path.replace('res://', '')}`, import.meta.url))
    assert.equal(png.subarray(1, 4).toString(), 'PNG')
    dimensions.set(path, [png.readUInt32BE(16), png.readUInt32BE(20)])
  }
  return dimensions.get(path)!
}

test('every standalone story portrait boundary matches actual Godot path, slot, natural size, position, scale and flip', () => {
  let count = 0
  for (const sequence of geometry.sequences) {
    let state = createOriginalStoryState(sequence.id)
    const length = originalStory.sequences.find(source => source.id === sequence.id)!.commands.length
    for (const frame of sequence.frames) {
      assert.ok(frame.cursor <= length)
      while (state.cursor < frame.cursor) state = executeOriginalCommand(state).state
      const actual = originalPortraitSlots(state).filter(slot => slot.value.visible)
      const label = `${sequence.id}:${frame.cursor}`
      assert.equal(actual.length, frame.slots.length, `${label} visible slots`)
      for (const expected of frame.slots) {
        const slot = actual.find(slot => slot.side === expected.side)
        assert.ok(slot, `${label} ${expected.side}`)
        assert.equal(slot.value.portrait_id, expected.path, `${label} portrait`)
        const [width, height] = size(expected.path)
        assert.deepEqual([width, height], expected.size, `${label} natural image size`)
        assert.ok(Math.abs(width - expected.rect_size[0]) < .001 && Math.abs(height - expected.rect_size[1]) < .001, `${label} Control size`)
        const layout = originalPortraitLayout(slot.value, width, height)
        for (const [name, a, b] of [['x', layout.x, expected.position[0]], ['y', layout.y, expected.position[1]], ['scale', layout.scale, expected.scale]] as const) {
          assert.ok(Math.abs(a - b) < .001, `${label} ${expected.side} ${name}: Electron ${a}, Godot ${b}`)
        }
        assert.equal(layout.flipped, expected.flipped, `${label} flip`)
      }
      count++
    }
  }
  assert.equal(count, 2311)
})
