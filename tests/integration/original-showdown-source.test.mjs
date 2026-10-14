import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'
import { extractOriginalShowdown } from '../../scripts/original-showdown-source.mjs'

const read = path => readFileSync(new URL(`../../godot/${path}`, import.meta.url), 'utf8')
const source = read('game/BattleScene.gd')
const scene = read('BattleScene.tscn')
const base = read('battle/BattleChapterBase.gd')

test('showdown contract comes from raw Godot and does not await the result pop', () => {
  const contract = extractOriginalShowdown(source, scene, base)
  assert.deepEqual(contract.slideSeconds, [1.5, 1.5])
  assert.deepEqual(contract.pauseSeconds, [.3, .5, .4, 1.5])
  assert.deepEqual(contract.flipSeconds, [.3, .3, .3, .3])
  assert.equal(contract.resultPopSeconds, .4)
  assert.equal(contract.fadeSeconds, .3)
  assert.equal(contract.totalSeconds, 7.2)
  assert.equal(contract.resultStartsSeconds, 5.4)
  assert.equal(contract.fadeStartsSeconds, 6.9)
  assert.equal(contract.dimAlpha, .4)
  assert.equal(contract.cardBack, 'res://assets/battle/cards/card_back.png')
  assert.deepEqual(contract.resultAnchors, [.2, .25, .8, .65])
})

test('source changes cannot silently retain an obsolete showdown contract', () => {
  assert.throws(() => extractOriginalShowdown(source.replace('_show_overlay_result(result, grade_reason)', 'await _show_overlay_result(result, grade_reason)'), scene, base), /unawaited/)
  assert.throws(() => extractOriginalShowdown(source.replace('card_h * 2.0 / 3.0', 'card_h * 1.0 / 2.0'), scene, base), /geometry/)
  const start = source.indexOf('func _play_janken_overlay(')
  const reordered = source.slice(0, start) + source.slice(start).replace('await get_tree().create_timer(0.5).timeout', '')
    .replace('\t_show_overlay_result(result, grade_reason)', '\tawait get_tree().create_timer(0.5).timeout\n\t_show_overlay_result(result, grade_reason)')
  assert.throws(() => extractOriginalShowdown(reordered, scene, base), /ordering/)
})
