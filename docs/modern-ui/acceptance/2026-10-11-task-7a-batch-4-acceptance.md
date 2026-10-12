# Task 7A Batch 4 — Selection Identity, Gestures and Reconciliation Acceptance

> **Result: PASS — Batch 4 isolated automated Exit Gate (2026-10-12).**
>
> - Repository: `qyxx2/dsm_helper`; working branch: `feature/t7a-file-browse`
> - Batch 4 base: `1676530b6d6a3a4f88e6303a9a24aca2dc458fc3` (Batch 3 acceptance)
> - **CI-verified code HEAD: `4e6e25dccc77435a76889e0a8313e3379c7a0b23`**
> - Final full CI: **#329**, run ID `38222916639`, `completed / success`
> - This file is a **documentation-only acceptance record after** the CI-verified code SHA. Its own commit does not claim a new code validation.

## 1. Scope, contracts and behavior

| Authority | Verified implementation and evidence | Limits |
| --- | --- | --- |
| `T7A-SEL-01`, `G-FILE-01` | `FileBrowseRow` handles horizontal swipe for an ordinary folder/file list row or grid tile. The route-local controller starts selection keyed by the exact, nonempty `FileItem.path`; in selection mode item taps toggle rather than navigate. Shared-root swipe cannot select; normal share-root and ordinary-folder taps still navigate. Added list/grid/root Widget tests and explicit selected-grid-folder test. | No file open, mutation, transfer, or selection-action dispatcher; no long-press action invented. |
| `T7A-SEL-02` | `FileBrowseController` exposes `isSelectionMode`, immutable `selectedPaths`, `selectPath`, `togglePath`, `selectLoaded`, `clearSelection`. Selection uses exact paths instead of row object identity, display name or list index. Unit tests cover duplicate names, rebuilt files and sorting; Widget test covers list→grid continuity. Selected list row has `selectedTileColor`; selected grid tile has a persistent `Material` surface using `secondaryContainer`, with no checkbox gutter. | Sort continuity was asserted at controller level, not on a separate live NAS. |
| `T7A-SEL-03`, `T7A-STATE-01` | Reconciliation removes missing selected paths **only when the latest fully validated fresh page generation is complete**. Partial/failed refresh and failed second sort page leave the prior completed listing and selection intact. Selection state does not leak across separately instantiated account/context controllers. | Tests are fake-DSM/controller tests; offline live NAS was not used. |
| `T7A-SEL-04` | Selection App Bar shows `已选择 N 项`, explicit exit and either `已加载项全选` (pagination incomplete) or `全选` (complete). Test of 251 entries, including one null path, verifies first 100 selected, next 100 **not** auto-selected, final count 250 eligible; Widget test verifies labels, count, and exit. | Header does not offer dead file-operation buttons. |
| `T7A-PATH-02`, `G-NAV-01/02/03` | `PopScope` consumes selection Back before directory Back; `onLeaveDirectory` clears selection and invalidates requests while retaining the completed parent snapshot. New page tests cover Back inside nested directory, view toggling, root navigation. | Existing production Files tab and its legacy handoff were not changed. The full tab-stack/context-switch relationship and real-device Gate belong to B5. |

Selection is directory-route/context-scoped and read-only. `FileBrowseState` remains the existing immutable pagination snapshot; the small selection set is kept in the existing route-owned `FileBrowseController`, so no redundant selection state model/provider was introduced. Unit tests were added to `file_browse_selection_test.dart`; existing `file_browse_controller_test.dart` remained unchanged because the new focused suite exercises the same controller API.

## 2. Actual RED → GREEN / corrective evidence

