import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('a rewritten-story save is preserved but never replays a second story', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-only-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.evaluate(save => globalThis.janken.save.write(save), { save_version: 1,
      player: { inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))), deck: [], money: 20 },
      progress: { checkpoint_id: 'matilda.start', flags: [] } })
    const path = join(userData, 'janken-save.json')
    const bytes = await readFile(path, 'utf8')
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('checkpoint-id').waitFor()
    assert.equal(await page.getByTestId('unsupported-save').count(), 1)
    assert.equal(await page.getByTestId('original-text').count(), 0)
    assert.equal(await readFile(path, 'utf8'), bytes)
    await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    assert.equal(await readFile(path, 'utf8'), bytes)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
