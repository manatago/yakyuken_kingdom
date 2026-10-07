import assert from 'node:assert/strict'
import test from 'node:test'
import { createInitialGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { prepareTutorial, playTutorialRound, acknowledgeTutorial, tutorialView, tutorialBattle } from '../../packages/battle/tutorial'

function prepared() {
  const save = createInitialGameSave()
  return prepareTutorial({ ...save, progress: { ...save.progress, checkpoint_id: 'matilda.await-deck' } }, save.player.inventory)
}

test('tutorial preparation validates nine owned Normal copies without changing inventory', () => {
  const initial = createInitialGameSave()
  const preparing = { ...initial, progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }
  const ready = prepared()
  assert.equal(ready.player.deck.length, 9)
  assert.deepEqual(ready.player.inventory, initial.player.inventory)
  assert.deepEqual(parseSave(JSON.parse(JSON.stringify(ready))), ready)
  assert.throws(() => prepareTutorial(initial, initial.player.inventory))
  assert.throws(() => prepareTutorial(preparing, initial.player.inventory.slice(0, 8)), /Nine owned Normal cards required/)
  assert.throws(() => prepareTutorial(preparing, Array(9).fill({ hand: 'paper', grade: 1 })), /Nine owned Normal cards required/)
  const bronze = { ...initial, player: { ...initial.player, inventory: Array(9).fill({ hand: 'rock', grade: 2 as const }) },
    progress: { ...initial.progress, checkpoint_id: 'matilda.await-deck' } }
  assert.throws(() => prepareTutorial(bronze, bronze.player.inventory))
})

test('first rock is fixed, persisted result cannot be played twice and draw refunds cards', () => {
  for (const [index, result, playerHp, opponentHp] of [[0, 'draw', 3, 3], [3, 'lose', 2, 3], [6, 'win', 3, 2]] as const) {
    const ready = prepared()
    const played = playTutorialRound(ready, index, .5)
    const view = tutorialView(played)
    assert.equal(view.last!.result, result)
    assert.equal(view.last!.opponent.hand, 'rock')
    assert.equal(view.playerHp, playerHp)
    assert.equal(view.opponentHp, opponentHp)
    assert.deepEqual(view.usedPlayer, result === 'draw' ? [] : [index])
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(played))), played)
    assert.throws(() => playTutorialRound(played, index, .1))
    assert.deepEqual(ready.progress.tutorial!.rounds, [])
  }
})

test('second round follows 80 percent win rate, consumes available cards and finishes after two', () => {
  const first = acknowledgeTutorial(playTutorialRound(prepared(), 6, 0))
  for (const [roll, expected] of [[0, 'win'], [.799999, 'win'], [.8, 'lose'], [.899999, 'lose'], [.9, 'draw'], [.999999, 'draw']] as const) {
    const second = playTutorialRound(first, 0, roll)
    assert.equal(tutorialView(second).last!.result, expected)
    const done = acknowledgeTutorial(second)
    assert.equal(done.progress.checkpoint_id, 'matilda.complete')
    assert.deepEqual(done.progress.flags, ['matilda.tutorial.completed'])
    assert.equal(done.player.money, 0)
    assert.deepEqual(done.player.inventory, first.player.inventory)
    assert.deepEqual(parseSave(JSON.parse(JSON.stringify(done))), done)
    assert.throws(() => playTutorialRound(done, 1, 0))
  }
  assert.throws(() => playTutorialRound(first, 6, 0))
  assert.throws(() => playTutorialRound(first, -1, 0))
  assert.throws(() => playTutorialRound(first, 0, 1))
  assert.equal(tutorialBattle.phases[1].rules[0].kind, 'player_win_rate')
})

test('save validation rejects forged battle ledgers, reuse and inconsistent checkpoints', () => {
  const good = playTutorialRound(prepared(), 6, 0)
  const corrupt = (edit: (save: any) => void) => {
    const save = structuredClone(good)
    edit(save)
    assert.throws(() => parseSave(save))
  }
  corrupt((s) => { s.progress.tutorial.battle_id = 'unknown' })
  corrupt((s) => { s.progress.tutorial.rounds[0].opponent_index = 3 })
  corrupt((s) => { s.progress.tutorial.rounds[0].player_index = 99 })
  corrupt((s) => { s.progress.tutorial.acknowledged = 2 })
  corrupt((s) => { s.progress.checkpoint_id = 'matilda.complete' })
  corrupt((s) => { s.progress.flags.push('matilda.tutorial.completed') })
  corrupt((s) => { s.progress.tutorial.rounds.push(s.progress.tutorial.rounds[0]); s.progress.tutorial.acknowledged = 1 })
  corrupt((s) => { s.progress.tutorial.extra = true })
  assert.deepEqual(parseSave(createInitialGameSave()), createInitialGameSave())
})

test('completed tutorial replay remains valid after real card losses change the active deck', () => {
  const first = acknowledgeTutorial(playTutorialRound(prepared(), 6, 0))
  const completed = acknowledgeTutorial(playTutorialRound(first, 0, 0))
  const inventory = completed.player.inventory.filter((_, index) => index >= 3)
  const activeDeck = completed.player.deck.slice(3)
  const afterLoss = { ...completed, player: { ...completed.player, inventory, deck: activeDeck } }
  assert.doesNotThrow(() => parseSave(JSON.parse(JSON.stringify(afterLoss))))
  assert.deepEqual(parseSave(afterLoss).progress.tutorial?.player_deck, completed.progress.tutorial?.player_deck)
  assert.equal(tutorialView(afterLoss).opponentHp, tutorialView(completed).opponentHp)
})
