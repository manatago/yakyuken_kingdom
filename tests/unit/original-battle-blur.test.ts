import assert from 'node:assert/strict'
import test from 'node:test'
import source from '../../content/stories/godot-battle-highlight.json'
import { originalBattleBlurFragment } from '../../packages/story/original-battle-blur'

test('battle blur translates the actual nine-tap shader and 15 texture-pixel offsets', () => {
  assert.equal(source.blur.amount, 15)
  assert.equal((originalBattleBlurFragment.match(/texture2D\(u_texture,/g) ?? []).length, 9)
  assert.match(originalBattleBlurFragment, /const float blur_amount = 15\.0/)
  assert.match(originalBattleBlurFragment, /vec2 ps = TEXTURE_PIXEL_SIZE \* blur_amount/)
  const weights = [...originalBattleBlurFragment.matchAll(/\* (0\.\d+);/g)].map(match => Number(match[1]))
  assert.deepEqual(weights, [.16, .12, .12, .12, .12, .09, .09, .09, .09])
  assert.ok(Math.abs(weights.reduce((total, weight) => total + weight, 0) - 1) < 1e-10)
  assert.doesNotMatch(originalBattleBlurFragment, /shader_type|hint_range|texture\(TEXTURE|COLOR =/)
})
