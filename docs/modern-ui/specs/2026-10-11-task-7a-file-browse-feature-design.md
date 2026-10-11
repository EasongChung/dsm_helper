# DSM Helper Modern UI — Task 7A File Station Browse Foundation Feature Design

> Status: **Preflight technically reviewed; feature boundary frozen for a later separately authorized Batch plan — no Batch plan or implementation started**  
> Date: 2026-10-11  
> Task: **7A — File Station: Browse Foundation**  
> Work branch: `feature/t7a-file-browse`  
> Audited integration baseline: `modern-ui@b80a59c61ca3baf07201478637deaa61a181c6a4`  
> Design route: **Thin browse adapter + context-scoped state + progressive File Station migration**

## 1. Purpose, success and authority

Task 7A establishes the Modern Material 3 **browse foundation** for DSM File Station: shared-folder root, folder listing, directory navigation, breadcrumb, list/grid, sorting, and stable selection. It does **not** rebuild DSM transport, mutate remote files, implement transfers, or replace the complete existing File Station in the production tab.

The product must remain usable throughout migration. Existing, already-functional legacy File Station is the primary complete feature until the Task 7B/7C operation and preview handoffs are ready and the corresponding real-device gate is accepted.

Inherited authority (do not copy/redefine):
- `docs/modern-ui/2026-10-06-dsm-helper-modern-ui-master-plan.md` — scope, branch, merge, legacy freeze, CI, T7A→T7B→T7C and final cutover.
- `docs/modern-ui/specs/2026-10-07-dsm-helper-modern-ui-spec.md` — section 12 File Station, section 8 context/resume, section 9 App Bar, sections 18–20 state, section 23 Back, section 30.6 selection.
- `docs/modern-ui/specs/2026-10-07-dsm-helper-modern-ui-visual-design.md` — Material 3 colors, density, title/row, list/grid, Bottom Sheet, system insets and theme.
- `docs/modern-ui/contracts/2026-10-07-global-contract-matrix.md` — especially `G-SESS-01`, `G-NAV-01/02/03`, `G-STATE-01`, `G-NET-01`, `G-THEME-01/02`, `G-LEGACY-01`, `G-FILE-01`, `G-NOTIFY-01`, `G-ANDROID-01/02/03`, `G-PREF-01`.
- `docs/modern-ui/contracts/2026-10-07-global-interface-protocol-inventory.md` — `SYNO.FileStation` models, session/legacy boundaries.
- Task 3–6 accepted shell/context/auth/dashboard/application wiring; `APK-IDENTITY-01` and `CI-DOCS-01`.

Task 7A adds only the feature-specific decisions below. Conflicting global semantics require explicit amendment of the global authority, not a quiet local override.

## 2. Repository facts audited (source rather than assumptions)

| Capability | Actual code authority | Verified constraint |
| --- | --- | --- |
| Shared-folder root | `lib/models/Syno/FileStation/FileStationList.dart::FileStationList.shareList` | `SYNO.FileStation.List/list_share` v2; sends `offset:0, limit:100`; decodes `shares` into `FileItem`. |
| Folder listing | same file: `FileStationList.fileList(path:...)` | `SYNO.FileStation.List/list` v2; sends `offset:0, limit:100`, path, sort parameters and additional fields; decodes `files`. |
| Result metadata | `FileStationList` and `FileItem` | Exposes nullable `files`, `offset`, `total`; individual `path`, `name`, `isdir`, nullable `additional` (size/time/perm/type). A missing response array is **not** proof of a successful empty directory. |
| Optional listing families | `favoriteList` and `virtualFolder` | Present in legacy model; not part of the 7A primary share→folder browse path. No blanket migration claim. |
| Existing preferences | `lib/pages/file/file.dart::FilesState.initState` | `SpUtil` keys `file_list_type`, `file_sort_by`, `file_sort_direction`. |
| Existing sorts | `lib/pages/file/enums/sort_enums.dart` | name, size, type, mtime, ctime, atime, posix, user, group; ASC/DESC; model defaults to lowercase `asc`. Verify server compatibility; do not assert case equivalence merely from code. |
| Legacy directory routing | `lib/pages/file/file_page.dart`, `lib/pages/file/file.dart::goPath`, `setPaths` | Nested Navigator; directory pages are pushed; path logic includes ordinary shares and paths with a URI-like `scheme://` form. |
| Legacy selection | `lib/pages/file/file.dart::FilesState` | `List<FileItem> selectedFiles` and `contains(file)` use object instances; no stable path identity guarantee over refresh/replacement. |
| Legacy file opening | `FilesState.openFile` and existing preview/editor/media flows | Real preview/file handling exists **only inside legacy UI flow**; it is not a reusable Task 7A public preview service. |
| Modern shell | `lib/new_ui/app/dsm_new_ui_shell.dart`, `new_ui_app_shell.dart`, `new_ui_shell.dart` | Five tab stacks; Files still uses `NewUiPrimaryPage` placeholder to open `LegacyPageHost(FilePage)`. No `lib/new_ui/files/**` yet. |
| Legacy handoff | `LegacyPageHost` + `DsmProviderScope` | Preserves legacy theme/context and Back route boundary. |
| External share / transfer | `ExternalIntentListener`, `_handleIntent`, `Upload`, `Transfer` | Existing upload/download routing remains; out of scope for 7A. |

