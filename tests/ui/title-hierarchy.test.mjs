import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('original title has scene/event/editor hierarchies and scene play never overwrites the player save', { timeout: 60_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-title-hierarchy-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: '中断から始める', exact: true }).waitFor({ timeout: 3000 })
    if (process.env.JANKEN_TITLE_SCREENSHOT) await page.screenshot({ path: process.env.JANKEN_TITLE_SCREENSHOT })
    await page.getByRole('button', { name: '中断から始める', exact: true }).click()
    await page.getByRole('heading', { name: 'ジャンプ先を選択' }).waitFor()
    if (process.env.JANKEN_TITLE_SCREENSHOT) await page.screenshot({ path: process.env.JANKEN_TITLE_SCREENSHOT + '.scenes.png' })
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
    await page.getByRole('button', { name: 'プロローグ（マチルダ戦）', exact: true }).waitFor()
    assert.equal(await page.getByRole('button', { name: /スモークテスト/ }).count(), 0)
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    await page.getByRole('button', { name: '編集モードで始める', exact: true }).click()
    await page.getByRole('button', { name: 'バトル立ち絵編集', exact: true }).click()
    await page.getByRole('button', { name: 'イベントバトル', exact: true }).waitFor()
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    await page.getByRole('button', { name: 'ストーリー編集', exact: true }).waitFor()
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    // Start and leave a real normal save before entering a disposable scene session.
    await page.getByRole('button', { name: '新しく始める', exact: true }).click()
    await page.getByTestId('original-text').filter({ hasText: '5月の大学キャンパス。' }).waitFor()
    await page.reload()
    await page.getByRole('button', { name: '中断から始める', exact: true }).waitFor()
    const before = await readFile(join(userData, 'janken-save.json'), 'utf8')
    await page.getByRole('button', { name: '中断から始める', exact: true }).click()
    await page.getByRole('button', { name: '自室', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:' }).waitFor()
    assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), before)
    await page.getByRole('button', { name: '場面選択に戻る', exact: true }).click()
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-text').filter({ hasText: '5月の大学キャンパス。' }).waitFor()
    assert.equal(await readFile(join(userData, 'janken-save.json'), 'utf8'), before)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

for (const [view, label] of [['story', 'ストーリー編集'], ['battle', '戦闘表示編集'], ['slides', '紙芝居編集']]) {
  test(`separate editor starts in ${view} and exits when its launched window is closed`, { timeout: 30_000 }, async () => {
    const userData = await mkdtemp(join(tmpdir(), 'janken-title-editor-view-'))
    let app
    try {
      app = await electron.launch({ executablePath, args: [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${userData}`, `--editor-view=${view}`, '--editor-launch'] })
      const page = await app.firstWindow()
      await page.getByRole('button', { name: label, exact: true }).waitFor()
      assert.equal(await page.getByRole('button', { name: label, exact: true }).getAttribute('aria-pressed'), 'true')
      const closed = app.waitForEvent('close', { timeout: 10_000 })
      await app.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0].close())
      await closed
    } finally { if (app) await app.close().catch(() => {}); await rm(userData, { recursive: true, force: true }) }
  })
}

test('title opens only the fixed separate editor view and rejects untrusted launch arguments', { timeout: 60_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-title-editor-route-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await app.evaluate(() => {
      const childProcess = process.getBuiltinModule('node:child_process')
      const { EventEmitter } = process.getBuiltinModule('node:events')
      childProcess.spawn = (...args) => {
        globalThis.__editorArgs = args
        const child = new EventEmitter()
        globalThis.__editorChild = child
        queueMicrotask(() => child.emit('spawn'))
        return child
      }
    })
    await page.getByRole('button', { name: '編集モードで始める', exact: true }).click()
    await page.getByRole('button', { name: 'ストーリー編集', exact: true }).click()
    const args = await app.evaluate(() => globalThis.__editorArgs)
    assert.equal(args[1][0], join(root, 'dist/editor/main/index.js'))
    assert.deepEqual(args[1].slice(1), ['--editor-view=story', '--editor-launch'])
    await assert.rejects(page.evaluate(() => globalThis.janken.launcher.openEditor('../../other')))
    await app.evaluate(() => globalThis.__editorChild.emit('exit', 0))
    await page.getByRole('button', { name: 'バトル立ち絵編集', exact: true }).click()
    await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
    assert.deepEqual(await app.evaluate(() => globalThis.__editorArgs[1].slice(1)), ['--editor-view=battle', '--editor-launch'])
    await app.evaluate(() => globalThis.__editorChild.emit('exit', 0))
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    await page.getByRole('button', { name: '紙芝居編集（敗北シーン）', exact: true }).click()
    assert.deepEqual(await app.evaluate(() => globalThis.__editorArgs[1].slice(1)), ['--editor-view=slides', '--editor-launch'])
    await assert.rejects(readFile(join(userData, 'janken-save.json')))
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

test('standalone event selection starts the real normal battle without creating a normal save', { timeout: 60_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-title-event-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
    await page.getByRole('button', { name: 'サブイベント1（ベルカ戦）', exact: true }).click()
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
    await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
    await page.getByRole('button', { name: 'サブイベント1（ベルカ戦）', exact: true }).waitFor()
    await assert.rejects(readFile(join(userData, 'janken-save.json')))
    await page.getByRole('button', { name: '戻る', exact: true }).click()
    assert.equal(await page.getByRole('button', { name: 'つづきから', exact: true }).isDisabled(), true)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})
