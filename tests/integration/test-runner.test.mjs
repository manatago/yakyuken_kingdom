import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'

async function fixture() {
  const root = await mkdtemp(join(tmpdir(), 'janken-test-runner-'))
  await mkdir(join(root, 'tests/ui'), { recursive: true })
  await mkdir(join(root, 'tests/integration'), { recursive: true })
  await mkdir(join(root, 'node_modules/electron'), { recursive: true })
  for (const file of ['run-tests.mjs', 'discover-test-files.mjs']) {
    await copyFile(new URL(`../${file}`, import.meta.url), join(root, 'tests', file))
  }
  await writeFile(join(root, 'package.json'), '{"type":"module"}')
  await writeFile(join(root, 'node_modules/electron/package.json'), '{"main":"index.cjs"}')
  // Model Electron's synchronous, on-demand install without a real download.
  await writeFile(join(root, 'node_modules/electron/index.cjs'), `
    const fs = require('node:fs');
    const path = require('node:path');
    const ready = path.join(__dirname, 'ready');
    if (!fs.existsSync(ready)) {
      fs.appendFileSync(path.join(__dirname, 'installs'), process.pid + '\\n');
      if (process.env.JANKEN_FIXTURE_INSTALL_FAIL === '1') throw new Error('fixture install failed');
      fs.mkdirSync(path.join(__dirname, 'install-lock'));
      Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, 100);
      fs.writeFileSync(ready, 'installed');
    }
    module.exports = 'fixture-electron';
  `)
  const worker = `
    import assert from 'node:assert/strict';
    import { createRequire } from 'node:module';
    import { appendFileSync } from 'node:fs';
    import test from 'node:test';
    const executable = createRequire(import.meta.url)('electron');
    test('worker uses installed Electron', () => {
      assert.equal(executable, 'fixture-electron');
      appendFileSync(new URL('../../workers', import.meta.url), 'ran\\n');
    });
  `
  for (const name of ['one', 'two']) await writeFile(join(root, `tests/ui/${name}.test.mjs`), worker)
  await writeFile(join(root, 'tests/integration/plain.test.mjs'), `
    import test from 'node:test';
    test('no Electron required', () => {});
  `)
  return root
}

function run(root, suite, overrides = {}) {
  const env = { ...process.env, JANKEN_FIXTURE_INSTALL_FAIL: '0', ...overrides }
  // This fixture starts a new test runner, not another worker of this test.
  delete env.NODE_TEST_CONTEXT
  return spawnSync(process.execPath, [join(root, 'tests/run-tests.mjs'), suite], {
    cwd: root, env,
    encoding: 'utf8', timeout: 20000
  })
}

test('UI runner installs Electron once in its parent before concurrent workers and reuses it', async () => {
  const root = await fixture()
  try {
    const cold = run(root, 'ui')
    assert.equal(cold.status, 0, cold.stdout + cold.stderr)
    assert.equal(await readFile(join(root, 'node_modules/electron/installs'), 'utf8'), `${cold.pid}\n`)
    assert.equal(await readFile(join(root, 'workers'), 'utf8'), 'ran\nran\n')
    const warm = run(root, 'ui')
    assert.equal(warm.status, 0, warm.stdout + warm.stderr)
    assert.equal(await readFile(join(root, 'node_modules/electron/installs'), 'utf8'), `${cold.pid}\n`)
    assert.equal(await readFile(join(root, 'workers'), 'utf8'), 'ran\nran\nran\nran\n')
  } finally {
    await rm(root, { recursive: true, force: true })
  }
})

test('failed Electron preparation stops before starting UI workers', async () => {
  const root = await fixture()
  try {
    const result = run(root, 'ui', { JANKEN_FIXTURE_INSTALL_FAIL: '1' })
    assert.notEqual(result.status, 0)
    assert.match(result.stderr, /fixture install failed/)
    assert.equal(await readFile(join(root, 'node_modules/electron/installs'), 'utf8'), `${result.pid}\n`)
    await assert.rejects(readFile(join(root, 'workers')), { code: 'ENOENT' })
  } finally {
    await rm(root, { recursive: true, force: true })
  }
})

test('non-UI suites do not initialize or install Electron', async () => {
  const root = await fixture()
  try {
    const result = run(root, 'integration', { JANKEN_FIXTURE_INSTALL_FAIL: '1' })
    assert.equal(result.status, 0, result.stdout + result.stderr)
    await assert.rejects(readFile(join(root, 'node_modules/electron/installs')), { code: 'ENOENT' })
  } finally {
    await rm(root, { recursive: true, force: true })
  }
})
