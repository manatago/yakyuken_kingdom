import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { advanceStory, advanceBattleDialogue, waitForStoryProgress } from './story-input.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
test('native input helper waits for the busy guard and does not double-advance a completed typewriter', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-input-sync-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${directory}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    // This isolates test-driver ordering, not the game's story expectations.
    await page.setContent('<main class="story-viewport"><section tabindex="0" data-original-dialogue="active"><span data-testid="text">partial</span></section><span data-testid="cursor">1</span><button disabled>タイトルに戻る</button></main>')
    await page.evaluate(() => {
      globalThis.inputAttempts = 0
      document.querySelector('section').addEventListener('keydown', () => {
        globalThis.inputAttempts++
        if (!document.querySelector('button').disabled) document.querySelector('[data-testid="cursor"]').textContent = '2'
      })
    })
    const input = advanceStory(page)
    await page.waitForTimeout(100) // Deliberate blocked interval, not a readiness workaround.
    assert.equal(await page.evaluate(() => globalThis.inputAttempts), 0)
    await page.evaluate(() => { document.querySelector('button').disabled = false })
    await input
    assert.equal(await page.getByTestId('cursor').textContent(), '2')
    await page.evaluate(() => {
      const alert = document.createElement('p'); alert.setAttribute('role', 'alert')
      alert.textContent = 'save:write EPERM'; document.body.append(alert)
    })
    await assert.rejects(waitForStoryProgress(page, 'cursor', '2', 100), error => {
      assert.match(error.message, /save:write EPERM/)
      assert.match(error.message, /"displayed":"2"/)
      assert.ok(error.cause)
      return true
    })
    await page.evaluate(() => {
      document.querySelector('[data-testid="cursor"]').textContent = '1'
      globalThis.inputAttempts = 0
    })
    const complete = advanceBattleDialogue(page, 'text', 'complete', 'cursor', '1')
    await page.waitForTimeout(100)
    assert.equal(await page.evaluate(() => globalThis.inputAttempts), 0, 'Wrong or partial text must not be accepted')
    await page.evaluate(() => { document.querySelector('[data-testid="text"]').textContent = 'complete' })
    await complete
    assert.equal(await page.evaluate(() => globalThis.inputAttempts), 1)
    assert.equal(await page.getByTestId('cursor').textContent(), '2')
  } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
})
