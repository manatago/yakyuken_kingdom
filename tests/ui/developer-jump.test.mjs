import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('developer launcher exposes original targets and creates an isolated, playable Jin save', { timeout: 60_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-launcher-ui-'))
  let editor, game
  try {
    editor = await electron.launch({ executablePath, args: [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await editor.firstWindow()
    await page.getByRole('combobox', { name: '開始地点' }).waitFor()
    assert.equal(await page.getByLabel('開始地点').locator('option').count(), 108)
    await page.getByLabel('開始地点').selectOption({ label: '  └ ジン戦 戦闘前' })
    // Intercept only process creation. Exercise the actual IPC validation and isolated save writer.
    await editor.evaluate(({ app }) => { app.setName('Developer isolation test') })
    await editor.evaluate(() => {
      const child = process.getBuiltinModule('node:child_process')
      const actual = child.spawn
      child.spawn = (...args) => {
        globalThis.__developerSpawn = args
        const process = actual(...args)
        globalThis.__developerChild = process
        return process
      }
    })
    await page.getByRole('button', { name: 'この場面から実プレイ' }).click()
    await page.getByRole('status').filter({ hasText: '別ウィンドウを開きました' }).waitFor()
    const args = await editor.evaluate(() => globalThis.__developerSpawn[1])
    const isolated = args.find(argument => argument.startsWith('--user-data-dir=')).slice('--user-data-dir='.length)
    assert.notEqual(isolated, userData)
    const save = JSON.parse(await readFile(join(isolated, 'janken-save.json'), 'utf8'))
    assert.match(save.progress.checkpoint_id, /^original:subevent1_hideout:/)
    assert.equal(save.progress.original_quest.id, 'subevent1')
    assert.equal(save.player.money, 100)
    assert.equal(save.player.inventory.length, 9)
    await assert.rejects(readFile(join(userData, 'janken-save.json')))
    await assert.rejects(page.evaluate(() => globalThis.janken.content.launchJump(-1)))
    // Close only the child created by this test, then check the exact same save in a controlled player.
    await editor.evaluate(() => globalThis.__developerChild.kill())
    const playData = await mkdtemp(join(tmpdir(), 'janken-jin-play-ui-'))
    const { writeFile } = await import('node:fs/promises')
    try {
      await writeFile(join(playData, 'janken-save.json'), JSON.stringify(save))
      game = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${playData}`, '--isolated-play'] })
      const player = await game.firstWindow()
      await player.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor({ timeout: 15_000 })
      assert.equal(await player.getByTestId('unsupported-save').count(), 0)
    } finally { if (game) await game.close(); game = undefined; await rm(playData, { recursive: true, force: true }) }
  } finally {
    if (game) await game.close()
    if (editor) { await editor.evaluate(() => globalThis.__developerChild?.kill()).catch(() => {}); await editor.close() }
    await rm(userData, { recursive: true, force: true })
  }
})

test('closing an isolated game window exits the process on Mac as well as Windows', { timeout: 30_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-isolated-close-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`, '--isolated-play'] })
    await app.firstWindow()
    const closed = app.waitForEvent('close', { timeout: 10_000 })
    await app.evaluate(({ BrowserWindow }) => BrowserWindow.getAllWindows()[0].close())
    await closed
  } finally { if (app) await app.close().catch(() => {}); await rm(userData, { recursive: true, force: true }) }
})
