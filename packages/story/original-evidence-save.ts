import { parseSave, type SaveData } from '../domain/save'

export function finishOriginalEvidenceSave(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_evidence_game
  if (!ledger?.game.outcome || ledger.cursor !== ledger.game.commands.length) throw new Error('Original evidence dialogue is incomplete')
  const { original_evidence_game: _finished, ...progress } = current.progress
  return parseSave({ ...current, progress: { ...progress,
    original_completed_minigames: [...(progress.original_completed_minigames ?? []), progress.checkpoint_id] } })
}
