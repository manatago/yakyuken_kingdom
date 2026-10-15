# Electron title and save protection

PR #21 review evidence, captured from the Electron game on macOS on 2026-09-27.
These images use isolated test saves, not actual player data. The screenshots show
the 1280×688 renderer area of the default 1280×720 window.

## Title

![Electron title](title.png)

## Overwrite confirmation

![Existing-save overwrite confirmation](overwrite-confirmation.png)

Opening or cancelling this confirmation leaves the save file unchanged. Only
“保存を上書きして開始” authorizes replacement. If the initial save read fails,
both New Game and Continue are disabled rather than overwriting unreadable data.

## Reproduce

```sh
JANKEN_UI_SCREENSHOT_DIR=test-results/title-start npm run test:ui
```

The UI tests create and remove temporary Electron user-data directories. The
optional screenshot output is ignored by Git; these two copies are review assets.
Source/license: screenshots of this repository's own React/CSS interface; no
external artwork is included.
