# Test results

## 2026-09-29 — Guild home prerequisite (local verification complete)

- Scope: existing Stage1 guild background/menu, confirmation-only navigation from tutorial/normal end, persistent home/return checkpoint, and existing card viewing/next-battle editing. Belka, quests, town, real story progression and other guild features remain unmigrated. No Godot/credentials/HTTPS changes.
- RED: guild unit test failed MODULE_NOT_FOUND before implementation. On authorized continuation, added non-overlap assertions reproduced the layout defect at 1920x1080 from both confirmation origins before the layout correction. Final macOS typecheck, 59 unit tests, 14 integration tests, all 22 UI tests and both game/editor smoke checks passed with no failures/skips. Coverage percentage not measured; Windows/CI not run.
- New isolated guild UI journeys both passed: entry/return atomic save failure safety, restart at home, title/continue, card-edit cancellation/failure/retry, unchanged historical records/inventory/money, disabled unmigrated menu and FHD/4:3/portrait letterboxing. Temporary player-data directories and Electron processes cleaned up.
- Initial full UI suite: 21 passed / 1 failed. The isolated-build fixture omitted the new guild background; single-test reproduction confirmed Vite's missing-asset error. After user authorization, the fixture now copies the background referenced by the home JSON. All original rebuild/editor-save/restart assertions are retained; the test passes.
- Initial visual verification found the default CardPanel top=884/bottom=auto overriding a CSS bottom adjustment and overlapping the menu. Corrected by supplying a guild-only JSON deck layout with y=800 to CardPanel and removing the ineffective CSS rule. Existing tutorial layouts/defaults are unchanged. The UI journeys assert deck bottom <= menu top at FHD, 4:3 and portrait viewport sizes; both pass. Updated FHD home/card screenshots were inspected and the complete deck is visible above the menu.
- Failure analysis was completed before the user authorized these two bounded corrections. No real saves or external services used; test temporary directories/processes cleaned up. Temporary dependency symlink removed after verification. Task4.2 remains unchecked; Belka is not implemented. Unstaged diff inspection OK; no staging, gate, commit, push or PR.

## 2026-09-29 — Task 4.2 first stage: HP engine and Matilda normal battle

- Scope: independent JSON normal-battle content and generic HP/probability/replay logic, saved prepared-deck snapshot, durable round confirmation/settlement, explicit retry after loss and return to representative dialogue. Other thirteen fixed chapters, three-card UI, transfers, full story/guild/minigames and Godot/CI/authentication/HTTPS changes are excluded; task4.2 stays unchecked.
- RED: `node --import tsx --test tests/unit/fixed-battle.test.ts` failed with MODULE_NOT_FOUND for the unimplemented fixed-battle module before production edits. Initial six cases then passed; eight new unit cases in the final suite cover snapshots, draws, HP, exhausted decks, terminal state, legacy saves, invalid ledgers, JSON validation and the actual Godot double grade-effect probability path.
- Final macOS verification passed: `npm run typecheck`; `npm test` (56 unit, 13 integration); `npm run test:ui` (20 UI); `npm run smoke:game`; `npm run smoke:editor`. No failures/skips. Smoke checks intentionally reject malformed IPC requests before both SMOKE_OK messages.
- Two new UI journeys use mkdtemp player-data directories, the completed tutorial and a reversed saved lineup. They verify the entry from tutorial end, independent battle snapshot, unchanged inventory/historical deck/tutorial, restart at every round result, write failure preservation/retry, cached reward after failed settlement, no repeat payout after restart, victory dialogue/end and defeat retry. A failed retry disables the competing return action until the same proposal succeeds.
- FHD screenshots viewed: `test-results/fixed-battle/win-selection.png`, `win-settled.png`; readable controls, settlement, full showdown cards and N badges. Normal deck panel is slightly taller with top-aligned cards so labels fit. Existing tutorial layout is unchanged. UI tests check loaded images before capture; other existing journeys/editor isolation also passed.
- Each Electron app and temporary save directory is cleaned in finally. Temporary dependency symlink removed after verification without deleting its target. Real saves and external services were not used. Screenshots/build outputs remain ignored. No video/player generator available; coverage percentage not measured. Windows execution awaits existing CI after publication. Review/gate outcomes are reported separately; no commit/push/PR creation in this workflow.

## 2026-09-29 — PR #27 pending-save regression resolved

