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

for (const outcome of ['win', 'lose']) {
  test(`normal battle ${outcome}: prepared snapshot, save/restart, settlement and return/retry`, { timeout: 120_000 }, async () => {
    const data = await mkdtemp(join(tmpdir(), 'janken-fixed-'))
    const target = join(data, 'janken-save.json')
    const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
    const original = { save_version: 1, player: { inventory: cards, deck: cards, prepared_deck: [...cards].reverse(), money: 20, items: ['rock_attract_white'] },
      progress: { checkpoint_id: 'matilda.end', flags: ['matilda.tutorial.completed'],
        tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 } } }
    let app, page
    const read = async () => JSON.parse(await readFile(target, 'utf8'))
    const open = async () => {
      app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
      page = await app.firstWindow()
      const session = await page.context().newCDPSession(page)
      await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByTestId('checkpoint-id').waitFor()
      await page.evaluate(() => { Math.random = () => 0 })
    }
    const restart = async () => {
      const before = await readFile(target, 'utf8')
      await app.close(); app = undefined
      await open()
      assert.equal(await readFile(target, 'utf8'), before)
    }
    const failNextSave = async () => {
      await app.evaluate(() => {
        const fs = process.getBuiltinModule('node:fs/promises')
        const rename = fs.rename
        fs.rename = async () => { fs.rename = rename; throw new Error('Injected test save failure') }
      })
    }
    const capture = async (name) => {
      const directory = join(root, 'test-results/fixed-battle')
      await mkdir(directory, { recursive: true })
      await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].every((img) => img.complete && img.naturalWidth > 0))
      await page.screenshot({ path: join(directory, `${name}.png`) })
    }
    try {
      await writeFile(target, JSON.stringify(original))
      await open()
      await page.getByRole('button', { name: '通常戦を試す', exact: true }).click()
      await page.getByTestId('story-text').waitFor()
      await page.getByRole('button', { name: '次へ', exact: true }).click()
      await page.getByRole('button', { name: 'マチルダ通常戦を開始', exact: true }).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      assert.deepEqual((await read()).progress.fixed_battle.player_deck, original.player.prepared_deck)
      assert.deepEqual(await page.getByTestId('fixed-deck').getByRole('button').first().getAttribute('aria-label'), '選択 パー N')
      await capture(`${outcome}-selection`)
      for (let round = 0; round < 3; round++) {
        const hand = outcome === 'win' ? 'パー' : 'チョキ'
        const buttons = page.getByRole('button', { name: `選択 ${hand} N`, exact: true })
        await buttons.nth(round).click()
        if (round === 0) await page.getByLabel('この勝負で使うアイテム').selectOption('rock_attract_white')
        if (round === 0) {
          const before = await readFile(target, 'utf8')
          await failNextSave()
          await page.getByRole('button', { name: '勝負！', exact: true }).click()
          await page.getByRole('alert').waitFor()
          assert.equal(await readFile(target, 'utf8'), before)
        }
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
        await page.getByTestId('fixed-result').waitFor()
        const saved = await read()
        assert.equal(saved.progress.fixed_battle.rounds.length, round + 1)
        assert.equal(saved.progress.fixed_battle.acknowledged, round)
        assert.deepEqual(saved.player.deck, original.player.deck)
        assert.deepEqual(saved.progress.tutorial, original.progress.tutorial)
        assert.deepEqual(saved.player.inventory, original.player.inventory)
        assert.deepEqual(saved.progress.fixed_battle.round_item_ids,
          Array.from({ length: round + 1 }, (_, index) => index === 0 ? 'rock_attract_white' : null))
        assert.deepEqual(saved.player.items, original.player.items)
        await restart()
        await page.getByTestId('fixed-result').waitFor()
        if (round < 2) await page.getByRole('button', { name: '次の勝負へ', exact: true }).click()
      }
      if (outcome === 'win') {
        const before = await readFile(target, 'utf8')
        await failNextSave()
        await page.getByRole('button', { name: '結果を確定', exact: true }).click()
        await page.getByRole('alert').waitFor()
        assert.equal(await readFile(target, 'utf8'), before)
        await page.evaluate(() => { Math.random = () => .999 })
      }
      await page.getByRole('button', { name: '結果を確定', exact: true }).click()
      await page.getByTestId('fixed-settled').waitFor()
      assert.equal((await read()).player.money, outcome === 'win' ? 30 : 20)
      assert.deepEqual((await read()).player.items, [])
      await capture(`${outcome}-settled`)
      await restart()
      await page.getByTestId('fixed-settled').waitFor()
      assert.equal((await read()).player.money, outcome === 'win' ? 30 : 20)
      assert.equal(await page.getByRole('button', { name: '結果を確定', exact: true }).count(), 0)
      if (outcome === 'lose') {
        await page.getByRole('button', { name: '会話に戻る', exact: true }).click()
        await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'matilda.normal.loss.intro')
        assert.equal((await read()).player.money, 20)
        await page.getByRole('button', { name: 'ホームに戻る', exact: true }).click()
        await page.getByRole('button', { name: 'つづきから', exact: true }).click()
        await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'matilda.normal.loss.intro')
        await restart()
        for (const checkpoint of ['matilda.normal.loss.intro', 'matilda.normal.loss.offer', 'matilda.normal.loss.response']) {
          await page.waitForFunction((id) => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === id, checkpoint)
          await page.getByRole('button', { name: '次へ', exact: true }).click()
        }
        await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'matilda.normal.loss.end')
        const before = await readFile(target, 'utf8')
        await failNextSave()
        await page.getByRole('button', { name: 'デッキを確認して再挑戦する', exact: true }).click()
        await page.getByRole('alert').waitFor()
        assert.equal(await readFile(target, 'utf8'), before)
        await page.getByRole('button', { name: 'デッキを確認して再挑戦する', exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
        const retried = await read()
        assert.equal(retried.player.money, 20)
        assert.deepEqual(retried.progress.fixed_battle.rounds, [])
        assert.deepEqual(retried.progress.tutorial, original.progress.tutorial)
        await restart()
        assert.deepEqual((await read()).progress.fixed_battle.rounds, [])
      } else {
        await page.getByRole('button', { name: '会話に戻る', exact: true }).click()
        await page.getByTestId('story-text').waitFor()
        assert.equal((await read()).progress.checkpoint_id, 'matilda.normal.complete')
        await page.getByRole('button', { name: '次へ', exact: true }).click()
        await page.getByRole('heading', { name: '通常戦終了', exact: true }).waitFor()
        await restart()
        assert.equal((await read()).player.money, 30)
      }
    } finally {
      try { if (app) await app.close() }
      finally { await rm(data, { recursive: true, force: true }) }
    }
  })
}
