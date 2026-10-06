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
const original = { save_version: 1,
  player: { inventory: [...cards, { hand: 'rock', grade: 2 }], deck: cards, money: 30,
    items: ['substitute_card'], equipment: ['greed_ring'] },
  progress: { checkpoint_id: 'matilda.normal.end', flags: ['matilda.tutorial.completed', 'matilda.normal.started',
    'adventurer.tutorial.completed', 'sub1_cleared'], random_battles_completed: 3,
    tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 },
      { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
    fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
      rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
      acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }

async function advanceDialogue(page) {
  const previous = await page.getByTestId('checkpoint-id').textContent()
  await page.getByRole('button', { name: '次へ', exact: true }).click()
  await page.waitForFunction((checkpoint) => {
    const current = document.querySelector('[data-testid="checkpoint-id"]')?.textContent
    const next = [...document.querySelectorAll('button')].find((button) => button.textContent === '次へ')
    return current !== checkpoint && (!next || !next.disabled)
  }, previous)
}

test('Subevent 2 starts from the guild board and resumes at its saved story/battle transition', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-subevent2-'))
  const target = join(data, 'janken-save.json')
  let app
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('checkpoint-id').waitFor()
    return page
  }
  try {
    await writeFile(target, JSON.stringify(original))
    let page = await open()
    await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).click()
    await page.getByTestId('quest-subevent2').getByRole('button', { name: '教会編を開始', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント2：教会の不正調査', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent2.pre.background')
    for (let step = 0; step < 20; step++) {
      const start = page.getByRole('button', { name: 'シスター長戦を開始', exact: true })
      if (await start.count()) break
      await advanceDialogue(page)
    }
    await page.getByRole('button', { name: 'シスター長戦を開始', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent2.battle.start')
    await app.close(); app = undefined
    page = await open()
    await page.getByRole('button', { name: 'シスター長戦を開始', exact: true }).waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent2.battle.start')
    await page.getByRole('button', { name: 'シスター長戦を開始', exact: true }).click()
    await page.getByTestId('fixed-deck').waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.fixed_battle.capture_bonus_enabled, true)
    const itemChoice = page.getByLabel('この勝負で使うアイテム')
    assert.equal(await itemChoice.locator('option').evaluateAll((options) => options.filter((option) => option.value === 'substitute_card').length), 1,
      `battle item options: ${JSON.stringify(await itemChoice.locator('option').evaluateAll((options) => options.map((option) => [option.value, option.textContent])))}; save inventory: ${JSON.stringify(JSON.parse(await readFile(target, 'utf8')).player.items)}`)
    await itemChoice.selectOption('substitute_card')
    assert.equal(await itemChoice.inputValue(), 'substitute_card')
  } finally {
    await app?.close()
    await rm(data, { recursive: true, force: true })
  }
})
