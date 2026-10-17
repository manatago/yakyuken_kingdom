import { createHash, randomUUID } from 'node:crypto'
import { lstat, mkdir, readFile, realpath, rename, rmdir, unlink, writeFile } from 'node:fs/promises'
import { join } from 'node:path'
import { commandTraceTargets, replaceTraceCommand } from '../../packages/developer/traces'
import { parseDocument, serializeDocument } from './json-document'
import { createProjectImages } from './project-images'
import { developerTools } from '../../packages/developer/jump'
import type { BattleTraceCommand } from '../../packages/story/original-battle'

export const TRACE_DOCUMENTS = {
  matilda: 'godot-prologue-battle.json', adventurer: 'godot-stage1-battle.json',
  quests: 'godot-quest-battles.json', campaign: 'godot-campaign-battles.json',
  curse: 'godot-subevent3-minigame.json', expression: 'godot-stage2-minigame.json',
  evidence: 'godot-stage3-minigame.json', strength: 'godot-stage4-minigame.json', question: 'godot-stage5-minigame.json'
} as const
const digest = (text: string) => createHash('sha256').update(text).digest('hex')
const MAX_TRACE_BYTES = 1_048_576
export interface TraceCatalogEntry { document: string; target: string; label: string; hasSlides: boolean }
export interface TraceEditRecord { commands: BattleTraceCommand[]; revision: string; label: string; background: string; setup: BattleTraceCommand[] }

export function createTraceCommandStore(projectRoot: string) {
  const images = createProjectImages(projectRoot)
  let pending = Promise.resolve()
  async function paths(id: unknown) {
    if (typeof id !== 'string' || !Object.hasOwn(TRACE_DOCUMENTS, id)) throw new Error('Unknown trace document')
    const root = await realpath(projectRoot), directory = join(root, 'content/stories')
    if (await realpath(directory) !== directory) throw new Error('Linked content directory')
    const target = join(directory, TRACE_DOCUMENTS[id as keyof typeof TRACE_DOCUMENTS])
    if (!(await lstat(target)).isFile()) throw new Error('Linked trace document')
    return { directory, target }
  }
  async function load(id: unknown) {
    const p = await paths(id)
    if ((await lstat(p.target)).size > MAX_TRACE_BYTES) throw new Error('Trace document is too large')
    const text = await readFile(p.target, 'utf8'), document = parseDocument(text)
    if (typeof document.format !== 'string' || document.version !== 1) throw new Error('Invalid trace format')
    return { ...p, text, document, revision: digest(text) }
  }
  return {
    async catalog() {
      const result: TraceCatalogEntry[] = []
      for (const document of Object.keys(TRACE_DOCUMENTS)) {
        const source = await load(document)
        result.push(...commandTraceTargets(source.document).map(target => ({ document, target: target.id, label: `${document} / ${target.label}`,
          hasSlides: target.commands.some(command => command.kind === 'background') && target.commands.some(command => command.kind === 'bubble') })))
      }
      return result
    },
    async read(document: unknown, target: unknown) {
      const source = await load(document)
      const selected = commandTraceTargets(source.document).find(entry => entry.id === target)
      if (!selected) throw new Error('Unknown trace target')
      let node: unknown = source.document, background = '', chapter = '', setup: BattleTraceCommand[] = []
      for (const key of [undefined, ...selected.path.slice(0, -1)]) {
        if (key !== undefined && node && typeof node === 'object') node = (node as Record<string | number, unknown>)[key]
        if (node && typeof node === 'object' && !Array.isArray(node)) {
          const context = node as Record<string, unknown>
          if (typeof context.background === 'string') background = context.background
          if (typeof context.chapter_path === 'string') chapter = context.chapter_path
          if (Array.isArray(context.setup)) setup = context.setup as BattleTraceCommand[]
        }
      }
      if (selected.path.at(-1) === 'setup') setup = []
      background ||= developerTools.battle_targets.find(target => target.path === chapter)?.bg ?? ''
      return { commands: selected.commands, revision: source.revision, label: selected.label, background, setup }
    },
    async write(value: unknown) {
      serializeDocument(value)
      const edit = value as { document: string; target: string; index: number; args: unknown[]; revision: string }
      if (Object.keys(edit).sort().join(',') !== 'args,document,index,revision,target' || typeof edit.document !== 'string' ||
          typeof edit.target !== 'string' || !Array.isArray(edit.args) || !Number.isSafeInteger(edit.index) || edit.index < 0 ||
          typeof edit.revision !== 'string' || !/^[a-f0-9]{64}$/.test(edit.revision)) throw new Error('Invalid trace edit')
      const operation = pending.then(async () => {
        const p = await paths(edit.document), lock = join(p.directory, `.trace-editor-${edit.document}.lock`)
        await mkdir(lock)
        try {
          const current = await load(edit.document)
          if (current.revision !== edit.revision) throw new Error('Trace changed; reload before saving')
          const target = commandTraceTargets(current.document).find(target => target.id === edit.target)
          const command = target?.commands[edit.index]
          if (!command) throw new Error('Unknown trace command')
          const image = command.kind === 'set_portrait' ? edit.args?.[1] : ['deck', 'background'].includes(command.kind) ? edit.args?.[0] : undefined
          if (image !== undefined) await images.resolve(image)
          const result = replaceTraceCommand(current.document, edit.target, edit.index, edit.args)
          if (command.kind === 'bubble') {
            const entry = { text: String(edit.args[0]), side: String((edit.args[1] as Record<string, unknown>)?.side ?? 'center') }
            const previous = Array.isArray(result.document.editor_bubbles) ? result.document.editor_bubbles : []
            const seen = new Map(previous.map(value => [JSON.stringify(value), value]))
            seen.set(JSON.stringify(entry), entry)
            result.document.editor_bubbles = [...seen.values()]
          }
          serializeDocument(result.document)
          const serialized = JSON.stringify(result.document, null, 2) + '\n', backup = p.target + '.bak'
          if (Buffer.byteLength(serialized, 'utf8') > MAX_TRACE_BYTES) throw new Error('Trace document is too large')
          const temporary = join(p.directory, `.trace-editor.${randomUUID()}.tmp`), backupTemporary = temporary + '.bak'
          try {
            await lstat(backup).then(stat => { if (!stat.isFile()) throw new Error('Linked trace backup') })
              .catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
            await writeFile(temporary, serialized, { flag: 'wx', mode: 0o600 })
            await writeFile(backupTemporary, current.text, { flag: 'wx', mode: 0o600 })
            await paths(edit.document)
            if (await readFile(p.target, 'utf8') !== current.text) throw new Error('Trace changed while saving')
            await rename(backupTemporary, backup)
            await rename(temporary, p.target)
          } finally {
            for (const path of [temporary, backupTemporary]) await unlink(path).catch((error: NodeJS.ErrnoException) => { if (error.code !== 'ENOENT') throw error })
          }
          return { affected: result.affected }
        } finally { await rmdir(lock) }
      })
      pending = operation.then(() => {}, () => {})
      return operation
    }
  }
}
