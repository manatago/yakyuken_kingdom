import { advanceStory, reopenStoryTitle } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { finishOriginalShowdown } from '../helpers/original-ui.mjs'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const dialogueGeometry = createRequire(import.meta.url)('../../content/stories/godot-battle-dialogue.json')

test('original inventory viewer returns after battle with its opening snapshot', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-viewer-lifecycle-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(() => globalThis.janken.save.write({ save_version: 1,
      player: { money: 75, deck: [], items: ['iron_shield'], equipment: [],
        inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
      progress: { checkpoint_id: 'original:prologue:195', flags: [] } }))
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:195' }).waitFor()
    await page.getByRole('button', { name: 'Item', exact: true }).click()
    const modal = page.getByRole('dialog', { name: 'アイテム', exact: true })
    await modal.waitFor()
    await advanceStory(page)
    await page.getByTestId('original-tutorial-cursor').waitFor()
    await page.waitForFunction(() => document.querySelector('[data-testid="original-battle-background"]')?.dataset.backgroundReady === 'true', undefined, { timeout: 2000 })
    const samples = await page.getByTestId('original-battle-background').evaluate(canvas => {
      const image = canvas.previousElementSibling
      const reference = document.createElement('canvas')
      reference.width = image.naturalWidth; reference.height = image.naturalHeight
      const context = reference.getContext('2d')
      context.drawImage(image, 0, 0)
      const pixels = context.getImageData(0, 0, reference.width, reference.height).data
      const gl = canvas.getContext('webgl')
      const taps = [[0,0,.16],[15,0,.12],[-15,0,.12],[0,15,.12],[0,-15,.12],[15,15,.09],[-15,-15,.09],[15,-15,.09],[-15,15,.09]]
      return [0, .13, .38, .67, 1].flatMap(rx => [0, .21, .54, .79, 1].map(ry => {
        const x = Math.round(rx * (canvas.width - 1)), y = Math.round(ry * (canvas.height - 1))
        const actual = new Uint8Array(4)
        gl.readPixels(x, canvas.height - 1 - y, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, actual)
        const expected = [0,1,2].map(channel => taps.reduce((sum, [dx,dy,weight]) => {
          const sampleX = Math.max(0, Math.min(canvas.width - 1, x + dx))
          const sampleY = Math.max(0, Math.min(canvas.height - 1, y + dy))
          return sum + pixels[(sampleY * canvas.width + sampleX) * 4 + channel] * weight
        }, 0))
        return { x, y, actual: [...actual], expected }
      }))
    })
    for (const sample of samples) sample.expected.forEach((value, channel) =>
      assert.ok(Math.abs(value - sample.actual[channel]) <= 2, JSON.stringify(sample)))
    assert.equal(await modal.count(), 0) // Main hides the original StoryScene during battle.
    let finished = false
    for (let i = 0; i < 180; i++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running')
      })
      const before = await page.getByTestId('original-tutorial-cursor').textContent()
      const save = await page.evaluate(() => globalThis.janken.save.read())
      const state = save.progress.original_tutorial
      if (state.phase === 'dialogue') {
        await advanceStory(page)
        await page.waitForFunction(({ before, text }) =>
          document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent !== before ||
          document.querySelector('[data-testid="original-tutorial-dialogue"]')?.textContent?.endsWith(text), { before, text: state.text })
        continue
      }
      if (state.phase === 'deck') {
        await page.getByRole('button', { name: '自動', exact: true }).click()
        await page.getByRole('button', { name: '準備完了', exact: true }).click()
      } else if (state.phase === 'selection') {
        await page.getByRole('button', { name: state.battle.rounds.length ? 'デッキ 6 paper' : 'デッキ 3 paper', exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
      } else if (state.phase === 'result') {
        await finishOriginalShowdown(page)
      } else if (state.phase === 'reward') {
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        await page.getByTestId('original-cursor').filter({ hasText: 'prologue:201' }).waitFor()
        await modal.waitFor({ timeout: 2000 })
        assert.match(await modal.innerText(), /所持金: 75/)
        assert.equal((await page.evaluate(() => globalThis.janken.save.read())).player.money, 75 + state.gold)
        await modal.getByRole('button', { name: '閉じる', exact: true }).click()
        await page.getByRole('button', { name: 'Item', exact: true }).click()
        assert.match(await modal.innerText(), new RegExp(`所持金: ${75 + state.gold}`))
        finished = true
        break
      }
      await page.waitForFunction(before => document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent !== before, before)
    }
    assert.equal(finished, true)
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})

