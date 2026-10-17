import { createHash } from 'node:crypto'

export function extractBubbleRules(battle, fit, wrap, measured) {
  const start = battle.indexOf('const BUBBLE_SIDE_ANCHORS := '), end = battle.indexOf('\n}', start)
  if (start < 0 || end < 0) throw new Error('Missing original bubble anchors')
  const anchors = JSON.parse(battle.slice(battle.indexOf('{', start), end + 2).replace(/,\s*}/g, '}'))
  function number(source, name) {
    const match = source.match(new RegExp(`^const ${name}(?:: [^=\\n]+)?\\s*:?=\\s*([\\d.]+)\\s*(?:#.*)?$`, 'm'))
    if (!match) throw new Error(`Missing original bubble constant ${name}`)
    return Number(match[1])
  }
  const breaks = wrap.match(/^const BREAK_CHARS:[^=]+?=\s*(\[[^\n]+\])/m)
  if (!breaks) throw new Error('Missing original bubble wrap punctuation')
  return { format: 'godot-bubble-rules', version: 1, anchors,
    font_size: number(battle, 'BUBBLE_FONT_SIZE'), line_height: measured.cases[0].line_height,
    max_height_ratio: number(fit, 'MAX_HEIGHT_RATIO'), label_width_ratio: number(fit, 'LABEL_W_RATIO'),
    label_height_ratio: number(fit, 'LABEL_H_RATIO'), max_chars: number(wrap, 'MAX_CHARS_PER_LINE'),
    breaks: JSON.parse(breaks[1]), source_hashes: {
      'game/BattleScene.gd': createHash('sha256').update(battle).digest('hex'),
      'ui/BubbleFit.gd': createHash('sha256').update(fit).digest('hex'),
      'ui/BubbleWrap.gd': createHash('sha256').update(wrap).digest('hex') }
  }
}
