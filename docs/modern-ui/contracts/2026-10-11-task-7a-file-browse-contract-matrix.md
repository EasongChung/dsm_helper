# DSM Helper Modern UI — Task 7A File Station Browse Contract Matrix

> Status: **Preflight draft for user review — not implementation authorization**  
> Date: 2026-10-11  
> Task: Task 7A — File Station: Browse Foundation  
> Branch: `feature/t7a-file-browse`  
> Audited integration base: `modern-ui@b80a59c61ca3baf07201478637deaa61a181c6a4`  
> Feature design: `docs/modern-ui/specs/2026-10-11-task-7a-file-browse-feature-design.md`

## 1. Contract scope and inherited precedence

This matrix refines only **browse/read state, navigation, list/grid/sort and selection**. It does not replace the global matrix, the DSM model contract or Task 7B/7C operation semantics.

Binding global rules: `G-DSM-01`, `G-API-01`, `G-SESS-01`, `G-NAV-01/02/03`, `G-STATE-01`, `G-NET-01`, `G-THEME-01/02`, `G-LEGACY-01`, `G-FILE-01`, `G-NOTIFY-01`, `G-ANDROID-01/02/03` and `G-PREF-01`. Project Specification and Visual Design Specification remain higher-level authorities; Task 7A may refine but not redefine their invariants.

**Authority classification:** `FileStationList` and the active `Api.dsm` context own DSM data/transport; Task 3/4 Shell owns global navigation and session; `SpUtil` existing keys own view/sort persistence; a new `lib/new_ui/files/**` adapter/controller owns only Modern browse/pagination/selection state. Feature code must not issue an independent Dio/HTTP client, persist a second SID, or rewrite the legacy operation UI.

## 2. Feature contract rows

