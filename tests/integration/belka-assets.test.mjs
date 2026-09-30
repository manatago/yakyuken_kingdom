import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

test('Belka arena referenced by content is included in CI LFS fetch', async () => {
  const content = JSON.parse(await readFile('content/stories/belka-verification.json', 'utf8'))
  const path = content.assets.find((asset) => asset.id === content.battles[0].background_asset_id)?.path
  assert.equal(path, 'godot/assets/backgrounds/prologue/bg06_prison_arena.png')
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const include = workflow.match(/--include="([^"]+)"/)[1].split(',')
  assert.ok(include.includes(path))
  const renderer = await readFile('electron/renderer/src/BelkaScreen.tsx', 'utf8')
  assert.ok(renderer.includes(`${path}?url`))
})
