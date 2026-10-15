import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { mkdtempSync, readFileSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { extractOriginalShowdown } from './original-showdown-source.mjs'

const root = fileURLToPath(new URL('..', import.meta.url))
const [executable, referenceRoot, output] = process.argv.slice(2)
if (!executable || !referenceRoot || !output) throw new Error('Expected Godot executable, reference repository and output JSON')
const project = join(referenceRoot, 'godot')
const paths = ['game/BattleScene.gd', 'BattleScene.tscn', 'battle/BattleChapterBase.gd', 'game/Card.gd']
const sources = paths.map(path => readFileSync(join(project, path), 'utf8'))
const contract = extractOriginalShowdown(...sources.slice(0, 3))
const directory = mkdtempSync(join(tmpdir(), 'janken-showdown-'))
const samplesPath = join(directory, 'samples.json')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
  join(directory, 'godot.log'), '--script', 'res://export_showdown_samples.gd', '--', samplesPath, project],
  { encoding: 'utf8', timeout: 60_000 })
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Cannot compile|Cannot open/.test(result.stderr)) {
  throw new Error(`Showdown export failed: ${result.stdout}\n${result.stderr}`)
}
const samples = JSON.parse(readFileSync(samplesPath, 'utf8'))
writeFileSync(output, JSON.stringify({ format: 'godot-showdown', version: 1,
  source_hashes: Object.fromEntries(paths.map((path, i) => [path, createHash('sha256').update(sources[i]).digest('hex')])),
  ...contract, ...samples }, null, 2) + '\n')
console.log(`Original showdown exported: ${contract.totalSeconds}s, ${samples.back_out.length} curve samples, ${Object.keys(samples.grade_reasons).length} reasons`)