test('Godot tutorial plays real cards, resumes its result and pays its original reward once', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-tutorial-ui-'))
  const app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(async () => {
      await globalThis.janken.save.write({ save_version: 1, player: { money: 0, deck: [], items: [],
        inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
      progress: { checkpoint_id: 'original:prologue:198', flags: [] } })
    })
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    let resumed = false
    let finished = false
    let handArrowChecked = false
    const read = () => page.evaluate(() => globalThis.janken.save.read())
    for (let i = 0; i < 180; i++) {
      await page.waitForFunction(() => {
        const cursor = document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent
        return cursor && !cursor.endsWith(':running')
      })
      const before = await page.getByTestId('original-tutorial-cursor').textContent()
      const saved = await read()
      const state = saved.progress.original_tutorial
      assert.ok(state)
      if (state.phase === 'dialogue') {
        const body = page.getByTestId('original-tutorial-text')
        assert.equal(await body.count(), 1)
        const actual = await body.evaluate(label => {
          const stage = label.closest('.story-stage').getBoundingClientRect(), rect = label.getBoundingClientRect(), scale = stage.width / 1920
          return { rect: [(rect.left - stage.left) / scale, (rect.top - stage.top) / scale, rect.width / scale],
            font: getComputedStyle(label).fontSize, lineHeight: getComputedStyle(label).lineHeight }
        })
        const expected = dialogueGeometry.cases.find(entry => entry.mode === 'battle' && entry.speaker === 'speaker')
        expected.body.slice(0, 3).forEach((value, index) => assert.ok(Math.abs(value - actual.rect[index]) < .1, JSON.stringify(actual)))
        assert.equal(actual.font, `${expected.font_size}px`)
        assert.equal(actual.lineHeight, `${expected.line_height}px`)
      }
      if (state.highlight === 'hand_panel' && state.phase === 'dialogue') {
        const arrow = page.getByTestId('original-battle-highlight')
        await arrow.waitFor()
        await page.waitForFunction(() => {
          const image = document.querySelector('[data-testid="original-battle-highlight"]')
          return image?.complete && image.naturalWidth > 0
        })
        const actual = await arrow.evaluate(image => {
          const stage = image.closest('.story-stage').getBoundingClientRect()
          const target = image.closest('.story-stage').querySelector('[data-original-highlight-target="hand_panel"]').getBoundingClientRect()
          const scale = stage.width / 1920
          const pointsRight = (target.left - stage.left + target.width / 2) / scale > 960
          const animations = image.getAnimations()
          animations.forEach(animation => { animation.pause(); animation.currentTime = 400 })
          return { left: Number.parseFloat(image.style.left), top: Number.parseFloat(image.style.top),
            expectedLeft: pointsRight ? (target.left - stage.left) / scale - 198 + 50 : (target.right - stage.left) / scale - 44 + 50,
            expectedTop: (target.top - stage.top + target.height / 2) / scale - 54,
            transform: getComputedStyle(image).transform, expectedTransform: pointsRight ? 'matrix(1.3, 0, 0, 1.3, 0, 0)' : 'matrix(-1.3, 0, 0, 1.3, 0, 0)', duration: animations[0]?.effect.getTiming().duration,
            targetOutline: getComputedStyle(image.closest('.story-stage').querySelector('[data-original-highlight-target="hand_panel"]')).outlineStyle }
        })
        assert.ok(Math.abs(actual.left - actual.expectedLeft) < .1, JSON.stringify({ actual, playback: state.playback }))
        assert.ok(Math.abs(actual.top - actual.expectedTop) < .1)
        assert.equal(actual.duration, 800)
        assert.equal(actual.transform, actual.expectedTransform)
        assert.equal(actual.targetOutline, 'none')
        handArrowChecked = true
      }
      if (state.phase === 'dialogue') {
        await advanceStory(page)
        await page.waitForFunction(({ before, text }) =>
          document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent !== before ||
          document.querySelector('[data-testid="original-tutorial-dialogue"]')?.textContent?.endsWith(text),
        { before, text: state.text })
        continue
      }
      if (state.phase === 'deck') {
        await page.getByRole('button', { name: '自動', exact: true }).click()
        await page.getByRole('button', { name: '準備完了', exact: true }).click()
      } else if (state.phase === 'selection') {
        await page.getByRole('button', { name: state.battle.rounds.length ? 'デッキ 6 paper' : 'デッキ 3 paper', exact: true }).click()
        await page.getByRole('button', { name: '勝負！', exact: true }).click()
      } else if (state.phase === 'result') {
        if (!resumed) {
          assert.equal(state.battle.rounds[0].result, 'win')
          assert.equal(state.battle.opponentHp, 2)
          await page.getByRole('button', { name: 'タイトルに戻る', exact: true }).click()
          await page.getByRole('button', { name: 'つづきから', exact: true }).click()
          await page.getByTestId('original-tutorial-cursor').filter({ hasText: ':result' }).waitFor()
          assert.deepEqual((await read()).progress.original_tutorial, state)
          resumed = true
        }
        await finishOriginalShowdown(page)
      } else if (state.phase === 'reward') {
        assert.equal(state.battle.rounds.length, 2)
        assert.ok(state.gold >= 10 && state.gold <= 30)
        await page.getByRole('button', { name: 'OK', exact: true }).click()
        await page.getByTestId('original-text').filter({ hasText: 'さっきは言ってなかったけど、HPは服装の枚数だ。' }).waitFor()
        const completed = await read()
        assert.equal(completed.player.money, state.gold)
        assert.equal(completed.player.inventory.length, 9)
        assert.equal(completed.progress.original_tutorial, undefined)
        assert.ok(completed.progress.flags.includes('original.matilda.tutorial.completed'))
        assert.equal(completed.progress.tutorial, undefined)
        assert.equal(completed.progress.checkpoint_id, 'original:prologue:201')
        await reopenStoryTitle(page)
        await page.getByRole('button', { name: 'つづきから', exact: true }).click()
        await page.getByTestId('original-cursor').filter({ hasText: 'prologue:201' }).waitFor()
        assert.equal((await read()).player.money, state.gold)
        assert.ok((await read()).progress.flags.includes('original.matilda.tutorial.completed'))
        finished = true
        break
      }
      await page.waitForFunction(before =>
        document.querySelector('[data-testid="original-tutorial-cursor"]')?.textContent !== before, before)
    }
    assert.equal(resumed, true)
    assert.equal(finished, true)
    assert.equal(handArrowChecked, true)
  } finally {
    await app.close()
    await rm(userData, { recursive: true, force: true })
  }
})
