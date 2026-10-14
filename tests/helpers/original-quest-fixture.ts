import { createNewGameSave } from '../../packages/domain/new-game'
import { ORIGINAL_STAGE1_END } from '../../packages/guild/routes'
import { originalStory } from '../../packages/story/original'
import { startOriginalQuestBattleSave, setOriginalQuestBattleDraft, prepareOriginalQuestBattleSave,
  updateOriginalQuestBattleSave, settleOriginalQuestBattleSave, beginOriginalQuestAftermath,
  advanceOriginalQuestAftermath, originalQuestLossRedirect } from '../../packages/story/original-quest-save'
import { stepOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, continueOriginalQuestRuntime } from '../../packages/story/original-quest-runtime'

export function originalQuestFixture(id: 'subevent2' | 'subevent3' | 'subevent4', boundary: 'entry' | 'finished' | 'redirect') {
  const sequence = { subevent2: 'subevent2_pre2', subevent3: 'subevent3_visit', subevent4: 'subevent4_post' }[id]
  const commands = originalStory.sequences.find(s => s.id === sequence)!.commands
  const index = commands.findIndex(c => c.kind === 'battle' && !c.parameters.is_minigame)
  let save = createNewGameSave()
  save.player = { ...save.player, inventory: Array.from({ length: 9 }, () => ({ hand: 'scissors', grade: 1 })), deck: [], money: 200 }
  save.progress = { checkpoint_id: `original:${sequence}:${index + 1}`, flags: [], original_quest: {
    id, route: 'full', origin_checkpoint: ORIGINAL_STAGE1_END,
    completed_battles: commands.flatMap((c, i) => c.kind === 'battle' && i < index ? [`original:${sequence}:${i + 1}`] : []) } }
  if (boundary === 'entry') return save
  save = prepareOriginalQuestBattleSave(setOriginalQuestBattleDraft(startOriginalQuestBattleSave(save), [0,1,2,3,4,5,6,7,8]))
  for (let i = 0; i < 300 && save.progress.original_quest_battle!.runtime!.phase !== 'finished'; i++) {
    const state = save.progress.original_quest_battle!.runtime!
    const next = state.phase === 'running' ? stepOriginalQuestRuntime(state, 0)
      : state.phase === 'selection' ? chooseOriginalQuestRuntimeCard(state, state.battle.playerUsed.findIndex(used => !used))
      : continueOriginalQuestRuntime(state)
    save = updateOriginalQuestBattleSave(save, next)
  }
  if (save.progress.original_quest_battle!.runtime!.outcome !== 'lose') throw new Error('Loss fixture did not lose')
  if (boundary === 'finished') return save
  save = beginOriginalQuestAftermath(settleOriginalQuestBattleSave(save, 0), 0)
  for (let i = 0; i < 10 && !originalQuestLossRedirect(save); i++) save = advanceOriginalQuestAftermath(save)
  if (!originalQuestLossRedirect(save)) throw new Error('Fixture did not reach redirect')
  return save
}
