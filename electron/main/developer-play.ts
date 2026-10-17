import { spawn, type ChildProcess } from 'node:child_process'
import { lstat, mkdtemp, rm } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { createDeveloperJumpSave } from '../../packages/developer/jump'
import { createSaveStore } from './save-store'

/** Game processes get disposable, separate saves. Renderer never supplies paths or executable arguments. */
export function createDeveloperPlay(gameEntry: string, executable = process.execPath) {
  const children = new Set<ChildProcess>()
  let launching = false
  return {
    async launch(index: unknown) {
      const save = createDeveloperJumpSave(index as number)
      if (launching || children.size >= 4) throw new Error('Close an existing development game before opening another')
      launching = true
      let directory: string | undefined
      try {
        if (!(await lstat(gameEntry)).isFile()) throw new Error('Build the game before starting developer play')
        directory = await mkdtemp(join(tmpdir(), 'janken-developer-play-'))
        await createSaveStore(directory).write(save)
        const isolated = directory
        const environment = { ...process.env }
        delete environment.ELECTRON_RENDERER_URL
        delete environment.ELECTRON_RUN_AS_NODE
        const child = spawn(executable, [gameEntry, `--user-data-dir=${directory}`, '--isolated-play'], { stdio: 'ignore', env: environment })
        children.add(child)
        const cleanup = () => {
          children.delete(child)
          void rm(isolated, { recursive: true, force: true, maxRetries: 5, retryDelay: 100 })
            .catch(() => console.error('Failed to remove an isolated developer-play save directory'))
        }
        child.once('exit', cleanup)
        await new Promise<void>((resolve, reject) => {
          child.once('spawn', resolve)
          child.once('error', error => { cleanup(); reject(error) })
        })
        return { checkpoint: save.progress.checkpoint_id }
      } catch (error) {
        if (directory) await rm(directory, { recursive: true, force: true })
        throw error
      } finally { launching = false }
    }
  }
}
