import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome, leaveGuildHome, GUILD_CHECKPOINT } from '../../packages/guild/home'
import { savePreparedDeck } from '../../packages/domain/deck-editing'

function completed(): SaveData {
  const initial = createInitialGameSave()
  let save = prepareTutorial({ ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.end' } })
}

function normalEnd(): SaveData {
  const source = completed()
  let save = prepareFixedBattle({ ...source, progress: { ...source.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } })
}

test('guild entry, save/reload and return preserve both completed confirmation records', () => {
  for (const source of [completed(), normalEnd()]) {
    const before = structuredClone(source)
    const home = enterGuildHome(source)
    assert.equal(home.progress.checkpoint_id, GUILD_CHECKPOINT)
    assert.equal(home.progress.guild_return_checkpoint, source.progress.checkpoint_id)
    assert.deepEqual(home.player, source.player)
    assert.deepEqual(home.progress.tutorial, source.progress.tutorial)
    assert.deepEqual(home.progress.fixed_battle, source.progress.fixed_battle)
    assert.deepEqual(leaveGuildHome(parseSave(JSON.parse(JSON.stringify(home)))), source)
    assert.deepEqual(source, before)
    assert.throws(() => enterGuildHome(home))
    assert.throws(() => leaveGuildHome(source))
    assert.deepEqual(parseSave(source), source)
  }
})

test('guild card editing changes only the next-battle lineup', () => {
  const home = enterGuildHome(normalEnd())
  const edited = savePreparedDeck(home, [...home.player.inventory].reverse())
  assert.deepEqual(parseSave(edited), edited)
  assert.deepEqual(edited.progress, home.progress)
  assert.deepEqual(edited.player.deck, home.player.deck)
  assert.deepEqual(edited.player.inventory, home.player.inventory)
  assert.equal(edited.player.money, home.player.money)
  assert.deepEqual(leaveGuildHome(edited).player.prepared_deck, edited.player.prepared_deck)
})

test('guild rejects unfinished entry, absent/forged/orphaned return metadata and wrong ledger origin', () => {
  assert.throws(() => enterGuildHome(createInitialGameSave()))
  const home = enterGuildHome(completed())
  for (const mutate of [
    (s: any) => { delete s.progress.guild_return_checkpoint },
    (s: any) => { s.progress.guild_return_checkpoint = 'matilda.await-deck' },
    (s: any) => { s.progress.guild_return_checkpoint = 'matilda.normal.end' },
    (s: any) => { s.progress.guild_return_checkpoint = 1 },
    (s: any) => { s.progress.checkpoint_id = 'matilda.end' },
    (s: any) => { delete s.progress.tutorial },
    (s: any) => { s.progress.tutorial.acknowledged = 1 }
  ]) {
    const bad = structuredClone(home)
    mutate(bad)
    assert.throws(() => parseSave(bad))
  }
  const settledHome = enterGuildHome(normalEnd())
  assert.throws(() => parseSave({ ...settledHome, progress: { ...settledHome.progress, guild_return_checkpoint: 'matilda.end' } }))
  const source = completed()
  const unfinished = prepareFixedBattle({ ...source, progress: { ...source.progress, checkpoint_id: 'matilda.normal.await' } })
  assert.throws(() => enterGuildHome(unfinished))
  assert.throws(() => parseSave({ ...unfinished, progress: { ...unfinished.progress, checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: 'matilda.normal.end' } }))
})
