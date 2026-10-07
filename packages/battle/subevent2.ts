import document from '../../content/stories/subevent2.json'
import type { ContentPack } from '../content/schema'
import { parseSave, type SaveData } from '../domain/save'
import { hasValidNineCardDeck } from '../domain/deck'
import { getSubeventUnlockState, SUBEVENT_COMPLETION_FLAGS } from '../domain/progression'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { enterGuildHome } from '../guild/home'
import { fixedView } from './fixed'

export const subevent2Content = document as ContentPack
export const SUBEVENT2_START_CHECKPOINT = 'subevent2.pre.background'
export const SUBEVENT2_BATTLE_CHECKPOINT = 'subevent2.battle.start'
export const SUBEVENT2_LOSS_CHECKPOINT = 'subevent2.loss.end'
export const SUBEVENT2_END_CHECKPOINT = 'subevent2.post.end'
export const SUBEVENT2_BATTLE_ID = 'battle.subevent2.sister-head'

export function isSubevent2Checkpoint(checkpoint: string): boolean {
  return subevent2Content.stories.some((story) => story.steps.some((step) => step.id === checkpoint))
}

export function subevent2StoryForCheckpoint(checkpoint: string): string | undefined {
  return subevent2Content.stories.find((story) => story.steps.some((step) => step.id === checkpoint))?.id
}

export function canStartSubevent2(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && !save.progress.flags.includes('subevent2.started') &&
    !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2) &&
    getSubeventUnlockState('subevent2', save.progress.flags, save.progress.random_battles_completed ?? 0).unlocked &&
    hasValidNineCardDeck(save.player.inventory, save.player.prepared_deck ?? save.player.deck)
}

export function startSubevent2(save: SaveData): SaveData {
  parseSave(save)
  if (!canStartSubevent2(save)) throw new Error('Subevent 2 is not unlocked at Guild Home')
  const { guild_return_checkpoint: _origin, ...progress } = save.progress
  return parseSave({ ...save, progress: { ...progress, checkpoint_id: SUBEVENT2_START_CHECKPOINT,
    flags: [...progress.flags, 'subevent2.started'] } })
}

export function canRetrySubevent2(save: SaveData): boolean {
  const ledger = save.progress.fixed_battle
  return save.progress.checkpoint_id === GUILD_CHECKPOINT && save.progress.guild_return_checkpoint === SUBEVENT2_LOSS_CHECKPOINT &&
    ledger?.battle_id === SUBEVENT2_BATTLE_ID && ledger.settled && fixedView(save).outcome === 'lose' &&
    !save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2)
}

export function completeSubevent2(save: SaveData): SaveData {
  parseSave(save)
  const ledger = save.progress.fixed_battle
  if (save.progress.checkpoint_id !== SUBEVENT2_END_CHECKPOINT || !save.progress.flags.includes('subevent2.started') ||
      save.progress.flags.includes(SUBEVENT_COMPLETION_FLAGS.subevent2) || ledger?.battle_id !== SUBEVENT2_BATTLE_ID ||
      !ledger.settled || fixedView(save).outcome !== 'win') throw new Error('Subevent 2 victory has not reached its ending')
  const completed = { ...save, progress: { ...save.progress,
    flags: [...save.progress.flags, SUBEVENT_COMPLETION_FLAGS.subevent2] } }
  return enterGuildHome(completed)
}
