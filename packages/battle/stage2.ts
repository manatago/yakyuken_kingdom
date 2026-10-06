import type { SaveData } from '../domain/save'
import { hasNineCardDeckWithLossReserve } from '../domain/deck'
import { SUBEVENT_COMPLETION_FLAGS } from '../domain/progression'
import stage2Document from '../../content/stories/stage2.json'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { fixedView } from './fixed'
import { startStage2Minigame } from './stage2-minigame'

const storyEndCheckpoints: Readonly<Record<string, string>> = {
  'story.stage2.pre': 'stage2.pre.end',
  'story.stage2.meet': 'stage2.first.end',
  'story.stage2.recover': 'stage2.recover.end',
  'story.stage2.rematch': 'stage2.battle2.end',
  'story.stage2.post': 'stage2.post.end',
  'story.stage2.close': 'stage2.close.end',
  'story.stage2.loss': 'stage2.battle2.loss.end'
}

const storyNextCheckpoints: Readonly<Record<string, string>> = {
  'story.stage2.pre': 'stage2.meet.background',
  'story.stage2.meet': 'stage2.recover.background',
  'story.stage2.post': 'stage2.close.start'
}

export function stage2StoryForCheckpoint(checkpointId: string): string | undefined {
  return stage2Document.stories.find((story) => story.steps.some((step) => step.id === checkpointId))?.id
}

export function finishStage2Story(save: SaveData, storyId: string, sceneOrder?: readonly number[]): SaveData {
  if (!save.progress.flags.includes('stage2.started') || storyEndCheckpoints[storyId] !== save.progress.checkpoint_id ||
      stage2StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) {
    throw new Error('Stage 2 story has not reached its valid ending')
  }
  const nextCheckpoint = storyNextCheckpoints[storyId]
  if (nextCheckpoint) return { ...save, progress: { ...save.progress, checkpoint_id: nextCheckpoint } }
  if (storyId === 'story.stage2.recover') {
    if (!sceneOrder) throw new Error('Stage 2 scene order is required')
    return startStage2Minigame(save, sceneOrder)
  }
  if (storyId === 'story.stage2.rematch') {
    const ledger = save.progress.fixed_battle
    if (!ledger?.settled || ledger.battle_id !== 'battle.stage2.rematch') throw new Error('Stage 2 rematch is not settled')
    if (fixedView(save).outcome === 'lose') throw new Error('A lost Stage 2 rematch cannot continue')
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage2.post.start' } }
  }
  if (storyId === 'story.stage2.close') return enterGuildHome(completeStage2(save))
  if (storyId === 'story.stage2.loss') return enterGuildHome(save)
  throw new Error('Unknown Stage 2 story')
}

export const STAGE2_START_CHECKPOINT = 'stage2.pre.guild.background'
export const STAGE2_CLOSE_END_CHECKPOINT = 'stage2.close.end'

export function canStartStage2(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2) &&
    !save.progress.flags.includes('stage2.started') && !save.progress.flags.includes('stage2_complete') &&
    hasNineCardDeckWithLossReserve(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function canRetryStage2Battle(save: SaveData): boolean {
  const ledger = save.progress.fixed_battle
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === 'stage2.battle2.loss.end' &&
    ledger?.battle_id === 'battle.stage2.rematch' && ledger.settled && fixedView(save).outcome === 'lose'
}

export function startStage2(save: SaveData): SaveData {
  if (!canStartStage2(save)) throw new Error('Stage 2 is not unlocked')
  const { guild_return_checkpoint: _guildReturnCheckpoint, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: STAGE2_START_CHECKPOINT,
    flags: [...progress.flags, 'stage2.started'] } }
}

export function completeStage2(save: SaveData): SaveData {
  if (save.progress.checkpoint_id !== STAGE2_CLOSE_END_CHECKPOINT || !save.progress.flags.includes('stage2.started') ||
      save.progress.flags.includes('stage2_complete')) throw new Error('Stage 2 cannot be completed here')
  return { ...save, progress: { ...save.progress, flags: [...save.progress.flags, 'stage2_complete'] } }
}
