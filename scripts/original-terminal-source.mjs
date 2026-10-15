import assert from 'node:assert/strict'

export function extractOriginalTerminalTimings(script) {
  const body = script.split('func play_terminal_effect(entry: Cmd.TerminalEffect):')[1]?.split('\nfunc ')[0]
  assert.ok(body, 'Missing original terminal handler')
  const number = pattern => {
    const match = body.match(pattern)
    assert.ok(match, `Missing original terminal timing ${pattern}`)
    return Number(match[1]) * 1000
  }
  assert.ok(!body.includes('entry.hold_time'), 'Original terminal hold behavior changed')
  return { fade_in: number(/tween_property\(overlay, "color:a", 0\.6, ([\d.]+)\)/),
    glitch: number(/create_timer\((0\.05)\)/), glitch_after: number(/create_timer\((0\.1)\)/),
    flash: number(/create_timer\((0\.08)\)/),
    fade_out: number(/tween_property\(overlay, "color:a", 0\.0, ([\d.]+)\)/),
    text_fade_out: number(/tween_property\(terminal, "modulate:a", 0\.0, ([\d.]+)\)/) }
}
