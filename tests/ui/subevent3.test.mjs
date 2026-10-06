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
  player: { inventory: [...cards, { hand: 'rock', grade: 2 }], deck: cards, money: 30 },
  progress: { checkpoint_id: 'matilda.normal.end', flags: ['matilda.tutorial.completed', 'matilda.normal.started',
    'adventurer.tutorial.completed', 'sub1_cleared', 'sub2_cleared'], random_battles_completed: 3,
    tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 },
      { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
    fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
      rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
      acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }

async function advanceDialogue(page) {
  const previous = await page.getByTestId('checkpoint-id').textContent()
  const nextButton = page.getByRole('button', { name: '次へ', exact: true })
  if (await nextButton.count()) await nextButton.click()
  else {
    const end = page.getByRole('button', { name: '次の場面へ', exact: true })
    if (!await end.count()) throw new Error(`No dialogue advance button at ${previous}: ${await page.locator('body').innerText()}`)
    await end.click()
  }
  await page.waitForFunction((checkpoint) => {
    const current = document.querySelector('[data-testid="checkpoint-id"]')?.textContent
    const action = document.querySelector('.story-dialogue button:not(:disabled)')
    return current !== checkpoint && !!action
  }, previous)
}

test('Subevent 3 persists the story handoff and resumes the minigame at the exact saved gauge', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-subevent3-'))
  const target = join(data, 'janken-save.json')
  let app
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.waitForFunction(() => document.querySelector('[data-testid="checkpoint-id"]') ||
      document.querySelector('[data-testid="subevent3-minigame"]'))
    return page
  }
  try {
    await writeFile(target, JSON.stringify(original))
    let page = await open()
    await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).click()
    await page.getByTestId('quest-subevent3').getByRole('button', { name: 'フィオナ編を開始', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント3：呪われた鎧', exact: true }).waitFor()
    for (let step = 0; step < 40; step++) {
      if (await page.getByTestId('subevent3-minigame').count()) break
      const investigate = page.getByRole('button', { name: '水晶で呪いを調べる', exact: true })
      if (await investigate.count()) {
        const previous = await page.getByTestId('checkpoint-id').textContent()
        await page.waitForFunction(() => [...document.querySelectorAll('.story-dialogue button')]
          .some((button) => button.textContent === '水晶で呪いを調べる' && !button.disabled))
        await investigate.click()
        await page.waitForFunction((checkpoint) => document.querySelector('[data-testid="checkpoint-id"]')?.textContent !== checkpoint,
          previous)
        continue
      }
      await advanceDialogue(page)
    }
    await page.getByTestId('subevent3-minigame').waitFor()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.checkpoint_id, 'subevent3.minigame')
    const firstChoice = page.getByRole('button', { name: 'ピー助に任せる', exact: true })
    await firstChoice.waitFor()
    await firstChoice.click()
    assert.equal(JSON.parse(await readFile(target, 'utf8')).progress.subevent3_minigame.gauge, 60)
    await app.close(); app = undefined
    page = await open()
    await page.getByTestId('subevent3-minigame').waitFor()
    assert.equal(await page.getByTestId('subevent3-gauge').innerText(), '60/130')
    assert.deepEqual(JSON.parse(await readFile(target, 'utf8')).progress.subevent3_minigame.rounds[0].selected, 'pisuke')
  } finally {
    await app?.close()
    await rm(data, { recursive: true, force: true })
  }
})
