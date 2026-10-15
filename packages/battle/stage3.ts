import type { SaveData } from '../domain/save'
import { hasNineCardDeckWithLossReserve } from '../domain/deck'
import { enterGuildHome } from '../guild/home'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { fixedView } from './fixed'
import { beginStage3Minigame } from './stage3-minigame'

const ENDINGS: Readonly<Record<string, string>> = {
  'story.stage3.pre': 'stage3.pre.end',
  'story.stage3.first': 'stage3.first.end',
  'story.stage3.rematch': 'stage3.rematch.end',
  'story.stage3.post': 'stage3.post.end',
  'story.stage3.loss': 'stage3.rematch.loss.end'
}
const NEXT: Readonly<Record<string, string>> = {
  'story.stage3.pre': 'stage3.first.background',
  'story.stage3.rematch': 'stage3.post.background'
}

export function isStage3Checkpoint(checkpoint: string): boolean {
  return checkpoint === 'stage3.minigame.ready' || checkpoint === 'stage3.minigame' || checkpoint === 'stage3.minigame.end' ||
    Object.values(ENDINGS).includes(checkpoint) || checkpoint.startsWith('stage3.pre.') || checkpoint.startsWith('stage3.first.') ||
    checkpoint.startsWith('stage3.rematch.') || checkpoint.startsWith('stage3.post.')
}

export function stage3StoryForCheckpoint(checkpoint: string): string | undefined {
  return Object.entries(ENDINGS).find(([, ending]) => ending === checkpoint)?.[0] ??
    (checkpoint.startsWith('stage3.pre.') ? 'story.stage3.pre' :
      checkpoint.startsWith('stage3.first.') ? 'story.stage3.first' :
        checkpoint.startsWith('stage3.rematch.') ? 'story.stage3.rematch' :
          checkpoint.startsWith('stage3.post.') ? 'story.stage3.post' : undefined)
}

export function canStartStage3(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.flags.includes('stage2_complete') &&
    !save.progress.flags.includes('stage3.started') && !save.progress.flags.includes('stage3_complete') &&
    hasNineCardDeckWithLossReserve(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startStage3(save: SaveData): SaveData {
  if (!canStartStage3(save)) throw new Error('Stage 3 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return { ...save, progress: { ...progress, checkpoint_id: 'stage3.pre.background',
    flags: [...progress.flags, 'stage3.started'] } }
}

export function finishStage3Story(save: SaveData, storyId: string, rolls?: readonly number[]): SaveData {
  if (!save.progress.flags.includes('stage3.started') || ENDINGS[storyId] !== save.progress.checkpoint_id ||
      stage3StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) throw new Error('Stage 3 story has not reached a valid ending')
  const next = NEXT[storyId]
  if (next) return { ...save, progress: { ...save.progress, checkpoint_id: next } }
  if (storyId === 'story.stage3.first') {
    const battle = save.progress.fixed_battle
    if (battle?.battle_id !== 'battle.stage3.first' || !battle.settled || fixedView(save).outcome !== 'lose' || !rolls) {
      throw new Error('Stage 3 first battle must be settled before the evidence review')
    }
    return beginStage3Minigame({ ...save, progress: { ...save.progress, checkpoint_id: 'stage3.minigame.ready' } }, rolls)
  }
  if (storyId === 'story.stage3.rematch') {
    const battle = save.progress.fixed_battle
    if (battle?.battle_id !== 'battle.stage3.rematch' || !battle.settled || fixedView(save).outcome !== 'win') {
      throw new Error('Stage 3 rematch must be won before the appeal concludes')
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'stage3.post.background' } }
  }
  if (storyId === 'story.stage3.post') {
    const battle = save.progress.fixed_battle
    if (battle?.battle_id !== 'battle.stage3.rematch' || !battle.settled || fixedView(save).outcome !== 'win' ||
        save.progress.flags.includes('stage3_complete')) throw new Error('Stage 3 appeal cannot be completed')
    return enterGuildHome({ ...save, progress: { ...save.progress,
      flags: [...save.progress.flags, 'stage3_complete'] } })
  }
  if (storyId === 'story.stage3.loss') return enterGuildHome(save)
  throw new Error('Unknown Stage 3 story')
}

export function continueStage3Minigame(save: SaveData): SaveData {
  const ledger = save.progress.stage3_minigame
  if (save.progress.checkpoint_id !== 'stage3.minigame.end' || !ledger?.outcome) throw new Error('Stage 3 evidence review has not ended')
  const flags = save.progress.flags.includes('stage3_minigame_completed')
    ? [...save.progress.flags] : [...save.progress.flags, 'stage3_minigame_completed']
  return { ...save, progress: { ...save.progress, flags, checkpoint_id: 'stage3.rematch.background' } }
}

export function canRetryStage3Battle(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === 'stage3.rematch.loss.end' &&
    save.progress.fixed_battle?.battle_id === 'battle.stage3.rematch' && save.progress.fixed_battle.settled &&
    fixedView(save).outcome === 'lose'
}
