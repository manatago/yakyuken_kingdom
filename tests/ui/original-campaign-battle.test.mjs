import { advanceStory, originalDisplayedBattleText } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const chapters = JSON.parse(await readFile(join(root, 'content/stories/godot-campaign-battles.json'), 'utf8')).chapters
const sequences = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8')).sequences

test('all ten canonical campaign variants draft, play raw lines, resume and settle once', { timeout: 180_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-campaign-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.addInitScript(() => { Math.random = () => 0 })
    let verifiedEntrance = false
    for (const chapter of chapters) {
      // No prior story callback may write over the next isolated fixture.
      await page.reload()
      await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
      const sequence = sequences.find(sequence => sequence.commands.some(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path))
      const cursor = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path) + 1
      const checkpoint = `original:${sequence.id}:${cursor}`
      await page.evaluate(save => globalThis.janken.save.write(save), { save_version: 1,
        player: { money: 0, deck: [], items: [], inventory: Array.from({ length: 9 }, () => ({ hand: 'rock', grade: chapter.first_battle ? 1 : 5 })) },
        progress: { checkpoint_id: checkpoint, flags: chapter.first_battle ? [] : [chapter.flag_key] } })
      await page.reload()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
      const read = () => page.evaluate(() => globalThis.janken.save.read())
      assert.equal((await read()).progress.original_quest_battle.chapter_id, `campaign:${chapter.opponent_id}:${chapter.first_battle ? 'initial' : 'rematch'}`)
      await page.getByRole('button', { name: '自動', exact: true }).click()
      await page.waitForFunction(async () => (await globalThis.janken.save.read()).progress.original_quest_battle.draft.length === 9)
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
          assert.ok(chapter.traces.some(trace => trace.commands.some(command => command.kind === 'band' && command.args[1] === state.text)))
          if (!verifiedEntrance && state.portraitOptions.appear_effect === 'fade_slide') {
            const image = page.getByTestId(`original-portrait-${chapter.opponent_id}`)
            await image.waitFor()
            const motion = await image.evaluate(image => {
              const animation = image.parentElement.getAnimations().find(animation => animation.effect.getKeyframes().length === 61)
              return animation ? { duration: animation.effect.getTiming().duration, frames: animation.effect.getKeyframes() } : null
            })
            assert.ok(motion, 'Original battle entrance must reach the actual portrait animation')
            assert.equal(motion.duration, state.portraitOptions.appear_duration * 1000)
            assert.equal(motion.frames[0].opacity, '0')
            const translation = frame => { const values = frame.translate.split(' ').map(parseFloat); return [values[0], values[1] ?? 0] }
            assert.deepEqual(translation(motion.frames[0]), [200, 0])
            assert.equal(motion.frames.at(-1).opacity, '1')
            assert.deepEqual(translation(motion.frames.at(-1)), [0, 0])
            verifiedEntrance = true
          }
          const displayedText = originalDisplayedBattleText(state)
          if (await page.getByTestId('original-quest-text').textContent() !== displayedText) await advanceStory(page)
          await page.waitForFunction(text => document.querySelector('[data-testid="original-quest-text"]')?.textContent === text, displayedText)
          await advanceStory(page)
        } else if (state.phase === 'selection') {
          const index = state.battle.playerUsed.findIndex(used => !used)
          await page.getByRole('button', { name: `デッキ ${index + 1} rock`, exact: true }).click()
          await page.getByRole('button', { name: '勝負！', exact: true }).click()
        } else if (state.phase === 'result') {
          if (!resumed) {
            await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
            await page.getByRole('button', { name: 'つづきから', exact: true }).click()
            await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':result' }).waitFor()
            assert.deepEqual((await read()).progress.original_quest_battle.runtime, state)
            resumed = true
          }
          await finishOriginalShowdown(page)
        } else if (state.phase === 'finished') {
          assert.equal(state.outcome, chapter.first_battle ? 'lose' : 'win')
          await page.getByRole('button', { name: 'OK', exact: true }).click()
          await page.waitForFunction(async () => !(await globalThis.janken.save.read()).progress.original_quest_battle)
          const next = await read()
          assert.deepEqual(next.progress.original_completed_battles, [checkpoint])
          assert.equal(resumed, true)
          if (!chapter.first_battle) {
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
    assert.equal(verifiedEntrance, true)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
