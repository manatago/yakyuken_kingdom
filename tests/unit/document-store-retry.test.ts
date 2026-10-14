import assert from 'node:assert/strict'
import { mkdtemp, readFile, readdir, rename, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { createDocumentStore } from '../../electron/main/document-store'

const fault = (code: string) => Object.assign(new Error(code), { code })
for (const code of ['EPERM', 'EACCES', 'EBUSY']) test(`Windows ${code} replacement retries without deleting the previous save`, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-retry-'))
  try {
    const target = join(directory, 'save.json')
    await writeFile(target, '{"value":"old"}')
    let calls = 0
    const waits: number[] = []
    const store = createDocumentStore(directory, 'save.json', { platform: 'win32',
      pause: async milliseconds => { waits.push(milliseconds) },
      renameFile: async (source, destination) => {
        calls++
        assert.equal(await readFile(target, 'utf8'), '{"value":"old"}')
        if (calls < 3) throw fault(code)
        await rename(source, destination)
      } })
    await store.write({ value: 'new' })
    assert.equal(calls, 3)
    assert.deepEqual(waits, [25, 50])
    assert.deepEqual(await store.read(), { value: 'new' })
    assert.deepEqual(await readdir(directory), ['save.json'])
  } finally { await rm(directory, { recursive: true, force: true }) }
})

test('persistent replacement failure is bounded, preserves bytes and permits a subsequent write', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-retry-failure-'))
  try {
    const target = join(directory, 'save.json'), original = '{"value":"old"}'
    await writeFile(target, original)
    let fail = true, calls = 0
    const error = fault('EPERM'), waits: number[] = []
    const store = createDocumentStore(directory, 'save.json', { platform: 'win32', pause: async ms => { waits.push(ms) },
      renameFile: async (source, destination) => { calls++; if (fail) throw error; await rename(source, destination) } })
    await assert.rejects(store.write({ value: 'failed' }), cause => cause === error)
    assert.equal(calls, 7)
    assert.deepEqual(waits, [25, 50, 100, 200, 400, 800])
    assert.equal(await readFile(target, 'utf8'), original)
    assert.deepEqual(await readdir(directory), ['save.json'])
    fail = false
    await store.write({ value: 'recovered' })
    assert.deepEqual(await store.read(), { value: 'recovered' })
  } finally { await rm(directory, { recursive: true, force: true }) }
})

for (const [platform, code] of [['darwin', 'EPERM'], ['win32', 'ENOSPC']] as const) test(`${platform} ${code} is not retried`, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-no-retry-'))
  try {
    let calls = 0
    const error = fault(code)
    const store = createDocumentStore(directory, 'save.json', { platform,
      pause: async () => { assert.fail('Unexpected retry') }, renameFile: async () => { calls++; throw error } })
    await assert.rejects(store.write({ value: 'new' }), cause => cause === error)
    assert.equal(calls, 1)
    assert.deepEqual(await readdir(directory), [])
  } finally { await rm(directory, { recursive: true, force: true }) }
})

test('read after a queued write waits for replacement and returns the new complete document', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-read-order-'))
  try {
    await writeFile(join(directory, 'save.json'), '{"value":"old"}')
    let release!: () => void, entered!: () => void
    const blocked = new Promise<void>(resolve => { release = resolve })
    const started = new Promise<void>(resolve => { entered = resolve })
    let reads = 0
    const store = createDocumentStore(directory, 'save.json', { readDocument: async path => {
      reads++; return readFile(path, 'utf8')
    }, renameFile: async (source, destination) => {
      entered(); await blocked; await rename(source, destination)
    } })
    const write = store.write({ value: 'new' })
    await started
    const read = store.read()
    await new Promise<void>(resolve => setImmediate(resolve))
    assert.equal(reads, 0, 'Blocked replacement must prevent file reads, not just delay their result')
    release()
    await write
    assert.deepEqual(await read, { value: 'new' })
    assert.equal(reads, 1)
  } finally { await rm(directory, { recursive: true, force: true }) }
})
