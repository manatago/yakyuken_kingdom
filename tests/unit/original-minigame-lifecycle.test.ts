import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { originalMinigameUiVisible } from '../../packages/story/original-minigame-lifecycle'
import { createOriginalCurseGame, playOriginalCurseChoice, originalCurseSource } from '../../packages/story/original-curse-game'
import { createOriginalExpressionGame, chooseOriginalExpression, originalExpressionSource } from '../../packages/story/original-expression-game'
import { createOriginalEvidenceGame, chooseOriginalEvidence, originalEvidenceSource } from '../../packages/story/original-evidence-game'
import { createOriginalStrengthGame, chooseOriginalStrength, originalStrengthSource } from '../../packages/story/original-strength-game'
import { createOriginalQuestionGame, chooseOriginalQuestion, originalQuestionSource } from '../../packages/story/original-question-game'

const screens = ['Curse', 'Expression', 'Evidence', 'Strength', 'Question']
test('original minigames remove source UI at teardown and finish without another input', () => {
  for (const name of screens) {
    const source = readFileSync(new URL(`../../electron/renderer/src/Original${name}Screen.tsx`, import.meta.url), 'utf8')
    assert.match(source, /originalMinigameUiVisible\(/, `${name} must preserve source teardown boundary`)
    assert.match(source, /if \(!command && ledger\.game\.outcome && !busy && !error\) void finish\(\)/, `${name} must auto-finish`)
    assert.doesNotMatch(source, />続ける<\/button>/, `${name} adds an original-absent input`)
  }
})
test('evidence gauge keeps native green boundary at 40', () => {
  const source = readFileSync(new URL('../../electron/renderer/src/OriginalEvidenceScreen.tsx', import.meta.url), 'utf8')
  assert.match(source, /gauge >= 40 \? '#e6c733'/)
})
test('all five actual final action traces retain reaction/gauge UI and remove it before source endings', () => {
  let curse = createOriginalCurseGame(Array(8).fill(0))
  let expression = createOriginalExpressionGame(0)
  let evidence = createOriginalEvidenceGame(Array(13).fill(0))
  let strength = createOriginalStrengthGame(Array(5).fill(0))
  let question = createOriginalQuestionGame(Array(7).fill(0))
  for (let turn = 0; turn < 3; turn++) {
    curse = playOriginalCurseChoice(curse, 'pisuke', 0, Array(8).fill(0))
    expression = chooseOriginalExpression(expression, turn === 0 ? 'blush' : '_pisuke', 0)
    evidence = chooseOriginalEvidence(evidence, turn === 0 ? originalEvidenceSource.valid_combos.find(combo =>
      evidence.chapters.includes(combo.chapter) && evidence.evidences.includes(combo.evidence))! : '_pisuke', 0, Array(13).fill(0))
    strength = chooseOriginalStrength(strength, '_pisuke', 0, Array(5).fill(0))
    question = chooseOriginalQuestion(question, 1, Array(7).fill(0))
  }
  const cases = [
    { game: curse, count: 1, firstText: originalCurseSource.ending.win },
    { game: expression, count: 4, firstText: originalExpressionSource.ending.win },
    { game: evidence, count: 4, firstText: originalEvidenceSource.ending.win },
    { game: strength, count: 4, firstText: originalStrengthSource.config.win_narration },
    { game: question, count: originalQuestionSource.win.length, firstText: originalQuestionSource.win[0].args[1] }
  ]
  for (const { game, count, firstText } of cases) {
    assert.equal(game.outcome, 'win')
    const boundary = game.commands.length - count
    assert.ok(game.commands.slice(0, boundary).some(command => command.kind === 'gauge'))
    assert.ok(game.commands[boundary].args.includes(firstText))
    for (let cursor = 0; cursor < boundary; cursor++) assert.equal(originalMinigameUiVisible(game, cursor, count), true)
    for (let cursor = boundary; cursor <= game.commands.length; cursor++) assert.equal(originalMinigameUiVisible(game, cursor, count), false)
    assert.equal(originalMinigameUiVisible({ commands: game.commands }, game.commands.length, count), true)
  }
})
