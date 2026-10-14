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
const commands = source.sequences.find(sequence => sequence.id === 'prologue').commands
const index = commands.findIndex(command => command.kind === 'band' && command.parameters.speaker_id === 'main')
const scene = await readFile(join(root, 'godot/StoryScene.tscn'), 'utf8')
const bodyNode = scene.split('[node name="BodyLabel" type="Label" parent="DialogueBand/InnerLeft"]')[1].split('[node ')[0]
const bodyAnchor = name => Number(bodyNode.match(new RegExp(`^${name} = ([0-9.]+)$`, 'm'))[1])

test('original character bubble uses source RGB background filter and narrator restores it', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-bg-filter-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(cursor => globalThis.janken.save.write({ save_version: 1,
      player: { inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))), deck: [], money: 0, items: [] },
      progress: { checkpoint_id: `original:prologue:${cursor}`, flags: [] } }), index + 1)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: `prologue:${index + 1}` }).waitFor()
    assert.match(await page.getByAltText('背景', { exact: true }).evaluate(image => getComputedStyle(image).filter), /url\(/)
    const matrix = page.getByTestId('original-background-color-matrix')
    assert.equal(await matrix.getAttribute('color-interpolation-filters'), 'sRGB')
    const values = (await matrix.getAttribute('values')).split(/\s+/).map(Number)
    const expected = [.592275, .132075, .02565, 0, 0, .067275, .657075, .02565, 0, 0, .067275, .132075, .55065, 0, 0, 0, 0, 0, 1, 0]
    assert.equal(values.length, expected.length)
    values.forEach((value, index) => assert.ok(Math.abs(value - expected[index]) < 1e-8))
    assert.equal(await page.getByTestId('original-portrait-main').evaluate(image => getComputedStyle(image).filter), 'none')
    const body = await page.getByTestId('original-text').evaluate(text => {
      const frame = text.parentElement.getBoundingClientRect(), rect = text.getBoundingClientRect()
      return { left: (rect.left - frame.left) / frame.width, top: (rect.top - frame.top) / frame.height,
        width: rect.width / frame.width, height: rect.height / frame.height, frameWidth: frame.width, frameHeight: frame.height }
    })
    for (const [name, expected] of Object.entries({ left: bodyAnchor('anchor_left'), top: bodyAnchor('anchor_top'),
      width: bodyAnchor('anchor_right') - bodyAnchor('anchor_left'), height: bodyAnchor('anchor_bottom') - bodyAnchor('anchor_top') })) {
      // Chromium rounds each layout edge to 1/64 CSS px; a size has two edges.
      const dimension = ['left', 'width'].includes(name) ? body.frameWidth : body.frameHeight
      assert.ok(Math.abs(body[name] - expected) * dimension <= 1 / 32, `Godot bubble ${name}: ${body[name]} != ${expected}`)
    }
    if (process.env.JANKEN_VISUAL_DIR) {
      await page.setViewportSize({ width: 1920, height: 1080 })
      await page.waitForFunction(() => [...document.querySelectorAll('img')].every(image => image.complete && image.naturalWidth > 0))
      await page.screenshot({ path: join(process.env.JANKEN_VISUAL_DIR, 'electron.png') })
      const comparison = await app.evaluate(({ nativeImage }, directory) => {
        const source = nativeImage.createFromPath(`${directory}/godot.png`)
        const target = nativeImage.createFromPath(`${directory}/electron.png`)
        const a = source.toBitmap(), b = target.toBitmap(), size = source.getSize()
        if (source.isEmpty() || target.isEmpty() || size.width !== target.getSize().width || size.height !== target.getSize().height) {
          throw new Error('Reference frame dimensions differ')
        }
        let total = 0, samples = 0, maximum = 0
        // Stable background/portrait region, excluding both engines' UI controls and text.
        for (let y = 100; y <= 800; y += 40) for (let x = 80; x <= 1840; x += 40) {
          const offset = (y * size.width + x) * 4
          for (let channel = 0; channel < 3; channel++) {
            const difference = Math.abs(a[offset + channel] - b[offset + channel])
            total += difference; samples++; maximum = Math.max(maximum, difference)
          }
        }
        return { size, meanAbsoluteRgbDifference: total / samples, maximum, samples }
      }, process.env.JANKEN_VISUAL_DIR)
      console.log('Actual Godot/Electron frame comparison', comparison)
    }
    for (let cursor = index + 1; cursor <= commands.length; cursor++) {
      const command = commands[cursor - 1]
      if (!['band', 'line'].includes(command.kind) || !command.parameters.wait_for_input) continue
      await page.getByTestId('original-cursor').filter({ hasText: `prologue:${cursor}` }).waitFor()
      if (command.parameters.speaker_id === 'narrator') {
        assert.equal(await page.getByAltText('背景', { exact: true }).evaluate(image => getComputedStyle(image).filter), 'none')
        return
      }
      await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text, command.parameters.text)
      await advanceStory(page)
    }
    assert.fail('Missing original narrator transition')
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
