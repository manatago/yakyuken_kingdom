# Session Current State

## Branch: feature/battle-scene
## Date: 2026-02-27

## Completed This Session
- Fixed Bug 1: display_scale not persisting from 3rd portrait change
  - Root cause: `target_rect.position = target_pos` in `_show_character()` was overwriting `offset_left` set by `_apply_display_scale` (Godot 4 anchor system recalculates offsets when position is set)
  - Fix: Restructured `_show_character` flow to: reset offsets → set position → THEN apply scale/offset_y
  - Now always resets offsets to defaults, always applies position (from cache or computed), then applies display adjustments as deltas
- Fixed Bug 2: right-edge clipping when heroine scaled up on right side
  - Root cause: Symmetric expansion pushed offset_right to -10, placing right edge at 1910px (10px from 1920 screen edge)
  - Fix: Changed `_apply_display_scale` to directional expansion:
    - RightChar: expands leftward only (offset_left decreases, offset_right unchanged)
    - LeftChar: expands rightward only (offset_right increases, offset_left unchanged)
    - CenterChar: symmetric expansion

## Modified Files (uncommitted)
- `godot/scripts/StoryScene.gd` - Restructured _show_character, _apply_display_scale, _apply_display_offset_y
- `godot/resources/story/StoryCharacter.gd` - display_scale and display_offset_y properties (from previous session)
- `godot/resources/story/DefaultStory.gd` - heroine display_scale=1.45, display_offset_y=40.0 (from previous session)
- Various other files from previous sessions (see git status)

## Next Actions
- Visual testing to confirm both bugs are fixed
- Commit all changes
