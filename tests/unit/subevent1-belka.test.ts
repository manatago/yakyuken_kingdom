import assert from 'node:assert/strict'
import { existsSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { validateContent } from '../../packages/content/validate'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { acknowledgeTutorial, playTutorialRound, prepareTutorial } from '../../packages/battle/tutorial'
import { acknowledgeFixedRound, fixedView, prepareFixedBattle, playFixedRound, settleFixedBattle } from '../../packages/battle/fixed'
import { enterGuildHome } from '../../packages/guild/home'
import { PROGRESSION_FLAGS } from '../../packages/domain/progression'
import { startSubevent1JinStory } from '../../packages/battle/jin'
import { equipItem, unequipItem } from '../../packages/domain/equipment'
import { startSubevent1Belka, playSubevent1BelkaRound, acknowledgeSubevent1BelkaRound,
  settleSubevent1Belka, continueSubevent1Belka, returnSubevent1BelkaToGuild, subevent1BelkaContent, subevent1BelkaView } from '../../packages/battle/subevent1-belka'

const root = fileURLToPath(new URL('../..', import.meta.url))

function readySave() {
  const initial = createInitialGameSave()
  const preparing = { ...initial, player: { ...initial.player, money: 100 },
    progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }
  let save = prepareTutorial(preparing, preparing.player.inventory)
  save = acknowledgeTutorial(playTutorialRound(save, 6, 0))
  save = acknowledgeTutorial(playTutorialRound(save, 0, 0))
  save = prepareFixedBattle({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.await' } })
  for (const index of [6, 7, 8]) {
    save = playFixedRound(save, index, 0)
    if (!fixedView(save).outcome) save = acknowledgeFixedRound(save)
  }
  save = settleFixedBattle(save, 0)
  const guild = enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end',
    flags: [...save.progress.flags, 'adventurer.tutorial.completed'], random_battles_completed: 3 } }))
  const story = startSubevent1JinStory(guild, [guild.player.inventory[0]!, guild.player.inventory[3]!, guild.player.inventory[6]!])
  return parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.belka.challenge' } })
}

function playToEnd(save: ReturnType<typeof readySave>, playerIndex: number, roll: number, bonusRoll = 0.5) {
  let next = save
  for (let i = 0; i < 3; i++) {
    next = playSubevent1BelkaRound(next, playerIndex + i, roll, undefined, bonusRoll)
    const result = subevent1BelkaView(next)
    if (result.outcome) break
    next = acknowledgeSubevent1BelkaRound(next)
  }
  return next
}

test('Subevent 1 Belka content is valid and independent from verification content', () => {
  assert.deepEqual(validateContent(subevent1BelkaContent, (path) => existsSync(`${root}/${path}`)), { valid: true, issues: [] })
  assert.notEqual(subevent1BelkaContent.battles.find((entry) => entry.id === 'battle.subevent1.belka'),
    subevent1BelkaContent.battles.find((entry) => entry.id === 'battle.belka'))
})

test('Belka rejects invalid entry, round, and premature transition requests', () => {
  const original = readySave()
  assert.throws(() => startSubevent1Belka(parseSave({ ...original,
    progress: { ...original.progress, checkpoint_id: 'guild.home' } })), /Nine owned cards/)
  const started = startSubevent1Belka(original)
  assert.throws(() => playSubevent1BelkaRound(started, 0, 1), /Invalid random roll/)
  assert.throws(() => playSubevent1BelkaRound(started, -1, 0.5), /player card|index|Invalid/i)
  assert.throws(() => acknowledgeSubevent1BelkaRound(started), /No pending Belka result/)
  assert.throws(() => settleSubevent1Belka(started, 0.5), /terminal Belka result/)
  assert.throws(() => continueSubevent1Belka(started), /not ready to continue/)
  assert.throws(() => returnSubevent1BelkaToGuild(started), /not complete/)
})

