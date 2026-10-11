# Task 7A Batch 2 — Directory Browse Controller / Paging / Failure State Acceptance

> **Result: PASS — Batch 2 automated Exit Gate (2026-10-11).**
>
> - Project: `qyxx2/dsm_helper`, DSM Helper Modern UI Task 7A
> - Scope: **Batch 2 only**, directory-local controller, paging, failure/generation state and verified ancestor projection
> - Working branch: `feature/t7a-file-browse`
> - Batch start/base: `bc7f34157d08fe6065af8f6aef16a28e72a1d43a` (Batch 1 acceptance)
> - **CI-verified implementation HEAD: `1d1d07ea98f0ffd1955af5434b5dc8cf24b9cf5d`**
> - This acceptance document is a **docs-only commit after** that validated code SHA; it is not a new independently tested implementation SHA.

## 1. Frozen contract verification

| Contract | Actual Batch 2 evidence | Limit / deferred work |
| --- | --- | --- |
| `T7A-DATA-03` progressive paging | `loadInitial()` retrieves only offset 0, limit 100; each `loadNext()` requests one page and coalesces overlapping calls. 0/100/101/250+ fixtures, offsets 0/100/200, known/unknown total and exact-full terminal semantics, duplicate-path aggregation and contradictory/repeated/oversized/short-page detection verified. No 100-item hard cap or automatic eager loop. | Scroll-triggered invocation and user-facing Load More/Retry are B3 UI, not claimed in B2. |
| `T7A-DATA-05` retained completed state | V1 completed snapshot stays visible throughout V2 refresh; partial new pages cannot overwrite V1; a failed refresh becomes stale; a later fully completed V2 replaces V1 atomically. If no prior completed snapshot exists, loaded rows remain partial/incomplete, and a first-request failure is not valid empty. | Controller exposes `phase` and `error`; visual presentation belongs to B3. |
| `T7A-DATA-06` request generation | Older sort-generation success/error discarded; old directory requests canceled logically by `onLeaveDirectory()`; disposed NAS A controller cannot publish into NAS B controller. Completed parent directory snapshot survives leave/back. | The B3 Navigator creates and disposes a controller per directory route; the B2 code does not create routes or hold global session authority. |
| `T7A-PATH-01` verified ancestor data | Root `path == null`; ordinary and Unicode paths are exact; remote `scheme://` remains intact; only explicitly supplied visited ancestors are projected, with duplicate navigable paths collapsed, same-label/different-path entries distinct and returned list immutable. | Breadcrumb widget and Back/ancestor navigation are B3, not claimed here. |
| `T7A-STATE-01` state classification | Verified valid empty versus initial loading, refreshing/stale/partial, Dio offline, generic DSM unavailable and DSM `119` reauthentication signal (per-controller callback at most once). Late requests do not change state or notify after dispose. | No session credential write, forced logout or UI integration; cross-route reauth de-duplication remains under the existing session coordinator. |
| `G-FILE-01` directory departure | `onLeaveDirectory()` invalidates the in-flight generation but keeps the last completed parent snapshot. | B4 adds temporary selection state; there is no selection to clear in B2. |

Controller input uses the existing Batch 1 `FileBrowseDataSource`, `FileStationList` metadata, exact nullable path and the legacy sorting enums. No additional transport, write API, route ownership or credentials are introduced.

## 2. TDD evidence (actual GitHub Actions)

| Stage | Commit | Run | Evidence |
| --- | --- | --- | --- |
| 2.1 RED | `f827002c621dc549b31120fa7608242bf8f0d8db` | **#306**, `38127160505` | Expected compile failure: missing new controller and state types. Pre-existing tests passed. |
| 2.1 GREEN | `50a9b78295b6a664d6ff7836ff1b4b1803a8f6eb` | **#307**, `38127467505` | Controller tests passed; analyzer caught redundant import in the new test. |
| 2.1 GREEN final | `8db319ac098d0bd8b04bd4c336200a1426ab1f53` | **#308**, `38127692432` | `completed / success`; corrected analyzer-only unused import, no production behavior change. |
| 2.2 RED | `8f8a1636e07068d703c5d6a5d92e3815a5cc9c67` | **#309**, `38128393075` | 330 passed, 1 failed: oversized response incorrectly treated as valid. |
| 2.2 RED extension | `4dd43df0045b19cb45803de369237db81b24f8f6` | **#310**, `38134019273` | 330 passed, 4 failed: oversized response; unknown-total empty terminator; contradictory short page; duplicate paths with invalid completed total. |
| 2.2 GREEN | `c6f17db6299c2a35f760adac3967685ce03ae107` | **#311**, `38134298389` | `completed / success`; 334 tests passed, analyzer clean, APK and signing checks passed. |
| 2.3 RED | `bcd33fdea3ec2c65a3d6ede511f3060a956f9631` | **#312**, `38135695937` | Expected missing `file_browse_path.dart` and ancestor projection symbol errors. |
| **2.3 GREEN / Batch 2 Gate** | **`1d1d07ea98f0ffd1955af5434b5dc8cf24b9cf5d`** | **#313**, `38136122168` | **`completed / success`**, 340 tests, analyzer clean, APK built, install identity verified and artifact uploaded. |