| ID | Operation / preconditions | Existing authority / input | Required delta and invariant | Unchanged / failure semantics | Executable proof |
| --- | --- | --- | --- | --- | --- |
| **T7A-DATA-01** | Enter File root with active DSM context | `FileStationList.shareList` → `SYNO.FileStation.List/list_share` v2 | Load DSM shared-folder rows; root is a distinct virtual navigation level, not a guessed OS path. Only a structurally valid empty response renders “无共享文件夹”. | No write, no extra API/session authority; network/API failure is not empty. | Root success/empty/error fixtures; verify exact API method and context. |
| **T7A-DATA-02** | Open a returned readable folder | `FileStationList.fileList(path: ...)`, full `FileItem.path` | Request child listing using exact path supplied by DSM; publish only for current path/context/request generation. | Null/invalid path cannot trigger a guessed request; permission denial shows local error/Retry. | Root→share→subdir; exact path assertions; invalid path fixture. |
| **T7A-DATA-03** | Root or folder has more than one page | Existing `shareList/fileList`, `offset`/`total`, default `limit=100` | Add only backward-compatible optional pagination input where necessary; fetch beyond 100, aggregate unique DSM item paths, respect valid totals and short terminal pages. | Existing callers retain 0/100 defaults. Invalid/non-advancing/repeated page never loops or produces “complete list”; retain partial rows with explicit incomplete/Retry state. | Sizes 0, 1, 100, 101, 250; offsets 0→100→200, duplicate/repeated/missing-total/invalid-total fixtures, bounded termination. |
| **T7A-DATA-04** | Receive listing envelope and nullable file fields | `FileStationList.fromJson`, `FileItem` and `additional` | Distinguish a valid `files=[]`/`shares=[]` response from missing/invalid arrays; render names and only available metadata. | Never coerce malformed payload, null path, null time/size or permission denial into “empty” or crash. | Empty-vs-malformed assertions, nullable owner/time/size/path, long Unicode names. |
| **T7A-DATA-05** | Request fails after prior valid load | Existing DSM exceptions/Dio; `G-STATE-01` | Retain last valid directory snapshot and selection; surface refresh failure/stale/offline and retry. | No stale response may overwrite newer path; network failure cannot clear saved SID or force logout. | V1→refresh fail→V1 stale→V2 success; timeout preserves credentials. |
| **T7A-DATA-06** | New directory/sort/context starts while older request remains active | Current-context key; request-generation guard in new browse controller | Discard every late page/success/error from prior generation; no cross-directory, cross-sort or cross-NAS mutation. | Unrelated tabs/routes/prefs unaffected. | A path slow→B path fast→A returns; change sort mid-page; context A→B while A request pending. |
| **T7A-PATH-01** | Breadcrumb and parent navigation | Actual visited DSM `FileItem.path`, current tab Navigator | Display current path, verified ancestors and root, support ancestor jump/Back; keep share root separate from ordinary folder path. | No lossy split/normalization of `scheme://` or special path; unverified ancestors not clickable. | Ordinary share/path ancestor test, scheme-like path fixture, Back to root. |
| **T7A-PATH-02** | Back from nested browse/selection and tab switching | `NewUiShell`/`G-ANDROID-01` and temporary selection state | Dismiss popup/IME → exit selection → pop directory → shell root/exit policy; switching tabs and ordinary resume preserve current Files route. | Never pop another tab or duplicate a nested global navigator. | Selection+directory Back order; tab A→Files subdir→B→Files same subdir; resume with gate. |
| **T7A-VIEW-01** | Render loaded result in list/grid | Task 2 Visual Spec, `FileItem` and available icon metadata | Medium-high-density list default; optional grid with equivalent browse/selection; row name max 2 lines, one valid metadata line, appropriate 48dp target; no per-file Cards or always-visible overflow. | No full legacy page/Glass styling copied into Modern UI; missing optional metadata omitted. | Light/Dark, list/grid, long labels, large fonts, null metadata, empty state widget tests. |
| **T7A-VIEW-02** | Change sort or view preferences | Legacy enums and `SpUtil` keys `file_list_type`, `file_sort_by`, `file_sort_direction` | View toggle preserves current directory/selection; sort resets pagination for same path and preserves selected paths that remain; valid preferences restored after rebuild. | No second persisted key family; avoid unverified sort-direction casing changes; invalid saved values use known legacy defaults. | Preference round-trip, corrupt preference, emitted sort args, sort→refresh→stable selection. |
| **T7A-SEL-01** | User enters selection from ordinary file-directory list/grid | `G-FILE-01`, exact nonempty DSM `FileItem.path` in current context | In file directories, horizontal row/tile swipe enters selection and selects item; tap in selection toggles by stable path, not object instance/index/name. Shared-folder root entries remain navigation-only in 7A. | Do not steal breadcrumb/system Back gestures; selection alone never invokes remote operation or root-share mutation. | Both view modes; rebuilt FileItems with equal paths; duplicate names/different paths; null-path item; no root-share swipe selection. |
| **T7A-SEL-02** | Selection persists across in-directory presentation changes | Controller key: current NAS context + current directory + exact path | Sort, reorder and list/grid toggle preserve selected exact paths; no permanent checkbox gutter/content jump. | No stale selected status borrowed from another directory or NAS. | A,C selected→sort/rebuild/grid→A,C; same name in other directory not selected. |
| **T7A-SEL-03** | Refresh/partial result after selection | Valid fully loaded directory result vs failed/incomplete result | Fully successful latest snapshot prunes missing paths; refreshing/failed/incomplete results retain previous selection and identify incomplete data. | Never infer remote deletion from partial pagination/network loss. | Select A,B,C→full refresh A,C keeps A,C; failed/partial refresh keeps A,B,C. |
| **T7A-SEL-04** | Select-all and exit selection | Loaded directory item set, current selection header | Header provides explicit exit/count/select-all. Select-all covers exactly the loaded valid items; if page loading continues, disable global action or explicitly label loaded-only. Back/exit/directory change clears selection. | Do not imply select-all includes unseen remote files; no empty action buttons for unimplemented 7B/7C commands. | 250-item pagination with pending page; select-all count; Back/exit; directory/context reset. |
| **T7A-STATE-01** | Loading, empty, offline, permission and auth error | `G-STATE-01`, `G-NET-01`, existing Task 4/5 session callback | Render distinctly: initial loading; real empty; refreshing; stale; partial/incomplete; offline; permission/API unavailable; verified DSM 119 reauth. | Timeout/403-equivalent *permission* is not assumed to mean 119; no implicit credential deletion or false empty list. | Matrix fixtures for each outcome and 119 vs generic DSM error vs Dio. |
| **T7A-SHELL-01** | Display in modern shell and fallback | Existing `NewUiAppShell`, `LegacyPageHost`, `DsmProviderScope`, `G-NOTIFY-01` | Modern preview uses inherited theme, session and global notifications; legacy Files remains complete and usable. App Bar respects one global notification + at most one feature direct action. | Production Files primary destination is **not replaced** in Task 7A; existing Upload/Transfer/external share handlers unchanged. | Preview/legacy open/back, light/dark isolation, notifications, ensure production Files still opens original route; source diff guard. |
| **T7A-SHELL-02** | Device/account switch A→B | `G-NAV-03`, active context coordinator, keyed provider subtree | Destroy A browsing routes/cache/selections and return Overview for B; B requests use B context only. | Ordinary tab switch/resume does not behave like context switch; app-local view/sort prefs remain. | A/B fake accounts with same path, in-flight A result, switch B, assert only B rows and root navigation. |
| **T7A-CUTOVER-01** | End-of-7A acceptance | Master Plan Task 7A/B/C boundaries | Accept independently testable isolated browse only, with verified real-DSM scope; operations/preview still provided by legacy primary feature until 7B/7C and later approved cutover. | No Task 7B/7C code, no new primary-tab substitution, no false full-feature PASS. | Files tab legacy route still accessible; new browse preview working where tested; diff scan confirms no 7B/7C additions. |

