---
kind: configuration_system
name: 'iOS App Configuration: Hardcoded Secrets, Info.plist, and Unused xcconfig Template'
category: configuration_system
scope:
    - '**'
source_files:
    - Secrets.example.xcconfig
    - .gitignore
    - Moko/Moko/Info.plist
    - Moko/Moko/SupabaseManager.swift
    - Moko/Moko/MokoApp.swift
---

## What system/approach is used

The Moko iOS app uses **no centralized runtime configuration framework**. Configuration is split across three ad-hoc sources:

1. **Xcode build-time secrets via `.xcconfig`** — an example template (`Secrets.example.xcconfig`) defines keys `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`. The real `Secrets.xcconfig` is gitignored (see `.gitignore`).
2. **`Info.plist`** — Apple bundle configuration (URL schemes for Google sign-in, camera/mic usage descriptions).
3. **Hardcoded values in Swift source** — the production Supabase URL and publishable key are embedded directly in `SupabaseManager.swift`.

There is no feature-flag system, no environment-based config loader, no `.env` files, and no runtime config layer beyond these static sources.

## Key files and packages

- `Secrets.example.xcconfig` — template of secret keys expected by the build; not included in the repo.
- `.gitignore` — explicitly excludes `Secrets.xcconfig` to prevent secrets from leaking.
- `Moko/Moko/Info.plist` — bundle-level configuration: Google OAuth redirect scheme (`com.googleusercontent.apps.431501174320-7d0a18atrmlqedt15le8039j21qdkdih`), NSCameraUsageDescription, NSMicrophoneUsageDescription.
- `Moko/Moko/SupabaseManager.swift` — singleton that constructs the `SupabaseClient` with a hardcoded URL and key.
- `Moko/Moko/MokoApp.swift` — app entry point; initializes SwiftUI + SwiftData containers but performs no config loading.

## Architecture and conventions

- **No config abstraction**: There is no `Config` struct, enum, or protocol that centralizes settings. Consumers read secrets either from `Bundle.main.infoDictionary` (for plist values) or directly from hard-coded strings.
- **Build-time vs runtime split**: `.xcconfig` is intended for per-environment secrets at build time, but the only file that consumes them (`SupabaseManager.swift`) does not reference any `$(SUPABASE_*)` macro — it instead hardcodes the Supabase endpoint and key. This means the `.xcconfig` template is currently unused by the active code path.
- **Google OAuth scheme** is baked into `Info.plist` rather than loaded from config, so changing the client ID requires editing the plist.
- **No environment detection**: There is no staging/production/environment switch; the same binary always connects to the same Supabase instance.
- **No feature flags**: Feature toggles do not exist as a configuration concern. UI behavior is controlled by SwiftData models (e.g. `OnboardingState`, `Profile`) and SwiftUI state, not by a config flag.

## Conventions and constraints

- **Rule enforced by `.gitignore`**: `Secrets.xcconfig` must not be committed to the repository; developers copy `Secrets.example.xcconfig` to `Secrets.xcconfig` and fill in values locally.
- **Rule implied by `Secrets.example.xcconfig`**: A local `Secrets.xcconfig` should define `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, and `GOOGLE_WEB_CLIENT_ID` — although the current `SupabaseManager.swift` does not consume these keys, so adding this file has no effect on the running app unless the source is updated to use `$(SUPABASE_URL)` / `$(SUPABASE_PUBLISHABLE_KEY)` macros.
- **Constraint enforced by `Info.plist`**: Google Sign-In requires the bundle's `CFBundleURLSchemes` to match the registered OAuth redirect scheme; changing the Google client ID requires updating both the plist and the Google Cloud Console.
- **Constraint observed in `SupabaseManager.swift`**: The Supabase URL and key are literal Swift string literals, making them impossible to override without modifying source code or using Xcode preprocessor macros (which are not set up here).

## Summary

This is a minimal iOS app with a very thin configuration surface area. The intended pattern is `.xcconfig` for secrets plus `Info.plist` for bundle metadata, but the active code path bypasses `.xcconfig` entirely and hardcodes credentials. There is no runtime configuration system, no environment switching, and no feature-flag infrastructure.