# Test results

## 2026-09-28 — Task 3.5 concurrent-editor save protection

- Red: independent stores both accepted the same expected layout (2 successes,
  expected 1), and a separate Node process ignored a held project lock.
  The subprocess harness first required CommonJS-compatible module loading;
  after correcting that setup, both intended race checks failed before the fix.
- Green: atomic project-directory lock encloses reread, target conflict check,
  backup and replacement. A competing writer fails without touching the source;
  success/error releases the lock. Stale crash locks fail closed, with manual
  recovery documented; they are never expired automatically.
- Focused project-store suite: all 5 passed. Independent-store overlap preserves
  the winning record/backup, and a subsequent different-ID save retains it.
  A child process cannot save under a held lock; retry works after release.
- `npm run typecheck`: passed.
- `npm test`: 43 unit and 13 integration tests passed, no failures/skips.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/layout npm run test:ui`: all 13 passed,
  no failures/skips, including drag, failure/draft retention, save and reopen.
- Both smoke targets passed. Deliberately rejected null IPC probes emit errors.
- Isolated editor save -> copied game rebuild -> new game/Continue launches:
  position/scale reflected both times; unrelated content, backup and player save
  bytes retained. Build-isolation integration checks passed.
- Screenshot checks retain a visible aspect-preserving preview with real art.
- Coverage percentage unavailable; Windows execution remains for publication CI.

All checks use host macOS and temporary project/player-data directories, cleaned
in finally. No real saves, source edits through the app, Godot/images, services,
credentials, dependencies, commits or PR writes. The two regression tests and
project-wide locking address the prior concurrent-editor review finding.

## 2026-09-28 — Task 3.5 preview-width resolution

- Editor-only `align-items: stretch` restores workspace/preview width. Existing
  drag coordinates and save expectations were not changed.
- `npm run typecheck`: passed.
- `npm test`: 41 unit and 13 integration tests passed, no failures/skips.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/layout npm run test:ui`: all 13 passed,
  no failures/skips, including scaled drag, numeric preview, invalid input,
  backup failure/draft retention, save, reload and editor reopen.
- `npm run smoke:game` / `npm run smoke:editor`: both passed (`SMOKE_OK`).
  Invalid null IPC writes deliberately emit handler errors during these probes.
- Isolated source/assets copy: actual editor saved only card-box X=1510,
  scale=0.9; other records and original-byte backup were preserved. Rebuilding
  that copy's game and launching it twice (new game, then Continue) rendered
  the saved position/scale both times and retained the player's save bytes.
- Editor and game-reflection screenshots were visually inspected. Preview is
  visible, aspect-preserving and displays real portraits/cards.
- Coverage percentage is not measured; Windows execution remains for CI.

Tests ran on host macOS with temporary project/player-data directories removed
in finally. No actual player saves, source content through the app, Godot/assets,
external services or credentials were changed. Build-isolation integration
checks passed. Final review identified a remaining concurrent-editor write
race: the write queue is instance-local and the byte recheck before rename does
not serialize separate processes. Staging and Gate have not been performed;
this is not a claim that Task 3.5 is complete. No follow-up code correction was
made after that review finding.

## 2026-09-28 — Task 3.5 import resolution (UI verification incomplete)

