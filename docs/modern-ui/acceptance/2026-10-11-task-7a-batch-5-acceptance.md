# Task 7A Batch 5 — Opt-in Browse Integration / Real-Device Acceptance

> **Result: PASS — user-approved Task 7A/B5 scoped Exit Gate (2026-10-12).**
>
> - Repository: `qyxx2/dsm_helper`; branch: `feature/t7a-file-browse`.
> - B5 start: `eccf21fcc7abdf0c462316e528172d75070a4435` (B4 documentation acceptance).
> - **Final B5 feature-code SHA: `255a01b600352bc8eecb0d3ca76fbf353707cfa3`.**
> - **CI #337**, run `38230645699`: `completed / success` against precisely that SHA.
> - The user's real Android/DSM functional feedback: **“功能测试没有问题”**, followed by the explicit B5 acceptance decision **“先验收掉B5吧。通过”**.
> - Acceptance is for the **isolated, optional, read-only Modern browse foundation**, not a complete replacement File Station, not a guarantee of smooth/120 FPS scrolling, and not a merge authorization.

## 1. Scope and final behavior

`NewUiPrimaryPage` exposes `onOpenBrowsePreview` only when supplied by Files; the original `打开现有功能` button remains the primary, fully capable legacy route. `NewUiAppShell` uses `browsePreviewBuilder` to push onto the existing **Files-tab Navigator**; the Files destination in `DsmNewUiShell` supplies the active `contextId`, notification callback and `onReauthNeeded`, without making the incomplete Modern page the primary tab root or introducing a new session authority.

The isolated browser supports verified DSM shares and exact returned folder paths, breadcrumb/ancestor and Android Back, incremental pages of 100, list/grid, sort/view persistence, route-scoped path-based selection, select-loaded, incomplete/stale/offline/119 treatment and context switch isolation. Normal legacy file operations and external intents remain unchanged. Task 7B/7C functions are **not implemented here**.

The user-requested B5 corrective follow-up at the final SHA additionally:
- Replaces animated child-folder `MaterialPageRoute` with zero-duration `PageRouteBuilder` for immediate child-directory entry/return; the preview-entry route itself is unchanged.
- Disables sorting `PopupMenuButton` open/close animation in this browser only.
- Removes visible `加载更多` footer/button; **scroll-near-end** continues incrementally requesting subsequent pages; failure state retry remains available.
- Reuses a single selected-path snapshot per widget rebuild rather than repeatedly constructing an unmodifiable set per built row.

These are specific low-risk changes. **No measured 60/90/120 Hz or rendering frame-time result is claimed.**

## 2. Contract-by-contract executable evidence

