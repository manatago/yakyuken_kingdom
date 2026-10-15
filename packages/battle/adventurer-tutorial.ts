import { parseSave, type SaveData } from '../domain/save'
import { judgeCards } from '../domain/card'
import { GUILD_CHECKPOINT } from '../guild/routes'
import { TUTORIAL_COMPLETE } from './tutorial'

export const ADVENTURER_TUTORIAL_COMPLETE = 'adventurer.tutorial.completed'

export function canStartAdventurerTutorial(save: SaveData): boolean {
  return save.progress.checkpoint_id === GUILD_CHECKPOINT &&
    save.progress.guild_return_checkpoint === 'matilda.normal.end' &&
    save.progress.flags.includes(TUTORIAL_COMPLETE) &&
    !save.progress.flags.includes(ADVENTURER_TUTORIAL_COMPLETE) &&
    !save.progress.adventurer_tutorial
}

export function startAdventurerTutorial(save: SaveData): SaveData {
  if (!canStartAdventurerTutorial(save)) throw new Error('Adventurer tutorial is not available')
  return parseSave({ ...save, progress: { ...save.progress,
    adventurer_tutorial: { step: 0, original_deck: save.player.deck.map((card) => ({ ...card })) }
  } })
}

export function advanceAdventurerTutorial(save: SaveData): SaveData {
  const tutorial = save.progress.adventurer_tutorial
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !tutorial || tutorial.step !== 0) {
    throw new Error('Adventurer tutorial cannot advance')
  }
  return parseSave({ ...save, progress: { ...save.progress,
    adventurer_tutorial: { ...tutorial, step: tutorial.step + 1 }
  } })
}

export function buildAdventurerTutorialDeck(save: SaveData): SaveData {
  const tutorial = save.progress.adventurer_tutorial
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !tutorial || tutorial.step !== 1) {
    throw new Error('Tutorial deck is not being prepared')
  }
  return parseSave({ ...save, progress: {
    ...save.progress,
    adventurer_tutorial: { ...tutorial, step: 2 }
  } })
}

export function playAdventurerTutorialBattle(save: SaveData): SaveData {
  const tutorial = save.progress.adventurer_tutorial
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !tutorial || tutorial.step !== 2) {
    throw new Error('Adventurer tutorial battle is not ready')
  }
  const result = judgeCards({ hand: 'paper', grade: 1 }, { hand: 'rock', grade: 1 })
  if (result !== 'win') throw new Error('The fixed tutorial encounter must produce a win')
  return parseSave({ ...save, progress: { ...save.progress,
    adventurer_tutorial: { ...tutorial, step: 3, result }
  } })
}

export function completeAdventurerTutorial(save: SaveData): SaveData {
  const tutorial = save.progress.adventurer_tutorial
  if (save.progress.checkpoint_id !== GUILD_CHECKPOINT || !tutorial || tutorial.step !== 3 ||
      !save.progress.flags.includes(TUTORIAL_COMPLETE)) throw new Error('Adventurer tutorial is incomplete')
  const { adventurer_tutorial: _tutorial, ...progress } = save.progress
  return parseSave({ ...save,
    progress: { ...progress, flags: [...progress.flags, ADVENTURER_TUTORIAL_COMPLETE] }
  })
}
