import assert from 'node:assert/strict'
import { mkdtemp, mkdir, readFile, writeFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('guild verification Belka battle saves each round, settles once and returns without rewriting Matilda history', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-belka-'))
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
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
  }
  const failNextSave = async () => {
    await app.evaluate(() => {
      const fs = process.getBuiltinModule('node:fs/promises')
      const rename = fs.rename
      fs.rename = async () => { fs.rename = rename; throw new Error('Injected Belka save failure') }
    })
  }
  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await page.getByTestId('belka-verification-disclosure').locator('summary').click()
    await failNextSave()
    await page.getByRole('button', { name: 'ベルカ戦を確認', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.deepEqual(await read(), original)
    await page.getByRole('button', { name: 'ベルカ戦を確認', exact: true }).click()
    await page.getByRole('heading', { name: 'ベルカ戦（確認用）', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'belka.await')
    await page.evaluate(() => { Math.random = () => 0 })
    const session = await page.context().newCDPSession(page)
    for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
      await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
      await page.waitForFunction(({ width, height }) => {
        const frame = document.querySelector('[data-testid="belka-frame"]').getBoundingClientRect()
        const scale = Math.min(width / 1920, height / 1080)
        return Math.abs(frame.width - 1920 * scale) < 1 && Math.abs(frame.height - 1080 * scale) < 1
      }, size)
      const frame = await page.getByTestId('belka-frame').boundingBox()
      assert.ok(Math.abs(frame.x - (size.width - frame.width) / 2) < 1)
      assert.ok(Math.abs(frame.y - (size.height - frame.height) / 2) < 1)
    }
    await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
    await page.waitForFunction(() => { const img = document.querySelector('[data-testid="belka-background"]'); return img.complete && img.naturalWidth > 0 })
    assert.equal(await page.getByTestId('bayes-eye').isVisible(), true)
    await mkdir(join(root, 'test-results/belka'), { recursive: true })
    await page.screenshot({ path: join(root, 'test-results/belka/battle.png') })
    for (let round = 0; round < 3; round++) {
      await page.getByRole('button', { name: '選択 パー N', exact: true }).nth(round).click()
      if (round === 0) await page.getByLabel('この勝負で使うアイテム').selectOption('rock_attract_white')
      if (round === 0) await failNextSave()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      if (round === 0) {
        await page.getByRole('alert').waitFor()
        assert.equal((await read()).progress.belka_battle.rounds.length, 0)
        await page.evaluate(() => { Math.random = () => 0.99 })
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
      }
      await page.getByTestId('belka-result').waitFor()
      assert.equal((await read()).progress.belka_battle.rounds.length, round + 1)
      assert.equal((await read()).progress.belka_battle.round_item_ids.length, round + 1)
      if (round === 0) assert.equal((await read()).progress.belka_battle.rounds[0].opponent_index, 0)
      if (round === 0) {
        await app.close(); app = undefined
        await open()
        await page.getByRole('heading', { name: 'ベルカ戦（確認用）', exact: true }).waitFor()
        await page.evaluate(() => { Math.random = () => 0 })
      }
      if (round === 2) await failNextSave()
      await page.getByRole('button', { name: round === 2 ? '結果を確定' : '次の勝負へ', exact: true }).click()
      if (round === 2) {
        await page.getByRole('alert').waitFor()
        assert.equal((await read()).player.money, 30)
        await page.evaluate(() => { Math.random = () => 0.99 })
        await page.getByRole('button', { name: '結果を確定', exact: true }).click()
      }
    }
    await page.getByTestId('belka-settled').waitFor()
    const settled = await read()
    assert.equal(settled.progress.belka_battle.settled, true)
    assert.equal(settled.player.money, 70)
    assert.deepEqual(settled.player.items, [])
    assert.deepEqual(settled.progress.fixed_battle, original.progress.fixed_battle)
    assert.deepEqual(settled.progress.tutorial, original.progress.tutorial)
    assert.deepEqual(settled.player.deck, original.player.deck)
    await page.getByRole('button', { name: 'ギルドホームに戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'guild.home')
    assert.equal(await page.getByRole('button', { name: 'ベルカ戦を確認', exact: true }).count(), 0)
    await page.getByRole('button', { name: '終了', exact: true }).click()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    assert.equal((await read()).progress.belka_battle.settled, true)
    assert.match(await page.getByTestId('belka-verification-settled').innerText(), /物語本編のベルカ戦はサブイベント1から開始できます/)
    await session.detach().catch(() => {})
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
