import assert from 'node:assert/strict'
import test from 'node:test'
import { askPisukeForStage2Minigame, chooseStage2Expression, continueToStage2Rematch, parseStage2Minigame,
  isStage2PickCorrect, startStage2Minigame, STAGE2_MINIGAME_SCENES, type Stage2Expression } from '../../packages/battle/stage2-minigame'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'

const order = Array.from({ length: STAGE2_MINIGAME_SCENES.length }, (_, index) => index)
const freshSave = () => {
  let save = createInitialGameSave()
  save = prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  return { ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'stage2.started', 'stage2_first_battle_completed'] } }
}
const correct = (scene: number): Stage2Expression => STAGE2_MINIGAME_SCENES[scene]!
const wrong = (scene: number): Stage2Expression => (['shake', 'blush', 'sweat', 'panic'] as const)
  .find((choice) => choice !== STAGE2_MINIGAME_SCENES[scene])!

test('Stage 2 expression minigame persists its randomized scene order and resumes exact progress', () => {
  const base = freshSave()
  const home = { ...base, progress: { ...base.progress, checkpoint_id: 'guild.home',
    guild_return_checkpoint: 'matilda.normal.end' } }
  const started = startStage2Minigame(home, [...order].reverse())
  assert.equal(Object.hasOwn(started.progress, 'guild_return_checkpoint'), false)
  parseSave(JSON.parse(JSON.stringify(started)))
  const afterHit = chooseStage2Expression(started, correct(order.length - 1))
  const reloaded = parseSave(JSON.parse(JSON.stringify(afterHit)))
  assert.equal(reloaded.progress.stage2_minigame?.current_scene, 1)
  assert.equal(reloaded.progress.stage2_minigame?.gauge, 60)
  assert.deepEqual(reloaded.progress.stage2_minigame?.scene_order, [...order].reverse())
})

test('Stage 2 minigame wins at zero and cannot accept extra answers', () => {
  let save = startStage2Minigame(freshSave(), order)
  save = chooseStage2Expression(save, correct(0))
  save = chooseStage2Expression(save, correct(1))
  save = chooseStage2Expression(save, correct(2))
  assert.equal(save.progress.stage2_minigame?.outcome, 'win')
  assert.equal(save.progress.checkpoint_id, 'stage2.minigame.end')
  assert.throws(() => chooseStage2Expression(save, correct(3)))
  const rematch = continueToStage2Rematch(save)
  assert.equal(rematch.progress.checkpoint_id, 'stage2.battle2.start')
  assert.ok(rematch.progress.flags.includes('stage2_minigame_completed'))
  assert.throws(() => continueToStage2Rematch(startStage2Minigame(freshSave(), order)))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(rematch))), rematch)
})

test('Stage 2 minigame loses at 130, clamps gauge, and rejects tampered save progress', () => {
  let save = startStage2Minigame(freshSave(), order)
  for (let index = 0; index < 6; index++) save = chooseStage2Expression(save, wrong(index))
  assert.equal(save.progress.stage2_minigame?.gauge, 130)
  assert.equal(save.progress.stage2_minigame?.outcome, 'lose')
  assert.throws(() => parseStage2Minigame({ ...save.progress.stage2_minigame, gauge: 0 }))
  assert.throws(() => parseSave({ ...save, progress: { ...save.progress,
    stage2_minigame: { ...save.progress.stage2_minigame, scene_order: [...order.slice(0, -1), 0] } } }))
  assert.throws(() => parseSave({ ...freshSave(), progress: { ...freshSave().progress, checkpoint_id: 'stage2.minigame' } }))
  assert.throws(() => startStage2Minigame(freshSave(), [0, 0, ...order.slice(2)]))
})

test('asking Pisuke records the assist and applies the scene answer as one correct pick', () => {
  const save = askPisukeForStage2Minigame(startStage2Minigame(freshSave(), order))
  assert.deepEqual(save.progress.stage2_minigame?.picks, ['ask_pisuke'])
  assert.equal(save.progress.stage2_minigame?.gauge, 60)
  assert.equal(save.progress.stage2_minigame?.current_scene, 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(save))), save)
  assert.equal(isStage2PickCorrect(0, 'ask_pisuke'), true)
  assert.equal(isStage2PickCorrect(0, 'blush'), true)
  assert.equal(isStage2PickCorrect(0, 'shake'), false)
})
