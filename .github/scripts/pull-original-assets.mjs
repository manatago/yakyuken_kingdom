import { spawnSync } from 'node:child_process'
import { readFileSync } from 'node:fs'
import { dirname, relative, resolve, sep } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../..', import.meta.url))
const mapping = resolve(root, 'electron/renderer/src/original-assets.ts')
const imports = [...readFileSync(mapping, 'utf8').matchAll(/\bimport\s+\w+\s+from\s+['"]([^'"]+\.png)\?url['"]/g)]
const paths = [...new Set(imports.map(([, path]) => {
  const name = relative(root, resolve(dirname(mapping), path)).split(sep).join('/')
  if (!name.startsWith('godot/assets/') || name.includes('..') || /[,\r\n]/.test(name)) throw new Error(`Invalid original asset path: ${name}`)
  return name
}))].sort()
if (!paths.length) throw new Error('No original assets found')
const mode = process.argv[2]
if (process.argv.length !== 3 || !['--list', '--check', '--pull'].includes(mode)) throw new Error('Usage: pull-original-assets.mjs --list|--check|--pull')
if (mode === '--list') {
  console.log(JSON.stringify(paths))
} else if (mode === '--check') {
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])
  for (const path of paths) {
    if (!readFileSync(resolve(root, path)).subarray(0, 8).equals(signature)) throw new Error(`Original asset is not fetched PNG data: ${path}`)
  }
  console.log(`Original PNG assets verified: ${paths.length}`)
} else {
  // Keep each argument below Windows command-line limits; use the existing CI credential helper.
  const batches = [[]]
  for (const path of paths) {
    if (batches.at(-1).join(',').length + path.length + 1 > 4000) batches.push([])
    batches.at(-1).push(path)
  }
  for (const batch of batches) {
    const result = spawnSync('git', ['-c', 'credential.helper=', '-c',
      'credential.helper=!node .github/scripts/lfs-credential.mjs', '-c', 'credential.useHttpPath=true',
      'lfs', 'pull', `--include=${batch.join(',')}`], { cwd: root, stdio: 'inherit' })
    if (result.error) throw result.error
    if (result.status !== 0) process.exit(result.status ?? 1)
  }
}
