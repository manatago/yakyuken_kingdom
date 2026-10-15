import { readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { extractOriginalStoryMenu } from './original-story-menu-source.mjs'

const [reference, output] = process.argv.slice(2)
if (!reference || !output) throw new Error('Expected reference repository and output JSON')
const source = extractOriginalStoryMenu(readFileSync(join(reference, 'godot/StoryScene.tscn'), 'utf8'),
  readFileSync(join(reference, 'godot/game/StoryScene.gd'), 'utf8'))
writeFileSync(output, JSON.stringify(source, null, 2) + '\n')
console.log('Original story menu exported')
