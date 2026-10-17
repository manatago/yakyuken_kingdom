import assert from 'node:assert/strict'
import { copyFile, mkdir, mkdtemp, readFile, rm } from 'node:fs/promises'
import { join } from 'node:path'
import { tmpdir } from 'node:os'
import test from 'node:test'
import { createTraceCommandStore, TRACE_DOCUMENTS } from '../../electron/main/trace-command-store'
import { replaceTraceCommand } from '../../packages/developer/traces'

test('trace store preserves other chapters, checks revision, and rejects foreign document IDs', async () => {
  const root = await mkdtemp(join(tmpdir(), 'janken-trace-store-'))
  try {
    await mkdir(join(root, 'content/stories'), { recursive: true })
    for (const file of Object.values(TRACE_DOCUMENTS)) await copyFile(join('content/stories', file), join(root, 'content/stories', file))
    const store = createTraceCommandStore(root), catalog = await store.catalog()
    const target = catalog.find(target => target.document === 'quests')!
    const record = await store.read(target.document, target.target)
    assert.match(record.background, /^res:\/\/assets\//)
    const index = record.commands.findIndex(command => ['band', 'bubble'].includes(command.kind))
    // A setup-only target may not have dialogue. Select an outfit target instead.
    const choice = index >= 0 ? target : catalog.find(target => target.document === 'quests' && target.label.includes('outfit_'))!
    const source = await store.read(choice.document, choice.target)
    const cursor = source.commands.findIndex(command => command.kind === 'band')
    assert.ok(cursor >= 0)
    const file = join(root, 'content/stories', TRACE_DOCUMENTS.quests), before = await readFile(file, 'utf8')
    const args = [...source.commands[cursor].args]; args[1] = '隔離した戦闘台詞の編集'
    const edit = { document: choice.document, target: choice.target, index: cursor, revision: source.revision, args }
    const result = await store.write(edit)
    assert.ok(result.affected >= 1)
    assert.equal(await readFile(file + '.bak', 'utf8'), before)
    assert.equal((await store.read(choice.document, choice.target)).commands[cursor].args[1], args[1])
    await assert.rejects(store.write(edit), /changed/)
    await assert.rejects(store.read('../story', choice.target), /Unknown/)
    await assert.rejects(store.read('__proto__', choice.target), /Unknown/)
    const previous = JSON.parse(before), after = JSON.parse(await readFile(file, 'utf8'))
    assert.deepEqual(after.chapters.slice(1), previous.chapters.slice(1))
  } finally { await rm(root, { recursive: true, force: true }) }
})

test('trace store refuses oversized formatted output without changing the readable source', async () => {
  const root = await mkdtemp(join(tmpdir(), 'janken-trace-limit-'))
  try {
    await mkdir(join(root, 'content/stories'), { recursive: true })
    for (const file of Object.values(TRACE_DOCUMENTS)) await copyFile(join('content/stories', file), join(root, 'content/stories', file))
    const store = createTraceCommandStore(root)
    const catalog = await store.catalog()
    for (const target of catalog.filter(entry => entry.document === 'evidence')) {
      const record = await store.read(target.document, target.target)
      const index = record.commands.findIndex(command => command.kind === 'narrator_band')
      if (index < 0) continue
      const file = join(root, 'content/stories', TRACE_DOCUMENTS.evidence)
      const before = await readFile(file, 'utf8')
      const args = [...record.commands[index].args]
      args[0] = 'x'.repeat(400_000)
      const candidate = replaceTraceCommand(JSON.parse(before), target.target, index, args).document
      assert.ok(Buffer.byteLength(JSON.stringify(candidate)) < 1_048_576, 'Compact validation alone would accept this edit')
      assert.ok(Buffer.byteLength(JSON.stringify(candidate, null, 2) + '\n') > 1_048_576, 'Formatted source exceeds the load limit')
      await assert.rejects(store.write({ document: target.document, target: target.target, index, args, revision: record.revision }), /too large/)
      assert.equal(await readFile(file, 'utf8'), before)
      assert.equal((await store.read(target.document, target.target)).revision, record.revision)
      return
    }
    assert.fail('Expected an editable evidence narrator command')
  } finally { await rm(root, { recursive: true, force: true }) }
})