- Six relative imports in LayoutEditor.tsx corrected, with no expectation changes.
- `npm run typecheck`: passed.
- `npm test`: 41 unit and 13 integration tests passed, no failures/skips.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/layout npm run test:ui`: 12 passed,
  1 failed, none skipped. New layout UI failed its drag assertion at line 46.
- Both smoke commands chained after UI, isolated game rebuild/restart reflection,
  final review, staging and gate were not executed. Coverage is not measured.

Read-only GUI diagnosis in a copied temporary project measured the card box and
story stage at width/height 0. X remained 1554; stage.width/1920 was zero, so the
expected drag coordinate was not finite. The diagnostic screenshot confirms an
absent preview. Shared main CSS sets place-items:center; the editor flex root
inherits centered alignment and its workspace shrinks around the 290px toolbar,
leaving the preview no width. Proposed fix is editor-only stretch/width styling,
not weaker drag expectations. No consecutive implementation fix was applied.

New store/movement unit checks passed, including backup bytes, other-record
preservation, stale/invalid writes, linked target and backup-error protection.
Existing gameplay UI regressions passed. Saving/reopening the new editor remains
unverified because its scenario stopped before those actions.

All UI and diagnosis used host macOS and temporary project/player-data paths
removed in finally. No real source JSON was written through the app and no real
player saves, external services, Godot/assets or credentials were changed.
The temporary dependency symlink was removed; the target dependencies remain.

## 2026-09-28 — Task 3.5 initial implementation (verification incomplete)

- Red: `node --import tsx --test tests/unit/layout.test.ts tests/unit/layout-store.test.ts`
  failed because the new layout and project-layout-store modules did not exist.
- Post-implementation `npm run typecheck` failed with TS2307 for six imports
  in `electron/editor/src/LayoutEditor.tsx`, plus consequent TS7006 errors.
- The chained focused unit run was not executed after typecheck failure.
  Full unit/integration/UI suites, game rebuild/restart verification, screenshots,
  both smoke targets, review, staging and gate have not been completed.
- Coverage percentage is not measured; Windows verification remains for CI.

The editor file uses four parent segments for root packages instead of three,
and three for electron/preload instead of two. The referenced modules exist.
Smallest proposed fix: correct those six relative imports, then typecheck and
run the full verification plan. No consecutive code/test fix was applied after
failure. SDD/TDD remains at Implement; this entry is not a completion claim.

Node/Electron verification uses the macOS host, with new tests designed around
temporary project and player-data directories cleaned in finally. Actual source
content was not edited through the running editor, and actual player saves,
Godot/assets, external services and credentials were not accessed. The temporary
dependency symlink was removed after the failed check; its target is retained.

## 2026-09-28 — Task 3.4 preparation-test input resolution

- `npm run typecheck`: passed.
- `npm test`: 36 unit and 13 integration tests passed, no failures/skips.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/tutorial npm run test:ui`: 12 passed,
  no failures/skips.
- `npm run smoke:game` / `npm run smoke:editor`: both passed (`SMOKE_OK`).
- Coverage percentage not measured; Windows execution remains for CI.

The invalid-deck tests now use the preparation checkpoint without a tutorial
ledger. Both the eight-card and unowned-copy cases require the specific
`Nine owned Normal cards required` error, preventing the already-prepared guard
from satisfying these assertions. The separate wrong-checkpoint assertion remains.
This resolution changes test input/expectations and this record only, not runtime
behavior. The full suite reverified two-round practice, save failure/retry,
restart and completion using temporary save directories cleaned in finally on
the macOS host. Actual player saves and external services were not accessed.

## 2026-09-28 — Task 3.4 UI counting resolution and full re-verification

- `npm run typecheck`: passed.
- `npm test`: 36 unit and 13 integration tests passed, no failures/skips.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/tutorial npm run test:ui`: 12 passed,
  no failures/skips, including two-round practice and its restart/error paths.
- `npm run smoke:game` / `npm run smoke:editor`: both passed (`SMOKE_OK`).
  Rejected null IPC writes deliberately emit handler errors during these probes.
- Coverage percentage not measured: the existing runner has no coverage reporter.

The corrected UI check now requires three visible Paper entries, two enabled and
one disabled after the first victory. Expected card consumption is unchanged;
production behavior was not adjusted for this resolution. The test continued
through second-round selection restart, failed save with no displayed result,
successful retry, saved-result restart, completion flag/checkpoint and completion
restart. Inventory and money remain unchanged.

The resulting `test-results/tutorial/tutorial-result.png` screenshot was visually
inspected: both full cards, HP, feedback, remaining deck and end-practice control
are visible. Existing FHD/4:3/portrait card and dialogue tests also passed.
All tests used host macOS GUI support and temporary player-data directories
removed in finally. No actual saves, DB, services, Godot/assets, credentials,
HTTPS configuration or dependencies were changed. Windows remains for CI.
Temporary dependency symlink removed after verification; target retained.

## 2026-09-28 — Task 3.4 initial implementation verification (incomplete)

- `npm run typecheck`: passed.
- `npm test`: 36 unit and 13 integration tests passed, none failed or skipped.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/tutorial npm run test:ui`: 11 passed,
  1 failed, none skipped. Workflow stopped before review/staging/gate.
