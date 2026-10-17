import source from '../../content/stories/godot-battle-bubbles.json'
import rules from '../../content/stories/godot-bubble-rules.json'
import matilda from '../../content/stories/godot-prologue-battle.json'
import quests from '../../content/stories/godot-quest-battles.json'

const layouts = new Map(source.cases.map(entry => [JSON.stringify([entry.text, entry.side]), entry]))
const edited = new Set([matilda, quests].flatMap(document => {
  const entries = (document as unknown as { editor_bubbles?: { text: string; side: string }[] }).editor_bubbles ?? []
  return entries.map(entry => JSON.stringify([entry.text, entry.side]))
}))
export function wrapOriginalBubble(text: string) {
  return text.split('\n').flatMap(line => {
    const characters = Array.from(line), output: string[] = []
    let cursor = 0
    while (characters.length - cursor > rules.max_chars) {
      let count = rules.max_chars
      for (let i = rules.max_chars - 1; i > 0; i--) {
        if (rules.breaks.includes(characters[cursor + i])) { count = i + 1; break }
      }
      output.push(characters.slice(cursor, cursor + count).join('')); cursor += count
    }
    output.push(characters.slice(cursor).join(''))
    return output
  }).join('\n')
}

export function originalBubbleLayout(text: string, side: string, fontSize = 0, measure?: (character: string, size: number) => number, editedPreview = false) {
  const layout = layouts.get(JSON.stringify([text, side]))
  if (layout && (!fontSize || fontSize === layout.font_size)) return structuredClone(layout)
  if (!editedPreview && !edited.has(JSON.stringify([text, side]))) throw new Error('Missing actual original bubble layout or saved editor approval')
  const anchor = rules.anchors[side as keyof typeof rules.anchors]
  if (!anchor) throw new Error('Unknown original bubble side')
  const size = fontSize || rules.font_size
  if (!Number.isSafeInteger(size) || size < 1 || size > 256) throw new Error('Invalid bubble font size')
  const wrapped = wrapOriginalBubble(text), width = 1920 * (anchor.r - anchor.l), labelWidth = width * rules.label_width_ratio
  const lineHeight = Math.ceil(rules.line_height * size / rules.font_size)
  let lines = 0
  for (const line of wrapped.split('\n')) {
    lines++; let row = 0
    for (const character of Array.from(line)) {
      const advance = measure?.(character, size) ?? size * (character.codePointAt(0)! > 255 ? 1 : 0.6)
      if (row > 0 && row + advance > labelWidth) { lines++; row = 0 }
      row += advance
    }
  }
  const height = Math.min(1080 * rules.max_height_ratio, Math.max(1080 * (anchor.b - anchor.t), lines * lineHeight / rules.label_height_ratio))
  const x = 1920 * anchor.l, y = anchor.t >= 0.5 ? 1080 * anchor.b - height : 1080 * anchor.t
  return { text, side, wrapped, rect: [x, y, width, height],
    body: [x + width * (1 - rules.label_width_ratio) / 2, y + height * (1 - rules.label_height_ratio) / 2, labelWidth, height * rules.label_height_ratio],
    font_size: size, line_height: lineHeight }
}

export function originalBattleTypingText(text: string, side: string, editedPreview = false) {
  return side ? originalBubbleLayout(text, side, 0, undefined, editedPreview).wrapped : text
}
