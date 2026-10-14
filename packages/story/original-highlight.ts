import { originalPrologueBattleTraces, type OriginalBattlePlayback } from './original-battle'

export function originalHighlightPlacement(target: string, rect: number[], options: Record<string, unknown> = {}) {
  const [x, y, width, height] = rect
  let direction = String(options.direction ?? 'auto')
  if (direction === 'auto') direction = target === 'card_bar' ? 'top' : x + width / 2 > 960 ? 'left' : 'right'
  const position = direction === 'right' ? [x + width - 44, y + height / 2 - 54]
    : direction === 'left' ? [x - 198, y + height / 2 - 54]
      : direction === 'top' ? [x + width / 2 - 96, y - 114]
        : [x + width / 2 - 96, y + height + 6]
  position[0] += Number(options.offset_x ?? 0)
  position[1] += Number(options.offset_y ?? 0)
  return { position, size: [192, 108], pivot: [96, 54], flip: direction === 'right',
    rotation: direction === 'top' ? Math.PI / 2 : direction === 'bottom' ? -Math.PI / 2 : 0 }
}

export const originalHighlightPulse = (seconds: number) => 1 + .3 * (1 - Math.cos(Math.PI * seconds / .4)) / 2

/** Recover source options without adding transient UI state to historical saves. */
export function originalTutorialHighlightOptions(playback: OriginalBattlePlayback): Record<string, unknown> {
  const trace = originalPrologueBattleTraces.find(trace => trace.method === playback.method &&
    (trace.repeated ?? false) === playback.repeated && playback.results.every((result, index) => trace.outcomes[index] === result))
  const command = trace?.commands.slice(0, playback.cursor).reverse().find(command => ['highlight', 'unhighlight'].includes(command.kind))
  return command?.kind === 'highlight' ? structuredClone(command.args[1] as Record<string, unknown> ?? {}) : {}
}
