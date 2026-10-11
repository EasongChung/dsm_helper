# Task 7A File Station Browse Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver a separately testable Modern Material 3 read-only File Station browse foundation—shares, directories, incremental paging, breadcrumb/Back, list/grid, sorting and stable selection—without replacing the existing complete legacy Files entry.

**Architecture:** Retain `FileStationList`/`Api.dsm` as the only DSM transport/model authority, extend their page parameters compatibly, and add a narrow `lib/new_ui/files/**` adapter, directory-route-scoped `ChangeNotifier` state and compact widgets. After isolated behavior is proven, expose an opt-in **secondary** preview route from the existing Files placeholder; keep its primary `打开现有功能` legacy fallback and all Task 7B/7C operations unchanged.

**Tech Stack:** Flutter 3.22.3 / Dart, Material 3, existing `FileStationList` and `DsmApi`/Dio, `SpUtil`, `ChangeNotifier`, existing `NewUiAppShell`/`NewUiShell`, existing GitHub Actions Android beta APK CI.

**Spec:** `docs/modern-ui/specs/2026-10-11-task-7a-file-browse-feature-design.md`  
**Contracts:** `docs/modern-ui/contracts/2026-10-11-task-7a-file-browse-contract-matrix.md`  
**Other authorities:** `docs/modern-ui/2026-10-06-dsm-helper-modern-ui-master-plan.md`; Task 1 Project Spec, Task 2 Visual Design Spec and Global Contract Matrix.

## Global Constraints

- Integration branch: `modern-ui`. Task branch: `feature/t7a-file-browse`. Plan baseline: `3cb0bd8139aaa55b7f66715502a429fe480ffe90`, with `modern-ui@b80a59c61ca3baf07201478637deaa61a181c6a4`.
- Implement **B1 → B2 → B3 → B4 → B5**. Each Batch has its own RED→GREEN evidence, acceptance record, diff boundary and stop gate. A Batch instruction does not authorize the next Batch, a PR, or integration merge.
- Source authority: actual GitHub HEAD, current plan/spec/contracts/previous acceptance and real implementation/test files **re-read before each Batch**. Never infer from this plan that an intervening commit or CI succeeded.
- Do **not** begin Task 7B/7C/8. Search, favorite/share/copy/move/rename/delete, create-folder, preview/open, transfer, background tasks, external share intent destination and remote/virtual management are deferred.
- Do not replace the production Files destination: original `NewUiPrimaryPage` legacy button/`FilePage` and its `LegacyPageHost` stay functional. Task 7A only adds a labeled secondary opt-in Modern browse preview at B5.
- New feature code: `lib/new_ui/files/**`, tests `test/new_ui/files/**`; only minimal compatible `FileStationList.dart` model change in B1 and narrowly justified `NewUiPrimaryPage` / `NewUiAppShell` / `DsmNewUiShell` wiring in B5. No blanket editing legacy `lib/pages/file/**`, `lib/apis/**`, `lib/database/**`, provider/session/transfer code.
- Preserve `FileItem.path` exactly, including special `scheme://` paths. Do not key selection by name/index/object instance/`real_path`, or synthesize a navigable path.
- Back/selection/context/notifications/theme follow `G-FILE-01`, `G-NAV-01/02/03`, `G-ANDROID-01/02/03`, `G-STATE-01`, `G-NET-01` and `G-NOTIFY-01`. Use existing global/session ownership; never add a second SID or DSM transport.
- Pagination: page size `100`; load first page, fetch additional pages incrementally when scrolled; no silent file cap and no eager unbounded loop. A new sort/path/context generation invalidates previous in-flight work.
- File-list presentation preference authority is already `SpUtil`: `file_list_type` values `list/grid` (default `list`), `file_sort_by` legacy `SortByEnum` values (default `name`), `file_sort_direction` values `ASC/DESC` (default `ASC`). Legacy sends enum `.name`; preserve actual request string without guessing alternative casing.
- Null `files` vs valid empty array must be distinguishable. Retain prior *completed* directory snapshot during refresh failure; an incomplete result is never declared complete, and missing selected paths are pruned only after full successful fresh listing.
- `APK-IDENTITY-01`: user beta/debug APK remains `top.apaipai.dsm_helper`, same fixed dev certificate; cover-install preserves app data. `CI-DOCS-01`: docs-only commits do not need duplicate full CI.
- The executor must NOT claim Flutter tests ran locally when Flutter/Dart is unavailable. RED/GREEN can use targeted GitHub CI commits and exact workflow/run evidence; do not keep rerunning a known hung/cancelled unchanged workflow. No permission to update tests *instead of* fixing implementation without explaining the evidence.
- Each code-changing Batch must finish static checks, targeted tests, full **relevant** Modern UI tests as directed below, remote commit/SHA/diff audit, and an acceptance file; final B5 also needs real-device evidence before declaring the Task complete. User-declined/nonessential tests are labeled `NOT TESTED`, not `PASS`.

## Review Focus — five high-risk inputs and owning tests

