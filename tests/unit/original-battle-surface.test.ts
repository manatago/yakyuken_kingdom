import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalBattleSurface, applyOriginalBattleSurface } from '../../packages/story/original-battle-surface'

test('battle band, explicit bubble and cleared blur remain independent', () => {
  const state = createOriginalBattleSurface()
  applyOriginalBattleSurface(state, { kind: 'band', args: ['matilda', '原本の本文'] })
  applyOriginalBattleSurface(state, { kind: 'select_hand', args: [] })
  assert.equal(state.bandVisible, true)
  applyOriginalBattleSurface(state, { kind: 'bubble', args: ['別の吹き出し', { side: 'left' }] })
  assert.deepEqual(state.band, { text: '原本の本文', speaker: 'matilda' })
  applyOriginalBattleSurface(state, { kind: 'set_battle_ui_visible', args: [false] })
  assert.equal(state.blurred, false)
  assert.equal(state.bandVisible, false)
  assert.deepEqual(state.bubble, { text: '別の吹き出し', side: 'left', revision: 1 })
  applyOriginalBattleSurface(state, { kind: 'set_battle_ui_visible', args: [true] })
  assert.equal(state.bandVisible, true)
  assert.equal(state.blurred, false)
})