- Smoke commands after the failing UI suite were not executed.
- Coverage percentage not measured; existing runner has no coverage reporter.

Red evidence before implementation: new unit test could not load the absent
`packages/battle/tutorial` module; new UI test timed out waiting for the missing
Auto button after launching the built app and loading the isolated preparation save.

The new UI test then passed preparation, first fixed-rock victory, and result
restart, but failed at `tutorial-battle.test.mjs:51` (`3 !== 2`). The locator counts
all three visible Paper buttons, including the used, disabled copy. Production
disables used entries (`TutorialBattle.tsx:68`), preserving the nine-slot display.
Proposed correction: assert two enabled Paper buttons and one disabled copy,
not change the expected consumption. No consecutive source/test fix was applied.
Second-round save failure/retry, completion and completion restart remain unverified.

Host macOS Electron was used because GUI support is required. Test saves lived
in temporary directories removed by finally blocks; no actual player saves,
DB/services, Godot sources, assets, credentials or HTTPS settings were modified.
The temporary dependency symlink was removed; its target dependencies remain intact.
Windows/macOS CI remains for publication after successful local verification.

## 2026-09-28 15:30 JST — Task 3.3 oversized-deck review resolution

- `npm run typecheck`: passed.
- `npm test`: 32 unit and 13 integration tests passed, none failed or skipped.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/cards npm run test:ui`: 11 passed,
  none failed or skipped.
- Coverage percentage: not measured; no coverage reporter is configured.

Red regression evidence: the ten-card saved-deck fixture rendered ten grid slots,
failing the new exact-nine assertion (`10 !== 9`). The deck grid now always has
nine slots. Additional saved cards are exposed in a separately labelled, scrollable
overflow panel with a saved-count heading, not silently discarded or rewritten.
The regression checks nine and ten cards, overflow absence/presence, full preview
of the tenth card and byte-for-byte unchanged saves after UI interaction.

The overflow screenshot in ignored `test-results/cards/cards-overflow.png` was
visually inspected. Verification used macOS host Electron GUI support with
temporary player-data directories closed and removed by the tests. Actual saves,
save schema, source assets, credentials and server configuration were not changed.
Windows verification remains for CI after publishing; HTTPS remains separate.

## 2026-09-28 15:00 JST — Task 3.3 Normal card displays

- `npm run typecheck`: passed.
- `npm test`: 32 unit and 13 integration tests passed, none failed or skipped.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/cards npm run test:ui`: 10 passed,
  none failed or skipped.
- Coverage percentage: not measured; no coverage reporter is configured.

Red evidence: the new unit test failed because card presentation was missing.
After building the existing app, the new UI test timed out waiting for the absent
card box. An earlier UI attempt before the isolated worktree's first build timed
out launching Electron; that harness-preparation error was not used as feature
regression evidence. Its temporary data was removed by the test's finally block.

Checks cover Normal hands and grade labels, the reference 2:3 crop, nine owned
copies and nine empty deck slots, loaded compact/full images, a transient full
preview without save mutation, partial saved-deck restart, and panel containment
at exact FHD, 4:3 and portrait renderer sizes. Existing dialogue/save/UI regressions
remain unchanged. Three card screenshots in ignored `test-results/cards/` were
visually inspected. Source images were confirmed as 848x1264 and not modified.

Verification used macOS host Electron GUI support, temporary player-data
directories cleaned up after closing each app, and mocked credentials in existing
integration tests. No actual player saves, DB, network LFS fetch or server changes
were used. Windows execution remains for CI after publishing. HTTPS remains a
separate unresolved work item; the existing endpoint/authentication is unchanged.
No video/HTML player generated: the repository lacks `generate-player.ts`.

## 2026-09-28 14:32 JST — PR #22 macOS resolution re-verification

