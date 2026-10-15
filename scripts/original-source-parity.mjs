// User-approved deferral: the adventurer tutorial does not grant this item yet.
// Match the complete known hook, never arbitrary reward functions or dialogue.
export function stripDeferredAdventurerReward(source) {
  return source.replace(/^func get_item_rewards\(\) -> Array:\n\treturn \["substitute_card"\]\n\n/m, '')
}
