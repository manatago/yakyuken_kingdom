import { readFileSync } from 'node:fs'
const bubbleSource = JSON.parse(readFileSync(new URL('../../content/stories/godot-battle-bubbles.json', import.meta.url), 'utf8'))
export function originalDisplayedBattleText(state) {
  if (!state.bubbleSide) return state.text
  const entry = bubbleSource.cases.find(entry => entry.text === state.text && entry.side === state.bubbleSide)
  if (!entry) throw new Error('Missing actual Godot displayed bubble text')
  return entry.wrapped
}

/** Use the actual dialogue input, not a developer-only navigation button. */
export async function advanceStory(page) {
  // Disk writes can finish before React releases the screen's busy guard.
  // Wait on the same rendered guard as a player's enabled controls.
  await page.waitForFunction(() => {
    const root = document.querySelector('.story-viewport')
    const exit = root && [...root.querySelectorAll('button')].find(button => button.textContent === 'タイトルに戻る')
    return root && (!exit || !exit.disabled) && (root.querySelector('[data-testid="original-cursor"]') ||
      root.querySelector('[data-original-dialogue="active"]') || [...root.querySelectorAll('button')].some(button => button.textContent === '次へ' && !button.disabled))
  })
  const viewport = page.locator('.story-viewport:has([data-testid="original-cursor"])')
  if (await viewport.count()) await viewport.press('Enter')
  else if (await page.locator('[data-original-dialogue="active"]').count()) {
    const dialogue = page.locator('[data-original-dialogue="active"]')
    if (await dialogue.getAttribute('data-bubble-ready') !== null) {
      await page.waitForFunction(() => document.querySelector('[data-original-dialogue="active"]')?.dataset.bubbleReady === 'true')
    }
    await dialogue.press('Enter')
  }
  else await page.getByRole('button', { name: '次へ', exact: true }).click()
}

/** Verify the actual full line before one input; never race a typing-completion click. */
export async function advanceBattleDialogue(page, textId, text, cursorId, previous) {
  await page.waitForFunction(({ textId, text, cursorId, previous }) =>
    document.querySelector(`[data-testid="${cursorId}"]`)?.textContent === previous &&
    document.querySelector(`[data-testid="${textId}"]`)?.textContent === text,
  { textId, text, cursorId, previous })
  await advanceStory(page)
}

/** Reload the application to the title, retaining the isolated persistent save. */
export async function reopenStoryTitle(page) {
  const debugExit = page.getByRole('button', { name: '原本再生を終了', exact: true })
  if (await debugExit.count()) await debugExit.click()
  else await page.reload()
  await page.getByRole('heading', { name: 'Janken Kingdom', exact: true }).waitFor()
}
