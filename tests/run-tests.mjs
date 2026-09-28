import { spawnSync } from 'node:child_process'
import { createRequire } from 'node:module'
import { fileURLToPath } from 'node:url'
import { discoverTestFiles } from './discover-test-files.mjs'

const root = fileURLToPath(new URL('..', import.meta.url))
const suite = process.argv[2]
const files = discoverTestFiles(suite, root)
if (files.length === 0) throw new Error(`No ${suite} tests found`)

// Electron may install on first require; finish before parallel UI workers start.
if (suite === 'ui') createRequire(import.meta.url)('electron')

const loader = suite === 'unit' ? ['--import', 'tsx'] : []
const result = spawnSync(process.execPath, [...loader, '--test', ...files], {
  cwd: root,
  stdio: 'inherit'
})
if (result.error) throw result.error
process.exitCode = result.status ?? 1
