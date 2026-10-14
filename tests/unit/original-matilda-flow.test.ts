import assert from 'node:assert/strict'
import test from 'node:test'
import source from '../../content/stories/godot-main-flow.json'
import { createOriginalMatildaFlow, completeOriginalMatildaFlowStory, chooseOriginalMatildaRedirect,
  chooseOriginalMatildaResult, originalMatildaFlowChoices } from '../../packages/story/original-matilda-flow'

test('loss and draw retain the source redirect conversation, choices and home result', () => {
  for (const result of ['lose', 'draw'] as const) {
    const initial = createOriginalMatildaFlow(result)
    assert.equal(initial.phase, 'redirect-story')
    assert.equal(initial.sequenceId, source.matilda_redirect.sequence_id)
    const choice = completeOriginalMatildaFlowStory(initial)
    assert.deepEqual(originalMatildaFlowChoices(choice), [
      { label: '再挑戦する', choice: 'retry' }, { label: 'ホームに戻る', choice: 'home' }])
    const retry = chooseOriginalMatildaRedirect(choice, 'retry')
    assert.equal(retry.phase, 'retry-battle')
    const home = chooseOriginalMatildaRedirect(choice, 'home')
    assert.equal(home.phase, 'aftermath-story')
    assert.equal(home.result, 'lose')
    assert.equal(home.sequenceId, 'prologue_battle_lose')
    assert.equal(initial.phase, 'redirect-story')
  }
})

test('normal scenario result title follows the executed Main fallthrough, not the editor jump behavior', () => {
  const win = completeOriginalMatildaFlowStory(createOriginalMatildaFlow('win'))
  assert.deepEqual(originalMatildaFlowChoices(win), source.result_screens.find(screen => screen.result === 'win')!.buttons)
  for (const choice of ['next', 'title'] as const) {
    const next = chooseOriginalMatildaResult(win, choice)
    assert.equal(next.phase, 'next-story')
    assert.equal(next.sequenceId, 'stage1')
  }
  const loss = completeOriginalMatildaFlowStory(chooseOriginalMatildaRedirect(
    completeOriginalMatildaFlowStory(createOriginalMatildaFlow('lose')), 'home'))
  assert.equal(chooseOriginalMatildaResult(loss, 'retry').phase, 'retry-story')
  assert.equal(chooseOriginalMatildaResult(loss, 'retry').label, 'battle_start')
  assert.equal(chooseOriginalMatildaResult(loss, 'title').sequenceId, 'stage1')
})

test('Matilda flow rejects decisions before the canonical conversation and impossible result choices', () => {
  const win = createOriginalMatildaFlow('win')
  assert.throws(() => chooseOriginalMatildaResult(win, 'title'))
  assert.throws(() => chooseOriginalMatildaRedirect(win, 'retry'))
  const choices = completeOriginalMatildaFlowStory(win)
  assert.throws(() => chooseOriginalMatildaResult(choices, 'retry'))
  assert.throws(() => completeOriginalMatildaFlowStory(choices))
})
