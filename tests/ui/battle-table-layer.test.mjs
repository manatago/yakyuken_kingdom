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
const targets = JSON.parse(await readFile(join(root, 'content/developer-tools.json'), 'utf8')).battle_targets.filter(target => target.mode === 'battle')

test('every normal event battle paints its table in front of the opponent and below the HUD', { timeout: 90_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-table-layer-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    for (const target of targets) {
      await page.reload()
      await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
      await page.getByRole('button', { name: target.name, exact: true }).click()
      await page.getByRole('button', { name: '自動', exact: true }).click()
      await page.getByRole('button', { name: '準備完了', exact: true }).click()
      await page.getByTestId('original-portrait-deck').waitFor()
      await page.waitForFunction(() => [...document.querySelectorAll('img[data-testid^="original-portrait-"]')]
        .filter(image => image.dataset.testid !== 'original-portrait-deck').some(image => image.complete && image.naturalWidth > 0))
      await page.getByTestId('original-portrait-deck').evaluate(image => image.decode())
      const order = await page.evaluate(() => {
        const table = document.querySelector('[data-testid="original-portrait-deck"]').parentElement
        const actor = [...document.querySelectorAll('img[data-testid^="original-portrait-"]')]
          .find(image => image.dataset.testid !== 'original-portrait-deck').parentElement
        const hud = document.querySelector('[data-testid="original-opponent-hp"]')
        return { actorBeforeTable: !!(actor.compareDocumentPosition(table) & Node.DOCUMENT_POSITION_FOLLOWING),
          tableBeforeHud: !!(table.compareDocumentPosition(hud) & Node.DOCUMENT_POSITION_FOLLOWING) }
      })
      if (process.env.JANKEN_TABLE_SCREENSHOT && target.id === 'subevent1_boss') await page.screenshot({ path: process.env.JANKEN_TABLE_SCREENSHOT })
      assert.equal(order.actorBeforeTable, true, target.name)
      assert.equal(order.tableBeforeHud, true, target.name)
    }
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})

for (const preview of [false, true]) test(`${preview ? 'battle editor preview' : 'Matilda tutorial'} also paints the table above the opponent`, { timeout: 45_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-table-extra-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, `dist/${preview ? 'editor' : 'game'}/main/index.js`), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    if (preview) {
      await page.getByRole('button', { name: '戦闘表示編集', exact: true }).click()
      const selection = await page.evaluate(async () => {
        const catalog = await globalThis.janken.content.traceCatalog()
        for (let selected = 0; selected < catalog.length; selected++) {
          const target = catalog[selected]
          const record = await globalThis.janken.content.readTrace(target.document, target.target)
          const deck = record.commands.findIndex(command => command.kind === 'deck' && command.args[0])
          const portrait = record.commands.findIndex(command => command.kind === 'set_portrait')
          if (deck >= 0 && portrait >= 0) return { selected, index: Math.max(deck, portrait) }
        }
        throw new Error('No original portrait/table trace found')
      })
      await page.getByLabel('戦闘の対象').selectOption(String(selection.selected))
      await page.getByLabel('表示命令').selectOption(String(selection.index))
    } else {
      await page.getByRole('button', { name: '中断から始める', exact: true }).click()
      await page.getByRole('button', { name: 'チュートリアル', exact: true }).click()
    }
    await page.getByTestId('original-portrait-deck').waitFor()
    await page.waitForFunction(() => [...document.querySelectorAll('img[data-testid^="original-portrait-"]')]
      .filter(image => image.dataset.testid !== 'original-portrait-deck').some(image => image.complete && image.naturalWidth))
    assert.equal(await page.evaluate(() => {
      const table = document.querySelector('[data-testid="original-portrait-deck"]').parentElement
      const actor = [...document.querySelectorAll('img[data-testid^="original-portrait-"]')]
        .find(image => image.dataset.testid !== 'original-portrait-deck').parentElement
      return !!(actor.compareDocumentPosition(table) & Node.DOCUMENT_POSITION_FOLLOWING)
    }), true)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})
