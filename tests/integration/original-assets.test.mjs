import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import test from 'node:test'

const root = fileURLToPath(new URL('../..', import.meta.url))
test('every original story image is mapped, fetched by CI and has actual supported image bytes', () => {
  const script = join(root, '.github/scripts/pull-original-assets.mjs')
  const result = spawnSync(process.execPath, [script, '--list'], { encoding: 'utf8' })
  assert.equal(result.status, 0, result.stderr)
  const paths = new Set(JSON.parse(result.stdout))
  const document = JSON.parse(readFileSync(join(root, 'content/stories/godot-original.json'), 'utf8'))
  function check(value) {
    if (typeof value === 'string' && value.startsWith('res://assets/')) {
      assert.ok(paths.has(`godot/${value.slice(6)}`), `Unmapped original resource: ${value}`)
    } else if (value && typeof value === 'object') Object.values(value).forEach(check)
  }
  check(document.sequences); check(document.cast)
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-prologue-battle.json'), 'utf8')).traces)
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-stage1-battle.json'), 'utf8')).traces)
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-quest-battles.json'), 'utf8')).chapters)
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-subevent3-minigame.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-stage2-minigame.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-campaign-battles.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-stage3-minigame.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-stage4-minigame.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-stage5-minigame.json'), 'utf8')))
  check(JSON.parse(readFileSync(join(root, 'content/stories/godot-showdown.json'), 'utf8')))
  assert.ok(paths.has('godot/assets/ui/speech_bubble_2_small.png'))
  const actual = spawnSync(process.execPath, [script, '--check'], { encoding: 'utf8' })
  assert.equal(actual.status, 0, actual.stderr)
  const workflow = readFileSync(join(root, '.github/workflows/electron-scaffold.yml'), 'utf8')
  assert.ok(workflow.includes('node .github/scripts/pull-original-assets.mjs --pull'))
  assert.ok(workflow.includes('node .github/scripts/pull-original-assets.mjs --check'))
})
