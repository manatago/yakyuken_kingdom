import content from '../../content/screens/guild-home.json'
import type { SaveData } from '../domain/save'
import originalDocument from '../../content/stories/godot-original.json'

export const guildHomeContent = content
export const GUILD_CHECKPOINT = content.checkpoint_id
export const ORIGINAL_STAGE1_END = `original:stage1:${originalDocument.sequences.find(sequence => sequence.id === 'stage1')!.commands.length}`
const origins = [ORIGINAL_STAGE1_END, 'matilda.end', 'matilda.normal.end', 'stage2.close.end', 'stage2.battle2.loss.end',
  'subevent2.loss.end', 'subevent2.post.end', 'subevent3.minigame.loss.end', 'subevent3.battle.loss.end', 'subevent3.post.end',
  'subevent4.post.end', 'stage3.rematch.loss.end', 'stage3.post.end', 'stage4.rematch.loss.end', 'stage4.post.end',
  'stage5.rematch.loss.end', 'stage5.post.end', 'stage6.rematch.loss.end', 'stage6.post.end', 'stage7.throne.end', 'stage7.epilogue.end']

// Validate navigation metadata before interpreting the historical battle records.
export function guildValidationSave(save: SaveData): SaveData {
  const atHome = save.progress.checkpoint_id === GUILD_CHECKPOINT
  const origin = save.progress.guild_return_checkpoint
  if (!atHome) {
    if (origin !== undefined) throw new Error('Guild return checkpoint outside home')
    return save
  }
  if (!origin || !origins.includes(origin)) throw new Error('Invalid guild return checkpoint')
  return { ...save, progress: { ...save.progress, checkpoint_id: origin } }
}

export function canEnterGuildHome(save: SaveData): boolean {
  return origins.includes(save.progress.checkpoint_id)
}
