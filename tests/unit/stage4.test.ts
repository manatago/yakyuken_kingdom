import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/stage4.json'
import type { ContentPack } from '../../packages/content/schema'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { startStage4, canStartStage4, canRetryStage4Battle, finishStage4Story } from '../../packages/battle/stage4'
import { beginStage4Minigame, chooseStage4Option, continueStage4Minigame, parseStage4Minigame,
  STAGE4_GAUGE_MAX, stage4Zone, validateStage4Minigame, validateStage4MinigameState } from '../../packages/battle/stage4-minigame'
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
  save = { ...save, player: { ...save.player,
    inventory: [...save.player.inventory, ...Array.from({ length: 3 }, () => ({ hand: 'rock' as const, grade: 2 as const }))] },
    progress: { ...save.progress, checkpoint_id: 'guild.home', guild_return_checkpoint: 'matilda.end',
      flags: [...save.progress.flags, 'stage3_complete'] } }
  return parseSave(save)
}

test('Stage 4 content validates and remains locked until Stage 3 is complete', () => {
  assert.deepEqual(validateContent(content, () => true), { valid: true, issues: [] })
  const first = content.battles.find((battle) => battle.id === 'battle.stage4.first')!
  assert.equal(first.hp?.forced_outcome, 'lose')
  assert.equal(first.gold_reward.min, 100)
  assert.equal(first.gold_reward.max, 150)
  assert.deepEqual(first.opponent_tendency, { rock: 0.35, paper: 0.35 })
  assert.equal(canStartStage4(readySave()), true)
  assert.equal(canStartStage4(createInitialGameSave()), false)
})

test('Stage 4 initial loss, strength calibration, and persisted rematch handoff follow the chapter flow', () => {
  let save = startStage4(readySave())
  save = finishStage4Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage4.pre.end' } }, 'story.stage4.pre')
  assert.equal(save.progress.checkpoint_id, 'stage4.first.background')
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'stage4.first.battle' } })
  while (!fixedView(save).outcome) {
    const ledger = save.progress.fixed_battle!
    const view = fixedView(save)
    const index = ledger.player_deck.findIndex((_, cardIndex) => !view.usedPlayer.includes(cardIndex))
    save = playFixedRound(save, index, 0.5)
    if (fixedView(save).outcome) save = settleFixedBattle(save, 0)
    else save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  save = returnFromFixedBattle(save)
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage4.first.end' } }
  save = finishStage4Story(save, 'story.stage4.first')
  save = { ...save, progress: { ...save.progress, checkpoint_id: 'stage4.recover.end' } }
  save = finishStage4Story(save, 'story.stage4.recover')
  assert.equal(save.progress.checkpoint_id, 'stage4.minigame')
  assert.equal(save.progress.stage4_minigame?.gauge, 110)
  save = chooseStage4Option(save, 'challenge')
  assert.equal(save.progress.stage4_minigame?.gauge, 115)
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(save))))
  save = chooseStage4Option(save, 'calm')
  save = chooseStage4Option(save, 'challenge')
  save = chooseStage4Option(save, 'challenge')
  assert.equal(save.progress.stage4_minigame?.gauge, 0)
  assert.equal(save.progress.stage4_minigame?.outcome, 'win')
  assert.equal(save.progress.checkpoint_id, 'stage4.minigame.end')
  assert.equal(STAGE4_GAUGE_MAX, 130)
  save = continueStage4Minigame(save)
  assert.equal(save.progress.checkpoint_id, 'stage4.rematch.background')
  save = { ...save, player: { ...save.player, deck: save.player.inventory.slice(0, 9) },
    progress: { ...save.progress, checkpoint_id: 'stage4.rematch.battle' } }
  save = loseFixedBattleAndReturn(prepareFixedBattle(save))
  assert.equal(canRetryStage4Battle(save), true)
  save = recoverCardsThroughTown(save, 3)
  const recoveredInventory = save.player.inventory
  save = parseSave({ ...save, player: { ...save.player, inventory: recoveredInventory,
    deck: recoveredInventory.slice(0, 9), prepared_deck: recoveredInventory.slice(0, 9) } })
  save = retryFixedBattle(save)
  assert.equal(save.progress.checkpoint_id, 'stage4.rematch.battle')
  save = winFixedBattle(save)
  save = finishStage4Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage4.rematch.end' } }, 'story.stage4.rematch')
  assert.equal(save.progress.checkpoint_id, 'stage4.post.background')
  const home = finishStage4Story({ ...save, progress: { ...save.progress, checkpoint_id: 'stage4.post.end' } }, 'story.stage4.post')
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.ok(home.progress.flags.includes('stage4_complete'))
  assert.ok(home.progress.flags.includes('stage4_minigame_completed'))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(home))), home)
  assert.equal(fixedContent.battles.some((battle) => battle.id === 'battle.stage4.rematch'), true)
})

test('Stage 4 minigame validates every choice zone, malformed history and checkpoint result', () => {
  assert.equal(stage4Zone(100), 'red')
  assert.equal(stage4Zone(49), 'yellow')
  assert.equal(stage4Zone(48), 'green')
  const source = startStage4(readySave())
  const ready = { ...source, progress: { ...source.progress, checkpoint_id: 'stage4.minigame.ready' } }
  let save = beginStage4Minigame(ready)
  for (const choice of ['challenge', 'calm', 'calm', 'neutral', 'challenge', 'challenge', 'calm', 'neutral', 'challenge'] as const) {
    save = chooseStage4Option(save, choice)
  }
  assert.equal(save.progress.stage4_minigame?.outcome, 'win')
  assert.deepEqual(parseStage4Minigame(JSON.parse(JSON.stringify(save.progress.stage4_minigame))), save.progress.stage4_minigame)
  assert.throws(() => validateStage4Minigame({ ...save.progress.stage4_minigame!, gauge: 1 }))
  assert.throws(() => parseStage4Minigame({ ...save.progress.stage4_minigame, unexpected: true }))
  assert.throws(() => parseStage4Minigame({ ...save.progress.stage4_minigame, outcome: 'draw' }))
  assert.throws(() => beginStage4Minigame(save))
  let pisuke = beginStage4Minigame(ready)
  for (const choice of ['calm', 'calm', 'calm', 'calm', 'challenge', 'challenge', 'pisuke'] as const) {
    pisuke = chooseStage4Option(pisuke, choice)
  }
  assert.equal(pisuke.progress.stage4_minigame?.outcome, 'win')
  for (const checkpoint_id of ['stage4.minigame', 'stage4.minigame.end', 'stage4.rematch.background']) {
    assert.throws(() => validateStage4MinigameState({ ...readySave(), progress: { ...readySave().progress, checkpoint_id } }))
  }
})
