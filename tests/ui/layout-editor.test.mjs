import assert from 'node:assert/strict'
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join, dirname } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('layout editor previews scaled dragging, saves one ID and reloads without touching other content', async () => {
  const project = await mkdtemp(join(tmpdir(), 'janken-layout-ui-'))
  const userData = join(project, 'user-data')
  const target = join(project, 'content/stories/matilda-tutorial.json')
  const original = await readFile(join(root, 'content/stories/matilda-tutorial.json'), 'utf8')
  const source = JSON.parse(original)
  const args = [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${userData}`, `--content-root=${project}`]
  let app
  try {
    await mkdir(dirname(target), { recursive: true })
    await writeFile(target, original)
    for (const asset of source.assets) {
      const path = join(project, asset.path)
      await mkdir(dirname(path), { recursive: true })
      await copyFile(join(root, asset.path), path)
    }
    const open = async () => {
      app = await electron.launch({ executablePath, args })
      const page = await app.firstWindow()
      await page.getByLabel('配置ID').waitFor()
      await page.waitForFunction(() => !document.querySelector('[aria-label="配置ID"]').disabled)
      return page
    }
    let page = await open()
    await page.getByLabel('配置ID').selectOption('layout.cards.box')
    const box = page.getByTestId('card-box')
    const rect = await box.boundingBox()
    const stage = await page.locator('.story-stage').boundingBox()
    const scale = stage.width / 1920
    await page.mouse.move(rect.x + rect.width / 2, rect.y + 16)
    await page.mouse.down()
    await page.mouse.move(rect.x + rect.width / 2 - 20, rect.y + 36, { steps: 5 })
    await page.mouse.up()
    assert.ok(Math.abs(Number(await page.getByLabel('X座標').inputValue()) - (1554 - 20 / scale)) < .1)
    assert.equal(await readFile(target, 'utf8'), original)
    assert.equal(await page.getByLabel('配置ID').isDisabled(), true)
    await page.getByRole('button', { name: '変更を取り消す', exact: true }).click()
    assert.equal(await page.getByLabel('X座標').inputValue(), '1554')
    await page.getByLabel('X座標').fill('1510')
    await page.getByLabel('拡大率').fill('0')
    assert.equal(await page.getByRole('button', { name: '配置を保存', exact: true }).isDisabled(), true)
    await page.getByLabel('拡大率').fill('0.9')
    assert.equal(await readFile(target, 'utf8'), original)
    // Backup failure must leave both the source and the unsaved preview intact.
    await mkdir(target + '.bak')
    await page.getByRole('button', { name: '配置を保存', exact: true }).click()
    await page.getByRole('alert').getByText(/保存に失敗/).waitFor()
    assert.equal(await readFile(target, 'utf8'), original)
    assert.equal(await page.getByLabel('X座標').inputValue(), '1510')
    await rm(target + '.bak', { recursive: true })
    await page.getByRole('button', { name: '配置を保存', exact: true }).click()
    await page.getByRole('status').getByText(/保存しました/).waitFor()
    const saved = JSON.parse(await readFile(target, 'utf8'))
    const edited = saved.layouts.find((layout) => layout.id === 'layout.cards.box')
    assert.equal(edited.x, 1510)
    assert.equal(edited.scale, .9)
    assert.deepEqual(saved, { ...source, layouts: source.layouts.map((layout) => layout.id === edited.id ? edited : layout) })
    assert.equal(await readFile(target + '.bak', 'utf8'), original)
    await page.getByRole('button', { name: '再読込', exact: true }).click()
    assert.equal(await page.getByLabel('X座標').inputValue(), '1510')
    await app.close(); app = undefined
    page = await open()
    await page.getByLabel('配置ID').selectOption('layout.cards.box')
    assert.equal(await page.getByLabel('X座標').inputValue(), '1510')
    await page.getByLabel('配置ID').selectOption('layout.cards.showdown')
    await page.getByTestId('tutorial-result').waitFor()
    assert.equal(await page.getByLabel('配置ID').inputValue(), 'layout.cards.showdown')
    await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].every((img) => img.complete && img.naturalWidth > 0))
    if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, 'layout-editor.png') })
    assert.equal(await readFile(target, 'utf8'), JSON.stringify(saved, null, 2) + '\n')
  } finally {
    if (app) await app.close()
    await rm(project, { recursive: true, force: true })
  }
})
