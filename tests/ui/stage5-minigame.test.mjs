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
const cards = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
const original = { save_version: 1, player: { inventory: cards, deck: cards, money: 0 }, progress: {
  checkpoint_id: 'stage5.minigame', flags: ['matilda.tutorial.completed', 'stage5.started'],
  tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 },
    { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
  stage5_minigame: { gauge: 100, hits: 0, misses: 0, rounds: [] }
} }

test('Stage 5 record review saves, resumes, and opens the rematch story', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-stage5-record-review-'))
  const target = join(data, 'janken-save.json')
  let app, page
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('stage5-minigame').waitFor()
  }
  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await page.getByRole('button', { name: '珠の反応記録と質問記録を照合する', exact: true }).click()
    assert.equal((await read()).progress.stage5_minigame.hits, 1)
    await app.close(); app = undefined
    await open()
    assert.equal(await page.getByTestId('stage5-gauge').innerText(), '60/130')
    await page.getByRole('button', { name: 'ピー助に記録を照合してもらう', exact: true }).click()
    await page.getByRole('button', { name: '珠の反応記録と質問記録を照合する', exact: true }).click()
    await page.getByTestId('stage5-result').waitFor()
    await page.getByRole('button', { name: '再審へ進む', exact: true }).click()
    const saved = await read()
    assert.equal(saved.progress.checkpoint_id, 'stage5.rematch.background')
    assert.ok(saved.progress.flags.includes('stage5_minigame_completed'))
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
