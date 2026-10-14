import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { advanceStory } from './story-input.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const source = createRequire(import.meta.url)('../../content/stories/godot-original.json')
const command = source.sequences.find(sequence => sequence.id === 'stage1').commands[52]
const terminalSource = createRequire(import.meta.url)('../../content/stories/godot-terminal-effect.json')
test('terminal overlay skips typing then waits for the original two accept inputs instead of auto-closing', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-terminal-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(() => globalThis.janken.save.write({ save_version: 1,
      player: { inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))),
        deck: [], items: [], money: 0 }, progress: { checkpoint_id: 'original:stage1:52', flags: [] } }))
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'stage1:52' }).waitFor()
    await advanceStory(page)
    const terminal = page.getByTestId('original-terminal')
    await terminal.waitFor({ timeout: 2000 })
    await page.waitForFunction(() => document.querySelector('[data-testid="original-terminal"]')?.textContent?.length > 1)
    await advanceStory(page)
    await page.waitForFunction(text => document.querySelector('[data-testid="original-terminal"]')?.textContent === text,
      command.parameters.lines.join('\n') + '\n█')
    await page.locator('[data-terminal-phase="waiting"]').waitFor()
    assert.equal(await terminal.evaluate(label => parseFloat(getComputedStyle(label).fontSize)), terminalSource.style.font_size)
    const rect = await terminal.evaluate(label => {
      const stage = label.closest('.story-stage').getBoundingClientRect(), rect = label.getBoundingClientRect(), scale = stage.width / 1920
      return [(rect.left - stage.left) / scale, (rect.top - stage.top) / scale, rect.width / scale, rect.height / scale]
    })
    rect.forEach((value, index) => assert.ok(Math.abs(value - terminalSource.style.rect[index]) < .1))
    const start = await page.evaluate(() => performance.now())
    // A deliberate temporal assertion: the unused hold_time must not auto-close the overlay.
    await page.waitForFunction(({ start, hold }) => performance.now() - start >= hold,
      { start, hold: command.parameters.hold_time * 1000 + 100 })
    assert.equal(await terminal.count(), 1)
    const during = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(during.progress.checkpoint_id, 'original:stage1:52')
    await advanceStory(page)
    assert.equal(await terminal.count(), 1)
    assert.equal(await page.getByTestId('original-cursor').textContent(), 'stage1:53')
    await advanceStory(page)
    await terminal.waitFor({ state: 'detached' })
    await page.getByTestId('original-cursor').filter({ hasText: 'stage1:55' }).waitFor()
    assert.equal((await page.evaluate(() => globalThis.janken.save.read())).progress.checkpoint_id, 'original:stage1:55')
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})

test('reference terminal unmount cancels its native effects without writing a game save', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-terminal-unmount-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const url = new URL(page.url())
    url.searchParams.set('original', 'stage1')
    url.searchParams.set('cursor', '52')
    await page.goto(url.href)
    await page.getByTestId('original-cursor').filter({ hasText: 'stage1:52' }).waitFor()
    await advanceStory(page)
    await page.waitForFunction(() => document.querySelector('[data-terminal-phase="fading-in"]')?.getAnimations().length > 0)
    await page.getByRole('button', { name: '原本再生を終了', exact: true }).click()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    assert.equal(await page.getByTestId('original-terminal').count(), 0)
    assert.equal(await page.evaluate(() => document.getAnimations().length), 0)
    assert.equal(await page.evaluate(() => globalThis.janken.save.read()), null)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
