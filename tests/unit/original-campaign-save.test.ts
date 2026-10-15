import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/godot-original.json'
import campaign from '../../content/stories/godot-campaign-battles.json'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { startOriginalQuestBattleSave, setOriginalQuestBattleDraft, prepareOriginalQuestBattleSave } from '../../packages/story/original-quest-save'
import { updateOriginalQuestBattleSave, settleOriginalQuestBattleSave, beginOriginalQuestAftermath, resumeOriginalQuestAfterVictory } from '../../packages/story/original-quest-save'
import { stepOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, continueOriginalQuestRuntime } from '../../packages/story/original-quest-runtime'

test('campaign battles without a quest save the selected initial/rematch variant and owned draft', () => {
  for (const chapter of campaign.chapters) {
    const sequence = document.sequences.find(sequence => sequence.commands.some(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path))!
    const cursor = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path) + 1
    const initial = createNewGameSave()
    initial.progress = { ...initial.progress, checkpoint_id: `original:${sequence.id}:${cursor}`, flags: chapter.first_battle ? [] : [chapter.flag_key] }
    const drafted = setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), [0,1,2,3,4,5,6,7,8])
    const saved = prepareOriginalQuestBattleSave(drafted)
    assert.equal(saved.progress.original_quest_battle!.chapter_id, `campaign:${chapter.opponent_id}:${chapter.first_battle ? 'initial' : 'rematch'}`)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(saved))), saved)
    assert.deepEqual(saved.player, parseSave(initial).player)
    assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress, flags: chapter.first_battle ? [chapter.flag_key] : [] } }))
    assert.throws(() => parseSave({ ...saved, progress: { ...saved.progress,
      original_completed_battles: [saved.progress.checkpoint_id] } }), /completed/i)
  }
})

test('campaign rematch loss with no farewell returns to Guild without invented dialogue', () => {
  for (const chapter of campaign.chapters.filter(chapter => !chapter.first_battle)) {
    const sequence = document.sequences.find(sequence => sequence.commands.some(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path))!
    const cursor = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path) + 1
    const initial = createNewGameSave()
    initial.player.inventory = Array.from({ length: 9 }, () => ({ hand: 'rock', grade: 1 }))
    initial.progress = { ...initial.progress, checkpoint_id: `original:${sequence.id}:${cursor}`, flags: [chapter.flag_key] }
    let save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), [0,1,2,3,4,5,6,7,8]))
    for (let step = 0; step < 300 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; step++) {
      const state = save.progress.original_quest_battle!.runtime!
      save = updateOriginalQuestBattleSave(save, state.phase === 'running' ? stepOriginalQuestRuntime(state, 0.999)
        : state.phase === 'selection' ? chooseOriginalQuestRuntimeCard(state, state.battle.playerUsed.findIndex(used => !used))
        : continueOriginalQuestRuntime(state))
    }
    assert.equal(save.progress.original_quest_battle!.runtime!.outcome, 'lose')
    const settled = settleOriginalQuestBattleSave(save, 0)
    const next = beginOriginalQuestAftermath(settled, 0)
    assert.equal(next.progress.checkpoint_id, 'guild.home')
    assert.equal(next.progress.original_quest_battle, undefined)
    assert.equal(next.progress.original_last_lose_narration, undefined)
    assert.deepEqual(next.player, settled.player)
  }
})

test('campaign initial defeats continue raw story and rematch victories grant original rewards only once', () => {
  for (const chapter of campaign.chapters) {
    const sequence = document.sequences.find(sequence => sequence.commands.some(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path))!
    const cursor = sequence.commands.findIndex(command => command.kind === 'battle' && command.parameters.chapter_path === chapter.chapter_path) + 1
    const initial = createNewGameSave()
    initial.player.inventory = Array.from({ length: 9 }, () => ({ hand: 'rock', grade: chapter.first_battle ? 1 : 5 }))
    initial.progress = { ...initial.progress, checkpoint_id: `original:${sequence.id}:${cursor}`, flags: chapter.first_battle ? [] : [chapter.flag_key] }
    let save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(initial), [0,1,2,3,4,5,6,7,8]))
    for (let step = 0; step < 300 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; step++) {
      const state = save.progress.original_quest_battle!.runtime!
      save = updateOriginalQuestBattleSave(save, state.phase === 'running' ? stepOriginalQuestRuntime(state, 0)
        : state.phase === 'selection' ? chooseOriginalQuestRuntimeCard(state, state.battle.playerUsed.findIndex(used => !used))
        : continueOriginalQuestRuntime(state))
    }
    assert.equal(save.progress.original_quest_battle!.runtime!.outcome, chapter.first_battle ? 'lose' : 'win')
    const settled = settleOriginalQuestBattleSave(save, 0)
    assert.throws(() => settleOriginalQuestBattleSave(settled, 0))
    const next = chapter.first_battle ? beginOriginalQuestAftermath(settled, 0) : resumeOriginalQuestAfterVictory(settled)
    assert.equal(next.progress.checkpoint_id, initial.progress.checkpoint_id)
    assert.equal(next.progress.original_quest_battle, undefined)
    assert.deepEqual(next.progress.original_completed_battles, [initial.progress.checkpoint_id])
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(next))), next)
    if (!chapter.first_battle) {
      const reward = chapter.card_reward as { hand?: string; grade?: number }
      const captures = chapter.can_gain_cards ? save.progress.original_quest_battle!.runtime!.battle.rounds.filter(round => round.result === 'win').length : 0
      assert.equal(next.player.inventory.length, 9 + captures + (reward.hand ? 1 : 0))
      assert.deepEqual(next.player.items, chapter.item_rewards)
      assert.equal(next.player.money, chapter.gold_reward.min)
    }
  }
})
