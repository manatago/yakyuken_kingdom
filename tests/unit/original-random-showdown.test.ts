import assert from 'node:assert/strict'
import test from 'node:test'
import { parseSave } from '../../packages/domain/save'
import { originalStory } from '../../packages/story/original'
import * as random from '../../packages/battle/random'

test('random showdown presentation replays the acknowledged prefix without rewriting the saved result', () => {
  const inventory = ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 })))
  const source = parseSave({ save_version: 1, player: { inventory, deck: inventory, money: 30, items: [] },
    progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: `original:stage1:${originalStory.sequences.find(sequence => sequence.id === 'stage1')!.commands.length}`,
      flags: ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed'] } })
  const encounter = random.enterTown(source, 'guild_street', { encounter: .3, opponent: .3,
    dialogue: [.3, .3, .3, .3], cards: [{ hand: .3, grade: 0 }, { hand: .3, grade: 0 }, { hand: .3, grade: 0 }], drop: .3 })
  const ready = random.acceptTownEncounter(encounter, [inventory[0], inventory[3], inventory[6]])
  const result = random.playRandomBattleRound(ready, 2, .3)
  const snapshot = structuredClone(result)
  assert.equal(random.randomBattleView(result).playerHp, 1)
  assert.equal(random.randomBattleView(result).opponentHp, 0)
  const before = random.randomBattlePreResultView(result)
  assert.equal(before.playerHp, 1)
  assert.equal(before.opponentHp, 1)
  assert.deepEqual(before.usedPlayer, [])
  assert.deepEqual(before.usedOpponent, [])
  assert.equal(before.outcome, undefined)
  assert.deepEqual(result, snapshot)
  assert.throws(() => random.randomBattlePreResultView(ready))
  const draw = random.playRandomBattleRound(ready, 0, .3)
  const acknowledged = random.acknowledgeRandomBattleRound(draw)
  const following = random.playRandomBattleRound(acknowledged, 2, .3)
  const prefix = random.randomBattlePreResultView(following)
  assert.equal(prefix.last?.result, 'draw')
  assert.equal(prefix.playerHp, 1)
  assert.equal(prefix.opponentHp, 1)
  assert.deepEqual(prefix.usedPlayer, [])
  assert.equal(following.progress.random_battle!.rounds.length, 2)
})
