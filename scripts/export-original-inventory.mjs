import { spawnSync } from 'node:child_process'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, reference, output] = process.argv.slice(2)
if (!executable || !reference || !output) throw new Error('Expected Godot executable, reference repository and output JSON')
const path = join(mkdtempSync(join(tmpdir(), 'janken-original-inventory-')), 'inventory.json')
const result = spawnSync(executable, ['--headless', '--path', join(reference, 'godot'), '--log-file', `${path}.log`,
  '--script', join(root, 'godot/export_story_inventory_geometry.gd'), '--', path], { encoding: 'utf8', timeout: 60_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|not imported|Cannot write|No loader found/.test(result.stderr)) {
  throw new Error(`Original imported inventory capture failed: ${result.stderr}`)
}
writeFileSync(output, JSON.stringify(JSON.parse(readFileSync(path, 'utf8')), null, 2) + '\n')
console.log('Actual imported inventory captured: populated and empty panels')
