import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { startJin, jinContent, jinProbabilities, jinView, playJinRound, returnJinToGuild,
  acknowledgeJinRound, startSubevent1JinStory, prepareSubevent1Jin, continueSubevent1Jin, returnSubevent1JinToGuild,
  prepareSubevent1Marco, continueSubevent1Marco, SUBEVENT1_MARCO_CHECKPOINT,
  activeJinLedger, canStartJin, canStartSubevent1Jin,
  setJinDraft, settleJin, validateJinState } from '../../packages/battle/jin'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome } from '../../packages/guild/home'
import { startBelka, playBelkaRound, acknowledgeBelkaRound, settleBelka, returnBelkaToGuild, belkaView } from '../../packages/battle/belka'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { validateContent } from '../../packages/content/validate'
import { equipItem, unequipItem } from '../../packages/domain/equipment'

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
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end',
    flags: [...save.progress.flags, 'adventurer.tutorial.completed'], random_battles_completed: 3 } }))
}

function zeroMoneyGuild(): SaveData {
  const initial = createInitialGameSave()
  let save = prepareTutorial({ ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }, initial.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [3, 4, 5]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  assert.equal(fixedView(save).outcome, 'lose')
  save = settleFixedBattle(save, 0)
  assert.equal(save.player.money, 0)
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end',
    flags: [...save.progress.flags, 'adventurer.tutorial.completed'], random_battles_completed: 3 } }))
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

function loseBelka(save: SaveData): SaveData {
  let current = startBelka(save)
  for (const index of [3, 4, 5]) {
    current = playBelkaRound(current, index, 0)
    if (!belkaView(current).outcome) current = acknowledgeBelkaRound(current)
  }
  assert.equal(belkaView(current).outcome, 'lose')
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

test('Jin rejects invalid rolls and premature result transitions', () => {
  const source = guild()
  const started = startJin(source, source.player.inventory.slice(6, 9))
  assert.equal(activeJinLedger(source), undefined)
  assert.throws(() => jinView(source), /not started/)
  assert.throws(() => playJinRound(started, 0, Number.NaN), /random roll/)
  assert.throws(() => acknowledgeJinRound(started), /No pending Jin result/)
  assert.throws(() => settleJin(started, 0), /terminal Jin result/)
  assert.throws(() => returnJinToGuild(started), /not settled/)
  assert.throws(() => continueSubevent1Jin(started), /not ready to continue/)
})

test('Jin victory captures one card and settles once; draw consumes neither hand nor inventory', () => {
  const source = guild(), deck = [source.player.inventory[6], source.player.inventory[7], source.player.inventory[8]]
  const started = startJin(source, deck)
  assert.equal(started.progress.jin_battle?.belka_preceded_jin, false)
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

test('Greed Ring adds a persisted second capture to a one-round Jin win', () => {
  const source = guild()
  const equipped = equipItem({ ...source, player: { ...source.player, items: ['greed_ring'] } }, 'greed_ring')
  const started = startJin(equipped, equipped.player.inventory.slice(0, 3))
  const terminal = playJinRound(started, 0, .5)
  assert.equal(jinView(terminal).outcome, 'win')
  const settled = settleJin(terminal, .5, .99)
  const ledger = settled.progress.jin_battle!
  assert.equal(settled.player.inventory.length, equipped.player.inventory.length + 2)
  assert.notEqual(ledger.bonus_capture_index, ledger.rounds[0]!.opponent_index)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('Jin battle item choice is saved, bounded by inventory, and consumed once after settlement', () => {
  const source = guild()
  const owned = { ...source, player: { ...source.player, items: ['rock_attract_white'] as const } }
  const started = startJin(owned, owned.player.inventory.slice(6, 9))
  const pending = playJinRound(started, 0, 0, 'rock_attract_white')
  assert.deepEqual(pending.progress.jin_battle?.round_item_ids, ['rock_attract_white'])
  assert.deepEqual(pending.player.items, ['rock_attract_white'])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(pending))), pending)
  assert.throws(() => playJinRound(pending, 1, 0, 'rock_attract_white'))
  const settled = settleJin(pending, 0)
  assert.deepEqual(settled.player.items, [])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('Jin snapshots the gold charm bonus and permits changing equipment after settlement', () => {
  const source = guild(), equipped = equipItem({ ...source, player: { ...source.player, items: ['gold_charm'] } }, 'gold_charm')
  const deck = [equipped.player.inventory[6]!, equipped.player.inventory[7]!, equipped.player.inventory[8]!]
  const pending = playJinRound(startJin(equipped, deck), 0, 0)
  const settled = settleJin(pending, 0)
  assert.equal(settled.player.money, equipped.player.money + 23)
  assert.deepEqual(settled.progress.jin_battle?.equipment_before, ['gold_charm'])
  assert.deepEqual(unequipItem(settled, 'gold_charm').player.equipment, [])
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

test('Subevent 1 Jin can follow the verification Jin battle without overwriting its ledger', () => {
  const original = guild(), verificationDeck = original.player.inventory.slice(6, 9)
  const verification = settleJin(playJinRound(startJin(original, verificationDeck), 0, 0), 0)
  const home = returnJinToGuild(verification)
  const eventDeck = home.player.inventory.slice(0, 3)
  const story = startSubevent1JinStory(home, eventDeck)
  const challenge = parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } })
  const prepared = prepareSubevent1Jin(challenge)

  assert.deepEqual(prepared.progress.jin_battle, verification.progress.jin_battle)
  assert.equal(prepared.progress.subevent1_jin_battle?.battle_id, 'battle.subevent1.jin')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(prepared))), prepared)
  const legacy = structuredClone(prepared) as any
  legacy.progress.jin_battle = legacy.progress.subevent1_jin_battle
  delete legacy.progress.subevent1_jin_battle
  const migrated = parseSave(legacy)
  assert.equal(migrated.progress.subevent1_jin_battle?.battle_id, 'battle.subevent1.jin')
  assert.equal(migrated.progress.jin_battle, undefined)
  const pending = playJinRound(prepared, 0, 0)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(pending))), pending)
})

