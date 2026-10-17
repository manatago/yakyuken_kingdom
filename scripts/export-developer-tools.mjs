import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { join, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, reference = root, output = join(root, 'content/developer-tools.json')] = process.argv.slice(2)
if (!executable) throw new Error('Expected Godot executable, optional original repository and output JSON')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'),
  '--script', join(root, 'godot/export_developer_tools.gd'), '--', join(resolve(reference), 'godot/game/Main.gd'), resolve(output)],
{ encoding: 'utf8', timeout: 30_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Parse Error/.test(result.stdout + result.stderr)) throw new Error(result.stdout + result.stderr)
const document = JSON.parse(readFileSync(output, 'utf8'))
if (document.format !== 'godot-developer-tools' || !document.source_hashes) throw new Error('Invalid developer target capture')
console.log(`Captured ${document.jump_points.length} original jump points, ${document.story_targets.length} story rows and ${document.battle_targets.length} battle targets`)
