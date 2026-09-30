import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

test('guild background and screen definition are included in CI asset fetching and triggers', async () => {
  const content = JSON.parse(await readFile('content/screens/guild-home.json', 'utf8'))
  assert.equal(content.checkpoint_id, 'guild.home')
  assert.deepEqual(content.menu.map((entry) => entry.action), ['quests', 'cards', 'items', 'equipment', 'shop', 'status', 'town', 'story', 'title'])
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const include = workflow.match(/--include="([^"]+)"/)[1].split(',')
  assert.ok(include.includes(content.background))
  assert.ok(workflow.includes(`- '${content.background}'`))
  assert.ok(workflow.includes("- 'content/screens/**'"))
  const renderer = await readFile('electron/renderer/src/GuildHome.tsx', 'utf8')
  assert.ok(renderer.includes(`'${content.background}': guildBackground`))
})
