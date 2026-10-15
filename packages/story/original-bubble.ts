import source from '../../content/stories/godot-battle-bubbles.json'

const layouts = new Map(source.cases.map(entry => [JSON.stringify([entry.text, entry.side]), entry]))
export function originalBubbleLayout(text: string, side: string) {
  const layout = layouts.get(JSON.stringify([text, side]))
  if (!layout) throw new Error('Missing actual original bubble layout')
  return structuredClone(layout)
}

export function originalBattleTypingText(text: string, side: string) {
  return side ? originalBubbleLayout(text, side).wrapped : text
}
