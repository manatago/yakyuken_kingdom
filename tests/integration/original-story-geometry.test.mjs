import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { createHash } from 'node:crypto'
import test from 'node:test'

test('all original standalone portrait geometry is captured from the actual Godot StoryScene', () => {
  const frames = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-geometry.json', import.meta.url), 'utf8'))
  assert.equal(frames.scope, 'standalone-portrait-geometry')
  assert.deepEqual(frames.viewport, [1920, 1080])
  assert.equal(frames.sequences.length, 47)
  assert.equal(frames.ignored_battles, 26)
  assert.ok(frames.sequences.every(sequence => sequence.frames.length > 0))
  for (const [path, hash] of Object.entries(frames.source_hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(new URL(`../../godot/${path}`, import.meta.url))).digest('hex'), hash, path)
  }
  for (const [path, hash] of Object.entries(frames.source_asset_hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(new URL(`../../godot/${path.replace('res://', '')}`, import.meta.url))).digest('hex'), hash, path)
  }
})
