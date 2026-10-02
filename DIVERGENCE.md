# DIVERGENCE — Loop (AID) PowerPack vs upstream LoopKit/Loop

> A short description of what this fork does that upstream Loop
> doesn't, what upstream does that this fork explicitly doesn't pull,
> how often we sync with upstream, and where to file feedback.

## What this is

**Loop (AID) PowerPack** is an independently-maintained derivative of
[LoopKit/Loop](https://github.com/LoopKit/Loop), the open-source iOS
automated insulin delivery (AID) app. PowerPack adds a coherent set of
features for AI-assisted carb counting, AI-assisted therapy-settings
tuning, motion-aware preset automation, fat/protein-aware bolusing,
infusion + sensor site rotation tracking, and a chart-detail interaction
layer — all behind opt-in feature flags so users can pick which ones
they want.

PowerPack is **not** a separate AID algorithm. The closed-loop dosing
engine remains LoopKit's. PowerPack adds *information surfaces* and
*decision-support inputs* that flow through Loop's existing safe-dosing
path (ISF, CR, basal schedules, max bolus, etc.).

PowerPack is **not** approved by any regulatory body. It is DIY software
for personal use. The same disclaimers that apply to upstream Loop apply
here, and then some.

## Why this fork exists separately

PowerPack ships features that benefit from **AI-assisted development
velocity** — concept to user-facing UI in days, not months or years. Upstream
LoopKit's contribution policy (codified in their `CONTRIBUTING.md`,
adapted from Trio's) does not accept pull requests that are largely
AI-generated. That's a legitimate maintainer choice, and we respect it.
Rather than dilute either project, PowerPack lives independently and
distributes through its own install paths.

We periodically merge from upstream so PowerPack users continue to
benefit from LoopKit's algorithm improvements, pump/CGM driver updates,
iOS SDK churn fixes, and security patches. PowerPack does not attempt
to upstream its features.

## Development principles

PowerPack adheres to a set of self-imposed engineering principles that
make the fork easy to install, easy to uninstall, easy to update with
upstream Loop, and easy to extend without compromising the host:

- **Minimal footprint in upstream Loop files.** Modifications to
  unmodified-from-upstream Loop files (CarbEntryView, BolusEntryViewModel,
  SettingsView, LoopDataManager, etc.) are limited to anchor-based
  inserts and small additions. No refactors of upstream code, no
  reformatting, no opportunistic cleanup. Less divergence = easier
  upstream merges.

- **Portability — feature-namespaced everything.** Each feature lives
  in `Loop/<Models|Resources|Services|Views|Managers|View Models>/<Feature>/`
  with all files prefixed `<Feature>_`. The installer can copy a
  feature's files in or remove them on uninstall without touching
  unrelated code.

- **Decoupled feature communication.** Features that need to talk to
  each other (e.g. BolusPro broadcasting analytics, DataLayer recording
  it, LoopInsights' BehaviorAnalyzer learning from it) do so via
  `NotificationCenter` events with documented payloads. No compile-time
  dependencies between features. Removing one feature doesn't break
  another.

- **Master flags default OFF.** Every feature ships disabled
  (GraphDetailView is the lone exception — it's a passive UI affordance
  with no algorithm side-effects). Users opt in. No feature changes app
  behavior until the user explicitly enables it.

- **No algorithm changes.** Dosing-adjacent features (BolusPro,
  LoopInsights' suggestions, AutoPresets) all flow through Loop's
  existing public APIs (e.g. `addCarbEntry` delegate, override schedule,
  preset activation). The closed-loop dosing engine remains LoopKit's,
  untouched.

- **Privacy-first analytics.** DataLayer (part of LoopInsights) stores
  all events locally in SQLite first. Cloud upload is opt-in per consent
  category. No third-party data brokers; the user owns their data and
  the dashboard endpoint they hit is their own GCP project (or none).

- **Documentation standards.** Every feature has a `README.md`
  (user-facing) and a `_DEVELOPER.md` (architecture, file map,
  integration points) under `Loop/Documentation/<Feature>/`. Every Swift
  file carries a standardized header with attribution. Every DataLayer
  event payload is documented in `DataLayer_EventModels.swift`.

- **L&L Customizations compatibility.** The Option B installer detects
  and respects Loop & Learn patches applied before PowerPack install.
  Anchor-based insertion patches play nicely with L&L's
  protocol/signature changes (e.g. L&L's `Result<DoseEntry, any Error>`
  enactBolus signature is preserved when PowerPack's BolusPro additions
  are inserted into BolusEntryViewModel).

- **Backward-compatible event schemas.** DataLayer event payloads use
  schema versioning. New fields are additive; existing fields are never
  removed or renamed. Dashboard endpoints stay backward-compatible.

- **Reproducible installs.** The installer creates a backup stash
  before any change. Every change is reversible via `--rollback`.
  Deterministic UUIDs in pbxproj patches mean repeated installs produce
  identical project files.

## What PowerPack adds beyond upstream Loop

Each feature is a separate opt-in. Master toggles default OFF. Detailed
docs live in `LoopWorkSpace/Loop/Documentation/<Feature>/`.

| Feature | Adds | Default |
|---|---|---|
| **AutoPresets** | Auto-activate Loop override presets when CMPedometer/CMMotionActivity detect sustained walking or running. Optional geofence + calendar triggers | OFF |
| **BolusPro** | Per-meal toggle + slider on the Add Carb Entry screen that creates a second timed carb entry sized for the protein/fat tail (Trio's gram formula). Loop doses against both entries via its existing closed-loop logic — no second bolus, no algorithm changes | OFF |
| **FoodFinder** | AI image analysis of food photos returning carbs/fat/protein/fiber/calories per item, optional barcode lookup via OpenFoodFacts, voice/text natural-language entry. BYO API key (OpenAI / Anthropic / Google) | OFF |
| **GraphDetailView** | Long-press the home-screen glucose chart to surface a detail popup with glucose / IOB / COB / bolus / basal rate / preset / AutoPreset / heart rate at the touched timestamp. Scrub left/right to explore | Always-on once installed |
| **LoopInsights** | AI-powered analysis of glucose, insulin, and meal data with suggestions for therapy settings (CR / ISF / basal). Includes Behavior Insights, Caregiver Digest email/iMessage, Endo Visit PDF report generator, Meal Debrief retrospective, Pre-Meal Advisor, Ask Loopy chat, and **DataLayer** — a local SQLite event store with opt-in cloud upload for personal analytics dashboards (per-category consent: glucose, insulin, carbs, AI behavioral, biometrics, substances, activity/presets). BYO API key for AI features (shared with FoodFinder) | OFF |
| **SiteAtlas** | Visual body-map tracker for pump infusion sets and CGM sensors. Color-coded age fade with type-aware safe-reuse windows (pump 10d, sensor 5d). Touch-and-drag pin adjustment with proximity warnings | OFF |

Plus shared infrastructure:
- LoopKit fork (`taylorpatterson-T1D/LoopKit`) for any LoopKit-side
  integration that PowerPack needs
- An installer (`feat/installer` branch on this repo) that overlays
  PowerPack onto a vanilla LoopKit/Loop clone that could include L&L Customizations — the **Option B install
  path** — alongside the all-features clone — the **Option A install
  path**
- Per-feature install/uninstall scripts so users can adopt one feature
  at a time

## What PowerPack tracks from upstream

PowerPack tracks `LoopKit/Loop:dev` — the active upstream mainline.
LoopKit/Loop's `main` branch is no longer maintained (last commit
April 2025; confirmed by LoopKit maintainer Marion Barker). `dev` is
where new pump/CGM driver work, bug fixes, and feature work land.

PowerPack does not currently ship:
- Any **experimental upstream feature flags** that are off by default
  in upstream `dev` (they may be available but PowerPack doesn't
  pre-enable them)
- Any **Loop & Learn (L&L) customizations** by default. The Option B
  installer respects L&L patches that were applied before PowerPack
  install, but PowerPack itself does not bundle L&L code. You have to do this first yourself.

## Upstream-merge cadence

| Trigger | Action |
|---|---|
| Upstream `dev` security/critical fix | Merged within 7 days |
| Upstream `dev` pump/CGM driver update | Merged within 14 days |
| Routine upstream `dev` activity | Merged on a weekly automated probe (`upstream-probe.yml` GitHub Action). Conflict-free merges are pushed automatically; conflicts open an issue for manual resolution |
| Upstream `main` activity | Not pulled. The branch is dormant. |

Merge events are visible in the commit history of `feat/AllFeatures`
and posted to the project's GitHub Discussions.

## Where PowerPack lives canonically

| Surface | URL |
|---|---|
| Loop repo (PowerPack feature commits) | https://github.com/LoopPowerPack/Loop |
| LoopWorkspace repo (install instructions, feat/installer scripts, this doc) | https://github.com/LoopPowerPack/LoopWorkspace |
| Browser-build mirror (TestFlight pipeline) | https://github.com/TaylorJPatterson/Loop-AllFeatures *(intentionally not migrated; auto-syncs from LoopWorkspace and continues to work)* |
| LoopKit fork (LoopKit-side feature integration) | https://github.com/taylorpatterson-T1D/LoopKit *(intentionally not migrated; submodule URL resolves correctly)* |
| Install instructions (canonical user-facing README) | https://github.com/LoopPowerPack/LoopWorkspace/pull/1 |
| Position paper on AI-assisted development | [`MANIFESTO.md`](MANIFESTO.md) at this repo root (also published on Substack at [taylor256.substack.com](https://taylor256.substack.com)) |

## Filing bugs, requesting features, asking questions

| Channel | Best for |
|---|---|
| **GitHub Discussions** on `LoopPowerPack/LoopWorkspace` | Feature requests, install help, peer support |
| **GitHub Issues** on `LoopPowerPack/Loop` | Confirmed bugs with reproduction steps |
| **Loop community Zulip** ([loop.zulipchat.com](https://loop.zulipchat.com)) | General Loop questions; mention PowerPack explicitly so non-PowerPack users aren't troubleshooting your fork-specific behavior |

PowerPack does not file bugs, feature requests, or pull requests
against `LoopKit/Loop`. Issues with upstream behavior should be filed
upstream directly.

## License + attribution

PowerPack is released under the same license as upstream LoopKit/Loop
(MIT-style permissive — see [LICENSE.md](LICENSE.md)).

Every Swift file in PowerPack-added directories carries this header:

```
//  Loop (AID) PowerPack — based on LoopKit/Loop.
//  Copyright © 2026 LoopKit Authors and Taylor Patterson.
```

Files inherited unchanged from upstream LoopKit/Loop carry their
original headers unmodified.

The "Loop" word mark and any LoopKit/Loop branding are property of the
LoopKit project. PowerPack uses "Loop (AID) PowerPack" as a distinct
product name to avoid implying upstream endorsement.

## Disclaimers

PowerPack is **DIY software for personal use**. It is not a medical
device, has not been evaluated by the FDA or any other regulatory body,
and carries no warranty. Decisions about insulin dosing remain entirely
the user's responsibility. PowerPack's information surfaces (BolusPro
slider, FoodFinder analysis, LoopInsights suggestions) are
**decision-support inputs**, not dosing decisions. The closed-loop
algorithm enforcing dosing is LoopKit's, and the existing safety bounds
(max bolus, max basal, target ranges) are the user's responsibility to
configure correctly.

Use of PowerPack at your own risk. Monitor your glucose closely,
especially in the first weeks after enabling any new feature, and
particularly for any feature that influences insulin dosing (BolusPro,
LoopInsights suggestions). When in doubt, default to your endocrinologist
or diabetes care team's guidance over PowerPack's.
