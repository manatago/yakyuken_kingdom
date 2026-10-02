import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome } from '../../packages/guild/home'
import { startSubevent1JinStory, prepareSubevent1Jin, playJinRound, settleJin, continueSubevent1Jin,
  prepareSubevent1Marco, continueSubevent1Marco } from '../../packages/battle/jin'
import { prepareSubevent1Gald, playGaldRound, settleGald, galdView, continueSubevent1Gald,
  returnSubevent1GaldToGuild } from '../../packages/battle/gald'

function guild(): SaveData {
  const initial = createInitialGameSave()
  let save = prepareTutorial({ ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
}

function galdSetup(): SaveData {
  const source = guild()
  const deck = [source.player.inventory[0], source.player.inventory[6], source.player.inventory[3]]
  const story = startSubevent1JinStory(source, deck)
  const jinStarted = prepareSubevent1Jin(parseSave({ ...story,
    progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } }))
  const jinWon = settleJin(playJinRound(jinStarted, 0, .2), 0)
  const afterJin = continueSubevent1Jin(jinWon)
  const marcoStarted = prepareSubevent1Marco(parseSave({ ...afterJin,
    progress: { ...afterJin.progress, checkpoint_id: 'subevent1.marco.challenge' } }))
  const marcoWon = settleJin(playJinRound(marcoStarted, 0, .5), 0)
  const afterMarco = continueSubevent1Marco(marcoWon)
  return parseSave({ ...afterMarco,
    progress: { ...afterMarco.progress, checkpoint_id: 'subevent1.gald.warning' } })
}

test('Gald victory captures a card, gold, and each configured item once across save/reload', () => {
  const challenge = galdSetup()
  const started = prepareSubevent1Gald(challenge)
  assert.equal(started.progress.checkpoint_id, 'subevent1.gald.await')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(started))), started)

  const won = settleGald(playGaldRound(started, 1, .2), 0)
  assert.equal(galdView(won).outcome, 'win')
  assert.equal(won.player.inventory.length, started.player.inventory.length + 1)
  assert.equal(won.player.money, started.player.money + 8)
  assert.deepEqual(won.player.items, ['scissors_attract_white', 'paper_seal_white'])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(won))), won)
  assert.throws(() => settleGald(won, 0))

  const end = parseSave({ ...continueSubevent1Gald(won), progress: {
    ...continueSubevent1Gald(won).progress, checkpoint_id: 'subevent1.gald.end'
  } })
  const home = returnSubevent1GaldToGuild(end)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.deepEqual(home.player.items, ['scissors_attract_white', 'paper_seal_white'])
})

test('Gald defeat does not grant item rewards and returns to Guild Home', () => {
  const started = prepareSubevent1Gald(galdSetup())
  const lost = settleGald(playGaldRound(started, 2, .2), 0)
  assert.equal(galdView(lost).outcome, 'lose')
  assert.deepEqual(lost.player.items, [])
  assert.equal(lost.player.inventory.length, started.player.inventory.length - 1)
  assert.equal(returnSubevent1GaldToGuild(lost).progress.checkpoint_id, 'guild.home')
})
