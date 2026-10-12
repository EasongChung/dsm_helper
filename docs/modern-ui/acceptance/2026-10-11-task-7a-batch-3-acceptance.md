# Task 7A Batch 3 — Modern File Browse / Breadcrumb / View Acceptance

> **Result: PASS — Batch 3 isolated automated Exit Gate (2026-10-12).**
>
> - Project: `qyxx2/dsm_helper`; DSM Helper Modern UI, Task 7A **Batch 3 only**
> - Working branch: `feature/t7a-file-browse`
> - Batch 3 base: `155d8e03e236da1727fc7a7a2882e85fc4a61459` (Batch 2 acceptance)
> - **CI-verified implementation HEAD: `1f501609f79564439f368e779a1224c40240c50b`**
> - This acceptance is a **docs-only commit after** the verified implementation HEAD; its commit SHA is not a separately tested code SHA.

## 1. Contract and scope audit

| Contract / plan | Implementation and verified evidence | Deferred / limitation |
| --- | --- | --- |
| `T7A-VIEW-01` | `FileBrowsePage` and `FileBrowseRow` render DSM shared roots and folders as compact Material 3 list/grid, read-only file rows, two-line titles and nullable size/time metadata; no per-file `Card`/permanent checkbox. Widget tests exercise Unicode, null metadata, dark mode and text scale 1.6. | No preview/remote thumbnail or file operation; real handset visual QA remains for B5. |
| `T7A-VIEW-02`, `G-PREF-01` | `SpUtilFileBrowsePreferencesStore` exclusively uses `file_list_type`, `file_sort_by`, `file_sort_direction`; legacy `ListType`, `SortByEnum`, `SortDirectionEnum`, name/ASC/list defaults, corrupt-value fallback and failed-write error. View toggling preserves loaded items; sort UI changes controller ordering through the inherited B2 generation mechanism. | Preference unit tests and controller tests verify persistence/sort semantics; no real DSM sort behavior is claimed. |
| `T7A-PATH-01` | `FileBrowseBreadcrumb` projects visited `FileBrowseAncestor` values; no path splitting or reconstructed `scheme://` ancestor. Current directory is nonclickable; tapping an ancestor pops to its existing route rather than pushing duplicates. | Ancestors depend on route-verified entries supplied by this page; no manually typed path navigation. |
| `T7A-PATH-02`, `G-NAV-01/02` | Directory taps push `MaterialPageRoute` under `Navigator.of(context)`, child names `t7a-folder:<exact DSM path>`. A B2 `FileBrowseController` belongs to each page and is disposed on pop. Parent `onLeaveDirectory()` invalidates old requests but retains its completed snapshot; widget test checks root→share→nested, ancestor pop, Android Back and nonzero preserved parent scroll. | B4 adds selection clearing/order; B5 mounts the root via Files-tab Navigator and assigns the `t7a-file-root` host route name. Test-mounted root is `MaterialApp.home`. |
| `T7A-DATA-03/05`, `T7A-STATE-01` | UI drives existing B2 paging only at scroll end or `加载更多`; it shows initial loading, true empty, offline/retry, refresh/stale and incomplete conditions from B2 states, without a false successful empty response. Widget tests verify root/empty/offline/Retry, paging trigger and request coalescing; B2 controller tests cover stale/partial/119 and generation ordering. | Specific permission/119 and stale cases are primarily controller-level, not each duplicated as B3 widget tests. |
| `T7A-SHELL-01`, `G-FILE-01` | No production Shell/Files-tab wiring, selection gesture, file open, preview, write/delete/upload or new DSM API. File rows are deliberately non-actionable. | Isolated page is test-mounted only. B4 selection; B5 preview entry; Task 7B/7C operations and preview. |

The implementation does not allocate a second DSM session/client, infer a path from display text, or replace the existing File Station entry.

## 2. TDD evidence from actual GitHub Actions

