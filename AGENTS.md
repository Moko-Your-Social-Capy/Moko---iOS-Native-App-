# AGENTS.md: Moko iOS Code Rules

Read this file before you write, move or delete any code. These rules apply to every AI agent and every human editing Moko.

## 1. Target and tools
- Language: Swift 6. UI: SwiftUI only. No UIKit unless Apple has no SwiftUI option (write a comment saying why).
- Minimum iOS: set in one place (the project target). Use the newest APIs from that version.
- Use Apple documentation first: https://developer.apple.com/documentation/swiftui and https://developer.apple.com/documentation/foundationmodels
- Never invent an API. If you are not sure a modifier exists, search Apple docs first.

## 2. Before you change code: scan
1. Walk the whole folder tree. Write down every file and its job in one line.
2. Find unused code:
   - Run Periphery (free, open source): `periphery scan --setup` then `periphery scan`.
   - Check the results by hand. Periphery can miss code used only by Rive, SwiftData macros or previews.
3. Never delete these without asking the owner:
   - SwiftData models and migration code (they hold user data).
   - Rive files, animation names and their state-machine input names.
   - Localized strings and anything used by Supabase or Firebase.
4. Delete in small commits, one feature at a time. Build and run after each one.

## 3. Modern SwiftUI style (write it this way)
- State: use `@Observable` classes with `@State`, `@Bindable`, `@Environment`. Do not use `ObservableObject` or `@StateObject` in new code.
- Navigation: `NavigationStack` with `navigationDestination(for:)`. Do not use `NavigationView`.
- Tabs: `Tab` inside `TabView`.
- Colours and fonts: `foregroundStyle`, not `foregroundColor`. Use semantic colours and text styles (`.font(.title)`), not fixed sizes.
- Lists and grids: `List`, `LazyVGrid`, `LazyVStack` for long content.
- Async work on appear: use `.task { }`, not `.onAppear { Task { } }`.
- Change watching: use the two-value form `.onChange(of: value) { old, new in }`.
- Symbols: `Image(systemName:)` with `.symbolEffect(...)` for small motion.
- Haptics: `.sensoryFeedback(.success, trigger: value)`.
- Never use `AnyView`, `print` (use `Logger`), force unwrap `!` (use `guard let`), or `DispatchQueue.main.async` (use `@MainActor`).
- One view = one struct. Keep `body` short. Move big parts into small child views.

## 4. Comments: explain like to a 5-year-old
Add a comment above every important line: a modifier that is new or unusual, `onAppear` or `.task`, any Apple framework call (SwiftData, FoundationModels, UserNotifications, ActivityKit, AVFoundation, Speech), and any state property.

Rules:
- One short line, plain words, no jargon. Say what it does and why we need it.
- Do not repeat the code. Explain the idea.
- Do not write a comment on obvious lines (`let x = 1`).

Examples:

```swift
// This is a box that remembers if it is on or off.
// When it changes, the screen redraws by itself.
@State private var isOn = false

// .task runs this code when the screen first shows up.
// It is like saying "start this job now".
.task {
    await loadQuests()
}

// SwiftData is Apple's storage. It saves our data on the phone.
@Query private var quests: [Quest]

// .symbolEffect makes the icon wiggle one time when the value changes.
Image(systemName: "flame.fill")
    .symbolEffect(.bounce, value: streakCount)
```

## 5. Folder structure (feature first)
Find any screen or file in under 10 seconds. Group by feature, not by file type.

```
Moko/
  App/                    App entry point, root tabs, app-level router
    MokoApp.swift
    RootTabView.swift
  Features/               One folder per screen or flow
    Overview/             OverviewView.swift, OverviewViewModel.swift, Components/
    Quests/               QuestsView.swift, QuestDetailView.swift, Components/
    CalmDown/             CalmDownView.swift, BreathingTimer.swift
    Debrief/              DebriefView.swift, DebriefJudge.swift, Tokeniser.swift
    Insights/             InsightsView.swift, RadarChart.swift
    Profile/              ProfileView.swift, EditProfileView.swift, Wardrobe/
    Onboarding/           OnboardingFlow.swift, one file per step
    Settings/             SettingsView.swift, PrivacyView.swift
  Core/                   Logic with no screens
    Data/                 SwiftData models, repositories, migrations
    Services/             Notifications, Speech, Audio, FoundationModels (AFM)
    Backend/              Supabase and Firebase clients
    Scoring/              XP, levels, streak rules (pure Swift, easy to test)
  DesignSystem/           Colours, spacing, buttons, cards, shared styles
  Resources/
    Assets.xcassets/
    Rive/                 .riv files only
    Audio/
  Tests/                  Mirrors the Features and Core folders
```

Naming rules:
- One main type per file. The file name is the type name: `OverviewView.swift` holds `OverviewView`.
- Views end in `View`. View models end in `ViewModel`. Services end in `Service`.
- Components in a `Components/` folder inside their feature.
- No folder named `Misc`, `Helpers` or `Utils`. Put the code where it belongs.
- Keep files under about 250 lines. Split when they grow.

## 6. Working as an agent
- Change one feature at a time. Explain what you changed in plain words.
- Keep a `CHANGELOG.md` line per change: date, file, what and why.
- Build after each change. If the build fails, fix it before moving on.
- If a rule here conflicts with a request, follow the request and say so.
- Never add a new library without asking. Prefer Apple frameworks first.
