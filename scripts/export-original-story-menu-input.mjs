import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const [executable, output] = process.argv.slice(2)
if (!executable || !output) throw new Error('Expected Godot executable and output JSON')
const root = fileURLToPath(new URL('..', import.meta.url))
const path = join(mkdtempSync(join(tmpdir(), 'janken-original-menu-input-')), 'input.json')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file', `${path}.log`,
  '--script', 'res://capture_story_menu_input.gd', '--', 'prologue', '15', path], { encoding: 'utf8', timeout: 60_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Skip probe/.test(result.stderr)) throw new Error(`Original menu input capture failed: ${result.stderr}`)
writeFileSync(output, JSON.stringify(JSON.parse(readFileSync(path, 'utf8')), null, 2) + '\n')
console.log('Actual original menu ui_accept captured; prefix effects omitted')
