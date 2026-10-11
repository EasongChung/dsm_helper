# Task 6 — Applications Hub + Settings Shell Final Acceptance

> Result: **PASS — Task 6 Batch 5 / Task 6 complete**  
> Recorded: **2026-10-11**  
> Repository: `qyxx2/dsm_helper`  
> Work branch: `feature/t6-applications-settings`  
> Integration target: `modern-ui`  
> Final CI-verified implementation SHA: **`b7ec45c31147bb39c9de9bffe38697de93f5bfed`**  
> Pre-closure documentation HEAD: `4e71b3bbaaa29ade4ddf1b9cda1ae9f95fac3a94`  
> Documentation-only closure is exempt from a duplicate APK build under `CI-DOCS-01`.

## Authoritative scope and predecessors

The user explicitly authorized Task 6 Batch 5 and subsequently approved the five UI corrections before final device verification. Task 6 completes the Modern Applications and My production shell cutover; it does **not** implement every underlying DSM application or legacy Settings detail.

Previous Batch acceptance records remain immutable historical evidence:

- B1: `2026-10-10-task-6-batch-1-application-catalog-acceptance.md`
- B2: `2026-10-10-task-6-batch-2-application-favorites-acceptance.md`
- B3: `2026-10-10-task-6-batch-3-applications-ui-acceptance.md`
- B4: `2026-10-10-task-6-batch-4-settings-shell-acceptance.md`

Feature/design authority: `../specs/2026-10-10-task-6-applications-settings-feature-design.md`; contract matrix: `../contracts/2026-10-10-task-6-applications-settings-contract-matrix.md`; execution plan: `../plans/2026-10-10-task-6-applications-settings-batch-plan.md`.

## Final implementation and relationships

- `应用` root is the Modern `ApplicationsPage`; `我的` root is the Modern `SettingsPage`. Existing Overview / Files / Tasks entry points and both legacy root fallbacks remain in the shell.
- DSM InitData drives the supported canonical applications catalog; Log Center and Docker/Container Manager aliases dedupe without guessing routes. Each supported app has an explicit legacy destination.
- Application children and Settings details open through the existing `LegacyPageHost` and current `DsmProviderScope`. Back, global notifications and independent tab navigation retain established shell semantics.
- Favorites remain app-local `SpUtil` data, capped at eight visible apps, preserved across contexts and reordered via a lossless merge. No DSM desktop or Task 5 shortcut mutation.
- Existing Task 4 account-management/logout callbacks and `DarkModeProvider` remain the sole authorities. No new shutdown/reboot backend or Dynamic Color.
- A/B context-remount relationship tests cover catalog refresh, stale InitData isolation, visible-favorites projection and primary-tab reset.

### Device-feedback corrective follow-up (five approved changes)

1. Removed the always-visible `常用` Edit button. Pinned apps expose contextual **调整常用顺序** on long press when reordering is meaningful; the existing reorder editor remains.
2. Applications favorite-action Bottom Sheets use the bottom NavigationBar background in both Light and Dark themes.
3. Removed My category headings.
4. Replaced the previous device/account section with one compact device/account tonal card, containing **个人设置** and **退出登录** icon actions.
5. Remaining My settings rows have unified text-first layout and no mixed leading icons.

These are final-B5 presentation supersessions of historical B3/B4 behavior; the earlier accepted snapshots are not retroactively relabeled as using the new layout.

## RED → GREEN / CI evidence

- B5 shell cutover RED `23837ab40f2a99688b5e659ad28d2810db40ddf5`; production cutover `859273e6d46bd68957ea7790179a2b25bf5d61ef`. CI #289 established an initial full GREEN baseline, with subsequent relationship tests and fixes through #295.
- B5 final integration: CI **#295**, run `38052787497`, success, **300 tests passed**, targeted analyzer clean, beta debug APK and identity Gate passed.
- Corrective follow-up RED `549fbc0acc576e2a84afcb4d73d093f2b14d4f20`; CI #296 recorded **300 passed, 6 failed** (the six expected new Light/Dark corrective assertions). Follow-up implementation and test fixes culminated in final code SHA `b7ec45c31147bb39c9de9bffe38697de93f5bfed`.
- **Final authoritative CI: #299**, run `38101990946`, job `114359649164`, **completed / success**:
  - Complete `flutter test`: **306 passed, 0 failed**.
  - Targeted `flutter analyze lib/new_ui test/new_ui`: **No issues found**.
  - `flutter build apk --debug --flavor beta`: **success**.
  - APK package and signing-certificate identity check: **success**.
  - Development APK Artifact upload: **success**.
- Package ID: `top.apaipai.dsm_helper`.
- Stable development signing certificate SHA-256: `0b8e6e0765cfba89e156f3037b66c9e9382d91f788e5e9be50516df02313d9a2`.
- Artifact `dsm-helper-modern-ui-android-debug`, ID `11688470911`, attached to #299; downloadable at `https://github.com/qyxx2/dsm_helper/actions/runs/38101990946/artifacts/11688470911`. Stored zip SHA-256: `a0c57bc968105c8906715b374faf9c8df9d002d3d289605ca1277f032d6accb3`.

The later documentation-only commits change neither production nor tests; per `CI-DOCS-01`, no redundant Android build is required after final code SHA.

## Real-device Gate — user-confirmed

**Result: PASS (reported by user, 2026-10-11).** Following the final #299 APK and the corrected 13-item device checklist, the user replied **“验收通过”** and instructed final document correction and merging the PR to `modern-ui`.

The accepted checklist covered overlay installation/data retention, Modern Applications and My roots, four-column application layout, pin/reorder persistence, legacy app/detail Back handoffs, Task 4 management/logout entries, theme persistence, notifications, tab switching, absent Modern power actions, and Light/Dark visual consistency including the five requested changes. This is **one aggregate user acceptance report**; no per-scenario screenshots, logs or independent device telemetry were provided, so individual device actions are not separately asserted as instrumented test evidence.

Task 4 limitations not newly exercised by this acceptance—such as self-signed HTTPS, OTP/2FA, multi-account isolation on two real DSM accounts, or server-side SID revocation—remain **not tested on device** for those configurations. Automated context A/B fixtures are not a substitute for a second real DSM account.

## Final boundary audit

Compared with `modern-ui`, Task 6 changes are limited to the approved `lib/new_ui/applications/**`, `lib/new_ui/settings/**`, minimal production shell wiring, related tests and `docs/modern-ui/**`. The 2026-10-11 corrective diff modifies only two feature pages, their tests, and Task 6 spec/contract/plan documents before this closure.

No Task 7 code, unrelated DSM SDK/Drift/auth architecture changes, legacy application/Settings deletion, power backend, or Dynamic Color was introduced.

**Exit Gate: PASS.** This acceptance authorizes the explicitly requested Task 6 feature PR to `modern-ui`, but does not authorize Task 7 execution or changes to `dev`/`master`.
