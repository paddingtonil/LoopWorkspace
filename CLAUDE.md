# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

`LoopWorkspace` is an Xcode **workspace + git-submodule aggregator** for the Loop iOS automated-insulin-delivery app, in its **Loop (AID) PowerPack** fork form (`LoopPowerPack/*`). It contains almost no app code itself: the app is the `Loop` submodule, and every other top-level directory (`LoopKit`, `OmnipodKit`, `CGMBLEKit`, `G7SensorKit`, `LibreTransmitter`, `NightscoutService`, `TidepoolService`, …) is a dependency submodule. Root-level files are build config (`*.xcconfig`), fastlane/CI, and maintenance scripts.

The current branch (`merge/dev-3.14.11-upstream-sync`) is a merge of upstream `LoopKit/LoopWorkspace` `dev` into the PowerPack branch. Upstream `dev` is the mainline PowerPack tracks; upstream `main` is dormant.

### Submodule branch pinning
`.gitmodules` pins specific branches only for the forks:
- `Loop` → `LoopPowerPack/Loop` @ `feat/AllFeatures`
- `LoopKit` → `taylorpatterson-T1D/LoopKit` @ `feat/AllFeatures`
- `TidepoolService` → `LoopPowerPack/TidepoolService` @ `powerpack/pin-tidepoolkit-revision`
- `EversenseKit` → `LoopPowerPack/EversenseKit` @ `powerpack/loopplugin-infoplist-fix`

Everything else is an upstream `LoopKit/*` (or `loopandlearn/OmnipodKit`, `jbr7rr/MedtrumKit`) checkout at a recorded commit. A change made inside a submodule is a separate commit in that submodule's own repo; the workspace then needs a commit that bumps the submodule pointer. Check `git status` inside the submodule before assuming a change is "in" this repo.

## Build and test

Build/test target is the **`LoopWorkspace` scheme** on `LoopWorkspace.xcworkspace` — never the `Loop` scheme (that skips the plugin/submodule frameworks). This is the same command CI (`.circleci/config.yml`) runs:

```bash
xcodebuild -workspace LoopWorkspace.xcworkspace -scheme LoopWorkspace -destination 'platform=iOS Simulator,name=iPhone 17' build
```

```bash
xcodebuild -workspace LoopWorkspace.xcworkspace -scheme LoopWorkspace -destination 'platform=iOS Simulator,name=iPhone 17' -collect-test-diagnostics never test
```

Run a single test class or method with `-only-testing:<TestTarget>/<Class>[/<method>]` appended to the `test` command. Tests live in the submodules (e.g. `Loop/LoopTests`, `Loop/DoseMathTests`), not at the workspace root.

Clone with `--recurse-submodules`; `xed .` opens the workspace. Signing: uncomment/set `LOOP_DEVELOPMENT_TEAM` in `LoopConfigOverride.xcconfig` (simulator builds need no team).

### Configuration files at the root
- `LoopConfigOverride.xcconfig` — local overrides included by `Loop/Loop.xcconfig` via `#include?`. Here it sets `SWIFT_ACTIVE_COMPILATION_CONDITIONS` (`EXPERIMENTAL_FEATURES_ENABLED`, `SIMULATORS_ENABLED`, `ALLOW_ALGORITHM_EXPERIMENTS`, `DEBUG_FEATURES_ENABLED`, `DEV_BRANCH_WARNING_DISABLED`), so these flags are on in this checkout's builds.
- `VersionOverride.xcconfig` — `LOOP_MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`; bump here, not in the submodule.
- `OverrideAssets*.xcassets` — icon/asset overrides for the app and watch app.

### Release / CI
- Browser builds go through GitHub Actions in `.github/workflows/` (`add_identifiers` → `create_certs` → `validate_secrets` → `build_loop_manual`/`build_loop_auto`), backed by lanes in `fastlane/Fastfile` (`build_loop`, `identifiers`, `certs`, `release`, …). Fastlane is pinned in `Gemfile` (`bundle exec fastlane <lane>`). User-facing instructions: `fastlane/testflight.md`.
- `build_loop_manual` deliberately has no `schedule:` trigger (fork protection auto-disables scheduled workflows) — don't re-add one.

