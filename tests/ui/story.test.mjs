import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdir, mkdtemp, readFile, rename, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const original = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))
const opening = original.sequences.find(sequence => sequence.id === 'prologue').commands

async function assertFittedViewport(page, size) {
  await page.waitForFunction(({ width, height }) => {
    const frame = document.querySelector('.story-frame').getBoundingClientRect()
    return innerWidth === width && innerHeight === height && Math.abs(frame.width - Math.min(width, height * 16 / 9)) < 1
  }, size)
  const rect = await page.locator('.story-frame').boundingBox()
  assert.ok(Math.abs(rect.width / rect.height - 16 / 9) < .001)
  assert.ok(Math.abs(rect.x - (size.width - rect.width) / 2) < 1)
  assert.ok(Math.abs(rect.y - (size.height - rect.height) / 2) < 1)
}

test('Godot story displays real portraits, fits letterboxed viewports and resumes unchanged dialogue', async (t) => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-story-ui-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app
  try {
    app = await electron.launch({ executablePath, args })
    let page = await app.firstWindow()
    await page.getByRole('button', { name: 'はじめから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:6' }).waitFor()
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text, opening[5].parameters.text)
    await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].length >= 2 &&
      [...document.querySelectorAll('.story-stage img')].every(image => image.complete && image.naturalWidth > 0))
    assert.equal(await page.getByTestId('original-portrait-main').evaluate(image => image.complete && image.naturalWidth > 0), true)
    const checkpoint = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')).progress.checkpoint_id
    assert.equal(checkpoint, 'original:prologue:6')
    await app.close(); app = undefined
    app = await electron.launch({ executablePath, args })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:6' }).waitFor()
    assert.equal(await page.getByTestId('original-text').textContent(), opening[5].parameters.text)
    assert.equal(JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')).progress.checkpoint_id, checkpoint)
    const native = await app.evaluate(({ BrowserWindow, screen }) => {
      const window = BrowserWindow.getAllWindows()[0]
      window.setMaximumSize(800, 600); window.setContentSize(1920, 1080)
      const [width, height] = window.getContentSize()
      return { width, height, workArea: screen.getPrimaryDisplay().workAreaSize }
    })
    t.diagnostic(`Native actual=${native.width}x${native.height} workArea=${JSON.stringify(native.workArea)}`)
    assert.ok(native.width <= 800 && native.height <= 600)
    await assertFittedViewport(page, native)
    const session = await page.context().newCDPSession(page)
    try {
      for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
        await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
        await assertFittedViewport(page, size)
        if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, `story-${size.width}x${size.height}.png`) })
      }
    } finally { await session.send('Emulation.clearDeviceMetricsOverride'); await session.detach() }
    await assertFittedViewport(page, native)
    await advanceStory(page)
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:7' }).waitFor()
    const save = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8'))
    assert.equal(save.progress.checkpoint_id, 'original:prologue:7')
    assert.equal(save.player.inventory.length, 9)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

test('failed original dialogue save keeps the visible and persisted checkpoint unchanged', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-story-save-error-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'はじめから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:6' }).waitFor()
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text, opening[5].parameters.text)
    const target = join(userData, 'janken-save.json')
    const previous = await readFile(target, 'utf8')
    const backup = join(userData, 'original-save.json')
    await rename(target, backup); await mkdir(target)
    await advanceStory(page)
    await page.getByRole('alert').waitFor()
    assert.equal(await page.getByTestId('original-text').textContent(), opening[5].parameters.text)
    assert.equal(await page.getByTestId('original-cursor').textContent(), 'prologue:6')
    assert.equal(await readFile(backup, 'utf8'), previous)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})