RED and GREEN are based on actual remote logs. RED failures are expected missing feature/failed behavior assertions; no failed CI is presented as a passing result.

## 3. Final Gate at exact implementation HEAD

- **Workflow:** `Modern UI Android CI`, run **#313** (`38136122168`), job `114460226035`; check-out/head SHA `1d1d07ea98f0ffd1955af5434b5dc8cf24b9cf5d`.
- **Outcome:** `completed / success`, every workflow step passed.
- **Toolchain:** Flutter `3.22.3`, Java 17, project dependencies via `flutter pub get`.
- **Full `flutter test`: 340 passed, 0 failed.** Log contains 34 passed tests under `test/new_ui/files/`: 15 controller tests, 6 path tests, 7 adapter tests and 6 page-model tests.
- **`flutter analyze lib/new_ui test/new_ui`: `No issues found!`** (0 analyzer issues). This wider invocation includes every `lib/new_ui/files` and `test/new_ui/files` file.
- **APK:** `flutter build apk --debug --flavor beta` succeeded; `build/app/outputs/flutter-apk/app-beta-debug.apk` generated.
- **Package ID:** `top.apaipai.dsm_helper`.
- **Stable dev certificate SHA-256:** `0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2` — verified against CI expectation.
- **APK artifact:** `dsm-helper-modern-ui-android-debug`, artifact `11700834574`, 190,139,220 bytes, from the same implementation SHA.
- **Artifact ZIP digest (not APK digest):** `sha256:aba15d0fa82c9ab70979dedd99287973ae100a499f2bf26703ef21f81cd63f8b`.
- **Workflow:** https://github.com/qyxx2/dsm_helper/actions/runs/38136122168
- **Artifact:** https://github.com/qyxx2/dsm_helper/actions/runs/38136122168/artifacts/11700834574

The isolated plan commands `flutter test test/new_ui/files -r expanded` and `flutter analyze lib/new_ui/files test/new_ui/files` were **not executed as standalone commands** because Flutter/Dart are not available in the current execution environment. The actual CI's full repository test suite and broader targeted New UI analyzer are superset checks at this exact commit; no local execution is claimed.

## 4. Repository boundary and commit diff

Remote GitHub compare `bc7f34157d08fe6065af8f6aef16a28e72a1d43a...1d1d07ea98f0ffd1955af5434b5dc8cf24b9cf5d`: **8 implementation/test commits ahead; exactly 5 added files**, all within the frozen Batch 2 boundary:

1. `lib/new_ui/files/file_browse_controller.dart`.
2. `lib/new_ui/files/file_browse_state.dart`.
3. `lib/new_ui/files/file_browse_path.dart`.
4. `test/new_ui/files/file_browse_controller_test.dart`.
5. `test/new_ui/files/file_browse_path_test.dart`.

No legacy File Station implementation, `lib/apis/**`, shared shell/`lib/new_ui/app/**`, navigation widgets, preferences, Task 7B/7C, transfers, mutations, release configuration or CI workflow files were touched.

## 5. Exit limits and handoff

- **PASS for Batch 2 isolated automated Exit Gate.** Paging, snapshot retention, async-generation isolation, DSM error distinctions and verified ancestor data are proved using fake/injected loaders.
- **Not a usable Modern Files screen yet.** Batch 3 is separately authorized work for widgets, breadcrumb and route/Back/scroll behavior. Batch 4 adds selection. No production UI cutover, preview exposure or file write capabilities were implemented here.
- **Real NAS and physical-device tests:** not performed and **not recorded as passed**. Batch 2 has no independent device gate. DSM-specific live share/permission/mount behavior remains unverified until integration.
- This document records **only Batch 2**. No Batch 3 implementation, PR, merge to `modern-ui` or other task is authorized by this acceptance.
- Docs-only acceptance should not trigger a redundant APK build under `CI-DOCS-01` / workflow `paths-ignore`.

**Final conclusion: Batch 2 automated Exit Gate PASS at implementation SHA `1d1d07ea98f0ffd1955af5434b5dc8cf24b9cf5d`. STOP after acceptance.**
