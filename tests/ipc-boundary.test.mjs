import assert from 'node:assert/strict'
import { existsSync, readFileSync } from 'node:fs'
import { mkdtemp, readFile, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { createRequire } from 'node:module'
import ts from 'typescript'

const root = fileURLToPath(new URL('..', import.meta.url))
const require = createRequire(import.meta.url)

async function loadTypeScript(path) {
  const source = readFileSync(join(root, path), 'utf8')
  const javascript = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2022 }
  }).outputText
  return import(`data:text/javascript;base64,${Buffer.from(javascript).toString('base64')}`)
}

function loadCommonJsTypeScript(path, dependencies = {}) {
  const source = readFileSync(join(root, path), 'utf8')
  const javascript = ts.transpileModule(source, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022 }
  }).outputText
  const module = { exports: {} }
  const resolve = (name) => dependencies[name] ?? require(name)
  new Function('require', 'module', 'exports', javascript)(resolve, module, module.exports)
  return module.exports
}

test('game and editor use distinct preload entrypoints', () => {
  const game = readFileSync(join(root, 'electron.vite.game.config.ts'), 'utf8')
  const editor = readFileSync(join(root, 'electron.vite.editor.config.ts'), 'utf8')
  assert.match(game, /electron\/preload\/game\.ts/)
  assert.match(editor, /electron\/preload\/editor\.ts/)
  assert.ok(existsSync(join(root, 'electron/preload/game.ts')))
  assert.ok(existsSync(join(root, 'electron/preload/editor.ts')))
})

test('IPC documents accept only bounded JSON objects', async () => {
  const { serializeDocument } = await loadTypeScript('electron/main/json-document.ts')
  assert.equal(serializeDocument({ message: 'hello' }), '{"message":"hello"}')
  for (const value of [null, [], { number: Number.NaN }, { missing: undefined }, JSON.parse('{"__proto__":{}}')]) {
    assert.throws(() => serializeDocument(value))
  }
  const circular = {}
  circular.self = circular
  assert.throws(() => serializeDocument(circular))
  assert.throws(() => serializeDocument({ data: 'x'.repeat(1_048_576) }))
})

test('fixed document store preserves prior data when a write is rejected', async () => {
  const json = loadCommonJsTypeScript('electron/main/json-document.ts')
  const { createDocumentStore } = loadCommonJsTypeScript('electron/main/document-store.ts', {
    './json-document': json
  })
  const directory = await mkdtemp(join(tmpdir(), 'janken-ipc-test-'))
  try {
    const store = createDocumentStore(directory, 'document.json')
    assert.equal(await store.read(), null)
    await store.write({ message: 'first' })
    assert.deepEqual(await store.read(), { message: 'first' })
    await assert.rejects(store.write({ message: undefined }))
    assert.equal(await readFile(join(directory, 'document.json'), 'utf8'), '{"message":"first"}')
  } finally {
    await rm(directory, { recursive: true, force: true })
  }
})
