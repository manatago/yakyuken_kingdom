import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, output, reference = root] = process.argv.slice(2)
if (!executable || !output) throw new Error('Expected Godot executable and output JSON')
const directory = mkdtempSync(join(tmpdir(), 'janken-original-skip-'))
function capture(script, cursor) {
  const path = join(directory, `${script}-${cursor}.json`)
  const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file', `${path}.log`,
    '--script', `res://${script}.gd`, '--', 'prologue', String(cursor), path, join(reference, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (result.error) throw result.error
  if (result.status !== 0 || /SCRIPT ERROR|Skip probe|ObjectDB instances were leaked|resources still in use/.test(result.stderr)) {
    throw new Error(`Original Skip capture failed: ${result.stdout}\n${result.stderr}`)
  }
  return JSON.parse(readFileSync(path, 'utf8'))
}
const cases = [15, 50, 75, 90, 105, 145].map(cursor => capture('capture_story_skip', cursor))
const battle_boundary = capture('capture_story_skip_main', 190)
writeFileSync(output, JSON.stringify({ scope: 'single-skip-prebattle-input-boundaries', version: 1, cases, battle_boundary }, null, 2) + '\n')
console.log('Actual original Skip captured: six prebattle boundaries and pending Main battle I/O; prefix effects omitted')
