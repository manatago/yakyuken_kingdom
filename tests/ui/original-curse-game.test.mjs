import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalStage1End } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('raw Subevent 3 minigame plays original dialogue, resumes and continues without changing owned cards', { timeout: 120_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-curse-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const player = { money: 75, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({length: 3}, () => ({hand, grade: 1}))) }
    await page.evaluate(async save => globalThis.janken.save.write(save), { save_version: 1, player,
      progress: { checkpoint_id: 'original:subevent3_visit:71', flags: [],
        original_quest: { id: 'subevent3', route: 'full', origin_checkpoint: originalStage1End } } })
    const savedPlayer = await page.evaluate(async () => (await globalThis.janken.save.read()).player)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-curse-cursor').waitFor()
    await page.waitForFunction(async () => !!(await globalThis.janken.save.read()).progress.original_curse_game)
    let resumed = false
    let finished = false
    for (let steps = 0; steps < 200; steps++) {
      await page.waitForFunction(async () => !!document.querySelector('[data-testid="original-curse-cursor"]') || !(await globalThis.janken.save.read()).progress.original_curse_game)
      const save = await page.evaluate(() => globalThis.janken.save.read())
      const ledger = save.progress.original_curse_game
      if (!ledger) { finished = true; break }
      const command = ledger.game.commands[ledger.cursor]
      if (command && ['narrator_band', 'dialogue_band'].includes(command.kind) && ledger.game.outcome && ledger.cursor >= ledger.game.commands.length - 1) {
        await page.waitForFunction(previous => !document.querySelector('[data-testid="original-curse-cursor"]') || document.querySelector('[data-testid="original-curse-cursor"]')?.textContent === previous,
          `${ledger.game.actions.length}:${ledger.cursor}`)
        assert.equal(await page.getByTestId('original-curse-gauge').count(), 0)
        assert.equal(await page.getByRole('button', { name: '続ける', exact: true }).count(), 0)
      }
      if (command?.kind === 'narrator_band') {
        await page.waitForFunction(text => document.querySelector('[data-testid="original-curse-text"]')?.textContent === text, String(command.args[0]))
        await advanceStory(page)
        await page.waitForFunction(previous => document.querySelector('[data-testid="original-curse-cursor"]')?.textContent !== previous,
          `${ledger.game.actions.length}:${ledger.cursor}`)
      } else if (command) {
        await page.waitForFunction(previous => document.querySelector('[data-testid="original-curse-cursor"]')?.textContent !== previous,
          `${ledger.game.actions.length}:${ledger.cursor}`)
      } else if (!ledger.game.outcome) {
        const expectedGauge = [110, 60, 10][ledger.game.actions.length]
        assert.equal(ledger.game.gauge, expectedGauge)
        if (ledger.game.actions.length === 1 && !resumed) {
          await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
          await page.getByRole('button', { name: 'つづきから', exact: true }).click()
          await page.getByRole('button', { name: '[5] ピー助に任せる', exact: true }).waitFor()
          assert.deepEqual((await page.evaluate(() => globalThis.janken.save.read())).progress.original_curse_game, ledger)
          resumed = true
        }
        await page.getByRole('button', { name: '[5] ピー助に任せる', exact: true }).click()
        await page.waitForFunction(count => document.querySelector('[data-testid="original-curse-cursor"]')?.textContent?.startsWith(`${count + 1}:`), ledger.game.actions.length)
      } else {
        assert.equal(ledger.game.outcome, 'win')
        assert.equal(ledger.game.pisukeUsed.length, 3)
        await page.getByTestId('original-text').filter({hasText: '水晶球の光が強まっていく。'}).waitFor()
        const result = await page.evaluate(() => globalThis.janken.save.read())
        assert.deepEqual(result.player, savedPlayer)
        assert.equal(result.progress.original_curse_game, undefined)
        assert.deepEqual(result.progress.original_quest.completed_battles, ['original:subevent3_visit:71'])
        finished = true; break
      }
    }
    const completed = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(completed.progress.original_curse_game, undefined)
    assert.deepEqual(completed.player, savedPlayer)
    assert.deepEqual(completed.progress.original_quest.completed_battles, ['original:subevent3_visit:71'])
    assert.equal(resumed, true)
    assert.equal(finished, true)
    await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].every(image => image.complete && image.naturalWidth > 0))
  } finally {
    await app.close(); await rm(userData, {recursive: true, force: true})
  }
})
