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
  assert.deepEqual(battle.opponent_card_ids, ['scissors_bronze', 'scissors_normal', 'rock_normal'])
  assert.deepEqual(battle.item_reward_ids, ['paper_attract_white', 'rock_break_white'])
  assert.deepEqual(battle.hp && [battle.hp.player, battle.hp.opponent], [1, 1])
  assert.equal(battle.gold_reward.min, 3)
  assert.equal(battle.gold_reward.max, 8)
  assert.notEqual(battle.id, 'battle.thief_jin')

  const tied: FixedLedger = { battle_id: battle.id, player_deck: [
    { hand: 'scissors', grade: 2 }, { hand: 'rock', grade: 1 }, { hand: 'paper', grade: 1 }
  ], rounds: [{ player_index: 0, opponent_index: 0 }], acknowledged: 0, settled: false, balance_before: 0 }
  assert.equal(replayFixedBattle(battle as typeof battle & { hp: NonNullable<typeof battle.hp> }, tied).outcome, 'draw')
})

test('Subevent 1 continues from Jin into the one-match balanced Marco encounter', () => {
  const content = JSON.parse(readFileSync(join(root, 'content/stories/subevent1-jin.json'), 'utf8')) as ContentPack
  const steps = content.stories[0].steps
  const jinAfter = steps.find((step) => step.id === 'subevent1.jin.after')
  assert.equal(jinAfter?.kind, 'line')
  if (jinAfter?.kind !== 'line') throw new Error('Missing Jin victory dialogue')
  assert.equal(jinAfter.next_id, 'subevent1.marco.approach')

  const battle = content.battles.find((entry) => entry.id === 'battle.subevent1.marco')
  assert.ok(battle)
  assert.equal(battle.opponent_id, 'marco')
  assert.equal(battle.player_deck_size, 3)
  assert.equal(battle.opponent_deck_size, 3)
  assert.equal(battle.round_limit, 1)
  assert.deepEqual(battle.opponent_card_ids, ['rock_normal', 'scissors_normal', 'paper_bronze'])
  assert.deepEqual(battle.item_reward_ids, ['substitute_card', 'iron_shield'])
  assert.deepEqual(battle.hp && [battle.hp.player, battle.hp.opponent, battle.hp.lose_gold], [1, 1, 3])
  assert.equal(battle.bayes_eye, true)
  assert.deepEqual(battle.opponent_tendency, {})
  assert.deepEqual([battle.gold_reward.min, battle.gold_reward.max], [5, 10])
  assert.equal(battle.transfer_cards, true)
  assert.equal(battle.result_route, 'guild_home')

  const legacyEnd = steps.find((step) => step.id === 'subevent1.jin.end')
  assert.equal(legacyEnd?.kind, 'end')
})

test('Subevent 1 continues from Marco to Gald with the configured battle and item rewards', () => {
  const content = JSON.parse(readFileSync(join(root, 'content/stories/subevent1-jin.json'), 'utf8')) as any
  const marcoReport = content.stories[0].steps.find((step: any) => step.id === 'subevent1.marco.report')
  assert.equal(marcoReport?.next_id, 'subevent1.gald.approach')

  const battle = content.battles.find((entry: any) => entry.id === 'battle.subevent1.gald')
  assert.ok(battle)
  assert.equal(battle.opponent_id, 'gald')
  assert.equal(battle.player_deck_size, 3)
  assert.equal(battle.opponent_deck_size, 3)
  assert.equal(battle.round_limit, 1)
  assert.deepEqual(battle.opponent_card_ids, ['rock_bronze', 'rock_normal', 'scissors_normal'])
  assert.deepEqual(battle.item_reward_ids, ['scissors_attract_white', 'paper_seal_white'])
  assert.deepEqual([battle.gold_reward.min, battle.gold_reward.max], [8, 15])
  assert.deepEqual(battle.opponent_tendency, { rock: 2 })
  assert.equal(battle.bayes_eye, true)
})

test('Subevent 1 continues from Gald to the story Belka boss and returns after the aftermath', () => {
  const content = JSON.parse(readFileSync(join(root, 'content/stories/subevent1-jin.json'), 'utf8')) as ContentPack
  const steps = content.stories[0].steps
  const galdReport = steps.find((step) => step.id === 'subevent1.gald.report')
  assert.equal(galdReport?.kind, 'line')
  if (galdReport?.kind !== 'line') throw new Error('Missing Gald aftermath')
  assert.equal(galdReport.next_id, 'subevent1.belka.approach')
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.await')?.kind, 'battle')
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.after')?.kind, 'line')
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.end')?.kind, 'end')

  const battle = content.battles.find((entry) => entry.id === 'battle.subevent1.belka')
  assert.ok(battle)
  assert.equal(battle.opponent_id, 'belka')
  assert.equal(battle.player_deck_size, 9)
  assert.equal(battle.opponent_deck_size, 9)
  assert.equal(battle.transfer_cards, true)
  assert.equal(battle.bayes_eye, true)
  assert.deepEqual(battle.hp && [battle.hp.player, battle.hp.opponent, battle.hp.lose_gold], [3, 3, 25])
  assert.deepEqual(battle.opponent_tendency, { paper: 0.4 })
  assert.deepEqual([battle.gold_reward.min, battle.gold_reward.max], [40, 60])
  assert.deepEqual(battle.item_reward_ids, ['greed_ring', 'rock_attract_crimson'])
})