1. **101/250+/duplicated response pages**: endless/repeated pages must not produce an infinite request sequence, false total or silent 100-item truncation. B1 model/page validation; B2 controller pagination/progress tests.
2. **Slow page A arrives after directory B or account B**: stale page/error must not overwrite B or display A file paths. B2 generation tests; B5 Shell A→B relationship test.
3. **Sort/layout changes while selection active**: exact selected paths persist across reconstructed `FileItem` and list↔grid; names duplicated under different paths remain distinct. B2 identity, B4 widget selection tests.
4. **Unstable network/permissions/null metadata**: complete valid empty must be separate from permission error, DSM 119, transport timeout and malformed response; refreshing must not erase the old valid rows. B1 parser validation, B2 controller error classifier, B3 states.
5. **Legacy regression during preview**: legacy File Station, normal navigation/Back, notifications, existing intents and installed APK identity remain unchanged. B5 integration tests and real-device Gate.

## Dependency / Batch Matrix

| Batch | Reviewable deliverable | Depends on | Contracts owned | Prohibited scope |
| --- | --- | --- | --- | --- |
| **B1** | Compatible DSM list pagination + typed read adapter | approved preflight | `T7A-DATA-01/02/04`; page wire side `03` | controller, UI, selection, shell |
| **B2** | Route-scoped directory/page controller, last-valid and generation safety | B1 | `T7A-DATA-03/05/06`, `T7A-PATH-01` (pure ancestors), `T7A-STATE-01`, `T7A-SHELL-02` (pure context reset) | widget/shell wiring, file mutation |
| **B3** | Modern read-only browse page, breadcrumb/Back, view/sort/prefs | B1–B2 | `T7A-PATH-01/02`, `T7A-VIEW-01/02`, `T7A-STATE-01` (widget) | selection gestures/actions, preview shell, production cutover |
| **B4** | Stable directory-local selection + list/grid interactions | B1–B3 | `T7A-SEL-01/02/03/04`, Back-selection precedence | file operations/preview, production cutover |
| **B5** | Opt-in preview handoff + full relationship/CI/APK and device Gate | B1–B4 | `T7A-SHELL-01/02`, `T7A-CUTOVER-01`, integration of all previous rows | legacy removal, default Files replacement, Tasks 7B/7C/8 |

**Integration rule:** use one Task 7A branch with successive small commits and acceptance files. Do not open a continuously auto-building PR for every intermediate Batch; inspect Actions for each necessary code SHA. PR→`modern-ui` and merge require explicit later instruction and real-device Gate when required. Do not declare a Batch PASS from document checkboxes alone.

---

# Batch 1 — Existing FileStation List Contract / Read Adapter

**Purpose:** Establish actual read and page inputs before controller/UI. Keep legacy callers byte-for-byte equivalent at defaults.

**Files:**
- Modify minimally: `lib/models/Syno/FileStation/FileStationList.dart` (`shareList` and `fileList` only; parser adjustments **only** if a failing malformed-payload test proves they are needed).
- Create: `lib/new_ui/files/file_browse_data_source.dart`.
- Create: `lib/new_ui/files/file_browse_page_model.dart`.
- Create: `test/new_ui/files/file_browse_data_source_test.dart`.
- Create: `test/new_ui/files/file_browse_page_model_test.dart`.
- Create after GREEN: `docs/modern-ui/acceptance/2026-10-11-task-7a-batch-1-acceptance.md`.

**Interfaces — lock these names for later Batches:**

`FileStationList.shareList` adds named `int offset = 0, int limit = 100`; `FileStationList.fileList` adds the same, without changing existing positional/named parameters, `method`, `version: 2`, `folder_path`, `filetype`, `additional` or sort request values.

`lib/new_ui/files/file_browse_page_model.dart` produces:

```dart
class FileBrowseRequest {
  const FileBrowseRequest({
    required this.path, // null = shared-folder root
    required this.offset,
    this.limit = 100,
    required this.sortBy,
    required this.sortDirection,
  });
  final String? path;
  final int offset;
  final int limit;
  final String sortBy;
  final String sortDirection;
}

class FileBrowsePage {
  const FileBrowsePage({
    required this.path,
    required this.offset,
    required this.limit,
    required this.items,
    required this.total,
  });
  final String? path;
  final int offset;
  final int limit;
  final List<FileItem> items;
  final int? total;
}
```

`lib/new_ui/files/file_browse_data_source.dart` produces:

```dart
typedef FileSharePageLoader = Future<FileStationList> Function({
  required int offset,
  required int limit,
  required String sortBy,
  required String sortDirection,
});
typedef FileFolderPageLoader = Future<FileStationList> Function({
  required String path,
  required int offset,
  required int limit,
  required String sortBy,
  required String sortDirection,
});
class FileBrowseDataSource {
  const FileBrowseDataSource({
    required this.loadShares,
    required this.loadFolder,
  });
  factory FileBrowseDataSource.production();
  final FileSharePageLoader loadShares;
  final FileFolderPageLoader loadFolder;
  Future<FileBrowsePage> loadPage(FileBrowseRequest request);
}
```

Adapter checks `offset>=0`, `limit>0`, a matching integer/nonnegative returned offset (or documented safe fallback when absent), integer/nonnegative `total` if present, non-null `files` (shares normalized to files by legacy parser), and no malformed row crash. Fail with a typed local browse-data error; **do not** map errors to valid empty. Rely on existing `DsmException`/Dio for transport codes.

### Task 1.1 — Page inputs and legacy request compatibility

