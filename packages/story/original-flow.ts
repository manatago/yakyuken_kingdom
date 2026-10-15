import { parseSave, type SaveData } from '../domain/save'
import { getGoldBonus } from '../domain/item-catalog'
import { originalAutoDeckIndices } from '../battle/original-janken'
import { createOriginalNormal } from './original-normal'
import { originalStory } from './original'
import { enterGuildHome } from '../guild/home'
import { ORIGINAL_STAGE1_END } from '../guild/routes'
import type { SubeventId } from '../domain/progression'
import { canStartOriginalQuest, originalQuestSequences } from './original-quests'

export function startOriginalQuest(save: SaveData, id: SubeventId): SaveData {
  parseSave(save)
  if (!canStartOriginalQuest(save, id)) throw new Error('Original quest is not unlocked at Guild Home')
  const route = id === 'subevent2' && save.progress.flags.includes('encounter_sister_long_seen') ? 'rematch' : 'full'
  const quest = { id, origin_checkpoint: ORIGINAL_STAGE1_END, route } as const
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, original_quest: quest,
    checkpoint_id: `original:${originalQuestSequences(quest)[0]}:0` } })
}

export function advanceOriginalQuestStory(save: SaveData): SaveData {
  save = parseSave(save)
  const quest = save.progress.original_quest
  const [, id, cursor] = save.progress.checkpoint_id.split(':')
  const sequence = originalStory.sequences.find(s => s.id === id)
  if (!quest || !sequence || Number(cursor) !== sequence.commands.length) throw new Error('Original quest scene is not complete')
  // Never pretend that an unsupported battle has been completed to reach the next scene.
  if (save.progress.original_quest_battle || sequence.commands.some((command, index) => command.kind === 'battle' &&
      !quest.completed_battles?.includes(`original:${id}:${index + 1}`))) throw new Error('Original quest battle settlement is not complete')
  const route = originalQuestSequences(quest)
  const next = route[route.indexOf(id) + 1]
  if (!next) {
    const battles = route.flatMap(id => originalStory.sequences.find(s => s.id === id)!.commands.flatMap((command, index) =>
      command.kind === 'battle' ? [`original:${id}:${index + 1}`] : []))
    if (battles.some(checkpoint => !quest.completed_battles?.includes(checkpoint))) throw new Error('Original quest completion requires its battle settlement')
    const { original_quest: _quest, ...progress } = save.progress
    return parseSave({ ...save, progress: { ...progress, checkpoint_id: 'guild.home', guild_return_checkpoint: quest.origin_checkpoint,
      original_completed_quests: [...new Set([...(progress.original_completed_quests ?? []), quest.id])] } })
  }
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: `original:${next}:0` } })
}

/** Main._run_scenario_from finishes its main scenario in GuildHome. */
export function completeOriginalStage1Story(save: SaveData): SaveData {
  if (save.progress.checkpoint_id !== ORIGINAL_STAGE1_END || save.progress.original_adventurer) {
    throw new Error('Original Stage 1 story is not complete')
  }
  const { original_story_origin: _origin, ...progress } = save.progress
  return enterGuildHome({ ...save, progress })
}

/** Main._handle_battle_aftermath and PrologueBattleChapter's redirect choices. */
export function completeOriginalMatildaStory(save: SaveData, choice: 'next' | 'retry'): SaveData {
  const [, id, cursor] = save.progress.checkpoint_id.split(':')
  const sequence = originalStory.sequences.find(s => s.id === id)
  if (!save.progress.checkpoint_id.startsWith('original:') || !sequence || Number(cursor) !== sequence.commands.length ||
      (choice === 'next' ? id !== 'prologue_battle_win' : id !== 'prologue_battle_lose')) {
    throw new Error('Original Matilda story is not ready for this transition')
  }
  if (choice === 'next') return { ...save, progress: { ...save.progress, checkpoint_id: 'original:stage1:0',
    original_story_origin: 'prologue_battle_win' } }
  const deck = originalAutoDeckIndices(save.player.inventory).map(index => save.player.inventory[index])
  return { ...save, progress: { ...save.progress, checkpoint_id: 'original:prologue:234',
    original_story_origin: 'prologue_battle_lose',
    original_normal: createOriginalNormal(deck, save.player.money, getGoldBonus((save.player.equipment ?? []).map(id => ({ id })))) } }
}
