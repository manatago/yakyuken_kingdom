import { parseSave, type SaveData } from '../domain/save'

/** Main.gd's is_minigame branch only completes the command: no normal-battle aftermath. */
export function finishOriginalCurseSave(save: SaveData): SaveData {
  const current = parseSave(save)
  const ledger = current.progress.original_curse_game
  const quest = current.progress.original_quest
  if (!ledger?.game.outcome || ledger.cursor !== ledger.game.commands.length || !quest) throw new Error('Original minigame has not finished its dialogue')
  const { original_curse_game: _finished, ...progress } = current.progress
  return parseSave({ ...current, progress: { ...progress, original_quest: { ...quest,
    completed_battles: [...(quest.completed_battles ?? []), current.progress.checkpoint_id] } } })
}
