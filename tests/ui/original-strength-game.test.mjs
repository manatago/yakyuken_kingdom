import { advanceBattleDialogue, waitForStoryProgress } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const require = createRequire(import.meta.url)

test('raw Stage 4 strength minigame retains original text, immediate support and resume state', { timeout: 120_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-strength-'))
  const app = await electron.launch({ executablePath: require('electron'), args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const player = { money: 75, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) }
    await page.evaluate(async save => globalThis.janken.save.write(save), { save_version: 1, player,
      progress: { checkpoint_id: 'original:stage4_recover:18', flags: [] } })
    const baseline = (await page.evaluate(() => globalThis.janken.save.read())).player
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-strength-cursor').waitFor()
    await page.waitForFunction(async () => !!(await globalThis.janken.save.read()).progress.original_strength_game)
    let resumed = false; let finished = false
    for (let steps = 0; steps < 200; steps++) {
      await page.waitForFunction(async () => !!document.querySelector('[data-testid="original-strength-cursor"]') || !(await globalThis.janken.save.read()).progress.original_strength_game)
      const save = await page.evaluate(() => globalThis.janken.save.read())
      const ledger = save.progress.original_strength_game
      if (!ledger) { finished = true; break }
      const command = ledger.game.commands[ledger.cursor]
      if (command && ['narrator_band', 'dialogue_band'].includes(command.kind) && ledger.game.outcome && ledger.cursor >= ledger.game.commands.length - 4) {
        await page.waitForFunction(previous => !document.querySelector('[data-testid="original-strength-cursor"]') || document.querySelector('[data-testid="original-strength-cursor"]')?.textContent === previous,
          `${ledger.game.actions.length}:${ledger.cursor}`)
        assert.equal(await page.getByTestId('original-strength-gauge').count(), 0)
        assert.equal(await page.getByRole('button', { name: '続ける', exact: true }).count(), 0)
      }
      const previous = `${ledger.game.actions.length}:${ledger.cursor}`
      if (command && ['narrator_band', 'dialogue_band'].includes(command.kind)) {
        const text = String(command.args[command.kind === 'narrator_band' ? 0 : 1])
        await page.waitForFunction(previous => document.querySelector('[data-testid="original-strength-cursor"]')?.textContent === previous, previous)
        await advanceBattleDialogue(page, 'original-strength-text', text, 'original-strength-cursor', previous)
      } else if (!command && !ledger.game.outcome) {
        assert.equal(ledger.game.gauge, [110, 70, 30][ledger.game.actions.length])
        assert.equal(await page.getByTestId('original-strength-support').isDisabled(), false)
        if (ledger.game.actions.length === 1 && !resumed) {
          await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
          await page.getByRole('button', { name: 'つづきから', exact: true }).click()
          await page.getByTestId('original-strength-support').waitFor()
          assert.deepEqual((await page.evaluate(() => globalThis.janken.save.read())).progress.original_strength_game, ledger)
          resumed = true
        }
        await page.getByTestId('original-strength-support').click()
      } else if (!command) {
        assert.equal(ledger.game.outcome, 'win')
        await page.waitForFunction(async () => !(await globalThis.janken.save.read()).progress.original_strength_game)
        const result = await page.evaluate(() => globalThis.janken.save.read())
        assert.deepEqual(result.player, baseline)
        assert.deepEqual(result.progress.original_completed_minigames, ['original:stage4_recover:18'])
        finished = true; break
      }
      await waitForStoryProgress(page, 'original-strength-cursor', previous)
    }
    const completed = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(completed.progress.original_strength_game, undefined)
    assert.deepEqual(completed.player, baseline)
    assert.deepEqual(completed.progress.original_completed_minigames, ['original:stage4_recover:18'])
    assert.equal(resumed, true); assert.equal(finished, true)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