These observations are from inspected source in the audited integration commit. They are **not** evidence that arbitrary file counts, DSM permissions, remote mounts, or special-server paths have been physically tested on a real NAS.

## 3. Architectural options and selected preflight direction

**A. Copy `FilesState` into Modern UI:** fastest apparent port, but duplicates its 1,745-line coupling of browse, file operations, previews, transfer, floating media and navigation; preserves identity/pagination defects. **Reject.**

**B. Replace DSM File Station model/transport with a new SDK/repository:** can solve pagination in one abstraction but violates legacy-first reuse and creates unnecessary transport authority. **Reject.**

**C. Thin browse adapter over the existing `FileStationList` + a small Modern state owner:** reuse DSM model/session and shared shell; expose backward-compatible paginated calls only if needed; keep browse state, path, selection and last-valid snapshots together. **Select.**

Responsibility boundaries:
- **Browse data adapter**: invokes existing `FileStationList.shareList/fileList` with active DSM session; maps success, typed failure and pagination; never owns credentials/HTTP stack.
- **Directory-route-scoped browse controller/state**: each Files-tab directory route owns its own current directory, last-valid snapshot, paging, error/refresh metadata, selection and request generation. A child route uses the existing Files-tab Navigator; on forward navigation the previous route invalidates outstanding requests and clears selection, while its completed browse snapshot can be restored on Back. Account-switch remount clears all routes/controllers.
- **Modern File Station browse UI**: Material 3 list/grid, row metadata, breadcrumb, refresh, selection interaction; no DSM request logic inside widgets.
- **Existing Shell and legacy**: owns tab navigator, theme, global notification/action budget, account switch and complete feature fallback.

New units belong under `lib/new_ui/files/**` with focused tests under `test/new_ui/files/**`. Existing model additions, if a proven minimal blocker, must remain backward compatible; do not rewrite `lib/pages/file/**`, `lib/apis/**`, `lib/database/**`, providers or Shell unnecessarily.

## 4. Task boundary and progressive delivery

### 4.1 Included in Task 7A
1. Shared-folder root and child folder read-only listing.
2. Exact DSM returned folder path navigation, clickable ancestors and compact breadcrumb; Android Back relationship.
3. Pagination sufficient to reveal all returned accessible items rather than silently cap at 100.
4. Compact list as default, optional grid, existing sort choices and persistent display preferences.
5. Enter/exit selection mode, stable full-path selection identity, toggle, select-all, refresh reconciliation, Back priority.
6. Loading/empty/stale/offline/error/auth-invalid distinctions and stale-request suppression.
7. Opt-in Modern browse preview/test entry reachable from the existing Files placeholder and its scoped device gate; **no production Files tab cutover**.

### 4.2 Out of scope
- Task 7B: search; rename, delete, create-folder or other mutations; favorite/share management; copy/move; selection operation dispatch and risk confirmation.
- Task 7C: Android/DSM upload/download, media/image/video/text/PDF preview/open, background tasks, external share destination modernization.
- Task 8: transfer overview and transfer settings.
- Virtual folders, special remote-mount management, share-link management and File Station feature expansion not proven necessary for the share→folder browse flow.
- Legacy cleanup, auth/session redesign, app-wide navigation rewrite, new preference authority, desktop/tablet layout, unrelated UI changes.

