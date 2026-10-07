import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/stage5.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { canRetryStage5Battle, canStartStage5, continueStage5Minigame, finishStage5Story, startStage5 } from '../../packages/battle/stage5'
import { beginStage5Minigame, chooseStage5Response, continueStage5Minigame, parseStage5Minigame,
  validateStage5MinigameState, STAGE5_GAUGE_MAX } from '../../packages/battle/stage5-minigame'
import { fixedContent, prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView,
  returnFromFixedBattle } from '../../packages/battle/fixed'
import { retryFixedBattle } from '../../packages/battle/fixed'
import { loseFixedBattleAndReturn, recoverCardsThroughTown } from '../helpers/fixed-battle-loss'

const content = document as ContentPack

function winFixedBattle(source: ReturnType<typeof prepareFixedBattle>) {
  let save = source
  while (!fixedView(save).outcome) {
    const view = fixedView(save), ledger = save.progress.fixed_battle!
    let winningRound: ReturnType<typeof playFixedRound> | undefined
    for (let index = 0; index < ledger.player_deck.length && !winningRound; index++) {
      if (view.usedPlayer.includes(index)) continue
      for (let step = 0; step < 1000; step++) {
        const candidate = playFixedRound(save, index, step / 1000)
        if (fixedView(candidate).last?.result === 'win') { winningRound = candidate; break }
      }
    }
    assert.ok(winningRound, 'a winning player/opponent pairing must exist in the rematch')
    save = winningRound!
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'win')
  return returnFromFixedBattle(save)
}

function readySave() {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = { ...save, player: { ...save.player, inventory: [...save.player.inventory,
    ...Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const }))] },
    progress: { ...save.progress, checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.end',
    flags: [...save.progress.flags, 'stage2_complete', 'stage3_complete', 'stage4_complete'] } }
  return parseSave(save)
}

function settleFirstBattle(save: ReturnType<typeof readySave>) {
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.interrogation.battle' } })
  while (!fixedView(save).outcome) {
    const view = fixedView(save), ledger = save.progress.fixed_battle!
    const index = ledger.player_deck.findIndex((_, cardIndex) => !view.usedPlayer.includes(cardIndex))
    save = playFixedRound(save, index, 0.5)
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  return returnFromFixedBattle(save)
}

test('Stage 5 content validates, requires Stage 4, and uses the scripted Silver first hearing', () => {
  assert.deepEqual(validateContent(content, () => true), { valid: true, issues: [] })
  assert.equal(content.battles.find((battle) => battle.id === 'battle.stage5.first')?.hp?.forced_outcome, 'lose')
  assert.equal(content.battles.find((battle) => battle.id === 'battle.stage5.first')?.opponent_card_ids.every((id) => id.endsWith('_silver')), true)
  assert.equal(content.battles.find((battle) => battle.id === 'battle.stage5.rematch')?.gold_reward.min, 120)
  assert.equal(canStartStage5(readySave()), true)
  assert.equal(canStartStage5(createInitialGameSave()), false)
})

test('Stage 5 preserves a forced first loss, saves record review, and routes its outcome to rematch', () => {
  let save = startStage5(readySave())
  save = finishStage5Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.summon.end' } }, 'story.stage5.summon')
  assert.equal(save.progress.checkpoint_id, 'stage5.interrogation.background')
  save = settleFirstBattle(save)
  save = finishStage5Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.interrogation.end' } }, 'story.stage5.interrogation')
  save = finishStage5Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.recover.end' } }, 'story.stage5.recover')
  assert.equal(save.progress.checkpoint_id, 'stage5.minigame')
  assert.equal(save.progress.stage5_minigame?.gauge, 100)
  save = chooseStage5Response(save, 'source_record')
  assert.equal(parseSave(JSON.parse(JSON.stringify(save))).progress.stage5_minigame?.hits, 1)
  save = chooseStage5Response(save, 'pisuke')
  save = chooseStage5Response(save, 'source_record')
  assert.equal(save.progress.stage5_minigame?.gauge, 0)
  assert.equal(save.progress.stage5_minigame?.outcome, 'win')
  assert.equal(STAGE5_GAUGE_MAX, 130)
  save = continueStage5Minigame(save)
  assert.equal(save.progress.checkpoint_id, 'stage5.rematch.background')
  assert.ok(save.progress.flags.includes('stage5_minigame_completed'))
  save = { ...save, player: { ...save.player, deck: save.player.inventory.slice(0, 9) },
    progress: { ...save.progress, checkpoint_id: 'stage5.rematch.battle' } }
  save = loseFixedBattleAndReturn(prepareFixedBattle(save))
  assert.equal(canRetryStage5Battle(save), true)
  save = recoverCardsThroughTown(save, 3)
  const recoveredInventory = save.player.inventory
  save = parseSave({ ...save, player: { ...save.player, inventory: recoveredInventory,
    deck: recoveredInventory.slice(0, 9), prepared_deck: recoveredInventory.slice(0, 9) } })
  save = retryFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'stage5.rematch.battle')
  save = winFixedBattle(save)
  save = finishStage5Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.rematch.end' } }, 'story.stage5.rematch')
  assert.equal(save.progress.checkpoint_id, 'stage5.post.background')
  const home = finishStage5Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.post.end' } }, 'story.stage5.post')
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.ok(home.progress.flags.includes('stage5_complete'))
  assert.ok(home.progress.flags.includes('stage5_minigame_completed'))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(home))), home)
})

test('Stage 5 minigame clamps at six unsupported answers and rejects tampered history', () => {
  let save = startStage5(readySave())
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage5.minigame.ready' } }
  save = beginStage5Minigame(save)
  for (let index = 0; index < 6; index++) save = chooseStage5Response(save, 'accept_conclusion')
  assert.equal(save.progress.stage5_minigame?.gauge, 130)
  assert.equal(save.progress.stage5_minigame?.outcome, 'lose')
  assert.equal(save.progress.checkpoint_id, 'stage5.minigame.end')
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress, stage5_minigame: {
    ...save.progress.stage5_minigame, gauge: 0
  } } }))
  assert.equal(fixedContent.battles.some((battle) => battle.id === 'battle.stage5.rematch'), true)
})

test('Stage 5 rejects malformed ledgers and responses outside the active checkpoint', () => {
  for (const value of [null, [], { gauge: 100, hits: 0, misses: 0, rounds: 'bad' },
    { gauge: 100, hits: 0, misses: 0, rounds: [], extra: true },
    { gauge: 100, hits: 0, misses: 0, rounds: [{ selected: 'source_record', hit: true, delta: -40,
      gauge_after: 60, extra: true }] },
    { gauge: 100, hits: 0, misses: 0, rounds: [], outcome: 'draw' }]) {
    assert.throws(() => parseStage5Minigame(value))
  }
  const source = startStage5(readySave())
  assert.throws(() => beginStage5Minigame(source))
  assert.throws(() => continueStage5Minigame(source))
  assert.throws(() => chooseStage5Response(source, 'source_record'))
  const active = beginStage5Minigame({ ...source, progress: { ...source.progress, checkpoint_id: 'stage5.minigame.ready' } })
  assert.throws(() => chooseStage5Response(active, 'not-a-choice' as any))
  assert.throws(() => continueStage5Minigame(active))
  assert.throws(() => validateStage5MinigameState({ ...active, progress: { ...active.progress,
    stage5_minigame: undefined, checkpoint_id: 'stage5.rematch.background' } }))
})
