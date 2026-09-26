import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { createSaveStore } from '../../electron/main/save-store'
import { createNewSave, parseSave } from '../../packages/domain/save'

const rock = { hand: 'rock', grade: 1 } as const
const paper = { hand: 'paper', grade: 2 } as const

test('new Electron game state has a version and resumes without losing state', () => {
  const initial = { inventory: [rock, paper], deck: [rock], money: 15 }
  const save = createNewSave('matilda.start', initial)
  assert.deepEqual(save, {
    save_version: 1,
    player: initial,
    progress: { checkpoint_id: 'matilda.start', flags: [] }
  })
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.deepEqual(initial, { inventory: [rock, paper], deck: [rock], money: 15 })
})

test('save schema rejects unsupported versions and invalid game state', () => {
  const valid = createNewSave('matilda.start', {
    inventory: [rock, paper], deck: [rock], money: 15
  })
  const invalid = [
    { ...valid, save_version: 2 },
    { ...valid, save_version: undefined },
    { ...valid, player: { ...valid.player, money: -1 } },
    { ...valid, player: { ...valid.player, money: 1.5 } },
    { ...valid, player: { ...valid.player, inventory: [{ hand: 'invalid', grade: 1 }] } },
    { ...valid, player: { ...valid.player, inventory: [{ hand: 'rock', grade: 6 }] } },
    { ...valid, player: { ...valid.player, inventory: Array(1) } },
    { ...valid, player: { ...valid.player, deck: Array(1) } },
    { ...valid, player: { ...valid.player, deck: [rock, rock] } },
    { ...valid, progress: { ...valid.progress, checkpoint_id: '' } },
    { ...valid, progress: { ...valid.progress, flags: Array(1) } },
    { ...valid, progress: { ...valid.progress, flags: ['completed', 'completed'] } }
  ]
  for (const value of invalid) assert.throws(() => parseSave(value))
  assert.throws(() => createNewSave('', { inventory: [], deck: [], money: 0 }))
})

test('Electron save store reloads a save and preserves old data on invalid writes', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-save-test-'))
  const filename = 'janken-save.json'
  const target = join(directory, filename)
  try {
    const store = createSaveStore(directory)
    assert.equal(await store.read(), null)
    const save = createNewSave('matilda.start', {
      inventory: [rock, paper], deck: [rock], money: 15
    })
    await store.write(save)
    assert.deepEqual(await store.read(), save)
    const previous = await readFile(target, 'utf8')
    await assert.rejects(store.write({ ...save, save_version: 2 }))
    await assert.rejects(store.write({ ...save, player: { ...save.player, money: Number.NaN } }))
    assert.equal(await readFile(target, 'utf8'), previous)

    await writeFile(target, '{"save_version":2}')
    await assert.rejects(store.read())
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})
