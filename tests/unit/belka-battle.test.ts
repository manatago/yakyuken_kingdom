import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave, type SaveData } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial } from '../../packages/battle/tutorial'
import { prepareFixedBattle, playFixedRound, acknowledgeFixedRound, settleFixedBattle, fixedView } from '../../packages/battle/fixed'
import { enterGuildHome, leaveGuildHome } from '../../packages/guild/home'
import { startBelka, playBelkaRound, acknowledgeBelkaRound, settleBelka, returnBelkaToGuild,
  belkaView, belkaProbabilities, belkaBayesProbabilities, belkaContent } from '../../packages/battle/belka'
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
  return enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
}

function outcome(kind: 'win' | 'lose'): SaveData {
  let save = startBelka(guild())
  for (const index of kind === 'win' ? [6, 7, 8] : [3, 4, 5]) {
    save = playBelkaRound(save, index, 0)
    if (!belkaView(save).outcome) save = acknowledgeBelkaRound(save)
  }
  assert.equal(belkaView(save).outcome, kind)
  return save
}

test('Belka content defines independent nine-card encounter and normalized paper tendency', () => {
  assert.deepEqual(validateContent(belkaContent, () => true), { valid: true, issues: [] })
  const battle = belkaContent.battles[0]
  assert.equal(battle.opponent_card_ids.length, 9)
  assert.deepEqual(battle.gold_reward, { min: 40, max: 60 })
  const p = belkaProbabilities(startBelka(guild()))
  assert.ok(Math.abs(p.rock - 3 / 12.6) < 1e-12)
  assert.ok(Math.abs(p.scissors - 3 / 12.6) < 1e-12)
  assert.ok(Math.abs(p.paper - 6.6 / 12.6) < 1e-12)
  const high = belkaProbabilities(startBelka(guild()), { hand: 'rock', grade: 3 })
  const display = belkaBayesProbabilities(startBelka(guild()), { hand: 'rock', grade: 3 })
  assert.ok(high.scissors > display.scissors && display.scissors > p.scissors)
})

test('Belka starts only from eligible guild, snapshots lineup and preserves Matilda history', () => {
  const source = guild()
  const before = structuredClone(source)
  const started = startBelka(source)
  assert.equal(started.progress.checkpoint_id, 'belka.await')
  assert.equal(started.progress.belka_battle?.battle_id, 'battle.belka')
  assert.deepEqual(started.progress.fixed_battle, before.progress.fixed_battle)
  assert.deepEqual(started.progress.tutorial, before.progress.tutorial)
  assert.deepEqual(started.player, before.player)
  assert.deepEqual(source, before)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(started))), started)
  assert.throws(() => startBelka(started))
  assert.throws(() => startBelka(leaveGuildHome(source)))
})

test('Belka rejects invalid rolls and premature round, settlement, and return actions', () => {
  const source = guild()
  const started = startBelka(source)
  assert.throws(() => belkaView(source), /not started/)
  assert.throws(() => playBelkaRound(started, 0, Number.NaN), /random roll/)
  assert.throws(() => acknowledgeBelkaRound(started), /No pending/)
  assert.throws(() => settleBelka(started, 0), /terminal Belka result/)
  assert.throws(() => returnBelkaToGuild(started), /not settled/)
})

test('Belka win and loss settle exactly once and return to guild without erasing history', () => {
  for (const kind of ['win', 'lose'] as const) {
    const pending = outcome(kind)
    assert.throws(() => playBelkaRound(pending, 0, 0))
    const settled = settleBelka(pending, 0.999)
    assert.equal(settled.player.money, pending.player.money + (kind === 'win' ? 60 : -Math.min(pending.player.money, 25)))
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
    assert.throws(() => settleBelka(settled, 0))
    const home = returnBelkaToGuild(settled)
    assert.equal(home.progress.checkpoint_id, 'guild.home')
    assert.equal(home.progress.guild_return_checkpoint, 'matilda.normal.end')
    assert.deepEqual(home.progress.fixed_battle, pending.progress.fixed_battle)
    assert.deepEqual(home.progress.tutorial, pending.progress.tutorial)
    assert.deepEqual(home.player.inventory, pending.player.inventory)
    assert.deepEqual(home.player.deck, pending.player.deck)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(home))), home)
    assert.throws(() => startBelka(home))
  }
})

test('Belka snapshots the gold charm bonus and permits changing equipment after settlement', () => {
  const source = guild()
  const equipped = equipItem({ ...source, player: { ...source.player, items: ['gold_charm'] } }, 'gold_charm')
  let pending = startBelka(equipped)
  for (const index of [6, 7, 8]) {
    pending = playBelkaRound(pending, index, 0)
    if (!belkaView(pending).outcome) pending = acknowledgeBelkaRound(pending)
  }
  const settled = settleBelka(pending, .999)
  assert.equal(settled.player.money, equipped.player.money + 80)
  assert.deepEqual(settled.progress.belka_battle?.equipment_before, ['gold_charm'])
  assert.deepEqual(unequipItem(settled, 'gold_charm').player.equipment, [])
})

test('Belka records a per-round probability item and consumes it once when settling', () => {
  const source = guild()
  const owned = { ...source, player: { ...source.player, items: ['rock_attract_white'] as const } }
  let pending = startBelka(owned)
  for (const [round, index] of [6, 7, 8].entries()) {
    pending = playBelkaRound(pending, index, 0, round === 0 ? 'rock_attract_white' : undefined)
    if (!belkaView(pending).outcome) pending = acknowledgeBelkaRound(pending)
  }
  assert.equal(belkaView(pending).outcome, 'win')
  assert.deepEqual(pending.progress.belka_battle?.round_item_ids, ['rock_attract_white', null, null])
  const settled = settleBelka(pending, 0)
  assert.deepEqual(settled.player.items, [])
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(settled))), settled)
})

test('Belka save rejects missing history, forged checkpoint and unsettled home', () => {
  const pending = outcome('win')
  for (const mutate of [
    (s: any) => { delete s.progress.belka_battle },
    (s: any) => { s.progress.belka_battle.battle_id = 'other' },
    (s: any) => { s.progress.belka_battle.rounds[1].player_index = 6 },
    (s: any) => { s.progress.checkpoint_id = 'guild.home'; s.progress.guild_return_checkpoint = 'matilda.normal.end' },
    (s: any) => { s.progress.belka_battle.settled = true },
    (s: any) => { delete s.progress.fixed_battle }
  ]) {
    const bad = structuredClone(pending)
    mutate(bad)
    assert.throws(() => parseSave(bad))
  }
})
