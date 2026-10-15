import assert from 'node:assert/strict'
import test from 'node:test'
import { createNewGameSave } from '../../packages/domain/new-game'
import { parseSave } from '../../packages/domain/save'
import { createOriginalEvidenceGame, chooseOriginalEvidence, originalEvidenceSource as source } from '../../packages/story/original-evidence-game'
import { finishOriginalEvidenceSave } from '../../packages/story/original-evidence-save'

test('original evidence saves only at its raw battle and finishes without changing player data', () => {
  const rolls = Array(13).fill(0)
  let game = createOriginalEvidenceGame(rolls)
  const base = createNewGameSave()
  const draft = { ...base, progress: { ...base.progress, checkpoint_id: 'original:stage3_recover:56', original_evidence_game: { game, cursor: 0 } } }
  assert.deepEqual(parseSave(draft).progress.original_evidence_game, draft.progress.original_evidence_game)
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, checkpoint_id: 'original:stage3_recover:55' } }))
  assert.throws(() => finishOriginalEvidenceSave(parseSave(draft)))
  const combo = source.valid_combos.find(combo => game.chapters.includes(combo.chapter) && game.evidences.includes(combo.evidence))!
  game = chooseOriginalEvidence(game, combo, 0, rolls)
  game = chooseOriginalEvidence(game, '_pisuke', 0, rolls)
  game = chooseOriginalEvidence(game, '_pisuke', 0, rolls)
  const save = parseSave({ ...draft, progress: { ...draft.progress, original_evidence_game: { game, cursor: game.commands.length } } })
  const next = finishOriginalEvidenceSave(save)
  assert.deepEqual(next.player, save.player)
  assert.deepEqual(next.progress.original_completed_minigames, ['original:stage3_recover:56'])
  assert.equal(next.progress.checkpoint_id, 'original:stage3_recover:56')
  assert.equal(next.progress.original_evidence_game, undefined)
  assert.throws(() => finishOriginalEvidenceSave(next))
  assert.throws(() => parseSave({ ...draft, progress: { ...draft.progress, original_evidence_game: { game, cursor: -1 } } }))
})
