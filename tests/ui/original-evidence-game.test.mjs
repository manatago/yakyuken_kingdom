import { advanceStory } from './story-input.mjs'
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
const source = require('../../content/stories/godot-stage3-minigame.json')

test('raw Stage 3 evidence minigame retains original text, first-turn lock and resume state', { timeout: 120_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-evidence-'))
  const app = await electron.launch({ executablePath: require('electron'), args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const player = { money: 75, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) }
    await page.evaluate(async save => globalThis.janken.save.write(save), { save_version: 1, player,
      progress: { checkpoint_id: 'original:stage3_recover:56', flags: [] } })
    const baseline = (await page.evaluate(() => globalThis.janken.save.read())).player
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-evidence-cursor').waitFor()
    await page.waitForFunction(async () => !!(await globalThis.janken.save.read()).progress.original_evidence_game)
    let resumed = false; let finished = false
    for (let steps = 0; steps < 200; steps++) {
      await page.waitForFunction(async () => !!document.querySelector('[data-testid="original-evidence-cursor"]') || !(await globalThis.janken.save.read()).progress.original_evidence_game)
      const save = await page.evaluate(() => globalThis.janken.save.read())
      const ledger = save.progress.original_evidence_game
      if (!ledger) { finished = true; break }
      const command = ledger.game.commands[ledger.cursor]
      if (command && ['narrator_band', 'dialogue_band'].includes(command.kind) && ledger.game.outcome && ledger.cursor >= ledger.game.commands.length - 4) {
        await page.waitForFunction(previous => !document.querySelector('[data-testid="original-evidence-cursor"]') || document.querySelector('[data-testid="original-evidence-cursor"]')?.textContent === previous,
          `${ledger.game.actions.length}:${ledger.cursor}`)
        assert.equal(await page.getByTestId('original-evidence-gauge').count(), 0)
        assert.equal(await page.getByRole('button', { name: '続ける', exact: true }).count(), 0)
      }
      const previous = `${ledger.game.actions.length}:${ledger.cursor}`
      if (command && ['narrator_band', 'dialogue_band'].includes(command.kind)) {
        const text = String(command.args[command.kind === 'narrator_band' ? 0 : 1])
        await page.waitForFunction(previous => document.querySelector('[data-testid="original-evidence-cursor"]')?.textContent === previous, previous)
        const display = page.getByTestId('original-evidence-text')
        if (await display.textContent() !== text) await advanceStory(page)
        await page.waitForFunction(text => document.querySelector('[data-testid="original-evidence-text"]')?.textContent === text, text)
        await advanceStory(page)
      } else if (!command && !ledger.game.outcome) {
        const bounds = await page.locator('[data-testid^="original-evidence-book-"], [data-testid^="original-evidence-proof-"]').evaluateAll(buttons => {
          const decide = [...document.querySelectorAll('button')].find(button => button.textContent === '[決定] この組み合わせで攻撃').getBoundingClientRect()
          return buttons.map(button => ({ id: button.dataset.testid, bottom: button.getBoundingClientRect().bottom,
            limit: decide.top, font: getComputedStyle(button).fontSize }))
        })
        for (const button of bounds) {
          assert.ok(button.bottom <= button.limit, `${button.id} overlaps the decision row`)
          assert.equal(button.font, '20px')
        }
        assert.equal(ledger.game.gauge, [100, 60, 20][ledger.game.actions.length])
        if (ledger.game.actions.length === 0) {
          assert.equal(await page.getByRole('button', { name: '[ピー助に任せる]（残り 1 ターン）', exact: true }).isDisabled(), true)
          const combo = source.valid_combos.find(combo => ledger.game.chapters.includes(combo.chapter) && ledger.game.evidences.includes(combo.evidence))
          assert.ok(combo)
          assert.equal(await page.getByRole('button', { name: '[決定] この組み合わせで攻撃', exact: true }).isDisabled(), true)
          await page.getByTestId(`original-evidence-book-${combo.chapter}`).click()
          await page.getByTestId(`original-evidence-proof-${combo.evidence}`).click()
          await page.getByRole('button', { name: '[決定] この組み合わせで攻撃', exact: true }).click()
        } else {
          if (!resumed) {
            await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
            await page.getByRole('button', { name: 'つづきから', exact: true }).click()
            await page.getByRole('button', { name: '[ピー助に任せる]', exact: true }).waitFor()
            assert.deepEqual((await page.evaluate(() => globalThis.janken.save.read())).progress.original_evidence_game, ledger)
            resumed = true
          }
          await page.getByRole('button', { name: '[ピー助に任せる]', exact: true }).click()
        }
      } else if (!command) {
        assert.equal(ledger.game.outcome, 'win')
        await page.waitForFunction(async () => !(await globalThis.janken.save.read()).progress.original_evidence_game)
        const result = await page.evaluate(() => globalThis.janken.save.read())
        assert.deepEqual(result.player, baseline)
        assert.deepEqual(result.progress.original_completed_minigames, ['original:stage3_recover:56'])
        finished = true; break
      }
      await page.waitForFunction(previous => document.querySelector('[data-testid="original-evidence-cursor"]')?.textContent !== previous, previous)
    }
    const completed = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(completed.progress.original_evidence_game, undefined)
    assert.deepEqual(completed.player, baseline)
    assert.deepEqual(completed.progress.original_completed_minigames, ['original:stage3_recover:56'])
    assert.equal(resumed, true); assert.equal(finished, true)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
