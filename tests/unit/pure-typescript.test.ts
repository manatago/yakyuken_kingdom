import assert from 'node:assert/strict'
import test from 'node:test'
import { total } from '../fixtures/sample-pure-function'

test('pure TypeScript modules run without building or launching Electron', () => {
  assert.equal(total([]), 0)
  assert.equal(total([2, 3, 5]), 10)
})
