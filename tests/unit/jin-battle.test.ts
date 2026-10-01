import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { startJin, jinContent, jinProbabilities, jinView, playJinRound, returnJinToGuild,
  setJinDraft, settleJin, validateJinState } from '../../packages/battle/jin'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome } from '../../packages/guild/home'
import { startBelka, playBelkaRound, acknowledgeBelkaRound, settleBelka, returnBelkaToGuild, belkaView } from '../../packages/battle/belka'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { validateContent } from '../../packages/content/validate'

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

function winBelka(save: SaveData): SaveData {
  let current = startBelka(save)
  for (const index of [6, 7, 8]) {
    current = playBelkaRound(current, index, 0)
    if (!belkaView(current).outcome) current = acknowledgeBelkaRound(current)
  }
  assert.equal(belkaView(current).outcome, 'win')
  return returnBelkaToGuild(settleBelka(current, 0))
}

test('Jin opens a three-card encounter with the Godot deck and card transfer', () => {
  assert.deepEqual(validateContent(jinContent, (path) => path === 'godot/assets/backgrounds/prologue/bg06_prison_arena.png'), { valid: true, issues: [] })
  const battle = jinContent.battles[0]
  assert.deepEqual(battle.opponent_card_ids, ['scissors_normal', 'scissors_normal', 'rock_normal'])
  assert.equal(battle.player_deck_size, 3)
  assert.equal(battle.transfer_cards, true)
  const save = createInitialGameSave()
  assert.throws(() => startJin(save, save.player.inventory.slice(0, 3)))
  assert.equal(battle.hp?.first_hand, undefined)
})

test('Jin saves a three-card ordered draft, applies the opponent tendency and reloads a pending round', () => {
  const source = guild(), picked = [source.player.inventory[6], source.player.inventory[7], source.player.inventory[8]]
  assert.throws(() => startJin(source, picked.slice(0, 2)))
  assert.throws(() => startJin(source, [...picked, picked[0]]))
  const draft = setJinDraft(source, picked)
  assert.deepEqual(draft.progress.jin_draft, picked)
  const started = startJin(draft)
  assert.deepEqual(started.progress.jin_battle?.player_deck, picked)
  assert.equal(started.progress.checkpoint_id, 'jin.await')
  const probabilities = jinProbabilities(started)
  assert.ok(Math.abs(probabilities.scissors - 8 / 9) < 1e-12)
  const pending = playJinRound(started, 0, 0)
  assert.equal(jinView(pending).last?.opponent.hand, 'rock')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(pending))), pending)
  assert.equal(jinView(pending).outcome, 'win')
})

test('Jin victory captures one card and settles once; draw consumes neither hand nor inventory', () => {
  const source = guild(), deck = [source.player.inventory[6], source.player.inventory[7], source.player.inventory[8]]
  const started = startJin(source, deck)
  const pending = playJinRound(started, 0, 0)
  const settled = settleJin(pending, 0)
  assert.equal(settled.player.inventory.length, source.player.inventory.length + 1)
  assert.deepEqual(settled.player.inventory.at(-1), { hand: 'rock', grade: 1 })
  assert.equal(settled.player.money, started.player.money + 3)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
  assert.throws(() => settleJin(settled, 0))
  assert.equal(returnJinToGuild(settled).progress.checkpoint_id, 'guild.home')

  const drawn = startJin(source, [source.player.inventory[3], source.player.inventory[4], source.player.inventory[5]])
  const tie = playJinRound(drawn, 0, .2)
  assert.equal(jinView(tie).last?.result, 'draw')
  assert.equal(jinView(tie).outcome, undefined)
  assert.deepEqual(tie.player.inventory, drawn.player.inventory)
  assert.deepEqual(jinView(tie).usedPlayer, [])
})

test('Jin loss removes one played card while preserving historical Matilda save and valid current lineup', () => {
  const source = guild(), deck = [source.player.inventory[3], source.player.inventory[4], source.player.inventory[5]]
  const started = startJin(source, deck)
  const pending = playJinRound(started, 0, 0)
  assert.equal(jinView(pending).last?.result, 'lose')
  const settled = settleJin(pending, .99)
  assert.equal(settled.player.inventory.length, source.player.inventory.length - 1)
  assert.equal(settled.player.deck.length, source.player.deck.length - 1)
  assert.equal(settled.player.money, started.player.money - Math.min(started.player.money, 2))
  assert.deepEqual(settled.progress.tutorial, source.progress.tutorial)
  assert.deepEqual(settled.progress.fixed_battle, source.progress.fixed_battle)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
  assert.equal(returnJinToGuild(settled).progress.checkpoint_id, 'guild.home')
  const forged = structuredClone(settled) as any
  forged.player.inventory.push({ hand: 'paper', grade: 1 })
  assert.throws(() => validateJinState(forged))
  assert.throws(() => parseSave(forged))
})

test('Jin and Belka ledgers remain valid in either encounter order', () => {
  const priorBelka = winBelka(guild())
  const jinAfterBelka = startJin(priorBelka, priorBelka.player.inventory.slice(6, 9))
  const settledJinAfterBelka = settleJin(playJinRound(jinAfterBelka, 0, 0), 0)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settledJinAfterBelka))), settledJinAfterBelka)

  const startedJin = startJin(guild(), guild().player.inventory.slice(6, 9))
  const settledJin = settleJin(playJinRound(startedJin, 0, 0), 0)
  const belkaAfterJin = winBelka(returnJinToGuild(settledJin))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(belkaAfterJin))), belkaAfterJin)
})
