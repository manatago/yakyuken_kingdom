import assert from 'node:assert/strict'
import { spawnSync } from 'node:child_process'
import { createHash } from 'node:crypto'
import { mkdtempSync, readFileSync, readdirSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { stripDeferredAdventurerReward } from './original-source-parity.mjs'
import { extractOriginalVisualStyle } from './original-visual-style-source.mjs'
import { extractOriginalStoryMenu } from './original-story-menu-source.mjs'

const root = fileURLToPath(new URL('..', import.meta.url))
const executable = process.argv[2]
if (!executable) throw new Error('Usage: node scripts/verify-original-story.mjs PATH_TO_GODOT')
const referenceRoot = process.argv[3]
const highlightOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-highlight-verify-')), 'highlight.json')
const highlightResult = spawnSync(executable, ['--headless', '--path', join(referenceRoot ?? root, 'godot'),
  '--log-file', `${highlightOutput}.log`, '--script', join(root, 'godot/export_battle_highlight.gd'), '--',
  highlightOutput, join(referenceRoot ?? root, 'godot')], { encoding: 'utf8', timeout: 60_000 })
if (highlightResult.error) throw highlightResult.error
if (highlightResult.status !== 0 || /SCRIPT ERROR|Missing original|leaked|resources still in use/.test(highlightResult.stderr)) {
  throw new Error(`Original highlight capture failed: ${highlightResult.stdout}\n${highlightResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(highlightOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-battle-highlight.json'), 'utf8')), 'Original highlight geometry/pulse differs')
console.log('Original highlight isolated method verified: 10 placements and 41 SINE pulse samples')
const dialogueOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-dialogue-verify-')), 'dialogue.json')
const dialogueResult = spawnSync(executable, ['--headless', '--path', join(referenceRoot ?? root, 'godot'),
  '--log-file', `${dialogueOutput}.log`, '--script', join(root, 'godot/export_battle_dialogue.gd'), '--', dialogueOutput],
  { encoding: 'utf8', timeout: 60_000 })
if (dialogueResult.error) throw dialogueResult.error
if (dialogueResult.status !== 0 || /SCRIPT ERROR|leaked|resources still in use/.test(dialogueResult.stderr)) {
  throw new Error(`Original dialogue capture failed: ${dialogueResult.stdout}\n${dialogueResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(dialogueOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-battle-dialogue.json'), 'utf8')), 'Original battle dialogue controls differ')
console.log('Original battle/selection/minigame central dialogue verified: 6 actual control layouts')
const bubblesOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-bubbles-verify-')), 'bubbles.json')
const bubblesResult = spawnSync(executable, ['--headless', '--path', join(referenceRoot ?? root, 'godot'),
  '--log-file', `${bubblesOutput}.log`, '--script', join(root, 'godot/export_battle_bubbles.gd'), '--', bubblesOutput,
  join(root, 'content/stories')], { encoding: 'utf8', timeout: 60_000 })
if (bubblesResult.error) throw bubblesResult.error
if (bubblesResult.status !== 0 || /SCRIPT ERROR|leaked|resources still in use/.test(bubblesResult.stderr)) {
  throw new Error(`Original explicit bubbles capture failed: ${bubblesResult.stdout}\n${bubblesResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(bubblesOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-battle-bubbles.json'), 'utf8')), 'Original explicit bubble controls/text wrapping differ')
console.log('Original explicit bubble controls verified: 113 source text/side layouts')
const farewellOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-farewell-verify-')), 'farewell.json')
const farewellResult = spawnSync(executable, ['--headless', '--path', join(referenceRoot ?? root, 'godot'),
  '--log-file', `${farewellOutput}.log`, '--script', join(root, 'godot/capture_farewell_controls.gd'), '--', farewellOutput],
  { encoding: 'utf8', timeout: 60_000 })
if (farewellResult.error) throw farewellResult.error
if (farewellResult.status !== 0 || /SCRIPT ERROR|leaked|resources still in use/.test(farewellResult.stderr)) {
  throw new Error(`Original farewell capture failed: ${farewellResult.stdout}\n${farewellResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(farewellOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-farewell-controls.json'), 'utf8')), 'Original Main farewell controls differ')
console.log('Original Main farewell controls verified: 19 reconstructed battle boundaries')
assert.deepEqual(extractOriginalStoryMenu(readFileSync(join(referenceRoot ?? root, 'godot/StoryScene.tscn'), 'utf8'),
  readFileSync(join(referenceRoot ?? root, 'godot/game/StoryScene.gd'), 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-story-menu.json'), 'utf8')), 'Original story menu differs')
console.log('Original story menu labels verified')
const menuInputOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-menu-input-verify-')), 'input.json')
const menuInputResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-story-menu-input.mjs'), executable, menuInputOutput],
  { encoding: 'utf8', timeout: 60_000 })
if (menuInputResult.error) throw menuInputResult.error
if (menuInputResult.status !== 0) throw new Error(`Original menu input capture failed: ${menuInputResult.stdout}\n${menuInputResult.stderr}`)
const menuInput = JSON.parse(readFileSync(menuInputOutput, 'utf8'))
assert.deepEqual(menuInput, JSON.parse(readFileSync(join(root, 'content/stories/godot-story-menu-input.json'), 'utf8')),
  'Original focused viewer keyboard dispatch differs')
for (const [path, hash] of Object.entries(menuInput.source_hashes)) {
  assert.equal(createHash('sha256').update(readFileSync(join(referenceRoot ?? root, 'godot', path))).digest('hex'), hash,
    `Reference menu input source differs: ${path}`)
}
console.log('Original focused viewer ui_accept verified (key echo ignored; panel remains open)')
const terminalOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-terminal-verify-')), 'terminal.json')
const terminalResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-terminal.mjs'), executable, terminalOutput],
  { encoding: 'utf8', timeout: 60_000 })
if (terminalResult.error) throw terminalResult.error
if (terminalResult.status !== 0) throw new Error(`Original terminal capture failed: ${terminalResult.stdout}\n${terminalResult.stderr}`)
const terminalSource = JSON.parse(readFileSync(terminalOutput, 'utf8'))
assert.deepEqual(terminalSource, JSON.parse(readFileSync(join(root, 'content/stories/godot-terminal-effect.json'), 'utf8')),
  'Original terminal input or geometry differs')
assert.equal(createHash('sha256').update(readFileSync(join(referenceRoot ?? root, 'godot/game/StoryScene.gd'))).digest('hex'),
  terminalSource.source_hash, 'Reference terminal source differs')
console.log('Original isolated terminal input/geometry/timings verified')
const menuGeometryOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-menu-')), 'geometry.json')
const menuGeometryResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
  `${menuGeometryOutput}.log`, '--script', 'res://export_story_menu_geometry.gd', '--', menuGeometryOutput],
  { encoding: 'utf8', timeout: 60_000 })
if (menuGeometryResult.error) throw menuGeometryResult.error
if (menuGeometryResult.status !== 0 || /SCRIPT ERROR|Cannot write/.test(menuGeometryResult.stderr)) {
  throw new Error(`Original menu capture failed: ${menuGeometryResult.stdout}\n${menuGeometryResult.stderr}`)
}
const menuGeometry = JSON.parse(readFileSync(menuGeometryOutput, 'utf8'))
assert.deepEqual(menuGeometry,
  JSON.parse(readFileSync(join(root, 'content/stories/godot-story-menu-geometry.json'), 'utf8')), 'Original menu geometry differs')
for (const [path, hash] of Object.entries(menuGeometry.source_hashes)) {
  assert.equal(createHash('sha256').update(readFileSync(join(referenceRoot ?? root, 'godot', path))).digest('hex'), hash,
    `Reference menu source differs: ${path}`)
}
console.log('Original menu geometry verified (empty inventory; icon rendering not verified)')
const inventoryOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-inventory-verify-')), 'inventory.json')
const inventoryResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-inventory.mjs'), executable,
  referenceRoot ?? root, inventoryOutput], { encoding: 'utf8', timeout: 60_000 })
if (inventoryResult.error) throw inventoryResult.error
if (inventoryResult.status !== 0) throw new Error(`Original imported inventory capture failed: ${inventoryResult.stdout}\n${inventoryResult.stderr}`)
assert.deepEqual(JSON.parse(readFileSync(inventoryOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-story-inventory-geometry.json'), 'utf8')), 'Original imported inventory geometry differs')
console.log('Original imported inventory verified: populated/empty panels, title/close/icon rectangles; glyph pixels not compared')
const skipOutput = join(mkdtempSync(join(tmpdir(), 'janken-original-skip-verify-')), 'skip.json')
const skipResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-story-skip.mjs'), executable, skipOutput, referenceRoot ?? root],
  { encoding: 'utf8', timeout: 60_000 })
if (skipResult.error) throw skipResult.error
if (skipResult.status !== 0) throw new Error(`Original Skip capture failed: ${skipResult.stdout}\n${skipResult.stderr}`)
const skipSource = JSON.parse(readFileSync(skipOutput, 'utf8'))
assert.deepEqual(skipSource, JSON.parse(readFileSync(join(root, 'content/stories/godot-story-skip.json'), 'utf8')),
  'Original prebattle Skip boundaries differ')
for (const sample of skipSource.cases) for (const [path, hash] of Object.entries(sample.source_hashes)) {
  assert.equal(createHash('sha256').update(readFileSync(join(referenceRoot ?? root, 'godot', path))).digest('hex'), hash,
    `Reference Skip source differs: ${path}`)
}
assert.equal(createHash('sha256').update(readFileSync(join(referenceRoot ?? root, 'godot/game/Main.gd'))).digest('hex'),
  skipSource.battle_boundary.action_details.main_source_hash, 'Reference Main Skip bridge differs')
console.log('Original Skip verified: six prebattle boundaries and pending Main battle I/O; full battle rendering/results not verified')
assert.deepEqual(extractOriginalVisualStyle(readFileSync(join(referenceRoot ?? root, 'godot/game/StoryScene.gd'), 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-visual-style.json'), 'utf8')), 'Original automatic background filter differs')
console.log('Original automatic background filter verified')
if (referenceRoot) {
  const files = ['DefaultStory.gd', 'StoryCommands.gd', 'StoryCharacter.gd', 'PortraitLayout.gd',
    ...readdirSync(join(root, 'godot/story/chapters')).filter(f => f.endsWith('.gd')).map(f => `chapters/${f}`)]
  for (const file of files) {
    assert.deepEqual(readFileSync(join(root, 'godot/story', file)),
      readFileSync(join(referenceRoot, 'godot/story', file)), `Reference source differs: ${file}`)
  }
  console.log(`Reference source verified: ${files.length} files`)
  const chapter = 'godot/battle/chapters/PrologueBattleChapter.gd'
  assert.deepEqual(readFileSync(join(root, chapter)), readFileSync(join(referenceRoot, chapter)), 'Reference prologue battle differs')
}
const directory = mkdtempSync(join(tmpdir(), 'janken-original-story-'))
const geometryOutput = join(directory, 'geometry.json')
const geometryResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-story-geometry.mjs'), executable,
  referenceRoot ?? root, geometryOutput], { encoding: 'utf8', timeout: 60_000 })
if (geometryResult.error) throw geometryResult.error
if (geometryResult.status !== 0) throw new Error(`Original geometry regeneration failed: ${geometryResult.stdout}\n${geometryResult.stderr}`)
assert.deepEqual(JSON.parse(readFileSync(geometryOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-story-geometry.json'), 'utf8')), 'Original standalone geometry differs')
console.log('Original standalone portrait geometry verified: 47 sequences, 2311 boundaries')
const output = join(directory, 'commands.json')
const result = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
  join(directory, 'godot.log'), '--script', 'res://export_story_commands.gd', '--', output], {
  encoding: 'utf8', timeout: 60_000
})
if (result.error) throw result.error
if (result.status !== 0 || /SCRIPT ERROR|Unsupported|Cannot open/.test(result.stderr)) {
  throw new Error(`Original export failed: ${result.stdout}\n${result.stderr}`)
}
const expected = JSON.parse(readFileSync(join(root, 'content/stories/godot-original.json'), 'utf8'))
const actual = JSON.parse(readFileSync(output, 'utf8'))
assert.deepEqual(actual, expected, 'Checked-in commands differ from the executed Godot builders')
console.log(`Original parity verified: ${actual.sequences.length} sequences, ${actual.sequences.reduce((n, s) => n + s.commands.length, 0)} commands`)
console.log(`Evidence: ${directory}`)
const battleOutput = join(directory, 'battle.json')
const battleResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
  join(directory, 'battle.log'), '--script', 'res://export_prologue_battle.gd', '--', battleOutput], {
  encoding: 'utf8', timeout: 60_000
})
if (battleResult.error) throw battleResult.error
if (battleResult.status !== 0 || /SCRIPT ERROR|Cannot open/.test(battleResult.stderr)) {
  throw new Error(`Battle trace export failed: ${battleResult.stdout}\n${battleResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(battleOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-prologue-battle.json'), 'utf8')), 'Original battle traces differ')
console.log('Original prologue battle branches verified: 27 traces')
const adventurerOutput = join(directory, 'adventurer.json')
if (referenceRoot) {
  const chapter = 'godot/battle/chapters/Stage1BattleChapter.gd'
  assert.equal(stripDeferredAdventurerReward(readFileSync(join(root, chapter), 'utf8')),
    stripDeferredAdventurerReward(readFileSync(join(referenceRoot, chapter), 'utf8')), 'Reference Stage 1 battle differs outside deferred reward')
  console.log('Deferred by user: adventurer substitute_card reward (not granted in Electron)')
}
const adventurerResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
  join(directory, 'adventurer.log'), '--script', 'res://export_stage1_battle.gd', '--', adventurerOutput], {
  encoding: 'utf8', timeout: 60_000
})
if (adventurerResult.error) throw adventurerResult.error
if (adventurerResult.status !== 0 || /SCRIPT ERROR|Cannot open|Compilation failed/.test(adventurerResult.stderr)) {
  throw new Error(`Adventurer export failed: ${adventurerResult.stdout}\n${adventurerResult.stderr}`)
}
assert.deepEqual(JSON.parse(readFileSync(adventurerOutput, 'utf8')),
  JSON.parse(readFileSync(join(root, 'content/stories/godot-stage1-battle.json'), 'utf8')), 'Original adventurer traces differ')
console.log('Original adventurer tutorial verified: 3 traces')
// Current reference chapters include newer grades and reward hooks than this
// worktree's preserved Godot sources. Require the explicit reference for them.
if (referenceRoot) {
  const showdownOutput = join(directory, 'showdown.json')
  const showdownResult = spawnSync(process.execPath, [join(root, 'scripts/export-original-showdown.mjs'), executable,
    referenceRoot, showdownOutput], { encoding: 'utf8', timeout: 60_000 })
  if (showdownResult.error) throw showdownResult.error
  if (showdownResult.status !== 0) throw new Error(`Original showdown export failed: ${showdownResult.stdout}\n${showdownResult.stderr}`)
  assert.deepEqual(JSON.parse(readFileSync(showdownOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-showdown.json'), 'utf8')), 'Original showdown geometry, timing, curves or grade explanations differ')
  console.log('Original showdown verified: 7.2s asynchronous result pop, 61 BACK/OUT samples, 75 grade explanations')
  const mainOutput = join(directory, 'main-flow.json')
  const mainResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'main-flow.log'), '--script', 'res://export_main_flow.gd', '--', mainOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (mainResult.error) throw mainResult.error
  if (mainResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Cannot open/.test(mainResult.stderr)) {
    throw new Error(`Original Main flow export failed: ${mainResult.stdout}\n${mainResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(mainOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-main-flow.json'), 'utf8')), 'Original Main aftermath and redirect traces differ')
  console.log('Original Main flow verified: 6 scenario traces, 5 Matilda battle bridge traces')
  const questOutput = join(directory, 'quest-battles.json')
  const questResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'quest-battles.log'), '--script', 'res://export_quest_battles.gd', '--', questOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (questResult.error) throw questResult.error
  if (questResult.status !== 0 || /SCRIPT ERROR|Cannot open|Compilation failed/.test(questResult.stderr)) {
    throw new Error(`Quest battle export failed: ${questResult.stdout}\n${questResult.stderr}`)
  }
  const actual = JSON.parse(readFileSync(questOutput, 'utf8'))
  assert.deepEqual(actual, JSON.parse(readFileSync(join(root, 'content/stories/godot-quest-battles.json'), 'utf8')),
    'Original quest battle configuration or traces differ')
  console.log(`Original quest battles verified: ${actual.chapters.length} chapters, ${actual.chapters.reduce((n, c) => n + c.traces.length, 0)} traces`)
  const curseOutput = join(directory, 'subevent3-minigame.json')
  const curseResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'subevent3-minigame.log'), '--script', 'res://export_subevent3_minigame.gd', '--', curseOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (curseResult.error) throw curseResult.error
  if (curseResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(curseResult.stderr)) {
    throw new Error(`Original curse minigame export failed: ${curseResult.stdout}\n${curseResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(curseOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-subevent3-minigame.json'), 'utf8')), 'Original curse minigame differs')
  console.log('Original curse minigame verified: 18 choices, 15 Pisuke traces, intro and ending narration')
  const expressionOutput = join(directory, 'stage2-minigame.json')
  const expressionResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'stage2-minigame.log'), '--script', 'res://export_stage2_minigame.gd', '--', expressionOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (expressionResult.error) throw expressionResult.error
  if (expressionResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(expressionResult.stderr)) {
    throw new Error(`Original expression minigame export failed: ${expressionResult.stdout}\n${expressionResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(expressionOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-stage2-minigame.json'), 'utf8')), 'Original expression minigame differs')
  console.log('Original expression minigame verified: 10 scenes, 50 responses and support unlock timing')
  const campaignOutput = join(directory, 'campaign-battles.json')
  const campaignResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'campaign-battles.log'), '--script', 'res://export_campaign_battles.gd', '--', campaignOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (campaignResult.error) throw campaignResult.error
  if (campaignResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(campaignResult.stderr)) {
    throw new Error(`Original campaign export failed: ${campaignResult.stdout}\n${campaignResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(campaignOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-campaign-battles.json'), 'utf8')), 'Original campaign battle traces differ')
  console.log('Original campaign battles verified: 10 configurations, 90 result traces')
  const evidenceOutput = join(directory, 'stage3-minigame.json')
  const evidenceResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'stage3-minigame.log'), '--script', 'res://export_stage3_minigame.gd', '--', evidenceOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (evidenceResult.error) throw evidenceResult.error
  if (evidenceResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(evidenceResult.stderr)) {
    throw new Error(`Original book/evidence minigame export failed: ${evidenceResult.stdout}\n${evidenceResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(evidenceOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-stage3-minigame.json'), 'utf8')), 'Original book/evidence minigame differs')
  console.log('Original book/evidence minigame verified: 225 pairs, 7 repeats and 7 support traces')
  const strengthOutput = join(directory, 'stage4-minigame.json')
  const strengthResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'stage4-minigame.log'), '--script', 'res://export_stage4_minigame.gd', '--', strengthOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (strengthResult.error) throw strengthResult.error
  if (strengthResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(strengthResult.stderr)) {
    throw new Error(`Original strength minigame export failed: ${strengthResult.stdout}\n${strengthResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(strengthOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-stage4-minigame.json'), 'utf8')), 'Original strength minigame differs')
  console.log('Original strength minigame verified: 30 choices, 9 support traces, 131 zone boundaries and 262 gauge transitions')
  const questionOutput = join(directory, 'stage5-minigame.json')
  const questionResult = spawnSync(executable, ['--headless', '--path', join(root, 'godot'), '--log-file',
    join(directory, 'stage5-minigame.log'), '--script', 'res://export_stage5_minigame.gd', '--', questionOutput,
    join(referenceRoot, 'godot')], { encoding: 'utf8', timeout: 60_000 })
  if (questionResult.error) throw questionResult.error
  if (questionResult.status !== 0 || /SCRIPT ERROR|Cannot compile|Compilation failed/.test(questionResult.stderr)) {
    throw new Error(`Original question minigame export failed: ${questionResult.stdout}\n${questionResult.stderr}`)
  }
  assert.deepEqual(JSON.parse(readFileSync(questionOutput, 'utf8')),
    JSON.parse(readFileSync(join(root, 'content/stories/godot-stage5-minigame.json'), 'utf8')), 'Original question minigame differs')
  console.log('Original question minigame verified: 12 questions, 72 responses, 262 gauge transitions and victory evidence')
} else {
  console.warn('Quest battle reference parity not checked: pass the current Godot repository root as the third argument')
}
