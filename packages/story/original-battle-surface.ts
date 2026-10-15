import type { BattleTraceCommand } from './original-battle'

export interface OriginalBattleSurface {
  blurred: boolean
  bandVisible: boolean
  band?: { text: string; speaker: string }
  bubble?: { text: string; side: string; revision: number }
}
export const createOriginalBattleSurface = (): OriginalBattleSurface => ({ blurred: true, bandVisible: false })

/** StoryScene's band and SpeechBubble are separate controls, not one text slot. */
export function applyOriginalBattleSurface(surface: OriginalBattleSurface, command?: BattleTraceCommand) {
  if (!command) return
  const args = command.args
  if (command.kind === 'band') {
    surface.band = { text: String(args[1]), speaker: String(args[0]) }
    surface.bandVisible = true
  } else if (command.kind === 'narrator_band') {
    surface.band = { text: String(args[0]), speaker: '' }
    surface.bandVisible = true
  } else if (command.kind === 'bubble') {
    surface.bubble = { text: String(args[0]), side: String((args[1] as Record<string, unknown>)?.side ?? 'center'), revision: (surface.bubble?.revision ?? 0) + 1 }
  } else if (command.kind === 'set_battle_ui_visible') {
    surface.bandVisible = Boolean(args[0])
    if (!surface.bandVisible) surface.blurred = false
  }
}
