import assert from 'node:assert/strict'
import { readFileSync, readdirSync } from 'node:fs'
import { fileURLToPath } from 'node:url'
import test from 'node:test'
import { originalPrologueBattleTraces } from '../../packages/story/original-battle'

test('Godot battle chapters and generated Electron commands do not invoke removed videos', () => {
  const directory = new URL('../../godot/battle/chapters/', import.meta.url)
  for (const filename of readdirSync(directory).filter(name => name.endsWith('.gd'))) {
    const source = readFileSync(fileURLToPath(new URL(filename, directory)), 'utf8')
    assert.doesNotMatch(source, /\.play_video\s*\(/, `Video playback remains in ${filename}`)
  }
  for (const trace of originalPrologueBattleTraces) {
    assert.equal(trace.commands.some(command => command.kind === 'play_video'), false)
    assert.equal(trace.commands.some(command => command.args.some(arg => typeof arg === 'string' && /\.(ogv|mp4|webm)$/.test(arg))), false)
  }
})
