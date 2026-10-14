import assert from 'node:assert/strict'
import test from 'node:test'
import { parseSave, type SaveData } from '../../packages/domain/save'
import * as normal from '../../packages/story/original-normal'
import { originalStory, restoreOriginalStoryState } from '../../packages/story/original'
import { beginOriginalMatildaAftermath, checkpointOriginalMatildaAftermath,
  chooseOriginalMatildaAftermath, validateOriginalMatildaAftermath, originalMatildaAftermathIncomingScene,
  originalMainIncomingScene } from '../../packages/story/original-matilda-aftermath-save'

function finished(winning: boolean): SaveData {
  const deck = Array.from({ length: 9 }, () => ({ hand: winning ? 'paper' as const : 'scissors' as const, grade: 1 as const }))
  let state = normal.prepareOriginalNormal(normal.createOriginalNormal(deck, 20), deck)
  while (state.phase !== 'finished') {
    if (state.phase === 'running') state = normal.stepOriginalNormal(state, 0)
    else if (state.phase === 'selection') state = normal.chooseOriginalNormalCard(state, state.battle.playerUsed.findIndex(used => !used))
    else state = normal.continueOriginalNormal(state)
  }
  return parseSave({ save_version: 1, player: { money: 20, deck: [], inventory: deck, items: [] },
    progress: { checkpoint_id: 'original:prologue:234', flags: [], original_normal: state } })
}

function complete(save: SaveData) {
  const ledger = save.progress.original_matilda_aftermath!
  const length = originalStory.sequences.find(sequence => sequence.id === ledger.flow.sequenceId)!.commands.length
  return checkpointOriginalMatildaAftermath(save, length, true)
}

test('Matilda loss settles once, resumes the redirect and preserves source same-chapter retry', () => {
  const initial = finished(false)
  const snapshot = structuredClone(initial)
  let save = beginOriginalMatildaAftermath(initial)
  assert.equal(save.player.money, 10)
  assert.equal(save.progress.original_matilda_aftermath!.flow.phase, 'redirect-story')
  assert.throws(() => beginOriginalMatildaAftermath(save))
  assert.throws(() => chooseOriginalMatildaAftermath(save, 'retry'))
  save = checkpointOriginalMatildaAftermath(save, 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.throws(() => checkpointOriginalMatildaAftermath(save, 0))
  const choices = complete(save)
  const retry = chooseOriginalMatildaAftermath(choices, 'retry')
  assert.equal(retry.progress.checkpoint_id, 'original:prologue:234')
  assert.equal(retry.progress.original_matilda_aftermath, undefined)
  assert.equal(retry.progress.original_normal!.playback.repeated, true)
  assert.equal(retry.progress.original_normal!.balanceBefore, 10)
  assert.deepEqual(retry.player, choices.player)
  assert.deepEqual(initial, snapshot)
})

test('Matilda home replays the loss conversation and result retry is a fresh chapter', () => {
  const loss = complete(beginOriginalMatildaAftermath(finished(false)))
  const home = chooseOriginalMatildaAftermath(loss, 'home')
  assert.equal(home.progress.original_matilda_aftermath!.flow.phase, 'aftermath-story')
  assert.equal(home.progress.original_matilda_aftermath!.cursor, 0)
  assert.equal(home.player.money, 10)
  assert.deepEqual(parseSave(home), home)
  const result = complete(home)
  const retry = chooseOriginalMatildaAftermath(result, 'retry')
  assert.equal(retry.progress.original_normal!.playback.repeated, false)
  assert.equal(retry.progress.original_normal!.actions.length, 0)
  const title = chooseOriginalMatildaAftermath(result, 'title')
  assert.equal(title.progress.checkpoint_id, 'original:stage1:0')
  assert.equal(title.player.money, 10)
})

test('Matilda win follows source result choices and tampered money, cursor or phase are rejected', () => {
  const save = beginOriginalMatildaAftermath(finished(true))
  assert.equal(save.player.money, 30)
  assert.equal(save.progress.original_matilda_aftermath!.flow.phase, 'aftermath-story')
  const completeSave = complete(save)
  assert.equal(chooseOriginalMatildaAftermath(completeSave, 'next').progress.checkpoint_id, 'original:stage1:0')
  assert.equal(chooseOriginalMatildaAftermath(completeSave, 'title').progress.checkpoint_id, 'original:stage1:0')
  assert.throws(() => parseSave({ ...save, player: { ...save.player, money: 31 } }))
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'original:prologue_battle_win:1' } }))
  assert.throws(() => validateOriginalMatildaAftermath({ ...save.progress.original_matilda_aftermath,
    flow: { ...save.progress.original_matilda_aftermath!.flow, phase: 'aftermath-choice' } }, save.progress.checkpoint_id, save.player, save.progress.flags))
})

test('Matilda aftermath and Stage 1 retain the actual reused source StoryScene on resume', () => {
  const save = beginOriginalMatildaAftermath(finished(true))
  const incoming = originalMatildaAftermathIncomingScene(save)!
  const preBattle = restoreOriginalStoryState('prologue', 234)
  assert.deepEqual(incoming.portraits, preBattle.portraits)
  const first = restoreOriginalStoryState('prologue_battle_win', 3, incoming.flags, incoming)
  assert.equal(first.portraits.main.visible, true)
  const completeSave = complete(save)
  const stage1 = chooseOriginalMatildaAftermath(completeSave, 'next')
  assert.equal(stage1.progress.original_story_origin, 'prologue_battle_win')
  const retained = originalMainIncomingScene(parseSave(JSON.parse(JSON.stringify(stage1))))!
  assert.equal(retained.portraits.main.portrait_id, 'res://assets/characters/main/satoshi/isekai/satoshi_isekai_055.png')
  assert.equal(retained.background, first.background)
  assert.equal(retained.text, originalStory.sequences.find(s => s.id === 'prologue_battle_win')!.commands.at(-1)!.parameters.text)
  const home = chooseOriginalMatildaAftermath(complete(beginOriginalMatildaAftermath(finished(false))), 'home')
  const lossIncoming = originalMatildaAftermathIncomingScene(parseSave(JSON.parse(JSON.stringify(home))))!
  assert.equal(lossIncoming.text, originalStory.sequences.find(s => s.id === 'prologue_battle_lose')!.commands.at(-1)!.parameters.text)
  assert.throws(() => parseSave({ ...stage1, progress: { ...stage1.progress, original_story_origin: 'stage7' } }))
  for (const invalid of [['prologue_battle_win'], null, {}]) {
    assert.throws(() => parseSave({ ...stage1, progress: { ...stage1.progress, original_story_origin: invalid } }))
  }
  assert.throws(() => parseSave({ ...stage1, progress: { ...stage1.progress, checkpoint_id: 'original:subevent1_pre:0' } }))
})
