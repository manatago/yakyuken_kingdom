import assert from 'node:assert/strict'
import { mkdir, mkdtemp, rm, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { contentAssetPlugin } from '../../electron.asset-plugin'

test('content asset build includes referenced replacements, not the entire image library', async () => {
  const root = await mkdtemp(join(tmpdir(), 'janken-content-assets-'))
  try {
    await mkdir(join(root, 'content/stories'), { recursive: true })
    await mkdir(join(root, 'godot/assets'), { recursive: true })
    await writeFile(join(root, 'godot/assets/replacement.png'), 'fixture')
    await writeFile(join(root, 'godot/assets/unused.png'), 'fixture')
    await writeFile(join(root, 'content/stories/edited.json'), JSON.stringify({ path: 'res://assets/replacement.png', copy: 'res://assets/replacement.png' }))
    const plugin = contentAssetPlugin(root), watched: string[] = []
    const load = plugin.load as Function
    const source = load.call({ addWatchFile: (path: string) => watched.push(path) }, '\0virtual:janken-content-assets') as string
    assert.match(source, /replacement\.png\?url/)
    assert.doesNotMatch(source, /unused/)
    assert.equal(source.match(/^import /gm)?.length, 1)
    assert.equal(watched.length, 1)
  } finally { await rm(root, { recursive: true, force: true }) }
})
