import { advanceStory, originalDisplayedBattleText } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalGuildSave, originalStage1End, finishOriginalShowdown } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const battles = JSON.parse(await readFile(join(root, 'content/stories/godot-quest-battles.json'), 'utf8'))

for (const winning of [true, false]) test(`original Jin ${winning ? 'victory resumes raw commands' : 'loss plays raw farewell and returns to Guild'} with real saved checkpoints`, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-quest-battle-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.addInitScript(() => { Math.random = () => 0 })
    const initial = originalGuildSave()
    initial.player.money = 20
    if (winning) { initial.player.items = ['iron_shield', 'substitute_card']; initial.player.equipment = ['greed_ring'] }
    initial.progress = { checkpoint_id: 'original:subevent1_hideout:24', flags: [],
      original_quest: { id: 'subevent1', origin_checkpoint: originalStage1End, route: 'full' } }
    await page.evaluate(save => globalThis.janken.save.write(save), initial)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
    const read = () => page.evaluate(() => globalThis.janken.save.read())
    for (const index of winning ? [6, 7, 8] : [3, 4, 5]) {
      await page.getByRole('button', { name: `手持ち ${index + 1} ${winning ? 'paper' : 'scissors'} 1`, exact: true }).click()
      await page.waitForFunction(async length => (await globalThis.janken.save.read()).progress.original_quest_battle.draft.length === length,
        (winning ? [6, 7, 8] : [3, 4, 5]).indexOf(index) + 1)
      await page.waitForFunction(length => document.querySelectorAll('button[aria-label^="デッキ "]').length === length &&
        [...document.querySelectorAll('button')].some(button => button.textContent === 'タイトルに戻る' && !button.disabled),
      (winning ? [6, 7, 8] : [3, 4, 5]).indexOf(index) + 1)
    }
    await page.waitForFunction(() => [...document.querySelectorAll('button')].some(button =>
      button.textContent === '準備完了' && !button.disabled))
    const drafting = (await read()).progress.original_quest_battle
    assert.deepEqual(drafting.draft, winning ? [6, 7, 8] : [3, 4, 5])
    await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
    assert.deepEqual((await read()).progress.original_quest_battle, drafting)
    await page.getByRole('button', { name: '準備完了', exact: true }).click()
    let resumed = false
    for (let count = 0; count < 100; count++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-quest-battle-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running') && !cursor.endsWith(':deck')
      })
      const before = await page.getByTestId('original-quest-battle-cursor').textContent()
      const saved = await read()
      const state = saved.progress.original_quest_battle.runtime
      if (state.phase === 'dialogue') {
        await advanceStory(page)
        await page.waitForFunction(({ before, text }) => document.querySelector('[data-testid="original-quest-battle-cursor"]')?.textContent !== before ||
          document.querySelector('[data-testid="original-quest-text"]')?.textContent === text, { before, text: originalDisplayedBattleText(state) })
        if (await page.getByTestId('original-quest-battle-cursor').textContent() === before) await advanceStory(page)
      } else if (state.phase === 'selection') {
        if (winning) {
          await page.getByRole('button', { name: '鉄の盾', exact: true }).click()
          await page.waitForFunction(async () => (await globalThis.janken.save.read()).progress.original_quest_battle.runtime.resources.roundItem === 'iron_shield')
          assert.deepEqual((await read()).player.items, ['substitute_card'])
          await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
          await page.getByRole('button', { name: 'つづきから', exact: true }).click()
          await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':selection' }).waitFor()
          assert.equal((await read()).progress.original_quest_battle.runtime.resources.roundItem, 'iron_shield')
          await page.getByRole('button', { name: '鉄の盾', exact: true }).click()
          await page.waitForFunction(async () => !(await globalThis.janken.save.read()).progress.original_quest_battle.runtime.resources.roundItem)
          assert.deepEqual((await read()).player.items, ['iron_shield', 'substitute_card'])
          await page.getByRole('button', { name: '鉄の盾', exact: true }).click()
          await page.waitForFunction(async () => (await globalThis.janken.save.read()).progress.original_quest_battle.runtime.resources.roundItem === 'iron_shield')
        }
        const index = state.battle.playerUsed.findIndex(used => !used)
        await page.getByRole('button', { name: `デッキ ${index + 1} ${winning ? 'paper' : 'scissors'}`, exact: true }).click()
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
        assert.equal(resumed, true)
        assert.equal(state.outcome, winning ? 'win' : 'lose')
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        if (winning) {
          await page.getByTestId('original-cursor').filter({ hasText: 'subevent1_hideout:29' }).waitFor()
          const completed = await read()
          assert.deepEqual(completed.progress.original_quest.completed_battles, ['original:subevent1_hideout:24'])
          assert.equal(completed.progress.original_quest_battle, undefined)
          assert.equal(completed.player.money, 23)
          assert.equal(completed.player.inventory.length, 11)
          assert.deepEqual(completed.player.items, ['substitute_card', 'paper_attract_white', 'rock_break_white'])
          assert.deepEqual(completed.player.equipment, ['greed_ring'])
          assert.ok(Number(completed.progress.checkpoint_id.split(':')[2]) > 24)
        } else {
          await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':aftermath' }).waitFor()
          const first = await read()
          assert.equal(first.progress.original_quest_battle.aftermath.cursor, 0)
          assert.equal(first.player.money, 18)
          const farewell = battles.chapters.find(chapter => chapter.opponent_id === 'jin').farewell.lose
          const texts = [farewell.narration, farewell.text,
            ...battles.lose_narrations.patterns[first.progress.original_quest_battle.aftermath.pattern].frames.map(([, text]) => text.replaceAll('{opponent}', '盗賊ジン'))]
          for (let index = 0; index < texts.length; index++) {
            await page.waitForFunction(text => document.querySelector('[data-testid="original-quest-text"]')?.textContent === text, texts[index]).catch(async error => {
              const snapshot = await read()
              throw new Error(JSON.stringify({ index, expected: texts[index],
                displayed: await page.getByTestId('original-quest-text').textContent(),
                aftermath: snapshot.progress.original_quest_battle?.aftermath,
                alert: await page.getByRole('alert').allTextContents() }), { cause: error })
            })
            await advanceStory(page)
            await page.waitForFunction(async index => {
              const save = await globalThis.janken.save.read()
              return save.progress.checkpoint_id === 'guild.home' || save.progress.original_quest_battle.aftermath.cursor !== index
            }, index)
          }
          await page.getByTestId('guild-frame').waitFor()
          const completed = await read()
          assert.equal(completed.progress.original_quest_battle, undefined)
          assert.equal(completed.progress.original_quest, undefined)
          assert.equal(completed.progress.guild_return_checkpoint, originalStage1End)
          assert.equal(completed.player.money, 18)
          assert.equal(completed.player.inventory.length, 8)
          assert.equal(completed.progress.flags.includes('sub1_cleared'), false)
        }
        return
      }
      await page.waitForFunction(before => document.querySelector('[data-testid="original-quest-battle-cursor"]')?.textContent !== before, before)
    }
    assert.fail('Original battle did not finish')
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
