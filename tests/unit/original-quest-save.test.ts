import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { ORIGINAL_STAGE1_END } from '../../packages/guild/routes'
import { startOriginalQuestBattleSave, setOriginalQuestBattleDraft, prepareOriginalQuestBattleSave, updateOriginalQuestBattleSave, settleOriginalQuestBattleSave, resumeOriginalQuestAfterVictory,
  beginOriginalQuestAftermath, originalQuestAftermathFrames, advanceOriginalQuestAftermath } from '../../packages/story/original-quest-save'
import { stepOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, continueOriginalQuestRuntime } from '../../packages/story/original-quest-runtime'
import { useOriginalQuestBattleItemSave, originalQuestLossRedirect, checkpointOriginalQuestLossRedirect } from '../../packages/story/original-quest-save'
import document from '../../content/stories/godot-original.json'

function source(): SaveData {
  const initial = createNewGameSave()
  return { ...initial, player: { ...initial.player, money: 20 }, progress: { ...initial.progress,
    checkpoint_id: 'original:subevent1_hideout:24', original_quest: { id: 'subevent1', origin_checkpoint: ORIGINAL_STAGE1_END, route: 'full' } } }
}

test('all exported normal quest battles can draft and resume in their own original route', () => {
  for (const [id, sequence, opponent] of [
    ['subevent2', 'subevent2_pre2', 'sister_head'],
    ['subevent2', 'subevent2_rematch', 'sister_head'],
    ['subevent3', 'subevent3_visit', 'fiona'],
    ['subevent4', 'subevent4_post', 'receptionist']
  ] as const) {
    const commands = document.sequences.find(s => s.id === sequence)!.commands
    const index = commands.findIndex(c => c.kind === 'battle' && !c.parameters.is_minigame)
    const initial = source()
    const completed = commands.flatMap((c, i) => c.kind === 'battle' && i < index ? [`original:${sequence}:${i + 1}`] : [])
    initial.progress = { ...initial.progress, checkpoint_id: `original:${sequence}:${index + 1}`,
      original_quest: { id, origin_checkpoint: ORIGINAL_STAGE1_END, route: sequence.endsWith('rematch') ? 'rematch' : 'full', completed_battles: completed } }
    const save = startOriginalQuestBattleSave(initial)
    assert.equal(save.progress.original_quest_battle!.chapter_id, opponent)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
    assert.deepEqual(save.player, initial.player)
  }
})

function defeatedQuest(id: 'subevent2' | 'subevent3' | 'subevent4'): SaveData {
  const sequence = { subevent2: 'subevent2_pre2', subevent3: 'subevent3_visit', subevent4: 'subevent4_post' }[id]
  const commands = document.sequences.find(s => s.id === sequence)!.commands
  const index = commands.findIndex(c => c.kind === 'battle' && !c.parameters.is_minigame)
  const initial = source()
  initial.player.inventory = Array.from({ length: 9 }, () => ({ hand: 'scissors', grade: 1 }))
  initial.player.deck = []
  initial.progress = { ...initial.progress, checkpoint_id: `original:${sequence}:${index + 1}`, original_quest: {
    id, route: 'full', origin_checkpoint: ORIGINAL_STAGE1_END,
    completed_battles: commands.flatMap((c, i) => c.kind === 'battle' && i < index ? [`original:${sequence}:${i + 1}`] : []) } }
  let save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), [0,1,2,3,4,5,6,7,8]))
  for (let i = 0; i < 300 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; i++) {
    const state = save.progress.original_quest_battle!.runtime!
    const next = state.phase === 'running' ? stepOriginalQuestRuntime(state, 0)
      : state.phase === 'selection' ? chooseOriginalQuestRuntimeCard(state, state.battle.playerUsed.findIndex(used => !used))
      : continueOriginalQuestRuntime(state)
    save = updateOriginalQuestBattleSave(save, next)
  }
  assert.equal(save.progress.original_quest_battle!.runtime!.outcome, 'lose')
  return beginOriginalQuestAftermath(settleOriginalQuestBattleSave(save, 0), 0)
}