**File tap/long-press completeness:** in the final product, the Project Spec requires file tap to open and long-press to expose contextual operations. 7A does not pretend these operations are implemented. Its isolated test surface may browse/select file rows but must neither display dead operation buttons nor claim to replace the fully functional legacy page; the production Files entry stays legacy. The full behavior is a 7B/7C handoff and cutover dependency. Share-root rows are navigation-first; do not manufacture unsupported share-root destructive actions in 7A.

### 4.3 Cutover gate
Do not change the existing Files destination into the incomplete Modern browser in 7A. For real-device verification, extend only the existing Files **placeholder** with an explicitly secondary, clearly labeled `试用新版文件浏览（测试）` action alongside its existing primary `打开现有功能` legacy handoff. That action pushes the Modern browser into the **existing Files tab Navigator** and returns to the same placeholder on Back; it is not a new bottom-navigation destination, a new nested primary Navigator or an automatic default entry. Any required shell/placeholder callback wiring must be minimal and must leave the original legacy route the normal complete-feature entry. Final production cutover remains deferred to the Task 7C completion gate specified in the Master Plan, or an explicitly approved equivalent complete handoff.

## 5. Directory and path semantics

- Root is a distinct state represented by the existing `shareList` call; it is **not** a guessed DSM physical filesystem path. A returned shared folder’s exact `FileItem.path` becomes the child listing request path.
- An ordinary folder’s exact `path` returned by DSM is the next request path. Folder names/indices/`real_path` are not navigation IDs.
- Every displayed breadcrumb ancestor must map to an exact verified navigable ancestor, including returning to the root. If a `scheme://` remote mount path cannot be safely decomposed into a tested ancestor, do not fabricate clickable intermediate components; preserve full readable path and provide verified Back/root navigation.
- Within a NAS context, pushing a child folder route clears the departing directory's selection by default (`G-FILE-01`) and invalidates its ongoing requests. Ordinary Back restores the **previous route's already valid browse snapshot**, without restoring its old selection. A breadcrumb ancestor jump pops back to the verified corresponding route; no duplicate route stack or guessed parent path is created.
- Android Back priority: active popup/IME → selection mode → current nested directory route → current primary tab/root exit policy. Do not consume Back through an independent competing nested Navigator.
- Primary tab switches preserve that tab’s in-memory nested directory/navigation state during ordinary app resume. Cold start returns to shell root, and account/NAS switch destroys prior NAS directory, file cache and selection (`G-NAV-02/03`).

## 6. Listing, pagination and sort semantics

- Default page size inherits the existing model’s `limit=100`, but 7A must **not stop at the first page** when more records exist. Prefer adding optional `offset`/`limit` to existing `shareList/fileList` (default `0/100` for all legacy callers), with no change to DSM API/response parsing authority. Load the first page promptly, then incrementally request subsequent pages on approaching the visible list end (with an explicit Retry/Load More affordance for failures); do **not** eagerly download an arbitrarily large NAS directory in one unbounded loop.
- Request success means a structurally valid result; `files=[]` with completed, valid listing is genuinely empty, while missing/invalid data, transport failure or DSM error is an unavailable/failed result, never silently coerced to empty.
- Aggregate distinct DSM item paths within one directory+sort+context generation across pages; avoid duplicates from repeated/overlapping responses without silently pretending a broken result is complete. A previously completed snapshot and an in-progress new listing are separate versions: keep the prior snapshot visible (marked refreshing/stale) until a valid new page can be shown, never interleave rows from different sorts or generations.
- Use server-reported `total` and `offset` when valid; absent `total` may use page-length termination with progress and repeated-page guards. Stop when a consistent `total` is reached or a short terminal page proves the end; do not impose a silent maximum-file cap. Non-advancing offset, zero new unique items on a full repeated page, invalid/contradictory total, or non-progress is a recoverable **partial/incomplete listing failure**, never infinite looping or a false complete count. If an older fully valid snapshot exists, keep it visible as stale; otherwise show only accumulated valid partial rows with an explicit incomplete/Retry label.
- A new directory, sort choice or DSM context invalidates previous in-flight page requests. Ignore late results/errors for inactive generations; do not append A/sort-old pages into B/sort-new.
- Preserve server sort authority. Keep the supported legacy `SortByEnum` keys and direction semantics; **confirm actual request spelling/casing and supported fields** before final code. Do not invent client-side folder grouping or a second independent sorting algorithm. Sorting invalidates/reloads pagination for the same path while preserving selection by path when entries remain.
- Use existing `SpUtil` keys `file_list_type` (list/grid), `file_sort_by` and `file_sort_direction`. Invalid saved values resolve to existing enum defaults without erasing unrelated preferences. Preference write failures must not corrupt active DSM/session state.

