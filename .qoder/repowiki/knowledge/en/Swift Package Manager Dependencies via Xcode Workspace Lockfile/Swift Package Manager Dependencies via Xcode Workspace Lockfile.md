---
kind: dependency_management
name: Swift Package Manager Dependencies via Xcode Workspace Lockfile
category: dependency_management
scope:
    - '**'
source_files:
    - Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - Moko/Moko.xcodeproj/project.pbxproj
    - Moko/Moko/SupabaseManager.swift
    - Moko/skills-lock.json
---

## Approach

The Moko iOS app uses **Swift Package Manager (SPM)** exclusively for third-party dependency resolution. There is no `Package.swift` at the repository root; instead, dependencies are declared inside the Xcode project and resolved into a workspace-level lockfile.

## Key Files

- `Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — the canonical SPM lockfile pinning every transitive dependency to an exact Git revision and version tag.
- `Moko/Moko.xcodeproj/project.pbxproj` — where the package URLs and version requirements are registered with Xcode (the actual `.package(...)` declarations live here).
- `Moko/skills-lock.json` — locks the internal `.agents/skills/rive-animation` agent skill (not a Swift package).
- `supabase/.temp/cli-latest` — tracks the Supabase CLI binary used for migrations/seeding.

## Pinned Dependencies

The lockfile pins 18 packages, all sourced from remote Git repositories:

| Identity | Source | Version |
|---|---|---:|
| `app-check` | `github.com/google/app-check.git` | 11.3.2 |
| `appauth-ios` | `github.com/openid/AppAuth-iOS.git` | 3.0.0 |
| `googlesignin-ios` | `github.com/google/GoogleSignIn-iOS` | 10.0.0 |
| `googleutilities` | `github.com/google/GoogleUtilities.git` | 8.1.5 |
| `gtm-session-fetcher` | `github.com/google/gtm-session-fetcher.git` | 5.3.1 |
| `gtmappauth` | `github.com/google/GTMAppAuth.git` | 6.0.0 |
| `interop-ios-for-google-sdks` | `github.com/google/interop-ios-for-google-sdks.git` | 101.0.0 |
| `lottie-ios` | `github.com/airbnb/lottie-ios` | 4.6.1 |
| `promises` | `github.com/google/promises.git` | 2.4.1 |
| `rive-ios` | `github.com/rive-app/rive-ios` | 6.29.0 |
| `supabase-swift` | `github.com/supabase/supabase-swift` | 2.55.4 |
| `swift-asn1` | `github.com/apple/swift-asn1.git` | 1.7.3 |
| `swift-clocks` | `github.com/pointfreeco/swift-clocks` | 1.1.1 |
| `swift-concurrency-extras` | `github.com/pointfreeco/swift-concurrency-extras` | 1.4.3 |
| `swift-crypto` | `github.com/apple/swift-crypto.git` | 4.5.2 |
| `swift-http-types` | `github.com/apple/swift-http-types.git` | 1.8.0 |
| `swift-issue-reporting` | `github.com/pointfreeco/swift-issue-reporting` | 2.1.2 |
| `xctest-dynamic-overlay` | `github.com/pointfreeco/xctest-dynamic-overlay` | 1.13.1 |

## Architecture & Conventions

- **No vendored sources**: All packages are pulled from GitHub over HTTPS at resolve time; there is no `vendor/`, `Pods/`, or checked-in source tree.
- **Workspace-scoped lockfile**: The lockfile lives under `project.xcworkspace/.../swiftpm/`, which is the default Xcode location when packages are added through the Xcode UI rather than a top-level `Package.swift`.
- **Version + revision dual-pinning**: Each entry records both a semantic version tag and the exact commit SHA (`revision`) that was resolved, ensuring reproducible builds even if tags move.
- **Dependency usage is centralized in a few modules**:
  - `Supabase` is imported by `AuthService.swift`, `GoogleAuthService.swift`, `SupabaseManager.swift`, `QuestLibraryService.swift`, and `ImageryGuideStore.swift`.
  - `Lottie` is imported by `Features/Animation/MokoLottieView.swift` and `Features/Animation/MokoAnimationTypes.swift`.
  - `RiveRuntime` is imported by `BadgeUnlockRiveView.swift`, `Breathingsessionscreen.swift`, and `MokoAnimatedMascotView.swift`.
- **Internal assets vs. packages**: Rive animation scenes are not consumed as packages — they are authored in `RiveProjects/` and compiled into `.riv` assets embedded directly in the Xcode target.
- **No private registry or `GOPRIVATE`-style configuration**: No `.swiftpmconfig`, custom registries, or authentication tokens are present in the repo.
- **Supabase client credentials are hardcoded** in `SupabaseManager.swift` (URL and publishable key), so backend access does not go through a separate dependency-managed config file.

## Constraints & Rules

- The lockfile format is SPM v3 (`"version": 3`), which is enforced by Xcode's built-in SwiftPM integration.
- Because the lockfile is committed, CI (`.github/workflows/swift.yml`) can rely on deterministic dependency resolution without needing network access to fetch package manifests beyond what Xcode requires.
- There is no automated dependency update tool (no Dependabot, Renovate, or similar) detected in the repository; updates would be performed manually through Xcode's "Update to Latest Versions" flow.