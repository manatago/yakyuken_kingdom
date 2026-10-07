import assert from 'node:assert/strict'
import { mkdtemp, readFile, writeFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('equipment can be equipped and removed from Guild Home and persists after reload', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-equipment-'))
  const target = join(data, 'janken-save.json')
  const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const save = { save_version: 1, player: { inventory: cards, deck: cards, money: 20,
    items: ['greed_ring', 'gold_charm', 'paper_seal_white'] },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.normal.end',
      flags: ['matilda.tutorial.completed', 'matilda.normal.started'],
      tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
      fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
        rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
        acknowledged: 3, settled: true, balance_before: 10, gold_delta: 10 } } }
  let app
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('guild-frame').waitFor()
    return page
  }
  try {
    await writeFile(target, JSON.stringify(save))
    let page = await open()
    await page.getByRole('button', { name: '装備 強欲の指輪', exact: true }).click()
    await page.getByRole('button', { name: '外す 強欲の指輪', exact: true }).waitFor()
    assert.deepEqual((await read()).player.items, ['gold_charm', 'paper_seal_white'])
    assert.deepEqual((await read()).player.equipment, ['greed_ring'])
    await app.close(); app = undefined
    page = await open()
    await page.getByRole('button', { name: '外す 強欲の指輪', exact: true }).click()
    await page.getByText('装備中のアイテムはありません。', { exact: true }).waitFor()
    assert.deepEqual((await read()).player.items, ['gold_charm', 'paper_seal_white', 'greed_ring'])
    assert.deepEqual((await read()).player.equipment, [])
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
