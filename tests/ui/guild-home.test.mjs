import assert from 'node:assert/strict'
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalGuildSave } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('canonical guild preserves saves across reload, letterboxing, cancelled edits and failed writes', { timeout: 90_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-original-guild-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = originalGuildSave(cards)
  original.player.inventory.push({ hand: 'rock', grade: 2 })
  original.player.money = 20
  original.progress.flags = ['original.matilda.tutorial.completed']
  const bytes = JSON.stringify(original)
  let app, page
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('guild-frame').waitFor()
  }
  try {
    await writeFile(target, bytes)
    await open()
    assert.equal(await page.getByTestId('main-story-board').count(), 0)
    await page.getByTestId('subevent-board').waitFor()
    assert.match(await page.getByTestId('quest-subevent1').innerText(), /未解放：冒険者チュートリアルを完了/)
    assert.equal(await readFile(target, 'utf8'), bytes)
    const session = await page.context().newCDPSession(page)
    for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
      await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
      await page.waitForFunction(({ width, height }) => {
        const frame = document.querySelector('[data-testid="guild-frame"]').getBoundingClientRect()
        const scale = Math.min(width / 1920, height / 1080)
        return Math.abs(frame.width - 1920 * scale) < 1 && Math.abs(frame.height - 1080 * scale) < 1
      }, size)
      const frame = await page.getByTestId('guild-frame').boundingBox()
      assert.ok(Math.abs(frame.x - (size.width - frame.width) / 2) < 1)
      assert.ok(Math.abs(frame.y - (size.height - frame.height) / 2) < 1)
    }
    await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
    await page.getByRole('button', { name: 'カード', exact: true }).click()
    await page.getByRole('button', { name: '編成を編集', exact: true }).click()
    await page.getByRole('dialog').getByRole('button', { name: '編成から削除 グー N', exact: true }).first().click()
    await page.getByRole('button', { name: 'キャンセル', exact: true }).click()
    assert.equal(await readFile(target, 'utf8'), bytes)
    await page.getByRole('button', { name: '編成を編集', exact: true }).click()
    const dialog = page.getByRole('dialog')
    await dialog.getByRole('button', { name: '編成から削除 グー N', exact: true }).first().click()
    await dialog.getByRole('button', { name: '編成に追加 グー B', exact: true }).click()
    await app.evaluate(() => {
      const fs = process.getBuiltinModule('node:fs/promises'), rename = fs.rename
      fs.rename = async () => { fs.rename = rename; throw new Error('Injected save failure') }
    })
    await dialog.getByRole('button', { name: '編成を保存', exact: true }).click()
    await dialog.getByRole('alert').waitFor()
    assert.equal(await readFile(target, 'utf8'), bytes)
    await dialog.getByRole('button', { name: '編成を保存', exact: true }).click()
    await dialog.waitFor({ state: 'detached' })
    const savedBytes = await readFile(target, 'utf8'), saved = JSON.parse(savedBytes)
    assert.equal(saved.player.prepared_deck.at(-1).grade, 2)
    assert.deepEqual(saved.player.inventory, original.player.inventory)
    assert.deepEqual(saved.player.deck, original.player.deck)
    assert.equal(saved.player.money, original.player.money)
    assert.deepEqual(saved.progress, original.progress)
    await app.close(); app = undefined
    await open()
    assert.equal(await readFile(target, 'utf8'), savedBytes)
  } finally { if (app) await app.close(); await rm(data, { recursive: true, force: true }) }
})
