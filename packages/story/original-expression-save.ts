import { parseSave, type SaveData } from '../domain/save'

/** Main.gd completes minigames in place, without normal-battle settlement. */
export function finishOriginalExpressionSave(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_expression_game
  if (!ledger?.game.outcome || ledger.cursor !== ledger.game.commands.length) throw new Error('Original expression dialogue is incomplete')
  const { original_expression_game: _finished, ...progress } = current.progress
  return parseSave({ ...current, progress: { ...progress,
    original_completed_minigames: [...(progress.original_completed_minigames ?? []), progress.checkpoint_id] } })
}
