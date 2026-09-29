import assert from 'node:assert/strict'
import { mkdtemp, mkdir, readFile, writeFile, rm, symlink, readdir } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { spawnSync } from 'node:child_process'
import { pathToFileURL } from 'node:url'
import data from '../../content/stories/matilda-tutorial.json'
import { createProjectLayoutStore } from '../../electron/main/project-layout-store'

async function fixture() {
  const root = await mkdtemp(join(tmpdir(), 'janken-layout-store-'))
  const directory = join(root, 'content/stories')
  const target = join(directory, 'matilda-tutorial.json')
  await mkdir(directory, { recursive: true })
  const original = JSON.stringify(data, null, 2) + '\n'
  await writeFile(target, original)
  return { root, directory, target, original, store: createProjectLayoutStore(root, () => true) }
}

test('a separate process cannot save while the project lock is held; retry releases it', async () => {
  const f = await fixture()
  const lock = join(f.directory, '.matilda-layout.lock')
  try {
    await mkdir(lock)
    const module = pathToFileURL(join(process.cwd(), 'electron/main/project-layout-store.ts')).href
    const probe = spawnSync(process.execPath, ['--import', 'tsx', '--input-type=module', '-e', `
      import assert from 'node:assert/strict';
      import storeModule from ${JSON.stringify(module)};
      const { createProjectLayoutStore } = storeModule;
      const store = createProjectLayoutStore(process.env.JANKEN_LAYOUT_TEST_ROOT, () => true);
      const document = await store.read();
      const expected = document.layouts[0];
      await assert.rejects(store.write({ expected, layout: { ...expected, x: 1200 } }), /locked/i);
    `], { env: { ...process.env, JANKEN_LAYOUT_TEST_ROOT: f.root }, encoding: 'utf8', timeout: 10000 })
    assert.equal(probe.status, 0, probe.stdout + probe.stderr)
    assert.equal(await readFile(f.target, 'utf8'), f.original)
    assert.ok((await readdir(f.directory)).includes('.matilda-layout.lock'))
    await rm(lock, { recursive: true })
    const expected = data.layouts[0]
    await f.store.write({ expected, layout: { ...expected, x: 1200 } })
    assert.equal((await f.store.read()).layouts[0].x, 1200)
    assert.equal((await readdir(f.directory)).includes('.matilda-layout.lock'), false)
  } finally { await rm(f.root, { recursive: true, force: true }) }
})

test('independent writers cannot overwrite the same expected layout and can retry other IDs', async () => {
  const f = await fixture()
  try {
    const other = createProjectLayoutStore(f.root, () => true)
    const expected = data.layouts[0]
    const outcomes = await Promise.allSettled([
      f.store.write({ expected, layout: { ...expected, x: 1100 } }),
      other.write({ expected, layout: { ...expected, x: 1200 } })
    ])
    assert.equal(outcomes.filter(result => result.status === 'fulfilled').length, 1)
    const rejected = outcomes.find(result => result.status === 'rejected') as PromiseRejectedResult
    assert.match(String(rejected.reason), /locked|changed/i)
    const saved = await f.store.read()
    const winner = saved.layouts[0]
    assert.equal(winner.x, outcomes[0].status === 'fulfilled' ? 1100 : 1200)
    assert.equal(await readFile(f.target + '.bak', 'utf8'), f.original)
    // A separate ID may be retried, but must retain the winning change.
    const second = data.layouts[1]
    await other.write({ expected: second, layout: { ...second, x: 1300 } })
    assert.deepEqual((await other.read()).layouts.slice(0, 2), [winner, { ...second, x: 1300 }])
    assert.equal((await readdir(f.directory)).includes('.matilda-layout.lock'), false)
  } finally { await rm(f.root, { recursive: true, force: true }) }
})

test('project layout save changes only its ID, preserves backup bytes and reloads', async () => {
  const f = await fixture()
  try {
    const before = await f.store.read()
    const expected = before.layouts[0]
    const layout = { ...expected, x: expected.x + 24, scale: .9, flipped: true }
    await f.store.write({ expected, layout })
    const after = await f.store.read()
    assert.deepEqual(after, { ...before, layouts: [layout, ...before.layouts.slice(1)] })
    assert.equal(await readFile(f.target + '.bak', 'utf8'), f.original)
    assert.deepEqual(await createProjectLayoutStore(f.root, () => true).read(), after)
    assert.deepEqual((await readdir(f.directory)).sort(), ['matilda-tutorial.json', 'matilda-tutorial.json.bak'])
  } finally { await rm(f.root, { recursive: true, force: true }) }
})

test('malformed, unknown, stale and invalid layout writes preserve project content', async () => {
  const f = await fixture()
  try {
    const expected = data.layouts[0]
    const layout = { ...expected, x: 1000 }
    for (const payload of [null, data, { expected, layout, path: '../elsewhere' },
      { expected, layout: { ...layout, id: 'missing' } },
      { expected, layout: { ...layout, scale: 0 } },
      { expected, layout: { ...layout, x: Infinity } },
      { expected: { ...expected, x: 1 }, layout }]) {
      await assert.rejects(f.store.write(payload))
      assert.equal(await readFile(f.target, 'utf8'), f.original)
    }
    await f.store.write({ expected, layout })
    const saved = await readFile(f.target, 'utf8')
    await assert.rejects(f.store.write({ expected, layout: { ...layout, x: 1200 } }), /changed/)
    assert.equal(await readFile(f.target, 'utf8'), saved)
    // A later save rereads current content rather than overwriting another ID.
    const external = JSON.parse(saved)
    external.layouts[1].x = 1234
    await writeFile(f.target, JSON.stringify(external))
    await f.store.write({ expected: layout, layout: { ...layout, y: 500 } })
    assert.equal((await f.store.read()).layouts[1].x, 1234)
  } finally { await rm(f.root, { recursive: true, force: true }) }
})

test('project writer rejects linked content and backup failure before replacing the source', async () => {
  const f = await fixture()
  try {
    await mkdir(f.target + '.bak')
    const expected = data.layouts[0]
    await assert.rejects(f.store.write({ expected, layout: { ...expected, x: 1200 } }))
    assert.equal(await readFile(f.target, 'utf8'), f.original)
    await rm(f.target + '.bak', { recursive: true })
    await rm(f.target)
    const outside = join(f.root, 'outside.json')
    await writeFile(outside, f.original)
    await symlink(outside, f.target)
    await assert.rejects(f.store.read(), /link|path/i)
    await assert.rejects(f.store.write({ expected, layout: { ...expected, x: 1200 } }))
    assert.equal(await readFile(outside, 'utf8'), f.original)
  } finally { await rm(f.root, { recursive: true, force: true }) }
})
