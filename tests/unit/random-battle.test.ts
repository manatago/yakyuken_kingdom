import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome } from '../../packages/guild/home'
import { PROGRESSION_FLAGS } from '../../packages/domain/progression'
import { equipItem } from '../../packages/domain/equipment'
import { acceptTownEncounter, acknowledgeRandomBattleRound, declineTownEncounter, enterTown,
  continueTownAfterBattle, playRandomBattleRound, randomBattleDialogue, randomBattleProbabilities, randomBattleView,
  returnToGuildFromTown, settleRandomBattle, townContent, travelTown, canEnterTown } from '../../packages/battle/random'

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
    flags: [...save.progress.flags, 'adventurer.tutorial.completed'] } }))
}

const rolls = (encounter: number, opponent: number) => ({ encounter, opponent,
  cards: [{ hand: 0, grade: 0 }, { hand: .5, grade: 0 }, { hand: .99, grade: 0 }] as const, drop: 0 })
const battleDeck = (save: SaveData): SaveData['player']['inventory'] => [
  save.player.inventory.find((card) => card.hand === 'paper')!,
  save.player.inventory.find((card) => card.hand === 'scissors')!,
  save.player.inventory.find((card) => card.hand === 'rock')!
]

test('Stage 1 town content matches Godot areas, encounter weights, opponent profiles and grade ranges', () => {
  assert.deepEqual(townContent.homeConnections, ['guild_street', 'market', 'tavern'])
  assert.deepEqual(Object.keys(townContent.areas), ['guild_street', 'market', 'tavern', 'slum', 'outside', 'port'])
  assert.equal(townContent.areas.guild_street.battleRate, .6)
  assert.deepEqual(townContent.areas.guild_street.encounters.map((entry) => [entry.opponentId, entry.weight, entry.gradeMin, entry.gradeMax]), [
    ['thug_01', 3, 1, 1], ['merchant_02', 2, 1, 1], ['adv_a_01', 1, 1, 1]
  ])
  assert.equal(townContent.areas.market.battleRate, .5)
  assert.deepEqual(townContent.areas.slum.encounters.map((entry) => [entry.opponentId, entry.weight, entry.gradeMin, entry.gradeMax]), [
    ['thug_01', 5, 1, 2], ['bandit_01', 3, 1, 2]
  ])
  assert.equal(townContent.opponents.thug_01.charType, 'normal')
  assert.deepEqual(townContent.opponents.adv_a_01.deck, [
    { hand: 'rock', grade: 1 }, { hand: 'rock', grade: 1 }, { hand: 'paper', grade: 1 }
  ])
  assert.equal(townContent.opponents.adv_a_01.charType, 'rare')
  assert.equal(townContent.opponents.adv_a_01.tendency.rock, 2.33)
})

test('town exploration persists the weighted fixed encounter before accepting it and resumes the same deck', () => {
  const source = guild()
  const pending = enterTown(source, 'guild_street', rolls(.6, .99))
  assert.equal(pending.progress.checkpoint_id, 'town.encounter')
  assert.equal(pending.progress.random_battle?.opponent_id, 'adv_a_01')
  assert.equal(pending.progress.random_battle?.char_type, 'rare')
  assert.equal(pending.progress.random_battle?.player_deck.length, 0)
  assert.equal(pending.progress.random_battle?.opponent_deck.length, 3)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(pending))), pending)
  assert.throws(() => acceptTownEncounter(pending, battleDeck(source).slice(0, 2)))
  assert.throws(() => acceptTownEncounter(pending, [{ hand: 'paper', grade: 5 }, ...battleDeck(source).slice(1)]))
  const declined = declineTownEncounter(pending)
  assert.equal(declined.progress.checkpoint_id, 'town.area')
  assert.equal(declined.progress.random_battle, undefined)
  assert.deepEqual(returnToGuildFromTown(declined).progress.guild_return_checkpoint, 'matilda.normal.end')

  const battle = acceptTownEncounter(pending, battleDeck(source))
  assert.deepEqual(battle.progress.random_battle?.player_deck, battleDeck(source))
  const unresolved = playRandomBattleRound(battle, 0, 0)
  assert.equal(randomBattleView(unresolved).outcome, 'win')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(unresolved))), unresolved)
})

