import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { mkdtempSync, readFileSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, sep } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const root = fileURLToPath(new URL('../..', import.meta.url))
const fixtures = ['godot-terminal-effect.json', 'godot-story-geometry.json', 'godot-story-menu-geometry.json']

test('hashed Godot sources retain LF and original hashes with core.autocrlf=true', () => {
  const hashes = new Map()
  for (const name of fixtures) {
    const fixture = JSON.parse(readFileSync(join(root, 'content/stories', name), 'utf8'))
    const entries = fixture.source_hashes ?? { 'game/StoryScene.gd': fixture.source_hash }
    for (const [path, hash] of Object.entries(entries)) hashes.set(`godot/${path}`, hash)
  }
  const paths = [...hashes.keys()]
  const attributes = spawnSync('git', ['-c', 'core.autocrlf=true', 'check-attr', '-z', 'eol', '--', ...paths],
    { cwd: root, encoding: 'utf8' })
  assert.equal(attributes.status, 0, attributes.stderr)
  const values = attributes.stdout.split('\0').filter(Boolean)
  for (let index = 0; index < values.length; index += 3) assert.equal(values[index + 2], 'lf', values[index])
  const directory = mkdtempSync(join(tmpdir(), 'janken-source-eol-'))
  try {
    // Read the index into a disposable directory; do not change config or worktree sources.
    const checkout = spawnSync('git', ['-c', 'core.autocrlf=true', 'checkout-index', `--prefix=${directory}${sep}`, '--', ...paths],
      { cwd: root, encoding: 'utf8' })
    assert.equal(checkout.status, 0, checkout.stderr)
    for (const [path, hash] of hashes) {
      const bytes = readFileSync(join(directory, path))
      assert.equal(bytes.includes(13), false, `${path} must not contain CR`)
      assert.equal(createHash('sha256').update(bytes).digest('hex'), hash, path)
    }
  } finally { rmSync(directory, { recursive: true, force: true }) }
})
