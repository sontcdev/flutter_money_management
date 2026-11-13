# Visual rollout

- Phase: IMPLEMENTATION, revision 1.
- Approval: user replied `duệt` after the six-phase revision 1 was presented. Interpreted as approval in the Vietnamese conversation.
- Scope: central visual tokens, shared components, all feature UI, dark consistency and mocked visual verification. Preserve chosen accent, financial/status/data colors and all business behavior.
- Exclusions: backend, auth behavior, models/repositories/providers, dependencies, identity/signing, production writes, commit/deploy.
- Baseline HEAD: `42e32899d68dcb8a97006e59e5e1d911548d7e3b`; dirty compliance, UX batches 1–3 and Today pilot are pre-existing.
- Full relevant Dart snapshots and SHA-256 manifest: `/private/var/folders/3f/9vdr43354x589_78_t1mcy740000gn/T/opencode/visual_rollout_baseline/`. Includes initial status and scoped diff.
- Previous current-state verification: 607 tests passed, analyze clean, debug APK built; independently reviewed pilot PASS. New rollout changes invalidate affected prior evidence.
- Steps: P1 central tokens; P2 global components; P3 shared widgets; P4 feature groups; P5 dark/visual matrix; P6 final verification. Independent review gates after each phase.
- Acceptance: cool light surfaces throughout; no feature-local palette dependency; dark base preserved; text contrast >=4.5 and graphical controls >=3 where applicable; no layout overflow; vi/en/ja and enlarged text; all tests, analyze and debug build pass.
- Visual artifacts: temporary mock-data screenshots, not committed goldens. No production launch is needed.
- P1 complete: central AppSurfaceTokens extracted; independent review PASS, 18 focused tests and scoped analyze passed.
- P2 complete: cool light neutrals and component themes; chosen primary, semantic colors and dark base preserved. Review cycle 1 found insufficient text contrast; cycle 2 PASS after black/white onPrimary and accessible accent-text roles. Independent 22 tests and scoped analyze passed.
- P3 complete: seven shared widgets use contrast-aware foregrounds. Independent review PASS; 153 focused tests plus one load-error test and scoped analyze passed.
- P4 implementation includes budget selection/progress/remaining text, Settings tile icons, transaction category chips/icons/detail, calendar/group labels and workspace warning/expiry labels. Worker-reported focused checks passed; combined independent P4 review remains pending.
- Discovery: Settings logout FilledButton overrides its fill with AppColors.error but inherits foreground for the unrelated selected primary. A scoped worker is checking and correcting this on resume.
- Discovery: the adjacent-month alpha assertion conflicted with approved contrast. It now checks distinguishable readable colors; Calendar async Regression tests were preserved.
- P4 limitation: one workspace-related run failed with truncated output and no identified failing test. Four subsequent runs passed. A flake is not established.
- P5 mocked screenshot/layout matrix and P6 full verification/final review remain pending. Earlier 607-test evidence does not verify the current rollout state.
- Resume inspection confirmed HEAD unchanged and all existing dirty/untracked work retained. No production launch, commit or deploy is authorized.

## Final status (P4 corrections, P5, P6)
- P4 cycle 2: budget pill text (4.50/4.52) PASS; logout foreground PASS; wallet icons incl. selected chip (AppTheme tests) PASS; P4i chart (theme fallback, axis onSurfaceVariant, pie label ensureContrast) PASS.
- Calendar badge fontSize 7 left unchanged (overflow not measured) — residual.
- P5: mocked 6 screens x 8 configs matrix; 7 overflows were Ahem-only false positives (pass with Roboto). Real defect fixed: bottom nav label wrap -> FittedBox(scaleDown)+maxLines 1 in home_screen.dart.
- Harness moved out of test/ to $TMPDIR/opencode/harness/ per final review (SDK font cache dependency).
- P6 CI on final tree: pub get 0, gen-l10n 0, build_runner 0, analyze 0, test --coverage 0 (+910 with harness, +862 after removal), build apk --debug 0 (before harness removal; harness is test-only). Logs: $TMPDIR/opencode/final_ci/.
- Final review: CHANGES_REQUIRED only on harness placement; resolved by removal. No commit/deploy.

