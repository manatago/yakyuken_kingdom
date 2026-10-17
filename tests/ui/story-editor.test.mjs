import assert from 'node:assert/strict'
import { copyFile, mkdir, mkdtemp, readFile, rm, writeFile } from 'node:fs/promises'
import { createRequire } from 'node:module'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const executablePath = createRequire(import.meta.url)('electron')

test('all-story editor previews drafts, preserves unsaved edits across tabs, saves and reloads', { timeout: 60_000 }, async () => {
  const project = await mkdtemp(join(tmpdir(), 'janken-all-story-ui-'))
  const target = join(project, 'content/stories/godot-original.json')
  let app
  try {
    await mkdir(join(project, 'content/stories'), { recursive: true })
    await mkdir(join(project, 'godot/assets/editor-test'), { recursive: true })
    await writeFile(join(project, 'godot/assets/editor-test/pixel.png'), Buffer.alloc(0))
    await copyFile(join(root, 'content/stories/godot-original.json'), target)
    const original = await readFile(target, 'utf8')
    const scene = JSON.parse(original).sequences.find(scene => scene.id === 'stage2_pre')
    const index = scene.commands.findIndex(command => ['line', 'band'].includes(command.kind) && command.parameters.text)
    app = await electron.launch({ executablePath, args: [join(root, 'dist/editor/main/index.js'), `--user-data-dir=${join(project, 'user')}`, `--content-root=${project}`] })
    const page = await app.firstWindow()
    const pixel = await app.evaluate(({ nativeImage }) => nativeImage.createFromBitmap(Buffer.from([255, 255, 255, 255]), { width: 1, height: 1 }).toPNG().toString('base64'))
    await writeFile(join(project, 'godot/assets/editor-test/pixel.png'), Buffer.from(pixel, 'base64'))
    await page.getByRole('button', { name: 'ストーリー編集', exact: true }).click()
    await page.getByRole('button', { name: '画像候補を取得', exact: true }).click()
    await page.waitForFunction(() => document.querySelectorAll('#story-image-candidates option').length === 1)
    const imageLoaded = await page.evaluate(() => new Promise(resolve => {
      const image = new Image()
      image.crossOrigin = 'anonymous'
      image.onload = () => {
        try {
          const canvas = document.createElement('canvas'), gl = canvas.getContext('webgl')
          const texture = gl.createTexture(); gl.bindTexture(gl.TEXTURE_2D, texture)
          gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, image)
          const error = gl.getError(); gl.deleteTexture(texture)
          resolve({ width: image.naturalWidth, error })
        } catch (error) { resolve({ error: error.name }) }
      }
      image.onerror = () => resolve(false)
      image.src = 'janken-project-image://project/?path=' + encodeURIComponent('res://assets/editor-test/pixel.png')
    }))
    assert.deepEqual(imageLoaded, { width: 1, error: 0 })
    await page.getByLabel('シーケンス', { exact: true }).selectOption('stage2_pre')
    await page.waitForFunction(() => !document.querySelector('[aria-label="命令"]').disabled)
    await page.getByLabel('命令', { exact: true }).selectOption(String(index))
    await page.getByLabel('編集 text', { exact: true }).fill('隔離テストの変更です。')
    await page.getByTestId('story-editor-preview').getByTestId('original-text').filter({ hasText: '隔離テストの変更です。' }).waitFor()
    assert.equal(await readFile(target, 'utf8'), original)
    assert.equal(await page.getByLabel('シーケンス', { exact: true }).isDisabled(), true)
    await page.getByRole('button', { name: '途中から始める', exact: true }).click()
    await page.getByRole('button', { name: 'ストーリー編集', exact: true }).click()
    assert.equal(await page.getByLabel('編集 text', { exact: true }).inputValue(), '隔離テストの変更です。')
    await page.getByRole('button', { name: '命令を保存', exact: true }).click()
    await page.getByRole('status').filter({ hasText: '保存しました。' }).waitFor()
    assert.equal(await readFile(target + '.bak', 'utf8'), original)
    const saved = JSON.parse(await readFile(target, 'utf8'))
    assert.equal(saved.sequences.find(scene => scene.id === 'stage2_pre').commands[index].parameters.text, '隔離テストの変更です。')
    await page.reload()
    await page.getByRole('button', { name: 'ストーリー編集', exact: true }).click()
    await page.getByRole('button', { name: '前回の編集位置', exact: true }).click()
    await page.getByLabel('編集 text', { exact: true }).filter({ visible: true }).waitFor()
    assert.equal(await page.getByLabel('編集 text', { exact: true }).inputValue(), '隔離テストの変更です。')
  } finally { if (app) await app.close(); await rm(project, { recursive: true, force: true }) }
})
