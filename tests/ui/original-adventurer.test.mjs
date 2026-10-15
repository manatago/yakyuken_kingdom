import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('original adventurer tutorial resumes its forced result, captures Rock and returns to the original guild dialogue', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-adventurer-ui-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.addInitScript(() => { Math.random = () => 0 })
    await page.evaluate(async () => globalThis.janken.save.write({ save_version: 1,
      player: { money: 30, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand =>
        Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) }, progress: { checkpoint_id: 'original:stage1:113', flags: [] } }))
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    let resumed = false
    let sawBayes = false
    let finished = false
    const read = () => page.evaluate(() => globalThis.janken.save.read())
    for (let i = 0; i < 80; i++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-adventurer-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running')
      })
      const before = await page.getByTestId('original-adventurer-cursor').textContent()
      const state = (await read()).progress.original_adventurer
      if (state.bayesVisible) {
        await page.getByTestId('original-bayes-eye').filter({ hasText: 'グー 90%' }).waitFor(); sawBayes = true
      }
      if (state.phase === 'dialogue') {
        await advanceStory(page)
        await page.waitForFunction(({ before, text }) => document.querySelector('[data-testid="original-adventurer-cursor"]')?.textContent !== before ||
          document.querySelector('[data-testid="original-adventurer-dialogue"]')?.textContent?.startsWith(text), { before, text: state.text })
        continue
      }
      if (state.phase === 'result') {
        assert.equal(state.battle.rounds[0].player.hand, 'paper'); assert.equal(state.battle.rounds[0].opponent.hand, 'rock')
        await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
        await page.getByRole('button', { name: 'つづきから', exact: true }).click()
        await page.getByTestId('original-adventurer-cursor').filter({ hasText: ':result' }).waitFor()
        assert.deepEqual((await read()).progress.original_adventurer, state); resumed = true
        await finishOriginalShowdown(page)
      } else if (state.phase === 'reward') {
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        await page.getByTestId('original-cursor').filter({ hasText: 'stage1:' }).waitFor()
        const completed = await read()
        assert.equal(completed.player.money, 35); assert.equal(completed.player.inventory.length, 10)
        assert.equal(completed.progress.original_adventurer, undefined)
        finished = true; break
      }
      await page.waitForFunction(before => document.querySelector('[data-testid="original-adventurer-cursor"]')?.textContent !== before, before)
    }
    assert.equal(resumed, true); assert.equal(sawBayes, true); assert.equal(finished, true)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
