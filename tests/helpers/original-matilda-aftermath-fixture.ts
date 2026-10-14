import { parseSave } from '../../packages/domain/save'
import * as normal from '../../packages/story/original-normal'
import { beginOriginalMatildaAftermath } from '../../packages/story/original-matilda-aftermath-save'

export function originalMatildaAftermathFixture(winning: boolean) {
  const deck = Array.from({ length: 9 }, () => ({ hand: winning ? 'paper' as const : 'scissors' as const, grade: 1 as const }))
  let state = normal.prepareOriginalNormal(normal.createOriginalNormal(deck, 20), deck)
  while (state.phase !== 'finished') {
    if (state.phase === 'running') state = normal.stepOriginalNormal(state, 0)
    else if (state.phase === 'selection') state = normal.chooseOriginalNormalCard(state, state.battle.playerUsed.findIndex(used => !used))
    else state = normal.continueOriginalNormal(state)
  }
  return beginOriginalMatildaAftermath(parseSave({ save_version: 1,
    player: { money: 20, deck: [], inventory: deck, items: [] },
    progress: { checkpoint_id: 'original:prologue:234', flags: [], original_normal: state } }))
}
