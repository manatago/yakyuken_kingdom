import assert from 'node:assert/strict'
import test from 'node:test'
import stage6Document from '../../content/stories/stage6.json'
import stage7Document from '../../content/stories/stage7.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { canRetryStage6Battle, canStartStage6, finishStage6Story, startStage6 } from '../../packages/battle/stage6'
import { canStartStage7, finishStage7Story, startStage7 } from '../../packages/battle/stage7'
import { acknowledgeFixedRound, fixedContent, fixedView, playFixedRound, prepareFixedBattle,
  returnFromFixedBattle, settleFixedBattle } from '../../packages/battle/fixed'
import { retryFixedBattle } from '../../packages/battle/fixed'
import { loseFixedBattleAndReturn } from '../helpers/fixed-battle-loss'

const stage6 = stage6Document as ContentPack
const stage7 = stage7Document as ContentPack

function readySave() {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  const extra = Array.from({ length: 6 }, () => ({ hand: 'rock' as const, grade: 2 as const }))
  return parseSave({ ...save, player: { ...save.player, inventory: [...save.player.inventory, ...extra] },
    progress: { ...save.progress, checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.end',
      flags: [...save.progress.flags, 'stage2_complete', 'stage3_complete', 'stage4_complete', 'stage5_complete'] } })
}

function playToOutcome(save: ReturnType<typeof readySave>, expected: 'win' | 'lose') {
  while (!fixedView(save).outcome) {
    const view = fixedView(save), ledger = save.progress.fixed_battle!
    const playerIndex = ledger.player_deck.findIndex((_, index) => !view.usedPlayer.includes(index))
    let next: ReturnType<typeof playFixedRound> | undefined
    for (let step = 1; step < 1000; step++) {
      const candidate = playFixedRound(save, playerIndex, step / 1000)
      if (fixedView(candidate).last?.result === (expected === 'win' ? 'win' : 'lose')) { next = candidate; break }
    }
    assert.ok(next, `Could not find a deterministic ${expected} card outcome`)
    save = next!
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, expected)
  return returnFromFixedBattle(save)
}

test('Stages 6 and 7 content validates and progression is locked to the preceding chapter', () => {
  assert.deepEqual(validateContent(stage6, () => true), { valid: true, issues: [] })
  assert.deepEqual(validateContent(stage7, () => true), { valid: true, issues: [] })
  assert.equal(stage6.battles.find((battle) => battle.id === 'battle.stage6.first')?.hp?.forced_outcome, 'lose')
  assert.equal(stage6.battles.find((battle) => battle.id === 'battle.stage6.first')?.gold_reward.min, 150)
  assert.equal(stage6.battles.find((battle) => battle.id === 'battle.stage6.rematch')?.result_route, 'guild_home')
  assert.equal(canStartStage6(readySave()), true)
  assert.equal(canStartStage7(readySave()), false)
  assert.equal(fixedContent.stories.some((story) => story.id === 'story.stage7.epilogue'), true)
})

test('Stage 6 fixed-loss hearing and ordinary rematch lead into resumable Stage 7 completion', () => {
  let save = startStage6(readySave())
  save = finishStage6Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.pre.end' } }, 'story.stage6.pre')
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.banquet.battle' } })
  save = playToOutcome(save, 'lose')
  save = finishStage6Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.banquet.end' } }, 'story.stage6.banquet')
  save = finishStage6Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.recover.end' } }, 'story.stage6.recover')
  const rebuiltDeck = save.player.inventory.slice(0, 9)
  save = parseSave({ ...save, player: { ...save.player, deck: rebuiltDeck },
    progress: { ...save.progress, checkpoint_id: 'stage6.rematch.battle' } })
  save = prepareFixedBattle(save)
  save = loseFixedBattleAndReturn(save)
  assert.equal(canRetryStage6Battle(save), true)
  save = parseSave({ ...save, player: { ...save.player, deck: save.player.inventory.slice(0, 9),
    prepared_deck: save.player.inventory.slice(0, 9) } })
  save = retryFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'stage6.rematch.battle')
  save = playToOutcome(save, 'win')
  save = finishStage6Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.rematch.end' } }, 'story.stage6.rematch')
  assert.equal(save.progress.checkpoint_id, 'stage6.post.background')
  save = finishStage6Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage6.post.end' } }, 'story.stage6.post')
  assert.ok(save.progress.flags.includes('stage6_complete'))
  assert.equal(canStartStage7(save), true)
  save = startStage7(save)
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
  save = finishStage7Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage7.throne.end' } }, 'story.stage7.throne')
  assert.equal(save.progress.checkpoint_id, 'stage7.epilogue.background')
  save = finishStage7Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage7.epilogue.end' } }, 'story.stage7.epilogue')
  assert.equal(save.progress.checkpoint_id, 'guild.home')
  assert.ok(save.progress.flags.includes('game_complete'))
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
})
