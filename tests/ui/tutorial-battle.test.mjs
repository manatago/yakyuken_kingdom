import assert from 'node:assert/strict'
import { mkdtemp, readFile, writeFile, rename, mkdir, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')
const inventory = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))

test('tutorial prepares, resumes results and completes two rounds without duplicate consumption', async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-tutorial-'))
  const target = join(data, 'janken-save.json')
  const args = [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`]
  let app
  const read = async () => JSON.parse(await readFile(target, 'utf8'))
  const open = async () => {
    app = await electron.launch({ executablePath, args })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    return page
  }
  try {
    await writeFile(target, JSON.stringify({ save_version: 1, player: { inventory, deck: [], money: 17 },
      progress: { checkpoint_id: 'matilda.await-deck', flags: [] } }))
    let page = await open()
    await page.getByRole('button', { name: '自動', exact: true }).waitFor()
    assert.equal(await page.getByRole('button', { name: '準備完了', exact: true }).isDisabled(), true)
    await page.getByRole('button', { name: '追加 グー N', exact: true }).first().click()
    await page.getByRole('button', { name: '削除 グー N', exact: true }).click()
    await page.getByRole('button', { name: '自動', exact: true }).click()
    await page.getByRole('button', { name: '準備完了', exact: true }).click()
    await page.getByTestId('tutorial-selection').waitFor()
    assert.equal(await page.getByRole('button', { name: '勝負！', exact: true }).isDisabled(), true)
    await page.getByRole('button', { name: '選択 パー N', exact: true }).first().click()
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('tutorial-result').waitFor()
    assert.ok((await page.getByTestId('tutorial-result').textContent()).includes('勝ち'))
    const first = await read()
    assert.equal(first.progress.tutorial.rounds.length, 1)
    assert.equal(first.progress.tutorial.acknowledged, 0)
    await app.close(); app = undefined
    page = await open()
    await page.getByTestId('tutorial-result').waitFor()
    assert.deepEqual(await read(), first)
    await page.getByRole('button', { name: '次の練習へ', exact: true }).click()
    await page.getByTestId('tutorial-selection').waitFor()
    const papers = page.getByRole('button', { name: '選択 パー N', exact: true })
    assert.equal(await papers.count(), 3)
    assert.equal(await papers.locator('visible=true').count(), 3)
    assert.equal(await papers.evaluateAll((buttons) => buttons.filter((button) => !button.disabled).length), 2)
    assert.equal(await papers.evaluateAll((buttons) => buttons.filter((button) => button.disabled).length), 1)
    await app.close(); app = undefined
    page = await open()
    await page.getByTestId('tutorial-selection').waitFor()
    await page.getByRole('button', { name: '選択 グー N', exact: true }).first().click()
    // Fail only the isolated save path, keeping the committed save for restoration.
    await rename(target, join(data, 'held-save.json')); await mkdir(target)
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByRole('alert').waitFor()
    assert.equal(await page.getByTestId('tutorial-result').count(), 0)
    await rm(target, { recursive: true }); await rename(join(data, 'held-save.json'), target)
    await page.getByRole('button', { name: '勝負！', exact: true }).click()
    await page.getByTestId('tutorial-result').waitFor()
    const second = await read()
    assert.equal(second.progress.tutorial.rounds.length, 2)
    await app.close(); app = undefined
    page = await open()
    await page.getByTestId('tutorial-result').waitFor()
    assert.deepEqual(await read(), second)
    if (process.env.JANKEN_UI_SCREENSHOT_DIR) await page.screenshot({ path: join(process.env.JANKEN_UI_SCREENSHOT_DIR, 'tutorial-result.png') })
    await page.getByRole('button', { name: '練習を終える', exact: true }).click()
    await page.getByTestId('story-text').getByText(/これがじゃんけんバトルの基本/).waitFor()
    const done = await read()
    assert.equal(done.progress.checkpoint_id, 'matilda.complete')
    assert.deepEqual(done.progress.flags, ['matilda.tutorial.completed'])
    assert.deepEqual(done.player.inventory, inventory)
    assert.equal(done.player.money, 17)
    await app.close(); app = undefined
    page = await open()
    await page.getByTestId('story-text').getByText(/これがじゃんけんバトルの基本/).waitFor()
    assert.deepEqual(await read(), done)
  } finally {
    if (app) await app.close()
    await rm(data, { recursive: true, force: true })
  }
})
