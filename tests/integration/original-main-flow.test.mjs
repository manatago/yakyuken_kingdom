import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import test from 'node:test'

test('executed original Main retains Matilda redirect choices and result title fallthrough', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-main-flow.json', import.meta.url), 'utf8'))
  const loss = source.bridge_traces.find(trace => trace.results[0] === 'lose' && trace.choices[0] === 'home')
  assert.ok(loss.commands.some(command => command.kind === 'scene' && command.id === 'prologue_battle_lose'))
  assert.deepEqual(loss.commands.find(command => command.kind === 'redirect_choice').labels, ['再挑戦する', 'ホームに戻る'])
  const title = source.scenario_traces.find(trace => trace.result === 'win' && trace.choice === 'title')
  assert.ok(title.commands.some(command => command.kind === 'scene' && command.id === 'stage1'))
  assert.equal(title.commands.at(-1).kind, 'guild_home')
  const screen = source.result_screens.find(screen => screen.result === 'lose')
  assert.equal(screen.title, '敗北...')
  assert.equal(screen.message, '残念...再戦しますか？')
  assert.deepEqual(screen.buttons, [{ label: '再戦する', choice: 'retry' }, { label: 'タイトルに戻る', choice: 'title' }])
})