test('Sister and Fiona preserve raw loss scene checkpoints before common loss and Guild Home', () => {
  for (const id of ['subevent2', 'subevent3'] as const) {
    let save = defeatedQuest(id)
    for (let i = 0; i < 10 && !originalQuestLossRedirect(save); i++) save = advanceOriginalQuestAftermath(save)
    const redirect = originalQuestLossRedirect(save)!
    assert.equal(redirect.sequenceId, `${id}_battle_lose`)
    assert.equal(redirect.cursor, 0)
    assert.throws(() => advanceOriginalQuestAftermath(save))
    const length = document.sequences.find(s => s.id === redirect.sequenceId)!.commands.length
    const before = structuredClone(save)
    save = checkpointOriginalQuestLossRedirect(save, 5, save.progress.flags)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
    assert.equal(originalQuestLossRedirect(save)!.cursor, 5)
    assert.equal(before.progress.original_quest_battle!.aftermath!.redirect_cursor, undefined)
    assert.throws(() => checkpointOriginalQuestLossRedirect(save, 4, save.progress.flags))
    assert.throws(() => checkpointOriginalQuestLossRedirect(save, length + 1, save.progress.flags))
    save = checkpointOriginalQuestLossRedirect(save, length, save.progress.flags)
    assert.equal(originalQuestLossRedirect(save)!.cursor, length)
    assert.throws(() => advanceOriginalQuestAftermath(save))
    save = checkpointOriginalQuestLossRedirect(save, length, save.progress.flags, true)
    assert.equal(originalQuestLossRedirect(save), undefined)
    if (id === 'subevent3') assert.ok(originalQuestAftermathFrames(save.progress.original_quest_battle!).some(frame => frame.text.includes('セバス')))
    for (let i = 0; i < 20 && save.progress.original_quest_battle; i++) save = advanceOriginalQuestAftermath(save)
    assert.equal(save.progress.checkpoint_id, 'guild.home')
    assert.equal(save.progress.original_quest, undefined)
    assert.equal(save.progress.flags.includes(`${id}_complete`), false)
  }
})

test('Receptionist loss with empty farewell resumes the original next command without an invented page', () => {
  const save = defeatedQuest('subevent4')
  const checkpoint = save.progress.checkpoint_id
  assert.equal(originalQuestLossRedirect(save), undefined)
  assert.equal(save.progress.checkpoint_id, checkpoint)
  assert.deepEqual(save.progress.original_quest!.completed_battles, [checkpoint])
  assert.equal(save.progress.original_quest_battle, undefined)
  assert.equal(save.progress.original_last_lose_narration, undefined)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
})

test('canonical battle draft and real round checkpoints persist without changing owned cards', () => {
  const initial = parseSave(source())
  let save = startOriginalQuestBattleSave(initial)
  assert.equal(save.progress.original_quest_battle!.chapter_id, 'jin')
  assert.deepEqual(save.player, initial.player)
  save = setOriginalQuestBattleDraft(save, [6, 7, 8])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  const drafting = structuredClone(save)
  save = prepareOriginalQuestBattleSave(save)
  for (let count = 0; count < 30 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; count++) {
    const runtime = save.progress.original_quest_battle!.runtime!
    const next = runtime.phase === 'running' ? stepOriginalQuestRuntime(runtime, 0)
      : runtime.phase === 'selection' ? chooseOriginalQuestRuntimeCard(runtime, 0) : continueOriginalQuestRuntime(runtime)
    save = updateOriginalQuestBattleSave(save, next)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  }
  assert.equal(save.progress.original_quest_battle!.runtime!.outcome, 'win')
  assert.deepEqual(save.player, initial.player)
  assert.equal(drafting.progress.original_quest_battle!.runtime, undefined)
  assert.throws(() => setOriginalQuestBattleDraft(drafting, [0, 0, 0]))
  assert.throws(() => prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(drafting, [0])))
  assert.throws(() => parseSave({ ...save, player: { ...save.player, money: 21 } }))
  assert.throws(() => startOriginalQuestBattleSave({ ...initial, progress: { ...initial.progress, checkpoint_id: 'original:subevent1_hideout:25' } }))
  assert.throws(() => updateOriginalQuestBattleSave(save, { ...save.progress.original_quest_battle!.runtime!, battle: { ...save.progress.original_quest_battle!.runtime!.battle, playerHp: 10 } }))
})

test('original quest equipment and selected consumables survive replay and settle only their real captures', () => {
  const initial = parseSave({ ...source(), player: { ...source().player, equipment: ['greed_ring'], items: ['iron_shield', 'substitute_card'] } })
  let save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), [6, 7, 8]))
  while (save.progress.original_quest_battle!.runtime!.phase !== 'selection') {
    const state = save.progress.original_quest_battle!.runtime!
    save = updateOriginalQuestBattleSave(save, state.phase === 'running' ? stepOriginalQuestRuntime(state, 0) : continueOriginalQuestRuntime(state))
  }
  save = useOriginalQuestBattleItemSave(save, 'iron_shield')
  assert.deepEqual(save.player.items, ['substitute_card'])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  save = useOriginalQuestBattleItemSave(save, 'iron_shield')
  assert.deepEqual(save.player.items, initial.player.items)
  save = useOriginalQuestBattleItemSave(save, 'substitute_card')
  assert.deepEqual(save.player.items, ['iron_shield'])
  assert.throws(() => useOriginalQuestBattleItemSave(save, 'paper_attract_gold'))
  save = updateOriginalQuestBattleSave(save, chooseOriginalQuestRuntimeCard(save.progress.original_quest_battle!.runtime!, 0))
  while (save.progress.original_quest_battle!.runtime!.phase !== 'finished') {
    const state = save.progress.original_quest_battle!.runtime!
    save = updateOriginalQuestBattleSave(save, state.phase === 'running' ? stepOriginalQuestRuntime(state, 0, .99) : continueOriginalQuestRuntime(state))
  }
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.equal(save.progress.original_quest_battle!.runtime!.battle.opponentUsed.filter(Boolean).length, 2)
  const settled = settleOriginalQuestBattleSave(save, 0)
  assert.equal(settled.player.inventory.length, 11)
  assert.deepEqual(settled.player.items, ['iron_shield', 'paper_attract_white', 'rock_break_white'])
  assert.deepEqual(initial.player.items, ['iron_shield', 'substitute_card'])
})