| Stage | SHA | CI run / observation |
| --- | --- | --- |
| 3.1 RED | `163787f52cbbed94fb1cc5c70401301507de155a` | **#314** (`38140255312`), expected compilation failure: missing `file_browse_preferences.dart`. |
| 3.1 GREEN | `fed949c3ba1e2d9b9206a54e4dbc1b8480d978d6` | **#315** (`38140575480`), success; 344 tests and clean analyzer; APK/signing verified. |
| 3.2 RED | `41e566902143f7c6e5c3705aa0d6a7561ff32285` | **#316** (`38156116649`), expected missing `file_browse_page.dart`, 344 existing tests passed. |
| 3.2 GREEN (initial) | `49fc72adb52e014368b2b3d73b396c537ca0c421` | **#317** (`38156416083`), 348 tests passed; analyzer rejected a redundant import in a new test. |
| 3.2 GREEN (final) | `038c4f452a78d090b78975204db63129ddf76b75` | **#318** (`38159812159`), success; 348 tests, clean analyzer, APK/signature checks passed. |
| 3.3 RED | `d89e46117d224e0031303a67d78b6fcfd9648080` | **#319** (`38160961740`), expected missing `file_browse_breadcrumb.dart`, 348 existing tests passed. |
| 3.3 GREEN (initial) | `d2e8a596eb354df2ae0c6cb57c1e8faed4619421` | **#320** (`38161168850`), 351 tests passed and 1 widget test failed because a hard-coded, lazily built list item was not yet visible. |
| **3.3 GREEN / B3 final gate** | **`1f501609f79564439f368e779a1224c40240c50b`** | **#321** (`38161348386`), `completed / success`. Test now scrolls to actual rendered item; **352 passed**, analyzer clean, APK/signature/artifact PASS. |

Intermediate corrective commits did not change the contract scope. All failures above are recorded as failures; none is relabeled as a passing Gate.

## 3. Final automated gate at exact code SHA

- **Workflow:** Modern UI Android CI, run **#321** (`38161348386`), job `114534737622`; workflow head/checkout SHA `1f501609f79564439f368e779a1224c40240c50b`.
- **Result:** `completed / success`; all required steps including testing, analysis, APK, signing and upload succeeded.
- **`flutter test`: 352 passed, 0 failed**, including 4 B3 preference tests, 6 B3 page tests and 2 B3 breadcrumb tests, alongside inherited B1/B2/file and full-project tests.
- **`flutter analyze lib/new_ui test/new_ui`: `No issues found!`**, broader than the B3-only target.
- **APK:** `flutter build apk --debug --flavor beta` → `build/app/outputs/flutter-apk/app-beta-debug.apk`.
- **Package ID:** `top.apaipai.dsm_helper`.
- **Stable development certificate SHA-256:** `0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2`.
- **Artifact:** `dsm-helper-modern-ui-android-debug`, artifact ID **`11710563026`**, **190,139,220 bytes**; ZIP digest `sha256:6e4cba160fbeb347b24655bd484a14ecabcbd4ec980d4fde5606a12b07062eb1`. The artifact belongs to the same verified run/implementation SHA.
- **Run:** https://github.com/qyxx2/dsm_helper/actions/runs/38161348386
- **Artifact:** https://github.com/qyxx2/dsm_helper/actions/runs/38161348386/artifacts/11710563026

The narrower standalone commands `flutter test test/new_ui/files -r expanded` and `flutter analyze lib/new_ui/files test/new_ui/files` were **not executed locally**: the execution environment lacks Flutter/Dart. CI ran the actual full test suite and a broader analyzer at the exact HEAD. No fabricated local test run or real NAS/device validation is reported.

## 4. Remote scope/diff audit

Comparing B3 base `155d8e03e236da1727fc7a7a2882e85fc4a61459` with verified implementation SHA `1f501609f79564439f368e779a1224c40240c50b`: **9 commits ahead, 0 behind; exactly 7 added files**:

1. `lib/new_ui/files/file_browse_breadcrumb.dart`
2. `lib/new_ui/files/file_browse_page.dart`
3. `lib/new_ui/files/file_browse_preferences.dart`
4. `lib/new_ui/files/file_browse_row.dart`
5. `test/new_ui/files/file_browse_breadcrumb_test.dart`
6. `test/new_ui/files/file_browse_page_test.dart`
7. `test/new_ui/files/file_browse_preferences_test.dart`

All fall within the Batch 3 plan; no pre-existing legacy, Shell, session, Android build configuration, CI workflow, API adapter/controller or other Task file was changed. One intermediate tree-construction commit was corrected immediately before any GREEN validation; the final tree and remote compare retain the complete original repository.

## 5. Acceptance result and next boundary

**PASS — Task 7A Batch 3 isolated automated Exit Gate**, based on CI #321 at SHA `1f501609f79564439f368e779a1224c40240c50b`. The supported evidence is read-only test-mounted browsing, list/grid, old preferences, folder paths, breadcrumbs and Back.

**No real DSM/NAS, handset visual or device acceptance was performed.** Batch 3 requires no independent device gate. No production preview entry is present; shipped Files tab remains unchanged. **STOP before Batch 4**; selection is separately scoped to B4 and integration to B5. No PR or merge is part of this acceptance.
