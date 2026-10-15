import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { canEnterTown, enterTown, returnToGuildFromTown } from '../../packages/battle/random'
import { completeOriginalStage1Story } from '../../packages/story/original-flow'
import { ORIGINAL_STAGE1_END } from '../../packages/guild/routes'
import { createOriginalAdventurer, stepOriginalAdventurer, continueOriginalAdventurer, finishOriginalAdventurerSave } from '../../packages/story/original-adventurer'

test('original adventurer settlement records completion without granting the deferred item', () => {
  let state = createOriginalAdventurer()
  while (state.phase !== 'reward') state = state.phase === 'running' ? stepOriginalAdventurer(state, 0) : continueOriginalAdventurer(state)
  const initial = createNewGameSave()
  const paid = finishOriginalAdventurerSave({ ...initial, progress: { ...initial.progress,
    checkpoint_id: 'original:stage1:113', original_adventurer: state } })
  assert.ok(paid.progress.flags.includes('adventurer.tutorial.completed'))
  assert.deepEqual(paid.player.items, initial.player.items)
  assert.equal(paid.player.inventory.length, 10)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(paid))), paid)
})

test('both original tutorials permit town travel and return without fabricating old battle ledgers', () => {
  const initial = createNewGameSave()
  const source = completeOriginalStage1Story({ ...initial, progress: { ...initial.progress,
    checkpoint_id: ORIGINAL_STAGE1_END, flags: ['original.matilda.tutorial.completed', 'adventurer.tutorial.completed'] } })
  assert.equal(canEnterTown(source), true)
  const rolls = { encounter: .99, opponent: 0,
    cards: [{ hand: 0, grade: 0 }, { hand: .5, grade: 0 }, { hand: .99, grade: 0 }] as const, drop: 0 }
  const town = enterTown(source, 'guild_street', rolls)
  assert.equal(town.progress.checkpoint_id, 'town.area')
  assert.equal(town.progress.town_origin_checkpoint, ORIGINAL_STAGE1_END)
  assert.equal(town.progress.tutorial, undefined)
  assert.equal(town.progress.fixed_battle, undefined)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(town))), town)
  assert.deepEqual(returnToGuildFromTown(town), source)
  for (const flags of [[], ['original.matilda.tutorial.completed'], ['adventurer.tutorial.completed']]) {
    const incomplete = { ...source, progress: { ...source.progress, flags } }
    assert.equal(canEnterTown(incomplete), false)
    assert.throws(() => enterTown(incomplete, 'guild_street', rolls))
  }
})
