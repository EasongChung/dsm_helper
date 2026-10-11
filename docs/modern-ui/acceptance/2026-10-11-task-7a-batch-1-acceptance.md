# Task 7A Batch 1 — File Station Read Contract / Adapter Acceptance

> **Result: PASS — Batch 1 automated Exit Gate (2026-10-11).**
>
> - Task: DSM Helper Modern UI Task 7A — File Station Browse Foundation
> - Batch: **1 only** — Existing FileStation List Contract / Read Adapter
> - Work branch: `feature/t7a-file-browse`
> - Batch implementation base: `0e07e56335b872b4c3f482066da8e7eff8db0c2b`
> - **CI-verified implementation HEAD: `787e1de93694bbf4eb4c81e284232c7378087d4c`**
> - This file is the later documentation-only acceptance commit. It does **not** establish an independently tested new implementation HEAD.

## 1. Contract acceptance

| Contract | Batch 1 proof and boundary |
| --- | --- |
| `T7A-DATA-01` — share root | The production adapter calls existing `FileStationList.shareList` (`SYNO.FileStation.List`, quoted `"list_share"`, v2); `FileBrowseRequest.path == null` is the share root, not a synthesized folder. Valid `shares: []` maps to a legitimate empty list; missing arrays and propagated DSM errors do not. |
| `T7A-DATA-02` — folder read wire | A non-null, nonempty request path calls existing `FileStationList.fileList(path: ...)` (`SYNO.FileStation.List`, quoted `"list"`, v2). The original path, including Unicode/space and `scheme://` cases, reaches the injected loader/API unchanged. An empty-string path is rejected rather than guessed. Route navigation and late-request suppression are later Batches. |
| `T7A-DATA-03` — page-input portion only | Both legacy list calls have *optional named* `offset = 0` and `limit = 100`, preserving prior default request payloads. The adapter passes `offset/limit/sort` unchanged, validates requested bounds and checks returned offset, total and missing-total representation. Server page fetch at offset 100 is possible. Incremental fetch, terminal-page detection, deduplication and scroll orchestration remain **Batch 2**, not accepted here. |
| `T7A-DATA-04` — structural read semantics | Existing `shares`/`files` parser normalizes both into `FileStationList.files`; valid empty arrays remain empty; missing/null array, malformed row and invalid negative/noninteger/mismatched numeric metadata produce typed `FileBrowseDataException`. Nullable file metadata/path and distinct item paths sharing a name are preserved. `DsmException(119)`, other `DsmException` codes and Dio transport failures pass through without converting to empty success. |

The adapter owns neither HTTP/session/auth nor paging state: the existing `Api.dsm` and `FileStationList` remain authoritative. The model's existing `favoriteList`, `virtualFolder` and all mutation methods are unchanged. No `lib/pages/file/**`, shell, UI or transfer code was modified.

## 2. TDD chronology — verified remote commits

| Stage | Commit | GitHub Actions | Actual evidence |
| --- | --- | --- | --- |
| 1.1 RED | `e78086c036c6b044eae7b5a515690953a9d3c678` | **#302**, run `38119092805` | `completed / failure`: test cannot compile calls to `shareList/fileList(offset: ...)`, because named `offset` does not exist. This is the expected missing-input RED. |
| 1.1 GREEN | `427f84593909d9d0694c6f4ca77c2dfb6cac9ae8` | **#303**, run `38120243633` | `completed / success`: legacy request payload/default/quoted-sort assertions and full workflow passed. |
| 1.2 RED | `885b7e0282a04faa13eaf1fd4ca379a81e1759be` | **#304**, run `38121217481` | `completed / failure`: the two newly imported `file_browse_page_model.dart` / `file_browse_data_source.dart` files and their typed symbols did not yet exist. Expected missing-adapter RED. |
| 1.2 GREEN | **`787e1de93694bbf4eb4c81e284232c7378087d4c`** | **#305**, run `38121451189` | `completed / success`: all 13 Batch 1 tests present and passing (six page-model and seven data-source), complete repository tests and analyzer clean, debug APK built and uploaded. |

