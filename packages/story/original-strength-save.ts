import { parseSave, type SaveData } from '../domain/save'
export function finishOriginalStrengthSave(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_strength_game
  if (!ledger?.game.outcome || ledger.cursor !== ledger.game.commands.length) throw new Error('Original strength dialogue is incomplete')
  const { original_strength_game: _finished, ...progress } = current.progress
  return parseSave({ ...current, progress: { ...progress,
    original_completed_minigames: [...(progress.original_completed_minigames ?? []), progress.checkpoint_id] } })
}
