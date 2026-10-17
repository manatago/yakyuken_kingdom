import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import test from 'node:test'

test('developer target catalog is synchronized with the unchanged Godot declarations', () => {
  const source = readFileSync(new URL('../../godot/game/Main.gd', import.meta.url), 'utf8')
  const catalog = JSON.parse(readFileSync(new URL('../../content/developer-tools.json', import.meta.url), 'utf8'))
  assert.equal(catalog.format, 'godot-developer-tools')
  assert.equal(catalog.version, 1)
  for (const [declaration, expected] of Object.entries(catalog.source_hashes)) {
    const start = source.indexOf(declaration), end = source.indexOf('\n]', start)
    assert.ok(start >= 0 && end >= 0, declaration)
    assert.equal(createHash('sha256').update(source.slice(start, end + 2)).digest('hex'), expected, declaration)
  }
  assert.equal(catalog.jump_points.length, 108)
  assert.equal(catalog.story_targets.length, 66)
  assert.equal(catalog.battle_targets.length, 18)
})
