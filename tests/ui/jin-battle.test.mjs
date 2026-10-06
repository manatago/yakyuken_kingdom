import assert from 'node:assert/strict'
import { mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('guild Jin verification persists a three-card draft, retries failed saves, reloads, transfers a card and returns home', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-jin-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 30, items: ['rock_attract_white'] },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end',
      flags: ['matilda.tutorial.completed', 'matilda.normal.started'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }
  let app, page
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [`--user-data-dir=${data}`, join(root, 'dist/game/main/index.js')] })
    page = await app.firstWindow()
    page.on('pageerror', (error) => console.error('Jin renderer pageerror:', error))
    page.on('console', (message) => { if (message.type() === 'error') console.error('Jin renderer console:', message.text()) })
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
  }
  const failNextSave = async () => {
    await app.evaluate(() => {
      const fs = process.getBuiltinModule('node:fs/promises')
      const rename = fs.rename
      fs.rename = async () => { fs.rename = rename; throw new Error('Injected Jin save failure') }
    })
  }
  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await page.getByTestId('jin-draft-disclosure').locator('summary').click()
    await page.getByTestId('jin-draft').waitFor()
    await failNextSave()
    await page.getByRole('button', { name: 'ジン戦に追加 パー N 7', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.deepEqual(await read(), original)
    await page.getByRole('button', { name: 'ジン戦に追加 パー N 7', exact: true }).click()
    await page.getByRole('button', { name: 'ジン戦に追加 パー N 8', exact: true }).click()
    await page.getByRole('button', { name: 'ジン戦に追加 パー N 9', exact: true }).click()
    await page.getByTestId('jin-draft').locator('p').filter({ hasText: '選択済み 3/3' }).waitFor()
    assert.equal((await read()).progress.jin_draft.length, 3)
    await app.close(); app = undefined
    await open()
    await page.getByTestId('jin-draft-disclosure').locator('summary').click()
    await page.getByTestId('jin-draft').waitFor()
    assert.equal((await read()).progress.jin_draft.length, 3)
    await page.getByRole('button', { name: '3枚でジン戦を開始', exact: true }).click()
    await page.getByRole('heading', { name: 'ジン戦（確認用）', exact: true }).waitFor()
    await page.getByRole('button', { name: '選択 パー N', exact: true }).first().click()
    const session = await page.context().newCDPSession(page)
    for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
      await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
      await page.waitForFunction(({ width, height }) => {
        const frame = document.querySelector('[data-testid="jin-frame"]').getBoundingClientRect()
        const scale = Math.min(width / 1920, height / 1080)
        return Math.abs(frame.width - 1920 * scale) < 1 && Math.abs(frame.height - 1080 * scale) < 1
      }, size)
    }
    await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
    await page.getByLabel('この勝負で使うアイテム').selectOption('rock_attract_white')
    await page.evaluate(() => { Math.random = () => 0 })
    await failNextSave()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.equal((await read()).progress.jin_battle.rounds.length, 0)
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('jin-result').waitFor()
    assert.equal((await read()).progress.jin_battle.rounds.length, 1)
    assert.deepEqual((await read()).progress.jin_battle.round_item_ids, ['rock_attract_white'])
    assert.deepEqual((await read()).player.items, ['rock_attract_white'])
    assert.equal((await read()).progress.jin_battle.rounds[0].opponent_index, 2)
    await mkdir(join(root, 'test-results/jin'), { recursive: true })
    await page.screenshot({ path: join(root, 'test-results/jin/battle.png') })
    await app.close(); app = undefined
    await open()
    await page.getByTestId('jin-result').waitFor()
    await page.evaluate(() => { Math.random = () => 0 })
    await failNextSave()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.equal((await read()).progress.jin_battle.settled, false)
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    const settled = await read()
    assert.equal(settled.progress.jin_battle.settled, true)
    assert.equal(settled.player.inventory.length, cards.length + 1)
    assert.deepEqual(settled.player.items, [])
    assert.equal(settled.player.money, 33)
    await app.close(); app = undefined
    await open()
    await page.getByTestId('jin-settled').waitFor()
    assert.equal((await read()).player.inventory.length, cards.length + 1)
    await page.getByRole('button', { name: 'ギルドホームに戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'guild.home')
    await session.detach().catch(() => {})
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