## 7. File identity, selection and visibility

- **Stable identity**: within one active DSM context, the exact non-empty `FileItem.path` returned by the canonical listing identifies a file/folder for selection. Do not key by object instance, index, name, thumbnail URL or `real_path`. The active context boundary is explicit; the same literal path in another NAS account is a different logical identity.
- Deduplicate path collisions in a page aggregation without guessing that two different paths with the same name are the same file.
- Selection mode is per **ordinary file directory**. Shared-folder root entries are navigation-only in 7A (legacy does not expose the same ordinary file-operation selection there). In a file directory, normal-mode horizontal swipe on a selectable row/tile enters mode and selects that item; normal-mode folder taps navigate. In selection mode taps toggle; repeat swipe is not required.
- Entrance gestures must respect Android system Back and not hijack breadcrumb horizontal scrolling. Implement/test both list and grid target hit areas. Normal-mode long-press action behavior stays with later Task 7B; do not silently repurpose it into a contradictory operation.
- Selection header shows explicit exit, count and select-all. No permanent checkbox gutter or layout jump; selection is full-row/tile restrained tonal emphasis.
- Switch list↔grid or change sort: selected paths remain selected across reordered/recreated `FileItem` objects. When a **fully valid fresh listing** confirms a selected path no longer exists, remove that path. While refresh is pending, failed, or listing is partial/incomplete, preserve prior selection and label data stale; do not infer deletion from an incomplete set.
- Select-all means all **currently loaded, selectable items in the current directory**, not all unseen DSM pages. During incomplete pagination, label it **“已加载项全选”** and select only the current loaded snapshot; subsequently fetched items are not automatically selected. At complete load, label it “全选” for the complete listing. The selected count always reflects the selected path set (even if some paths are not yet present in the newest partial sort page); never claim that unseen items were selected. Selection remains local until a later task executes an explicit operation.
- Leaving selection via Back/exit clears it; changing directory or switching context clears it. No operations execute merely by selecting a file.
- Rows with unusable/missing `path` cannot be selected/opened; preserve a readable row/error indication without crashing.

## 8. Read-only data state and failure semantics

The feature tracks distinct states: **initial loading**, **valid loaded nonempty**, **valid loaded empty**, **refreshing existing valid**, **stale after failed refresh**, **partial/incomplete pagination**, **offline**, **permission/API unavailable**, and **auth invalidated**.

- On refresh, keep existing valid items and selection until a valid newer result replaces/reconciles them. A failed request leaves the last valid directory visible with stale/error feedback and a Retry path.
- A successful empty listing is not interchangeable with permission denial, missing response array, offline or pagination failure.
- Transport failure (Dio/network/timeout) is **not** logout/119. Real DSM auth-invalid (observed 119) delegates to established Task 4/Task 5 reauth authority; do not create a new auth coordinator or throw away persisted credentials.
- If a directory has never loaded successfully and the first request fails, show a readable error/Retry state, not a fake empty directory. If a user navigates away during load, old late errors do not appear in the new directory.
- Context switch from A→B clears all A snapshots first. Persistent *presentation* preferences can remain app-local, but no A path/file/selection/error leaks into B.
- Nullable owner/time/size/permission fields do not crash rendering or produce invented metadata. Root share rows need not show per-file size when unavailable.
- Refresh is user-initiated via normal pull-to-refresh / appropriate contextual action; no 7A-specific background polling loop or duplicate automatic-refresh authority.

## 9. Visual and navigation implementation guardrails

- Modern compact **list-first**, grid optional; file icon/thumbnail only where an audited existing safe source exists. No per-file Card or permanent overflow and no permanent empty checkbox gutter.
- List row: max two lines for primary name, one compact secondary line for valid size/time/type; gracefully omit missing fields, respect larger system fonts and 48dp targets. Task 7A uses available local file-type icons; do not introduce remote SID-bearing thumbnail URLs or preview loading before Task 7C. Do not reuse legacy `GlassScaffold`/`GlassAppBar` as Modern visual authority.
- Compact breadcrumb below App Bar; ellipsis may collapse older ancestors without losing reachable verified ancestors.
- Global notification entry and connection status use established App Bar semantics; only one high-frequency page-specific direct action (search is not implemented in 7A, so do not add a dead Search button). Sort/grid/refresh belong in overflow/Bottom Sheet when not pull-to-refresh.
- Normal data refresh and selection must not rebuild the entire shell, switch tabs or reset an unrelated tab. Light/Dark must use existing Modern tokens, maintain contrast and actual Android safe insets.
- During temporary selection mode, a selection App Bar may replace normal global actions as allowed by the project spec.

