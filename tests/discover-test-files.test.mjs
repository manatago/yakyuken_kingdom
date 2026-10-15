import assert from 'node:assert/strict'
import { mkdtemp, mkdir, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import test from 'node:test'
import { discoverTestFiles } from './discover-test-files.mjs'

test('new tests are discovered in every suite without editing npm scripts', async () => {
  const root = await mkdtemp(join(tmpdir(), 'janken-test-discovery-'))
  const cases = [
    ['unit', 'tests/unit/nested/new.test.ts'],
    ['integration', 'tests/new.test.mjs'],
    ['integration', 'tests/integration/nested/new.test.mjs'],
    ['ui', 'tests/ui/nested/new.test.mjs']
  ]
  try {
    for (const [, file] of cases) {
      const path = join(root, file)
      await mkdir(dirname(path), { recursive: true })
      await writeFile(path, '')
    }
    assert.deepEqual(discoverTestFiles('unit', root), ['tests/unit/nested/new.test.ts'])
    assert.deepEqual(discoverTestFiles('integration', root), [
      'tests/integration/nested/new.test.mjs',
      'tests/new.test.mjs'
    ])
    assert.deepEqual(discoverTestFiles('ui', root), ['tests/ui/nested/new.test.mjs'])
  } finally {
    await rm(root, { recursive: true, force: true })
  }
})
