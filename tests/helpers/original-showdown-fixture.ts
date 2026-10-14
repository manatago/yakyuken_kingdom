import { createNewGameSave } from '../../packages/domain/new-game'
import { originalTutorialShowdownPreview } from '../../packages/story/original-tutorial-preview'
import * as normal from '../../packages/story/original-normal'
import * as adventurer from '../../packages/story/original-adventurer'

export function originalShowdownFixture(kind: string) {
  if (kind === 'tutorial') return originalTutorialShowdownPreview()
  const save = createNewGameSave()
  if (kind === 'normal') {
    let state = normal.prepareOriginalNormal(normal.createOriginalNormal(save.player.inventory, save.player.money), save.player.inventory)
    while (state.phase !== 'result') {
      if (state.phase === 'running') state = normal.stepOriginalNormal(state, 0)
      else if (state.phase === 'selection') state = normal.chooseOriginalNormalCard(state, 0)
      else state = normal.continueOriginalNormal(state)
    }
    return { ...save, progress: { ...save.progress, checkpoint_id: 'original:prologue:234', original_normal: state } }
  }
  if (kind === 'adventurer') {
    let state = adventurer.createOriginalAdventurer(0, save.player.money)
    while (state.phase !== 'result') state = state.phase === 'running'
      ? adventurer.stepOriginalAdventurer(state, 0) : adventurer.continueOriginalAdventurer(state)
    return { ...save, progress: { ...save.progress, checkpoint_id: 'original:stage1:113', original_adventurer: state } }
  }
  throw new Error('Unknown original showdown fixture')
}