test('random encounter dialogue selection is saved and remains the same across reloads and outcomes', () => {
  const source = guild()
  const pending = enterTown(source, 'guild_street', { ...rolls(.1, 0), dialogue: [.99, 0, .99, 0] })
  assert.deepEqual(pending.progress.random_battle?.dialogue_indexes,
    { greeting: 2, battle_start: 0, farewell_win: 2, farewell_lose: 0 })
  assert.equal(randomBattleDialogue(pending, 'greeting'), 'チッ、金はねぇのか。ならカードで払え！')
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(pending))), pending)
  assert.throws(() => parseSave({ ...pending, progress: { ...pending.progress, random_battle: {
    ...pending.progress.random_battle, dialogue_indexes: { greeting: 99, battle_start: 0, farewell_win: 0, farewell_lose: 0 }
  } } }))
})

test('random win transfers the played card and gold charm bonus once', () => {
  const source = guild()
  const ready = equipItem({ ...source, player: { ...source.player, items: ['gold_charm'] } }, 'gold_charm')
  const pending = enterTown(ready, 'guild_street', rolls(.2, .01))
  const battle = acceptTownEncounter(pending, battleDeck(ready))
  const terminal = playRandomBattleRound(battle, 0, 0)
  const settled = settleRandomBattle(terminal, .999)
  assert.equal(settled.player.money, ready.player.money + 35)
  assert.equal(settled.player.inventory.length, ready.player.inventory.length + 1)
  assert.deepEqual(settled.player.items, ready.player.items)
  assert.equal(settled.progress.random_battles_completed, 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
  const returned = returnToGuildFromTown(settled)
  assert.equal(returned.progress.checkpoint_id, 'guild.home')
  assert.equal(returned.progress.random_battles_completed, 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(returned))), returned)
  assert.throws(() => settleRandomBattle(settled, 0, 0))
})

test('battle items adjust the next-hand prediction, prevent a card loss or preserve HP once, and are consumed', () => {
  const source = guild()
  const items = parseSave({ ...source, player: { ...source.player, items: ['substitute_card', 'iron_shield', 'rock_attract_white'] } })
  const pending = enterTown(items, 'guild_street', rolls(.1, 0))
  const battle = acceptTownEncounter(pending, battleDeck(items))
  const rock = battle.progress.random_battle!.player_deck[2]!
  const adjusted = randomBattleProbabilities(battle, rock, 'rock_attract_white')
  assert.ok(Math.abs(adjusted.rock - .3833333333333333) < 1e-12)
  assert.ok(Math.abs(adjusted.scissors - .3083333333333333) < 1e-12)
  assert.ok(Math.abs(adjusted.paper - .3083333333333333) < 1e-12)

  const protectedLoss = playRandomBattleRound(battle, 2, .99, 'substitute_card')
  assert.equal(randomBattleView(protectedLoss).outcome, 'lose')
  const settled = settleRandomBattle(protectedLoss, .5)
  assert.equal(settled.player.inventory.length, items.player.inventory.length)
  assert.deepEqual(settled.player.items, ['iron_shield', 'rock_attract_white'])

  const shielded = playRandomBattleRound(battle, 2, .99, 'iron_shield')
  assert.equal(randomBattleView(shielded).outcome, undefined)
  assert.equal(randomBattleView(shielded).playerHp, 1)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(shielded))), shielded)
})

test('random drops follow Godot progression pools and are granted only on victory', () => {
  const source = guild()
  const progressed = parseSave({ ...source, progress: { ...source.progress, flags: [...source.progress.flags, 'sub1_cleared'] } })
  const normalEncounter = enterTown(progressed, 'guild_street', rolls(.2, 0))
  assert.equal(normalEncounter.progress.random_battle?.item_reward_id, 'substitute_card')
  const normalBattle = acceptTownEncounter(normalEncounter, battleDeck(progressed))
  const normalWin = settleRandomBattle(playRandomBattleRound(normalBattle, 0, 0), 0)
  assert.ok(normalWin.player.items?.includes('substitute_card'))

  const rareEncounter = enterTown(source, 'guild_street', rolls(.2, .99))
  assert.equal(rareEncounter.progress.random_battle?.char_type, 'rare')
  assert.equal(rareEncounter.progress.random_battle?.item_reward_id, 'substitute_card')
  const rareBattle = acceptTownEncounter(rareEncounter, battleDeck(source))
  const rareLoss = settleRandomBattle(playRandomBattleRound(rareBattle, 2, .99), .5)
  assert.ok(!rareLoss.player.items?.includes('substitute_card'))
})

