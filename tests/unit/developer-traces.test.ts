import assert from 'node:assert/strict'
import test from 'node:test'
import { commandTraceTargets, replaceTraceCommand } from '../../packages/developer/traces'

const portrait = () => ({ kind: 'set_portrait', args: ['opponent', 'res://assets/a.png', { scale: 1, position: [0, 0] }] })
const fixture = () => ({ traces: ['win', 'lose'].map(outcome => ({ method: 'outfit_3', outcomes: [outcome], commands: [
  portrait(), { kind: 'janken', args: [0, {}, outcome] }, { kind: 'band', args: ['opponent', outcome] }
] })) })

test('editing shared battle portrait updates every compatible outcome without mutating the input', () => {
  const original = fixture(), targets = commandTraceTargets(original)
  assert.equal(targets.length, 2)
  const result = replaceTraceCommand(original, targets[0].id, 0, ['opponent', 'res://assets/b.png', { scale: 2, position: [20, 30] }])
  for (const trace of result.document.traces) assert.equal(trace.commands[0].args[1], 'res://assets/b.png')
  assert.equal(result.affected, 2)
  assert.equal(original.traces[0].commands[0].args[1], 'res://assets/a.png')
})

test('an edit after a janken affects only its actual outcome branch', () => {
  const original = fixture(), targets = commandTraceTargets(original)
  const result = replaceTraceCommand(original, targets[0].id, 2, ['opponent', '勝利後の台詞'])
  assert.equal(result.affected, 1)
  assert.equal(result.document.traces[0].commands[2].args[1], '勝利後の台詞')
  assert.equal(result.document.traces[1].commands[2].args[1], 'lose')
})

test('chapter boundaries, simulation commands and malformed edits are protected', () => {
  const original = { chapters: [fixture(), fixture()] }, targets = commandTraceTargets(original)
  const result = replaceTraceCommand(original, targets[0].id, 0, ['opponent', 'res://assets/b.png', { scale: 1, position: [0, 0] }])
  assert.equal(result.affected, 2)
  assert.equal(result.document.chapters[1].traces[0].commands[0].args[1], 'res://assets/a.png')
  assert.throws(() => replaceTraceCommand(original, targets[0].id, 1, [9, {}, 'win']))
  assert.throws(() => replaceTraceCommand(original, '../../file', 0, []))
  assert.throws(() => replaceTraceCommand(original, targets[0].id, 0, ['opponent', 99]))
  assert.throws(() => replaceTraceCommand(original, targets[0].id, -1, []))
})
