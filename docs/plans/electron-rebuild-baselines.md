# Electron Rebuild Baselines

## Purpose

These scenarios define observable Godot behavior that the Electron version must preserve. They are migration references, not new game requirements.

## Capture Method

Run the following from a clean checkout of the `develop` commit used for the reference images. The script renders through Godot's viewport and writes 1920×1080 PNGs without relying on manual window placement. It requires the GUI renderer; Godot's `--headless` mode does not expose a capturable viewport texture. It also checks a save/load round trip using a uniquely named temporary file under `user://` and removes that file afterward.

```sh
"/path/to/Godot" --rendering-driver opengl3 --path godot --script res://tests/GenerateElectronBaselineImages.gd
```

## 1. Matilda Tutorial

Entry: start the Prologue tutorial battle (`PrologueBattleChapter`) without editor capture mode. Capture the initial guided dialogue with the player's Normal cards visible.

Expected result: the tutorial opens with the protagonist's default inventory and Normal-grade cards visible. The later deck-building and card-selection steps require a separate playthrough; this image records only the opening state.

Reference: [matilda-tutorial.png](baseline-images/matilda-tutorial.png)

## 2. Fixed Battle

Entry: open `BattleSystemTestChapter`, advance the opening line, and use the normal Auto and Ready controls to build the deck.

Expected result: the normal card-selection phase shows the nine-card player deck, Matilda, Bayes Eye, and item-display affordances with both sides at their initial HP.

Reference: [fixed-battle.png](baseline-images/fixed-battle.png)

## 3. Random Battle

Entry: create `RandomBattleChapter` from the `merchant2` encounter, then use the normal Auto and Ready controls to build the deck.

Expected result: the encounter-derived opponent, portrait, and deck appear in the normal opening battle flow with both sides at their initial HP.

Reference: [random-battle.png](baseline-images/random-battle.png)

## 4. Save and Load

Entry: initialize the default inventory, set a distinct chapter, label, and money value, write the `GameState` payload to a new temporary JSON file under `user://`, read it back, reset the state, and apply the loaded data. The probe removes its temporary file and never uses a user save slot.

Expected result: the restored state, including inventory and the distinct values, exactly matches the saved state. The generator exits with an error on a mismatch and prints `[BASELINE] PASS: GameState restored from temporary save file` on success.

Manual UI check for the full continuation flow: save to an unused slot during play, return to the title, choose Continue and the same slot, then confirm the chapter, cards, and money. This UI flow is not exercised by the generator.

## Title

The separate [title.png](baseline-images/title.png) records the initial menu appearance. It is not evidence of a successful load.

## Existing Limitations

- These images are state-entry references, not pixel-perfect approval snapshots. The image-comparison tolerance and CI policy remain a later migration decision.
- The generator stops at the first tutorial dialogue and at card selection in normal battles; it does not complete full matches or the save-slot UI flow.
- The current Godot project can render debug/editor chrome when manually run. Generated images intentionally capture the viewport instead.
- The reference set was generated from `develop` commit `ae9abbd` in an isolated worktree because the primary worktree contains unrelated, uncommitted Godot changes.
