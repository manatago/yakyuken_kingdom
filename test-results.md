# Test results

## 2026-09-28 10:31 JST — PR #22 LFS CI authentication resolution

- GitHub Secret names `LFS_USERNAME` and `LFS_PASSWORD`: confirmed registered;
  their values were not retrieved.
- `npm run typecheck`: passed.
- `npm run test:unit`: 30 passed, 0 failed, 0 skipped.
- `npm run test:integration`: 10 passed, 0 failed, 0 skipped (includes four new LFS checks).
- `npm run test:ui`: 9 passed, 0 failed, 0 skipped.
- Workflow YAML parse: passed using Ruby YAML.
- Coverage percentage: not measured; no coverage reporter is configured.

The image-fetch step now receives Secrets through step-scoped environment
variables and uses a command-scoped Git credential helper. The helper only returns
credentials for the existing repository LFS endpoint; store/erase are no-ops.
Preflight rejects missing or invalid Secrets without printing their values.
Node setup precedes the fetch step; all existing build/test steps remain.

Regression checks use dummy credentials (including shell-special characters),
test endpoint/path restrictions and missing/invalid credentials, exercise real
`git credential fill` without any network calls, and assert workflow Secret wiring.
Verification ran on macOS for the existing Electron GUI tests, using temporary
save directories that are cleaned up after each scenario. No actual player saves,
credential files, Git configuration, or LFS server settings were changed.

Actual GitHub Secrets cannot be read back locally: authenticated LFS downloading
and Windows execution must be confirmed by CI after publishing. HTTP transport
remains unchanged per the chosen existing-account setup; communication with the
LFS server is not encrypted. Fork and Dependabot PRs do not receive these Secrets
and will stop at preflight rather than silently skipping image verification.

## 2026-09-28 09:11 JST — Task 3.2 Matilda dialogue and scene

- `npm run typecheck`: passed.
- `npm run test:unit`: 30 passed, 0 failed, 0 skipped.
- `npm run test:integration`: 6 passed, 0 failed, 0 skipped.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/story npm run test:ui`: 9 passed, 0 failed, 0 skipped.
- Coverage percentage: not measured; no coverage reporter is configured.

Red evidence before implementation: the story unit test failed because its runner
module was missing; the initial UI test timed out on the placeholder screen.
The first implementation run then passed unit tests but failed dialogue restart:
the UI loop issued another click before the previous checkpoint had rendered.
The resumed test now waits for checkpoint change and save completion after every
successful advance and verifies the file checkpoint matches the displayed one.
Content expectations were preserved; no production change was needed for this fix.

Checks cover real bundled images, portrait changes, appended grade explanations,
restart at the displayed checkpoint, the explicit pre-deck boundary, unchanged
player inventory/flags, save-write failure, and existing title/save protections.
Unit checks cover validated append metadata, deterministic frame replay, loops,
invalid checkpoints and uniform viewport sizing.

Verification ran on the macOS host for Electron GUI support, with temporary
`--user-data-dir` directories removed after closing each app. No actual player saves,
DB or external services were accessed. FHD, 4:3 and portrait screenshots were
inspected and copied to `docs/plans/electron-story-rendering-images/`.
Windows execution remains for CI after publication. Video/HTML-player generation
was not run because `generate-player.ts` is unavailable in this repository.

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