- `npm run typecheck`: passed.
- `npm test`: 30 unit and 13 integration tests passed, none failed or skipped.
- `npm run test:ui`: 9 passed, none failed or skipped.
- The constrained native viewport was 800x568; all three controlled viewports
  and the restored native viewport passed the fitting assertions.
- Verification used the macOS host GUI and temporary player-data directories
  cleaned up by the tests. No actual player saves or external services were used.
- Coverage percentage: not measured; no coverage reporter is configured.

Per the user's scope decision, HTTPS remediation is a separate work item and
remains unresolved; it is not a completion criterion for this macOS-only fix.
No LFS endpoint, credentials, CI workflow or server settings changed in this
resolution. GitHub macOS and Windows verification remains pending publication.

## 2026-09-28 14:19 JST — PR #22 macOS viewport regression resolution

- `npm run typecheck`: passed.
- `npm test`: 30 unit and 13 integration tests passed, none failed or skipped.
- `node --test tests/ui/story.test.mjs`: 2 passed.
- `JANKEN_UI_SCREENSHOT_DIR=test-results/story-viewport npm run test:ui`:
  9 passed, none failed or skipped.
- Coverage percentage: not measured; no coverage reporter is configured.

Red evidence: constraining the native Electron window to 800x600 and requesting
1920x1080 produced an actual content size of 800x568 on this macOS host. The
original exact-size wait failed after 30 seconds, reproducing the CI failure mode.
The corrected test verifies the actual constrained native viewport, then controls
renderer dimensions through CDP to verify exact FHD, 4:3 and portrait dimensions,
16:9 fitting and centered margins. It clears the override and verifies the native
viewport again. No layout expectations or timeouts were relaxed.

The three screenshots in the ignored `test-results/story-viewport/` directory
were visually inspected. Verification used macOS host Electron GUI support and
temporary player-data directories, removed after closing the apps. Actual player
saves, production application code and source images were unchanged. Execution
of this updated test on GitHub macOS and Windows runners remains pending.

The separate HTTPS finding is unresolved. Anonymous, certificate-validating
connection checks found an expired certificate on port 443 (expired May 17,
2026) and a TLS protocol error on port 8080. No credentials were sent during
these checks; no server settings, Secrets or LFS endpoint were changed. A valid
HTTPS LFS endpoint or separately authorized server configuration is required.

## 2026-09-28 13:51 JST — PR #22 Electron cold-install race resolution

- `npm run typecheck`: passed.
- `npm run test:unit`: 30 passed, 0 failed, 0 skipped.
- `npm run test:integration`: 13 passed, 0 failed, 0 skipped.
- `npm run test:ui`: 9 passed, 0 failed, 0 skipped.
- Real cold Electron install in an isolated temporary dependency directory,
  followed by the same UI runner: 9 passed, 0 failed, 0 skipped.
- Coverage percentage: not measured; no coverage reporter is configured.

Red regression evidence: two mock Electron consumers started their initial
installation in parallel, causing an `EEXIST` directory-creation error. The UI
runner now resolves Electron synchronously in its parent before starting workers.
Three regression checks verify one parent install, reuse on subsequent runs,
failure before workers start, and no Electron initialization for non-UI suites.
The nested-runner fixture removes `NODE_TEST_CONTEXT` so its child runs an actual
independent suite rather than inheriting the outer runner's worker context.

Verification ran on macOS for Electron GUI support. All test player-data and the
cold-install fixture were temporary and removed after use; existing Electron
dependencies and actual player saves were not changed. No application logic or
UI test expectations were changed. Windows verification of this code remains
for CI after publishing.

Separately, the existing local LFS credentials were validated against this
repository's batch API and used to update its two Actions Secrets without
displaying their values. CI run `36366999830`, attempt 2, then passed LFS image
fetch, typecheck and unit/integration tests on both platforms, but failed Windows
UI startup during concurrent Electron extraction; macOS UI was cancelled by
matrix fail-fast. This entry records the local fix for that newly exposed issue,
not a successful cross-platform CI result. HTTP transport remains unchanged.

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
