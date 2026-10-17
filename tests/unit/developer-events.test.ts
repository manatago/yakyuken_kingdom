import assert from 'node:assert/strict'
import test from 'node:test'
import { createDeveloperEventSave, eventBattleTargets } from '../../packages/developer/jump'
import { originalStory } from '../../packages/story/original'
import { parseSave } from '../../packages/domain/save'
import { editorView } from '../../electron/main/editor-launcher'

test('title event targets follow the original battle-only menu and start the exact normal battle', () => {
  assert.equal(eventBattleTargets.length, 10)
  for (const target of eventBattleTargets) {
    const save = createDeveloperEventSave(target.id)
    assert.deepEqual(parseSave(save), save)
    assert.equal(save.player.money, 1000)
    assert.equal(save.player.inventory.length, 9)
    const [, sequence, cursor] = save.progress.checkpoint_id.split(':')
    const command = originalStory.sequences.find(scene => scene.id === sequence)!.commands[Number(cursor) - 1]
    assert.equal(command.kind, 'battle')
    assert.equal(command.parameters.chapter_path, target.path)
    assert.equal(command.parameters.is_tutorial, false)
    assert.equal(command.parameters.is_minigame, false)
  }
  assert.throws(() => createDeveloperEventSave('stage1'), /Unknown/)
  assert.throws(() => createDeveloperEventSave('../other'), /Unknown/)
})

test('editor launch accepts only fixed implemented views, never paths or arguments', () => {
  for (const view of ['story', 'battle', 'slides']) assert.equal(editorView(view), view)
  for (const view of ['', '../editor', '--inspect=0', 'random', null, { view: 'story' }]) assert.throws(() => editorView(view))
})
