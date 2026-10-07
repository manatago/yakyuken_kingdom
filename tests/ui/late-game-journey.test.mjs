import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const cards = Array.from({ length: 12 }, () => ({ hand: 'paper', grade: 1 }))
const original = { save_version: 1, player: { inventory: cards, deck: cards.slice(0, 9), prepared_deck: cards.slice(0, 9), money: 50 },
  progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.end', flags: ['matilda.tutorial.completed', 'stage2_complete', 'stage3_complete',
    'stage4_complete', 'stage5_complete'], tutorial: { battle_id: 'battle.matilda.practice',
      rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 } } }

async function advanceStoryTo(page, target) {
  for (let attempt = 0; attempt < 50; attempt++) {
    const current = await page.getByTestId('checkpoint-id').textContent()
    if (current === target) return
    const advance = page.locator('.story-dialogue button:not(:disabled)').first()
    if (!await advance.count()) throw new Error(`Cannot advance story from ${current}: ${await page.locator('body').innerText()}`)
    await advance.click()
    await page.waitForFunction((previous) => document.querySelector('[data-testid="checkpoint-id"]')?.textContent !== previous,
      current, { timeout: 5000 })
  }
  throw new Error(`Story did not reach ${target}: ${await page.getByTestId('checkpoint-id').textContent()}`)
}

test('Stage 6 scripted loss, rematch, Stage 7 epilogue and completion form one resumable UI journey',
  { timeout: 180_000 }, async () => {
    const data = await mkdtemp(join(tmpdir(), 'janken-late-game-'))
    const target = join(data, 'janken-save.json')
    let app, page
    const read = async () => JSON.parse(await readFile(target, 'utf8'))
    const open = async () => {
      app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
      page = await app.firstWindow()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    }
    const playFixedRounds = async (count, buttonLabel, continuationLabel) => {
      for (let round = 0; round < count; round++) {
        await page.locator('[aria-label="選択 パー N"]:not(:disabled)').first().click()
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
        await page.getByTestId('fixed-result').waitFor()
        if (round < count - 1) {
          await page.getByRole('button', { name: continuationLabel, exact: true }).click()
          await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
        }
      }
      await page.getByRole('button', { name: buttonLabel, exact: true }).click()
      await page.getByTestId('fixed-settled').waitFor()
    }

    try {
      await writeFile(target, JSON.stringify(original))
      await open()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      await page.getByRole('button', { name: 'Stage 6・王宮晩餐会へ', exact: true }).click()
      await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'stage6.pre.receptionist')
      await advanceStoryTo(page, 'stage6.pre.end')
      await advanceStoryTo(page, 'stage6.banquet.battle')
      assert.match(await page.getByTestId('fixed-deck').locator('h2').innerText(), /アレクシア王女戦/)
      await page.getByRole('button', { name: 'アレクシア王女戦を開始', exact: true }).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      await page.evaluate(() => { Math.random = () => 0 })

      await page.locator('[aria-label="選択 パー N"]:not(:disabled)').first().click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByTestId('fixed-result').waitFor()
      assert.equal((await read()).progress.fixed_battle.rounds.length, 1)
      await app.close(); app = undefined
      await open()
      await page.getByTestId('fixed-result').waitFor()
      assert.equal((await read()).progress.fixed_battle.rounds.length, 1)
      await page.evaluate(() => { Math.random = () => 0 })
      await page.getByRole('button', { name: '次の勝負へ', exact: true }).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      await page.locator('[aria-label="選択 パー N"]:not(:disabled)').first().click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByTestId('fixed-result').waitFor()
      await page.getByRole('button', { name: '次の勝負へ', exact: true }).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      await page.locator('[aria-label="選択 パー N"]:not(:disabled)').first().click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByRole('button', { name: '結果を確定', exact: true }).click()
      await page.getByTestId('fixed-settled').waitFor()
      assert.match(await page.getByTestId('fixed-settled').innerText(), /対戦に敗北/)
      assert.equal((await read()).player.inventory.length, 9)
      await page.getByRole('button', { name: '会話に戻る', exact: true }).click()
      await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'stage6.banquet.result')
      await advanceStoryTo(page, 'stage6.banquet.end')
      await advanceStoryTo(page, 'stage6.recover.end')
      await advanceStoryTo(page, 'stage6.rematch.battle')
      assert.match(await page.getByTestId('fixed-deck').locator('h2').innerText(), /アレクシア王女戦/)
      await page.getByRole('button', { name: 'アレクシア王女戦を開始', exact: true }).click()
      await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      await page.evaluate(() => { Math.random = () => 0 })
      await playFixedRounds(3, '結果を確定', '次の勝負へ')
      assert.match(await page.getByTestId('fixed-settled').innerText(), /対戦に勝利/)
      await page.getByRole('button', { name: '会話に戻る', exact: true }).click()
      await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'stage6.rematch.result')
      await advanceStoryTo(page, 'stage6.rematch.end')
      await advanceStoryTo(page, 'stage6.post.end')
      await page.getByRole('button', { name: '継承の記録を保存してギルドへ戻る', exact: true }).click()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      assert.ok((await read()).progress.flags.includes('stage6_complete'))
      assert.equal((await read()).progress.checkpoint_id, 'guild.home')

      await page.getByRole('button', { name: '最終章・エピローグを見る', exact: true }).click()
      await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === 'stage7.throne.declaration')
      await advanceStoryTo(page, 'stage7.throne.end')
      await advanceStoryTo(page, 'stage7.epilogue.end')
      assert.match(await page.getByRole('heading').first().innerText(), /最終章/)
      await page.getByRole('button', { name: 'エピローグを終える', exact: true }).click()
      await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
      const completed = await read()
      assert.ok(completed.progress.flags.includes('game_complete'))
      assert.equal(completed.progress.checkpoint_id, 'guild.home')
      await page.getByTestId('game-complete').waitFor()
    } finally {
      try { if (app) await app.close() }
      finally { await rm(data, { recursive: true, force: true }) }
    }
  })