test('the Subevent 1 draft remains available after the one-time Jin verification battle', () => {
  const original = guild(), verificationDeck = original.player.inventory.slice(6, 9)
  const verification = settleJin(playJinRound(startJin(original, verificationDeck), 0, 0), 0)
  const home = returnJinToGuild(verification)
  assert.equal(canStartJin(home), false)
  assert.equal(canStartSubevent1Jin(home), true)
  const eventDeck = home.player.inventory.slice(0, 3)
  const drafted = setJinDraft(home, eventDeck)
  assert.deepEqual(drafted.progress.jin_draft, eventDeck)
  assert.equal(startSubevent1JinStory(drafted, eventDeck).progress.checkpoint_id, 'subevent1.jin.intro')
})

test('verification Jin can follow completed Subevent 1 Jin while retaining both ledgers', () => {
  const original = guild()
  const story = startSubevent1JinStory(original, original.player.inventory.slice(0, 3))
  const challenge = parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } })
  const prepared = prepareSubevent1Jin(challenge)
  const storyResult = settleJin(playJinRound(prepared, 0, .5), 0)
  assert.equal(jinView(storyResult).outcome, 'win')
  const after = continueSubevent1Jin(storyResult)
  const end = parseSave({ ...after, progress: { ...after.progress, checkpoint_id: 'subevent1.jin.end' } })
  const home = returnSubevent1JinToGuild(end)

  assert.equal(canStartJin(home), true)
  const verification = startJin(home, home.player.inventory.slice(0, 3))
  assert.equal(activeJinLedger(verification)?.battle_id, jinContent.battles[0].id)
  assert.deepEqual(verification.progress.subevent1_jin_battle, home.progress.subevent1_jin_battle)
  const verificationResult = settleJin(playJinRound(verification, 0, .5), 0)
  assert.equal(jinView(verificationResult).outcome, 'win')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(verificationResult))), verificationResult)
  const returned = returnJinToGuild(verificationResult)
  assert.equal(returned.progress.checkpoint_id, 'guild.home')
  assert.deepEqual(returned.progress.subevent1_jin_battle, home.progress.subevent1_jin_battle)
})

test('Subevent 1 continues through Marco, preserving and resuming both settled battle ledgers', () => {
  const source = guild()
  const story = startSubevent1JinStory(source, source.player.inventory.slice(0, 3))
  const jinChallenge = parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } })
  const jinStarted = prepareSubevent1Jin(jinChallenge)
  const jinWon = settleJin(playJinRound(jinStarted, 0, .5), 0)
  assert.equal(jinView(jinWon).outcome, 'win')
  const afterJin = continueSubevent1Jin(jinWon)
  const marcoChallenge = parseSave({ ...afterJin, progress: { ...afterJin.progress, checkpoint_id: 'subevent1.marco.challenge' } })
  const marcoStarted = prepareSubevent1Marco(marcoChallenge)

  assert.equal(marcoStarted.progress.checkpoint_id, SUBEVENT1_MARCO_CHECKPOINT)
  assert.deepEqual(marcoStarted.progress.subevent1_jin_battle, jinWon.progress.subevent1_jin_battle)
  assert.equal(activeJinLedger(marcoStarted)?.battle_id, 'battle.subevent1.marco')
  assert.deepEqual(jinProbabilities(marcoStarted), { rock: 1 / 3, scissors: 1 / 3, paper: 1 / 3 })
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(marcoStarted))), marcoStarted)

  const marcoWon = settleJin(playJinRound(marcoStarted, 0, .5), 0)
  assert.equal(jinView(marcoWon).outcome, 'win')
  assert.equal(marcoWon.progress.subevent1_marco_battle?.gold_delta, 5)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(marcoWon))), marcoWon)
  const afterMarco = continueSubevent1Marco(marcoWon)
  const end = parseSave({ ...afterMarco, progress: { ...afterMarco.progress, checkpoint_id: 'subevent1.marco.end' } })
  const home = returnSubevent1JinToGuild(end)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.deepEqual(home.progress.subevent1_jin_battle, jinWon.progress.subevent1_jin_battle)
  assert.deepEqual(home.progress.subevent1_marco_battle, marcoWon.progress.subevent1_marco_battle)
})