test('quest rewards settle once, preserve the pre-battle snapshot, and loss removes only one matching copy', () => {
  for (const winning of [true, false]) {
    const initial = parseSave(source())
    let save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), winning ? [6, 7, 8] : [3, 4, 5]))
    assert.throws(() => settleOriginalQuestBattleSave(save, 0))
    for (let count = 0; count < 30 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; count++) {
      const runtime = save.progress.original_quest_battle!.runtime!
      const next = runtime.phase === 'running' ? stepOriginalQuestRuntime(runtime, 0)
        : runtime.phase === 'selection' ? chooseOriginalQuestRuntimeCard(runtime, 0) : continueOriginalQuestRuntime(runtime)
      save = updateOriginalQuestBattleSave(save, next)
    }
    const previous = structuredClone(save)
    const settled = settleOriginalQuestBattleSave(save, 0)
    assert.equal(settled.player.money, winning ? 23 : 18)
    assert.equal(settled.player.inventory.length, winning ? 10 : 8)
    assert.deepEqual(settled.player.items, winning ? ['paper_attract_white', 'rock_break_white'] : [])
    assert.equal(settled.progress.original_quest_battle!.settlement!.gold, winning ? 3 : -2)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
    // Godot emits grade before hand; parsed saves emit hand before grade.
    const reordered = structuredClone(settled)
    reordered.player.inventory = reordered.player.inventory.map(card => ({ grade: card.grade, hand: card.hand }))
    assert.deepEqual(parseSave(reordered), settled)
    const changed = structuredClone(reordered)
    changed.player.inventory[0].grade = 2
    assert.throws(() => parseSave(changed))
    assert.deepEqual(save, previous)
    assert.throws(() => settleOriginalQuestBattleSave(settled, 0))
    assert.throws(() => parseSave({ ...settled, player: { ...settled.player, money: 999 } }))
    if (winning) {
      const resumed = resumeOriginalQuestAfterVictory(settled)
      assert.equal(resumed.progress.checkpoint_id, settled.progress.checkpoint_id)
      assert.equal(resumed.progress.original_quest_battle, undefined)
      assert.deepEqual(resumed.progress.original_quest?.completed_battles, [settled.progress.checkpoint_id])
      assert.deepEqual(resumed.player, settled.player)
      assert.deepEqual(parseSave(JSON.parse(JSON.stringify(resumed))), resumed)
      assert.throws(() => resumeOriginalQuestAfterVictory(resumed))
    } else {
      assert.throws(() => resumeOriginalQuestAfterVictory(settled))
      let aftermath = beginOriginalQuestAftermath(settled, 0.99)
      const frames = originalQuestAftermathFrames(aftermath.progress.original_quest_battle!)
      assert.equal(frames[0].text, 'サトシは盗賊ジンに敗北した。\nこれ以上先に進むのは危険だ...。')
      assert.equal(frames[1].text, 'へっ！ 雑魚が！ 出直してこい！')
      assert.ok(frames.length > 2)
      assert.throws(() => beginOriginalQuestAftermath(aftermath, 0))
      for (let index = 0; index < frames.length; index++) {
        assert.equal(aftermath.progress.original_quest_battle!.aftermath!.cursor, index)
        assert.deepEqual(parseSave(JSON.parse(JSON.stringify(aftermath))), aftermath)
        aftermath = advanceOriginalQuestAftermath(aftermath)
      }
      assert.equal(aftermath.progress.checkpoint_id, 'guild.home')
      assert.equal(aftermath.progress.guild_return_checkpoint, ORIGINAL_STAGE1_END)
      assert.equal(aftermath.player.money, 0)
      assert.equal(aftermath.progress.original_quest_battle, undefined)
      assert.equal(aftermath.progress.original_quest, undefined)
      assert.equal(aftermath.progress.flags.includes('sub1_cleared'), false)
    }
  }
})
