import assert from 'node:assert/strict'
import { cp, mkdir, mkdtemp, readFile, realpath, rm, symlink } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { dirname, join } from 'node:path'
import { spawnSync } from 'node:child_process'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const require = createRequire(import.meta.url)
const executablePath = require('electron')
const viteCli = join(dirname(require.resolve('electron-vite')), '../bin/electron-vite.js')

test('editor JSON save survives an isolated game rebuild and restart', { timeout: 180_000 }, async () => {
  const temporary = await mkdtemp(join(tmpdir(), 'janken-layout-reflection-'))
  let app
  try {
    // Vite resolves HTML inputs to real paths; Windows TEMP can use 8.3 aliases.
    const project = await realpath(temporary)
    for (const path of ['electron', 'packages', 'content', 'package.json', 'tsconfig.json', 'electron.vite.game.config.ts']) {
      await cp(join(root, path), join(project, path), { recursive: true })
    }
    const rendererRoot = join(project, 'electron/renderer')
    assert.equal(rendererRoot, await realpath(rendererRoot))
    await symlink(await realpath(join(root, 'node_modules')), join(project, 'node_modules'), process.platform === 'win32' ? 'junction' : 'dir')
    const target = join(project, 'content/stories/matilda-tutorial.json')
    const original = await readFile(target, 'utf8')
    const source = JSON.parse(original)
    const paths = [...source.assets.map((asset) => asset.path),
      ...['rock', 'scissors', 'paper'].map((hand) => `godot/assets/battle/cards/${hand}_normal.png`)]
    for (const path of paths) {
      await mkdir(dirname(join(project, path)), { recursive: true })
      await cp(join(root, path), join(project, path))
    }
    app = await electron.launch({ executablePath, args: [join(root, 'dist/editor/main/index.js'),
      `--user-data-dir=${join(project, 'editor-user')}`, `--content-root=${project}`] })
    let page = await app.firstWindow()
    await page.getByLabel('配置ID').waitFor()
    await page.waitForFunction(() => !document.querySelector('[aria-label="配置ID"]').disabled)
    await page.getByLabel('配置ID').selectOption('layout.cards.box')
    await page.getByLabel('X座標').fill('1510')
    await page.getByLabel('拡大率').fill('0.9')
    await page.getByRole('button', { name: '配置を保存', exact: true }).click()
    await page.getByRole('status').getByText(/保存しました/).waitFor()
    const saved = JSON.parse(await readFile(target, 'utf8'))
    const edited = saved.layouts.find((layout) => layout.id === 'layout.cards.box')
    assert.equal(edited.x, 1510)
    assert.equal(edited.scale, .9)
    assert.deepEqual(saved, { ...source, layouts: source.layouts.map((layout) => layout.id === edited.id ? edited : layout) })
    assert.equal(await readFile(target + '.bak', 'utf8'), original)
    await app.close(); app = undefined
    const build = spawnSync(process.execPath, [viteCli, 'build', '--config', 'electron.vite.game.config.ts'],
      { cwd: project, encoding: 'utf8', timeout: 90_000 })
    assert.equal(build.error, undefined, String(build.error))
    assert.equal(build.status, 0, build.stdout + build.stderr)
    let playerBytes
    for (let attempt = 0; attempt < 2; attempt++) {
      app = await electron.launch({ executablePath, args: [join(project, 'dist/game/main/index.js'),
        `--user-data-dir=${join(project, 'game-user')}`] })
      page = await app.firstWindow()
      await page.getByRole('button', { name: attempt ? 'つづきから' : 'はじめから', exact: true }).click()
      const box = page.getByTestId('card-box')
      await box.waitFor()
      assert.equal(await box.evaluate((element) => element.style.left), '1510px')
      assert.equal(await box.evaluate((element) => element.style.transform), 'scale(0.9, 0.9)')
      await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].length > 0 &&
        [...document.querySelectorAll('.story-stage img')].every((img) => img.complete && img.naturalWidth > 0))
      const bytes = await readFile(join(project, 'game-user/janken-save.json'), 'utf8')
      if (attempt) assert.equal(bytes, playerBytes)
      else playerBytes = bytes
      await app.close(); app = undefined
    }
    assert.equal(await readFile(join(root, 'content/stories/matilda-tutorial.json'), 'utf8'), original)
  } finally {
    try {
      if (app) await app.close()
    } finally {
      await rm(temporary, { recursive: true, force: true })
    }
  }
})