## Calendar follow-up completion
- User requested continuation. Calendar badge font increased from 7 to 9; no other production delta. New permanent test covers 24 actual vi/en/ja locale/theme/scale/orientation cases. Cycle 1 caught missing localization delegates; cycle 2 corrected them and asserted resolved locale. Independent review PASS; harness-placement issue closed.
- External real-font evidence: 24 badge cases and 4 full Japanese Hiragino grid cases passed. Japanese screenshot matrix: 18 passed with font9 source; AppBar/button tofu resolved with harness-only font overrides. Home avatar remains a font-harness limitation; no production defect established. Landscape calendar uses a scrollable section; screenshot was captured before scrolling.
- Final current-state verification, repository cwd: flutter analyze exit0; flutter test --coverage after locale correction exit0, 886 passed; flutter build apk --debug exit0 (production source unchanged since build); git diff --check exit0. Logs: $TMPDIR/opencode/calendar_final/ and calendar_review_c2_{test,analyze}.log.
- Remaining limits: no physical-device/Noto rendering verification; tested text scales 1 and 1.3. No production startup, commit, deploy, or release. Google Play external release gates remain outside this visual task.

## Emulator acceptance follow-up
- User authorized building/installing and emulator acceptance. Used external mock entrypoint with real feature widgets and fake providers; no Supabase initialization. Normal lib/main.dart debug APK restored with install -r after verification; not launched online.
- Inspected all 36 initial phone screenshots (6 screens, en/vi/ja, light/dark, portrait/landscape, scale1.3). Android Japanese glyph rendering verified. Gesture checks confirmed Home final content, Settings final row, budget horizontal filters, and landscape calendar final week reachable.
- Fixed actual findings: historical Reports bars now contrast-corrected on actual card background (independent PASS); quick-date controls Wrap to avoid Yesterday mid-word splitting (independent PASS; original snapshot fails regression); shared transaction type toggle permits full centered multiline labels without ellipsis (independent PASS).
- Final mocked emulator screenshots confirmed Reports light/dark bars, Yesterday single-line, full Vietnamese transfer label, landscape calendar last week. Reviewer independently accepted transfer wrapping and closely spaced but distinct chart endpoint labels; no mandatory correction remains.
- Verification on latest source: flutter analyze --no-pub exit0; flutter test --no-pub --coverage exit0, 924 passed; git diff --check exit0; pubspec.yaml/lock unchanged. Logs: $TMPDIR/opencode/emulator_final_checks/. Normal build/install exit0: restore_build2.log and adb evidence from emulator worker. An initial pub-enabled check timed out fetching dependencies; no PASS claimed for it.
- Acceptance: PASS for tested mocked phone visual states and stated criteria, not backend/auth/production workflows or physical-device/tablet emulator acceptance. No commit/deploy/release. Artifacts remain external under $TMPDIR/opencode/emu/.

## Durable screenshot follow-up — final evidence
- Supersedes the earlier broad acceptance and external-only artifact statement. Durable images 01–64 are in docs/acceptance-screenshots/; originals remain historical evidence.
- Corrected Japanese chart label width/endpoint collision, Today bottom clearance, workspace invitation tab readability, and bounded status-chip wrapping. Calendar totals were proven reachable without a production calendar change.
- Independent source review PASS for all incremental fixes. Chart cycle 2 uses production NumberFormat.compact and actual resolved locales. Workspace tests no longer filter framework errors.
- Independent original-image reviews: 20–53 identified the workspace issue and confirmed chart/Home/calendar replacements; 54–58 dialogs PASS; 59–64 workspace replacements PASS. Images 16 and 34/35 retain historical defects, replaced by 45 and 59–64 respectively.
- Latest full verification, repo root: flutter analyze --no-pub exit 0; flutter test --no-pub --coverage exit 0, 970 passed; git diff --check exit 0. Logs: $TMPDIR/opencode/final_workspace_checks/. Later changes are screenshot/documentation only.
- Capture worker reports normal explicit lib/main.dart debug build and adb install -r exit 0, emulator rotation restored, normal app not launched. Capture source identifiers are stored with durable harness artifacts.
- Final acceptance: PASS for reviewed representative mocked phone visual states, not exhaustive whole-app/device/locale coverage. No known blocking defect remains in those reviewed states. Backend/auth behavior, production data, tablets, physical devices, keyboard-open states, and exhaustive locale/theme combinations remain unverified. No commit, push, deploy, or release.