## 10. Required proofs before implementation may be declared accepted

**Pure/controller**: empty vs failure; 0/100/101/250+ items; offset progression, short page, duplicate/repeated page/invalid total; changed sort during fetch; A→B during fetch; path identity on rebuilt model objects; duplicate names; metadata nulls; successful-refresh pruning vs failed/partial retention; invalid persisted view/sort.

**Widget**: root and nested directory, breadcrumb ancestors, list/grid with long Unicode names and large font, light/dark, selection swipe/toggle/all/clear, no checkbox gutter, normal App Bar notification behavior, loading/stale/permission/empty differences.

**Relationship**: File child route Back and selection Back precedence; tab switch/resume route preservation; context-switch A→B reset; startup offline; explicit secondary test-preview entry available from Files placeholder while the original `打开现有功能` remains the default complete route; existing external-share and transfer routing unmodified.

**CI**: targeted `flutter test`, targeted `flutter analyze lib/new_ui test/new_ui`, Android beta debug APK, artifact and stable package/signature checks on any code-bearing batch. Docs-only preflight follows `CI-DOCS-01` and requires no redundant APK build.

**Real device**: HTTP LAN DSM scope with real shared folders and nested paths, a folder with >100 entries if available, sort/list-grid/selection/Back, failed/offline refresh and non-destructive verification. Record any environment unavailable as **NOT TESTED**, not PASS. Do not require unrelated 2FA/HTTPS/second-account physical tests without a demonstrated current blocker.

**Stage-specific Gate**: 7A success means Modern browse foundation is demonstrably correct in an isolated route while production Files fallback remains complete. It does **not** mean 7B/7C features or File Station full cutover are finished.

## 11. Preflight gap disposition

| Gap | Finding | Resolution at design level | Blocking? |
| --- | --- | --- | --- |
| `T7A-GAP-01` listing capped at 100 | Both public listing calls are fixed at `0/100` | Backward-compatible optional pagination parameters on existing authority; paged aggregation and stop/retry guards. | **Must resolve in 7A implementation**, not a reason to rewrite SDK. |
| `T7A-GAP-02` selection instance equality | Legacy `contains(file)` is not stable across replacement | Context-scoped exact DSM path key; reconciliation on complete success only. | **Must resolve in 7A**. |
| `T7A-GAP-03` nested navigation vs shell | Legacy and modern tab both have navigator layers | Reuse Task 3 tab stack; breadcrumb derived from safe verified paths; modal/selection Back priority. | **Must resolve in 7A**. |
| `T7A-GAP-04` weak load/empty/error state | Legacy `loading/success` cannot encode partial, stale, 119 | Small typed browse state and request-generation guard; reuse global auth/network rules. | **Must resolve in 7A**. |
| `T7A-GAP-05` incomplete file-open and action destination | Preview/operation wiring belongs to later tasks | Keep production Files legacy until later fully integrated cutover; do not ship dead action affordances. | **Nonblocking for isolated 7A; blocks final cutover**. |
| `T7A-GAP-06` remote/special path parsing | Legacy supports `scheme://` paths; blindly splitting on slash is unsafe | Preserve exact DSM path; expose only verified navigable ancestors, fallback Back/root. | **Must test for cases 7A claims to support**; unsupported optional remote mount family deferred. |
| `T7A-GAP-07` sort casing/DSM capability | Legacy sends uppercase direction enum; model default lower-case | Verify against existing request patterns and, if needed, real DSM before freezing code spelling. No hard-coded unverified equivalence. | **Code-execution audit gate**, not a product ambiguity requiring new architecture. |

**Preflight review outcome (2026-10-11):** Source-based technical and cross-contract review completed; feature scope and proposed boundary are frozen **for future planning only** under the user's instruction to continue the approved preflight process. This records delegated continuation, not a claim that the user individually inspected every clause or that device testing was performed. The user's earlier **“先不拆batch”** instruction remains binding: no Batch Execution Plan, Task 7A implementation, APK build or integration merge is authorized by this preflight review. A later **explicit** request is required to begin Batch planning.
