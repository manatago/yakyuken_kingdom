import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { extractOriginalVisualStyle } from './original-visual-style-source.mjs'

const [reference, output] = process.argv.slice(2)
if (!reference || !output) throw new Error('Expected reference repository and output JSON')
const style = extractOriginalVisualStyle(readFileSync(join(reference, 'godot/game/StoryScene.gd'), 'utf8'))
writeFileSync(output, JSON.stringify(style, null, 2) + '\n')
console.log('Original automatic background filter exported')
