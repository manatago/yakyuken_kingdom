# Matilda layout editor

## Developer tools expansion (2026-10-15, in progress)

The normal game's title restores the Godot entrance hierarchy:
**中断から始める → ジャンプ先を選択**, **イベントバトル → 対象選択**, and
**編集モードで始める → 編集機能 → バトル立ち絵編集の種別選択**.
The existing **つづきから** remains a separate action for the player's disk save.
Scene/event selection plays in the same window in an in-memory disposable session.
Returning to its selection screen or closing/reloading the game discards that session;
normal save bytes are never written by it. Standalone events use the original ten
`mode: battle` targets, the initial nine cards and 1000G, then return to event selection
after settlement instead of entering the following story. This is not a resumable save.

Story, event portrait and slideshow editing launch only the fixed separate editor build
with a validated initial view. Its launched window exits on close on Mac too. Both builds
are required. Random portrait editing and battle-system checks are explicitly unavailable
while migration is unfinished; they do not redirect into a different tool.

The separate editor now opens a developer launcher with **途中から始める**,
**ストーリー編集**, **戦闘表示編集**, **紙芝居編集**, and **マチルダ配置編集** tabs. The existing Matilda workflow below
is under its named tab and remains supported. Build both apps before using the
launcher. It creates a disposable game save and automatically resumes it in a new game
window. Closing that development game removes its temporary save, not the normal
player save.

The story editor reads the project's `content/stories/godot-original.json`, edits
one existing command, and preserves its previous bytes in `.bak`. Reload before
saving after a concurrent project change. A new game build includes the saved
JSON and referenced PNG/JPEG/WebP images. It does not rewrite GDScript. Project
images are previewed live through an editor-only, root-restricted image protocol.

Battle and slideshow tabs edit existing visual commands from nine original trace
documents. Structured fields and advanced JSON share the same draft. Saving applies
the change to compatible shared branches within that chapter, backs up the original,
and checks concurrent writes. New bubble text is approved in the same saved document;
the game preserves original captured layouts for unchanged text. Rebuild/restart the
game to use saved content. Source exporters refuse to overwrite editor-backed-up files.

This is not yet Godot editor parity: random-battle tools, image processing, system
checks, dialogue/page insertion/deletion and special jump handlers remain in the single task described
in `docs/plans/electron-developer-tools-parity.md`.

Run `npm run dev:editor` from the project root. The editor is a separate build;
the normal game has only editor-launch menus, not editing controls or content-write IPC.

Select a layout ID or drag the portrait/card region in the preview. Numeric X/Y
coordinates use the 1920×1080 stage, regardless of preview size. Scale affects the
whole selected group. Portrait coordinates are its existing center anchor;
card groups use their top-left anchor. Only portraits offer horizontal flip.

The five editable IDs are the intro and explanation portraits, card box, deck
and showdown group. Explanation scenes share one portrait layout. Preview uses
the same game display components; game controls are inert in the editor.

Changes are preview-only until **配置を保存**. Save one ID at a time; save or
discard before selecting another ID or reloading. Invalid input disables saving.
On failure the draft remains. If another editor changed the same ID, discard and
reload before editing again rather than overwriting it.

The fixed save target is `content/stories/matilda-tutorial.json`. Other records
are read fresh and retained. Its previous bytes are backed up to
`matilda-tutorial.json.bak` before atomic replacement. Backups and write
temporaries are ignored by Git. The renderer cannot choose a filesystem path.

Saving takes a project-wide `.matilda-layout.lock` directory lock, including
across editor processes. Another concurrent save fails without discarding its
draft; retry after the first save finishes. If the same ID changed, discard and
reload before editing again. Locks are released on success and ordinary errors.
If a process is forcibly terminated during saving, the lock may remain: close
all editors for that project, inspect the source and `.bak`, then remove only
the empty `content/stories/.matilda-layout.lock` directory before reopening.
Do not remove a lock while an editor could be saving; locks are never expired
automatically because that could let two live writers replace each other's data.

After saving, close/restart the game after `npm run build:game`, or restart
`npm run dev:game`. The game imports the source JSON at build time, not the
editor's private user-data or a runtime override. Commit the JSON change to
share it or include it in future game builds. No GDScript changes are made.

For an isolated project copy, launch the built editor with a trusted main-process
argument: `electron dist/editor/main/index.js --content-root=/absolute/project`.
The copy must contain the same source JSON and referenced `godot/assets/` files.
Only the fixed content documents within that root are writable. A moved editor build without a
source project must receive this argument; it is not a player-facing tool.