Tests were submitted **before** the respective production changes. The isolated commands named by the Batch Plan were *not* separately run because Flutter/Dart are unavailable in this executor environment; the CI's full `flutter test` and `flutter analyze lib/new_ui test/new_ui` are broader inclusive checks at the exact implementation SHA. No local Flutter run is claimed.

## 3. Final Gate — exact implementation HEAD

- **Workflow:** Modern UI Android CI — **#305**, run ID `38121451189`, job ID `114416858618`.
- **Checkout/implementation SHA:** `787e1de93694bbf4eb4c81e284232c7378087d4c`.
- **Result:** `completed / success`.
- **Flutter:** `3.22.3`.
- **Full `flutter test`: 319 passed, 0 failed**, including 13 focused `test/new_ui/files/` tests.
- **`flutter analyze lib/new_ui test/new_ui`: `No issues found!`** (0 analyzer issues).
- **`flutter build apk --debug --flavor beta`: success**, generated `build/app/outputs/flutter-apk/app-beta-debug.apk`.
- **APK package ID:** `top.apaipai.dsm_helper`.
- **Fixed development signing SHA-256:** `0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2`.
- **APK artifact uploaded:** `dsm-helper-modern-ui-android-debug`, artifact ID `11695207302`, size `190139220` bytes.
- **Artifact ZIP SHA-256 (not APK digest):** `601cdb27549ae4162a7bd65b76e6aeb38ba670c9f215c72b6856ca7459fbe663`.
- **Workflow:** https://github.com/qyxx2/dsm_helper/actions/runs/38121451189
- **Artifact:** https://github.com/qyxx2/dsm_helper/actions/runs/38121451189/artifacts/11695207302

## 4. Verified file boundary

Remote compare `0e07e56335b872b4c3f482066da8e7eff8db0c2b...787e1de93694bbf4eb4c81e284232c7378087d4c`: **ahead by 4 commits, exactly 5 affected files**:

1. `lib/models/Syno/FileStation/FileStationList.dart` — modify `shareList` / `fileList` signatures and the matching request `offset/limit` values only; original defaults retained.
2. `lib/new_ui/files/file_browse_page_model.dart` — new request/page types and local data exception.
3. `lib/new_ui/files/file_browse_data_source.dart` — new typed loader adapter with production seam and structural validation.
4. `test/new_ui/files/file_browse_data_source_test.dart` — legacy wire and injected-loader/error behavior tests.
5. `test/new_ui/files/file_browse_page_model_test.dart` — request/page and invalid-data tests.

The model diff was independently checked against the Batch base: code **before `shareList` and from `favoriteList` onward is byte-identical**, including all legacy mutation paths. Changes are restricted to the two list method declarations and four data-map entries. No changes to legacy UI, API transport, auth, persistence, app shell, Task 7B/7C, or other Task were made.

## 5. Boundaries, deferred dependencies and physical-device Gate

- The root/folder typed adapter is implemented **in isolation**; no Files-tab production cutover, navigation controller, breadcrumb, progressive pagination, list/grid, sorting UI, selection, preview or transfer behavior exists as part of this Batch.
- `FileBrowsePage.total == null` means *unknown*, not zero. When server offset is omitted, the adapter retains the verified requested offset as the documented safe fallback. Invalid present totals/offsets are errors, not empty.
- Legacy `FileItem.path` and optional metadata remain nullable. A downstream navigation/controller must not treat missing row paths as valid destinations.
- **Next dependency:** separately authorized Task 7A **Batch 2** owns incremental page orchestration, request-generation isolation and aggregation according to the frozen plan; none was implemented or authorized by this acceptance.
- **Real-NAS/device verification:** not performed and not claimed. B1 is a pure read-contract and adapter Batch, and its Exit Gate is automated; route/device gate belongs to later integration Batches. No proof is claimed for server-specific DSM permissions, real remote mounts, or >100 real directory entries.
- No integration PR, merge to `modern-ui`, next Batch implementation or new write capability was performed.

**Exit Gate conclusion:** **PASS**, based on the exact implementation HEAD's CI #305. The following docs-only acceptance commit is intentionally excluded from redundant APK rebuilding under `CI-DOCS-01`.
