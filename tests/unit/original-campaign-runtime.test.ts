import assert from 'node:assert/strict'
import test from 'node:test'
import document from '../../content/stories/godot-campaign-battles.json'
import { originalCampaignChapterId } from '../../packages/story/original-quest-battle'
import { createOriginalQuestRuntime, stepOriginalQuestRuntime, continueOriginalQuestRuntime, chooseOriginalQuestRuntimeCard, restoreOriginalQuestRuntime } from '../../packages/story/original-quest-runtime'

test('all original campaign variants select by flags and preserve their raw opening and resume', () => {
  const deck = Array.from({ length: 9 }, (_, index) => ({ hand: ['rock', 'scissors', 'paper'][index % 3] as 'rock' | 'scissors' | 'paper', grade: 1 as const }))
  for (const chapter of document.chapters) {
    const flags = chapter.first_battle ? [] : [chapter.flag_key]
    const id = originalCampaignChapterId(chapter.chapter_path, flags)
    assert.equal(id, `campaign:${chapter.opponent_id}:${chapter.first_battle ? 'initial' : 'rematch'}`)
    let state = createOriginalQuestRuntime(id, deck)
    let sawDialogue = false, sawSelection = false
    for (let step = 0; step < 30 && !sawSelection; step++) {
      if (state.phase === 'running') state = stepOriginalQuestRuntime(state, 0)
      else if (state.phase === 'dialogue') {
        assert.ok(state.portraitRevision > 0)
        assert.equal(state.portraitCommand?.kind, 'set_portrait')
        assert.ok(chapter.traces.some(trace => trace.commands.some(command => command.kind === 'band' && command.args[1] === state.text)))
        sawDialogue = true
        state = continueOriginalQuestRuntime(state)
      } else if (state.phase === 'selection') {
        assert.deepEqual(restoreOriginalQuestRuntime(state), state)
        state = chooseOriginalQuestRuntimeCard(state, 0)
        sawSelection = true
      } else throw new Error(`Unexpected campaign phase ${state.phase}`)
    }
    assert.equal(sawDialogue, true)
    assert.equal(sawSelection, true)
    assert.deepEqual(restoreOriginalQuestRuntime(state), state)
  }
  assert.throws(() => originalCampaignChapterId('res://unknown.gd', []))
})