## Maintenance scripts (`Scripts/`)
- `update_submodule_refs.sh` — checks out and pulls every submodule at the tip of its branch; uses `PROJECTS` from `define_common.sh`. Modifies the current clone.
- `define_common.sh` — shared config (translation branch names, language list, `PROJECTS`); sourced by the other scripts, which accept `TRANSLATION_BRANCH` / `TARGET_LOOPWORKSPACE_BRANCH` as optional args 1 and 2.
- `export_localizations.sh` / `import_localizations.sh` / `manual_*.sh` — Lokalise translation round-trip (see `Scripts/LocalizationInstructions.md`). Translations for other languages go through Lokalise, not hand edits; contribute English source strings only.
- `install_features.sh` — the "Option B" installer that overlays PowerPack onto a *vanilla* LoopKit/Loop clone (backup stash, `--rollback`, deterministic pbxproj UUIDs). Not used in this all-features checkout (Option A); relevant only when changing how features are packaged.
- `update_pbxproj.py` — pbxproj patching helper used by the installer.
- `sync.swift` — upstream sync tool (needs `swift-sh`).

`patches/` is for LoopWorkspace-level patches only. `outputs/git-bundles/` holds generated bundles, not source.

## PowerPack architecture (inside the `Loop` submodule)

PowerPack features are additive layers over upstream Loop; read `DIVERGENCE.md` before touching them. Features: AutoPresets, BolusPro, DirectConnect, FoodFinder, GraphDetailView, LoopInsights (incl. DataLayer), SiteAtlas. The rules that shape every edit:

- **Feature-namespaced layout.** Each feature lives under `Loop/Loop/{Models,Resources,Services,Views,Managers,View Models}/<Feature>/` with files prefixed `<Feature>_` (e.g. `AutoPresets_ScannedEventsView.swift`). Shared helpers (AI model-search buttons) sit in `Views/PowerPack` and `Services/PowerPack`. Per-feature docs: `Loop/Documentation/<Feature>/` (`README.md` + `_DEVELOPER.md`).
- **Minimal footprint in upstream files.** Edits to upstream-owned files (`CarbEntryView`, `BolusEntryViewModel`, `SettingsView`, `LoopDataManager`, …) must be small anchor-based inserts — no refactors, reformatting, or cleanup. This is what keeps weekly upstream merges conflict-light.
- **No algorithm changes.** Dosing-adjacent features go through Loop's existing public paths (`addCarbEntry`, override schedules, preset activation). Do not modify the dosing engine.
- **Features communicate via `NotificationCenter`**, with documented payloads — no compile-time dependencies between features, so one can be removed without breaking another. DataLayer events use additive schema versioning (never remove/rename fields).
- **Master flags default OFF** (GraphDetailView is the lone exception).
- New Swift files in PowerPack directories carry the standard attribution header (`Loop (AID) PowerPack — based on LoopKit/Loop. Copyright © 2026 LoopKit Authors and Taylor Patterson.`), plus the Claude Code co-author disclosure described in `MANIFESTO.md`. Inherited upstream files keep their original headers.

### Known project quirk
`xcodebuild` warns that `AutoPresets_ScannedEventsView.swift` is a member of multiple `AutoPresets` groups in `Loop.xcodeproj` (malformed duplicate group reference). It doesn't break the build, but pbxproj edits should avoid adding more of this.

## Other docs at the root
- `DIVERGENCE.md` — authoritative description of fork vs upstream, merge cadence, canonical repo URLs.
- `CONTRIBUTING.md` — upstream Loop contribution rules (small focused PRs, match existing style, no drive-by formatting).
- `MANIFESTO.md` — position paper on AI-assisted development in this fork.
