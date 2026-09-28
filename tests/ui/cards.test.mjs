import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('saved decks retain nine slots and expose overflow without rewriting the save', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-deck-overflow-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app
  try {
    for (const size of [9, 10]) {
      const deck = Array.from({ length: size }, (_, index) => ({ hand: index === 9 ? 'scissors' : 'rock', grade: 1 }))
      const save = { save_version: 1, player: { inventory: deck, deck, money: 0 },
        progress: { checkpoint_id: 'matilda.start', flags: [] } }
      const source = JSON.stringify(save)
      await writeFile(join(userData, 'janken-save.json'), source)
      app = await electron.launch({ executablePath, args })
      const page = await app.firstWindow()
      await page.getByRole('button', { name: 'つづきから' }).click()
      await page.getByTestId('deck-panel').waitFor()
      assert.equal(await page.getByTestId('deck-panel').locator('.deck-grid > *').count(), 9)
      assert.equal(await page.getByTestId('deck-panel').locator('button').count(), 9)
      if (size === 10) {
        const overflow = page.getByTestId('deck-overflow')
        await overflow.waitFor()
        assert.ok((await overflow.textContent()).includes('超過カード 1枚'))
        assert.ok(!(await page.getByTestId('deck-panel').textContent()).includes('10/9'))
        await overflow.getByRole('button', { name: 'チョキ N', exact: true }).click()
        await page.getByTestId('card-preview').getByRole('img', { name: 'チョキ N', exact: true }).waitFor()
        await page.waitForFunction(() => [...document.querySelectorAll('.card-view img')].every((img) => img.complete && img.naturalWidth > 0))
        if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, 'cards-overflow.png') })
      } else {
        assert.equal(await page.getByTestId('deck-overflow').count(), 0)
      }
      assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), source)
      await app.close()
      app = undefined
    }
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('Normal card box, deck slots and full preview show real art without modifying the save', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-card-ui-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app
  try {
    app = await electron.launch({ executablePath, args })
    let page = await app.firstWindow()
    await page.getByRole('button', { name: 'はじめから' }).click()
    const box = page.getByTestId('card-box')
    await box.waitFor()
    assert.equal(await box.locator('button').count(), 9)
    assert.equal(await box.locator('.card-grade').allTextContents().then((x) => x.join('')), 'NNNNNNNNN')
    assert.equal(await page.getByTestId('empty-deck-slot').count(), 9)
    for (const hand of ['グー', 'チョキ', 'パー']) {
      assert.equal(await box.getByRole('button', { name: `${hand} N`, exact: true }).count(), 3)
    }
    const before = await readFile(join(userData, 'janken-save.json'), 'utf8')
    await box.getByRole('button', { name: 'パー N', exact: true }).first().click()
    await page.getByTestId('card-preview').getByRole('img', { name: 'パー N', exact: true }).waitFor()
    await page.waitForFunction(() => [...document.querySelectorAll('.card-view img')].every((img) => img.complete && img.naturalWidth > 0))
    assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), before)
    const session = await page.context().newCDPSession(page)
    try {
      for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
        await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
        await page.waitForFunction(({ width, height }) => {
          const frame = document.querySelector('.story-frame').getBoundingClientRect()
          return innerWidth === width && innerHeight === height && Math.abs(frame.width - Math.min(width, height * 16 / 9)) < 1
        }, size)
        const frame = await page.getByTestId('story-frame').boundingBox()
        for (const id of ['card-box', 'deck-panel', 'card-preview']) {
          const rect = await page.getByTestId(id).boundingBox()
          assert.ok(rect.x >= frame.x - 1 && rect.y >= frame.y - 1)
          assert.ok(rect.x + rect.width <= frame.x + frame.width + 1)
          assert.ok(rect.y + rect.height <= frame.y + frame.height + 1)
        }
        const compact = await box.locator('.card-view').first().boundingBox()
        assert.ok(Math.abs(compact.width / compact.height - 2 / 3) < .01)
        const full = await page.getByTestId('card-preview').locator('.card-view').boundingBox()
        assert.ok(Math.abs(full.width / full.height - 848 / 1264) < .01)
        if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, `cards-${size.width}x${size.height}.png`) })
      }
    } finally {
      await session.send('Emulation.clearDeviceMetricsOverride')
      await session.detach()
    }
    await app.close()
    app = undefined
    const save = JSON.parse(before)
    save.player.deck = save.player.inventory.slice(0, 3)
    await writeFile(join(userData, 'janken-save.json'), JSON.stringify(save))
    app = await electron.launch({ executablePath, args })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから' }).click()
    await page.getByTestId('deck-panel').waitFor()
    assert.equal(await page.getByTestId('deck-panel').locator('button').count(), 3)
    assert.equal(await page.getByTestId('empty-deck-slot').count(), 6)
    await page.getByTestId('deck-panel').getByRole('button', { name: 'グー N', exact: true }).first().click()
    await page.getByTestId('card-preview').getByRole('img', { name: 'グー N', exact: true }).waitFor()
    assert.deepEqual(JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')), save)
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
