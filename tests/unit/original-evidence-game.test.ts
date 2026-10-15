import assert from 'node:assert/strict'
import test from 'node:test'
import { createOriginalEvidenceGame, chooseOriginalEvidence, restoreOriginalEvidenceGame, originalEvidenceSource as source } from '../../packages/story/original-evidence-game'

const rolls = Array(13).fill(0)
test('original evidence grid has exactly one valid pair, locks first support and never mutates previous state', () => {
  const game = createOriginalEvidenceGame(rolls)
  assert.equal(game.chapters.length, 4)
  assert.equal(game.evidences.length, 4)
  assert.equal(source.valid_combos.filter(combo => game.chapters.includes(combo.chapter) && game.evidences.includes(combo.evidence)).length, 1)
  assert.throws(() => chooseOriginalEvidence(game, '_pisuke', 0, rolls))
  const combo = source.valid_combos.find(combo => game.chapters.includes(combo.chapter) && game.evidences.includes(combo.evidence))!
  const first = chooseOriginalEvidence(game, combo, 0, rolls)
  assert.equal(first.gauge, 60)
  assert.equal(game.gauge, 100)
  assert.deepEqual(first.used, [`${combo.chapter}|${combo.evidence}`])
  assert.throws(() => chooseOriginalEvidence(first, combo, 0, rolls))
  const second = chooseOriginalEvidence(first, '_pisuke', 0, rolls)
  const final = chooseOriginalEvidence(second, '_pisuke', 0, rolls)
  assert.equal(final.gauge, 0)
  assert.equal(final.outcome, 'win')
  assert.deepEqual(restoreOriginalEvidenceGame(final), final)
  assert.throws(() => restoreOriginalEvidenceGame({ ...final, gauge: 1 }))
  assert.throws(() => chooseOriginalEvidence(final, '_pisuke', 0, rolls))
})
test('original evidence misses end at 130 and invalid random inputs are rejected', () => {
  let game = createOriginalEvidenceGame(rolls)
  for (let turn = 0; turn < 6; turn++) game = chooseOriginalEvidence(game,
    { chapter: game.chapters.find(key => source.miss_chapter_keys.includes(key))!, evidence: game.evidences[0] }, 0, rolls)
  assert.equal(game.gauge, 130)
  assert.equal(game.outcome, 'lose')
  assert.deepEqual(restoreOriginalEvidenceGame(game), game)
  assert.throws(() => createOriginalEvidenceGame(Array(13).fill(1)))
  assert.throws(() => createOriginalEvidenceGame([]))
})
test('exhausted original pairs give weak repeats and exhausted support has no effect', () => {
  let game = createOriginalEvidenceGame(rolls)
  for (let hit = 0; hit < 7; hit++) {
    const pair = source.valid_combos.find(combo => game.chapters.includes(combo.chapter) && game.evidences.includes(combo.evidence))!
    game = chooseOriginalEvidence(game, pair, 0, rolls)
    for (let miss = 0; miss < 8; miss++) game = chooseOriginalEvidence(game,
      { chapter: game.chapters.find(key => source.miss_chapter_keys.includes(key))!, evidence: game.evidences[0] }, 0, rolls)
  }
  assert.equal(game.used.length, 7)
  const repeated = source.valid_combos.find(combo => game.chapters.includes(combo.chapter) && game.evidences.includes(combo.evidence))!
  game = chooseOriginalEvidence(game, repeated, 0, rolls)
  assert.equal(game.gauge, 105)
  const supported = chooseOriginalEvidence(game, '_pisuke', 0, rolls)
  assert.equal(supported.gauge, 105)
  assert.equal(supported.used.length, 7)
  assert.deepEqual(restoreOriginalEvidenceGame(supported), supported)
})