| Contract | Verification in current source / CI #337 |
| --- | --- |
| `T7A-DATA-01` | `test/new_ui/files/file_browse_data_source_test.dart`, `file_browse_page_test.dart`: share-root read, empty/error distinction and active adapter. |
| `T7A-DATA-02` | `file_browse_page_test.dart`, `file_browse_path_test.dart`: exact returned folder path and nested read; invalid paths rejected. |
| `T7A-DATA-03` | `file_browse_controller_test.dart`, `file_browse_page_test.dart`: 0/100/101/250+ paging, scrolling offsets, dedup/termination; **no visible Load More button**. |
| `T7A-DATA-04` | `file_browse_data_source_test.dart`, `file_browse_page_model_test.dart`, `file_browse_page_test.dart`: malformed vs valid empty and nullable metadata. |
| `T7A-DATA-05` | `file_browse_controller_test.dart`: last-complete snapshot, failed refresh and partial-page behavior. |
| `T7A-DATA-06` | `file_browse_controller_test.dart`, `task7a_files_preview_relationship_test.dart`: request generations, late results, context A→B remount. |
| `T7A-PATH-01` | `file_browse_breadcrumb_test.dart`, `file_browse_path_test.dart`, `file_browse_page_test.dart`: verified ancestry and breadcrumb jumps. |
| `T7A-PATH-02` | `file_browse_page_test.dart`, `task7a_files_preview_relationship_test.dart`: Back, tab stack, parent snapshot/scroll, immediate child routes. |
| `T7A-VIEW-01` | `file_browse_page_test.dart`, `file_browse_row.dart`: list/grid, Unicode/large text, light/dark, file/folder/icon/selection presentation. |
| `T7A-VIEW-02` | `file_browse_preferences_test.dart`, `file_browse_page_test.dart`: existing SpUtil keys, sort direction and view persistence. |
| `T7A-SEL-01` | `file_browse_selection_test.dart`, `file_browse_page_test.dart`: list/grid horizontal swipe, exact-path selection, root excluded. |
| `T7A-SEL-02` | Same tests: selection survives model replacement, sort and view mode change. |
| `T7A-SEL-03` | `file_browse_selection_test.dart`: completed replacement prunes, failed/incomplete does not. |
| `T7A-SEL-04` | `file_browse_selection_test.dart`, `file_browse_page_test.dart`: count/select-loaded, 100→250 without unseen auto-selection, Back exit. |
| `T7A-STATE-01` | `file_browse_controller_test.dart`, `task7a_files_preview_relationship_test.dart`: initial/empty, stale, offline, Dio timeout and DSM 119 one-shot callback. |
| `T7A-SHELL-01` | `task7a_files_preview_relationship_test.dart`, `new_ui_primary_page_test.dart`, existing Task 6 shell and legacy nested-navigation tests: Files-only opt-in preview, primary legacy path, notifications/Back. |
| `T7A-SHELL-02` | `task7a_files_preview_relationship_test.dart`: keyed account remount discards old path/selection/in-flight A completion and opens Overview. |
| `T7A-CUTOVER-01` | Remote diff audit plus relation/source tests: no new full file-operation UI or default Files replacement; 7B/7C deferred. |

The CI runs **`flutter test` (complete suite)** and **`flutter analyze lib/new_ui test/new_ui`**. The plan's separate, more granular test commands were **not run as distinct commands** in this environment without local Flutter; successful full CI covers their included test files.

## 3. RED→GREEN history and final automation Gate

| Run / source commit | Real result |
| --- | --- |
| #330 / `5475c538` | 360 passed, 2 failed **due to test compilation errors**; not counted as a valid behavior RED. |
| #331 / `beb4196f` | 363 passed, 2 failed, expected **runtime `NoSuchMethodError`** on the missing preview callback/constructor argument: valid B5.1 RED. |
| #332 / `9269f815` | 365 passed; analyzer, beta Debug APK, package/signature and artifact PASS: B5.1 GREEN. |
| #333 / `fe427105` | Test-fixture compilation issue (incorrect `await` on a void lifecycle method), not a production behavior regression. |
| #334 / `30e36c55` | 369 passed; analyzer/build/signature/upload PASS: B5 shell/error/context relationship GREEN. |
| #335 / `657e2c63` | Animation tests failed (one test also advanced before asynchronous data loaded); test setup was corrected. |
| #336 / `645699a6` | 367 passed, 4 **expected behavioral failures**: animated folder route, animated sort menu and still-visible Load More footer. |
| **#337 / `255a01b600352bc8eecb0d3ca76fbf353707cfa3`** | **371 tests passed, 0 failed**; `flutter analyze lib/new_ui test/new_ui` **No issues found**; `flutter build apk --debug --flavor beta` PASS; Android package/signature checked; Artifact uploaded. |

