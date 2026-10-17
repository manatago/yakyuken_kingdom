import assert from 'node:assert/strict'
import { copyFile, mkdir, mkdtemp, readFile, rm } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url)), executablePath = createRequire(import.meta.url)('electron')

test('battle and slideshow editors preview and save shared trace edits and new bubble text', { timeout: 60_000 }, async () => {
  const project = await mkdtemp(join(tmpdir(), 'janken-trace-editor-ui-'))
  let app
  try {
    await mkdir(join(project, 'content/stories'), { recursive: true })
    for (const name of ['prologue-battle', 'stage1-battle', 'quest-battles', 'campaign-battles', 'subevent3-minigame', 'stage2-minigame', 'stage3-minigame', 'stage4-minigame', 'stage5-minigame']) {
      await copyFile(join(root, `content/stories/godot-${name}.json`), join(project, `content/stories/godot-${name}.json`))
    }
    app = await electron.launch({ executablePath, args: [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${join(project, 'user')}`, `--content-root=${project}`] })
    const page = await app.firstWindow()
    await page.getByRole('button', { name: '戦闘表示編集', exact: true }).click()
    const battle = page.getByRole('main', { name: '戦闘表示編集画面' })
    const catalog = await page.evaluate(() => globalThis.janken.content.traceCatalog())
    const selected = catalog.findIndex(target => target.document === 'quests' && target.label.includes('outfit_1'))
    await battle.getByLabel('戦闘の対象').selectOption(String(selected))
    const record = await page.evaluate(target => globalThis.janken.content.readTrace(target.document, target.target), catalog[selected])
    const index = record.commands.findIndex(command => command.kind === 'band')
    await battle.getByLabel('表示命令').selectOption(String(index))
    const args = [...record.commands[index].args]; args[1] = '戦闘エディタの隔離テスト'
    await battle.getByLabel('引数 2', { exact: true }).fill(args[1])
    await battle.getByTestId('trace-preview-text').filter({ hasText: args[1] }).waitFor()
    await battle.getByRole('button', { name: '表示を保存', exact: true }).click()
    await battle.getByRole('status').filter({ hasText: '保存しました。' }).waitFor()
    const changed = await page.evaluate(target => globalThis.janken.content.readTrace(target.document, target.target), catalog[selected])
    assert.equal(changed.commands[index].args[1], args[1])
    await page.getByRole('button', { name: '紙芝居編集', exact: true }).click()
    const slides = page.getByRole('main', { name: '紙芝居編集画面' }), slideCatalog = catalog.filter(target => target.hasSlides)
    await slides.getByLabel('戦闘の対象').selectOption('0')
    const slide = await page.evaluate(target => globalThis.janken.content.readTrace(target.document, target.target), slideCatalog[0])
    const bubble = slide.commands.findIndex(command => command.kind === 'bubble')
    await slides.getByLabel('表示命令').selectOption(String(bubble))
    const newText = '紙芝居の新しい台詞'
    const edit = [newText, { ...slide.commands[bubble].args[1], font_size: 42 }]
    await slides.getByText('詳細設定（JSON）', { exact: true }).click()
    await slides.getByLabel('表示引数').fill(JSON.stringify(edit))
    await slides.getByTestId('trace-preview-bubble').filter({ hasText: newText }).waitFor()
    assert.equal(await slides.getByTestId('trace-preview-bubble').evaluate(node => getComputedStyle(node).fontSize), '42px')
    await slides.getByRole('button', { name: '表示を保存', exact: true }).click()
    await slides.getByRole('status').filter({ hasText: '保存しました。' }).waitFor()
    const saved = JSON.parse(await readFile(join(project, 'content/stories/godot-prologue-battle.json'), 'utf8'))
    assert.ok(saved.editor_bubbles.some(entry => entry.text === newText))
    await slides.getByRole('button', { name: '表示を再読込', exact: true }).click()
    await slides.getByLabel('表示命令').selectOption(String(bubble))
    assert.equal(JSON.parse(await slides.getByLabel('表示引数').inputValue())[0], newText)
  } finally { if (app) await app.close(); await rm(project, { recursive: true, force: true }) }
})