| Stage | Commit SHA | Observed GitHub Actions evidence |
| --- | --- | --- |
| 4.1 RED | `f4ae53b659546997814ffac1cd99de2591b29173` | [#322](https://github.com/qyxx2/dsm_helper/actions/runs/38206644776): **352 passed, 4 failed**, expected `NoSuchMethodError` for absent `selectPath()`. |
| 4.1 GREEN | `b340bc16940c6b5d6f3727d9af01f39bde66612d` | [#323](https://github.com/qyxx2/dsm_helper/actions/runs/38209755551): **356 passed**, analyzer clean, APK/signing/upload passed. |
| 4.2 RED | `7d3ae7388f675df670a1f6de47a65970e3ea973d` | [#324](https://github.com/qyxx2/dsm_helper/actions/runs/38210791425): **356 passed, 3 failed**, missing swipe/selection widget behavior. |
| 4.2 GREEN (initial) | `b5f36ddd8f584fe19244a8221e98a3a12265210c` | [#325](https://github.com/qyxx2/dsm_helper/actions/runs/38211339618): **359 passed**, analyzer failed on deprecated `MaterialStatePropertyAll`; no APK claim for this run. |
| 4.2 GREEN (final) | `c2d2a1b7d196a773295187b0993681d5d84b0b46` | [#326](https://github.com/qyxx2/dsm_helper/actions/runs/38214959445): **359 passed**, analyzer clean, APK/signing/upload passed. |
| 4.3 added paged-all tests | `d714cbcd880d76a6657c585f55969116686fa047` | [#327](https://github.com/qyxx2/dsm_helper/actions/runs/38216774743): **362 passed**, analyzer clean, APK/signing/upload passed. **The new tests passed immediately:** existing `selectLoaded`/paging implementation already met these cases. Thus this stage has no fabricated failing RED run or gratuitous GREEN production change. |
| B4 grid highlight follow-up RED | `f5f76e84027e16fecee71c840b5e9390613e4f80` | [#328](https://github.com/qyxx2/dsm_helper/actions/runs/38218433847): **362 passed, 1 failed**: selected grid tile lacked persistent `Material` tonal surface. |
| **B4 final GREEN / Exit Gate** | **`4e6e25dccc77435a76889e0a8313e3379c7a0b23`** | [**#329**](https://github.com/qyxx2/dsm_helper/actions/runs/38222916639): **363 passed, 0 failed**; clean analyzer, APK/build/signing/upload all passed. |

The RED failures above were confirmed from actual job logs rather than inferred from workflow status.

## 3. Final automated, build and distribution checks

CI #329 ran against the precise final implementation SHA:

- `flutter test` → **363 tests passed, 0 failed**, including all B1–B4 File Browse tests and the broader existing test suite.
- `flutter analyze lib/new_ui test/new_ui` → **`No issues found!`**, 18.2 seconds. This covers a superset of the required B4 targeted analyzer.
- `flutter build apk --debug --flavor beta` → **PASS**, produced `build/app/outputs/flutter-apk/app-beta-debug.apk`.
- Verified installed package identity: `top.apaipai.dsm_helper`.
- Verified retained development certificate SHA-256: `0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2`.
- Successfully uploaded `dsm-helper-modern-ui-android-debug`, artifact **ID `11735023330`** (approximately 190 MB), [CI artifact link](https://github.com/qyxx2/dsm_helper/actions/runs/38222916639/artifacts/11735023330).
- Workflow CI was used because this execution environment cannot run Flutter/Dart locally. **Standalone** `flutter test test/new_ui/files -r expanded` and `flutter analyze lib/new_ui/files test/new_ui/files` were **not run as distinct commands**; full-suite tests and broader analysis at the exact code SHA passed instead.

## 4. Remote Git boundary audit

GitHub compare `1676530b6d6a3a4f88e6303a9a24aca2dc458fc3...4e6e25dccc77435a76889e0a8313e3379c7a0b23`: **8 commits ahead, 0 behind; exactly six changed files**.

1. `lib/new_ui/files/file_browse_controller.dart`
2. `lib/new_ui/files/file_browse_page.dart`
3. `lib/new_ui/files/file_browse_row.dart`
4. `lib/new_ui/files/file_browse_selection_bar.dart` (new)
5. `test/new_ui/files/file_browse_selection_test.dart` (new)
6. `test/new_ui/files/file_browse_page_test.dart`

No modifications to legacy File Station, DSM models/API/session, Shell/Files destination, Android build configuration, CI or unrelated Task files. The optional plan touchpoints `file_browse_state.dart` and `file_browse_controller_test.dart` were not changed because immutable listing state needed no schema changes and controller cases were covered in the new focused selection tests.

## 5. Acceptance and next boundary

**PASS — Task 7A Batch 4 isolated automated Exit Gate**, substantiated by CI **#329** at `4e6e25dccc77435a76889e0a8313e3379c7a0b23`. This result covers the read-only selection identity, gestures, presentation, full-refresh reconciliation, paged select-loaded counts and Back priority within an isolated test-mounted browse page.

**NOT TESTED:** real NAS/DSM behavior, real Android gesture/visual testing, physical APK cover installation, and full Files-tab preview integration/context switch. No real-device testing was required by the B4-specific Gate; B5 requires separate opt-in preview wiring, relationship tests and physical validation.

**STOP after Batch 4.** Do not automatically implement Batch 5, replace the production Files destination, create PR, merge into `modern-ui`, or declare Task 7A complete. A docs-only acceptance commit does not require another APK CI under `CI-DOCS-01`.
