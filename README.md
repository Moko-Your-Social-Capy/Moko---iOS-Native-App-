## Moko - Your Social Capy
<h1 align="center">MOKO 🦫</h1>

<p align="center">
  <b>Your Social Capybara</b><br/>
  A native iOS social-wellness app where a calm capybara coach guides you through breathing, reflection and everyday confidence.
</p>


<p align="center">
  <a href="https://github.com/Moko-Your-Social-Capy/Moko---iOS-Native-App-/actions/workflows/ios-ci.yml">
    <img src="https://github.com/Moko-Your-Social-Capy/Moko---iOS-Native-App-/actions/workflows/ios-ci.yml/badge.svg" alt="CI"/>
  </a>
  <img src="https://img.shields.io/badge/iOS-17%2B-black?logo=apple" alt="iOS 17+"/>
  <img src="https://img.shields.io/badge/Swift-5.9%2B-orange?logo=swift" alt="Swift 5.9+"/>
  <img src="https://img.shields.io/badge/SwiftUI-native-blue" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/status-in%20development-yellow" alt="Status: in development"/>
</p>

> ⚠️ **MOKO is a self-improvement and wellness app.** It is not a medical device and does not diagnose, treat or prevent any condition. If you are struggling, please contact a qualified professional or local emergency services.

---

## Table of contents

