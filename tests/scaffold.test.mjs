import assert from 'node:assert/strict'
import { existsSync, readFileSync, readdirSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))

function readTree(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .map((entry) => {
      const path = join(directory, entry.name)
      // Inspect shipped code/content, not PNG/video bytes interpreted as UTF-8.
      return entry.isDirectory() ? readTree(path) : /\.(?:[cm]?js|html|css|json|map|txt)$/i.test(entry.name)
        ? readFileSync(path, 'utf8') : ''
    })
    .join('\n')
}

test('build isolation inspection includes text but does not decode binary assets', () => {
  const directory = mkdtempSync(join(tmpdir(), 'janken-build-inspection-'))
  try {
    writeFileSync(join(directory, 'code.js'), 'Janken Kingdom')
    writeFileSync(join(directory, 'data.json'), '{"value":"text data"}')
    writeFileSync(join(directory, 'image.png'), Buffer.from('Janken Editor'))
    assert.match(readTree(directory), /Janken Kingdom/)
    assert.match(readTree(directory), /text data/)
    assert.doesNotMatch(readTree(directory), /Janken Editor/)
  } finally { rmSync(directory, { recursive: true, force: true }) }
})

test('both applications have separate development and build commands', () => {
  const packageJson = JSON.parse(readFileSync(join(root, 'package.json'), 'utf8'))
  for (const command of ['dev:game', 'dev:editor', 'build:game', 'build:editor', 'typecheck', 'test']) {
    assert.equal(typeof packageJson.scripts[command], 'string', `${command} is missing`)
  }
  assert.notEqual(packageJson.scripts['dev:game'], packageJson.scripts['dev:editor'])
  assert.notEqual(packageJson.scripts['build:game'], packageJson.scripts['build:editor'])
})

test('game and editor build outputs are distinct', () => {
  const game = join(root, 'dist/game')
  const editor = join(root, 'dist/editor')
  assert.ok(existsSync(join(game, 'main/index.js')))
  assert.ok(existsSync(join(game, 'renderer/index.html')))
  assert.ok(existsSync(join(editor, 'main/index.js')))
  assert.ok(existsSync(join(editor, 'renderer/index.html')))
  assert.match(readTree(game), /Janken Kingdom/)
  assert.doesNotMatch(readTree(game), /Janken Editor|Editor workspace|content:read|content:write|editor-content\.json/)
  assert.match(readTree(editor), /Janken Editor/)
  assert.doesNotMatch(readTree(editor), /save:read|save:write|janken-save\.json/)
})
