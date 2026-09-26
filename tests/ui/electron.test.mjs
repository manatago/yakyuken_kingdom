import assert from 'node:assert/strict'
import { createRequire } from 'node:module'
import { join } from 'node:path'
import test from 'node:test'
import { fileURLToPath } from 'node:url'
import { _electron as electron } from 'playwright-core'

const root = fileURLToPath(new URL('../..', import.meta.url))
const require = createRequire(import.meta.url)
const executablePath = require('electron')

for (const application of [
  { build: 'game', title: 'Janken Kingdom', capability: 'save' },
  { build: 'editor', title: 'Janken Editor', capability: 'content' }
]) {
  test(`${application.build} renders its screen with only its own bridge`, async () => {
    const app = await electron.launch({
      executablePath,
      args: [join(root, 'dist', application.build, 'main/index.js')]
    })
    try {
      const page = await app.firstWindow()
      await page.getByRole('heading', { name: application.title }).waitFor()
      const bridgeKeys = await page.evaluate(() => Object.keys(globalThis.janken ?? {}).sort())
      assert.deepEqual(bridgeKeys, [application.capability, 'windowControls'].sort())
    } finally {
      await app.close()
    }
  })
}
