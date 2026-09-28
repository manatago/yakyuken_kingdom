# Test results

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
