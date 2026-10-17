import assert from 'node:assert/strict'
import { mkdir, mkdtemp, realpath, rm, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { createProjectImages } from '../../electron/main/project-images'

test('project image catalog lists only supported local images and rejects foreign requests', async () => {
  const root = await mkdtemp(join(tmpdir(), 'janken-images-'))
  try {
    await mkdir(join(root, 'godot/assets/cast'), { recursive: true })
    await writeFile(join(root, 'godot/assets/cast/portrait.png'), 'fixture')
    await writeFile(join(root, 'godot/assets/cast/metadata.txt'), 'not an image')
    const store = createProjectImages(root)
    assert.deepEqual(await store.catalog(), ['res://assets/cast/portrait.png'])
    assert.equal(await store.resolve('res://assets/cast/portrait.png'), await realpath(join(root, 'godot/assets/cast/portrait.png')))
    for (const value of [null, 'file:///private/data.png', 'res://assets/../../data.png', 'res://assets/cast/metadata.txt', 'res://assets/missing.png']) {
      await assert.rejects(store.resolve(value))
    }
  } finally { await rm(root, { recursive: true, force: true }) }
})
