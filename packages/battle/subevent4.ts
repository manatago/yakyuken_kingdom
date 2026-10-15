import document from '../../content/stories/subevent4.json'
import type { ContentPack } from '../content/schema'
import { parseSave, type SaveData } from '../domain/save'
import { hasValidNineCardDeck } from '../domain/deck'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS } from '../domain/progression'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { enterGuildHome } from '../guild/home'
import { fixedView } from './fixed'

export const subevent4Content = document as ContentPack
export const SUBEVENT4_START_CHECKPOINT = 'subevent4.pre.background'
export const SUBEVENT4_BATTLE_CHECKPOINT = 'subevent4.battle.start'
export const SUBEVENT4_BATTLE_ID = 'battle.subevent4.receptionist'
export const SUBEVENT4_END_CHECKPOINT = 'subevent4.post.end'

export function isSubevent4Checkpoint(checkpoint: string): boolean {
  return subevent4Content.stories.some((story) => story.steps.some((step) => step.id === checkpoint))
}

export function subevent4StoryForCheckpoint(checkpoint: string): string | undefined {
  return subevent4Content.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id
}

export function canStartSubevent4(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && !save.progress.flags.includes('subevent4.started') &&
    !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent4) &&
    getSubeventUnlockState('subevent4', save.progress.flags, save.progress.random_battles_completed ?? 0).unlocked &&
    hasValidNineCardDeck(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startSubevent4(save: SaveData): SaveData {
  parseSave(save)
  if (!canStartSubevent4(save)) throw new Error('Subevent 4 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: SUBEVENT4_START_CHECKPOINT,
    flags: [...progress.flags, 'subevent4.started'] } })
}

export function finishSubevent4Story(save: SaveData, storyId: string): SaveData {
  parseSave(save)
  const validEnds: Readonly<Record<string, string>> = {
    'story.subevent4.pre': 'subevent4.pre.end',
    'story.subevent4.post': SUBEVENT4_END_CHECKPOINT
  }
  if (!save.progress.flags.includes('subevent4.started') || subevent4StoryForCheckpoint(save.progress.checkpoint_id) !== storyId ||
      validEnds[storyId] !== save.progress.checkpoint_id) throw new Error('Subevent 4 story has not reached a valid ending')
  if (storyId === 'story.subevent4.pre') return { ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT4_BATTLE_CHECKPOINT } }
  if (storyId === 'story.subevent4.post') return completeSubevent4(save)
  throw new Error('Unknown Subevent 4 story')
}

export function completeSubevent4(save: SaveData): SaveData {
  parseSave(save)
  const ledger = save.progress.fixed_battle
  if (save.progress.checkpoint_id !== SUBEVENT4_END_CHECKPOINT || !save.progress.flags.includes('subevent4.started') ||
      save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent4) || ledger?.battle_id !== SUBEVENT4_BATTLE_ID ||
      !ledger.settled || !fixedView(save).outcome) throw new Error('Subevent 4 appeal has not been resolved')
  return enterGuildHome({ ...save, progress: { ...save.progress,
    flags: [...save.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent4] } })
}
