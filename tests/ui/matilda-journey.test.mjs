import assert from 'node:assert/strict'
import { mkdir, mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'
import { assertMatildaSave } from '../helpers/matilda-checks.mjs'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const content = JSON.parse(await readFile(join(root, 'content/stories/matilda-tutorial.json'), 'utf8'))

async function continueThroughPrologue(page) {
  for (let count = 0; count < 20; count++) {
    const checkpoint = await page.getByTestId('checkpoint-id').textContent()
    if (checkpoint === 'prologue.end') {
      await page.getByRole('button', { name: 'チュートリアルへ進む', exact: true }).click()
      await page.getByTestId('story-text').getByText(/周りの風景/).waitFor()
      return
    }
    assert.ok(checkpoint?.startsWith('prologue.'), `Unexpected opening checkpoint ${checkpoint}`)
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await page.waitForFunction((previous) => document.querySelector('[data-testid="checkpoint-id"]')?.textContent !== previous,
      checkpoint)
  }
  assert.fail('Prologue did not reach Matilda tutorial')
}

test('new game reaches every Matilda line, prepares, plays twice and resumes through the end', { timeout: 180_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-matilda-journey-'))
  const screenshots = join(root, 'test-results/matilda')
  const target = join(data, 'janken-save.json')
  let app, page, initial
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async (button) => {
    app = await electron.launch({ executablePath,
      args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    const session = await page.context().newCDPSession(page)
    await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
    await page.getByRole('button', { name: button, exact: true }).click()
    await page.getByTestId('checkpoint-id').waitFor()
  }
  const check = async (checkpoint, deckSize = 0, rounds = null, acknowledged = null) => {
    await page.waitForFunction((id) => document.querySelector('[data-testid="checkpoint-id"]')?.textContent === id, checkpoint)
    const save = await read()
    assertMatildaSave(save, initial, { checkpoint, deckSize, rounds, acknowledged })
    return save
  }
  const restart = async () => {
    const before = await readFile(target, 'utf8')
    const checkpoint = await page.getByTestId('checkpoint-id').textContent()
    const text = await page.getByTestId('story-text').allTextContents()
    const result = await page.getByTestId('tutorial-result').allTextContents()
    await app.close(); app = undefined
    await open('つづきから')
    assert.equal(await page.getByTestId('checkpoint-id').textContent(), checkpoint)
    assert.deepEqual(await page.getByTestId('story-text').allTextContents(), text)
    assert.deepEqual(await page.getByTestId('tutorial-result').allTextContents(), result)
    assert.equal(await readFile(target, 'utf8'), before)
  }
  const capture = async (name) => {
    await page.waitForFunction(() => [...document.querySelectorAll('.story-stage img')].length > 0 &&
      [...document.querySelectorAll('.story-stage img')].every((img) => img.complete && img.naturalWidth > 0))
    const rect = await page.getByTestId('story-frame').boundingBox()
    assert.deepEqual(rect, { x: 0, y: 0, width: 1920, height: 1080 })
    await page.screenshot({ path: join(screenshots, `${name}.png`) })
  }
  try {
    await mkdir(screenshots, { recursive: true })
    await open('はじめから')
    await continueThroughPrologue(page)
    initial = await read()
    await check('matilda.start')
    assert.equal(initial.player.inventory.length, 9)
    assert.equal(initial.player.money, 0)
    assert.ok(initial.player.inventory.every((card) => card.grade === 1))
    await capture('introduction')
    const lines = content.stories[0].steps.filter((step) => step.kind === 'line' && step.id !== 'matilda.complete')
    for (const line of lines) {
      await check(line.id)
      assert.ok((await page.getByTestId('story-text').textContent()).includes(line.text))
      if (line.id === 'matilda.grades.normal-only') {
        await capture('grades')
        await restart()
      }
      await page.getByRole('button', { name: '次へ', exact: true }).click()
      await page.waitForFunction((previous) => {
        const next = [...document.querySelectorAll('button')].find((button) => button.textContent === '次へ')
        return document.querySelector('[data-testid="checkpoint-id"]')?.textContent !== previous && (!next || !next.disabled)
      }, line.id)
    }
    await check('matilda.await-deck')
    await restart()
    const ready = page.getByRole('button', { name: '準備完了', exact: true })
    assert.equal(await ready.isDisabled(), true)
    await page.getByRole('button', { name: '追加 グー N', exact: true }).first().click()
    await page.getByRole('button', { name: '削除 グー N', exact: true }).click()
    await page.getByRole('button', { name: '自動', exact: true }).click()
    await capture('preparation')
    await ready.click()
    await page.getByTestId('tutorial-selection').waitFor()
    await check('matilda.await-deck', 9, 0, 0)
    await restart()
    for (const [round, hand] of [[0, 'パー'], [1, 'グー']]) {
      await page.getByTestId('tutorial-selection').waitFor()
      assert.equal(await page.getByRole('button', { name: '勝負！', exact: true }).isDisabled(), true)
      await page.getByRole('button', { name: `選択 ${hand} N`, exact: true }).first().click()
      await page.getByRole('button', { name: '勝負！', exact: true }).click()
      await page.getByTestId('tutorial-result').waitFor()
      const saved = await check('matilda.await-deck', 9, round + 1, round)
      if (!round) {
        assert.ok((await page.getByTestId('tutorial-result').textContent()).includes('勝ち'))
        assert.equal(saved.progress.tutorial.rounds[0].opponent_index, 0)
      }
      await capture(`result-${round + 1}`)
      await restart()
      await page.getByRole('button', { name: round ? '練習を終える' : '次の練習へ', exact: true }).click()
      if (!round) {
        await page.getByTestId('tutorial-selection').waitFor()
        await check('matilda.await-deck', 9, 1, 1)
        assert.equal(await page.getByRole('button', { name: '選択 パー N', exact: true })
          .evaluateAll((buttons) => buttons.filter((button) => button.disabled).length), 1)
        await restart()
      }
    }
    await check('matilda.complete', 9, 2, 2)
    await page.getByTestId('story-text').getByText(/これがじゃんけんバトルの基本/).waitFor()
    await capture('completion')
    await restart()
    await page.getByRole('button', { name: '次へ', exact: true }).click()
    await check('matilda.end', 9, 2, 2)
    await page.getByRole('heading', { name: 'チュートリアル完了', exact: true }).waitFor()
    assert.equal(await page.getByRole('button', { name: '次へ', exact: true }).count(), 0)
    await restart()
    await page.getByRole('heading', { name: 'チュートリアル完了', exact: true }).waitFor()
  } finally {
    try {
      if (app) await app.close()
    } finally {
      await rm(data, { recursive: true, force: true })
    }
  }
})
