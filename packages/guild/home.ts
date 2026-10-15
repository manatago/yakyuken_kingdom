import { parseSave, type SaveData } from '../domain/save'
import { canEnterGuildHome, GUILD_CHECKPOINT } from './routes'
export { GUILD_CHECKPOINT } from './routes'

export function enterGuildHome(save: SaveData): SaveData {
  parseSave(save)
  if (!canEnterGuildHome(save)) throw new Error('Guild entry requires a completed confirmation')
  return parseSave({ ...save, progress: { ...save.progress,
    checkpoint_id: GUILD_CHECKPOINT, guild_return_checkpoint: save.progress.checkpoint_id
  } })
}

export function leaveGuildHome(save: SaveData): SaveData {
  parseSave(save)
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT) throw new Error('Not at guild home')
  const { guild_return_checkpoint, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: guild_return_checkpoint! } })
}
