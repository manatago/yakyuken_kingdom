import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('battle hand artwork occupies the card button rather than shrinking into its text padding', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-hand-visibility-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'イベントバトル', exact: true }).click()
    await page.getByRole('button', { name: 'サブイベント1（ベルカ戦）', exact: true }).click()
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
    const card = page.getByRole('button', { name: '手持ち 1 rock 1', exact: true })
    await card.locator('img').evaluate(image => image.decode())
    if (process.env.JANKEN_HAND_SCREENSHOT) await page.screenshot({ path: process.env.JANKEN_HAND_SCREENSHOT })
    const metrics = await card.evaluate(button => {
      const frame = button.querySelector('.card-view'), image = frame.querySelector('img')
      return { button: button.getBoundingClientRect().width, art: frame.getBoundingClientRect().width,
        source: image.src, transform: getComputedStyle(image).transform }
    })
    assert.ok(metrics.art / metrics.button > .9, JSON.stringify(metrics))
    assert.match(metrics.source, /rock_normal/)
    assert.equal(metrics.transform, 'none')
    await card.click()
    const deck = page.getByRole('button', { name: 'デッキ 1 rock', exact: true })
    const ratio = await deck.evaluate(button => button.querySelector('.card-view').getBoundingClientRect().width / button.getBoundingClientRect().width)
    assert.ok(ratio > .9, `Deck artwork ratio: ${ratio}`)
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})
