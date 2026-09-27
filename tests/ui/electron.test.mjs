import assert from 'node:assert/strict'
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const require = createRequire(import.meta.url)
const executablePath = require('electron')

for (const application of [
  { build: 'game', title: 'Janken Kingdom', capability: 'save' },
  { build: 'editor', title: 'Janken Editor', capability: 'content' }
]) {
  test(`${application.build} renders its screen with only its own bridge`, async () => {
    const userData = await mkdtemp(join(tmpdir(), 'janken-ui-smoke-'))
    const app = await electron.launch({
      executablePath,
      args: [join(root, 'dist', application.build, 'main/index.js'), `--user-data-dir=${userData}`]
    })
    try {
      const page = await app.firstWindow()
      await page.getByRole('heading', { name: application.title }).waitFor()
      const bridgeKeys = await page.evaluate(() => Object.keys(globalThis.janken ?? {}).sort())
      assert.deepEqual(bridgeKeys, [application.capability, 'windowControls'].sort())
    } finally {
      await app.close()
      await rm(userData, { recursive: true, force: true })
    }
  })
}

test('new game saves Matilda start and Continue restores it after restart', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-ui-new-game-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app
  try {
    app = await electron.launch({ executablePath, args })
    let page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom' }).waitFor()
    assert.equal(await page.getByRole('button', { name: 'つづきから' }).isDisabled(), true)
    await page.getByRole('button', { name: 'はじめから' }).click()
    await page.getByRole('heading', { name: 'マチルダのチュートリアル' }).waitFor()
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), 'matilda.start')
    const save = JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8'))
    assert.equal(save.progress.checkpoint_id, 'matilda.start')
    assert.equal(save.player.inventory.length, 9)
    await app.close()

    app = await electron.launch({ executablePath, args })
    page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom' }).waitFor()
    await page.getByRole('button', { name: 'つづきから' }).click()
    await page.getByRole('heading', { name: 'マチルダのチュートリアル' }).waitFor()
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), 'matilda.start')
    assert.deepEqual(JSON.parse(await readFile(join(userData, 'janken-save.json'), 'utf8')), save)
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('failed save stays on title and shows an error', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-ui-save-error-'))
  const app = await electron.launch({
    executablePath,
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom' }).waitFor()
    await page.waitForFunction(() => !document.querySelector('.title-actions button')?.disabled)
    // Reading succeeds first; the obstruction then isolates the write-failure path.
    await mkdir(join(userData, 'janken-save.json'))
    await page.getByRole('button', { name: 'はじめから' }).click()
    await page.getByRole('alert').getByText('保存に失敗しました').waitFor()
    assert.equal(await page.getByRole('heading', { name: 'Janken Kingdom' }).isVisible(), true)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('existing save requires explicit overwrite confirmation and cancel preserves it', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-ui-confirm-'))
  const target = join(userData, 'janken-save.json')
  const original = JSON.stringify({
    save_version: 1,
    player: { inventory: [], deck: [], money: 73 },
    progress: { checkpoint_id: 'chapter-two.start', flags: ['finished'] }
  })
  await writeFile(target, original)
  let app
  try {
    app = await electron.launch({
      executablePath,
      args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
    })
    const page = await app.firstWindow()
    await page.waitForFunction(() => !document.querySelector('.title-actions button')?.disabled)
    if (process.env.JANKEN_UI_SCREENSHOT_DIR) {
      await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, 'title.png') })
    }
    await page.getByRole('button', { name: 'はじめから' }).click()
    await page.getByRole('alertdialog').waitFor()
    assert.equal(await readFile(target, 'utf8'), original)
    if (process.env.JANKEN_UI_SCREENSHOT_DIR) {
      await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, 'overwrite-confirmation.png') })
    }
    await page.getByRole('button', { name: 'キャンセル' }).click()
    assert.equal(await readFile(target, 'utf8'), original)
    await page.getByRole('button', { name: 'つづきから' }).click()
    await page.getByRole('heading', { name: '保存地点' }).waitFor()
    await page.getByRole('button', { name: 'タイトルに戻る' }).click()
    await page.getByRole('button', { name: 'はじめから' }).click()
    await page.getByRole('button', { name: '保存を上書きして開始' }).click()
    await page.getByRole('heading', { name: 'マチルダのチュートリアル' }).waitFor()
    const replaced = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(replaced.progress.checkpoint_id, 'matilda.start')
    assert.equal(replaced.player.money, 0)
    assert.deepEqual(replaced.progress.flags, [])
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('unreadable save disables new game and preserves the file', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-ui-read-error-'))
  const target = join(userData, 'janken-save.json')
  const original = '{invalid JSON'
  await writeFile(target, original)
  let app
  try {
    app = await electron.launch({
      executablePath,
      args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
    })
    const page = await app.firstWindow()
    await page.getByRole('alert').waitFor()
    assert.equal(await page.getByRole('button', { name: 'はじめから' }).isDisabled(), true)
    assert.equal(await page.getByRole('button', { name: 'つづきから' }).isDisabled(), true)
    // Native disabled controls must also reject direct DOM clicks.
    await page.getByRole('button', { name: 'はじめから' }).evaluate((button) => button.click())
    assert.equal(await readFile(target, 'utf8'), original)
    assert.equal(await page.getByRole('heading', { name: 'Janken Kingdom' }).isVisible(), true)
  } finally {
    if (app) await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('Continue does not label an unrelated saved checkpoint as Matilda', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-ui-other-checkpoint-'))
  await writeFile(join(userData, 'janken-save.json'), JSON.stringify({
    save_version: 1,
    player: { inventory: [], deck: [], money: 0 },
    progress: { checkpoint_id: 'chapter-two.start', flags: [] }
  }))
  const app = await electron.launch({
    executablePath,
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  })
  try {
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから' }).click()
    await page.getByRole('heading', { name: '保存地点' }).waitFor()
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), 'chapter-two.start')
    assert.equal(await page.getByRole('heading', { name: 'マチルダのチュートリアル' }).count(), 0)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