test('normal and rare drop tables advance by subevent and Stage 4 flags', () => {
  const source = guild()
  const cases = [
    { charRoll: 0, flag: PROGRESSION_FLAGS.subevent4Cleared, expected: 'rock_attract_white' },
    { charRoll: 0, flag: PROGRESSION_FLAGS.stage4Cleared, expected: 'rock_attract_crimson' },
    { charRoll: .99, flag: PROGRESSION_FLAGS.subevent4Cleared, expected: 'rock_attract_crimson' },
    { charRoll: .99, flag: PROGRESSION_FLAGS.stage4Cleared, expected: 'rock_attract_gold' }
  ] as const
  for (const entry of cases) {
    const flagged = parseSave({ ...source, progress: { ...source.progress, flags: [...source.progress.flags, entry.flag] } })
    const pending = enterTown(flagged, 'guild_street', rolls(.2, entry.charRoll))
    assert.equal(pending.progress.random_battle?.item_reward_id, entry.expected)
  }
})

test('town encounter generation rolls all three hands and grades within the selected area range', () => {
  const source = guild()
  const street = enterTown(source, 'guild_street', rolls(.99, 0))
  const generated = travelTown(street, 'slum', { encounter: .1, opponent: .1,
    cards: [{ hand: .01, grade: .99 }, { hand: .34, grade: .01 }, { hand: .99, grade: .55 }], drop: .5 })
  assert.deepEqual(generated.progress.random_battle?.opponent_deck, [
    { hand: 'rock', grade: 2 }, { hand: 'scissors', grade: 1 }, { hand: 'paper', grade: 2 }
  ])
})

