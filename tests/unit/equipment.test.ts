import test from 'node:test'
import assert from 'node:assert/strict'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { equipItem, unequipItem } from '../../packages/domain/equipment'

test('equipment moves between inventory and equipped slots and survives save reload', () => {
  const initial = createInitialGameSave()
  const source = { ...initial, player: { ...initial.player, items: ['greed_ring', 'gold_charm'] as const } }
  const equipped = equipItem(source, 'greed_ring')
  assert.deepEqual(equipped.player.items, ['gold_charm'])
  assert.deepEqual(equipped.player.equipment, ['greed_ring'])
  assert.deepEqual(unequipItem(equipped, 'greed_ring').player.items, ['gold_charm', 'greed_ring'])
  assert.deepEqual(unequipItem(equipped, 'greed_ring').player.equipment, [])
})

test('only owned equipment can be equipped and consumables cannot be equipped', () => {
  const source = createInitialGameSave()
  assert.throws(() => equipItem(source, 'greed_ring'))
  const withConsumable = { ...source, player: { ...source.player, items: ['paper_seal_white'] as const } }
  assert.throws(() => equipItem(withConsumable, 'paper_seal_white'))
  assert.throws(() => unequipItem(source, 'greed_ring'))
})

test('an equipment type cannot be equipped twice even when duplicate copies are owned', () => {
  const source = createInitialGameSave()
  const withDuplicates = { ...source, player: { ...source.player, items: ['greed_ring', 'greed_ring'] as const } }
  const equipped = equipItem(withDuplicates, 'greed_ring')
  assert.deepEqual(equipped.player.items, ['greed_ring'])
  assert.throws(() => equipItem(equipped, 'greed_ring'))
  assert.throws(() => parseSave({ ...equipped,
    player: { ...equipped.player, equipment: ['greed_ring', 'greed_ring'] } }))
})
