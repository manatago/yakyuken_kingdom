import assert from 'node:assert/strict'
import { existsSync, readFileSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))

function readTree(directory) {
  return readdirSync(directory, { withFileTypes: true })
    .map((entry) => {
      const path = join(directory, entry.name)
      return entry.isDirectory() ? readTree(path) : readFileSync(path, 'utf8')
    })
    .join('\n')
}

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
  assert.doesNotMatch(readTree(game), /Janken Editor|Editor workspace/)
  assert.match(readTree(editor), /Janken Editor/)
})