- CardPanel disables lineup editing while StoryScreen saves a dialogue checkpoint; the editor-opening callback also checks the pending ref. Save schema, historical deck, domain logic, Godot assets, CI and authentication/HTTPS configuration are unchanged.
- The two delayed-save UI cases hold the real atomic save before rename, assert the disabled editor cannot open and the existing file remains intact, then cover success/failure recovery and subsequent lineup persistence without changing progress or the historical deck. The test-only filesystem wrapper is restored and each isolated Electron process and user-data directory is cleaned up.
- Corrected the test-only Electron evaluate callback to accept the supplied failure flag as its second argument. Expectations were not weakened. Both regressions reproduced the enabled-editor defect before the application correction and now pass.
- Passed on macOS: `npm run typecheck`, 48 unit tests, 13 integration tests, 18 UI tests, `npm run smoke:game`, `npm run smoke:editor`. Both smoke checks deliberately reject malformed IPC requests and then print SMOKE_OK.
- Temporary dependency symlink removed after verification. Windows execution for this revision awaits publication/CI; coverage percentage not measured. No real saves, external services, commits or pushes used. Final review and gate are reported separately by the workflow.

## 2026-09-29 15:45 JST — PR #27 pending-save fix verification stopped

- Replaced unsupported main-process `require` with `process.getBuiltinModule`. Both delayed-save regression cases then failed at the expected assertion: editor entry was enabled while the actual atomic save was held. This reproduced the reported defect before application changes.
- CardPanel now accepts an edit-disabled flag; StoryScreen passes its saving state and guards editor opening with the pending ref. No save format, filesystem store, authentication or HTTPS settings changed.
- Typecheck, unit and integration suites passed. Full UI suite: 17/18 passed. The new successful-save case failed with checkpoint `matilda.start` rather than `matilda.items.box`; the failed-save case and all existing UI cases passed. Smoke commands were not reached after UI failure.
- Root cause: ElectronApplication.evaluate supplies the Electron module as its callback's first argument, with user input second. The release callback incorrectly used its first argument as the failure flag, so it injected failure in the success case as well. Proposed correction: accept `(_electron, fail)` in that callback, retaining the current assertions.
- Stopped without a consecutive correction. Temporary test data/processes cleaned and dependency symlink removed. Review and gate remain pending; Windows verification and coverage measurement not performed in this run.

## 2026-09-29 15:41 JST — PR #27 pending-save regression test setup failure

- Added two UI regression scenarios for delayed dialogue saves: editor entry must be disabled until success/failure settles, then lineup saving must preserve the resulting checkpoint and historical deck.
- Command: `node --test --test-name-pattern='dialogue save blocks' tests/ui/deck-editing.test.mjs`. Both scenarios failed in setup with `electronApplication.evaluate: ReferenceError: require is not defined` before the pending-save assertions ran. This is a test setup failure, not reproduction evidence for the application defect.
- Proposed next correction: load the filesystem promises module using an ESM-compatible import inside the main-process evaluation. No application changes or consecutive test corrections were made after this failure.
- Electron processes closed and temporary test save directories removed in finally; temporary dependency symlink removed. No real saves, authentication/HTTPS configuration, commits or pushes changed. Full verification, diff review and gate remain pending; coverage not measured.

## 2026-09-29 — Task 4.1 CI image selection correction

- Expanded only the existing LFS `--include` selection to all 15 hand/grade card images. Previous background and portrait selections remain. Authentication helper, Secrets environment, credential options and endpoint/HTTPS configuration are unchanged.
- Strengthened the existing integration test to require all fifteen exact card paths and reject extra card selections. Existing authentication isolation checks remain.
- Passed on macOS: typecheck, 48 unit tests, 13 integration tests, 16 UI tests, game/editor smoke checks. Smoke logs include deliberately rejected malformed IPC payloads before both SMOKE_OK messages.
- Existing Matilda journey, editor isolation and historical battle protection checks passed. Test saves were temporary and removed. FHD screenshot remains in ignored test-results/cards/deck-editor.png.
- GitHub Windows/macOS CI and actual remote LFS retrieval will run after publication, not in this local verification. Coverage percentage is not measured.
- Task4.1 implementation/local verification is complete; final review and gate are recorded by the workflow. No commit/push/PR creation in resolve.

## 2026-09-29 — Task 4.1 fixture correction and local verification

- Fixed only the invalid UI fixture: inventory now owns every copy in its recorded battle deck; battle ID comes from the real JSON. UI counts reflect the corrected inventory. Save validation and record-preservation expectations are unchanged.
- Passed: `npm run typecheck`, 48 unit tests, 13 integration tests, 16 UI tests, `npm run smoke:game`, `npm run smoke:editor`.
- Edited lineup persists through restart; cancel/read do not write the save; failed save retains its draft and previous file for retry. Inventory, money, historical battle deck and progress remain unchanged.
- Viewed `test-results/cards/deck-editor.png` at FHD: all grades and selected lineup labels visible, status and actions readable. Disabled inventory cards are dimmed; scrollable inventory includes the extra Normal copies.
- Isolated mkdtemp user-data removed in finally. No real saves or external services used. Existing dependency symlink is removed after verification; generated dist/screenshots remain ignored.
- Windows execution and coverage percentage are not measured locally. No video/HTML player generator is available.
- Remaining: CI LFS fetch includes only Normal images while the new UI requires every grade. CI change is awaiting permission and is not applied. Final review/gate and task4.1 completion remain pending.

