---
kind: configuration_system
name: 'iOS App Configuration: Hardcoded Values + xcconfig Template'
category: configuration_system
scope:
    - '**'
source_files:
    - Secrets.example.xcconfig
    - Moko/Moko/SupabaseManager.swift
    - Moko/Moko/GoogleAuthService.swift
    - Moko/Moko/Info.plist
    - Moko/Moko/MokoApp.swift
---

## What system/approach is used

Moko has no centralized runtime configuration framework. Configuration is split across three Apple-native mechanisms:

1. **Xcode `*.xcconfig`** — secret/URL values are intended to be supplied via an `Secrets.xcconfig` file (template at `Secrets.example.xcconfig`).
2. **`Info.plist`** — bundle-level metadata such as URL schemes and permission descriptions.
3. **Hardcoded Swift literals** — Supabase endpoint/key and Google client IDs are embedded directly in source code.

There is no `.env`, no feature-flag library, no runtime config loader, and no environment-based branching.

## Key files and packages

- `Secrets.example.xcconfig` — template defining `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_WEB_CLIENT_ID`.
- `Moko/Moko/SupabaseManager.swift` — singleton that constructs the `SupabaseClient` with a literal URL and publishable key.
- `Moko/Moko/GoogleAuthService.swift` — hardcodes Google Sign-In client/server client IDs into `GIDConfiguration`.
- `Moko/Moko/Info.plist` — declares `CFBundleURLTypes` (Google OAuth redirect scheme) and camera/mic usage descriptions.
- `Moko/Moko/MokoApp.swift` — application entry point; initializes SwiftUI model containers but performs no config loading.

## Architecture and conventions

- **Secrets via xcconfig**: The repo ships only `Secrets.example.xcconfig`; developers are expected to copy it to `Secrets.xcconfig` and fill in real values. The example keys are clearly placeholders (`YOUR_SUPABASE_PROJECT_URL`, etc.).
- **Runtime defaults are baked in**: `SupabaseManager` hardcodes the production Supabase URL (`https://qyxnhmnfzcxbtphzwsiq.supabase.co`) and a publishable key. `GoogleAuthService` hardcodes both the iOS and web Google client IDs. These values are not read from `Info.plist` or `UserDefaults`.
- **Bundle identifiers in Info.plist**: The Google OAuth redirect URL scheme is declared statically in `Info.plist` under `CFBundleURLTypes`, matching the iOS client ID in `GoogleAuthService`.
- **No runtime config layer**: There is no `Config` struct, no `EnvironmentObject`/`@StateObject` holding configuration, no `FeatureFlags` enum, and no `UserDefaults`-based settings store. Feature toggles or environment variants do not exist in the codebase.
- **Build-time vs runtime separation**: Build-time values (via xcconfig) are never referenced by any Swift file found in the scan — the grep for `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` / `GOOGLE_IOS_CLIENT_ID` / `GOOGLE_WEB_CLIENT_ID` returned zero matches. This means the xcconfig template exists but is currently unused by the active sources; the app instead runs with the hardcoded values.

## Conventions and constraints

- Secrets are kept out of version control: only `Secrets.example.xcconfig` is committed; the real `Secrets.xcconfig` is expected to be local-only.
- Third-party credentials (Supabase URL/key, Google client IDs) are treated as compile-time constants in Swift rather than being loaded from plist or user defaults.
- Permission strings for camera and microphone access are declared declaratively in `Info.plist` rather than requested programmatically at runtime.
- No feature flags, A/B tests, or remote configuration endpoints are present in the repository.