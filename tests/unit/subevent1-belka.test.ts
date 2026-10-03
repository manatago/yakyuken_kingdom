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
import { startSubevent1JinStory } from '../../packages/battle/jin'
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
  const guild = enterGuildHome(parseSave({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.normal.end' } }))
  const story = startSubevent1JinStory(guild, [guild.player.inventory[0]!, guild.player.inventory[3]!, guild.player.inventory[6]!])
  return parseSave({ ...story, progress: { ...story.progress, checkpoint_id: 'subevent1.belka.challenge' } })
}

function playToEnd(save: ReturnType<typeof readySave>, playerIndex: number, roll: number) {
  let next = save
  for (let i = 0; i < 3; i++) {
    next = playSubevent1BelkaRound(next, playerIndex + i, roll)
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
  assert.throws(() => settleSubevent1Belka(terminal, 0.5), /terminal Belka result/)
  assert.throws(() => parseSave({ ...terminal, player: { ...terminal.player, inventory: terminal.player.inventory.slice(0, -1) } }),
    /Invalid Subevent 1 Belka settlement/)
  assert.throws(() => parseSave({ ...terminal, player: { ...terminal.player, items: ['greed_ring'] } }),
    /Invalid Subevent 1 Belka settlement/)
  const atEnd = parseSave({ ...terminal, progress: { ...terminal.progress, checkpoint_id: 'subevent1.belka.end' } })
  assert.equal(returnSubevent1BelkaToGuild(atEnd).progress.checkpoint_id, 'guild.home')
})

test('story Belka defeat removes lost cards, deducts the configured gold and returns to guild', () => {
  const original = readySave()
  let terminal = playToEnd(startSubevent1Belka(original), 0, 0.99)
  assert.equal(subevent1BelkaView(terminal).outcome, 'lose')
  terminal = settleSubevent1Belka(terminal, 0.5)
  assert.equal(terminal.player.money, original.player.money - 25)
  assert.equal(terminal.player.inventory.length, original.player.inventory.length - 3)
  assert.deepEqual(terminal.player.items, [])
  assert.equal(returnSubevent1BelkaToGuild(terminal).progress.checkpoint_id, 'guild.home')
})

test('Subevent 1 aftermath content includes the guard scene and receptionist payment', () => {
  const steps = subevent1BelkaContent.stories[0]!.steps
  const report = steps.find((step) => step.id === 'subevent1.belka.report')
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.guard-arrives')?.kind, 'line')
  assert.equal(report?.kind, 'line')
  assert.match(report?.kind === 'line' ? report.text : '', /金貨50枚/)
  assert.equal(steps.find((step) => step.id === 'subevent1.belka.reception-background')?.kind, 'background')
})