## 2026-09-29 14:27 JST — Task 4.1 verification stopped

- Branch: `feature/electron-card-management`, based on develop `03f2487`.
- RED: new deck-editing test failed because its domain module did not exist.
- After implementation: typecheck passed; 48 unit and 13 integration tests passed.
- UI: 15 passed, 1 failed. All existing tests passed. New editing test could not Continue from its fixture.
- Diagnostic: fixture owns one Normal per hand but its recorded deck uses three per hand; parseSave rejects it with `Save deck contains cards not owned by the player`.
- A separate diagnostic with sufficient inventory exposes its incorrect battle ID (`matilda.practice` instead of `battle.matilda.practice`), rejected with `Invalid tutorial progress`.
- Correct only the fixture, not save validation or expected ownership/record preservation. No consecutive correction applied in this run.
- Editing UI, all-grade image rendering, failed-save recovery and edited-lineup restart remain unverified; no new screenshot was produced.
- CI currently fetches Normal images only. Expanding its LFS image selection is awaiting permission; credentials and HTTPS are out of scope.
- UI used isolated mkdtemp saves and finally cleanup. No real user saves, external API or database used. Existing dependencies temporarily linked. Windows and coverage percentage not measured.
- Review, staging, gate and task-list updates not completed. No commit or push.

## 2026-09-28 — PR #26 Windows isolated-build path correction

- Failure evidence: Windows job `109240419679`, run `36516678634`, passed
  45 unit/13 integration tests but failed the new layout-reflection UI test
  (14 UI passed, 1 failed). Vite rejected an HTML output name containing
  `../../.../runneradmin/AppData/Local/Temp/...`; rebuilt game startup was not
  reached and the later Windows smoke steps were skipped.
- Correction: canonicalize the created temporary project with `realpath`
  before deriving copy, editor, build and game paths. Keep the original
  temporary-directory handle for cleanup even if canonicalization fails.
  Add a canonical renderer-directory assertion; existing save/reflection
  assertions and isolation are unchanged.
- Local macOS also exposes an alias: `tmpdir()` uses `/var/folders/...`,
  while its real path uses `/private/var/folders/...`. The corrected test
  successfully builds and launches the canonical isolated project twice.
- `npm run typecheck`: passed.
- `npm test`: 45 unit and 13 integration tests passed, no failures/skips.
- `npm run test:ui`: 15 passed, no failures/skips, including layout reflection.
- `npm run smoke:game` / `npm run smoke:editor`: both `SMOKE_OK`.
- Windows short-name/root mismatch remains the likely diagnosis, not a claim
  of successful Windows execution. Publish the correction and confirm the
  existing Windows/macOS CI before treating PR #26 as merge-ready.
- Prevention: strengthened regression check for canonical renderer roots.
  No separate review lesson is needed; the guard is linked directly to the test.

Electron checks ran on host macOS with isolated project/player-data directories
removed in finally. The temporary dependency link was removed without deleting
its target. No real saves, source JSON, Godot/assets, dependencies, CI settings,
credentials or PR state changed. Coverage percentage remains unmeasured.

## 2026-09-28 — Task 3.6 Matilda journey verification

- Red: `node --import tsx --test tests/unit/matilda-journey.test.ts` failed
  because the new shared save-invariant helper did not exist. This was test-tool
  implementation evidence, not a reproduced application defect.
- Green: the helper contract and real-content journey both passed (2 tests).
- `npm run typecheck`: passed.
- `npm test`: 45 unit and 13 integration tests passed, no failures/skips.
- `npm run test:ui`: 15 passed, no failures/skips, including the unseeded full
  tutorial, restart at dialogue/preparation/selection/results/completion/end,
  and editor save -> copied game rebuild -> new game/Continue reflection.
- `npm run smoke:game` / `npm run smoke:editor`: both `SMOKE_OK`.
  Rejected null IPC probes intentionally log errors.
- FHD introduction, grades, preparation, result and closing images generated
  under ignored `test-results/matilda/`; inspected alongside the Godot reference.
  Background/panel/portrait/dialogue differences and clipped card captions are
  recorded in `docs/plans/electron-rebuild-verification.md`, not silently approved.
- Windows remains unexecuted locally; the existing two-OS CI discovers these
  tests automatically after publication. Coverage percentage is not measured.

Host macOS was used for Electron GUI checks. Temporary project/player-data
directories were removed in finally, without changing real saves, original
content/assets, Godot, credentials, services, dependencies or CI settings.
No application implementation or existing test expectations changed.
Task 3.5 is marked complete because PR #25 was merged. Task 3.6 remains unchecked
pending final review/publication; this is not a full Godot-parity approval.

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