test('story Belka victory waits through the guard scene and settles once at the receptionist', () => {
  const original = readySave(), started = startSubevent1Belka(original)
  assert.equal(started.progress.checkpoint_id, 'subevent1.belka.await')
  assert.equal(started.progress.subevent1_belka_battle?.player_deck.length, 9)
  let terminal = playToEnd(started, 3, 0.8)
  assert.equal(subevent1BelkaView(terminal).outcome, 'win')

  let aftermath = continueSubevent1Belka(terminal)
  assert.equal(aftermath.progress.checkpoint_id, 'subevent1.belka.after')
  assert.equal(aftermath.progress.subevent1_belka_battle?.settled, false)
  assert.equal(aftermath.player.money, started.player.money)
  assert.deepEqual(aftermath.player.inventory, started.player.inventory)
  assert.deepEqual(aftermath.player.items, started.player.items)
  assert.throws(() => settleSubevent1Belka(terminal, 0.5), /designated checkpoint/)

  for (const checkpoint_id of ['subevent1.belka.disband', 'subevent1.belka.guard-arrives',
    'subevent1.belka.guard-recognizes', 'subevent1.belka.guard-report']) {
    aftermath = parseSave({ ...aftermath, progress: { ...aftermath.progress, checkpoint_id } })
  }
  assert.throws(() => parseSave({ ...aftermath,
    progress: { ...aftermath.progress, checkpoint_id: 'subevent1.belka.reception-background' } }))
  const atReception = parseSave({ ...aftermath, progress: { ...aftermath.progress, checkpoint_id: 'subevent1.belka.report' } })
  terminal = settleSubevent1Belka(atReception, 0.5)
  assert.equal(terminal.player.money, original.player.money + 50)
  assert.equal(terminal.player.inventory.length, original.player.inventory.length + 3)
  assert.deepEqual(terminal.player.items, ['greed_ring', 'rock_attract_crimson'])
  const legacyLedger = { ...terminal.progress.subevent1_belka_battle! }
  delete (legacyLedger as { capture_bonus_enabled?: boolean }).capture_bonus_enabled
  assert.deepEqual(parseSave({ ...terminal, progress: { ...terminal.progress, subevent1_belka_battle: legacyLedger } })
    .progress.subevent1_belka_battle, legacyLedger)
  assert.throws(() => settleSubevent1Belka(terminal, 0.5), /terminal Belka result/)
  assert.throws(() => parseSave({ ...terminal, player: { ...terminal.player, inventory: terminal.player.inventory.slice(0, -1) } }),
    /Invalid Subevent 1 Belka settlement/)
  assert.throws(() => parseSave({ ...terminal, player: { ...terminal.player, items: ['greed_ring'] } }),
    /Invalid Subevent 1 Belka settlement/)
  const atEnd = parseSave({ ...terminal, progress: { ...terminal.progress, checkpoint_id: 'subevent1.belka.end' } })
  const home = returnSubevent1BelkaToGuild(atEnd)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.ok(home.progress.flags.includes(PROGRESSION_FLAGS.subevent1Cleared))
})

test('story Belka defeat removes lost cards, deducts the configured gold and returns to guild', () => {
  const original = readySave()
  let terminal = playToEnd(startSubevent1Belka(original), 0, 0.99)
  assert.equal(subevent1BelkaView(terminal).outcome, 'lose')
  terminal = settleSubevent1Belka(terminal, 0.5)
  assert.equal(terminal.player.money, original.player.money - 25)
  assert.equal(terminal.player.inventory.length, original.player.inventory.length - 3)
  assert.deepEqual(terminal.player.items, [])
  const home = returnSubevent1BelkaToGuild(terminal)
  assert.equal(home.progress.checkpoint_id, 'guild.home')
  assert.ok(!home.progress.flags.includes(PROGRESSION_FLAGS.subevent1Cleared))
})