- [ ] **Step 1 — RED test:** In `file_browse_data_source_test.dart`, test exact root `list_share` and folder `list` request fields; request offset `100`/limit `100`, legacy default offset `0`/limit `100`, `"sort_by"`/`"sort_direction"` including `ASC/DESC` and quoted legacy values, version `2`, and original path. For the global `Api.dsm` seam, temporarily install an explicit fake `DsmApi.entry` recorder and restore original in `tearDown`; no network call.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_data_source_test.dart -r expanded`. Expected **FAIL before change** because the existing model has no `offset/limit` arguments.
- [ ] **Step 3 — GREEN code:** Extend only `shareList/fileList` named args and request data fields. Do not alter `favoriteList`, `virtualFolder` or operation methods.
- [ ] **Step 4 — GREEN run:** Same command → all assertions PASS, including unchanged legacy-default payload. If faking `DsmApi.entry` requires a different seam, retain real-call coverage using a captured Dio adapter; never weaken request-field assertions.
- [ ] **Step 5 — Commit:** `test/new_ui/files/file_browse_data_source_test.dart` + model minimal diff; message `feat(t7a): support compatible paginated File Station lists`.

### Task 1.2 — Typed browse read semantics

- [ ] **Step 1 — RED test:** In `file_browse_page_model_test.dart` test valid zero rows; null/missing `files`; non-integer/negative total/offset; null metadata; duplicate names under different exact paths; `/share/space and 汉字`; virtual `scheme://` input preserved byte-for-byte. In data-source test assert injected loaders receive exact `FileBrowseRequest` and exceptions remain distinguishable (DSM 119, other DSM error, Dio exception).
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_page_model_test.dart test/new_ui/files/file_browse_data_source_test.dart -r expanded` → expected FAIL for missing adapter/types.
- [ ] **Step 3 — GREEN code:** Implement `FileBrowsePage`/`Request` validation and `FileBrowseDataSource.production()` using `FileStationList.shareList/fileList`. Preserve root/folder response distinction; do not reimplement JSON response envelope.
- [ ] **Step 4 — GREEN run:** Same command → PASS. Also run `flutter analyze lib/new_ui/files test/new_ui/files` → 0 errors.
- [ ] **Step 5 — Commit:** adapter/models/tests; message `feat(t7a): add typed browse read adapter`.

### Task 1.3 — B1 contract Gate

- [ ] Run targeted B1 tests and analyzer again at the exact commit to be handed off; record command/output or GitHub Actions run ID, failures, SHA, test count.
- [ ] Inspect `git diff <batch-base>...HEAD -- lib/models/Syno/FileStation/FileStationList.dart lib/new_ui/files test/new_ui/files`, ensure no legacy file mutation paths changed.
- [ ] Create `batch-1-acceptance.md`: mapping `DATA-01/02/04` and wire-page portion of `03`; RED→GREEN proof, changed files, untouched scope, known constraints, next dependency.
- [ ] Commit docs-only acceptance without redundant APK build; fetch remote SHA and compare file list.
- [ ] **STOP after B1.** No controller, view, preview, Batch 2, PR or merge.

**B1 Exit Gate:** Existing root/folder list API calls remain compatible with old callers, pages can request offset >0 and adapter distinguishes valid empty from error. Pagination orchestration remains B2.

---

# Batch 2 — Directory Browse Controller / Paging / Failure State

**Purpose:** Provide a pure, testable directory-local state owner before building widgets. Navigation owns routes in B3; B2 owns request generations and exact ancestors as data.

**Files:**
- Create: `lib/new_ui/files/file_browse_controller.dart`.
- Create: `lib/new_ui/files/file_browse_state.dart`.
- Create: `lib/new_ui/files/file_browse_path.dart`.
- Create: `test/new_ui/files/file_browse_controller_test.dart`.
- Create: `test/new_ui/files/file_browse_path_test.dart`.
- Create after GREEN: `docs/modern-ui/acceptance/2026-10-11-task-7a-batch-2-acceptance.md`.

**Interfaces (built on B1):**

```dart
enum FileBrowsePhase { initial, loading, valid, refreshing, stale, partial, offline, unavailable, reauthNeeded }
class FileBrowseAncestor {
  const FileBrowseAncestor({required this.label, required this.path}); // null path is root
  final String label;
  final String? path;
}
class FileBrowseController extends ChangeNotifier {
  FileBrowseController({
    required FileBrowseDataSource dataSource,
    required String contextId,
    required String? path,
    SortByEnum sortBy = SortByEnum.name,
    SortDirectionEnum sortDirection = SortDirectionEnum.ASC,
    VoidCallback? onReauthNeeded,
  });
  FileBrowsePhase get phase;
  List<FileItem> get visibleItems;
  bool get hasMore;
  int? get total;
  String? get path;
  Object? get error;
  bool get isComplete;
  Future<void> loadInitial();
  Future<void> loadNext();
  Future<void> refresh();
  Future<void> changeSort(SortByEnum by, SortDirectionEnum direction);
  void onLeaveDirectory();
}
```

`file_browse_path.dart` produces `FileBrowseAncestor` and `List<FileBrowseAncestor> buildBrowseAncestors({required List<FileBrowseAncestor> visited, required FileBrowseAncestor current})`. Only verified *visited* ancestors are actionable; display a readable full path for a special URI, never parse and invent an unvisited remote ancestor. The controller has only one current path; child routes create their **own** controller at B3. Selection methods are added to the same controller in B4; keep the state class extendable without a second controller authority.

### Task 2.1 — Directory generation, pagination and snapshot RED→GREEN

- [ ] **Step 1 — RED test:** `file_browse_controller_test.dart` cases: root `null` vs literal returned folder path; 0/100/101/250+ rows with successive offsets `0,100,200`; only initial page requested by `loadInitial`; exactly one incremental page per `loadNext` (coalesce parallel calls); valid end by total or short page; repeated full page/no cursor progress→`partial` with Retry; contradictory total→`partial`. Use completers/fake B1 loader; no live NAS.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_controller_test.dart -r expanded` → FAIL (controller absent).
- [ ] **Step 3 — GREEN code:** Implement `FileBrowseState` snapshot and `FileBrowseController` progressive loader. Track `generation`, pagination cursor, last fully completed snapshot separately from provisional pages. Do not hard cap total items and do not eagerly fetch all pages.
- [ ] **Step 4 — GREEN run:** Same command → PASS; evidence distinguishes `isComplete` from `hasMore` at exactly 100 and at 101.
- [ ] **Step 5 — Commit:** message `feat(t7a): manage directory paging and snapshots`.

