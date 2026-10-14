import { advanceStory, reopenStoryTitle } from './story-input.mjs'
import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
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

async function conversation(page, sequenceId) {
  const commands = source.sequences.find(sequence => sequence.id === sequenceId).commands
  for (const [index, command] of commands.entries()) {
    if (!['line', 'band'].includes(command.kind) || !command.parameters.wait_for_input) continue
    await page.getByTestId('original-cursor').filter({ hasText: `${sequenceId}:${index + 1}` }).waitFor()
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
      command.parameters.text)
    if (sequenceId === 'prologue_battle_win' && index === 2) {
      // Main reuses its pre-battle StoryScene: this band changes only Matilda.
      // Reconstructing the win sequence from an empty scene incorrectly loses Satoshi.
      await page.getByTestId('original-portrait-main').waitFor({ state: 'visible' })
      assert.equal(await page.getByTestId('original-portrait-main').isVisible(), true)
    }
    await advanceStory(page)
  }
  await page.getByTestId('original-matilda-choices').waitFor()
}

for (const winning of [false, true]) test(`Matilda ${winning ? 'win' : 'loss/home'} aftermath resumes and uses actual Main title fallthrough`, async () => {
  const fixture = spawnSync(process.execPath, ['--import', 'tsx', '-e',
    `const { originalMatildaAftermathFixture } = require('./tests/helpers/original-matilda-aftermath-fixture.ts'); console.log(JSON.stringify(originalMatildaAftermathFixture(${winning})))`],
  { cwd: root, encoding: 'utf8' })
  assert.equal(fixture.status, 0, fixture.stderr)
  const initial = JSON.parse(fixture.stdout)
  const userData = await mkdtemp(join(tmpdir(), 'janken-matilda-aftermath-ui-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(save => globalThis.janken.save.write(save), initial)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    const sequenceId = winning ? 'prologue_battle_win' : 'prologue_battle_lose'
    await conversation(page, sequenceId)
    const read = () => page.evaluate(() => globalThis.janken.save.read())
    const beforeResume = await read()
    assert.deepEqual(beforeResume.progress.flags, initial.progress.flags)
    await reopenStoryTitle(page)
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-matilda-choices').waitFor()
    assert.deepEqual(await read(), beforeResume)
    if (!winning) {
      await page.getByRole('button', { name: 'ホームに戻る', exact: true }).click()
      await page.getByTestId('original-matilda-choices').waitFor({ state: 'hidden' })
      await conversation(page, sequenceId)
      assert.equal((await read()).player.money, 10)
      assert.equal((await read()).progress.original_matilda_aftermath.actions.length, 3)
      await page.getByRole('heading', { name: '敗北...', exact: true }).waitFor()
      assert.match(await page.getByTestId('original-matilda-choices').innerText(), /残念\.\.\.再戦しますか？/)
    } else await page.getByRole('heading', { name: '勝利！', exact: true }).waitFor()
    await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'stage1:' }).waitFor()
    const stage1 = await read()
    assert.equal(stage1.progress.original_matilda_aftermath, undefined)
    assert.equal(stage1.progress.original_story_origin, winning ? 'prologue_battle_win' : 'prologue_battle_lose')
    assert.deepEqual(stage1.progress.flags, initial.progress.flags)
    assert.equal(stage1.player.money, winning ? 30 : 10)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
