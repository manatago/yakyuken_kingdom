import { readdirSync, readFileSync, existsSync, realpathSync } from 'node:fs'
import { resolve, relative } from 'node:path'
import type { Plugin } from 'vite'

/** Bundle referenced content images, including editor replacements, without bundling the whole image library. */
export function contentAssetPlugin(projectRoot = process.cwd()): Plugin {
  const id = '\0virtual:janken-content-assets'
  return {
    name: 'janken-content-assets',
    resolveId(source) { if (source === 'virtual:janken-content-assets') return id },
    load(source) {
      if (source !== id) return
      const references = new Set<string>()
      const collect = (value: unknown) => {
        if (typeof value === 'string' && value.startsWith('res://assets/') && /\.(?:png|jpe?g|webp)$/i.test(value)) references.add(value)
        else if (value && typeof value === 'object') for (const child of Object.values(value)) collect(child)
      }
      const directory = resolve(projectRoot, 'content/stories')
      for (const file of readdirSync(directory).filter(file => file.endsWith('.json'))) {
        const path = resolve(directory, file)
        this.addWatchFile(path)
        collect(JSON.parse(readFileSync(path, 'utf8')))
      }
      const assets = realpathSync(resolve(projectRoot, 'godot/assets'))
      const entries = [...references].sort().flatMap(path => {
        const candidate = resolve(projectRoot, 'godot', path.slice(6))
        if (!existsSync(candidate)) return [] // Some unused original cast entries have no shipped texture.
        const local = relative(assets, realpathSync(candidate))
        if (local.startsWith('..') || resolve(assets, local) !== realpathSync(candidate)) throw new Error('Content image is outside asset root')
        return [{ path, file: candidate }]
      })
      return entries.map((entry, i) => `import image${i} from ${JSON.stringify(entry.file + '?url')};`).join('\n') +
        '\nexport default {' + entries.map((entry, i) => `${JSON.stringify(entry.path)}:image${i}`).join(',') + '};'
    }
  }
}