### Task 2.2 — Error, stale and overlapping-request RED→GREEN

- [ ] **Step 1 — RED test:** V1 complete→refresh begins (still V1)→partial new page/failure (V1 stays stale)→V2 complete; first ever request fails (no false empty); permission/API error vs `DsmException(119)` vs Dio timeout; A path/sort generation slow, newer generation fast, old success/error ignored; after dispose no late notify; context A disposed while B controller runs (no A row appears). Assert auth callback fires only for actual 119, not timeout, and at most once per context.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_controller_test.dart -r expanded` → FAIL new failure tests.
- [ ] **Step 3 — GREEN code:** Complete generation fencing and error-classification state in controller. Keep `Api.dsm`/session owned externally; never rewrite auth coordinator. If an actual 119 type-conversion problem is demonstrated in legacy transport, record it as a **separate minimal blocker** and stop before touching `lib/apis/**` outside the frozen B2 boundary.
- [ ] **Step 4 — GREEN run:** Same test → PASS; `flutter analyze lib/new_ui/files test/new_ui/files` → 0 errors.
- [ ] **Step 5 — Commit:** message `feat(t7a): retain last valid file listing through failures`.

### Task 2.3 — Verified path and route handoff semantics

- [ ] **Step 1 — RED test:** `file_browse_path_test.dart` checks root → `/share` → `/share/汉字` exact visited path identity; ancestor jump only to visited paths; remote `scheme://server/folder` without verified parent yields no invented intermediate; duplicate display names at different paths are distinct.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_path_test.dart -r expanded` → FAIL.
- [ ] **Step 3 — GREEN code:** Implement immutable ancestor projection used by B3; `onLeaveDirectory()` invalidates pending requests and clears temporary directory-local selection when available (B4 adds selection state), without disposing parent completed snapshot.
- [ ] **Step 4 — GREEN run:** Targeted path+controller tests → PASS.
- [ ] **Step 5 — Commit:** message `feat(t7a): preserve verified File Station ancestor paths`.

### Task 2.4 — B2 Gate

- [ ] Re-run `flutter test test/new_ui/files -r expanded` and `flutter analyze lib/new_ui/files test/new_ui/files`; report SHA and CI run.
- [ ] Verify `T7A-DATA-03/05/06`, pure `PATH-01`, `STATE-01`; no `lib/new_ui/app/**`/Shell/widget changes.
- [ ] Create `batch-2-acceptance.md` with pager/no-cap/failure/generation evidence, then commit and verify remote diff/SHA.
- [ ] **STOP.** B2 controller exists but is not a production browse page.

**B2 Exit Gate:** Paging and stale-state rules work under adversarial async ordering; no widget/route or legacy shell cutover occurred.

---

# Batch 3 — Modern Browse Page, Breadcrumb, List/Grid and Sort

**Purpose:** Deliver a functioning **isolated** read-only Modern browser with actual directory push/Back and preference UI, without a production entry or selection actions yet.

**Files:**
- Create: `lib/new_ui/files/file_browse_page.dart`.
- Create: `lib/new_ui/files/file_browse_row.dart`.
- Create: `lib/new_ui/files/file_browse_breadcrumb.dart`.
- Create: `lib/new_ui/files/file_browse_preferences.dart`.
- Create: `test/new_ui/files/file_browse_page_test.dart`.
- Create: `test/new_ui/files/file_browse_breadcrumb_test.dart`.
- Create: `test/new_ui/files/file_browse_preferences_test.dart`.
- Create after GREEN: `docs/modern-ui/acceptance/2026-10-11-task-7a-batch-3-acceptance.md`.

**Interfaces:**

```dart
class FileBrowsePreferences {
  const FileBrowsePreferences({required this.view, required this.sortBy, required this.direction});
  final ListType view;
  final SortByEnum sortBy;
  final SortDirectionEnum direction;
}
class SpUtilFileBrowsePreferencesStore {
  FileBrowsePreferences load();
  Future<void> saveView(ListType view);
  Future<void> saveSort(SortByEnum by, SortDirectionEnum direction);
}
class FileBrowsePage extends StatefulWidget {
  const FileBrowsePage({
    super.key,
    required this.contextId,
    required this.onOpenNotifications,
    this.connectionStatusText,
    this.dataSource,
    this.path, // null for shared root
    this.ancestors = const <FileBrowseAncestor>[],
    this.onReauthNeeded,
  });
  final String contextId;
  final String? path;
  final List<FileBrowseAncestor> ancestors;
  final FileBrowseDataSource? dataSource;
  final VoidCallback onOpenNotifications;
  final String? connectionStatusText;
  final VoidCallback? onReauthNeeded;
}
```

B3 widgets construct one B2 controller **per pushed directory route** and dispose it on pop, reusing the current tab Navigator; root `RouteSettings(name:'t7a-file-root')` and child `RouteSettings(name:'t7a-folder:<exact path>')` are enough to identify verified stack ancestors. Do not push through `rootNavigator:true`. Preview B5 will provide this page with real session callbacks. File rows in normal mode have no invented open handler; avoid dead buttons. Remote thumbnail/preview requests are prohibited in B3.

### Task 3.1 — Preferences and local view projection RED→GREEN

- [ ] **Step 1 — RED test:** `file_browse_preferences_test.dart` checks defaults list/name/ASC; correct reads/writes to the **existing** three `SpUtil` keys; corrupt strings fall back separately; no DSM write or session mutation; choosing sort uses actual `SortByEnum.name` and `SortDirectionEnum.name`; view toggle does not change sort.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_preferences_test.dart -r expanded` → FAIL missing store.
- [ ] **Step 3 — GREEN code:** Store wrapper over existing `SpUtil`, using legacy `ListType`/sort enums and no new preference namespace.
- [ ] **Step 4 — GREEN run:** Targeted test → PASS; confirm fake shared preferences initialized per existing New UI test pattern.
- [ ] **Step 5 — Commit:** message `feat(t7a): reuse legacy file view preferences`.

### Task 3.2 — Root/list/grid/states RED→GREEN

- [ ] **Step 1 — RED widget test:** Fake B1 data source drives valid shared roots and folders, empty, initial-loading, offline/stale/partial/permission/reauth; null size/time/owner; long Unicode names and text scaling ≥1.6; light/dark contrast/48dp row targets; list/grid file and folder identity; no per-file Card, legacy glass or unchecked permanent checkbox column; visible `加载更多/重试` when paged/failure. Assert no extra requests until approaching scroll end; swiping scroll triggers `loadNext` once.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_page_test.dart -r expanded` → FAIL missing page.
- [ ] **Step 3 — GREEN code:** Build compact Material 3 `FileBrowsePage`/`file_browse_row.dart` on B2 state, `RefreshIndicator` where scrollable, proper loading/stale indicators, incremental paging, Overflow/Bottom Sheet for sort/view. Leave selection callback as a B4 extension point.
- [ ] **Step 4 — GREEN run:** Same test → PASS; `flutter analyze lib/new_ui/files test/new_ui/files` → 0 errors.
- [ ] **Step 5 — Commit:** message `feat(t7a): render Modern File Station browsing modes`.

### Task 3.3 — Breadcrumb and Back RED→GREEN

- [ ] **Step 1 — RED tests:** `file_browse_breadcrumb_test.dart` and `file_browse_page_test.dart`: root→share→nested folder; file is visible but **not opened** by a fake preview; verified ancestor tap pops to that existing route (no duplicate push); `scheme://` ancestor not fabricated; Android Back pops only one directory and restores parent's last completed view/scroll, without resurrecting prior selection; tab/route remains inside host MaterialApp.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_breadcrumb_test.dart test/new_ui/files/file_browse_page_test.dart -r expanded` → FAIL.
- [ ] **Step 3 — GREEN code:** Implement path-aware, scrollable compact breadcrumb. Use existing `Navigator.of(context)`; call old controller `onLeaveDirectory()` when pushing child and do not destroy its finished snapshot.
- [ ] **Step 4 — GREEN run:** Same tests → PASS. Check themes, App Bar global notification callback/connection status and layout.
- [ ] **Step 5 — Commit:** message `feat(t7a): add exact-path breadcrumb and directory routes`.

### Task 3.4 — B3 Gate

- [ ] `flutter test test/new_ui/files -r expanded`; `flutter analyze lib/new_ui/files test/new_ui/files` → PASS. If remote-only Flutter, capture Action RED/GREEN SHA and CI log.
- [ ] Evidence: `T7A-PATH-01/02`, `T7A-VIEW-01/02`, read-state presentation; no gestures/operations/preview or `DsmNewUiShell` wiring yet.
- [ ] Acceptance `batch-3-acceptance.md` + remote diff/SHA proof. **STOP before B4.**

**B3 Exit Gate:** A test-mounted modern browser navigates root/folders, renders list/grid, sorts and preserves old preference values; the shipped Files tab still behaves exactly as before.

---

# Batch 4 — Selection Identity, Gestures and Reconciliation

**Purpose:** Implement Task 7A's complete **read-only selection foundation** within ordinary directories, on top of the B3 page.

**Files:**
- Modify: `lib/new_ui/files/file_browse_controller.dart`, `file_browse_state.dart`, `file_browse_page.dart`, `file_browse_row.dart`.
- Create: `lib/new_ui/files/file_browse_selection_bar.dart`.
- Create: `test/new_ui/files/file_browse_selection_test.dart`.
- Extend: `test/new_ui/files/file_browse_controller_test.dart` and `file_browse_page_test.dart`.
- Create after GREEN: `docs/modern-ui/acceptance/2026-10-11-task-7a-batch-4-acceptance.md`.

**Interfaces added to `FileBrowseController`:**

```dart
bool get isSelectionMode;
Set<String> get selectedPaths; // immutable/unmodifiable outward view
void selectPath(String path);
void togglePath(String path);
void selectLoaded();
void clearSelection();
```

Selection is keyed by exact nonempty DSM `FileItem.path` within this controller's `contextId` and `path`; root shared folders are navigation-only and do not enter selection. If a folder route is pushed, its former parent selection is cleared; return does not resurrect it. Page controller methods must only accept paths in its visible current directory; do not mutate/delete/create remote files.

### Task 4.1 — Stable path identity and refresh reconciliation RED→GREEN

- [ ] **Step 1 — RED test:** select A/C, rebuild new `FileItem` instances with same paths, sort, switch layout → selected A/C; same name/different path remains distinct; change directory clears; full new listing without A removes A **only after completely valid refresh**; failed/incomplete refresh retains A; two NAS contexts using identical path never share selection.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_selection_test.dart test/new_ui/files/file_browse_controller_test.dart -r expanded` → FAIL missing selection behavior.
- [ ] **Step 3 — GREEN code:** Add selected path set and selection state to existing B2 controller; reconcile on fully completed latest listing only, without a second global selection provider or row object equality.
- [ ] **Step 4 — GREEN run:** Same command → PASS.
- [ ] **Step 5 — Commit:** message `feat(t7a): select files by stable full path`.

### Task 4.2 — Swipe/tap/select-all/Back widget RED→GREEN

- [ ] **Step 1 — RED widget test:** Horizontal swipe on an ordinary file/folder row/tile enters selection; mode-tap toggles; normal folder tap navigates; root share remains navigation-only; selection row uses whole-row tonal highlight with no checkbox gutter; header count/exit/select-all, temporary selection App Bar; Back exits selection **before** popping directory; no unintended system Back/scroll theft.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_selection_test.dart test/new_ui/files/file_browse_page_test.dart -r expanded` → FAIL.
- [ ] **Step 3 — GREEN code:** Implement `file_browse_selection_bar.dart` and wire callbacks/gesture hit targets into row/grid; use appropriate `PopScope` with existing shell Back priority; no rename/delete/copy/download/favorite/preview actions.
- [ ] **Step 4 — GREEN run:** Same tests → PASS in List and Grid, Light and Dark, high font scale.
- [ ] **Step 5 — Commit:** message `feat(t7a): add read-only file selection interactions`.

### Task 4.3 — Paged select-all with exact count

- [ ] **Step 1 — RED test:** after first `100` loaded of `250`, header reads `已加载项全选`, selected count=`100`; after next `100` loads, selected remains `100` (not `200`); complete `250` list “全选” selects all current `250` when invoked; invalid/null path excluded; Back/exit clears count; in-flight failed sort page does not prune prior valid selection.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/files/file_browse_selection_test.dart -r expanded` → FAIL.
- [ ] **Step 3 — GREEN code:** Implement select-loaded semantics and stable count/label across paging.
- [ ] **Step 4 — GREEN run:** Same test plus `flutter test test/new_ui/files -r expanded` and targeted analyzer → PASS.
- [ ] **Step 5 — Commit:** message `fix(t7a): define loaded-only select-all during paging`.

### Task 4.4 — B4 Gate

- [ ] Contract proof `SEL-01/02/03/04` and `G-FILE-01`; compare exact source diff: no File Station mutation handler or preview, no legacy changes.
- [ ] Acceptance `batch-4-acceptance.md`, recorded test counts/CI run/remote SHA/diff, docs-only commit. **STOP before B5.**

**B4 Exit Gate:** Read-only selection survives layout/sort/rebuild, prunes only on full valid refresh, and handles Back/loaded-only select-all correctly without changing the production Files destination.

---

# Batch 5 — Opt-in Preview Entry, Context Relationships and Real-Device Gate

**Purpose:** Make Task 7A browser reachable **only by explicit test choice**, protect all legacy operations, and exercise complete shell/session/theme/notification/integration behavior before closure.

**Files:**
- Modify minimally: `lib/new_ui/shell/new_ui_primary_page.dart` (optional preview action), `lib/new_ui/app/new_ui_app_shell.dart` (destination optional preview builder and same-tab push), `lib/new_ui/app/dsm_new_ui_shell.dart` (Files-only preview injection and reauth callback).
- Modify only as test-discovered blockers: `lib/new_ui/files/**`.
- Create: `test/new_ui/app/task7a_files_preview_relationship_test.dart`.
- Extend: `test/new_ui/shell/new_ui_primary_page_test.dart`; `test/new_ui/app/task6_shell_relationship_test.dart` **only** where its own frozen assumptions make the new optional Files-only action impossible to test without narrowly adjusting it.
- Create after review: `docs/modern-ui/acceptance/2026-10-11-task-7a-batch-5-acceptance.md` (initial CI Gate, later append explicit user-reported device results).
- Modify on closure only: `docs/modern-ui/2026-10-06-dsm-helper-modern-ui-master-plan.md`.

**Interfaces:**

`NewUiPrimaryPage` adds optional `VoidCallback? onOpenBrowsePreview` (default null). When present, render a secondary `OutlinedButton` labeled `试用新版文件浏览（测试）`, key `file-browse-preview`, **after** original primary legacy button. Non-Files placeholders without callback render unchanged.

`NewUiAppDestination` adds optional `NewUiModernRootBuilder? browsePreviewBuilder` (default null), **reusing the existing typedef in `new_ui_app_shell.dart`** so both existing callbacks are explicit: `(BuildContext context, {required VoidCallback onOpenNotifications, required String? connectionStatusText})`. `NewUiAppShell` creates an `onOpenBrowsePreview` callback *only* when this builder is non-null. It calls `Navigator.of(tabContext).push(MaterialPageRoute<void>(builder: (previewContext) => browsePreviewBuilder(previewContext, onOpenNotifications: openNotifications, connectionStatusText: connectionStatusText)))` on the **current Files tab** (`rootNavigator` remains false). Do not introduce `modernBuilder` for the Files root in Task 7A. In `DsmNewUiShell`, supply a Files-only `browsePreviewBuilder` returning `FileBrowsePage(contextId: widget.contextId ?? 'legacy-current-context', onOpenNotifications: onOpenNotifications, connectionStatusText: connectionStatusText, onReauthNeeded: widget.onReauthNeeded)`. No new notification path or global session singleton.

### Task 5.1 — Files-only preview entry RED→GREEN

- [ ] **Step 1 — RED test:** Existing primary Files root still displays `open-legacy-feature`; clicking it uses unchanged `FilePage` fallback; only Files root also displays `file-browse-preview`, clicking it pushes `FileBrowsePage` on its own Files tab stack, Back returns to same placeholder; Tasks tab remains unchanged; duplicate New UI AppBar/legacy theme bleed do not occur.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/app/task7a_files_preview_relationship_test.dart test/new_ui/shell/new_ui_primary_page_test.dart -r expanded` → FAIL missing opt-in action.
- [ ] **Step 3 — GREEN code:** Add optional preview callback/builder to existing shell components without changing the existing normal Files `legacyBuilder`/`onLegacyBack`. Keep tests using fake browse loader; no live DSM in CI.
- [ ] **Step 4 — GREEN run:** Same command → PASS; targeted new UI analyzer 0 errors.
- [ ] **Step 5 — Commit:** message `feat(t7a): expose opt-in File Station browse preview`.

### Task 5.2 — Shell context/notification/Back/error relationships

- [ ] **Step 1 — RED tests:** A Files preview subdirectory→switch tabs→return retains route; background/resume retains route; verified context A→B remount clears A path/selection/late request and returns Overview root; File preview notification opens global DSM notifications and Back returns to unchanged route; DSM 119 uses `onReauthNeeded` once; Dio timeout retains context; theme Light↔Dark preserves route/selection; existing FilePage legacy path and `ExternalIntentListener` routing remain intact. Use fake controller/data and `KeyedSubtree` test scopes.
- [ ] **Step 2 — RED run:** `flutter test test/new_ui/app/task7a_files_preview_relationship_test.dart -r expanded` → FAIL on missing relationship behavior.
- [ ] **Step 3 — GREEN code:** Only fix Task 7A-owned controller, preview route and minimal callback wiring. For auth, follow existing `OverviewController` 119 callback pattern, not a new login module. Any unrelated legacy/transport change requires an explicit blocker record and separate approval.
- [ ] **Step 4 — GREEN run:** Targeted test → PASS plus existing `test/new_ui/app/task6_shell_relationship_test.dart` and `test/new_ui/legacy/legacy_nested_navigation_test.dart` regression → PASS.
- [ ] **Step 5 — Commit:** message `test(t7a): verify preview isolation and shell relationships` (if code changed, use `fix(t7a): ...`).

### Task 5.3 — Automation and scope Gate

- [ ] Run (locally when Flutter available; otherwise GitHub Actions with exact run/commit evidence):
  - `flutter test test/new_ui/files -r expanded`
  - `flutter test test/new_ui/app/task7a_files_preview_relationship_test.dart test/new_ui/app/task6_shell_relationship_test.dart test/new_ui/shell/new_ui_primary_page_test.dart test/new_ui/legacy/legacy_nested_navigation_test.dart -r expanded`
  - `flutter test test/new_ui -r expanded` (use full New UI test suite for final Task relationship regression; do not add massive unrelated legacy/UI test suites)
  - `flutter analyze lib/new_ui test/new_ui`
  - Existing Android beta APK job/artifact/signature identity under `APK-IDENTITY-01`.
- [ ] Compare `git diff <B5-start>...HEAD` and the whole Task `git diff b80a59c6...HEAD`. Allowed feature code: `lib/new_ui/files/**`; allowed minimal seams: `FileStationList.dart` named list page params, `NewUiPrimaryPage`/`NewUiAppShell`/`DsmNewUiShell`. Only tests/acceptance/docs otherwise.
- [ ] Prove `T7A-DATA-01…06`, `T7A-PATH-01/02`, `T7A-VIEW-01/02`, `T7A-SEL-01…04`, `T7A-STATE-01`, `T7A-SHELL-01/02` and `T7A-CUTOVER-01`; list tests/CI evidence per row.
- [ ] Before an APK is handed to the user, confirm CI artifact corresponds to current code SHA and the same package ID/signing fingerprint. Do not fabricate device findings from CI.

### Task 5.4 — Real DSM/Android device acceptance

- [ ] On the user's currently installed Android phone, **install APK over the previous version**, not uninstall; account/session/data remain intact. Record APK source run, app version, package/signing evidence.
- [ ] From `文件`: normal `打开现有功能` still opens complete legacy File Station; exercise a known existing operation only if safe, no destructive testing necessary.
- [ ] Choose `试用新版文件浏览（测试）`: display real shared roots; enter nested folders, ancestor breadcrumb and Back; check exact Unicode/space names and ordinary file/folder distinction; verify >100 items if user has a suitable folder.
- [ ] Toggle list/grid, change sort direction and key, scroll/load more, refresh. Select two distinct files, toggle layout/sort, verify same paths remain selected; select loaded items and exit selection; check Android Back precedence.
- [ ] Toggle Light/Dark, switch to other tabs and return, resume from background. Test a safe offline failure (turn off LAN/Wi-Fi briefly) and reconnect without losing prior complete data. Real authentication invalidation/second-account case may be `NOT TESTED` when setup unavailable; corresponding unit/relationship tests still required.
- [ ] Verify notification entry and absence of a new normal file-open/copy/delete/upload/preview button in test surface. Confirm Task 7B/7C flows still available in existing legacy Files page.
- [ ] User feedback records explicit `PASS`, `FAIL` or `NOT TESTED` per concrete behavior. No blanket “all tested” for skipped scenarios; nonessential untested scenarios do not by themselves block next stage unless contractual/core-risk.
- [ ] On failures, fix only Task 7A contract violations through a scoped corrective follow-up. Repeat targeted tests/CI and impacted device checks; do not implement Task 7B/7C opportunistically.

### Task 5.5 — Task 7A closure, handoff and stop

- [ ] Finish `batch-5-acceptance.md`: automation and device evidence separately, untested inventory, frozen source diff, tested APK SHA, residual Task 7B/7C handoffs.
- [ ] Update Master Plan Task 7A status only after Gate evidence; retain 7B/7C as **not started**. Commit docs-only, re-fetch remote HEAD/commit details and compare changed-file scope.
- [ ] Prepare PR proposal only **on explicit instruction**. Merge to `modern-ui` only after required real-device Gate and explicit approval. Final recheck remote merged SHA/CI if merge is authorized.
- [ ] **STOP after B5/Task 7A; never start Task 7B, Task 7C or Task 8 automatically.**

**B5 / Task 7A Exit Gate:** Complete and demonstrably safe read-only Modern browse in a secondary opt-in preview, stable selection and navigation, normal existing Files operation handoff retained, targeted + full New UI regressions and signed APK evidence, real-device results recorded, 7B/7C deferred.

---

## Execution Order and Independent Approval Gates

```text
Reviewed Task 7A Feature Design + 18-row Contract Matrix
    ↓
B1  Compatible FileStation paging + typed read adapter
    ↓       [B1 acceptance + explicit instruction to continue]
B2  Controller / pagination / path / generation / stale
    ↓       [B2 acceptance + explicit instruction to continue]
B3  Modern browse page / breadcrumb / list-grid / sorting
    ↓       [B3 acceptance + explicit instruction to continue]
B4  Stable selection, reconciliation and Back
    ↓       [B4 acceptance + explicit instruction to continue]
B5  Optional Files preview entry / shell + real device Gate
    ↓       [B5 device acceptance + explicit PR/merge instruction]
Task 7A closure on branch → PR/merge on authorization
    ↓
Task 7B remains NOT STARTED
```

The strict dependency is B1→B2→B3→B4→B5. Every Batch must carry a remote SHA, a concise acceptance document and a known unchanged baseline. Use short-lived reviewable commits, not a permanently open PR that rebuilds the same incomplete feature after every doc change.

## Plan Self-Review / Coverage

- **Data:** `DATA-01/02/04` → B1; `DATA-03` → B1 wire + B2 pagination; `DATA-05/06` → B2; downstream UI/relationship proof B3/B5.
- **Navigation:** `PATH-01` → B2 verified ancestors + B3 widget routing; `PATH-02` → B3 route/Back + B4 selection Back + B5 shell.
- **View/preferences:** `VIEW-01/02` → B3, repeated selected-state and dark/light tests B4/B5.
- **Selection:** `SEL-01/02/03/04` → B4, relationship regression B5.
- **State:** `STATE-01` → B1 invalid envelope, B2 typed phases and callback, B3 presentation, B5 A→B/network relationships.
- **Shell/cutover:** `SHELL-01/02` and `CUTOVER-01` → B5 only, with legacy still default.
- **Review Focus:** five cases above have explicit owner tests at B1/B2/B3/B4/B5; none rely solely on real-device observation.
- **No speculative dependency:** no new SDK, auth service, database migration, production tab replacement, upload/download/preview handler or background task polling.
- **Known testing limitation:** GitHub Actions—not this plan's authoring session—must supply executable Flutter RED/GREEN/CI evidence if a local Flutter runtime is unavailable.
- **Approval boundary:** **This document is a plan only.** No Task 7A Batch has been executed by writing it. The next step requires user review of this Batch Plan and a separate instruction naming **B1**; never default to B2.
