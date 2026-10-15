import assert from 'node:assert/strict'
import test from 'node:test'
import { readFileSync } from 'node:fs'

test('original campaign exports every initial and rematch configuration without replacing dialogue', () => {
  const source = JSON.parse(readFileSync(new URL('../../content/stories/godot-campaign-battles.json', import.meta.url), 'utf8'))
  assert.equal(source.chapters.length, 10)
  for (const chapter of source.chapters) {
    assert.equal(chapter.opponent_deck.length, 9)
    assert.equal(chapter.player_hp, 3)
    assert.equal(chapter.opponent_hp, 3)
    assert.equal(chapter.traces.length, 9)
    assert.ok(Object.hasOwn(chapter, 'card_reward'))
    if (chapter.opponent_id === 'layla') assert.deepEqual(chapter.card_reward, { hand: 'rock', grade: 5 })
    assert.equal(chapter.lose_behavior, chapter.first_battle ? 'continue' : 'guild_home')
    for (const trace of chapter.traces) {
      assert.ok(trace.commands.some((command: { kind: string }) => command.kind === 'band'))
      const janken = trace.commands.find((command: { kind: string }) => command.kind === 'janken')
      assert.ok(janken)
      assert.equal(janken.args[2], trace.outcomes[0])
      if (chapter.first_battle) assert.equal(janken.args[1].win_rate, 0)
      else assert.ok(janken.args[1].win_rate > 0)
    }
  }
})
