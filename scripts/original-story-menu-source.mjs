import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'

export function extractOriginalStoryMenu(scene, script) {
  const buttons = [...scene.matchAll(/\[node name="(\w+Button)" type="Button" parent="DialogueBand\/MenuBar"\]\n([\s\S]*?)(?=\n\[node |$)/g)].map(([, id, body]) => {
    const label = body.match(/^text = "([^"]+)"$/m)?.[1]
    const fontSize = Number(body.match(/^theme_override_font_sizes\/font_size = (\d+)$/m)?.[1])
    assert.ok(label && Number.isFinite(fontSize), `Unsupported menu button ${id}`)
    return { id, label, font_size: fontSize }
  })
  assert.equal(buttons.length, 7, 'Expected all original menu buttons')
  const viewers = Object.fromEntries(['item', 'equip'].map(kind => {
    const body = script.split(`func _on_${kind}_pressed():`)[1]?.split('\nfunc ')[0]
    assert.ok(body?.includes('_close_story_modal()'), 'Missing original modal toggle')
    const text = name => {
      const value = body.match(new RegExp(`${name}\\.text = "([^"]+)"`))?.[1]
      assert.ok(value, `Missing viewer label ${name}`)
      return value
    }
    return [kind, { title: text('title_label'), empty: text('empty_label'), close: text('close_btn') }]
  }))
  const goldPrefix = script.match(/create_gold_label\(GameState.money, 22, 28, "([^"]+)"\)/)?.[1]
  assert.ok(goldPrefix, 'Missing original gold prefix')
  return { format: 'godot-story-menu', version: 1,
    source_hashes: { scene: createHash('sha256').update(scene).digest('hex'), script: createHash('sha256').update(script).digest('hex') },
    buttons, viewers, gold_prefix: goldPrefix }
}