- [What is MOKO?](#what-is-moko)
- [Features and status](#features-and-status)
- [Screenshots](#screenshots)
- [The mascot and animations](#the-mascot-and-animations)
- [Architecture](#architecture)
- [Getting started](#getting-started)
- [Testing](#testing)
- [CI/CD](#cicd)
- [Privacy](#privacy)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [License](#license)

---

## What is MOKO?

MOKO makes wellness feel approachable. A capybara coach appears at meaningful moments (onboarding, a breathing session, a completed goal) rather than crowding the interface. Around it sits a set of guided practices, personal insights and light gamification, all in an Apple-native UI.

**Product principles**

- **Emotional wellness:** help people notice and name what they feel.
- **Social confidence:** build comfort in everyday interactions, one small step at a time.
- **Guided self-improvement:** turn growth into activities that fit into a day.
- **Gamification with restraint:** use progress and the mascot to make consistency rewarding, without punishing missed days.
- **Privacy by default:** onboarding and reflection data stay under the user's control.

---

## Features and status

| Area | Feature | Status |
|---|---|---|
| Navigation | Shared tab bar driven by a single `MokoTab` enum | ✅ Implemented, being refined |
| Relax | Guided breathing with start, pause, resume, reset and completion | ✅ Implemented |
| Relax | Guided imagery, grounding and mirror exercises | 🚧 In progress |
| Relax | Timed sessions and completion screen | 🚧 In progress |
| Mascot | Lottie animations via `MokoLottieView` | 🚧 Integrated, sizing and rendering being debugged |
| Insights | Presence, Courage, Clarity, Warmth dimensions | 🚧 In progress |
| Insights | Day / Week / Month / Year summaries (Swift Charts) | 📋 Planned |
| Profile | Personal progress, achievements and milestones | 🚧 In progress |
| Onboarding | Welcome flow and inward-to-outward questions | 🚧 In progress |
| Auth | Supabase authentication | 🚧 Architecture defined, verify before release |
| Auth | Sign in with Apple and Google | 📋 Planned |
| Storage | SwiftData for local onboarding and private data | 🚧 In progress |
| Apple | WidgetKit widgets | 📋 Planned |
| Apple | ActivityKit Live Activities | 📋 Planned |
| Release | App Store distribution | 📋 Not yet released |

✅ Implemented · 🚧 In progress · 📋 Planned

---

### Relax & Calm Down

The Relax tab is the core experience:

1. **Relax home** lists breathing, grounding, imagery and mirror exercises.
2. **Guided imagery list** shows the available guides.
3. **Guide detail** explains the exercise and its duration.
4. **Timed session** runs the exercise with the capybara animating behind the controls.
5. **Completion** celebrates the session and returns the user to Relax. The tab bar stays visible throughout.

The breathing timer is independent of the animation. The mascot is purely presentational, so a dropped frame never affects the timing.

---

## Screenshots

> Captured on iPhone 15 Pro (Simulator), light mode unless noted.

| Welcome | Home | Relax |
|---|---|---|
| ![Welcome](docs/screenshots/01-welcome.png) | ![Home](docs/screenshots/02-home.png) | ![Relax](docs/screenshots/03-relax.png) |

| Guided imagery | Breathing session | Completion |
|---|---|---|
| ![Imagery](docs/screenshots/04-imagery.png) | ![Breathing](docs/screenshots/05-breathing.png) | ![Completion](docs/screenshots/06-completion.png) |

| Insights | Profile | Dark mode |
|---|---|---|
| ![Insights](docs/screenshots/07-insights.png) | ![Profile](docs/screenshots/08-profile.png) | ![Dark](docs/screenshots/09-dark.png) |

---

## The mascot and animations

Moko is a flat-vector capybara with a friendly, calm expression. Animations are Lottie JSON files rendered with [lottie-ios](https://github.com/airbnb/lottie-ios).

| Animation | File | Duration | Loop | Used on |
|---|---|---|---|---|
| Hello | `MokoHello.json` | 2.5 s | Play once | Welcome |
| Meditation | `MokoMeditation.json` | 4 s | Loop | Breathing background |
| Listening | `MokoListening.json` | 3 s | Loop | Conversation and coaching |
| Complete | `MokoComplete.json` | 2.5 s | Play once | Session and goal completion |
| Idle | `MokoIdle.json` | 2.5 s | Loop | Dashboard and empty states |

**Palette**

| Name | Hex | Use |
|---|---|---|
| Forest | `#1B422F` | Primary actions and branding |
| Capybara | `#C7A778` | Mascot body |
| Cream | `#DAC095` | Mascot body highlight |
| Mint | `#CBE6D3` | Backgrounds and gradients |
| Outline | `#4A3826` | Mascot outline |
| Lime | `#B7DB75` | Accent highlights |

**Usage**

```swift
import SwiftUI
import Lottie

MokoLottieView(
    animationName: "MokoListening",
    loopMode: .loop,
    frameWidth: 280
)
```

Animations respect **Reduce Motion**: when it is on, Moko shows a still frame instead of playing.

---

## Architecture

| Layer | Technology | Purpose |
|---|---|---|
| UI | SwiftUI | Screens and navigation |
| Language | Swift | Application logic |
| Local data | SwiftData | Onboarding and private user data |
| Auth | Supabase | Sign-in and account management |
| Animation | Lottie + SwiftUI | Animated mascot |
| Charts | Swift Charts | Wellness insights |
| Apple platform | WidgetKit, ActivityKit | Widgets and Live Activities (planned) |
| Design | SF Symbols, SF Pro Rounded | Native iconography and typography |

### Navigation

Tabs are defined once in `Models/MokoTab.swift` and shared by `MokoRootView`, `MainHomeContainerView`, `Overview`, and `RelaxScreen`, so tab selection has a single source of truth.

The Relax flow uses a `RelaxStep` enum:

```swift
enum RelaxStep: Hashable {
    case guideList
    case guideDetail(ImageryGuide)
    case session(ImageryGuide)
    case complete(ImageryGuide)
}
```

`ImageryGuide` must conform to `Hashable` for this to compile.

### Project structure

```
Moko---iOS-Native-App-/
├── Moko/
│   ├── Models/
│   │   ├── MokoTab.swift
│   │   └── QuestModels.swift
│   ├── Features/
│   │   └── Animation/
│   │       ├── MokoLottieView.swift
│   │       ├── MokoAnimationTypes.swift
│   │       └── MokoAnimationController.swift
│   ├── Resources/
│   │   └── Animations/            # Lottie JSON files
│   ├── UIScreens/
│   │   ├── startScreens/          # Welcome and onboarding
│   │   ├── homeScreens/           # Home, Overview, Insights
│   │   └── relaxScreens/          # Relax flow and breathing timer
│   └── App/
│       ├── MokoApp.swift
│       └── ContentView.swift
├── MokoTests/
├── docs/
│   └── screenshots/
└── .github/workflows/
    └── ios-ci.yml
```

---

## Getting started

### Requirements

- Xcode 15 or later (verify the version your project targets)
- iOS 17.0+ deployment target (SwiftData requires it)
- An Apple Developer account, for Sign in with Apple and device testing

### Setup

```bash
git clone https://github.com/Moko-Your-Social-Capy/Moko---iOS-Native-App-.git
cd Moko---iOS-Native-App-
open Moko/Moko.xcodeproj
```

1. **Add Lottie.** In Xcode, go to **File → Add Package Dependencies** and enter `https://github.com/airbnb/lottie-ios`.
2. **Configure Supabase.** Copy the template and fill in your project values:

   ```bash
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```

   ```xcconfig
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key
   ```

   `Secrets.xcconfig` is listed in `.gitignore`. **Never commit it, and never put a `service_role` key in the app.** Only the public anon key belongs on the client.
3. **Select a scheme and simulator.** Choose the `Moko` scheme and an iPhone simulator, then press **⌘R**.

---

## Testing

```bash
xcodebuild test \
  -project Moko/Moko.xcodeproj \
  -scheme Moko \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Or press **⌘U** in Xcode.

| Area | What's covered |
|---|---|
| Breathing timer | Start, pause, resume, reset and completion state transitions |
| Navigation | `MokoTab` selection and `RelaxStep` transitions |
| Insights | Aggregation for Day / Week / Month / Year ranges |

Snapshot tests for key screens are planned.

---

## CI/CD

Every pull request runs a build and test job on GitHub Actions. The workflow lives at `.github/workflows/ios-ci.yml`:

```yaml
name: iOS CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Build and test
        run: |
          xcodebuild test \
            -project Moko/Moko.xcodeproj \
            -scheme Moko \
            -destination 'platform=iOS Simulator,name=iPhone 15' \
            CODE_SIGNING_ALLOWED=NO
```

TestFlight delivery via Fastlane is planned.

---

## Privacy

MOKO is built around these commitments:

- **Local first.** Onboarding answers and reflections are stored on-device with SwiftData.
- **Explicit permissions.** The app asks only when a feature needs something.
- **Minimal collection.** Account data goes to Supabase only for authentication.
- **Transparent disclosure.** The App Store privacy label and in-app policy will describe what is collected and why.
- **Regulatory planning.** Compliance work covers Apple's App Store Review Guidelines and India's Digital Personal Data Protection Act. This is in progress and has not been certified.
- **No misleading claims.** MOKO does not claim to treat anxiety, depression or any other condition.

---


## Contributing

1. Branch from `main`: `feature/<short-name>`, `fix/<short-name>` or `chore/<short-name>`.
2. Keep commits small and use imperative messages, e.g. `Add pause state to breathing timer`.
3. Open a pull request with a screenshot or screen recording for any UI change.
4. CI must pass before merge.

Please don't include personal data, real user information or secrets in issues, PRs or screenshots.

---

## License

TBD. Choose a license before making the repository public.

---

## Acknowledgements

- [Lottie](https://github.com/airbnb/lottie-ios) by Airbnb for mascot animation
- [Supabase](https://supabase.com) for authentication
- Apple's SF Symbols and SF Pro for the native visual language

<p align="center">
  <i>Made with 🌿 and a very calm capybara.</i>
</p>
