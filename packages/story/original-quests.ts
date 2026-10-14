import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS, type SubeventId } from '../domain/progression'
import type { SaveData } from '../domain/save'
import { ORIGINAL_STAGE1_END } from '../guild/routes'
import document from '../../content/stories/godot-original.json'
import { restoreOriginalStoryState, type OriginalStoryState } from './original'

/** Sequence order and rematch branch from Main.gd SUBEVENT_CHAPTERS/_run_subevent. */
export const ORIGINAL_QUEST_ROUTES = {
  subevent1: ['subevent1_pre', 'subevent1_hideout', 'subevent1_post'],
  subevent2: ['subevent2_pre1', 'subevent2_pre2', 'subevent2_post'],
  subevent3: ['subevent3_pre', 'subevent3_blacksmith', 'subevent3_visit', 'subevent3_post'],
  subevent4: ['subevent4_pre', 'subevent4_post']
} as const

export interface OriginalQuest {
  id: SubeventId
  origin_checkpoint: string
  route: 'full' | 'rematch'
  completed_battles?: string[]
}

export function canStartOriginalQuest(save: SaveData, id: SubeventId): boolean {
  return Object.hasOwn(ORIGINAL_QUEST_ROUTES, id) && save.progress.checkpoint_id === 'guild.home' &&
    save.progress.guild_return_checkpoint === ORIGINAL_STAGE1_END && !save.progress.original_quest &&
    getSubeventUnlockState(id, originalQuestProgressionFlags(save), save.progress.random_battles_completed ?? 0).unlocked
}

/** User-configured board progression is separate from the unchanged source story flags. */
export function originalQuestProgressionFlags(save: SaveData): string[] {
  return [...new Set([...save.progress.flags,
    ...(save.progress.original_completed_quests ?? []).map(id => SUBEVENT_COMPLETION_FLAGS[id])])]
}

/** Main plays the route on one StoryScene. Reconstruct its preceding visuals on load too. */
export function originalQuestIncomingScene(save: SaveData): OriginalStoryState | undefined {
  const quest = save.progress.original_quest
  if (!quest) return undefined
  const [, current] = save.progress.checkpoint_id.split(':')
  const route = originalQuestSequences(quest)
  const index = route.indexOf(current)
  let incoming: OriginalStoryState | undefined
  const flags = Object.fromEntries(save.progress.flags.map(flag => [flag, true]))
  for (const id of route.slice(0, index)) {
    const sequence = document.sequences.find(sequence => sequence.id === id)!
    incoming = restoreOriginalStoryState(id, sequence.commands.length, flags, incoming)
  }
  return incoming
}

export function originalQuestSequences(quest: OriginalQuest): readonly string[] {
  return quest.route === 'rematch' ? ['subevent2_rematch', 'subevent2_post'] : ORIGINAL_QUEST_ROUTES[quest.id]
}

export function parseOriginalQuest(value: unknown, checkpoint: string): OriginalQuest {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid original quest')
  const record = value as Record<string, unknown>
  if (Object.keys(record).filter(key => key !== 'completed_battles').sort().join(',') !== 'id,origin_checkpoint,route' ||
      typeof record.id !== 'string' || !Object.hasOwn(ORIGINAL_QUEST_ROUTES, record.id) ||
      record.origin_checkpoint !== ORIGINAL_STAGE1_END || !['full', 'rematch'].includes(String(record.route)) ||
      record.route === 'rematch' && record.id !== 'subevent2') throw new Error('Invalid original quest route')
  const quest = { id: record.id as SubeventId, origin_checkpoint: record.origin_checkpoint as string, route: record.route as OriginalQuest['route'] }
  const [, sequence] = checkpoint.split(':')
  if (!checkpoint.startsWith('original:') || !originalQuestSequences(quest).includes(sequence)) throw new Error('Original quest checkpoint does not match its route')
  if (Object.hasOwn(record, 'completed_battles')) {
    const completed = record.completed_battles
    const route = originalQuestSequences(quest)
    const available = route.flatMap(id => document.sequences.find(s => s.id === id)!.commands.flatMap((command, index) =>
      command.kind === 'battle' ? [`original:${id}:${index + 1}`] : []))
    if (!Array.isArray(completed) || completed.some((entry, index) => entry !== available[index]) ||
        completed.some(entry => {
          const [, id, cursor] = String(entry).split(':')
          return route.indexOf(id) > route.indexOf(sequence) || id === sequence && Number(cursor) > Number(checkpoint.split(':')[2])
        })) throw new Error('Invalid original quest completed battles')
    return { ...quest, completed_battles: [...completed] as string[] }
  }
  return quest
}
