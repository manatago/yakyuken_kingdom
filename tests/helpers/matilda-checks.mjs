import assert from 'node:assert/strict'

// Cross-screen invariants shared by the domain journey and real-app journey.
export function assertMatildaSave(save, initial, { checkpoint, deckSize, rounds, acknowledged }) {
  assert.equal(save.save_version, 1)
  assert.deepEqual(save.player.inventory, initial.player.inventory)
  assert.equal(save.player.money, initial.player.money)
  assert.equal(save.player.deck.length, deckSize)
  assert.equal(save.progress.checkpoint_id, checkpoint)
  assert.deepEqual(save.progress.flags, [...initial.progress.flags,
    ...(acknowledged === 2 ? ['matilda.tutorial.completed'] : [])])
  if (deckSize === 9) {
    const cards = (deck) => deck.map(({ hand, grade }) => `${hand}:${grade}`).sort()
    assert.deepEqual(cards(save.player.deck), cards(initial.player.inventory))
  }
  if (rounds === null) {
    assert.equal(save.progress.tutorial, undefined)
    return
  }
  assert.equal(save.progress.tutorial?.battle_id, 'battle.matilda.practice')
  assert.equal(save.progress.tutorial.rounds.length, rounds)
  assert.equal(save.progress.tutorial.acknowledged, acknowledged)
}
