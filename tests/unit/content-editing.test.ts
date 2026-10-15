import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { createContentStore } from '../../electron/main/content-store'
import { createContentSession } from '../../packages/content/editing'
import type { ContentPack } from '../../packages/content/schema'

const assetExists = () => true

function example(): ContentPack {
  return {
    assets: [],
    layouts: [{ id: 'layout.matilda', x: 100, y: 200, scale: 1, flipped: false }],
    battles: [],
    stories: [{
      id: 'story.matilda', start_id: 'step.line', steps: [
        { id: 'step.line', kind: 'line', text: 'hello', next_id: 'step.end' },
        { id: 'step.end', kind: 'end' }
      ]
    }]
  }
}

test('draft, preview and saved content stay separate until a successful save', async () => {
  const source = example()
  const session = createContentSession(source, assetExists)
  session.replaceItem('layouts', 'layout.matilda', {
    id: 'layout.matilda', x: 300, y: 200, scale: 1, flipped: false
  })
  session.replaceStep('story.matilda', 'step.line', {
    id: 'step.line', kind: 'line', text: 'updated', next_id: 'step.end'
  })
  assert.equal(session.draft.layouts[0].x, 300)
  assert.equal(session.saved.layouts[0].x, 100)
  assert.equal(session.preview, null)
  session.showPreview()
  assert.equal(session.preview?.layouts[0].x, 300)
  session.replaceItem('layouts', 'layout.matilda', {
    id: 'layout.matilda', x: 400, y: 200, scale: 1, flipped: false
  })
  assert.equal(session.preview?.layouts[0].x, 300)
  await assert.rejects(session.save(async () => { throw new Error('disk failed') }), /disk failed/)
  assert.equal(session.saved.layouts[0].x, 100)
  await session.save(async () => {})
  assert.equal(session.saved.layouts[0].x, 400)
  assert.equal(source.layouts[0].x, 100)
})

test('ID edits reject missing and mismatched IDs without changing the draft', () => {
  const session = createContentSession(example(), assetExists)
  assert.throws(() => session.replaceItem('layouts', 'missing', {
    id: 'missing', x: 1, y: 2, scale: 1, flipped: false
  }))
  assert.throws(() => session.replaceItem('layouts', 'layout.matilda', {
    id: 'other', x: 1, y: 2, scale: 1, flipped: false
  }))
  assert.throws(() => session.replaceStep('story.matilda', 'missing', {
    id: 'missing', kind: 'end'
  }))
  assert.equal(session.draft.layouts[0].x, 100)
})

test('invalid draft cannot be previewed or saved', async () => {
  const session = createContentSession(example(), assetExists)
  session.replaceItem('layouts', 'layout.matilda', {
    id: 'layout.matilda', x: 100, y: 200, scale: 0, flipped: false
  })
  assert.throws(() => session.showPreview())
  let called = false
  await assert.rejects(session.save(async () => { called = true }))
  assert.equal(called, false)
  assert.equal(session.saved.layouts[0].scale, 1)
})

test('content store validates writes and preserves a backup of the previous document', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-content-test-'))
  try {
    const store = createContentStore(directory, assetExists)
    const target = join(directory, 'editor-content.json')
    const backup = `${target}.bak`
    assert.equal(await store.read(), null)
    const first = example()
    await store.write(first)
    assert.deepEqual(await store.read(), first)
    const firstBytes = await readFile(target, 'utf8')
    const second = example()
    second.layouts[0].x = 300
    await store.write(second)
    assert.deepEqual(await store.read(), second)
    assert.equal(await readFile(backup, 'utf8'), firstBytes)
    const secondBytes = await readFile(target, 'utf8')
    await assert.rejects(store.write({ ...second, layouts: [{ ...second.layouts[0], scale: 0 }] }))
    assert.equal(await readFile(target, 'utf8'), secondBytes)
    assert.equal(await readFile(backup, 'utf8'), firstBytes)
    await writeFile(target, '{"broken":true}')
    await assert.rejects(store.read())
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})

test('overlapping content writes keep call order and back up the preceding version', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-content-concurrent-'))
  try {
    const store = createContentStore(directory, assetExists)
    await store.write(example())
    const updates = Array.from({ length: 20 }, (_, index) => {
      const document = example()
      document.layouts[0].x = index + 1
      return document
    })
    await Promise.all(updates.map((document) => store.write(document)))
    assert.equal((await store.read())?.layouts[0].x, 20)
    const backup = JSON.parse(await readFile(join(directory, 'editor-content.json.bak'), 'utf8')) as ContentPack
    assert.equal(backup.layouts[0].x, 19)
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})
