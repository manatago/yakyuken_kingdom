import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { extractOriginalStoryMenu } from '../../scripts/original-story-menu-source.mjs'

test('story menu labels and viewer labels are mechanically derived from the Godot scene and handlers', () => {
  const scene = readFileSync(new URL('../../godot/StoryScene.tscn', import.meta.url), 'utf8')
  const script = readFileSync(new URL('../../godot/game/StoryScene.gd', import.meta.url), 'utf8')
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-story-menu.json', import.meta.url), 'utf8'))
  assert.deepEqual(extractOriginalStoryMenu(scene, script), source)
  assert.deepEqual(source.buttons.map((button: { label: string }) => button.label), ['Item', 'Equip', 'Skip', 'Save', 'Load', 'Config', 'Exit'])
  assert.throws(() => extractOriginalStoryMenu(scene.replace('text = "Item"', 'text = ""'), script))
})