**Final B5 APK:** [CI #337](https://github.com/qyxx2/dsm_helper/actions/runs/38230645699) — artifact `11738991587`, `dsm-helper-modern-ui-android-debug`, approximately 190 MB (GitHub uploaded artifact ZIP), artifact [link](https://github.com/qyxx2/dsm_helper/actions/runs/38230645699/artifacts/11738991587).

- Android package: **`top.apaipai.dsm_helper`**.
- Fixed developer certificate SHA-256: **`0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2`**.
- Version from `pubspec.yaml`: `0.1.2+152`.
- CI #337 corresponds exactly to final feature-code SHA above. Its **automated checks do not independently establish a physical overlay-install or frame-rate result**.

## 4. Real Android / DSM report and limits

The user reported that **functional testing had no issues** on their actual device/DSM, then requested removal of zooming directory transitions, faster sort-menu animation, no `加载更多` text/button and higher scrolling smoothness. The corrections were implemented, covered by #337 tests/build/signature, and the user **explicitly accepted B5 as PASS on 2026-10-12**.

**Observed/authorized as user report:** the tested B5 functional browser and legacy entry were acceptable; acceptance was explicitly authorized. This is **user-reported**, not a separate assistant-operated physical-device test.

**NOT independently documented as device-tested at the exact final #337 APK:** replacement/overlay install over the user's currently installed APK, all individual >100-folder/Unicode/scroll-selection/notification/offline/Back cases after the final animation and footer correction, real DSM 119 invalidation, real second-account isolation, optional remote-mount family. Their automated contract coverage is distinct from physical testing; the general user PASS must not be rewritten into individual measurements.

**Known nonblocking residual:** the user reported perceptibly low scrolling smoothness on the Debug build. A Release/AOT performance-comparison trial was made **on a separate, unmerged CI-only branch** `feature/t7a-b5-release-perf-trial` based on the exact B5 source SHA. Its only diff is `.github/workflows/android-ci.yml` (beta Release instead of beta Debug, separate artifact). [CI #338](https://github.com/qyxx2/dsm_helper/actions/runs/38232447755), source HEAD `2cfce83038d174e8e835e5b9bce6320c04ff9a07`, **371 tests passed, analyzer clean, Release build/signature/artifact PASS**; [Release comparison artifact `11739736244`](https://github.com/qyxx2/dsm_helper/actions/runs/38232447755/artifacts/11739736244), approximately 28.8 MB compressed artifact. Same beta package and fixed signature. **No actual Release-vs-Debug frame-time or real-device comparison has been reported.** CI #338 is evidence of an independent build experiment, not a replacement for the canonical #337 B5 code/CI record.

The user chose acceptance **with these performance and device-coverage limits**, without blocking progression to a later **separately authorized** task. Future cutover must not silently inherit unmeasured FPS or untested operation semantics.

## 5. Remote scope audit and handoff

Compare `eccf21fcc7abdf0c462316e528172d75070a4435...255a01b600352bc8eecb0d3ca76fbf353707cfa3`:

- **8 commits ahead / 0 behind, exactly 7 files**:
  - `lib/new_ui/app/dsm_new_ui_shell.dart`
  - `lib/new_ui/app/new_ui_app_shell.dart`
  - `lib/new_ui/shell/new_ui_primary_page.dart`
  - `lib/new_ui/files/file_browse_page.dart`
  - `test/new_ui/app/task7a_files_preview_relationship_test.dart` (new)
  - `test/new_ui/files/file_browse_page_test.dart`
  - `test/new_ui/shell/new_ui_primary_page_test.dart`
- Entire Task relative to `modern-ui@b80a59c61ca3baf07201478637deaa61a181c6a4`: **53 commits ahead, 0 behind; 32 touched files**, all within the reviewed Task 7A files/docs and backward-compatible DSM `FileStationList.dart` pagination seam. No Task 7B/7C implementation or unrelated source change.
- The separate Release performance-trial branch is **not** merged or brought into the Task 7A feature branch. Existing standard CI remains Debug.

**B5 / Task 7A Gate: PASS in the user's expressly accepted scope** — verified read-only Modern browse foundation behind a secondary opt-in; legacy complete-feature route preserved; complete automated tests/analyzer/debug APK/package/signature passed; user reported functioning on their device and expressly approved closure. Scrolling smoothness remains an **open performance follow-up** and must not be marked solved.

**Deferred handoff:** Task 7B owns search and real operations (copy/move/rename/delete/favorites/sharing). Task 7C owns transfers, media previews, integration/cutover. Nothing in this document authorizes starting 7B/7C, a PR or merging `feature/t7a-file-browse` into `modern-ui`.

**STOP after Batch 5.** This is a docs-only post-CI acceptance commit, not a new source-code CI run (`CI-DOCS-01`).
