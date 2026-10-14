import { advanceBattleDialogue, originalDisplayedBattleText } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalStage1End, finishOriginalShowdown } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const chapters = JSON.parse(await readFile(join(root, 'content/stories/godot-quest-battles.json'), 'utf8')).chapters
const sequences = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8')).sequences

// Full native typing across seven chapters takes about three minutes locally.
test('all seven canonical quest battles draft, play raw lines, resume and settle once', { timeout: 360_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-all-quests-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.addInitScript(() => { Math.random = () => 0 })
    for (const chapter of chapters) {
      // Stop the previous story player before replacing this isolated fixture.
      await page.reload()
      await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
      const sequence = sequences.find(sequence => sequence.commands.some(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path))
      const cursor = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path) + 1
      const checkpoint = `original:${sequence.id}:${cursor}`
      const completed = sequence.commands.slice(0, cursor - 1).flatMap((command, index) => command.kind === 'battle' ? [`original:${sequence.id}:${index + 1}`] : [])
      await page.evaluate(save => globalThis.janken.save.write(save), { save_version: 1,
        player: { money: 0, deck: [], items: [], inventory: Array.from({ length: 9 }, () => ({ hand: 'paper', grade: 5 })) },
        progress: { checkpoint_id: checkpoint, flags: [], original_quest: {
          id: sequence.id.split('_')[0], origin_checkpoint: originalStage1End, route: 'full', completed_battles: completed } } })
      await page.reload()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      try {
        await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
      } catch (cause) {
        console.error('Quest entry diagnostic', chapter.opponent_id, await page.evaluate(async () => ({
          body: document.body.innerText, save: await globalThis.janken.save.read()
        })))
        throw cause
      }
      const read = () => page.evaluate(() => globalThis.janken.save.read())
      assert.equal((await read()).progress.original_quest_battle.chapter_id, chapter.opponent_id)
      await page.getByRole('button', { name: '自動', exact: true }).click()
      await page.waitForFunction(async size => (await globalThis.janken.save.read()).progress.original_quest_battle.draft.length === size, chapter.player_deck_size)
      await page.getByRole('button', { name: '準備完了', exact: true }).click()
      let resumed = false, finished = false
      for (let step = 0; step < 100; step++) {
        await page.waitForFunction(() => {
          const text = document.querySelector('[data-testid="original-quest-battle-cursor"]')?.textContent
          return text && !text.endsWith(':running') && !text.endsWith(':deck')
        })
        const before = await page.getByTestId('original-quest-battle-cursor').textContent()
        const saved = await read(), state = saved.progress.original_quest_battle.runtime
        if (state.phase === 'dialogue') {
          assert.ok(chapter.traces.some(trace => trace.commands.some(command =>
            command.kind === 'band' && command.args[1] === state.text || command.kind === 'bubble' && command.args[0] === state.text)))
          const displayedText = originalDisplayedBattleText(state)
          await advanceBattleDialogue(page, 'original-quest-text', displayedText, 'original-quest-battle-cursor', before)
        } else if (state.phase === 'selection') {
          const index = state.battle.playerUsed.findIndex(used => !used)
          await page.getByRole('button', { name: `デッキ ${index + 1} paper`, exact: true }).click()
          await page.getByRole('button', { name: '勝負！', exact: true }).click()
        } else if (state.phase === 'result') {
          await page.getByTestId('original-showdown').waitFor()
          if (!resumed && chapter.opponent_id === 'jin') {
            await page.waitForFunction(() => document.querySelector('[data-testid="original-showdown"]')?.getAnimations({ subtree: true }).length === 7)
            const snapshot = await page.evaluate(() => {
              const overlay = document.querySelector('[data-testid="original-showdown"]')
              const animations = overlay.getAnimations({ subtree: true })
              const sample = time => {
                animations.forEach(animation => { animation.pause(); animation.currentTime = time })
                const style = track => {
                  const element = overlay.querySelector(`[data-showdown-track="${track}"]`)
                  const computed = getComputedStyle(element)
                  const group = getComputedStyle(overlay.querySelector('[data-showdown-cards]'))
                  return { width: computed.width, height: computed.height, top: `${parseFloat(group.top) + parseFloat(computed.top)}px`,
                    opacity: Number(computed.opacity), matrix: Array.from(new DOMMatrixReadOnly(computed.transform).toFloat64Array()) }
                }
                return { player: style('player-front'), opponent: style('opponent-front'),
                  result: style('result'), opacity: Number(getComputedStyle(overlay).opacity) }
              }
              return { first: sample(4100), second: sample(5100), afterSecond: sample(5101), pop: sample(5400), fade: sample(7050) }
            })
            assert.deepEqual([snapshot.first.player.width, snapshot.first.player.height, snapshot.first.player.top], ['280px', '420px', '250px'])
            assert.equal(snapshot.first.player.matrix[0], 0)
            assert.equal(snapshot.first.player.opacity, 1)
            assert.equal(snapshot.first.opponent.opacity, 0)
            assert.equal(snapshot.second.opponent.matrix[0], 0)
            // At zero width there are no face pixels; normalized WAAPI offsets can round the swap instant.
            assert.equal(snapshot.afterSecond.opponent.opacity, 1)
            assert.ok(Math.abs(snapshot.afterSecond.opponent.matrix[0] - 1 / 300) < 1e-6)
            assert.ok(Math.abs(snapshot.pop.result.matrix[0] - .3) < 1e-6)
            assert.ok(Math.abs(snapshot.fade.opacity - .5) < 1e-6)
            assert.equal(await page.getByTestId('original-showdown').locator('.card-grade').count(), 0)
            assert.ok((await page.getByTestId('original-opponent-hp').textContent()).includes(`HP: ${state.battle.opponentHp + 1}/`))
            assert.deepEqual((await read()).progress.original_quest_battle.runtime, state)
          }
          if (!resumed) {
            await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
            await page.getByRole('button', { name: 'つづきから', exact: true }).click()
            await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':result' }).waitFor()
            assert.deepEqual((await read()).progress.original_quest_battle.runtime, state)
            resumed = true
          }
          await finishOriginalShowdown(page)
        } else if (state.phase === 'finished') {
          assert.equal(state.outcome, 'win')
          await page.getByRole('button', { name: 'OK', exact: true }).click()
          await page.waitForFunction(async () => !(await globalThis.janken.save.read()).progress.original_quest_battle)
          const next = await read()
          assert.deepEqual(next.progress.original_quest.completed_battles, [...completed, checkpoint])
          assert.equal(resumed, true)
          {
            assert.deepEqual(next.player.items, chapter.item_rewards)
            assert.equal(next.player.money, chapter.gold_reward.min)
          }
          finished = true
          break
        } else assert.fail(`Unexpected campaign phase ${state.phase}`)
        await page.waitForFunction(before => document.querySelector('[data-testid="original-quest-battle-cursor"]')?.textContent !== before, before)
      }
      assert.equal(finished, true)
    }
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