test('Greed Ring captures a second unplayed opponent card and records the choice for reload', () => {
  const source = guild()
  const withRing = equipItem({ ...source, player: { ...source.player, items: ['greed_ring'] } }, 'greed_ring')
  const pending = enterTown(withRing, 'guild_street', rolls(.2, .01))
  const battle = acceptTownEncounter(pending, battleDeck(withRing))
  const terminal = playRandomBattleRound(battle, 0, 0)
  const settled = settleRandomBattle(terminal, .5, .99)
  const ledger = settled.progress.random_battle!
  const playedOpponentIndex = ledger.rounds[0]!.opponent_index
  assert.equal(settled.player.inventory.length, withRing.player.inventory.length + 2)
  assert.notEqual(ledger.bonus_capture_index, playedOpponentIndex)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('random loss removes a played card and deducts one quarter of reward without going below zero', () => {
  const source = guild()
  const pending = enterTown(source, 'guild_street', rolls(.1, 0))
  assert.equal(pending.progress.random_battle?.opponent_id, 'thug_01')
  const battle = acceptTownEncounter(pending, battleDeck(source))
  const terminal = playRandomBattleRound(battle, 2, .99)
  assert.equal(randomBattleView(terminal).outcome, 'lose')
  const settled = settleRandomBattle(terminal, .5, .5)
  assert.equal(settled.player.money, source.player.money - 5)
  assert.equal(settled.player.inventory.length, source.player.inventory.length - 1)
  assert.equal(settled.player.items.length, source.player.items.length)
  assert.equal(settled.progress.random_battles_completed, 1)
})

test('a random draw keeps both cards available so the player can choose again', () => {
  const source = guild()
  const pending = enterTown(source, 'guild_street', { ...rolls(.1, 0),
    cards: [{ hand: 0, grade: 0 }, { hand: 0, grade: 0 }, { hand: 0, grade: 0 }] })
  const deck = [
    source.player.inventory.find((card) => card.hand === 'rock')!,
    source.player.inventory.find((card) => card.hand === 'paper')!,
    source.player.inventory.find((card) => card.hand === 'scissors')!
  ]
  let battle = acceptTownEncounter(pending, deck)
  battle = playRandomBattleRound(battle, 0, 0)
  assert.equal(randomBattleView(battle).last?.result, 'draw')
  assert.deepEqual(randomBattleView(battle).usedPlayer, [])
  assert.deepEqual(randomBattleView(battle).usedOpponent, [])
  battle = acknowledgeRandomBattleRound(battle)
  battle = playRandomBattleRound(battle, 1, 0)
  assert.equal(randomBattleView(battle).outcome, 'win')
  const settled = settleRandomBattle(battle, .5)
  assert.equal(settled.player.inventory.length, source.player.inventory.length + 1)
})

test('random loss preserves the minimum three-card town deck to prevent a progression softlock', () => {
  let source = guild()
  const loseOneCard = (current: SaveData) => {
    const card = current.player.inventory[0]!
    const counter: Record<typeof card.hand, typeof card.hand> = { rock: 'paper', scissors: 'rock', paper: 'scissors' }
    const handRoll = { rock: .01, scissors: .34, paper: .67 }[counter[card.hand]]
    const pending = enterTown(current, 'guild_street', { encounter: .1, opponent: 0,
      cards: [{ hand: handRoll, grade: 0 }, { hand: handRoll, grade: 0 }, { hand: handRoll, grade: 0 }], drop: 0 })
    const battle = acceptTownEncounter(pending, current.player.inventory.slice(0, 3))
    const terminal = playRandomBattleRound(battle, 0, 0)
    return { terminal, settled: settleRandomBattle(terminal, .5) }
  }
  while (source.player.inventory.length > 3) {
    const { settled } = loseOneCard(source)
    source = returnToGuildFromTown(continueTownAfterBattle(settled))
  }
  const finalLoss = loseOneCard(source)
  assert.equal(randomBattleView(finalLoss.terminal).outcome, 'lose')
  const { settled } = finalLoss
  assert.equal(settled.player.inventory.length, 3)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('no-encounter arrival persists its area, enforces connected movement and can return to guild', () => {
  const source = guild()
  const arrival = enterTown(source, 'market', rolls(.9, 0))
  assert.equal(arrival.progress.checkpoint_id, 'town.area')
  assert.equal(arrival.progress.town_area, 'market')
  assert.throws(() => travelTown(arrival, 'outside', rolls(.9, 0)))
  const port = travelTown(arrival, 'port', rolls(.9, 0))
  assert.equal(port.progress.town_area, 'port')
  assert.equal(returnToGuildFromTown(port).progress.checkpoint_id, 'guild.home')
})

test('town and random encounter reject stale checkpoints, invalid rolls, unavailable items and forged ledgers', () => {
  const source = guild()
  assert.equal(canEnterTown(source), true)
  assert.equal(canEnterTown({ ...source, progress: { ...source.progress, checkpoint_id: 'town.area' } }), false)
  assert.throws(() => enterTown(source, 'unknown', rolls(.1, 0)))
  assert.throws(() => enterTown(source, 'market', { ...rolls(.1, 0), encounter: Number.NaN }))
  assert.throws(() => travelTown(source, 'market', rolls(.1, 0)))
  assert.throws(() => declineTownEncounter(source))
  assert.throws(() => randomBattleDialogue(source, 'greeting'))
  const pending = enterTown(source, 'guild_street', rolls(.1, 0))
  const oldLedger = { ...pending.progress.random_battle! }
  delete (oldLedger as { dialogue_indexes?: unknown }).dialogue_indexes
  const oldSave = { ...pending, progress: { ...pending.progress, random_battle: oldLedger } }
  assert.equal(randomBattleDialogue(oldSave, 'greeting'), townContent.opponents.thug_01.dialogues.greetings[0])
  assert.throws(() => acceptTownEncounter(pending, []))
  const battle = acceptTownEncounter(pending, battleDeck(source))
  assert.throws(() => playRandomBattleRound(battle, 0, Number.NaN))
  assert.throws(() => playRandomBattleRound(battle, 0, 0, 'unknown_item'))
  assert.throws(() => playRandomBattleRound(pending, 0, 0))
  assert.throws(() => settleRandomBattle(battle, 0))
  assert.throws(() => settleRandomBattle(playRandomBattleRound(battle, 0, 0), 1))
  assert.throws(() => acknowledgeRandomBattleRound(playRandomBattleRound(battle, 0, 0)))
  assert.throws(() => returnToGuildFromTown(battle))
  assert.throws(() => continueTownAfterBattle(battle))
  assert.throws(() => parseSave({ ...pending, progress: { ...pending.progress, random_battle: {
    ...pending.progress.random_battle, balance_before: -1
  } } }))
  assert.throws(() => parseSave({ ...pending, player: { ...pending.player, equipment: ['gold_charm'] } }))
  const ledger = pending.progress.random_battle!
  const forged = [
    { area_id: 'unknown_area' }, { opponent_id: 'unknown_opponent' }, { opponent_name: '偽名' },
    { char_type: 'rare' }, { item_reward_id: 'unknown_item' },
    { gold_reward: { min: -1, max: 2 } }, { loss_gold: 999 }, { acknowledged: -1 },
    { rounds: [{ player_index: 9, opponent_index: 9 }] }, { opponent_deck: [] }
  ]
  for (const [index, changes] of forged.entries()) {
    assert.throws(() => parseSave({ ...pending, progress: { ...pending.progress,
      random_battle: { ...ledger, ...changes } } }), `forged random battle field ${index}`)
  }
})
