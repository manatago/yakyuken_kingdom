import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { extractBubbleRules } from '../../scripts/bubble-rules-source.mjs'

test('edited bubble rules are extracted from the original Godot sizing and wrap definitions', () => {
  const read = path => readFileSync(new URL(`../../${path}`, import.meta.url), 'utf8')
  const actual = extractBubbleRules(...['game/BattleScene.gd', 'ui/BubbleFit.gd', 'ui/BubbleWrap.gd'].map(file => read(`godot/${file}`)),
    JSON.parse(read('content/stories/godot-battle-bubbles.json')))
  assert.deepEqual(actual, JSON.parse(read('content/stories/godot-bubble-rules.json')))
})
