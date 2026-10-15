import { reopenStoryTitle } from './story-input.mjs'
import assert from 'node:assert/strict'
import { execFileSync } from 'node:child_process'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { originalDocument, advanceOriginalDialogue } from '../helpers/original-ui.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
function fixture(id, boundary) {
  return JSON.parse(execFileSync(process.execPath, ['--import', 'tsx', '-e',
    `const { originalQuestFixture } = require('./tests/helpers/original-quest-fixture.ts'); console.log(JSON.stringify(originalQuestFixture('${id}', '${boundary}')))`], { cwd: root, encoding: 'utf8' }))
}
async function isolated(initial, run) {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-routing-'))
  let app
  try {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
    const page = await app.firstWindow()
    const errors = []
    page.on('pageerror', error => errors.push(error.message))
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(save => globalThis.janken.save.write(save), initial)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await run(page)
    assert.deepEqual(errors, [])
  } finally { if (app) await app.close(); await rm(userData, { recursive: true, force: true }) }
}

for (const id of ['subevent2', 'subevent3', 'subevent4']) test(`${id} starts its original normal battle at a saved raw command`, async () => {
  await isolated(fixture(id, 'entry'), async page => {
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':deck' }).waitFor()
    const save = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(save.progress.original_quest.id, id)
    assert.equal(save.progress.original_quest_battle.runtime, undefined)
  })
})

for (const id of ['subevent2', 'subevent3']) test(`${id} loss renders and resumes the raw chapter scene before common loss`, async () => {
  const sequence = `${id}_battle_lose`
  const commands = originalDocument.sequences.find(s => s.id === sequence).commands
  const inputs = commands.flatMap((c, i) => ['band', 'line'].includes(c.kind) && c.parameters.wait_for_input ? [i + 1] : [])
  await isolated(fixture(id, 'redirect'), async page => {
    await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:${inputs[0]}` }).waitFor()
    const saved = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(saved.progress.original_quest_battle.aftermath.redirect_cursor, inputs[0])
    await reopenStoryTitle(page)
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    for (const cursor of inputs) await advanceOriginalDialogue(page, sequence, cursor)
    await page.getByTestId('original-quest-battle-cursor').filter({ hasText: ':aftermath' }).waitFor()
    const completed = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(completed.progress.original_quest_battle.aftermath.redirect_cursor, commands.length)
    assert.equal(completed.progress.checkpoint_id, saved.progress.checkpoint_id)
    assert.equal(completed.player.money, saved.player.money)
    const background = commands.filter(command => command.kind === 'background').at(-1).parameters.path
    const filename = background.split('/').at(-1).replace('.png', '-')
    assert.ok((await page.locator('.story-background').getAttribute('src')).includes(filename))
  })
})

test('Receptionist empty farewell returns directly from result to original post story', async () => {
  await isolated(fixture('subevent4', 'finished'), async page => {
    await page.getByRole('button', { name: 'OK', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'subevent4_post:' }).waitFor()
    const save = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(save.progress.original_quest_battle, undefined)
    assert.deepEqual(save.progress.original_quest.completed_battles, ['original:subevent4_post:26'])
    assert.equal(save.progress.original_last_lose_narration, undefined)
  })
})
