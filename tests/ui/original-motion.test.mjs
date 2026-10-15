import { advanceStory, reopenStoryTitle } from './story-input.mjs'
import assert from 'node:assert/strict'
import { mkdtemp, rm, readFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const source = JSON.parse(await readFile(new URL('../../content/stories/godot-original.json', import.meta.url), 'utf8'))

for (const scenario of ['normal frames', 'coalesced frames', 'same background', 'slot replacement', 'unmount during fade']) test(`original portrait and background transitions retain the outgoing image and use source duration (${scenario})`, async () => {
  const fastFrames = scenario === 'coalesced frames'
  const directory = await mkdtemp(join(tmpdir(), 'janken-original-fades-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [`${root}/dist/game/main/index.js`, `--user-data-dir=${directory}`] })
  try {
    const page = await app.firstWindow()
    const errors = []
    page.on('pageerror', error => errors.push(error.message))
    const base = page.url()
    const kinds = scenario === 'same background' ? ['background'] : ['slot replacement', 'unmount during fade'].includes(scenario) ? ['portrait'] : ['portrait', 'background']
    const sequenceId = scenario === 'slot replacement' ? 'subevent3_visit' : 'prologue'
    for (let iteration = 0; iteration < (kinds.length === 1 ? 1 : 10); iteration++) for (const kind of kinds) {
      const commands = source.sequences.find(sequence => sequence.id === sequenceId).commands
      const index = scenario === 'same background' ? 186 : scenario === 'slot replacement' ? 53 : kind === 'portrait' ? 13 : 44
      const cursor = commands.slice(0, index).findLastIndex(command => command.kind === 'band' && command.parameters.wait_for_input) + 1
      const url = new URL(base); url.searchParams.set('original', sequenceId); url.searchParams.set('cursor', String(cursor))
      await page.goto(url.href)
      await page.getByTestId('original-cursor').filter({ hasText: `${sequenceId}:${cursor}` }).waitFor()
      await page.waitForFunction(() => [...document.images].every(image => image.complete && image.naturalWidth > 0))
      const outgoing = await page.evaluate(({ kind, character }) => {
        if (kind === 'background') return document.querySelector('.story-background').src
        return document.querySelector(`[data-testid="original-portrait-${character}"]`).src
      }, { kind, character: scenario === 'slot replacement' ? 'sebas' : 'main' })
      await page.evaluate(fast => {
        globalThis.fadeCalls = []
        const animate = Element.prototype.animate
        Element.prototype.animate = function (frames, options) {
          const kind = this.dataset.originalFade || this.dataset.originalSnapshot
          if (kind) globalThis.fadeCalls.push({ kind, frames, options, oldOpacity: getComputedStyle(this).opacity,
            snapshots: [...document.querySelectorAll('[data-original-snapshot]')].map(node =>
              ({ kind: node.dataset.originalSnapshot, opacity: getComputedStyle(node).opacity,
                src: node.tagName === 'IMG' ? node.src : node.querySelector('img').src })) })
          return animate.call(this, frames, options)
        }
        if (fast) {
          const frame = globalThis.requestAnimationFrame.bind(globalThis)
          let remaining = 8
          globalThis.requestAnimationFrame = callback => {
            if (--remaining <= 0) { globalThis.requestAnimationFrame = frame; return frame(callback) }
            queueMicrotask(() => callback(performance.now()))
            return 0
          }
        }
      }, fastFrames)
      if (fastFrames) await page.evaluate(() => [...document.querySelectorAll('button')].find(button => button.textContent === '次へ').click())
      else await advanceStory(page)
      await page.waitForFunction(kind => globalThis.fadeCalls.some(call => call.kind === kind), kind)
      const calls = await page.evaluate(() => globalThis.fadeCalls)
      const call = calls.find(call => call.kind === kind)
      assert.ok(call, `${kind} source transition was not executed`)
      assert.equal(call.options.duration, Number(commands[index].parameters[kind === 'portrait' ? 'transition_duration' : 'fade']) * 1000)
      if (scenario === 'slot replacement' || kind === 'background') {
        assert.ok(call.snapshots.some(snapshot => snapshot.kind === kind && snapshot.src === outgoing),
          'the exact outgoing image must remain during the fade')
      } else assert.ok(call.snapshots.some(snapshot => snapshot.kind === kind), 'outgoing image must remain during the fade')
      assert.deepEqual(call.frames, [{ opacity: 0 }, { opacity: 1 }])
      if (kind === 'portrait' && scenario === 'normal frames') {
        assert.equal(call.snapshots.find(snapshot => snapshot.kind === kind).opacity, call.oldOpacity,
          'outgoing portrait retains the current opacity of the Godot slot')
      }
      if (scenario === 'unmount during fade') {
        await reopenStoryTitle(page)
        await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
        assert.equal(await page.evaluate(() => document.querySelectorAll('[data-original-snapshot]').length), 0)
        assert.equal(await page.evaluate(() => document.getAnimations().length), 0)
        continue
      }
      await page.evaluate(() => Promise.all(document.getAnimations().map(animation => animation.finished.catch(() => {}))))
      await page.waitForFunction(() => document.querySelectorAll('[data-original-snapshot]').length === 0)
      if (kind === 'background') {
        const outgoingFade = await page.evaluate(() => globalThis.fadeCalls.find(call => call.kind === 'background' && call.frames[0].opacity === 1))
        assert.ok(outgoingFade, 'the outgoing background fades only after the incoming background')
        assert.equal(outgoingFade.options.duration, call.options.duration)
        assert.deepEqual(outgoingFade.frames, [{ opacity: 1 }, { opacity: 0 }])
      }
    }
    assert.equal(await page.evaluate(() => globalThis.janken.save.read()), null)
    assert.deepEqual(errors, [])
  } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
})

test('replacing a portrait during its crossfade preserves opacity before cancelling the old animation', async () => {
  const directory = await mkdtemp(join(tmpdir(), 'janken-original-overlapping-fades-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${directory}`] })
  try {
    const page = await app.firstWindow()
    const url = new URL(page.url()); url.searchParams.set('original', 'prologue'); url.searchParams.set('cursor', '11')
    await page.goto(url.href)
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:11' }).waitFor()
    await advanceStory(page)
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    const outgoing = await page.evaluate(() => {
      const image = document.querySelector('[data-testid="original-portrait-main"]')
      const animation = image.parentElement.getAnimations().find(animation => animation.effect.getKeyframes().length === 2)
      if (!animation) throw new Error('First source crossfade did not start')
      animation.pause(); animation.currentTime = 150
      globalThis.outgoingAnimation = animation
      return { src: image.src, opacity: getComputedStyle(image.parentElement).opacity }
    })
    assert.equal(outgoing.opacity, '0.5')
    const commands = source.sequences.find(sequence => sequence.id === 'prologue').commands
    for (const cursor of [15, 17]) {
      await page.evaluate(() => [...document.querySelectorAll('button')].find(button => button.textContent === '次へ').click())
      await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
        commands[cursor - 1].parameters.text)
      await page.evaluate(() => [...document.querySelectorAll('button')].find(button => button.textContent === '次へ').click())
      await page.waitForFunction(previous => document.querySelector('[data-testid="original-cursor"]')?.textContent !== previous, `prologue:${cursor}`)
    }
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:19' }).waitFor()
    const snapshot = await page.evaluate(src => [...document.querySelectorAll('[data-original-snapshot="portrait"]')]
      .filter(node => node.querySelector('img')?.src === src).map(node => getComputedStyle(node).opacity), outgoing.src)
    assert.deepEqual(snapshot, [outgoing.opacity])
    assert.equal(await page.evaluate(() => globalThis.outgoingAnimation.playState), 'idle')
    assert.equal(await page.evaluate(() => globalThis.janken.save.read()), null)
  } finally { await app.close(); await rm(directory, { recursive: true, force: true }) }
})
