import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { advanceStory } from './story-input.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
for (const cursor of [98, 95]) test(`source grow ends at the loaded portrait geometry (${cursor === 98 ? 'cold image' : 'different image dimensions'})`, async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-portrait-dimensions-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${directory}`] })
  try {
    const page = await app.firstWindow()
    await page.addInitScript(() => {
      globalThis.growClocks = []
      const cancelled = new WeakMap()
      const cancel = Animation.prototype.cancel
      Animation.prototype.cancel = function () {
        if (this.effect instanceof KeyframeEffect && this.effect.getTiming().duration === 1200) {
          cancelled.set(this.effect.target, this.currentTime)
        }
        return cancel.call(this)
      }
      const animate = Element.prototype.animate
      Element.prototype.animate = function (frames, options) {
        const before = cancelled.get(this)
        cancelled.delete(this)
        const animation = animate.call(this, frames, options)
        if (options?.duration === 1200 && frames.length === 61 && before !== undefined) {
          queueMicrotask(() => globalThis.growClocks.push({ before, after: animation.currentTime }))
        }
        return animation
      }
    })
    const url = new URL(page.url()); url.searchParams.set('original', 'prologue'); url.searchParams.set('cursor', String(cursor))
    await page.goto(url.href)
    if (cursor === 95) {
      await page.getByTestId('original-cursor').filter({ hasText: 'prologue:95' }).waitFor()
      await page.waitForFunction(() => document.querySelector('[data-testid="original-portrait-main"]')?.naturalWidth === 1280)
      await advanceStory(page)
    }
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:100' }).waitFor()
    await page.waitForFunction(() => document.querySelector('[data-testid="original-portrait-main"]')?.naturalWidth === 1465)
    await page.evaluate(() => Promise.all(document.getAnimations().map(animation => animation.finished.catch(() => {}))))
    const geometry = await page.evaluate(() => {
      const image = document.querySelector('[data-testid="original-portrait-main"]')
      const node = image.parentElement
      const style = getComputedStyle(node)
      return { x: parseFloat(style.left), y: parseFloat(style.top), targetX: parseFloat(node.style.left), targetY: parseFloat(node.style.top),
        transform: new DOMMatrix(style.transform).a, targetTransform: new DOMMatrix(node.style.transform).a, width: image.naturalWidth, height: image.naturalHeight }
    })
    assert.equal(geometry.width, 1465); assert.equal(geometry.height, 1249)
    assert.ok(Math.abs(geometry.x - geometry.targetX) < .01, JSON.stringify(geometry))
    assert.ok(Math.abs(geometry.y - geometry.targetY) < .01, JSON.stringify(geometry))
    assert.ok(Math.abs(geometry.transform - geometry.targetTransform) < .000001)
    const clocks = await page.evaluate(() => globalThis.growClocks)
    assert.ok(clocks.length > 0, 'texture load must exercise a source tween geometry correction')
    for (const clock of clocks) {
      assert.ok(Math.abs(clock.before - clock.after) < 1, `dimension correction restarted source tween: ${JSON.stringify(clock)}`)
    }
    assert.equal(await page.evaluate(() => globalThis.janken.save.read()), null)
  } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
})
