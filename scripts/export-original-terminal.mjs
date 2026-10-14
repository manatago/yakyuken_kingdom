import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { extractOriginalTerminalTimings } from './original-terminal-source.mjs'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, output] = process.argv.slice(2)
if (!executable || !output) throw new Error('Expected Godot executable and output JSON')
const path = join(mkdtempSync(join(tmpdir(), 'janken-original-terminal-')), 'terminal.json')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file', `${path}.log`,
  '--script', 'res://export_terminal_effect.gd', '--', path], { encoding: 'utf8', timeout: 60_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Terminal |Cannot write/.test(result.stderr)) throw new Error(`Original terminal capture failed: ${result.stderr}`)
const capture = JSON.parse(readFileSync(path, 'utf8'))
capture.timings = extractOriginalTerminalTimings(readFileSync(join(root, 'godot/game/StoryScene.gd'), 'utf8'))
writeFileSync(output, JSON.stringify(capture, null, 2) + '\n')
console.log('Actual terminal input/geometry and original effect timings captured')
