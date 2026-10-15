import type { SaveData } from '../domain/save'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'

const endings = { 'story.stage7.throne': 'stage7.throne.end', 'story.stage7.epilogue': 'stage7.epilogue.end' } as const

export function isStage7Checkpoint(checkpoint: string): boolean {
  return checkpoint.startsWith('stage7.throne.') || checkpoint.startsWith('stage7.epilogue.')
}

export function stage7StoryForCheckpoint(checkpoint: string): string | undefined {
  return Object.entries(endings).find(([, ending]) => ending === checkpoint)?.[0] ??
    (checkpoint.startsWith('stage7.throne.') ? 'story.stage7.throne' : checkpoint.startsWith('stage7.epilogue.') ? 'story.stage7.epilogue' : undefined)
}

export function canStartStage7(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes('stage6_complete') &&
    !save.progress.flags.includes('stage7.started') && !save.progress.flags.includes('game_complete')
}

export function startStage7(save: SaveData): SaveData {
  if (!canStartStage7(save)) throw new Error('Final chapter is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: 'stage7.throne.background', flags: [...progress.flags, 'stage7.started'] } }
}

export function finishStage7Story(save: SaveData, storyId: string): SaveData {
  if (!save.progress.flags.includes('stage7.started') || endings[storyId as keyof typeof endings] !== save.progress.checkpoint_id ||
      stage7StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) throw new Error('Final chapter has not reached a valid ending')
  if (storyId === 'story.stage7.throne') return { ...save, progress: { ...save.progress, checkpoint_id: 'stage7.epilogue.background' } }
  if (storyId === 'story.stage7.epilogue') {
    if (save.progress.flags.includes('game_complete')) throw new Error('The final chapter has already been completed')
    return enterGuildHome({ ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'game_complete'] } })
  }
  throw new Error('Unknown final chapter story')
}
