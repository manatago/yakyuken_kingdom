import test from 'node:test'
import assert from 'node:assert/strict'
import { ITEM_CATALOG, applyProbabilityAdjustment, getCaptureCount, getGoldBonus, getItemDefinition, isBattleUsable } from '../../packages/domain/item-catalog'

test('catalog includes every item defined by the Godot item database', () => {
  const expectedIds = [
    'substitute_card', 'iron_shield', 'intimidation',
    'rock_attract_white', 'rock_attract_crimson', 'rock_attract_gold',
    'rock_break_white', 'rock_break_crimson', 'rock_break_gold',
    'scissors_attract_white', 'scissors_attract_crimson', 'scissors_attract_gold',
    'scissors_dull_white', 'scissors_dull_crimson', 'scissors_dull_gold',
    'paper_attract_white', 'paper_attract_crimson', 'paper_attract_gold',
    'paper_seal_white', 'paper_seal_crimson', 'paper_seal_gold',
    'rank_up_talisman', 'smoke_bomb', 'greed_ring', 'gold_charm',
    'rare_find_pendant', 'crystal_fragment', 'rank_up_bracelet',
  ]
  assert.equal(ITEM_CATALOG.length, expectedIds.length)
  assert.deepEqual(ITEM_CATALOG.map(({ id }) => id), expectedIds)
  assert.equal(new Set(ITEM_CATALOG.map(({ id }) => id)).size, ITEM_CATALOG.length)
  for (const item of ITEM_CATALOG) {
    assert.ok(item.name.length > 0, `${item.id} has a name`)
    assert.ok(item.description.length > 0, `${item.id} has a description`)
    assert.ok(getItemDefinition(item.id))
  }
})

test('catalog preserves the one-use, adjusted probability behavior', () => {
  assert.equal(isBattleUsable(getItemDefinition('rank_up_talisman')!), false)
  assert.equal(isBattleUsable(getItemDefinition('smoke_bomb')!), false)
  assert.equal(isBattleUsable(getItemDefinition('intimidation')!), true)
  const increased = applyProbabilityAdjustment({ rock: 0.5, scissors: 0.3, paper: 0.2 }, 'rock', 0.1)
  assert.ok(Math.abs(increased.rock - 0.6) < Number.EPSILON * 4)
  assert.ok(Math.abs(increased.scissors - 0.24) < Number.EPSILON * 4)
  assert.ok(Math.abs(increased.paper - 0.16) < Number.EPSILON * 4)
  const reduced = applyProbabilityAdjustment({ rock: 0.5, scissors: 0.3, paper: 0.2 }, 'paper', -0.5)
  assert.ok(Math.abs(reduced.rock - 0.625) < Number.EPSILON * 4)
  assert.ok(Math.abs(reduced.scissors - 0.375) < Number.EPSILON * 4)
  assert.equal(reduced.paper, 0)
  assert.deepEqual(applyProbabilityAdjustment({ rock: 0, scissors: 0, paper: 1 }, 'paper', -0.1), {
    rock: 0,
    scissors: 0,
    paper: 0.9,
  })
})

test('equipment catalog describes the implemented capture and gold bonuses', () => {
  assert.equal(getCaptureCount([{ id: 'greed_ring' }]), 2)
  assert.equal(getCaptureCount([{ id: 'gold_charm' }]), 1)
  assert.equal(getGoldBonus([{ id: 'gold_charm' }]), 20)
  assert.equal(getGoldBonus([{ id: 'greed_ring' }]), 0)
  assert.equal(getItemDefinition('rank_up_bracelet')?.category, 'equipment')
})
