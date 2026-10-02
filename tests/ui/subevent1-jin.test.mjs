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

test('guild completes the Jin and Marco Subevent 1 battles and resumes the Marco checkpoint', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-subevent1-jin-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 30 },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end',
      flags: ['matilda.tutorial.completed', 'matilda.normal.started'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 },
      jin_draft: [cards[0], cards[3], cards[6]] } }
  let app
  try {
    await writeFile(target, JSON.stringify(original))
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    let page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await page.getByRole('button', { name: 'サブイベント1を開始（解放条件なし）', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1：盗賊団討伐', exact: true }).waitFor()
    await page.getByText('へっ、来たな冒険者。アジトの場所を嗅ぎつけるとは、やるじゃねえか。だが、ここから先は通さねえぜ。', { exact: true }).waitFor()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊ジン戦', exact: true }).waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('subevent1.jin.await'), true)
    await page.evaluate(() => { Math.random = () => 0.5 })
    await page.getByRole('button', { name: '選択 グー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('jin-result').waitFor()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('battle.subevent1.jin'), true)
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    for (let index = 0; index < 5; index++) await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊マルコ戦', exact: true }).waitFor()
    assert.equal((await readFile(target, 'utf8')).includes('subevent1.marco.await'), true)
    await app.close()
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('heading', { name: '盗賊マルコ戦', exact: true }).waitFor()
    await page.evaluate(() => { Math.random = () => 0.5 })
    await page.getByRole('button', { name: '選択 グー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('jin-result').waitFor()
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('jin-settled').waitFor()
    const savedMarco = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(savedMarco.progress.subevent1_marco_battle.battle_id, 'battle.subevent1.marco')
    assert.equal(savedMarco.progress.subevent1_marco_battle.settled, true)
    await page.getByRole('button', { name: '物語を続ける', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント1 前半終了', exact: true }).waitFor()
    await page.getByRole('button', { name: 'ギルドホームへ戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    const settled = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(settled.progress.checkpoint_id, 'guild.home')
    assert.equal(settled.progress.subevent1_jin_battle.battle_id, 'battle.subevent1.jin')
    assert.equal(settled.progress.subevent1_jin_battle.rounds.length, 1)
    assert.equal(settled.progress.subevent1_marco_battle.rounds.length, 1)
    assert.equal(settled.player.inventory.length, cards.length + 2)
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
