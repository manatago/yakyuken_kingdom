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

test('Stage 2 expression minigame saves each answer, resumes, and advances to the rematch checkpoint', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-stage2-minigame-'))
  const target = join(data, 'janken-save.json')
  const deck = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const original = { save_version: 1, player: { inventory: deck, deck, money: 0 }, progress: {
    checkpoint_id: 'stage2.minigame', flags: ['matilda.tutorial.completed', 'stage2.started', 'stage2_first_battle_completed'],
    tutorial: { battle_id: 'battle.matilda.practice', rounds: [
      { player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }
    ], acknowledged: 2 },
    stage2_minigame: { scene_order: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], current_scene: 0, gauge: 100, picks: [] }
  } }
  let app, page
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [`--user-data-dir=${data}`, join(root, 'dist/game/main/index.js')] })
    page = await app.firstWindow()
    page.on('pageerror', (error) => console.error('Stage 2 renderer pageerror:', error))
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('stage2-minigame').waitFor()
  }
  const failNextSave = async () => {
    await app.evaluate(() => {
      const fs = process.getBuiltinModule('node:fs/promises')
      const rename = fs.rename
      fs.rename = async () => { fs.rename = rename; throw new Error('Injected Stage 2 save failure') }
    })
  }
  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await failNextSave()
    await page.getByRole('button', { name: '顔が赤くなっている', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.deepEqual(await read(), original)
    await page.getByRole('button', { name: '顔が赤くなっている', exact: true }).click()
    await page.getByTestId('stage2-gauge').filter({ hasText: '60/130' }).waitFor()
    assert.equal((await read()).progress.stage2_minigame.current_scene, 1)
    await app.close(); app = undefined
    await open()
    assert.equal(await page.getByTestId('stage2-gauge').innerText(), '60/130')
    await page.getByRole('button', { name: 'ピー助に任せる', exact: true }).click()
    assert.deepEqual((await read()).progress.stage2_minigame.picks, ['blush', 'ask_pisuke'])
    await page.getByRole('button', { name: '手が震えている', exact: true }).click()
    await page.getByTestId('stage2-result').waitFor()
    assert.equal((await read()).progress.stage2_minigame.outcome, 'win')
    await page.getByRole('button', { name: '再戦へ進む', exact: true }).click()
    const saved = await read()
    assert.equal(saved.progress.checkpoint_id, 'stage2.battle2.start')
    assert.ok(saved.progress.flags.includes('stage2_minigame_completed'))
    assert.ok(saved.progress.flags.includes('stage2_first_battle_done'))
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
