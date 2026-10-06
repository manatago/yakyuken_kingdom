import assert from 'node:assert/strict'
import { readFile } from 'node:fs/promises'
import test from 'node:test'

test('Stage 1 town backgrounds used by gameplay are fetched from LFS in CI', async () => {
  const town = JSON.parse(await readFile('content/town/stage1.json', 'utf8'))
  const backgrounds = [...new Set(Object.values(town.areas).map((area) => area.background))]
  assert.equal(backgrounds.length, 6)
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const include = workflow.match(/--include="([^"]+)"/)[1].split(',')
  for (const background of backgrounds) {
    assert.ok(include.includes(background), `CI LFS include missing ${background}`)
    assert.ok(workflow.includes(`- '${background}'`), `CI path trigger missing ${background}`)
  }
  const renderer = await readFile('electron/renderer/src/RandomBattleScreen.tsx', 'utf8')
  for (const background of backgrounds) assert.ok(renderer.includes(background), `Renderer background missing ${background}`)
})

test('random opponent portraits are bundled for every Stage 1 profile and fetched from LFS', async () => {
  const town = JSON.parse(await readFile('content/town/stage1.json', 'utf8'))
  const portraitModule = await readFile('electron/renderer/src/random-battle-portraits.ts', 'utf8')
  const importedPaths = [...portraitModule.matchAll(/from '\.\/(assets\/random-battle\/[^']+\.png)\?url'/g)]
    .map((match) => match[1])
  assert.equal(importedPaths.length, 13)
  for (const path of importedPaths) await readFile(`electron/renderer/src/${path}`)
  for (const opponentId of Object.keys(town.opponents)) {
    assert.ok(portraitModule.includes(`${opponentId}:`), `missing portrait mapping for ${opponentId}`)
  }
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const lfsGlob = 'electron/renderer/src/assets/random-battle/**'
  assert.ok(includes.includes(lfsGlob), `CI LFS include missing ${lfsGlob}`)
  assert.ok(workflow.includes("- 'electron/**'"), 'CI path trigger missing Electron image assets')
})

test('guild subevent unlock configuration is JSON-driven and covered by CI triggers', async () => {
  const config = JSON.parse(await readFile('content/progression.json', 'utf8'))
  assert.equal(config.subeventRandomBattleRequirement, 3)
  assert.deepEqual(Object.keys(config.subeventCompleteFlags), ['subevent1', 'subevent2', 'subevent3', 'subevent4'])
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  assert.ok(workflow.includes("- 'content/progression.json'"))
})

test('Stage 2 story images used by Electron are fetched from LFS in CI', async () => {
  const stage2 = JSON.parse(await readFile('content/stories/stage2.json', 'utf8'))
  const assets = [...new Set(stage2.assets.map((asset) => asset.path))]
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const include = workflow.match(/--include="([^"]+)"/)[1].split(',')
  for (const asset of assets) {
    assert.ok(include.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`), `CI path trigger missing ${asset}`)
  }
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of assets) assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
})

test('Subevent 2 story backgrounds and the sister portrait are fetched from LFS in CI', async () => {
  const subevent2 = JSON.parse(await readFile('content/stories/subevent2.json', 'utf8'))
  const assets = [...new Set(subevent2.assets.map((asset) => asset.path))]
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const include = workflow.match(/--include="([^"]+)"/)[1].split(',')
  for (const asset of assets) {
    assert.ok(include.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`), `CI path trigger missing ${asset}`)
  }
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of assets) assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
})

test('Subevent 3 story backgrounds and Fiona portrait are fetched from LFS in CI', async () => {
  const subevent3 = JSON.parse(await readFile('content/stories/subevent3.json', 'utf8'))
  const assets = [...new Set(subevent3.assets.map((asset) => asset.path))]
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  for (const asset of assets) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`), `CI path trigger missing ${asset}`)
  }
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of assets) assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
})

test('Subevent 4 receptionist image is mapped in Electron and fetched from LFS in CI', async () => {
  const subevent4 = JSON.parse(await readFile('content/stories/subevent4.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  for (const asset of subevent4.assets.map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`), `CI path trigger missing ${asset}`)
  }
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of subevent4.assets.map((entry) => entry.path)) assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
})

test('Stage 3 story images are mapped in Electron and fetched from LFS in CI', async () => {
  const stage3 = JSON.parse(await readFile('content/stories/stage3.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of stage3.assets.map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`), `CI path trigger missing ${asset}`)
    assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
  }
})

test('Stage 4 story images are mapped in Electron and fetched from LFS in CI', async () => {
  const stage4 = JSON.parse(await readFile('content/stories/stage4.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of stage4.assets.map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    const hasSpecificTrigger = workflow.includes(`- '${asset}'`)
    const coveredByExistingPrologueTrigger = asset.startsWith('godot/assets/backgrounds/prologue/') &&
      workflow.includes("- 'godot/assets/backgrounds/prologue/**'")
    assert.ok(hasSpecificTrigger || coveredByExistingPrologueTrigger, `CI path trigger missing ${asset}`)
    assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
  }
})

test('Stage 5 story images are mapped in Electron and fetched from LFS in CI', async () => {
  const stage5 = JSON.parse(await readFile('content/stories/stage5.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of stage5.assets.map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    const hasSpecificTrigger = workflow.includes(`- '${asset}'`)
    const coveredByExistingTrigger = asset === 'godot/assets/backgrounds/stage1/bg07_st1_001.png' ||
      asset === 'godot/assets/backgrounds/stage2/bg_guild_resting.png' ||
      asset === 'godot/assets/characters/main/satoshi/isekai/satoshi_isekai_004.png' ||
      asset === 'godot/assets/characters/main/receptionist/clothed/receptionist_clothed_005.png'
    assert.ok(hasSpecificTrigger || coveredByExistingTrigger, `CI path trigger missing ${asset}`)
    assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
  }
})

test('Stage 6 and 7 story images are mapped in Electron and fetched from LFS in CI', async () => {
  const stage6 = JSON.parse(await readFile('content/stories/stage6.json', 'utf8'))
  const stage7 = JSON.parse(await readFile('content/stories/stage7.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  const alreadyTriggered = new Set([
    'godot/assets/backgrounds/stage1/bg07_st1_001.png',
    'godot/assets/characters/main/satoshi/isekai/satoshi_isekai_004.png'
  ])
  for (const asset of [...stage6.assets, ...stage7.assets].map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    assert.ok(workflow.includes(`- '${asset}'`) || alreadyTriggered.has(asset), `CI path trigger missing ${asset}`)
    assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
  }
})

test('adapted prologue images are mapped in Electron and fetched from LFS in CI', async () => {
  const prologue = JSON.parse(await readFile('content/stories/prologue.json', 'utf8'))
  const workflow = await readFile('.github/workflows/electron-scaffold.yml', 'utf8')
  const includes = [...workflow.matchAll(/--include="([^"]+)"/g)].flatMap((match) => match[1].split(','))
  const renderer = await readFile('electron/renderer/src/matilda-content.ts', 'utf8')
  for (const asset of prologue.assets.map((entry) => entry.path)) {
    assert.ok(includes.includes(asset), `CI LFS include missing ${asset}`)
    const hasTrigger = workflow.includes(`- '${asset}'`) ||
      asset.startsWith('godot/assets/backgrounds/prologue/') && workflow.includes("- 'godot/assets/backgrounds/prologue/**'")
    assert.ok(hasTrigger, `CI path trigger missing ${asset}`)
    assert.ok(renderer.includes(asset), `Renderer asset mapping missing ${asset}`)
  }
})
