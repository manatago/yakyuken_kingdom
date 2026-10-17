import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { advanceStory } from './story-input.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url)), executablePath = createRequire(import.meta.url)('electron')
const fixture = { save_version: 1, player: { money: 75, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand =>
  Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) }, progress: { checkpoint_id: 'original:prologue:15', flags: [] } }

test('bottom Exit returns to the title, closes viewers and keeps the normal save for Resume', { timeout: 30_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-exit-normal-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.evaluate(save => globalThis.janken.save.write(save), fixture)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    await page.getByRole('button', { name: 'Item', exact: true }).click()
    await page.getByRole('dialog').waitFor()
    const before = await readFile(join(userData, 'janken-save.json'), 'utf8')
    await page.getByRole('button', { name: 'Exit', exact: true }).click()
    await page.getByRole('button', { name: '中断から始める', exact: true }).waitFor({ timeout: 3000 })
    assert.equal(await page.getByRole('dialog').count(), 0)
    assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), before)
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    assert.equal(await page.getByRole('dialog').count(), 0)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

for (const mode of ['jump', 'event', 'minigame']) test(`bottom Exit from ${mode} returns to the first title, not the selection menu`, { timeout: 30_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-exit-session-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.evaluate(save => globalThis.janken.save.write(save), fixture)
    await page.reload()
    const before = await readFile(join(userData, 'janken-save.json'), 'utf8')
    if (mode === 'jump') {
      await page.getByRole('button', { name: '中断から始める', exact: true }).click()
      await page.getByRole('button', { name: 'チュートリアル', exact: true }).click()
    } else if (mode === 'event') {
      await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
      await page.getByRole('button', { name: 'サブイベント1（ベルカ戦）', exact: true }).click()
      await page.getByRole('button', { name: '自動', exact: true }).click()
      await page.getByRole('button', { name: '準備完了', exact: true }).click()
    } else {
      const catalog = JSON.parse(await readFile(join(root, 'content/developer-tools.json'), 'utf8'))
      const point = catalog.jump_points.find(point => point.label === '_minigame:minigame_stage2')
      assert.ok(point)
      await page.getByRole('button', { name: '中断から始める', exact: true }).click()
      await page.getByRole('button', { name: point.name, exact: true }).click()
    }
    await page.getByRole('button', { name: 'Exit', exact: true }).click()
    await page.getByRole('button', { name: '中断から始める', exact: true }).waitFor({ timeout: 3000 })
    assert.equal(await page.getByRole('heading', { name: 'ジャンプ先を選択' }).count(), 0)
    assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), before)
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

test('Exit drains a pending normal checkpoint and never lets its late callback reopen gameplay', { timeout: 30_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-exit-pending-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.evaluate(save => globalThis.janken.save.write(save), fixture)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    const story = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))
    const text = story.sequences.find(scene => scene.id === 'prologue').commands[14].parameters.text
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text, text)
    await app.evaluate(({ ipcMain, app }) => {
      const fs = process.getBuiltinModule('node:fs/promises')
      const gate = new Promise(resolve => { globalThis.__releaseExitWrite = resolve })
      globalThis.__exitWriteStarted = new Promise(resolve => { globalThis.__startExitWrite = resolve })
      ipcMain.removeHandler('save:write')
      ipcMain.handle('save:write', async (_event, next) => {
        globalThis.__startExitWrite()
        await gate
        await fs.writeFile(app.getPath('userData') + '/janken-save.json', JSON.stringify(next))
      })
    })
    await advanceStory(page)
    await app.evaluate(() => globalThis.__exitWriteStarted)
    await page.getByRole('button', { name: 'Exit', exact: true }).click()
    await page.getByRole('button', { name: '中断から始める', exact: true }).waitFor()
    assert.equal(await page.getByRole('button', { name: 'つづきから', exact: true }).isDisabled(), true)
    await app.evaluate(() => globalThis.__releaseExitWrite())
    await page.waitForFunction(() => [...document.querySelectorAll('button')].some(button => button.textContent === 'つづきから' && !button.disabled))
    assert.equal(await page.getByTestId('original-cursor').count(), 0)
    const checkpoint = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')).progress.checkpoint_id
    assert.notEqual(checkpoint, fixture.progress.checkpoint_id)
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: checkpoint.slice('original:'.length) }).waitFor()
  } finally {
    if (app) { await app.evaluate(() => globalThis.__releaseExitWrite?.()).catch(() => {}); await app.close() }
    await rm(userData, { recursive: true, force: true })
  }
})
