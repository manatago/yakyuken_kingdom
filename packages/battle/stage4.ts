import type { SaveData } from '../domain/save'
import { hasNineCardDeckWithLossReserve } from '../domain/deck'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { fixedView } from './fixed'
import { beginStage4Minigame, continueStage4Minigame } from './stage4-minigame'

const endIds: Readonly<Record<string, string>> = {
  'story.stage4.pre': 'stage4.pre.end', 'story.stage4.first': 'stage4.first.end',
  'story.stage4.recover': 'stage4.recover.end', 'story.stage4.rematch': 'stage4.rematch.end',
  'story.stage4.post': 'stage4.post.end', 'story.stage4.loss': 'stage4.rematch.loss.end'
}
const nextIds: Readonly<Record<string, string>> = { 'story.stage4.pre': 'stage4.first.background', 'story.stage4.first': 'stage4.recover.background' }

export function isStage4Checkpoint(checkpoint: string): boolean {
  return checkpoint.startsWith('stage4.pre.') || checkpoint.startsWith('stage4.first.') || checkpoint.startsWith('stage4.recover.') ||
    checkpoint.startsWith('stage4.rematch.') || checkpoint.startsWith('stage4.post.') || checkpoint === 'stage4.minigame' ||
    checkpoint === 'stage4.minigame.end'
}

export function stage4StoryForCheckpoint(checkpoint: string): string | undefined {
  return Object.entries(endIds).find(([, ending]) => ending === checkpoint)?.[0] ??
    (checkpoint.startsWith('stage4.pre.') ? 'story.stage4.pre' : checkpoint.startsWith('stage4.first.') ? 'story.stage4.first' :
      checkpoint.startsWith('stage4.recover.') ? 'story.stage4.recover' : checkpoint.startsWith('stage4.rematch.') ? 'story.stage4.rematch' :
        checkpoint.startsWith('stage4.post.') ? 'story.stage4.post' : undefined)
}

export function canStartStage4(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes('stage3_complete') &&
    !save.progress.flags.includes('stage4.started') && !save.progress.flags.includes('stage4_complete') &&
    hasNineCardDeckWithLossReserve(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startStage4(save: SaveData): SaveData {
  if (!canStartStage4(save)) throw new Error('Stage 4 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: 'stage4.pre.background', flags: [...progress.flags, 'stage4.started'] } }
}

export function finishStage4Story(save: SaveData, storyId: string): SaveData {
  if (!save.progress.flags.includes('stage4.started') || endIds[storyId] !== save.progress.checkpoint_id ||
      stage4StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) throw new Error('Stage 4 story has not reached a valid ending')
  const next = nextIds[storyId]
  if (next) return { ...save, progress: { ...save.progress, checkpoint_id: next } }
  if (storyId === 'story.stage4.first') {
    const ledger = save.progress.fixed_battle
    if (ledger?.battle_id !== 'battle.stage4.first' || !ledger.settled || fixedView(save).outcome !== 'lose') {
      throw new Error('Stage 4 first battle must be settled before recovery')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage4.recover.background' } }
  }
  if (storyId === 'story.stage4.recover') return beginStage4Minigame({ ...save, progress: { ...save.progress, checkpoint_id: 'stage4.minigame.ready' } })
  if (storyId === 'story.stage4.rematch') {
    const ledger = save.progress.fixed_battle
    if (ledger?.battle_id !== 'battle.stage4.rematch' || !ledger.settled || fixedView(save).outcome !== 'win') {
      throw new Error('Stage 4 rematch must be won before it can close')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage4.post.background' } }
  }
  if (storyId === 'story.stage4.post') {
    if (save.progress.fixed_battle?.battle_id !== 'battle.stage4.rematch' || fixedView(save).outcome !== 'win' ||
        save.progress.flags.includes('stage4_complete')) throw new Error('Stage 4 cannot be completed')
    return enterGuildHome({ ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'stage4_complete'] } })
  }
  if (storyId === 'story.stage4.loss') return enterGuildHome(save)
  throw new Error('Unknown Stage 4 story')
}

export { continueStage4Minigame }

export function canRetryStage4Battle(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === 'stage4.rematch.loss.end' &&
    save.progress.fixed_battle?.battle_id === 'battle.stage4.rematch' && save.progress.fixed_battle.settled && fixedView(save).outcome === 'lose'
}
