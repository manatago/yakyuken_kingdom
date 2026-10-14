import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalGuildSave } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const document = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))

test('original guild board opens all four canonical quest introductions and church rematch, retaining flags on restart', { timeout: 90_000 }, async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-quest-entry-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const source = originalGuildSave()
    source.progress.flags = ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed']
    source.progress.original_completed_quests = ['subevent1', 'subevent2', 'subevent3']
    source.progress.random_battles_completed = 3
    for (const [quest, sequence, rematch] of [
      ['subevent1', 'subevent1_pre', false], ['subevent2', 'subevent2_pre1', false],
      ['subevent3', 'subevent3_pre', false], ['subevent4', 'subevent4_pre', false],
      ['subevent2', 'subevent2_rematch', true]
    ]) {
      const saved = structuredClone(source)
      if (rematch) saved.progress.flags.push('encounter_sister_long_seen')
      await page.evaluate(value => globalThis.janken.save.write(value), saved)
      await page.reload()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByTestId('guild-frame').waitFor()
      assert.equal(await page.getByTestId(`quest-${quest}`).getAttribute('data-unlocked'), 'true')
      assert.equal(await page.getByTestId('main-story-board').count(), 0)
      await page.getByTestId(`quest-${quest}`).getByRole('button', { name: /サブイベント/ }).click()
      const commands = document.sequences.find(s => s.id === sequence).commands
      const index = commands.findIndex(c => ['band', 'line'].includes(c.kind) && c.parameters.wait_for_input)
      await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:${index + 1}` }).waitFor()
      await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent?.endsWith(text), commands[index].parameters.text)
      const current = await page.evaluate(() => globalThis.janken.save.read())
      assert.equal(current.progress.checkpoint_id, `original:${sequence}:${index + 1}`)
      assert.deepEqual(current.progress.flags, saved.progress.flags)
      assert.deepEqual(current.progress.original_quest, { id: quest, origin_checkpoint: source.progress.guild_return_checkpoint, route: rematch ? 'rematch' : 'full' })
      assert.equal(current.progress.subevent1_jin_battle, undefined)
      await page.reload()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:${index + 1}` }).waitFor()
      assert.deepEqual(await page.evaluate(() => globalThis.janken.save.read()), current)
    }
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})

test('original quest introduction finishes into its hideout sequence without losing the saved route', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-quest-transition-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const commands = document.sequences.find(s => s.id === 'subevent1_pre').commands
    const index = commands.findLastIndex(c => ['band', 'line'].includes(c.kind) && c.parameters.wait_for_input)
    const source = originalGuildSave()
    const origin = source.progress.guild_return_checkpoint
    delete source.progress.guild_return_checkpoint
    source.progress.checkpoint_id = `original:subevent1_pre:${index + 1}`
    source.progress.flags = ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed']
    source.progress.original_quest = { id: 'subevent1', origin_checkpoint: origin, route: 'full' }
    await page.evaluate(value => globalThis.janken.save.write(value), source)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent?.endsWith(text), commands[index].parameters.text)
    const before = await page.evaluate(() => globalThis.janken.save.read())
    await advanceStory(page)
    await page.getByTestId('original-cursor').filter({ hasText: 'subevent1_hideout:' }).waitFor()
    const current = await page.evaluate(() => globalThis.janken.save.read())
    assert.ok(current.progress.checkpoint_id.startsWith('original:subevent1_hideout:'))
    assert.deepEqual(current.progress.original_quest, source.progress.original_quest)
    assert.deepEqual(current.progress.flags, source.progress.flags)
    assert.deepEqual(current.player, before.player)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
