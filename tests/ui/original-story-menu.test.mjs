import assert from 'node:assert/strict'
import { mkdtemp, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const geometry = createRequire(import.meta.url)('../../content/stories/godot-story-menu-geometry.json')
const originalDocument = createRequire(import.meta.url)('../../content/stories/godot-original.json')
const inventoryGeometry = createRequire(import.meta.url)('../../content/stories/godot-story-inventory-geometry.json')
const paletteGeometry = createRequire(import.meta.url)('../../content/stories/godot-battle-dialogue.json').palettes
async function assertRect(locator, expected) {
  const actual = await locator.evaluate(control => {
    const stage = control.closest('.story-stage').getBoundingClientRect(), rect = control.getBoundingClientRect(), scale = stage.width / 1920
    return [(rect.left - stage.left) / scale, (rect.top - stage.top) / scale, rect.width / scale, rect.height / scale]
  })
  actual.forEach((value, index) => assert.ok(Math.abs(value - expected[index]) < .1, `control rect ${index}: ${value} != ${expected[index]}`))
}
test('original Item and Equip menus only view inventory and never alter the saved game', async () => {
  const userData = await mkdtemp(join(tmpdir(), 'janken-original-story-menu-'))
  const app = await electron.launch({ executablePath: createRequire(import.meta.url)('electron'),
    args: [join(root, 'dist/game/main/index.js'), `--user-data-dir=${userData}`] })
  try {
    const page = await app.firstWindow()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(() => globalThis.janken.save.write({ save_version: 1,
      player: { money: 75, deck: [], inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))),
        items: ['iron_shield', 'iron_shield', 'substitute_card'], equipment: ['gold_charm'] },
      progress: { checkpoint_id: 'original:prologue:15', flags: [] } }))
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    const before = await page.evaluate(() => globalThis.janken.save.read())
    assert.equal(await page.getByRole('button', { name: '原本再生を終了', exact: true }).count(), 0)
    assert.equal(await page.getByRole('button', { name: '次へ', exact: true }).count(), 0)
    const menu = page.getByTestId('original-story-menu')
    const item = menu.getByRole('button', { name: 'Item', exact: true })
    const color = await item.evaluate(button => getComputedStyle(button).color)
    assert.equal(color, `rgb(${geometry.styles.font.slice(0, 3).map(value => Math.round(value * 255)).join(', ')})`)
    await item.hover()
    const palette = originalDocument.sequences.find(sequence => sequence.id === 'prologue').commands.slice(0, 15)
      .filter(command => command.kind === 'band_color').at(-1).parameters.color
    const capturedPalette = paletteGeometry.find(entry => entry.color.every((value, index) => Math.abs(value - palette[['r', 'g', 'b', 'a'][index]]) < 1e-6))
    assert.ok(capturedPalette)
    const expectedHover = `rgba(${capturedPalette.hover.slice(0, 3).map(value => Math.round(value * 255)).join(', ')}, ${Number(capturedPalette.hover[3].toFixed(3))})`
    assert.equal(await item.evaluate(button => getComputedStyle(button).backgroundColor), expectedHover)
    for (const id of ['ItemButton', 'EquipButton', 'SaveButton', 'LoadButton', 'ConfigButton', 'ExitButton']) {
      const original = geometry.buttons.find(button => button.id === id)
      const rect = await menu.getByRole('button', { name: original.text, exact: true }).evaluate(button => {
        const stage = button.closest('.story-stage').getBoundingClientRect(), rect = button.getBoundingClientRect(), scale = stage.width / 1920
        return [(rect.left - stage.left) / scale, (rect.top - stage.top) / scale, rect.width / scale, rect.height / scale]
      })
      rect.forEach((value, index) => assert.ok(Math.abs(value - original.rect[index]) < .1, `${id} rect ${index}: ${value} != ${original.rect[index]}`))
    }
    for (const name of ['Save', 'Load', 'Config']) {
      await menu.getByRole('button', { name, exact: true }).click()
      assert.equal(await page.getByTestId('original-cursor').textContent(), 'prologue:15')
      assert.deepEqual(await page.evaluate(() => globalThis.janken.save.read()), before)
    }
    await menu.getByRole('button', { name: 'Item', exact: true }).click()
    const modal = page.getByRole('dialog')
    await modal.getByRole('heading', { name: 'アイテム', exact: true }).waitFor()
    assert.match(await modal.innerText(), /所持金: 75/)
    assert.equal(await modal.locator('img').count(), 3)
    await page.waitForFunction(() => [...document.querySelectorAll('[role="dialog"] img')].every(image => image.complete && image.naturalWidth > 0))
    await assertRect(modal, inventoryGeometry.viewers.item.rect)
    await assertRect(modal.getByRole('heading'), inventoryGeometry.viewers.item.title_rect)
    await assertRect(modal.getByRole('button'), inventoryGeometry.viewers.item.close_rect)
    await assertRect(modal.locator('img').first(), inventoryGeometry.viewers.item.gold.icon_rect)
    assert.ok(await modal.locator('img').first().evaluate(image => image.complete && image.naturalWidth > 0))
    assert.match(await modal.innerText(), /鉄の盾.*2/)
    assert.doesNotMatch(await modal.innerText(), /身代わりカード.*×1/)
    assert.equal(await modal.getByRole('button').count(), 1)
    await menu.getByRole('button', { name: 'Equip', exact: true }).click()
    assert.equal(await modal.count(), 0) // Godot closes an existing modal before opening another.
    await menu.getByRole('button', { name: 'Equip', exact: true }).click()
    await modal.getByRole('heading', { name: '装備', exact: true }).waitFor()
    assert.match(await modal.innerText(), /金運のお守り/)
    await assertRect(modal, inventoryGeometry.viewers.equip.rect)
    await assertRect(modal.getByRole('button'), inventoryGeometry.viewers.equip.close_rect)
    await modal.getByRole('button', { name: '閉じる', exact: true }).click()
    assert.deepEqual(await page.evaluate(() => globalThis.janken.save.read()), before)
    await page.reload()
    await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
    await page.evaluate(save => globalThis.janken.save.write({ ...save,
      player: { ...save.player, items: [], equipment: [] } }), before)
    await page.reload()
    await page.getByRole('button', { name: 'つづきから', exact: true }).click()
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:15' }).waitFor()
    const emptyBefore = await page.evaluate(() => globalThis.janken.save.read())
    await menu.getByRole('button', { name: 'Item', exact: true }).click()
    await modal.getByText('アイテムがありません', { exact: true }).waitFor()
    await assertRect(modal, inventoryGeometry.viewers.empty_item.rect)
    await assertRect(modal.getByRole('button'), inventoryGeometry.viewers.empty_item.close_rect)
    await modal.getByRole('button', { name: '閉じる', exact: true }).click()
    await menu.getByRole('button', { name: 'Equip', exact: true }).click()
    await modal.getByText('装備品がありません', { exact: true }).waitFor()
    await assertRect(modal, inventoryGeometry.viewers.empty_equip.rect)
    await assertRect(modal.getByRole('button'), inventoryGeometry.viewers.empty_equip.close_rect)
    await modal.getByRole('button', { name: '閉じる', exact: true }).click()
    assert.deepEqual(await page.evaluate(() => globalThis.janken.save.read()), emptyBefore)
    await menu.getByRole('button', { name: 'Item', exact: true }).click()
    const close = modal.getByRole('button', { name: '閉じる', exact: true })
    await close.dispatchEvent('keydown', { key: 'Enter', code: 'Enter', repeat: true, bubbles: true })
    assert.equal(await page.getByTestId('original-cursor').textContent(), 'prologue:15')
    await close.press('Enter')
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:17' }).waitFor({ timeout: 2000 })
    assert.equal(await modal.count(), 1) // Original _input handles ui_accept before the button GUI event.
    assert.deepEqual((await page.evaluate(() => globalThis.janken.save.read())).player, emptyBefore.player)
    await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
      originalDocument.sequences.find(sequence => sequence.id === 'prologue').commands[16].parameters.text)
    await close.focus()
    await page.keyboard.down('Enter')
    await page.getByTestId('original-cursor').filter({ hasText: 'prologue:19' }).waitFor()
    await page.keyboard.down('Enter') // Native repeated key, including the browser button default action.
    await page.keyboard.up('Enter')
    assert.equal(await modal.count(), 1)
    assert.equal(await page.getByTestId('original-cursor').textContent(), 'prologue:19')
  } finally { await app.close(); await rm(userData, { recursive: true, force: true }) }
})
