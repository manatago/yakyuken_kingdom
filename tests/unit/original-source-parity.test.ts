import assert from 'node:assert/strict'
import test from 'node:test'
import { stripDeferredAdventurerReward } from '../../scripts/original-source-parity.mjs'

test('only the explicitly deferred substitute-card reward is excluded from source comparison', () => {
  const base = 'func tutorial():\n\tpass\n'
  const reward = 'func get_item_rewards() -> Array:\n\treturn ["substitute_card"]\n\n'
  assert.equal(stripDeferredAdventurerReward(reward + base), base)
  assert.equal(stripDeferredAdventurerReward(base), base)
  const other = reward.replace('substitute_card', 'greed_ring')
  assert.equal(stripDeferredAdventurerReward(other + base), other + base)
  const changed = reward.replace('\treturn', '\tprint("changed")\n\treturn')
  assert.equal(stripDeferredAdventurerReward(changed + base), changed + base)
  assert.notEqual(stripDeferredAdventurerReward(reward + base.replace('pass', 'changed()')), base)
})
