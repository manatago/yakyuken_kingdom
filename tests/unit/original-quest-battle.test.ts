import assert from 'node:assert/strict'
import test from 'node:test'
import { originalQuestBattleChapters, createOriginalQuestBattle, nextOriginalQuestBattleCommand, advanceOriginalQuestBattleCommand } from '../../packages/story/original-quest-battle'

test('quest battle configuration retains current Godot grades, rewards and loss routing', () => {
  const jin = originalQuestBattleChapters.find(chapter => chapter.opponent_id === 'jin')!
  assert.equal(jin.opponent_deck[0].grade, 2)
  assert.deepEqual(jin.item_rewards, ['paper_attract_white', 'rock_break_white'])
  assert.equal(jin.lose_behavior, 'abort')
  assert.deepEqual(jin.lose_redirect, { type: 'guild_home' })
  assert.equal(jin.player_deck_size, 3)
  assert.equal(originalQuestBattleChapters.find(chapter => chapter.opponent_id === 'marco')!.opponent_deck[2].grade, 2)
  assert.equal(originalQuestBattleChapters.find(chapter => chapter.opponent_id === 'gald')!.opponent_deck[0].grade, 2)
})

test('canonical quest export includes Sister, Fiona and Receptionist with their original defeat destinations', () => {
  for (const [id, sequence] of [['sister_head', 'subevent2_battle_lose'], ['fiona', 'subevent3_battle_lose']] as const) {
    const chapter = originalQuestBattleChapters.find(chapter => chapter.opponent_id === id)
    assert.ok(chapter, `Missing original ${id} chapter`)
    assert.equal(chapter.lose_redirect.sequence_id, sequence)
  }
  assert.ok(originalQuestBattleChapters.some(chapter => chapter.opponent_id === 'receptionist'))
})

test('all quest outfit branches replay raw commands without treating fixture results as rules', () => {
  for (const chapter of originalQuestBattleChapters) {
    for (const trace of chapter.traces) {
      let playback = createOriginalQuestBattle(chapter.opponent_id, Number(trace.method.slice(-1)))
      for (const raw of trace.commands) {
        const command = nextOriginalQuestBattleCommand(chapter.opponent_id, playback)!
        assert.deepEqual(command, raw.kind === 'janken' ? { ...raw, args: raw.args.slice(0, 2) } : raw)
        if (command.kind === 'janken') {
          assert.throws(() => advanceOriginalQuestBattleCommand(chapter.opponent_id, playback))
          playback = advanceOriginalQuestBattleCommand(chapter.opponent_id, playback, trace.outcomes[0])
        } else playback = advanceOriginalQuestBattleCommand(chapter.opponent_id, playback)
      }
      assert.equal(nextOriginalQuestBattleCommand(chapter.opponent_id, playback), undefined)
      assert.throws(() => advanceOriginalQuestBattleCommand(chapter.opponent_id, playback))
    }
  }
  assert.throws(() => createOriginalQuestBattle('unknown', 1))
  assert.throws(() => createOriginalQuestBattle('jin', 3))
  assert.throws(() => nextOriginalQuestBattleCommand('jin', { method: 'outfit_1', cursor: 0, repeated: false, results: ['win'] }))
})
