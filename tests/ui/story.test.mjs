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

async function advanceDialogue(page) {
  const checkpoint = await page.getByTestId('checkpoint-id').textContent()
  await page.getByRole('button', { name: '次へ', exact: true }).click()
  await page.waitForFunction((previous) => {
    const current = document.querySelector('[data-testid="checkpoint-id"]')?.textContent
    const next = [...document.querySelectorAll('button')].find((button) => button.textContent === '次へ')
    return current !== previous && (!next || !next.disabled)
  }, checkpoint)
}

async function continueThroughPrologue(page) {
  for (let count = 0; count < 20; count++) {
    const checkpoint = await page.getByTestId('checkpoint-id').textContent()
    if (checkpoint === 'prologue.end') {
      await page.getByRole('button', { name: 'チュートリアルへ進む', exact: true }).click()
      await page.getByTestId('story-text').getByText(/周りの風景/).waitFor()
      return
    }
    assert.ok(checkpoint?.startsWith('prologue.'), `Unexpected opening checkpoint ${checkpoint}`)
    await advanceDialogue(page)
  }
  assert.fail('Prologue did not reach Matilda tutorial')
}

async function assertFittedViewport(page, size) {
  await page.waitForFunction(({ width, height }) => window.innerWidth === width && window.innerHeight === height, size)
  await page.waitForFunction(() => {
    const rect = document.querySelector('.story-frame').getBoundingClientRect()
    return Math.abs(rect.width - Math.min(innerWidth, innerHeight * 16 / 9)) < 1
  })
  const rect = await page.getByTestId('story-frame').boundingBox()
  assert.ok(Math.abs(rect.width / rect.height - 16 / 9) < .001)
  assert.ok(Math.abs(rect.x - (size.width - rect.width) / 2) < 1)
  assert.ok(Math.abs(rect.y - (size.height - rect.height) / 2) < 1)
}

test('Matilda scene displays real images, grades, scales and resumes its dialogue', async (t) => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-story-ui-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app
  try {
    app = await electron.launch({ executablePath, args })
    let page = await app.firstWindow()
    await page.getByRole('button', { name: 'はじめから' }).click()
    await continueThroughPrologue(page)
    await page.getByTestId('story-text').getByText(/周りの風景/).waitFor()
    await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].length >= 2 &&
      [...document.querySelectorAll('.story-stage img')].every((img) => img.complete && img.naturalWidth > 0))
    const initialPortrait = await page.getByTestId('story-portrait').getAttribute('src')
    for (let count = 0; count < 25; count++) {
      if ((await page.getByTestId('story-text').textContent()).includes('今回は練習だから')) break
      await advanceDialogue(page)
    }
    const gradeText = await page.getByTestId('story-text').textContent()
    assert.ok(gradeText.includes('今回は練習だから'))
    assert.ok(gradeText.includes('Nはノーマル、Bはブロンズ、Sはシルバー、Gはゴールド、Pはプラチナだ。'))
    assert.notEqual(await page.getByTestId('story-portrait').getAttribute('src'), initialPortrait)
    const checkpoint = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')).progress.checkpoint_id
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), checkpoint)
    await app.close()
    app = await electron.launch({ executablePath, args })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから' }).click()
    await page.getByTestId('story-text').getByText(/今回は練習だから/).waitFor()
    assert.equal(await page.getByTestId('story-text').textContent(), gradeText)
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), checkpoint)
    // Reproduce a CI display that cannot fit a native FHD window.
    const native = await app.evaluate(({ BrowserWindow, screen }) => {
      const window = BrowserWindow.getAllWindows()[0]
      window.setMaximumSize(800, 600)
      window.setContentSize(1920, 1080)
      const [width, height] = window.getContentSize()
      return { width, height, workArea: screen.getPrimaryDisplay().workAreaSize }
    })
    t.diagnostic(`Native requested=1920x1080 actual=${native.width}x${native.height} workArea=${JSON.stringify(native.workArea)}`)
    assert.ok(native.width <= 800 && native.height <= 600)
    await assertFittedViewport(page, native)
    // Control renderer dimensions independently of OS display/window limits.
    const viewportSession = await page.context().newCDPSession(page)
    try {
      for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
        await viewportSession.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
        t.diagnostic(`Controlled viewport requested=${size.width}x${size.height} native=${native.width}x${native.height}`)
        await assertFittedViewport(page, size)
        if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, `story-${size.width}x${size.height}.png`) })
      }
    } finally {
      await viewportSession.send('Emulation.clearDeviceMetricsOverride')
      await viewportSession.detach()
    }
    await assertFittedViewport(page, native)
    for (let count = 0; count < 10 && await page.getByRole('button', { name: '次へ', exact: true }).count(); count++) {
      await advanceDialogue(page)
    }
    await page.getByRole('button', { name: '準備完了', exact: true }).waitFor()
    const save = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8'))
    assert.deepEqual(save.progress.flags, ['prologue.completed'])
    assert.equal(save.player.inventory.length, 9)
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('failed dialogue save keeps the displayed checkpoint unchanged', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-story-save-error-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'はじめから' }).click()
    await continueThroughPrologue(page)
    await page.getByTestId('story-text').waitFor()
    const previous = await page.getByTestId('story-text').textContent()
    const target = join(userData, 'janken-save.json')
    await rename(target, join(userData, 'original-save.json'))
    await mkdir(target)
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.equal(await page.getByTestId('story-text').textContent(), previous)
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), 'matilda.start')
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
