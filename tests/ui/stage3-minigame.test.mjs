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
  checkpoint_id: 'stage3.minigame', flags: ['matilda.tutorial.completed', 'stage3.started'],
  tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 },
    { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
  stage3_minigame: { gauge: 100, hits: 0, rounds: [], offer: {
    chapters: ['history', 'intake', 'doctrine', 'charity'], evidence: ['minutes', 'access', 'letter', 'inventory'],
    target_chapter: 'intake', target_evidence: 'minutes'
  } }
} }

test('Stage 3 evidence review saves each selection, resumes, and continues to its rematch', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-stage3-minigame-'))
  const target = join(data, 'janken-save.json')
  let app, page
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('stage3-review').waitFor()
  }
  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await page.getByRole('button', { name: 'ピー助に任せる', exact: true }).click()
    assert.equal((await read()).progress.stage3_minigame.gauge, 60)
    assert.equal((await read()).progress.stage3_minigame.rounds[0].hit, true)
    await app.close(); app = undefined
    await open()
    assert.equal(await page.getByTestId('stage3-gauge').innerText(), '60/130')
    await page.getByRole('button', { name: 'ピー助に任せる', exact: true }).click()
    await page.getByRole('button', { name: 'ピー助に任せる', exact: true }).click()
    await page.getByTestId('stage3-result').waitFor()
    await page.getByRole('button', { name: '再審査へ進む', exact: true }).click()
    const saved = await read()
    assert.equal(saved.progress.checkpoint_id, 'stage3.rematch.background')
    assert.ok(saved.progress.flags.includes('stage3_minigame_completed'))
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
