import { createNewGameSave } from '../domain/new-game'
import { continueOriginalTutorial, createOriginalTutorial, stepOriginalTutorial,
  prepareOriginalTutorial, chooseOriginalTutorialCard } from './original-tutorial'

/** Read-only editor fixture reached through the canonical commands, not a rewritten story. */
export function originalTutorialDeckPreview() {
  let tutorial = createOriginalTutorial()
  for (let steps = 0; steps < 300; steps++) {
    if (tutorial.phase === 'deck') {
      const save = createNewGameSave()
      return { ...save, progress: { ...save.progress, checkpoint_id: 'original:prologue:198', original_tutorial: tutorial } }
    }
    if (tutorial.phase === 'dialogue') tutorial = continueOriginalTutorial(tutorial)
    else if (tutorial.phase === 'running') tutorial = stepOriginalTutorial(tutorial, 0)
    else throw new Error(`Unexpected tutorial preview phase: ${tutorial.phase}`)
  }
  throw new Error('Original tutorial deck command was not reached')
}

export function originalTutorialShowdownPreview() {
  const save = originalTutorialDeckPreview()
  let tutorial = prepareOriginalTutorial(save.progress.original_tutorial, save.player.inventory)
  for (let steps = 0; steps < 300; steps++) {
    if (tutorial.phase === 'result') return { ...save, progress: { ...save.progress, original_tutorial: tutorial } }
    if (tutorial.phase === 'dialogue') tutorial = continueOriginalTutorial(tutorial)
    else if (tutorial.phase === 'running') tutorial = stepOriginalTutorial(tutorial, 0)
    else if (tutorial.phase === 'selection') tutorial = chooseOriginalTutorialCard(tutorial, 0)
    else throw new Error(`Unexpected tutorial showdown preview phase: ${tutorial.phase}`)
  }
  throw new Error('Original tutorial showdown was not reached')
}
