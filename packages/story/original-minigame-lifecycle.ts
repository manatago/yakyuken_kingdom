import type { CurseCommand } from './original-curse-game'

/** The original frees its gauge/choice root after the last reaction and before ending dialogue. */
export function originalMinigameUiVisible(
  game: { commands: readonly CurseCommand[]; outcome?: 'win' | 'lose' }, cursor: number, endingLength: number
): boolean {
  return !game.outcome || cursor < game.commands.length - endingLength
}
