import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import { advanceStory } from '../ui/story-input.mjs'

export const originalDocument = JSON.parse(await readFile(new URL('../../content/stories/godot-original.json', import.meta.url), 'utf8'))
export const originalStage1End = `original:stage1:${originalDocument.sequences.find(sequence => sequence.id === 'stage1').commands.length}`

export function originalGuildSave(deck = []) {
  return { save_version: 1, player: { money: 0, deck, items: [],
    inventory: ['rock', 'scissors', 'paper'].flatMap(hand => Array.from({ length: 3 }, () => ({ hand, grade: 1 }))) },
  progress: { checkpoint_id: 'guild.home', guild_return_checkpoint: originalStage1End, flags: [] } }
}

// Finish the real browser animations; production durations and progression stay unchanged.
export async function finishOriginalShowdown(page) {
  await page.getByTestId('original-showdown').waitFor()
  await page.waitForFunction(() => document.querySelector('[data-testid="original-showdown"]')?.getAnimations({ subtree: true }).length === 7)
  await page.evaluate(() => {
    for (const animation of document.querySelector('[data-testid="original-showdown"]').getAnimations({ subtree: true })) animation.finish()
  })
  await page.getByTestId('original-showdown').waitFor({ state: 'detached' })
}

// Wait for the displayed post-save boundary, then the complete original text.
// There is no unconditional click to finish a typewriter that may already be done.
export async function advanceOriginalDialogue(page, sequence, cursor) {
  const command = originalDocument.sequences.find(entry => entry.id === sequence).commands[cursor - 1]
  assert.ok(command && ['band', 'line'].includes(command.kind) && command.parameters.wait_for_input)
  await page.getByTestId('original-cursor').filter({ hasText: `${sequence}:${cursor}` }).waitFor()
  await page.waitForFunction(text => document.querySelector('[data-testid="original-text"]')?.textContent === text,
    command.parameters.text)
  await advanceStory(page)
  await page.waitForFunction(previous => !document.querySelector('[data-testid="original-cursor"]') ||
    document.querySelector('[data-testid="original-cursor"]')?.textContent !== previous, `${sequence}:${cursor}`)
}
