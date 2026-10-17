import assert from 'node:assert/strict'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const source = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))
const commands = source.sequences.find(sequence => sequence.id === 'prologue').commands

for (const mode of ['new', 'resume']) for (const key of ['Enter', 'Space']) {
  test(`story accepts ${key} immediately after ${mode} without a viewport click or explicit focus`, async () => {
    const directory = await mkdtemp(join(tmpdir(), 'janken-keyboard-entry-'))
    const app = await electron.launch({ executablePath,
      args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${directory}`] })
    try {
      const page = await app.firstWindow()
      await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
      const cursor = mode === 'new' ? commands.findIndex(command => command.kind === 'band' && command.parameters.wait_for_input) + 1 : 15
      if (mode === 'resume') {
        await page.evaluate(save => globalThis.janken.save.write(save), { save_version: 1,
          player: { money: 75, deck: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand =>
            Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
          progress: { checkpoint_id: `original:prologue:${cursor}`, flags: [] } })
        await page.reload()
        await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      } else await page.getByRole('button', { name: '新しく始める', exact: true }).click()
      await page.getByTestId('original-cursor').filter({ hasText: `prologue:${cursor}` }).waitFor()
      await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
        commands[cursor - 1].parameters.text)
      const next = commands.findIndex((command, index) => index >= cursor && command.kind === 'band' && command.parameters.wait_for_input) + 1
      // keyboard.press deliberately does not focus a locator, unlike locator.press.
      await page.keyboard.press(key)
      await page.getByTestId('original-cursor').filter({ hasText: `prologue:${next}` }).waitFor({ timeout: 3000 })
      assert.equal((await page.evaluate(() => globalThis.janken.save.read())).progress.checkpoint_id, `original:prologue:${next}`)
    } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
  })
}

test('changing an editor preview does not steal keyboard focus from its selector', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-keyboard-editor-'))
  const app = await electron.launch({ executablePath,
    args: [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${directory}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'マチルダ配置編集', exact: true }).click()
    const selector = page.getByLabel('配置ID')
    await selector.waitFor()
    await page.waitForFunction(() => !document.querySelector('[aria-label="配置ID"]').disabled)
    await selector.focus()
    await selector.selectOption('layout.matilda.explanation')
    await page.waitForFunction(() => Number(document.querySelector('[data-testid="original-cursor"]')?.textContent?.split(':')[1]) >= 192)
    assert.equal(await page.evaluate(() => document.activeElement?.getAttribute('aria-label')), '配置ID')
  } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
})