test('legacy Matilda ledger without an inventory snapshot remains valid after later Subevent 1 card losses', () => {
  const source = readySave()
  const { inventory_before: _legacySnapshot, ...legacyFixedLedger } = source.progress.fixed_battle!
  const legacy = parseSave({ ...source, progress: { ...source.progress, fixed_battle: legacyFixedLedger } })
  const started = startSubevent1Belka(legacy)
  const terminal = playToEnd(started, 0, .99)
  assert.equal(subevent1BelkaView(terminal).outcome, 'lose')
  const settled = settleSubevent1Belka(terminal, .5)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('story Belka records consumable use, protects the selected card, and consumes once on loss', () => {
  const original = readySave()
  const owned = { ...original, player: { ...original.player, items: ['substitute_card'] } }
  const started = startSubevent1Belka(owned)
  let pending = playSubevent1BelkaRound(started, 0, .99, 'substitute_card')
  assert.deepEqual(pending.progress.subevent1_belka_battle?.round_item_ids, ['substitute_card'])
  pending = acknowledgeSubevent1BelkaRound(pending)
  const terminal = playToEnd(pending, 1, .99)
  assert.equal(subevent1BelkaView(terminal).outcome, 'lose')
  const settled = settleSubevent1Belka(terminal, .5)
  assert.equal(settled.player.inventory.length, owned.player.inventory.length - 2)
  assert.deepEqual(settled.player.items, [])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('story Belka snapshots the gold charm bonus and allows equipment changes after settlement', () => {
  const source = readySave()
  const equipped = equipItem({ ...source, player: { ...source.player, items: ['gold_charm'] } }, 'gold_charm')
  let terminal = playToEnd(startSubevent1Belka(equipped), 3, 0.8)
  let aftermath = continueSubevent1Belka(terminal)
  for (const checkpoint_id of ['subevent1.belka.disband', 'subevent1.belka.guard-arrives',
    'subevent1.belka.guard-recognizes', 'subevent1.belka.guard-report']) {
    aftermath = parseSave({ ...aftermath, progress: { ...aftermath.progress, checkpoint_id } })
  }
  aftermath = parseSave({ ...aftermath, progress: { ...aftermath.progress, checkpoint_id: 'subevent1.belka.report' } })
  terminal = settleSubevent1Belka(aftermath, .999)
  assert.equal(terminal.player.money, equipped.player.money + 80)
  assert.deepEqual(terminal.progress.subevent1_belka_battle?.equipment_before, ['gold_charm'])
  const end = parseSave({ ...terminal, progress: { ...terminal.progress, checkpoint_id: 'subevent1.belka.end' } })
  const home = returnSubevent1BelkaToGuild(end)
  assert.deepEqual(unequipItem(home, 'gold_charm').player.equipment, [])
})

test('story Belka Greed Ring captures one unused opponent card for every winning round', () => {
  const base = readySave()
  const source = { ...base, player: { ...base.player, items: ['greed_ring'] } }
  const equipped = equipItem(source, 'greed_ring')
  let terminal = playToEnd(startSubevent1Belka(equipped), 3, 0.8, 0.25)
  const ledger = terminal.progress.subevent1_belka_battle!
  assert.equal(ledger.capture_bonus_enabled, true)
  assert.equal(subevent1BelkaView(terminal).outcome, 'win')
  assert.equal(ledger.rounds.filter((round) => round.bonus_capture_index !== undefined).length, 3)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(terminal))), terminal)

  let aftermath = continueSubevent1Belka(terminal)
  for (const checkpoint_id of ['subevent1.belka.disband', 'subevent1.belka.guard-arrives',
    'subevent1.belka.guard-recognizes', 'subevent1.belka.guard-report']) {
    aftermath = parseSave({ ...aftermath, progress: { ...aftermath.progress, checkpoint_id } })
  }
  terminal = settleSubevent1Belka(parseSave({ ...aftermath,
    progress: { ...aftermath.progress, checkpoint_id: 'subevent1.belka.report' } }), 0.5)
  assert.equal(terminal.player.inventory.length, equipped.player.inventory.length + 6)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(terminal))), terminal)
  const forged = parseSave(JSON.parse(JSON.stringify(terminal)))
  const battle = forged.progress.subevent1_belka_battle!
  const rounds = battle.rounds.map((round, index) => index === 0
    ? { ...round, bonus_capture_index: round.opponent_index } : round)
  assert.throws(() => parseSave({ ...forged, progress: { ...forged.progress,
    subevent1_belka_battle: { ...battle, rounds } } }), /Greed Ring capture/)
})

test('Subevent 1 aftermath content includes the guard scene and receptionist payment', () => {
  const steps = subevent1BelkaContent.stories[0]!.steps
  const report = steps.find((step) => step.id === 'subevent1.belka.report')
  const close = steps.find((step) => step.id === 'subevent1.belka.reception-close')
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.guard-arrives')?.kind, 'line')
  assert.equal(report?.kind, 'line')
  assert.match(report?.kind === 'line' ? report.text : '', /金貨\{\{belkaRewardGold\}\}枚/)
  assert.match(close?.kind === 'line' ? close.text : '', /金貨\{\{belkaRewardGold\}\}枚/)
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.reception-background')?.kind, 'background')
})
