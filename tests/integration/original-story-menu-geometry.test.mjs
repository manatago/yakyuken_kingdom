import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { readFileSync } from 'node:fs'
import test from 'node:test'

test('story menu geometry is captured from the actual unchanged Godot controls', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-menu-geometry.json', import.meta.url), 'utf8'))
  assert.equal(source.scope, 'story-menu-controls-empty-inventory')
  assert.deepEqual(source.viewport, [1920, 1080])
  assert.equal(source.buttons.length, 7)
  for (const [path, hash] of Object.entries(source.source_hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(new URL(`../../godot/${path}`, import.meta.url))).digest('hex'), hash, path)
  }
  assert.ok(source.buttons.every(button => button.rect.length === 4 && button.rect.every(Number.isFinite)))
})

test('inventory icon uses the original GameState asset and is included in CI LFS discovery', () => {
  const state = readFileSync(new URL('../../godot/game/GameState.gd', import.meta.url), 'utf8')
  const mapping = readFileSync(new URL('../../electron/renderer/src/original-assets.ts', import.meta.url), 'utf8')
  const icon = state.match(/const DEFAULT_ITEM_ICON_PATH := "res:\/\/([^"\n]+)"/)?.[1]
  assert.equal(icon, 'assets/ui/icons/gold.png')
  assert.ok(mapping.includes(`import storyItemIcon from '../../../godot/${icon}?url'`))
  const png = readFileSync(new URL(`../../godot/${icon}`, import.meta.url))
  assert.ok(png.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])))
})

test('focused viewer Enter follows actual Godot input dispatch without closing the viewer', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-menu-input.json', import.meta.url), 'utf8'))
  assert.equal(source.scope, 'ui-accept-with-focused-viewer-close')
  assert.equal(source.cursor, 15)
  assert.equal(source.end_cursor, 17)
  assert.deepEqual(source.action_details, { echo_preserves_dialogue: true, viewer_stays_open: true })
  for (const [path, hash] of Object.entries(source.source_hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(new URL(`../../godot/${path}`, import.meta.url))).digest('hex'), hash)
  }
})

test('populated inventory bounds use actual imported Godot icons and unchanged source', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-inventory-geometry.json', import.meta.url), 'utf8'))
  assert.equal(source.scope, 'actual-imported-populated-story-inventory')
  assert.deepEqual(source.lifecycle, { gold_after_state_change: '所持金: 75', rows_after_state_change: 2,
    visible_after_scene_return: true, visible_with_hidden_band: true, visible_with_hidden_scene: false })
  assert.deepEqual(Object.keys(source.viewers).sort(), ['empty_equip', 'empty_item', 'equip', 'item'])
  for (const [path, hash] of Object.entries(source.source_hashes)) {
    assert.equal(createHash('sha256').update(readFileSync(new URL(`../../godot/${path}`, import.meta.url))).digest('hex'), hash)
  }
  assert.equal(createHash('sha256').update(readFileSync(new URL('../../godot/assets/ui/icons/gold.png', import.meta.url))).digest('hex'), source.icon_hash)
  assert.deepEqual(source.viewers.item.rows.map(row => row.text), ['鉄の盾 × 2', '身代わりカード'])
  assert.deepEqual(source.viewers.equip.rows.map(row => row.text), ['金運のお守り'])
  for (const viewer of Object.values(source.viewers)) {
    assert.ok(viewer.rect.length === 4 && viewer.rect.every(Number.isFinite))
    assert.ok(viewer.close_rect[1] >= viewer.rect[1] && viewer.close_rect[1] + viewer.close_rect[3] <= viewer.rect[1] + viewer.rect[3])
  }
})
