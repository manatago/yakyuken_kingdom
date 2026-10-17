import assert from 'node:assert/strict'
import { copyFile, mkdir, mkdtemp, readFile, rm, symlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { createStoryCommandStore } from '../../electron/main/story-command-store'

async function fixture() {
  const root = await mkdtemp(join(tmpdir(), 'janken-story-store-'))
  await mkdir(join(root, 'content/stories'), { recursive: true })
  const target = join(root, 'content/stories/godot-original.json')
  await copyFile('content/stories/godot-original.json', target)
  return { root, target, store: createStoryCommandStore(root) }
}

test('story editor refuses output exceeding its read limit and preserves the original', async () => {
  const { root, target, store } = await fixture()
  try {
    const document = JSON.parse(await readFile(target, 'utf8'))
    document.padding = ''
    document.padding = 'x'.repeat(8 * 1024 * 1024 - Buffer.byteLength(JSON.stringify(document, null, 2) + '\n') - 100)
    const before = JSON.stringify(document, null, 2) + '\n'
    await writeFile(target, before)
    const record = await store.read('stage2_pre')
    const index = record.sequence.commands.findIndex(command => ['line', 'band'].includes(command.kind) && command.parameters.text)
    assert.ok(index >= 0)
    await assert.rejects(store.write({ sequence: record.sequence.id, index, revision: record.revision,
      parameters: { ...record.sequence.commands[index].parameters, text: 'x'.repeat(10_000) } }), /too large/)
    assert.equal(await readFile(target, 'utf8'), before)
    assert.equal((await store.read(record.sequence.id)).revision, record.revision)
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('story editor writes one command, preserves other sequences and backs up original bytes', async () => {
  const { root, target, store } = await fixture()
  try {
    const original = await readFile(target, 'utf8')
    const record = await store.read('stage2_pre')
    const index = record.sequence.commands.findIndex(command => ['line', 'band'].includes(command.kind) && command.parameters.text)
    const parameters = { ...record.sequence.commands[index].parameters, text: '編集したテスト台詞' }
    await store.write({ sequence: 'stage2_pre', index, revision: record.revision, parameters })
    const changed = JSON.parse(await readFile(target, 'utf8'))
    const before = JSON.parse(original)
    before.sequences.find((scene: { id: string }) => scene.id === 'stage2_pre').commands[index].parameters.text = '編集したテスト台詞'
    assert.deepEqual(changed, before)
    assert.equal(await readFile(target + '.bak', 'utf8'), original)
    await assert.rejects(store.write({ sequence: 'stage2_pre', index, revision: record.revision, parameters }), /changed/)
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('invalid shapes, routing changes and foreign assets never write the source', async () => {
  const { root, target, store } = await fixture()
  try {
    const original = await readFile(target, 'utf8'), record = await store.read('prologue')
    const label = record.sequence.commands.findIndex(command => command.kind === 'label')
    await assert.rejects(store.write({ sequence: 'prologue', index: label, revision: record.revision, parameters: { label_name: 'other' } }))
    const image = record.sequence.commands.findIndex(command => command.kind === 'background')
    await assert.rejects(store.write({ sequence: 'prologue', index: image, revision: record.revision,
      parameters: { ...record.sequence.commands[image].parameters, path: 'res://assets/../../foreign.png' } }))
    for (const path of ['typo.png', 'https://example.com/image.png', 'res://assets/image.svg', 'res://assets/image.txt']) {
      await assert.rejects(store.write({ sequence: 'prologue', index: image, revision: record.revision,
        parameters: { ...record.sequence.commands[image].parameters, path } }), /asset reference/)
    }
    await assert.rejects(store.write({ sequence: 'prologue', index: image, revision: record.revision, parameters: { path: 9 } }))
    await assert.rejects(store.read('../game'))
    assert.equal(await readFile(target, 'utf8'), original)
    // Failed operations must not poison the per-store save queue.
    await assert.doesNotReject(store.write({ sequence: 'prologue', index: label, revision: record.revision, parameters: record.sequence.commands[label].parameters }))
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('another editor lock and linked source cannot be overwritten', async () => {
  const { root, target, store } = await fixture()
  try {
    const record = await store.read('stage7_epilogue')
    const edit = { sequence: record.sequence.id, index: 0, revision: record.revision, parameters: record.sequence.commands[0].parameters }
    await mkdir(join(root, 'content/stories/.original-story-editor.lock'))
    await assert.rejects(store.write(edit), /EEXIST/)
    await rm(join(root, 'content/stories/.original-story-editor.lock'), { recursive: true })
    await rm(target)
    await symlink(join(process.cwd(), 'content/stories/godot-original.json'), target)
    await assert.rejects(store.read('prologue'), /regular/)
  } finally { await rm(root, { recursive: true, force: true }) }
})
