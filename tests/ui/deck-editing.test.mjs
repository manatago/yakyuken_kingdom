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

test('all grades edit, cancel, recover from failed save and resume without rewriting battle records', { timeout: 90_000 }, async () => {
  const data = await mkdtemp(join(tmpdir(), 'janken-lineup-'))
  const target = join(data, 'janken-save.json')
  const inventory = ['rock', 'scissors', 'paper'].flatMap((hand) => [1, 2, 3, 4, 5].map((grade) => ({ hand, grade })))
  const battleDeck = ['rock', 'scissors', 'paper'].flatMap((hand) => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const content = JSON.parse(await readFile(join(root, 'content/stories/matilda-tutorial.json'), 'utf8'))
  // The recorded battle uses three Normal copies of each hand.
  const owned = [...inventory, ...['rock', 'scissors', 'paper'].flatMap((hand) =>
    Array.from({ length: 2 }, () => ({ hand, grade: 1 })))]
  const original = { save_version: 1, player: { inventory: owned, deck: battleDeck, money: 17 }, progress: {
    checkpoint_id: 'matilda.end', flags: ['matilda.tutorial.completed'], tutorial: {
      battle_id: content.battles[0].id, rounds: [{ player_index: 6, opponent_index: 0 }, { player_index: 0, opponent_index: 3 }], acknowledged: 2
    }
  } }
  const bytes = JSON.stringify(original)
  let app, page
  const open = async () => {
    app = await electron.launch({ executablePath, args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${data}`] })
    page = await app.firstWindow()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByRole('button', { name: '編成を編集', exact: true }).waitFor()
  }
  try {
    await writeFile(target, bytes)
    await open()
    const box = page.getByTestId('card-box')
    assert.equal(await box.locator('.card-grade').count(), owned.length)
    await page.waitForFunction(() => [...document.querySelectorAll('.card-box img')].every((img) => img.complete && img.naturalWidth > 0))
    for (const grade of ['N', 'B', 'S', 'G', 'P']) assert.equal(await box.getByLabel(`グレード ${grade}`, { exact: true }).count(), grade === 'N' ? 9 : 3)
    assert.equal(await readFile(target, 'utf8'), bytes)
    await page.getByRole('button', { name: '編成を編集', exact: true }).click()
    let dialog = page.getByRole('dialog')
    await dialog.getByRole('button', { name: '編成から削除 グー N', exact: true }).first().click()
    assert.equal(await dialog.getByRole('button', { name: '編成を保存', exact: true }).isDisabled(), true)
    await dialog.getByRole('button', { name: 'キャンセル', exact: true }).click()
    assert.equal(await readFile(target, 'utf8'), bytes)
    await page.getByRole('button', { name: '編成を編集', exact: true }).click()
    dialog = page.getByRole('dialog')
    while (await dialog.getByRole('button', { name: /^編成から削除/ }).count()) {
      await dialog.getByRole('button', { name: /^編成から削除/ }).first().click()
    }
    for (const grade of ['N', 'B', 'S', 'G', 'P']) {
      await dialog.getByRole('button', { name: `編成に追加 グー ${grade}`, exact: true }).first().click()
      if (grade !== 'N') assert.equal(await dialog.getByRole('button', { name: `編成に追加 グー ${grade}`, exact: true }).isDisabled(), true)
    }
    for (const grade of ['N', 'B', 'S', 'G']) await dialog.getByRole('button', { name: `編成に追加 チョキ ${grade}`, exact: true }).first().click()
    assert.equal(await dialog.getByRole('button', { name: '編成に追加 パー P', exact: true }).isDisabled(), true)
    await mkdir(join(root, 'test-results/cards'), { recursive: true })
    const session = await page.context().newCDPSession(page)
    await session.send('Emulation.setDeviceMetricsOverride', { width: 1920, height: 1080, deviceScaleFactor: 1, mobile: false })
    await page.screenshot({ path: join(root, 'test-results/cards/deck-editor.png') })
    await session.detach()
    await rename(target, join(data, 'held.json'))
    await mkdir(target)
    await dialog.getByRole('button', { name: '編成を保存', exact: true }).click()
    await dialog.getByRole('alert').waitFor()
    assert.equal(await dialog.getByRole('button', { name: /^編成から削除/ }).count(), 9)
    assert.equal(await readFile(join(data, 'held.json'), 'utf8'), bytes)
    await rm(target, { recursive: true })
    await rename(join(data, 'held.json'), target)
    await dialog.getByRole('button', { name: '編成を保存', exact: true }).click()
    await dialog.waitFor({ state: 'detached' })
    const savedBytes = await readFile(target, 'utf8')
    const saved = JSON.parse(savedBytes)
    assert.deepEqual(saved.player.prepared_deck, inventory.slice(0, 9))
    assert.deepEqual(saved.player.deck, battleDeck)
    assert.deepEqual(saved.player.inventory, owned)
    assert.deepEqual(saved.progress, original.progress)
    assert.equal(saved.player.money, 17)
    await app.close(); app = undefined
    await open()
    assert.equal(await readFile(target, 'utf8'), savedBytes)
    await page.getByRole('button', { name: '編成を編集', exact: true }).click()
    assert.equal(await page.getByRole('dialog').getByRole('button', { name: /^編成から削除/ }).count(), 9)
    await page.getByRole('dialog').getByRole('button', { name: 'キャンセル', exact: true }).click()
    assert.equal(await readFile(target, 'utf8'), savedBytes)
  } finally {
    try { if (app) await app.close() } finally { await rm(data, { recursive: true, force: true }) }
  }
})
