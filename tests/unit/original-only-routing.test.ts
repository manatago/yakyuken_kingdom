import assert from 'node:assert/strict'
import { readFileSync, existsSync } from 'node:fs'
import test from 'node:test'

test('the game entrypoint never imports or renders a rewritten story screen', () => {
  const source = readFileSync(new URL('../../electron/renderer/src/main.tsx', import.meta.url), 'utf8')
  assert.doesNotMatch(source, /from ['"]\.\/StoryScreen['"]|<StoryScreen\b/)
  assert.doesNotMatch(source, /<Stage[2-5]MinigameScreen\b|<Subevent3MinigameScreen\b|<JinScreen\b|<BelkaScreen\b|<Subevent1BelkaScreen\b/)
  assert.doesNotMatch(source, /原本の敗北後ホーム導線は移植中です/)
  for (const name of ['StoryScreen.tsx', 'JinScreen.tsx', 'BelkaScreen.tsx', 'Subevent1BelkaScreen.tsx',
    'Subevent3MinigameScreen.tsx', 'Stage2MinigameScreen.tsx', 'Stage3MinigameScreen.tsx',
    'Stage4MinigameScreen.tsx', 'Stage5MinigameScreen.tsx', 'matilda-content.ts']) {
    assert.equal(existsSync(new URL(`../../electron/renderer/src/${name}`, import.meta.url)), false, `Retired screen remains: ${name}`)
  }
})
