# Matilda layout editor

Run `npm run dev:editor` from the project root. The editor is a separate build;
the normal game has no editing screen or content-write IPC.

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
Only that root's fixed Matilda JSON is writable. A moved editor build without a
source project must receive this argument; it is not a player-facing tool.
