import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import test from 'node:test'

test('battle dialogue uses actual FHD central controls and the current narrator API', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-battle-dialogue.json', import.meta.url), 'utf8'))
  assert.equal(source.scope, 'actual-central-battle-dialogue-controls')
  assert.equal(source.cases.length, 6)
  assert.equal(source.palettes.length, 45)
  for (const palette of source.palettes) {
    assert.deepEqual(palette.normal, palette.color)
    palette.hover.forEach((value, index) => assert.ok(Math.abs(value - (index < 3 ? Math.fround(palette.color[index] + .12) : palette.color[index])) < 1e-6))
  }
  for (const [path, hash] of Object.entries(source.source_hashes)) {
    const code = readFileSync(new URL(`../../godot/${path}`, import.meta.url), 'utf8')
    if (path === 'game/BattleScene.gd') {
      // Primary reference has existing reward UI additions outside these captured methods.
      for (const [name, methodHash] of Object.entries(source.method_hashes)) {
        const start = code.indexOf(`func ${name}(`), end = code.indexOf('\nfunc ', start + 1)
        assert.ok(start >= 0 && end > start)
        assert.equal(createHash('sha256').update(code.slice(start, end)).digest('hex'), methodHash, name)
      }
    } else assert.equal(createHash('sha256').update(code).digest('hex'), hash, path)
  }
  for (const entry of source.cases) {
    assert.equal(entry.band[2], 1920)
    assert.equal(entry.band[3], 220)
    assert.equal(entry.body[0], 480)
    assert.equal(entry.body[2], 960)
    assert.equal(entry.font_size, 24)
    assert.equal(entry.speaker_font_size, 20)
    assert.equal(entry.speaker_visible, entry.speaker === 'speaker')
    assert.equal(entry.body[1] - entry.band[1], entry.speaker_visible ? 52 : 16)
  }
  const code = readFileSync(new URL('../../godot/game/BattleScene.gd', import.meta.url), 'utf8')
  const narrator = code.slice(code.indexOf('func narrator_band('), code.indexOf('func dialogue_band('))
  assert.match(narrator, /cmd\.speaker_id = "narrator"/)
  assert.match(narrator, /_pending_commands\.append\(cmd\)/)
  assert.doesNotMatch(narrator, /_battle_bubble/)
})
