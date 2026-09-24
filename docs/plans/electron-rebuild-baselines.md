# Electron Rebuild Baselines

## Purpose

These scenarios define observable Godot behavior that the Electron version must preserve. They are migration references, not new game requirements.

## Capture Method

Run the following from a clean checkout of the `develop` commit used for the reference images. The script renders through Godot's viewport and writes 1920×1080 PNGs without relying on manual window placement. It requires the GUI renderer; Godot's `--headless` mode does not expose a capturable viewport texture.

```sh
"/path/to/Godot" --rendering-driver opengl3 --path godot --script res://tests/GenerateElectronBaselineImages.gd
```

## 1. Matilda Tutorial

Entry: start the Prologue tutorial battle (`PrologueBattleChapter`).

Expected result: the tutorial battle opens with the protagonist's default inventory, a Normal-grade tutorial deck, and the guided card-selection/battle flow.

Reference: [matilda-tutorial.png](baseline-images/matilda-tutorial.png)

## 2. Fixed Battle

Entry: open `BattleSystemTestChapter`.

Expected result: a stable nine-card deck is shown for both sides; the opponent is Matilda; Bayes Eye and item-display affordances are available.

Reference: [fixed-battle.png](baseline-images/fixed-battle.png)

## 3. Random Battle

Entry: create `RandomBattleChapter` from the `merchant2` encounter.

Expected result: the encounter-derived opponent, portrait, deck, and random-battle flow are initialized without a missing-character error.

Reference: [random-battle.png](baseline-images/random-battle.png)

## 4. Save and Load

Entry: initialize the default inventory, serialize the `GameState` payload, and parse it back before returning to the title scene. This baseline probe never writes a user save slot.

Expected result: the restored payload is nonempty and the title menu remains available for a continuation flow. The title appearance alone does not prove persistence; the generator treats an empty restored payload as a failure.

Reference: [save-load.png](baseline-images/save-load.png)

## Existing Limitations

- These images are state-entry references, not pixel-perfect approval snapshots. The image-comparison tolerance and CI policy remain a later migration decision.
- The current Godot project can render debug/editor chrome when manually run. Generated images intentionally capture the viewport instead.
- The reference set was generated from `develop` commit `ae9abbd` in an isolated worktree because the primary worktree contains unrelated, uncommitted Godot changes.
