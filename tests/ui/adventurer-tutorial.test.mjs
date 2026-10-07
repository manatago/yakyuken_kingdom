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

test('Adventurer tutorial persists its steps, shows the forced prediction win and unlocks town entry', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-adventurer-tutorial-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 30 },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end',
      flags: ['matilda.tutorial.completed', 'matilda.normal.started'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }
  let app
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    return app.firstWindow()
  }
  try {
    await writeFile(target, JSON.stringify(original))
    let page = await open()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('button', { name: '冒険者チュートリアルを始める', exact: true }).click()
    await page.getByRole('button', { name: 'ルールを確認した', exact: true }).click()
    await page.getByRole('button', { name: '練習デッキを組む', exact: true }).click()
    await page.getByTestId('adventurer-tutorial').waitFor()
    const inProgress = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(inProgress.progress.adventurer_tutorial.step, 2)
    await app.close(); app = undefined

    page = await open()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('button', { name: 'パーでグーに勝負', exact: true }).click()
    await page.getByRole('button', { name: 'チュートリアルを終える', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.adventurer_tutorial.result, 'win')
    await page.getByRole('button', { name: 'チュートリアルを終える', exact: true }).click()
    await page.getByTestId('adventurer-tutorial-complete').waitFor()
    const completed = JSON.parse(await readFile(target, 'utf8'))
    assert.ok(completed.progress.flags.includes('adventurer.tutorial.completed'))
    assert.equal(completed.progress.adventurer_tutorial, undefined)
    assert.deepEqual(completed.player.deck, cards)
    await page.getByRole('button', { name: 'ランダム戦の街へ', exact: true }).waitFor()
    await page.getByRole('button', { name: 'ランダム戦の街へ', exact: true }).click()
    await page.getByTestId('town-destination-picker').waitFor()
    for (const destination of ['ギルド通りへ出る', '市場広場へ出る', '酒場へ出る']) {
      await page.getByRole('button', { name: destination, exact: true }).waitFor()
    }
  } finally {
    await app?.close().catch(() => {})
    await rm(data, { recursive: true, force: true })
  }
})
