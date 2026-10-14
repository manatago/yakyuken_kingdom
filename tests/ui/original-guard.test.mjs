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
const document = JSON.parse(await readFile(join(root, 'content/stories/godot-original.json'), 'utf8'))

test('all original prologue guard lines show the guard instead of retaining Minori or rewritten dialogue', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-guard-test-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    const commands = document.sequences.find(s => s.id === 'prologue').commands
    const lines = commands.map((command, index) => ({ command, index }))
      .filter(({ command }) => command.kind === 'band' && command.parameters.speaker_id === 'guard' && command.parameters.wait_for_input)
    assert.equal(lines.length, 4)
    for (const { command, index } of lines) {
      const saved = { save_version: 1, player: { money: 0, deck: [], items: [], equipment: [],
        inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
        progress: { checkpoint_id: `original:prologue:${index + 1}`, flags: [] } }
      await page.evaluate(value => globalThis.janken.save.write(value), saved)
      await page.reload()
      await page.getByRole('button', { name: 'つづきから', exact: true }).click()
      await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent?.endsWith(text), command.parameters.text)
      const portrait = commands.slice(0, index).findLast(c => c.kind === 'show_character' && c.parameters.character_id === 'guard').parameters.portrait_id
      const filename = portrait.split('/').at(-1).replace('.png', '-')
      const guard = page.getByTestId('original-portrait-guard')
      assert.ok((await guard.getAttribute('src')).includes(filename))
      await page.waitForFunction(() => {
        const img = document.querySelector('[data-testid="original-portrait-guard"]')
        return img?.complete && img.naturalWidth > 0 && img.getBoundingClientRect().width > 0
      })
      assert.equal(await page.getByTestId('original-portrait-heroine').isVisible(), false)
      assert.equal(await page.getByTestId('card-box').count(), 0)
      assert.equal((await page.evaluate(() => globalThis.janken.save.read())).progress.checkpoint_id, saved.progress.checkpoint_id)
      assert.equal(await page.getByText('身元が確認できるまで、いったん保護室で話を聞く。落ち着いて事情を説明してくれ。').count(), 0)
    }
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
