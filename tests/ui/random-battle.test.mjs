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

test('Stage 1 random encounter persists its generated deck and settles a one-HP battle after reload', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-random-battle-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 30, items: ['substitute_card'] },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end', flags: ['matilda.tutorial.completed', 'matilda.normal.started', 'adventurer.tutorial.completed'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }
  let app
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    return app.firstWindow()
  }
  try {
    await writeFile(target, JSON.stringify(original))
    let page = await open()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.evaluate(() => { Math.random = () => .3 })
    await page.getByRole('button', { name: 'ランダム戦の街へ', exact: true }).click()
    await page.getByTestId('town-destination-picker').waitFor()
    await page.getByRole('button', { name: 'ギルド通りへ出る', exact: true }).click()
    await page.getByTestId('random-encounter').waitFor()
    const portrait = page.getByTestId('random-opponent-portrait')
    assert.equal(await portrait.getAttribute('data-portrait-phase'), 'encounter')
    assert.equal(await portrait.evaluate((image) => image.naturalWidth > 0), true)
    const encounterSave = await read()
    assert.equal(encounterSave.progress.random_battle.opponent_id, 'thug_01')
    assert.equal(encounterSave.progress.random_battle.opponent_deck.length, 3)
    assert.equal(await page.getByTestId('random-dialogue-greeting').innerText(), '「ヘッ、弱そうなやつ発見。カードよこしな！」')
    await page.getByRole('button', { name: '編成 グー N', exact: true }).nth(0).click()
    await page.getByRole('button', { name: '編成 チョキ N', exact: true }).nth(0).click()
    await page.getByRole('button', { name: '編成 パー N', exact: true }).nth(0).click()
    assert.equal((await read()).progress.random_battle.player_deck.length, 0, 'draft is not committed before acceptance')
    await app.evaluate(() => {
      const fs = process.getBuiltinModule('node:fs/promises')
      const rename = fs.rename
      fs.rename = async () => { fs.rename = rename; throw new Error('Injected test save failure') }
    })
    await page.getByRole('button', { name: '3枚で勝負する', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'town.encounter')
    assert.equal((await read()).progress.random_battle.player_deck.length, 0)
    await page.getByRole('button', { name: '3枚で勝負する', exact: true }).click()
    await page.getByTestId('random-deck').waitFor()
    assert.equal(await portrait.getAttribute('data-portrait-phase'), 'battle')
    assert.equal(await page.getByTestId('random-dialogue-start').innerText(), '「さっさと出しな！」')
    const generated = await read()
    assert.deepEqual(generated.progress.random_battle.player_deck.map((card) => card.hand), ['rock', 'scissors', 'paper'])
    await app.close(); app = undefined

    page = await open()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('random-deck').waitFor()
    assert.deepEqual((await read()).progress.random_battle.opponent_deck, generated.progress.random_battle.opponent_deck)
    await page.evaluate(() => { Math.random = () => .3 })
    await page.getByLabel('この勝負で使うアイテム').selectOption('substitute_card')
    await page.getByRole('button', { name: '選択 パー N', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('random-result').waitFor()
    assert.equal((await read()).progress.random_battle.rounds.length, 1)
    assert.equal((await read()).progress.random_battle.opponent_deck[0].hand, 'rock')
    await app.close(); app = undefined

    page = await open()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('random-result').waitFor()
    await page.evaluate(() => { Math.random = () => .3 })
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('random-settlement').waitFor()
    assert.equal(await page.getByTestId('random-opponent-portrait').getAttribute('data-portrait-phase'), 'farewell_win')
    assert.equal(await page.getByTestId('random-dialogue-farewell').innerText(), '「嘘だろ...こんなガキに...」')
    const settled = await read()
    assert.equal(settled.progress.random_battles_completed, 1)
    assert.equal(settled.progress.random_battle.settled, true)
    assert.deepEqual(settled.progress.random_battle.round_item_ids, ['substitute_card'])
    assert.deepEqual(settled.player.items, [])
    assert.equal(settled.player.money, 38)
    assert.equal(settled.player.inventory.length, cards.length + 1)
    await page.getByRole('button', { name: '街の探索を続ける', exact: true }).click()
    await page.getByTestId('town-area').waitFor()
    await page.getByRole('button', { name: 'ギルドホームへ戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'guild.home')
  } finally {
    if (app) await app.close()
    await rm(data, { recursive: true, force: true })
  }
})