## 3. Explicit cross-feature handoff matrix

| Behavior / UI entry | Task 7A | Task 7B | Task 7C or later |
| --- | --- | --- | --- |
| Share-root and folder reads, breadcrumb, sort, list/grid | **Own** | Reuse | Reuse |
| Path-based selection mode, count/select-all, Back | **Own foundation** | Attach valid file operation actions | Attach download/other transfer actions |
| Normal tap on file / open preview | **No new handler**; legacy production path continues | No new preview authority | Own complete file/open/preview handoff |
| Long-press/contextual file actions | **Do not create dead menu** | Own operation sheet, permissions, mutation confirmation | Extend with relevant preview/transfer actions |
| Copy/move/rename/delete/share/favorite/search | Excluded | **Own** | Reuse where needed |
| Upload/download/background tasks/external intent destination | Existing legacy integration unchanged | No rewrite | **Own/finish** |
| Production Files root cutover | **Not permitted in 7A** | Not implicitly authorized | Only after feature completeness and real-device approval |

**Selection UI staging**: the Project Spec’s normal completed-file-manager selection footer contains file operations. 7A is not a complete file manager. The staging UI must implement the selection **mode**, but must not show non-working copy/move/download buttons. Task 7B/7C add these actions before the final product cutover.

## 4. Resolved design questions / deferred verification

| Gap ID | Status at preflight | Required handling |
| --- | --- | --- |
| `T7A-GAP-01` fixed 100 limit | **Scoped implementation issue** | Backward-compatible pagination addition to `FileStationList` as required by `T7A-DATA-03`; no new transport. |
| `T7A-GAP-02` object-instance selection | **Resolved by proposed feature contract** | Exact context+path selection and complete-refresh-only pruning. |
| `T7A-GAP-03` Shell/legacy double navigator | **Resolved by proposed feature contract** | Use existing Modern tab navigation; no independent primary shell. |
| `T7A-GAP-04` empty vs error | **Resolved by proposed feature contract** | Typed per-directory state and request-generation exclusion. |
| `T7A-GAP-05` operations/preview unavailable in 7A | **Deferred non-blocking for 7A; blocks cutover** | Keep production legacy Files route and its operations. |
| `T7A-GAP-06` special/remote path representation | **Constrained** | Exact-path navigation, verified ancestors only; unverified optional virtual/remote mount features remain outside 7A. |
| `T7A-GAP-07` actual sort-direction values | **Implementation-time interface audit required** | Test actual produced parameters and real DSM behavior where available; do not silently canonicalize the legacy string. |

**No unresolved product-choice gap is identified that requires redefining global File Station behavior before 7A can be planned, assuming the user approves this design.** The known technical issues are explicitly owned by 7A implementation; deeper operation/preview gaps belong to 7B/7C, not to this preflight.

## 5. Exit criteria for preflight review (not a Batch)

- [x] Compared 7A scope against current Master Plan, Project Spec, Visual Spec, global contracts and Task 3–6 shell/fallback.
- [x] Audited actual File Station models, legacy browse/navigation/selection, existing sorting keys, Modern Files placeholder, context and legacy handoff.
- [x] Chosen minimum-change browse architecture, path identity, paging and failure behavior.
- [x] Explicitly separated Task 7A vs 7B vs 7C/8 and protected the legacy production entry.
- [x] Every new proposed feature contract has an observable test target.
- [ ] **User has reviewed and approved this design + matrix.**

**Until the final review checkbox is satisfied:** do not mark Task 7A as completed, write a Batch Execution Plan, implement feature code, trigger avoidable APK builds, open an integration PR or merge to `modern-ui`. A documentation-only preflight commit on the isolated Task 7A branch is permitted and expected.
