import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'
import { _electron as electron } from 'playwright-core'
import { originalDocument, advanceOriginalDialogue } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const battleDocument = JSON.parse(await readFile(join(root, 'content/stories/godot-prologue-battle.json'), 'utf8'))

test('new game reads every original opening/tutorial line, prepares, plays twice and resumes into the original normal battle', { timeout: 360_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-matilda-journey-'))
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`]
  let app, page
  const open = async button => {
    app = await electron.launch({ executablePath, args })
    page = await app.firstWindow()
    await page.addInitScript(() => { Math.random = () => 0 })
    await page.evaluate(() => { Math.random = () => 0 })
    await page.getByRole('button', { name: button, exact: true }).click()
  }
  const read = () => page.evaluate(() => globalThis.janken.save.read())
  const restartTutorial = async state => {
    const before = await read()
    await app.close(); app = undefined
    await open('つづきから')
    await page.getByTestId('original-tutorial-cursor').filter({ hasText: `${state.playback.cursor}:${state.phase}` }).waitFor()
    assert.deepEqual(await read(), before)
    if (state.phase === 'dialogue') {
      await page.waitForFunction(text => document.querySelector('[data-testid="original-tutorial-dialogue"]')?.textContent?.endsWith(text), state.text)
    }
  }
  try {
    await open('はじめから')
    const sequence = originalDocument.sequences.find(entry => entry.id === 'prologue')
    const tutorialIndex = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.is_tutorial)
    assert.equal(tutorialIndex, 197)
    const initial = await read()
    assert.equal(initial.player.inventory.length, 9)
    assert.ok(initial.player.inventory.every(card => card.grade === 1))
    assert.equal(initial.player.money, 0)
    for (const [index, command] of sequence.commands.slice(0, tutorialIndex).entries()) {
      if (['band', 'line'].includes(command.kind) && command.parameters.wait_for_input) {
        await advanceOriginalDialogue(page, 'prologue', index + 1)
      }
    }
    const seenDialogue = []
    const resumedRounds = new Set()
    let sawDeck = false, completed = false, sawGrades = false
    for (let iteration = 0; iteration < 180; iteration++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running')
      })
      const saved = await read(), state = saved.progress.original_tutorial
      assert.ok(state)
      assert.deepEqual(saved.player.inventory, initial.player.inventory)
      assert.equal(saved.player.money, 0)
      const before = `${state.playback.cursor}:${state.phase}`
      if (state.phase === 'dialogue') {
        const trace = battleDocument.traces.find(trace => trace.method === 'tutorial' &&
          state.playback.results.every((result, index) => trace.outcomes[index] === result))
        const command = trace.commands[state.playback.cursor - 1]
        assert.equal(command.kind, 'band')
        assert.equal(state.text, command.args[1])
        seenDialogue.push(state.playback.cursor - 1)
        await page.waitForFunction(text => document.querySelector('[data-testid="original-tutorial-dialogue"]')?.textContent?.endsWith(text), state.text)
        if (state.text.includes('Nはノーマル')) {
          sawGrades = true
          await restartTutorial(state)
        }
        await advanceStory(page)
      } else if (state.phase === 'deck') {
        sawDeck = true
        assert.equal(await page.getByRole('button', { name: '準備完了', exact: true }).isDisabled(), true)
        await restartTutorial(state)
        await page.getByRole('button', { name: '手持ち rock N', exact: true }).click()
        await page.getByRole('button', { name: 'デッキ 1 rock', exact: true }).click()
        assert.equal(await page.getByRole('button', { name: 'デッキ 1 rock', exact: true }).count(), 0)
        await page.getByRole('button', { name: '自動', exact: true }).click()
        await page.getByRole('button', { name: '準備完了', exact: true }).click()
      } else if (state.phase === 'selection') {
        assert.equal(await page.getByRole('button', { name: '勝負！', exact: true }).isDisabled(), true)
        const index = state.battle.playerDeck.findIndex((card, index) => card.hand === 'paper' && !state.battle.playerUsed[index])
        assert.ok(index >= 0)
        await page.getByRole('button', { name: `デッキ ${index + 1} paper`, exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
      } else if (state.phase === 'result') {
        const round = state.battle.rounds.at(-1)
        assert.equal(round.result, 'win')
        assert.equal(round.opponent.hand, 'rock')
        assert.equal(state.battle.opponentHp, 3 - state.battle.rounds.length)
        await restartTutorial(state)
        resumedRounds.add(state.battle.rounds.length)
        await finishOriginalShowdown(page)
      } else if (state.phase === 'reward') {
        assert.equal(state.battle.rounds.length, 2)
        assert.equal(state.gold, 10)
        const trace = battleDocument.traces.find(trace => trace.method === 'tutorial' && trace.outcomes.every(result => result === 'win'))
        assert.deepEqual(seenDialogue, trace.commands.flatMap((command, index) => command.kind === 'band' ? [index] : []))
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        await page.getByTestId('original-cursor').filter({ hasText: 'prologue:201' }).waitFor()
        const paid = await read()
        assert.equal(paid.player.money, 10)
        assert.deepEqual(paid.player.inventory, initial.player.inventory)
        assert.equal(paid.progress.original_tutorial, undefined)
        for (const [index, command] of sequence.commands.entries()) {
          if (index >= 200 && command.kind !== 'battle' && ['line', 'band'].includes(command.kind) && command.parameters.wait_for_input) {
            await advanceOriginalDialogue(page, 'prologue', index + 1)
          }
        }
        await page.getByRole('button', { name: '準備完了', exact: true }).waitFor()
        const normal = await read()
        assert.equal(normal.progress.checkpoint_id, 'original:prologue:234')
        assert.equal(normal.progress.original_normal.phase, 'deck')
        assert.equal(normal.player.money, 10)
        completed = true; break
      }
      await page.waitForFunction(previous => document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent !== previous, before)
    }
    assert.equal(sawDeck, true); assert.equal(sawGrades, true); assert.equal(completed, true)
    assert.deepEqual([...resumedRounds], [1, 2])
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
})