test('Marco battle checkpoint rejects a save that has only the completed Jin ledger', () => {
  const source = guild()
  const story = startSubevent1JinStory(source, source.player.inventory.slice(0, 3))
  const jinStarted = prepareSubevent1Jin(parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } }))
  const jinWon = settleJin(playJinRound(jinStarted, 0, .5), 0)
  const forged = structuredClone(jinWon)
  forged.progress.checkpoint_id = SUBEVENT1_MARCO_CHECKPOINT

  assert.throws(() => parseSave(forged))
})

test('Subevent 1 Marco loss removes the played card and deducts up to 3G', () => {
  const source = zeroMoneyGuild()
  const story = startSubevent1JinStory(source, source.player.inventory.slice(0, 3))
  const jinStarted = prepareSubevent1Jin(parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.jin.challenge' } }))
  const jinWon = settleJin(playJinRound(jinStarted, 0, .5), 0)
  const afterJin = continueSubevent1Jin(jinWon)
  const marcoStarted = prepareSubevent1Marco(parseSave({ ...afterJin, progress: { ...afterJin.progress, checkpoint_id: 'subevent1.marco.challenge' } }))
  const lostCard = activeJinLedger(marcoStarted)!.player_deck[0]
  const beforeCount = marcoStarted.player.inventory.filter((card) => card.hand === lostCard.hand && card.grade === lostCard.grade).length
  const marcoLost = settleJin(playJinRound(marcoStarted, 0, .99), 0)

  assert.equal(jinView(marcoLost).outcome, 'lose')
  assert.equal(marcoLost.player.money, 0)
  assert.equal(marcoLost.player.inventory.length, marcoStarted.player.inventory.length - 1)
  assert.equal(marcoLost.player.inventory.filter((card) => card.hand === lostCard.hand && card.grade === lostCard.grade).length, beforeCount - 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(marcoLost))).progress.subevent1_marco_battle,
    marcoLost.progress.subevent1_marco_battle)
  const returned = returnJinToGuild(marcoLost)
  assert.equal(returned.progress.checkpoint_id, 'guild.home')
  assert.equal(returned.progress.guild_return_checkpoint, 'matilda.normal.end')
})

test('Jin and Belka ledgers remain valid in either encounter order', () => {
  const priorBelka = winBelka(guild())
  const jinAfterBelka = startJin(priorBelka, priorBelka.player.inventory.slice(6, 9))
  assert.equal(jinAfterBelka.progress.jin_battle?.belka_preceded_jin, true)
  const settledJinAfterBelka = settleJin(playJinRound(jinAfterBelka, 0, 0), 0)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settledJinAfterBelka))), settledJinAfterBelka)

  const startedJin = startJin(guild(), guild().player.inventory.slice(6, 9))
  const settledJin = settleJin(playJinRound(startedJin, 0, 0), 0)
  const belkaAfterJin = winBelka(returnJinToGuild(settledJin))
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(belkaAfterJin))), belkaAfterJin)
})

test('Belka loss at zero gold remains the earlier encounter when Jin also loses at zero gold', () => {
  const afterBelka = loseBelka(zeroMoneyGuild())
  assert.ok(afterBelka.progress.belka_battle?.gold_delta === 0)
  const startedJin = startJin(afterBelka, afterBelka.player.inventory.slice(3, 6))
  assert.equal(startedJin.progress.jin_battle?.belka_preceded_jin, true)
  const pending = playJinRound(startedJin, 0, 0)
  assert.equal(jinView(pending).last?.result, 'lose')

  const settledJin = settleJin(pending, 0)
  assert.ok(settledJin.progress.jin_battle?.gold_delta === 0)
  assert.equal(settledJin.player.inventory.length, startedJin.player.inventory.length - 1)
  const reloaded = parseSave(JSON.parse(JSON.stringify(settledJin)))
  assert.deepEqual(reloaded.player.inventory, settledJin.player.inventory)
  assert.equal(reloaded.player.money, 0)
  assert.ok(reloaded.progress.jin_battle?.gold_delta === 0)
})
