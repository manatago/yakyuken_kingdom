import document from '../../content/stories/subevent3.json'
import type { ContentPack } from '../content/schema'
import { parseSave, type SaveData } from '../domain/save'
import { hasValidNineCardDeck } from '../domain/deck'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS } from '../domain/progression'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { enterGuildHome } from '../guild/home'
import { fixedView } from './fixed'
import { beginSubevent3Minigame, SUBEVENT3_BATTLE_CHECKPOINT, SUBEVENT3_MINIGAME_LOSS,
  SUBEVENT3_MINIGAME_START } from './subevent3-minigame'

export const subevent3Content = document as ContentPack
export const SUBEVENT3_START_CHECKPOINT = 'subevent3.pre.background'
export const SUBEVENT3_BATTLE_ID = 'battle.subevent3.fiona'
export const SUBEVENT3_BATTLE_LOSS = 'subevent3.battle.loss.end'
export const SUBEVENT3_END_CHECKPOINT = 'subevent3.post.end'

const endToNext: Readonly<Record<string, string>> = {
  'story.subevent3.pre': 'subevent3.blacksmith.background',
  'story.subevent3.blacksmith': 'subevent3.visit.background'
}

export function isSubevent3Checkpoint(checkpoint: string): boolean {
  return subevent3Content.stories.some((story) => story.steps.some((step) => step.id === checkpoint))
}

export function subevent3StoryForCheckpoint(checkpoint: string): string | undefined {
  return subevent3Content.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id
}

export function canStartSubevent3(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    !save.progress.flags.includes('subevent3.started') && !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3) &&
    getSubeventUnlockState('subevent3', save.progress.flags, save.progress.random_battles_completed ?? 0).unlocked &&
    hasValidNineCardDeck(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startSubevent3(save: SaveData): SaveData {
  parseSave(save)
  if (!canStartSubevent3(save)) throw new Error('Subevent 3 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: SUBEVENT3_START_CHECKPOINT,
    flags: [...progress.flags, 'subevent3.started'] } })
}

export function canRetrySubevent3Minigame(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    save.progress.guild_return_checkpoint === SUBEVENT3_MINIGAME_LOSS &&
    save.progress.subevent3_minigame?.outcome === 'lose' && !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3)
}

export function retrySubevent3Minigame(save: SaveData, rolls: readonly number[]): SaveData {
  if (!canRetrySubevent3Minigame(save)) throw new Error('Subevent 3 minigame cannot be retried')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  const atStart = { ...save, progress: { ...progress, checkpoint_id: SUBEVENT3_MINIGAME_START } }
  return parseSave(beginSubevent3Minigame(atStart, rolls))
}

export function finishSubevent3Story(save: SaveData, storyId: string, rolls: readonly number[] = [0, 0, 0, 0]): SaveData {
  parseSave(save)
  if (!save.progress.flags.includes('subevent3.started') || subevent3StoryForCheckpoint(save.progress.checkpoint_id) !== storyId) {
    throw new Error('Subevent 3 story is not at a valid ending')
  }
  const step = subevent3Content.stories.find((story) => story.id === storyId)?.steps.find((entry) => entry.id === save.progress.checkpoint_id)
  if (step?.kind !== 'end') throw new Error('Subevent 3 story has not reached its ending')
  if (endToNext[storyId]) return { ...save, progress: { ...save.progress, checkpoint_id: endToNext[storyId]! } }
  if (storyId === 'story.subevent3.visit') return parseSave(beginSubevent3Minigame(save, rolls))
  if (storyId === 'story.subevent3.post') return completeSubevent3(save)
  if (storyId === 'story.subevent3.minigame-loss' || storyId === 'story.subevent3.battle-loss') return enterGuildHome(save)
  throw new Error('Unknown Subevent 3 story ending')
}

export function canContinueSubevent3AfterMinigame(save: SaveData): boolean {
  return save.progress.checkpoint_id === 'subevent3.minigame.end' &&
    save.progress.subevent3_minigame?.outcome === 'win' && save.progress.flags.includes('subevent3.started')
}

export function continueSubevent3ToBattle(save: SaveData): SaveData {
  if (!canContinueSubevent3AfterMinigame(save)) throw new Error('Subevent 3 minigame has not been won')
  return parseSave({ ...save, progress: { ...save.progress, checkpoint_id: SUBEVENT3_BATTLE_CHECKPOINT } })
}

export function canRetrySubevent3Battle(save: SaveData): boolean {
  const ledger = save.progress.fixed_battle
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === SUBEVENT3_BATTLE_LOSS &&
    ledger?.battle_id === SUBEVENT3_BATTLE_ID && ledger.settled && fixedView(save).outcome === 'lose' &&
    !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3)
}

export function completeSubevent3(save: SaveData): SaveData {
  parseSave(save)
  const ledger = save.progress.fixed_battle
  if (save.progress.checkpoint_id !== SUBEVENT3_END_CHECKPOINT || !save.progress.flags.includes('subevent3.started') ||
      save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent3) || ledger?.battle_id !== SUBEVENT3_BATTLE_ID ||
      !ledger.settled || fixedView(save).outcome !== 'win') throw new Error('Subevent 3 victory has not reached its ending')
  return enterGuildHome({ ...save, progress: { ...save.progress,
    flags: [...save.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent3] } })
}
