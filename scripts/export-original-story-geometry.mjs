import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, reference, output] = process.argv.slice(2)
if (!executable || !reference || !output) throw new Error('Expected Godot executable, reference repository and output JSON')
const paths = ['game/StoryScene.gd', 'StoryScene.tscn', 'story/DefaultStory.gd', 'story/StoryCommands.gd', 'story/StoryCharacter.gd', 'story/PortraitLayout.gd']
const hashes = Object.fromEntries(paths.map(path => {
  const source = readFileSync(join(reference, 'godot', path))
  assert.deepEqual(readFileSync(join(root, 'godot', path)), source, `Reference geometry source differs: ${path}`)
  return [path, createHash('sha256').update(source).digest('hex')]
}))
const directory = mkdtempSync(join(tmpdir(), 'janken-story-geometry-'))
const target = join(directory, 'geometry.json')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file', join(directory, 'godot.log'),
  '--script', 'res://export_story_geometry.gd', '--', target], { encoding: 'utf8', timeout: 60_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Parse Error|Unexpected original/.test(result.stderr)) {
  throw new Error(`Geometry export failed: ${result.stdout}\n${result.stderr}`)
}
const geometry = JSON.parse(readFileSync(target, 'utf8'))
const assetPaths = [...new Set(geometry.sequences.flatMap(sequence => sequence.frames.flatMap(frame => frame.slots.map(slot => slot.path))))].sort()
const assetHashes = Object.fromEntries(assetPaths.map(path => {
  assert.match(path, /^res:\/\/assets\/.*\.png$/, 'Unexpected original portrait resource')
  const relative = path.replace('res://', '')
  const source = readFileSync(join(reference, 'godot', relative))
  assert.deepEqual(readFileSync(join(root, 'godot', relative)), source, `Reference portrait differs: ${path}`)
  return [path, createHash('sha256').update(source).digest('hex')]
}))
writeFileSync(output, JSON.stringify({ ...geometry, source_hashes: hashes, source_asset_hashes: assetHashes }, null, 2) + '\n')
console.log(`Original standalone geometry exported: ${geometry.sequences.length} sequences, ${geometry.sequences.reduce((n, s) => n + s.frames.length, 0)} frames`)
