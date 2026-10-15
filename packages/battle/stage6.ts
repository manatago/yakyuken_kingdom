import type { SaveData } from '../domain/save'
import { hasNineCardDeckWithLossReserve } from '../domain/deck'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { fixedView } from './fixed'

const endings: Readonly<Record<string, string>> = {
  'story.stage6.pre': 'stage6.pre.end', 'story.stage6.banquet': 'stage6.banquet.end',
  'story.stage6.recover': 'stage6.recover.end', 'story.stage6.rematch': 'stage6.rematch.end',
  'story.stage6.post': 'stage6.post.end', 'story.stage6.loss': 'stage6.rematch.loss.end'
}

export function isStage6Checkpoint(checkpoint: string): boolean {
  return checkpoint.startsWith('stage6.pre.') || checkpoint.startsWith('stage6.banquet.') || checkpoint.startsWith('stage6.recover.') ||
    checkpoint.startsWith('stage6.rematch.') || checkpoint.startsWith('stage6.post.')
}

export function stage6StoryForCheckpoint(checkpoint: string): string | undefined {
  return Object.entries(endings).find(([, ending]) => ending === checkpoint)?.[0] ??
    (checkpoint.startsWith('stage6.pre.') ? 'story.stage6.pre' : checkpoint.startsWith('stage6.banquet.') ? 'story.stage6.banquet' :
      checkpoint.startsWith('stage6.recover.') ? 'story.stage6.recover' : checkpoint.startsWith('stage6.rematch.') ? 'story.stage6.rematch' :
        checkpoint.startsWith('stage6.post.') ? 'story.stage6.post' : undefined)
}

export function canStartStage6(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes('stage5_complete') &&
    !save.progress.flags.includes('stage6.started') && !save.progress.flags.includes('stage6_complete') &&
    hasNineCardDeckWithLossReserve(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startStage6(save: SaveData): SaveData {
  if (!canStartStage6(save)) throw new Error('Stage 6 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: 'stage6.pre.background', flags: [...progress.flags, 'stage6.started'] } }
}

export function finishStage6Story(save: SaveData, storyId: string): SaveData {
  if (!save.progress.flags.includes('stage6.started') || endings[storyId] !== save.progress.checkpoint_id ||
      stage6StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) throw new Error('Stage 6 story has not reached a valid ending')
  if (storyId === 'story.stage6.pre') return { ...save, progress: { ...save.progress, checkpoint_id: 'stage6.banquet.background' } }
  if (storyId === 'story.stage6.banquet') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage6.first' || !save.progress.fixed_battle.settled || fixedView(save).outcome !== 'lose') {
      throw new Error('Stage 6 first contest must end in its scripted loss')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage6.recover.background' } }
  }
  if (storyId === 'story.stage6.recover') return { ...save, progress: { ...save.progress, checkpoint_id: 'stage6.rematch.background' } }
  if (storyId === 'story.stage6.rematch') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage6.rematch' || !save.progress.fixed_battle.settled || fixedView(save).outcome !== 'win') {
      throw new Error('Stage 6 rematch must be won before the verdict')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage6.post.background' } }
  }
  if (storyId === 'story.stage6.post') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage6.rematch' || fixedView(save).outcome !== 'win' ||
        save.progress.flags.includes('stage6_complete')) throw new Error('Stage 6 cannot be completed')
    return enterGuildHome({ ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'stage6_complete'] } })
  }
  if (storyId === 'story.stage6.loss') return enterGuildHome(save)
  throw new Error('Unknown Stage 6 story')
}

export function canRetryStage6Battle(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === 'stage6.rematch.loss.end' &&
    save.progress.fixed_battle?.battle_id === 'battle.stage6.rematch' && save.progress.fixed_battle.settled && fixedView(save).outcome === 'lose'
}
