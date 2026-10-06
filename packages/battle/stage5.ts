import type { SaveData } from '../domain/save'
import { hasNineCardDeckWithLossReserve } from '../domain/deck'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { fixedView } from './fixed'
import { beginStage5Minigame, continueStage5Minigame } from './stage5-minigame'

const endIds: Readonly<Record<string, string>> = {
  'story.stage5.summon': 'stage5.summon.end', 'story.stage5.interrogation': 'stage5.interrogation.end',
  'story.stage5.recover': 'stage5.recover.end', 'story.stage5.rematch': 'stage5.rematch.end',
  'story.stage5.post': 'stage5.post.end', 'story.stage5.loss': 'stage5.rematch.loss.end'
}

export function isStage5Checkpoint(checkpoint: string): boolean {
  return checkpoint.startsWith('stage5.summon.') || checkpoint.startsWith('stage5.interrogation.') ||
    checkpoint.startsWith('stage5.recover.') || checkpoint.startsWith('stage5.rematch.') || checkpoint.startsWith('stage5.post.') ||
    checkpoint === 'stage5.minigame' || checkpoint === 'stage5.minigame.end'
}

export function stage5StoryForCheckpoint(checkpoint: string): string | undefined {
  return Object.entries(endIds).find(([, ending]) => ending === checkpoint)?.[0] ??
    (checkpoint.startsWith('stage5.summon.') ? 'story.stage5.summon' : checkpoint.startsWith('stage5.interrogation.') ? 'story.stage5.interrogation' :
      checkpoint.startsWith('stage5.recover.') ? 'story.stage5.recover' : checkpoint.startsWith('stage5.rematch.') ? 'story.stage5.rematch' :
        checkpoint.startsWith('stage5.post.') ? 'story.stage5.post' : undefined)
}

export function canStartStage5(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes('stage4_complete') &&
    !save.progress.flags.includes('stage5.started') && !save.progress.flags.includes('stage5_complete') &&
    hasNineCardDeckWithLossReserve(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startStage5(save: SaveData): SaveData {
  if (!canStartStage5(save)) throw new Error('Stage 5 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: 'stage5.summon.background', flags: [...progress.flags, 'stage5.started'] } }
}

export function finishStage5Story(save: SaveData, storyId: string): SaveData {
  if (!save.progress.flags.includes('stage5.started') || endIds[storyId] !== save.progress.checkpoint_id ||
      stage5StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) throw new Error('Stage 5 story has not reached a valid ending')
  if (storyId === 'story.stage5.summon') return { ...save, progress: { ...save.progress, checkpoint_id: 'stage5.interrogation.background' } }
  if (storyId === 'story.stage5.interrogation') {
    const ledger = save.progress.fixed_battle
    if (ledger?.battle_id !== 'battle.stage5.first' || !ledger.settled || fixedView(save).outcome !== 'lose') {
      throw new Error('Stage 5 first hearing must end in the scripted loss')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage5.recover.background' } }
  }
  if (storyId === 'story.stage5.recover') return beginStage5Minigame({ ...save, progress: { ...save.progress, checkpoint_id: 'stage5.minigame.ready' } })
  if (storyId === 'story.stage5.rematch') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage5.rematch' || !save.progress.fixed_battle.settled || fixedView(save).outcome !== 'win') {
      throw new Error('Stage 5 rematch must be won before it can close')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage5.post.background' } }
  }
  if (storyId === 'story.stage5.post') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage5.rematch' || fixedView(save).outcome !== 'win' ||
        save.progress.flags.includes('stage5_complete')) throw new Error('Stage 5 cannot be completed')
    return enterGuildHome({ ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'stage5_complete'] } })
  }
  if (storyId === 'story.stage5.loss') return enterGuildHome(save)
  throw new Error('Unknown Stage 5 story')
}

export { continueStage5Minigame }

export function canRetryStage5Battle(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === 'stage5.rematch.loss.end' &&
    save.progress.fixed_battle?.battle_id === 'battle.stage5.rematch' && save.progress.fixed_battle.settled && fixedView(save).outcome === 'lose'
}
