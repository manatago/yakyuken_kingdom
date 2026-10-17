import { readFileSync, writeFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { fileURLToPath } from 'node:url'
import { extractBubbleRules } from './bubble-rules-source.mjs'

const root = fileURLToPath(new URL('..', import.meta.url)), reference = process.argv[2] ?? root
const rules = extractBubbleRules(...['game/BattleScene.gd', 'ui/BubbleFit.gd', 'ui/BubbleWrap.gd']
  .map(file => readFileSync(resolve(reference, 'godot', file), 'utf8')),
JSON.parse(readFileSync(resolve(root, 'content/stories/godot-battle-bubbles.json'), 'utf8')))
writeFileSync(process.argv[3] ?? resolve(root, 'content/stories/godot-bubble-rules.json'), JSON.stringify(rules, null, 2) + '\n')
console.log('Original bubble anchor, wrap and sizing constants captured')
