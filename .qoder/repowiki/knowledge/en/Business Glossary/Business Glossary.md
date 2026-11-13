---
kind: business_term
name: Business Glossary
category: business_term
scope:
    - '**'
---

### AFM
- Definition：Apple Foundation Models layer — the on-device AI capability used for onboarding insights, quest card generation, debrief coaching, and daily mission invention. Requires iOS 26+ and a device with Apple Intelligence. All AFM calls have a Swift fallback so the app never blocks on the model.
- Aliases：Apple Foundation Models、on-device AI

### DebriefEngine
- Definition：The fixed-state-machine sequence that drives the voice debrief: greeting → main question → user answer → follow-up 1 (Presence) → follow-up 2 (Warmth) → follow-up 3 (weakest stat) → closing message. It computes confidence per answer and evidence-weighted averages per stat, then transitions to `.finished` where further input is ignored.
- Aliases：debrief state machine、voice debrief flow

### Mission Bank
- Definition：A curated set of ~20 pre-vetted social situations (each with scene, who, goal, age range, and four stat-specific follow-up questions) that the AFM mission planner and validator reference. Invented missions retain the bank `templateID` so debrief follow-ups stay grounded in vetted prompts.
- Aliases：mission bank、situation bank

### Quest
- Definition：A user-facing social-confidence challenge. A quest is either library-generated (identified by `isFromLibrary == (xp != nil)` and owned by the device-scoped `CurrentUser.localID`) or custom/user-authored. Each quest tracks progress via `QuestProgress` (XP, streak, idempotency keys).
- Aliases：quest card、social quest

### OverviewMode
- Definition：The app-wide session state controlling whether the home screen shows the normal overview or the debrief/quest-overview overlay. Toggled via environment values `.openOverview` / `.endSession`.
- Aliases：overview session、debrief session

### RelaxStep
- Definition：The enum driving the Relax tab navigation: a guide detail opens directly into a timed `session(ImageryGuide)` state, which transitions to `complete(ImageryGuide)` on finish. `ImageryGuide` must be `Hashable` for this to compile.
- Aliases：relax navigation state、imagery step

### MokoTab
- Definition：Single source of truth for the shared tab bar across `MokoRootView`, `MainHomeContainerView`, `Overview`, and `RelaxScreen`. Tab selection is driven by this enum rather than per-screen state.
- Aliases：tab enum、app tabs

### PBXFileSystemSynchronizedRootGroup
- Definition：The Xcode project root group (`path = Moko`) that auto-compiles files under `Moko/Moko/**`. Files placed under sibling directories like `Moko/Features/**`, `Moko/RiveProjects/`, or `Moko/.agents/` are NOT compiled into the app unless explicitly added to the target.
- Aliases：sync root group、auto-compile root

### SwiftData container
- Definition：Local persistence layer holding seven models for onboarding answers, reflections, profile, quest data, etc. New properties require defaults because implicit SwiftData migrations are used.
- Aliases：local data store、SwiftData models
