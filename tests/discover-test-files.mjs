import { existsSync, readdirSync } from 'node:fs'
import { join, relative, sep } from 'node:path'

const locations = {
  unit: [{ directory: 'unit', suffix: '.test.ts', recursive: true }],
  integration: [
    { directory: '.', suffix: '.test.mjs', recursive: false },
    { directory: 'integration', suffix: '.test.mjs', recursive: true }
  ],
  ui: [{ directory: 'ui', suffix: '.test.mjs', recursive: true }]
}

export function discoverTestFiles(suite, root) {
  if (!Object.hasOwn(locations, suite)) throw new Error(`Unknown test suite: ${suite}`)
  const files = []

  const collect = (directory, suffix, recursive) => {
    if (!existsSync(directory)) return
    for (const entry of readdirSync(directory, { withFileTypes: true })) {
      const path = join(directory, entry.name)
      if (entry.isDirectory() && recursive) collect(path, suffix, recursive)
      else if (entry.isFile() && entry.name.endsWith(suffix)) {
        files.push(relative(root, path).split(sep).join('/'))
      }
    }
  }

  for (const location of locations[suite]) {
    collect(join(root, 'tests', location.directory), location.suffix, location.recursive)
  }
  return files.sort()
}
