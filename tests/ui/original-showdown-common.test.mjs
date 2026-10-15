import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

for (const kind of ['tutorial', 'normal', 'adventurer']) test(`original ${kind} uses the shared showdown and continues without an invented result button`, async () => {
  const fixture = spawnSync(process.execPath, ['--import', 'tsx', '-e',
    `const { originalShowdownFixture } = require('./tests/helpers/original-showdown-fixture.ts'); console.log(JSON.stringify(originalShowdownFixture(${JSON.stringify(kind)})))`],
  { cwd: root, encoding: 'utf8' })
  assert.equal(fixture.status, 0, fixture.stderr)
  const save = JSON.parse(fixture.stdout)
  const key = `original_${kind}`
  const userData = await mkdtemp(join(tmpdir(), 'janken-showdown-common-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(save => globalThis.janken.save.write(save), save)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-showdown').waitFor({ timeout: 5000 })
    await page.waitForFunction(() => document.querySelector('[data-testid="original-showdown"]')?.getAnimations({ subtree: true }).length === 7)
    assert.equal(await page.getByRole('button', { name: '次へ', exact: true }).count(), 0)
    assert.equal(await page.evaluate(() => document.querySelector('[data-testid="original-showdown"]').getAnimations()[0].effect.getTiming().duration), 7200)
    assert.deepEqual((await page.evaluate(() => globalThis.janken.save.read())).progress[key], save.progress[key])
    await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-showdown').waitFor()
    if (kind === 'normal') {
      // At least one real-time run exercises the browser completion event, not a test shortcut.
      const started = Date.now()
      await page.getByTestId('original-showdown').waitFor({ state: 'detached' })
      assert.ok(Date.now() - started >= 6500)
    } else await finishOriginalShowdown(page)
    await page.waitForFunction(key => document.querySelector(`[data-testid="original-${key}-cursor"]`)?.textContent?.endsWith(':dialogue'), kind)
    const after = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(after.progress[key].battle.rounds.length, 1)
    assert.deepEqual(after.player, save.player)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
