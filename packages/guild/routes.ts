import content from '../../content/screens/guild-home.json'
import type { SaveData } from '../domain/save'

export const guildHomeContent = content
export const GUILD_CHECKPOINT = content.checkpoint_id
const origins = ['matilda.end', 'matilda.normal.end']

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
