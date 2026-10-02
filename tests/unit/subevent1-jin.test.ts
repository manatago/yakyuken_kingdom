import assert from 'node:assert/strict'
import { existsSync, readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { replayFixedBattle, type FixedLedger } from '../../packages/battle/fixed'
import { advanceStory, startStory } from '../../packages/story/runner'

const root = fileURLToPath(new URL('../..', import.meta.url))

test('Subevent 1 story reaches its fixed Jin battle separately from verification content', () => {
  const content = JSON.parse(readFileSync(join(root, 'content/stories/subevent1-jin.json'), 'utf8')) as ContentPack
  assert.deepEqual(validateContent(content, (path) => existsSync(join(root, path))), { valid: true, issues: [] })
  assert.equal(content.stories.length, 1)
  assert.equal(content.stories[0].id, 'story.subevent1.jin')

  let frame = startStory(content, 'story.subevent1.jin')
  while (frame.step.kind === 'line') frame = advanceStory(content, 'story.subevent1.jin', frame)
  assert.equal(frame.step.kind, 'battle')
  assert.equal(frame.step.id, 'subevent1.jin.await')

  const battle = content.battles.find((entry) => entry.id === frame.step.battle_id)
  assert.ok(battle)
  assert.equal(battle.id, 'battle.subevent1.jin')
  assert.equal(battle.opponent_id, 'jin')
  assert.equal(battle.player_deck_size, 3)
  assert.equal(battle.opponent_deck_size, 3)
  assert.equal(battle.round_limit, 1)
  assert.deepEqual(battle.opponent_card_ids, ['scissors_normal', 'scissors_normal', 'rock_normal'])
  assert.deepEqual(battle.hp && [battle.hp.player, battle.hp.opponent], [1, 1])
  assert.equal(battle.gold_reward.min, 3)
  assert.equal(battle.gold_reward.max, 8)
  assert.notEqual(battle.id, 'battle.thief_jin')

  const tied: FixedLedger = { battle_id: battle.id, player_deck: [
    { hand: 'scissors', grade: 1 }, { hand: 'rock', grade: 1 }, { hand: 'paper', grade: 1 }
  ], rounds: [{ player_index: 0, opponent_index: 0 }], acknowledged: 0, settled: false, balance_before: 0 }
  assert.equal(replayFixedBattle(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, tied).outcome, 'draw')
})
