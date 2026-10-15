import { advanceStory, originalDisplayedBattleText } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'
import { readFileSync } from 'node:fs'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const original = JSON.parse(readFileSync(join(root, 'content/stories/godot-original.json'), 'utf8'))

for (const winning of [true, false]) test(`original normal Matilda ${winning ? 'win' : 'loss'} resumes, settles and follows its raw result sequence`, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-normal-ui-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.addInitScript(() => { Math.random = () => 0 })
    await page.evaluate(async () => globalThis.janken.save.write({ save_version: 1,
      player: { money: 20, deck: [], items: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand =>
        Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
      progress: { checkpoint_id: 'original:prologue:234', flags: [] } }))
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    let resumed = false
    let finished = false
    const read = () => page.evaluate(() => globalThis.janken.save.read())
    for (let i = 0; i < 150; i++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-normal-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running')
      })
      const before = await page.getByTestId('original-normal-cursor').textContent()
      const state = (await read()).progress.original_normal
      if (state.phase === 'dialogue') {
        await advanceStory(page)
        await page.waitForFunction(({ before, text }) =>
          document.querySelector('[data-testid="original-normal-cursor"]')?.textContent !== before ||
          document.querySelector('[data-testid="original-normal-text"]')?.textContent === text,
        { before, text: originalDisplayedBattleText(state) })
        continue
      }
      if (state.phase === 'deck') {
        await page.getByRole('button', { name: '自動', exact: true }).click()
        await page.getByRole('button', { name: '準備完了', exact: true }).click()
      } else if (state.phase === 'selection') {
        const hand = winning ? 'paper' : 'scissors'
        const index = state.battle.playerDeck.findIndex((card, index) => card.hand === hand && !state.battle.playerUsed[index])
        await page.getByRole('button', { name: `デッキ ${index + 1} ${hand}`, exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
      } else if (state.phase === 'result') {
        if (!resumed) {
          await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
          await page.getByRole('button', { name: 'つづきから', exact: true }).click()
          await page.getByTestId('original-normal-cursor').filter({ hasText: ':result' }).waitFor()
          assert.deepEqual((await read()).progress.original_normal, state)
          resumed = true
        }
        await finishOriginalShowdown(page)
      } else if (state.phase === 'finished') {
        assert.equal(state.outcome, winning ? 'win' : 'lose')
        assert.equal(state.battle.rounds.length, 3)
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        const sequence = winning ? 'prologue_battle_win' : 'prologue_battle_lose'
        const action = winning ? '次の章へ' : '再挑戦する'
        await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:` }).waitFor()
        const completed = await read()
        assert.equal(completed.player.money, winning ? 30 : 10)
        assert.equal(completed.player.inventory.length, 9)
        assert.equal(completed.progress.original_normal, undefined)
        const victory = original.sequences.find(entry => entry.id === sequence)
        for (const [index, command] of victory.commands.entries()) {
          if (!['band', 'line'].includes(command.kind) || !command.parameters.wait_for_input) continue
          const cursor = index + 1
          await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:${cursor}` }).waitFor()
          await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
            command.parameters.text)
          assert.equal((await read()).progress.checkpoint_id, `original:${sequence}:${cursor}`)
          await advanceStory(page)
          await page.waitForFunction(({ cursor, sequence, action }) => document.querySelector('[data-testid="original-cursor"]')?.textContent !== `${sequence}:${cursor}` ||
            [...document.querySelectorAll('button')].some(button => button.textContent === action), { cursor, sequence, action }).catch(async cause => {
              console.error('Matilda aftermath diagnostic', { cursor, sequence, action,
                text: await page.locator('body').innerText(), save: await read() })
              throw cause
            })
        }
        await page.getByRole('button', { name: action, exact: true }).waitFor()
        if (!winning) assert.equal(await page.getByRole('button', { name: 'ホームに戻る', exact: true }).count(), 1)
        await page.getByRole('button', { name: action, exact: true }).click()
        if (winning) await page.getByTestId('original-cursor').filter({ hasText: 'stage1:' }).waitFor()
        else {
          await page.getByTestId('original-normal-cursor').filter({ hasText: ':deck' }).waitFor()
          assert.equal((await read()).player.money, 10)
          assert.equal((await read()).progress.original_normal.battle.rounds.length, 0)
        }
        finished = true; break
      }
      await page.waitForFunction(before => document.querySelector('[data-testid="original-normal-cursor"]')?.textContent !== before, before)
    }
    assert.equal(resumed, true); assert.equal(finished, true)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
