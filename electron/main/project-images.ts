import { lstat, readdir, realpath } from 'node:fs/promises'
import { join, relative, sep } from 'node:path'

export function createProjectImages(projectRoot: string) {
  async function root() {
    const project = await realpath(projectRoot), assets = join(project, 'godot/assets')
    if (await realpath(assets) !== assets) throw new Error('Linked image root')
    return assets
  }
  return {
    async resolve(value: unknown) {
      if (typeof value !== 'string' || !value.startsWith('res://assets/') || value.includes('..') || /[,\r\n\\*?\[\]]/.test(value) ||
          !/\.(?:png|jpe?g|webp)$/i.test(value)) throw new Error('Invalid project image')
      const assets = await root(), target = await realpath(join(assets, value.slice('res://assets/'.length)))
      if (!target.startsWith(assets + sep) || !(await lstat(target)).isFile()) throw new Error('Image outside project')
      return target
    },
    async catalog() {
      const assets = await root(), paths: string[] = []
      async function scan(directory: string): Promise<void> {
        for (const entry of await readdir(directory, { withFileTypes: true })) {
          const path = join(directory, entry.name)
          const name = relative(assets, path).split(sep).join('/')
          if (entry.isDirectory()) await scan(path)
          else if (entry.isFile() && /\.(?:png|jpe?g|webp)$/i.test(entry.name) && !/[,\r\n\\*?\[\]]/.test(name)) {
            paths.push(`res://assets/${name}`)
          }
          if (paths.length > 20_000) throw new Error('Too many project images')
        }
      }
      await scan(assets)
      return paths.sort()
    }
  }
}
