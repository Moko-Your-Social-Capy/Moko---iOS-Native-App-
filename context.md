# MOKO — Project Context

> **How to use this file:** read it before touching code, and update it at the end of every
> change session (sections that changed + a new entry in [Change log](#change-log)).
> Keep it factual: if the code and this file disagree, the code wins — then fix this file.

Last updated: 2026-11-13 · Branch: `fix/bugs` · HEAD: `6d55755`

---

## 1. What this project is

**MOKO 🦫 ("Your Social Capybara")** — a native iOS social-wellness / self-improvement app.
A calm capybara coach (Moko) guides short real-life social missions, a voice/text debrief, and
guided relaxation (breathing, grounding, imagery, mirror). Light gamification: XP, streaks,
badges. Not a medical device; no treatment claims.

- Repo: `Moko-Your-Social-Capy/Moko---iOS-Native-App-`
- Bundle ID: `com.SRMIST.Moko`
- Roughly 21k lines of Swift across ~90 files.

---

## 2. Toolchain & build

| Item | Value |
|---|---|
| Project | `Moko/Moko.xcodeproj` (single app target `Moko`) |
| Deployment target | **iOS 26.5** (not 17 — the README is stale) |
| Swift language mode | 5.0, Xcode project objectVersion 77 (Xcode 16+) |
| iOS SDK | Must support iOS 26.5 (needed for FoundationModels / AFM) |
| Tests | **None.** No test target exists, despite `README.md` |

Dependencies (Swift Package Manager, resolved versions):

| Package | Version | Used for |
|---|---|---|
| `supabase/supabase-swift` | 2.55.4 | Auth, Postgres/REST, Storage |
| `google/GoogleSignIn-iOS` | 10.0.0 | Google sign-in |
| `airbnb/lottie-ios` | 4.6.1 | Legacy mascot JSON animations |
| `rive-app/rive-ios` | 6.29.0 | Current mascot / badge animations |

Frameworks linked in the target: `Supabase`, `Auth`, `GoogleSignIn`, `GoogleSignInSwift`,
`Lottie`, `RiveRuntime`.

### File membership — the most important build fact

The target uses a **`PBXFileSystemSynchronizedRootGroup` with `path = Moko`**. Everything under
`Moko/Moko/` is compiled automatically (no pbxproj edit needed for new files). Build-file
exceptions (excluded/treated specially): `Info.plist`, `Resources/Animations/MokoMeditationRive/rive.yaml`,
`Resources/Animations/MokoMeditationRive/scene.rml`.

Consequences:

- `Moko/Moko/**` → **in the app** (Swift sources compiled, other files bundled as resources).
- `Moko/Features/` (duplicate `MokoLottieView.swift`, `ColorSystem/Colors.swift`),
  `Moko/RiveProjects/`, `Moko/.agents/` → **NOT part of the app at all**.
  Editing those changes nothing in the app (and the duplicates have *diverged*).

### Commands

```bash
open Moko/Moko.xcodeproj                 # then ⌘R / ⌘B

xcodebuild -project Moko/Moko.xcodeproj -scheme Moko \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build CODE_SIGNING_ALLOWED=NO
```

Caveats: there is **no shared scheme** (schemes live only in `xcuserdata/`), so `-scheme Moko`
depends on a scheme existing locally. `.github/workflows/swift.yml` runs `swift build` /
`swift test` at the repo root — that cannot work (there is no `Package.swift`); the README refers
to a nonexistent `ios-ci.yml`. Treat CI as non-functional until fixed.

---

## 3. Repository map (in-target paths)

```
Moko/Moko/
├── MokoApp.swift            @main; prewarms floss loader; SwiftData container; segmented control tint
├── ContentView.swift        App flow state machine (splash → auth → onboarding → home)
├── MokoRootView.swift       TabView shell + OverviewMode switching + debrief cover
├── AuthService.swift        Supabase email/password auth + deleteAccount() edge function call
├── GoogleAuthService.swift  GIDSignIn → Supabase signInWithIdToken
├── SupabaseManager.swift    Shared SupabaseClient (URL/key hardcoded)
├── MokoFlossLoader.html     Bundled page rendered by the WKWebView loader
├── Info.plist               Camera + mic usage strings, Google URL scheme
├── Models/                  SwiftData @Model types + value types + theme tokens
├── Features/
│   ├── AFM/                 Apple Foundation Models layer (mission bank, prompts, engines)
│   ├── Animation/           Lottie view, Rive helpers, floss loader, completion animation
│   ├── Audio/               Debrief success sound player
│   └── QuestLibrary/        Supabase-backed Explore tab (service, store, view)
├── UIScreens/
│   ├── startScreens/        MokoTheme, splash, intro, auth, mascot
│   ├── Onboarding/          Carousel → name → age → welcome (+ Color hex helpers)
│   ├── Onboarding_Questions/8 swipe yes/no cards, reflection, mic preprompt, done
│   ├── homeScreens/         Overview, resume, debrief-done, Insights, Profile + subscreens, Summary
│   ├── Quests/              Quests list, new quest, detail, debrief, navigation env values
│   └── relaxScreens/        Relax home, box breathing, breathing, grounding, imagery, mirror
├── Resources/Animations/    Lottie .json + Rive .riv files
└── Assets.xcassets/         Mascot costumes, onboarding art, illustrations, success mp3
```

Outside the app target (do not mistake for source of truth): `Moko/Features/`, `Moko/RiveProjects/`
(Rive CLI `.rml` projects + their own `AGENTS.md`/`CLAUDE.md`), `Moko/.agents/skills/rive-animation/`.
Inside the synced group but not app logic: `Moko/Moko/supabase/functions/delete-account/` (Deno edge
function, treated as a resource).

Repo root: `README.md`, `MOKO_AFM_README.md`, `Secrets.example.xcconfig`, `supabase/` (migrations + seeds).

---

## 4. App flow & navigation

`ContentView` drives a private `AppScreen` enum:

```
splash → intro → auth → onboardingInfo (carousel → name → age → welcome)
       → onboardingQuestions (8 swipe cards) → done → reflection → microphonePreprompt → home
                              └→ accountDeleted → intro
```

- "Fully registered" gate: `!profiles.isEmpty && !onboardingResponses.isEmpty && OnboardingState.isCompleted`.
- Session state in `@AppStorage`: `userName`, `userAge`, `moko.isSignedOut`,
  `hasCompletedOnboarding`, `moko.selectedCostumeLevel`, notify* keys.
- Sign-out / account deletion: `\.endSession: (SessionEndReason) -> Void` environment value,
  provided in `ContentView`, consumed by Profile screens.

`MokoRootView` is the signed-in shell:

- `MokoTab` (single source of truth): `.overview`, `.quests`, `.relax`, `.search` (Explore).
- `TabView` + `.tabBarMinimizeBehavior(.onScrollDown)` +
  `.tabViewSearchActivation(.searchTabSelection)` (required for the detached search tab on iOS 27),
  tint `MokoTheme.forestGreen`, text `MokoTheme.titleBrown`.
- **Explore uses the system search field, unmodified.** `QuestLibraryView` keeps its plain
  `.searchable(text:placement: .navigationBarDrawer(displayMode: .always))` and `MokoRootView` has no
  search-related state, no focus handling and no keyboard workarounds. Selecting the search tab
  expands the field (and lets iOS focus it); the field's ✕ is the system "deactivate search" control
  and returns to the previously selected tab. Nothing in `MokoRootView` reacts to that — it is the
  framework's behaviour and is deliberately left alone (see §11.8).
- Overview has three versions via `OverviewMode { .todo, .resume, .debriefDone }`.
  Deep screens set it through `\.openOverview` (mostly the debrief, presented as a `fullScreenCover`).
- The Overview mission card is a single slide pill — `OverviewSlideControl`, defined at the bottom of
  `Overview.swift` and shared with `OverviewResumeScreen`. One slide does the whole thing: the `.todo`
  pill reads "Slide to Complete", completes the quest (`QuestProgress.complete`) **and** opens the
  debrief in the same gesture. "Slide to Debrief" is only shown when the quest is already completed
  (reachable by leaving a debrief behind, never by completing one). `.resume` shows "Slide to Resume".
  The label is frozen for ~1.2 s after the slide (`isHandingOffToDebrief`), because completing the
  quest re-renders the card before the cover covers it — without the freeze the pill visibly flashes
  "Slide to Debrief" mid-transition.
  There is **no** separate "Start Debrief" / mic button: every debrief is entered by sliding.
- `PendingDebriefStore` (UserDefaults key `moko.pendingDebriefQuestID`) remembers *which* debrief is
  unfinished so "slide to resume" can reopen it; `DebriefDraftStore` remembers *how far* it got (§5).
- On first `task`: `DailyMissionService.ensureDailyMission(...)` guarantees a mission exists.

---

## 5. Data layer

### SwiftData (the app's local store)

Container registered in `MokoApp.swift`: `OnboardingState`, `OnboardingQuestion`,
`OnboardingResponse`, `Profile`, `CalmDownModel`, `Quest`, `InsightsModel`.

| Model | Purpose / notes |
|---|---|
| `Quest` | Custom + daily + library-origin quests. `ownerID` = `CurrentUser.localID`. `isFromLibrary == (xp != nil)`. `awardedXP`, `xpAwarded`, `debriefRecorded`, `completedAt`. |
| `Profile` | username, age, avatar `Data`, `xp`, `currentStreak`, `longestStreak`, `lastActivityDate`. Level = `xp / 400 + 1`. |
| `InsightsModel` | courage / clarity / presence / warmth + date. One row per debrief. |
| `CalmDownModel` | Finished relax session: title, seconds, date. Written by `modelContext.logCalmDown(_:seconds:)`. |
| `OnboardingState/Question/Response` | Local record of onboarding answers and completion. |

`MokoDatabase` (in `QuestModels.swift`) builds a **separate** `ModelContainer` for `Quest` only —
it is a preview/legacy helper and is *not* what the app runs on. Use `@Query` / `modelContext`.

`CurrentUser.localID` is a device-scoped UUID in `UserDefaults` (`moko.currentUserID`) — there is no
real per-account scoping yet. `CurrentUser.reset()` runs on account deletion.

### Progression

`QuestProgress.complete(_:in:at:)` marks a quest done and awards XP + streak **once**
(`xpAwarded` guard). Streak rule: same day keeps it, next day +1, a single missed day is allowed
when `current >= 7 && current % 7 == 0`, otherwise reset to 1.
`QuestProgress.saveDebrief(_:for:in:)` additionally inserts an `InsightsModel` with every score
floored at 45 (never zero) and is idempotent via `debriefRecorded`.

### Unfinished debrief (UserDefaults)

`PendingDebriefStore` (`moko.pendingDebriefQuestID`) holds the quest id; `DebriefDraftStore`
(`moko.debriefDraft.<quest-uuid>` → JSON `DebriefDraft`, in `Models/DebriefDraft.swift`) holds the
conversation: messages (coach / user+grade / divider), answers, grades, `questionNumber`, `focus`.
`DebriefSession` persists after every appended message and every grade, and on "Finish Later"; the
draft is cleared when the debrief completes (`recordDebrief`) or progress is left (`exit(.leave)`),
and `clearAll()` runs on account deletion.

`DebriefSession.restore(from:)` rebuilds the conversation and decides what happens first:
last message a divider → ask follow-up `questionNumber`; last message a user bubble → ask
`questionNumber + 1` with its header; all four answers already in → `finish()` and show the scores;
otherwise nothing and `start()` must not emit the greeting again. The plain
`QuestDebriefScreen(context:)` init has no quest id, so `persist()` is a no-op there (previews).

### Supabase (remote content + auth)

| Object | Where | Notes |
|---|---|---|
| `quest_library` | table | Explore cards; `category_sort_order`, `sort_order`, `xp`, `tint_hex`, `image_url`, `is_active` |
| `imagery_guides`, `imagery_guide_tags`, `imagery_guide_screen_content` | tables | Relax → Imagery content |
| `quest-library`, `imagery-guide` | storage buckets | Public read; artwork + ambient audio |
| `delete-account` | edge function (`Moko/Moko/supabase/functions/`) | Requires `SUPABASE_SERVICE_ROLE_KEY` on the server |

Migrations and seeds at repo root: `supabase/migrations/*.sql`, `supabase/seed.sql`,
`supabase/imagery_guides_seed.sql`. Reads only — content is edited in the dashboard.

Client setup: `SupabaseManager.shared.client` with the project URL + **publishable/anon key hardcoded
in `SupabaseManager.swift`**, and Google client IDs hardcoded in `GoogleAuthService.swift`.
`Secrets.example.xcconfig` exists but is **not wired into the build** (no xcconfig reference in the
pbxproj). Never put a `service_role` key in the app.

---

## 6. AFM (Apple Foundation Models) layer — `Features/AFM/`

Requires iOS 26 + Apple Intelligence device; **every call has a static Swift fallback**.

| File | Holds |
|---|---|
| `MokoMissionBank.swift` | `Stat`, `Difficulty`, `MissionTemplate`, the 20-situation mission bank |
| `MokoAFM.swift` | `AFM.generate` (one process-wide generation slot, fresh session per call, retry only on *transient* faults), preview gate, availability, `@Generable` types, all prompts |
| `MokoServices.swift` | `OnboardingScoring`, `StatScores`, `Band`, `QuestCardService`, `MissionPlanner`, `DebriefEngine` |
| `MokoMissionInvention.swift` | Invented daily missions + validator + AFM review pass |
| `AFMDebriefCoach.swift` | `DebriefCoaching` bridge into `QuestDebriefScreen`; `Stat ⇄ DebriefParameter` mapping |
| `DailyMissionService.swift` | Guarantees today's Overview mission; lowest-stat targeting; prep ramp for upcoming quests |

Design rules (also in `MOKO_AFM_README.md`): Swift owns logic/maths/scheduling; AFM only writes and
reads language; user text is wrapped in `<user_input>` / `<user_said>` and treated as data; prompts
use fresh sessions (~4k context); no guessed scores.

### Generation contract (added after the `LanguageModelFeedback.swift` crash)

- **`AFM.generate` is the only door to `LanguageModelSession`.** Never construct a session elsewhere.
- It takes a process-wide slot (`AFMGenerationGate`, an actor). The on-device model serves **one
  request at a time**; two overlapping sessions (a fire-and-forget `DailyMissionService` seed racing
  a debrief turn, or a preview scene re-running `.task`) make FoundationModels assert on its own
  session state inside `LanguageModelFeedback.swift`.
- **Retry only on transient faults** (`GenerationError.decodingFailure`, `LanguageModelError.timeout`).
  Guardrail / refusal / context-size / rate-limit / concurrent-request / unsupported-* are final:
  re-submitting them is exactly what re-enters the asserting path. All callers already have static
  Swift copy, so a thrown error is a normal outcome.
- **`AFM.isPreviewRuntime`** (`XCODE_RUNNING_FOR_PREVIEWS`, `XCODE_RUNNING_FOR_PLAYGROUNDS`, or a
  bundle path containing `/Previews/`) forces `isAvailable == false`, so SwiftUI Previews always
  render the fallbacks. Previews are not a supported FoundationModels host.
- The error model is split by OS: `LanguageModelSession.GenerationError` (iOS 26, deprecated in 27)
  vs `LanguageModelError` + `LanguageModelSession.Error` (iOS 27+, non-exhaustive → `@unknown default`).

Daily missions: `DailyMissionService.ensureDailyMission` picks a template by lowest average stat or
an upcoming custom quest's prep ramp, then optionally rewrites it via AFM. It also seeds one quest
per remaining category so the Quests tab has variety. `Quest.overviewMission` / `todayFallbackQuest`
guarantee the UI never shows an empty mission.

Debrief: `DebriefEngine` (fixed 1 main + 3 follow-up turns, `finished` is terminal), typed or
speech-to-text input, per-turn confidence + note, evidence-weighted final scores.
`DummyDebriefCoach` is the offline fallback; `AFMDebriefCoach` the live one.

---

## 7. Design system

`MokoTheme` (`UIScreens/startScreens/MokoTheme.swift`) is the canonical token set:

| Token | Hex | Use |
|---|---|---|
| `limeBackground` | `#F6FAE8` | Screen background (`MokoTheme.background`) |
| `forestGreen` | `#1B422F` | Primary actions, tint |
| `limeSelected` | `#E2F5B1` | Selected chip/segment fill |
| `titleBrown` | `#5C4330` | Titles, primary text |
| `bodyBrown` | `#51443E` | Body copy |
| `cardBackground` | `#FAFDF1` | Cards, fields |
| `textTertiary` | `#6F6762` | Muted/placeholder |
| `warmCream` | `#F6F0E4` | Alternate surface |

Also: `MokoPrimaryButtonStyle` (press scale + light haptic), `MokoFlowerOrnament`,
`MokoTheme.playFeedback(_:)` / `playNotificationFeedback(_:)`.

Overlapping token sets exist and should not proliferate:
`Models/ColorTokens.swift` (`public enum ColorTokens`), `UIScreens/Onboarding_Questions/OnboardingTheme.swift`
(`OBColor`), `UIScreens/Onboarding/Colors.swift` (static `Color` extension),
plus a **conflicting, out-of-target** `ColorTokens` in `Moko/Features/ColorSystem/Colors.swift`.
`Color(hex:)` is declared in several files with different signatures (`UInt32`, `UInt32, opacity`).
New code: use `MokoTheme`; don't add another palette.

Typography is system only (SF Pro / `.system(size:weight:design:)`) — no custom fonts, no
string catalog / localisation (English only).

Motion & accessibility: `accessibilityReduceMotion` is honoured in the floss loader, badge unlock,
profile entrance animations and Lottie/Rive usage. Decorative animations carry
`accessibilityLabel`s.

---

## 8. Animation stack

| Tech | Entry point | Notes |
|---|---|---|
| Lottie | `Features/Animation/MokoLottieView.swift` + `MokoAnimationTypes.swift` | `MokoLottieView(animationType:size:)` over `UIViewRepresentable`; JSON in `Resources/Animations`, tries `Resources/Animations` → `Animations` → bundle root |
| Rive | `UIScreens/startScreens/MokoAnimatedMascotView.swift`, `relaxScreens/Breathing/Breathingsessionscreen.swift`, `ProfileOverView/BadgeUnlockRiveView.swift` | `AsyncRiveUIViewRepresentable`, view-model properties (badge glyph, tier, angle, reduceMotion), `.riv` names `MokoWelcomeRive`, `MokoMeditationRive`, `MokoMascotRive`, `MokoCompleteRive`, `BadgeUnlock` |
| WebKit | `Features/Animation/MokoFlossLoadingView.swift` + `MokoFlossLoader.html` | Prewarmed in `MokoApp.init`; WebView pooling |
| Audio | `Features/Audio/DebriefSoundPlayer.swift` | `Assets.xcassets/google-pay-success.dataset` |

Rive authoring projects live in `Moko/RiveProjects/*` (RML + `rive` CLI). Their `AGENTS.md` requires
`rive schema` / `rive docs` lookups instead of guessing types, then `rive . --verify`,
`rive inspect . --summary`, and `rive . --screenshot --advance=<t>`.

---

## 9. Conventions observed in the codebase

- File header: `//  Name.swift` / `//  Moko` / one-line summary; comments explain *why*.
- SwiftData models are `final class` + `@Model`; new fields get defaults so the store can migrate
  implicitly (see the `Quest.isCompleted = false` comment).
- Shared services are `@MainActor enum` with static functions (`DailyMissionService`, `QuestProgress`,
  `AFM`) or `@MainActor @Observable final class` stores (`QuestLibraryStore`, `ImageryGuideStore`,
  `DebriefEngine`).
- Value types crossing actor boundaries are marked `nonisolated` (e.g. `QuestIntensity`,
  `QuestCategory`, `ImageryGuide`).
- Views take `Binding<MokoTab>` with `.constant(...)` defaults; callbacks are optional closures
  (`onStartDebrief`, `onComplete`).
- Cross-screen actions go through environment values (`endSession`, `openOverview`) instead of
  passing view models.
- Networking stores expose `isLoading`, `errorMessage`, `hasAttemptedLoad` and always render an
  error state.
- Filenames are inconsistent (`Questdebrief.swift`, `Newquestscreen.swift`, `SwipeQuestionCard.swift`);
  match the surrounding naming when adding to a folder rather than renaming files.

---

## 10. Feature status (as of this file)

- **Flow / auth:** splash, intro, email-password sign-up/in, Google sign-in, account deletion
  (edge function). "Sign in with Apple" is a **UI stub** — `onContinueWithApple` fakes `"Apple User"`.
- **Onboarding:** intro carousel, name, age, welcome; 8 swipe questions scoring Courage / Clarity /
  Presence / Warmth; reflection; mic preprompt.
- **Overview:** today's mission (one slide completes it and opens the debrief), debrief
  resume/done versions, radar/insights cards, Calm Down summary entry, avatar → Profile sheet.
- **Quests:** list by day, create custom quest (category/intensity/date), detail, full debrief with
  scores and AFM coaching (reopens from the saved draft when one exists).
- **Relax:** box breathing (cycles + timer), breathing session, grounding, imagery guides
  (Supabase-driven, ambient audio), mirror reflection (front camera, nothing saved).
- **Calm Down Summary** (`UIScreens/homeScreens/Summary_CalmDown/Summaryview.swift`): Day / Week /
  Month / Year totals of logged calm-down time. The chart's top value comes from the tallest bar
  (`SummaryData.niceMax`), so the graph grows and shrinks with what the user actually logged instead
  of sitting on a fixed 30/60-minute ceiling; the axis labels switch to hours from 120 minutes up.
- **Explore:** Quest Library from Supabase with the system search field + sectioned cards (5 s minimum
  loader). The field belongs to the search tab (§4): selecting the tab collapses the tab bar around
  it, iOS focuses the field, and its ✕ ends search and returns to the previous tab.
  The title is a **collapsing header**: the 34 pt in-content `headerSection` scrolls away and a
  compact 44 pt "Quest Library" bar (centred, 17 pt semibold, lime backing that ignores the top safe
  area, 0.5 pt hairline) fades in above the cards. `scrollOffset` comes from
  `.onScrollGeometryChange` on the `ScrollView` (`contentOffset.y + contentInsets.top`, 0 at rest) and
  maps to opacity 0→1 between 24 and 56 pt, so the swap finishes exactly as the large title leaves.
  The bar is an `.overlay(alignment: .top)` — it must not be a `safeAreaInset`, which would move the
  cards while scrolling — and is `allowsHitTesting(false)` + `accessibilityHidden` below half opacity.
- **Profile:** XP/level, streak, badges/achievements (Rive unlock), costume wardrobe, insights chart,
  settings, notifications toggle, sign-out, delete account.
- **Not built yet:** WidgetKit, Live Activities, real Sign in with Apple, per-account cloud scoping,
  any automated tests.

---

## 11. Known pitfalls

1. **Editing the wrong copy.** `Moko/Features/Animation/MokoLottieView.swift` and
   `Moko/Features/ColorSystem/Colors.swift` are stale, out-of-target duplicates. Only
   `Moko/Moko/**` ships.
2. **README is stale** (iOS 17+, Xcode 15, Lottie-only, `MokoTests`, `ios-ci.yml`). Trust the
   pbxproj and this file.
3. **CI is broken** (`swift build` with no `Package.swift`). Fix or ignore knowingly.
4. **No shared scheme / no tests** — `xcodebuild test` has nothing to run.
5. **Secrets are hardcoded** in `SupabaseManager.swift`, `GoogleAuthService.swift`, and duplicated in
   `AuthService.deleteAccount`. `Secrets.example.xcconfig` is aspirational. Don't add a
   `service_role` key client-side; don't commit new secrets.
6. **AFM needs a real, eligible device.** The simulator usually has no model — always verify the
   fallback path, never block UI on the model.
7. **Library quests never become the daily mission** (`isFromLibrary` filters in
   `Quest.overviewMission`, `MokoRootView`, `DailyMissionService`).
8. **Tab-bar quirks:** keep `.tabViewSearchActivation(.searchTabSelection)`; search is a role-based tab.
   Without it iOS 27 renders the search tab as a fourth glued tab with no field at all (a title-less
   `Tab(value:role: .search)` behaves the same — `.automatic` never morphs on iOS 27). With
   `.searchTabSelection` the tab bar collapses around the field, and the field's ✕ is the system
   "deactivate search" control: it ends search *and* returns to the previously selected tab. There is
   no public hook for it — `dismissSearch()`, `.searchFocused`, `.searchable(isPresented:)`,
   `.searchToolbarBehavior(.minimize)` and a `TabView`-level `.searchable` were all measured against
   the live hierarchy and change nothing (the ✕ is a `UIButton` inside the private
   `_UITabHostedSearchContainer`). Apple's own apps behave this way, so don't "fix" it by re-selecting
   the search tab (that traps the user / needs two taps) or by drawing a custom field (loses the
   collapsing bar).
9. **SwiftData migrations are implicit.** Add defaults to new properties; the project has no
   versioned schema or migration plan.
10. **Quest Library deliberately delays** (`keepLoaderVisible`, 5 s) — don't "optimise" it away
    without a design decision.
11. **Assets are incomplete** — e.g. `RelaxSession.boxBreathing.bannerImageName` references
    `relax_box_breathing`, which is not in the catalog. Provide a fallback when adding imagery.
12. **Two locations for Supabase artefacts:** SQL migrations at the repo root, the edge function
    under `Moko/Moko/supabase/functions/`.
13. `Questdebrief.swift`'s header comment still names "Listening / Curiosity / Confidence"; the real
    parameters are Courage / Clarity / Presence / Warmth.
14. **Never run AFM in SwiftUI Previews.** The Mac-side preview process reports the model as
    available and does generate; after a few minutes of re-entrant scene updates FoundationModels
    asserts in `LanguageModelFeedback.swift` (line 528 on iOS 27) and the preview crashes with
    `EXC_BREAKPOINT`. `AFM.isAvailable` is gated on `AFM.isPreviewRuntime` — keep it that way.
15. **Only one `LanguageModelSession` request may be in flight.** Any new AFM code must go through
    `AFM.generate` (which queues on `AFMGenerationGate`); a second session started in parallel trips
    the same assertion even in a normal app run.
16. **A resumed debrief must not replay the greeting.** `DebriefSession.start()` branches on
    `isRestored`, and the draft's last message decides whether a follow-up still has to be asked
    (`resumeStep`). Change `followUpCount`, the message kinds or the submit order and the resume step
    has to change with them — otherwise the coach either repeats the question or leaves the user on
    an invisible one. `restore(from:)` is the only place that reads a `DebriefDraft`.
17. **There is no GUI Simulator in this environment.** `simctl` boots headlessly and
    `Simulator.app` is absent from Xcode, so touch flows can't be automated; verify behaviour with
    screenshots plus a temporary launch-argument harness that calls the real session code, then
    delete the harness.

---

## 12. Checklist before calling a change done

- [ ] Builds (Xcode ⌘B or `xcodebuild … build`) with no new warnings.
- [ ] Change is inside `Moko/Moko/**` (not the duplicate `Moko/Features/**`).
- [ ] New SwiftData property has a default; onboarding-complete path still resolves.
- [ ] Supabase-backed screens have loading, empty and error states.
- [ ] AFM paths degrade to the static fallback.
- [ ] Debrief changes keep both sides of the draft in sync (`Questdebrief.swift` ⇄
      `Models/DebriefDraft.swift`) — every new message kind needs a snapshot + restore mapping.
- [ ] Any new AFM work goes through `AFM.generate` (no bare `LanguageModelSession`), and still has a
      static Swift fallback for previews / no-Apple-Intelligence devices.
- [ ] Reduce Motion + accessibility labels respected for new motion.
- [ ] No secrets added; no `service_role` key on the client.
- [ ] This file updated (relevant sections + Change log).

---

## 13. Change log

Newest first. One entry per session: date, what changed, which files/sections.

| Date | Change |
|---|---|
| 2026-11-13 | **Quest Library keeps its title visible while scrolling.** `Features/QuestLibrary/QuestLibraryView.swift` gains a collapsing header: `scrollOffset` is read with `.onScrollGeometryChange` on the `ScrollView` (`contentOffset.y + contentInsets.top`, 0 at rest) and drives `compactTitleOpacity` (0→1 between 24 and 56 pt, i.e. exactly as the 34 pt in-content title leaves); the compact bar is a 44 pt centred 17 pt semibold "Quest Library" with a lime backing that `ignoresSafeArea(edges: .top)` — the first build let scrolled cards show through above the bar, hence the widened backing — plus a 0.5 pt `QuestStyle.title.opacity(0.12)` hairline, applied as `.overlay(alignment: .top)` so nothing reflows, `allowsHitTesting(false)`, `accessibilityHidden` below half opacity. The large header, the refresh button, the hidden navigation bar and the stock `.searchable` are unchanged. Section 10 updated. Verified on the simulator with a temporary `-MokoStartOnExplore` + `-MokoScrollLibrary` harness (both removed, `grep` clean): at rest only the large title shows; after a 240 pt scroll the small title is pinned under the status bar with no content bleeding above it; build clean. |
| 2026-11-13 | **Reverted every tab-bar/search change.** `Moko/Moko/MokoRootView.swift` and `Moko/Moko/Features/QuestLibrary/QuestLibraryView.swift` are back to `HEAD` (the only remaining diff in the root is the earlier "no Start Debrief" resume call). The search tab is stock again: `Tab("Explore", systemImage: "magnifyingglass", value: .search, role: .search)` + `.tabViewSearchActivation(.searchTabSelection)`, no `import UIKit`, no `lowerSearchKeyboard()`, no `onChange(of: selectedTab)` keyboard pass, no `.searchable` on the `TabView`, `QuestLibraryView` keeps its own `@State searchText` and `.searchable(placement: .navigationBarDrawer(displayMode: .always))`. Trigger: the requested "✕ should only hide the keyboard" cannot be built on public API — measured on the live hierarchy, the ✕ is a `UIButton` in the private `_UITabHostedSearchContainer` whose action deactivates search and selects the previous tab (`tab=search` → `tab=overview`), and `dismissSearch()`, `.searchFocused`, `.searchable(isPresented:)`, `.searchToolbarBehavior(.minimize)`, a `TabView`-level `.searchable` and a title-less `Tab(value:role: .search)` with `.automatic` all leave that behaviour (or remove the field entirely) untouched. All temporary launch-argument harnesses removed (`grep` verified) and the keyboard-notification probe deleted. Sections 4, 10, 11.8 rewritten. Build clean; simulator screenshot shows the original 3 tabs + detached search button. |
| 2026-11-13 | Reverted the screen-owned Explore search field: `Features/QuestLibrary/QuestLibraryView.swift` is back to its original `.searchable(text:placement: .navigationBarDrawer(displayMode: .always))` (byte-identical to `HEAD`). The keyboard on search-tab selection is now handled where the tab lives — `MokoRootView.swift` keeps `.tabViewSearchActivation(.searchTabSelection)` (the only mode that gives the detached search button and the tab bar collapsing around the field) and adds `.onChange(of: selectedTab, initial: true)` → `lowerSearchKeyboard()`, called immediately and again after 180 ms so the framework cannot leave the field focused. Result: selecting Explore shows the library in the collapsed bar with the keyboard down and nothing shifted; the field focuses on a real tap. Tried and rejected: `.automatic` (search tab renders as a fourth glued tab, no field), `.searchable` on the `TabView`, `.searchable(isPresented:)`, `.searchFocused`, `.searchToolbarBehavior(.minimize)` — none of them prevent the automatic focus. Sections 4, 10, 11 updated. Verified with simulator screenshots (forced Explore at launch via a temporary `-MokoStartOnExplore` argument, since removed): collapsed bar + unfocused field + no keyboard; build clean. |
| 2026-11-13 | Explore no longer hijacks the keyboard: `Features/QuestLibrary/QuestLibraryView.swift` dropped `.searchable` and draws its own search pill (magnifier + `TextField` + cross, `@FocusState`) above the `ScrollView`, so selecting the search tab lands on the library with no keyboard and nothing shifts; focus only moves when the field is tapped, and the cross clears the query + hides the keyboard instead of leaving the screen (the system field's ✕ used to deactivate the search tab and bounce back to the previous tab). Header/field pinned outside the scroll view, `scrollDismissesKeyboard(.interactively)`, `onSubmit` only dismisses. `MokoRootView.swift` comment updated. Sections 4, 10, 11 updated. Verified with simulator screenshots: idle = no keyboard, focused = keyboard up with header and field in the same place, tab bar still 3 tabs + detached search button. |
| 2026-11-13 | Calm Down → Summary chart scales to the data: removed the "Swipe horizontally to explore …" hint (all four ranges), rewrote `SummaryData.niceMax` as a magnitude-based nice-number ceiling with 20% headroom (was a hard 30/60-minute floor, so short sessions looked empty) and updated `axisText` (minutes below 120, hours with one rounded decimal above). Section 10 updated. Verified headlessly: 20 s → max 2 min, 5 min → 8, 12 min → 15, 45 min → 60, 90 min → 150 (60–80% bar fill in every case); build clean. |
| 2026-11-13 | Stopped the mission pill flashing "Slide to Debrief" while the debrief cover animates in: `Overview.swift` gained `isHandingOffToDebrief`, set for ~1.2 s from the slide, so `slideTitle` stays "Slide to Complete" until the cover hides the card (the SwiftData `isCompleted` flip no longer leaks into the visible transition). Section 4 updated. Build verified. |
| 2026-11-13 | One slide, one destination: the `.todo` Overview pill completes the quest and opens the debrief in the same gesture (`UIScreens/homeScreens/Overview.swift`), so "Slide to Debrief" only appears when a completed quest has no debrief yet. Resume now restores the conversation: new `Models/DebriefDraft.swift` (`DebriefDraft` + `DebriefDraftStore`, one UserDefaults entry per quest) and `DebriefSession` persists after every message/grade and `restore(from:)`s mid-conversation (`UIScreens/Quests/Questdebrief.swift`) — no greeting replay, a follow-up that never arrived is re-asked (`resumeStep`), four saved answers jump to the score panel; drafts cleared on complete/leave (`exit(_:)`, `recordDebrief`), `clearAll()` on account deletion (`DeleteAccountFinalConfirm.swift`). `OverviewResumeScreen` now shows "N of 4 answers saved". Sections 4, 5, 10, 11, 12 updated. Verified headlessly (no GUI Simulator in this environment): save→restore identical, mid-flight asks the question once, four-answer resume completes — all PASS; temporary harness removed, build clean. |
| 2026-11-13 | Removed the "Start Debrief" / mic state from both Overview versions and unified the sliders into one `OverviewSlideControl` (in `UIScreens/homeScreens/Overview.swift`, reused by `OverviewResumeScreen.swift`): `.todo` slides "Slide to Complete" → "Slide to Debrief", `.resume` slides "Slide to Resume"; both open the debrief directly, so leaving a debrief no longer strands the user on a Start Debrief button. Dropped `slideOffset` / `isResumeCompleted` state, the now-unused `micGreen` tokens, and `OverviewResumeScreen.onStartDebrief` (call site in `MokoRootView.swift` updated). Sections 4 and 10 updated. Build verified, simulator screenshot confirmed the new pill. |
| 2026-11-13 | Overview slide now goes straight into the debrief: `Moko/Moko/UIScreens/homeScreens/Overview.swift` calls `QuestProgress.complete` **and** then opens the debrief from the slide's `onEnded` (matching `QuestSlideButton` in `Questdetailscreen.swift`), and the insert-then-open logic moved into one `startDebrief(for:)` helper shared with the "Start Debrief" button. Sections 4 and 10 updated. Build verified. |
| 2026-11-13 | Fixed the SwiftUI-Preview crash `assert in LanguageModelFeedback.swift:528`: `Moko/Moko/Features/AFM/MokoAFM.swift` now serializes every generation through a new `AFMGenerationGate` actor, retries only on transient faults (classifies iOS 26 `GenerationError` and iOS 27 `LanguageModelError` / `LanguageModelSession.Error`), checks cancellation per attempt, and reports `isAvailable == false` inside previews via `AFM.isPreviewRuntime`. Also handled `.modelNotReady` in `availabilityDescription` (clears a pre-existing warning). Sections 6, 11, 12 updated. Build verified: `xcodebuild … build` succeeded, no warnings in the file. |
| 2026-11-13 | Created `context.md`: toolchain, target membership rules, app flow, data layer, AFM layer, design system, animation stack, conventions, feature status, pitfalls, checklist. No source files changed. |
