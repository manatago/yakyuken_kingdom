import { advanceStory } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const source = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))

test('standalone original ending retains its final dialogue without invented migration status or chapter transition', async () => {
  const sequence = source.sequences.find(sequence => sequence.id === 'stage7_epilogue')
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-terminal-scene-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(cursor => globalThis.janken.save.write({ save_version: 1,
      player: { inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))), deck: [], money: 0, items: [] },
      progress: { checkpoint_id: `original:stage7_epilogue:${cursor}`, flags: [] } }), sequence.commands.length)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: `stage7_epilogue:${sequence.commands.length}` }).waitFor()
    assert.equal(await page.getByTestId('original-text').innerText(), sequence.commands.at(-1).parameters.text)
    await advanceStory(page)
    await page.locator('.story-viewport[data-original-playback="ended"]').waitFor()
    assert.doesNotMatch(await page.locator('body').innerText(), /シーケンス終了|章間遷移は移植中/)
    assert.equal(await page.getByTestId('original-text').innerText(), sequence.commands.at(-1).parameters.text)
    const save = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(save.progress.checkpoint_id, `original:stage7_epilogue:${sequence.commands.length}`)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
