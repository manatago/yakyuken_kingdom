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

for (const origin of ['matilda.end', 'matilda.normal.end']) {
  test(`guild home from ${origin}: persist, reload, edit, failure safety and verification return`, { timeout: 120_000 }, async () => {
    const data = await mkdtemp(join(tmpdir(), 'janken-guild-'))
    const target = join(data, 'janken-save.json')
    const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
    const normal = origin === 'matilda.normal.end'
    const original = { save_version: 1, player: { inventory: [...cards, { hand: 'rock', grade: 2 }], deck: cards, money: normal ? 30 : 20 },
      progress: { checkpoint_id: origin, flags: ['matilda.tutorial.completed', ...(normal ? ['matilda.normal.started'] : [])],
        tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
        ...(normal ? { fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
          rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
          acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } : {}) } }
    let app, page
    const read = async () => JSON.parse(await readFile(target, 'utf8'))
    const open = async () => {
      app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
      page = await app.firstWindow()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByTestId('checkpoint-id').waitFor()
    }
    const failNextSave = async () => {
      await app.evaluate(() => {
        const fs = process.getBuiltinModule('node:fs/promises')
        const rename = fs.rename
        fs.rename = async () => { fs.rename = rename; throw new Error('Injected test save failure') }
      })
    }
    const assertHistory = async () => {
      const save = await read()
      assert.deepEqual(save.player.inventory, original.player.inventory)
      assert.deepEqual(save.player.deck, original.player.deck)
      assert.equal(save.player.money, original.player.money)
      assert.deepEqual(save.progress.tutorial, original.progress.tutorial)
      assert.deepEqual(save.progress.fixed_battle, original.progress.fixed_battle)
      assert.deepEqual(save.progress.flags, original.progress.flags)
    }
    try {
      await writeFile(target, JSON.stringify(original))
      await open()
      await failNextSave()
      await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).click()
      await page.getByRole('alert').waitFor()
      assert.deepEqual(await read(), original)
      await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).click()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      await page.getByTestId('subevent-board').waitFor()
      assert.match(await page.getByTestId('quest-subevent1').innerText(), /未解放：冒険者チュートリアルを完了/)
      assert.match(await page.getByTestId('quest-subevent2').innerText(), /未解放：サブイベント1を完了/)
      assert.equal((await read()).progress.guild_return_checkpoint, origin)
      assert.equal((await read()).progress.checkpoint_id, 'guild.home')
      await assertHistory()
      const beforeReload = await readFile(target, 'utf8')
      await app.close(); app = undefined
      await open()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      assert.equal(await readFile(target, 'utf8'), beforeReload)
      for (const label of ['ショップ', 'ステータス', '街に出る', '次の章へ']) {
        assert.equal(await page.getByRole('button', { name: label, exact: true }).isDisabled(), true)
      }
      for (const label of ['クエスト', 'アイテム', '装備']) {
        assert.equal(await page.getByRole('button', { name: label, exact: true }).isDisabled(), false)
      }
      const session = await page.context().newCDPSession(page)
      for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
        await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
        await page.waitForFunction(({ width, height }) => {
          const frame = document.querySelector('[data-testid="guild-frame"]').getBoundingClientRect()
          const scale = Math.min(width / 1920, height / 1080)
          return Math.abs(frame.width - 1920 * scale) < 1 && Math.abs(frame.height - 1080 * scale) < 1
        }, size)
        const frame = await page.getByTestId('guild-frame').boundingBox()
        assert.ok(Math.abs(frame.x - (size.width - frame.width) / 2) < 1)
        assert.ok(Math.abs(frame.y - (size.height - frame.height) / 2) < 1)
        const menu = await page.getByRole('navigation', { name: 'ギルドメニュー' }).boundingBox()
        assert.ok(menu.x >= frame.x && menu.y >= frame.y && menu.y + menu.height <= frame.y + frame.height + 1)
      }
      await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
      await page.waitForFunction(() => { const img = document.querySelector('[data-testid="guild-background"]'); return img.complete && img.naturalWidth > 0 })
      await mkdir(join(root, 'test-results/guild-home'), { recursive: true })
      await page.screenshot({ path: join(root, 'test-results/guild-home', `${origin}-home.png`) })
      for (const [label, testId] of [['クエスト', 'subevent-board'], ['アイテム', 'item-inventory'], ['装備', 'equipment-inventory']]) {
        await page.getByRole('button', { name: label, exact: true }).click()
        await page.waitForFunction((id) => {
          const scroller = document.querySelector('.guild-notice')
          const target = document.querySelector(`[data-testid="${id}"]`)
          if (!scroller || !target) return false
          const viewport = scroller.getBoundingClientRect()
          const section = target.getBoundingClientRect()
          return scroller.scrollHeight <= scroller.clientHeight
            ? section.top >= viewport.top && section.top < viewport.bottom
            : section.top < viewport.bottom && section.bottom > viewport.top
        }, testId)
      }
      await page.getByRole('button', { name: 'カード', exact: true }).click()
      for (const size of [{ width: 1920, height: 1080 }, { width: 1024, height: 768 }, { width: 600, height: 1000 }]) {
        await session.send('Emulation.setDeviceMetricsOverride', { ...size, deviceScaleFactor: 1, mobile: false })
        await page.waitForFunction(({ width, height }) => {
          const frame = document.querySelector('[data-testid="guild-frame"]').getBoundingClientRect()
          const scale = Math.min(width / 1920, height / 1080)
          return Math.abs(frame.width - 1920 * scale) < 1 && Math.abs(frame.height - 1080 * scale) < 1
        }, size)
        const deck = await page.getByTestId('deck-panel').boundingBox()
        const menu = await page.getByRole('navigation', { name: 'ギルドメニュー' }).boundingBox()
        assert.ok(deck.y + deck.height <= menu.y, `deck must not overlap menu at ${size.width}x${size.height}`)
      }
      await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
      await page.getByRole('button', { name: '編成を編集', exact: true }).click()
      await page.getByRole('button', { name: '編成から削除 グー N', exact: true }).first().click()
      await page.getByRole('button', { name: 'キャンセル', exact: true }).click()
      assert.equal(await readFile(target, 'utf8'), beforeReload)
      await page.getByRole('button', { name: '編成を編集', exact: true }).click()
      await page.getByRole('button', { name: '編成から削除 グー N', exact: true }).first().click()
      await page.getByRole('button', { name: '編成に追加 グー B', exact: true }).click()
      await failNextSave()
      await page.getByRole('button', { name: '編成を保存', exact: true }).click()
      await page.getByRole('alert').waitFor()
      assert.equal(await readFile(target, 'utf8'), beforeReload)
      await page.getByRole('button', { name: '編成を保存', exact: true }).click()
      await page.getByRole('dialog').waitFor({ state: 'hidden' })
      assert.equal((await read()).player.prepared_deck.at(-1).grade, 2)
      await assertHistory()
      await page.screenshot({ path: join(root, 'test-results/guild-home', `${origin}-cards.png`) })
      await page.getByRole('button', { name: 'カード表示を閉じる', exact: true }).click()
      await page.getByRole('button', { name: '終了', exact: true }).click()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      const beforeReturn = await readFile(target, 'utf8')
      await failNextSave()
      await page.getByRole('button', { name: '確認画面へ戻る', exact: true }).click()
      await page.getByRole('alert').waitFor()
      assert.equal(await readFile(target, 'utf8'), beforeReturn)
      await page.getByRole('button', { name: '確認画面へ戻る', exact: true }).click()
      await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).waitFor()
      assert.equal((await read()).progress.checkpoint_id, origin)
      assert.equal(Object.hasOwn((await read()).progress, 'guild_return_checkpoint'), false)
      await assertHistory()
      await app.close(); app = undefined
      await open()
      await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).waitFor()
      assert.equal((await read()).progress.checkpoint_id, origin)
    } finally {
      try { if (app) await app.close() }
      finally { await rm(data, { recursive: true, force: true }) }
    }
  })
}
