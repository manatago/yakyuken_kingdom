# Test results

## 2026-09-28 08:16 JST — PR #21 save-protection resolution

- `npm run typecheck`: passed.
- `npm run test:unit`: 25 passed, 0 failed, 0 skipped.
- `npm run test:integration`: 6 passed, 0 failed, 0 skipped.
- `npm run test:ui`: 7 passed, 0 failed, 0 skipped.
- Coverage percentage: not measured; the project has no coverage reporter configured.

Regression checks cover confirmation-before-overwrite, cancel without modifying
the existing save, explicit overwrite, unreadable-save protection, and the existing
write-failure path. The write-failure fixture now introduces its obstruction only
after a successful read so that it still tests writing, rather than blocked startup.

Verification ran on the macOS host because the Electron UI requires the GUI runtime.
Each UI scenario used a temporary `--user-data-dir`, closed Electron and removed the
directory afterward. Actual player saves and external services were not accessed.

Title and overwrite-confirmation screenshots were inspected and copied into
`docs/plans/electron-title-start-images/`. Video and HTML-player generation were not
run: this repository does not provide `generate-player.ts`.
