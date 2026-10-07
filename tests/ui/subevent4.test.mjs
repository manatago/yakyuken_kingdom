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
  player: { inventory: cards, deck: cards, money: 30 },
  progress: { checkpoint_id: 'matilda.normal.end', flags: ['matilda.tutorial.completed', 'matilda.normal.started',
    'adventurer.tutorial.completed', 'sub1_cleared', 'sub2_cleared', 'sub3_cleared'], random_battles_completed: 3,
    tutorial: { battle_id: 'battle.matilda.practice', rounds: [{ player_index: 6, opponent_index: 0 },
      { player_index: 0, opponent_index: 3 }], acknowledged: 2 },
    fixed_battle: { battle_id: 'battle.matilda.normal', player_deck: cards,
      rounds: [6, 7, 8].map((player_index, opponent_index) => ({ player_index, opponent_index })),
      acknowledged: 3, settled: true, balance_before: 20, gold_delta: 10 } } }

async function waitForCheckpoint(page, expected) {
  await page.waitForFunction((checkpoint) =>
    document.querySelector('[data-testid="checkpoint-id"]')?.textContent === checkpoint, expected)
}

async function advanceTo(page, target) {
  for (let attempt = 0; attempt < 20; attempt++) {
    const current = await page.getByTestId('checkpoint-id').textContent()
    if (current === target) return
    const advance = page.getByRole('button', { name: '次へ', exact: true })
    await advance.click()
    await page.waitForFunction((previous) =>
      document.querySelector('[data-testid="checkpoint-id"]')?.textContent !== previous, current)
  }
  throw new Error(`Story did not reach ${target}: ${await page.getByTestId('checkpoint-id').textContent()}`)
}

test('Subevent 4 persists its story, battle, rewards and Guild completion', { timeout: 120_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-subevent4-'))
  const target = join(data, 'janken-save.json')
  let app, page
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('checkpoint-id').waitFor()
  }

  try {
    await writeFile(target, JSON.stringify(original))
    await open()
    await page.getByRole('button', { name: 'ギルドホームを確認', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()
    await page.getByTestId('quest-subevent4').getByRole('button', { name: '審査を開始', exact: true }).click()
    await page.getByRole('heading', { name: 'サブイベント4：公開審査', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'subevent4.pre.background')
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await waitForCheckpoint(page, 'subevent4.pre.hero')
    await app.close(); app = undefined

    await open()
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), 'subevent4.pre.hero')
    await advanceTo(page, 'subevent4.pre.end')
    await page.getByRole('button', { name: 'カード勝負へ進む', exact: true }).click()
    await page.getByRole('button', { name: '受付嬢との審査戦を開始', exact: true }).waitFor()
    assert.equal((await read()).progress.checkpoint_id, 'subevent4.battle.start')
    await page.getByRole('button', { name: '受付嬢との審査戦を開始', exact: true }).click()
    await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
    await page.evaluate(() => { Math.random = () => 0 })

    for (let round = 0; round < 3; round++) {
      await page.locator('[aria-label="選択 パー N"]:not(:disabled)').first().click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByTestId('fixed-result').waitFor()
      if (round < 2) {
        await page.getByRole('button', { name: '次の勝負へ', exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).waitFor()
      }
    }
    await page.getByRole('button', { name: '結果を確定', exact: true }).click()
    await page.getByTestId('fixed-settled').waitFor()
    assert.match(await page.getByTestId('fixed-settled').innerText(), /対戦に勝利/)
    assert.equal((await read()).progress.fixed_battle.item_rewards.length, 2)
    await page.getByRole('button', { name: '会話に戻る', exact: true }).click()
    await waitForCheckpoint(page, 'subevent4.post.result')
    await advanceTo(page, 'subevent4.post.end')
    await page.getByRole('button', { name: '審査結果を確定してギルドへ戻る', exact: true }).click()
    await page.getByRole('heading', { name: 'ギルドホーム', exact: true }).waitFor()

    const completed = await read()
    assert.equal(completed.progress.checkpoint_id, 'guild.home')
    assert.ok(completed.progress.flags.includes('sub4_cleared'))
    assert.ok(completed.player.items.includes('rare_find_pendant'))
    assert.ok(completed.player.items.includes('rank_up_talisman'))
    assert.ok(completed.player.money > original.player.money)
    assert.equal(await page.getByTestId('quest-subevent4').getAttribute('data-unlocked'), 'true')
  } finally {
    try { if (app) await app.close() }
    finally { await rm(data, { recursive: true, force: true }) }
  }
})
