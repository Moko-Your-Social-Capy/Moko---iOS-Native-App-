---
kind: dependency_management
name: Swift Package Manager Pinning via Package.resolved (Xcode SPM)
category: dependency_management
scope:
    - '**'
source_files:
    - Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - Moko/skills-lock.json
    - .github/workflows/swift.yml
---

## Approach

The Moko iOS app uses **Apple's Swift Package Manager (SPM)** exclusively for third-party dependency resolution. There is no `Package.swift` at the repository root — the project is an Xcode workspace (`Moko/Moko.xcodeproj`) and dependencies are declared inside Xcode's package integration, with the resolved state committed to source control.

## Key Files

- `Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — the single source of truth for pinned versions. It records each dependency's identity, remote git URL, exact commit SHA, and semantic version.
- `Moko/skills-lock.json` — a custom lockfile for the in-repo `.agents/skills/rive-animation/` agent skill (source: `iabhi1610/rive-animation-skill`, GitHub). This is separate from SPM and tracks AI agent skills rather than code dependencies.
- `.github/workflows/swift.yml` — CI workflow that runs `swift build` / `swift test`. Note: this workflow invokes `swift build` at the repo root, but there is no `Package.swift` at the root; the actual Xcode project lives under `Moko/`. The context file explicitly calls out that `swift test` at the repo root cannot work because there is no `Package.swift`.

## Pinned Dependencies

All 18 entries in `Package.resolved` use `kind: "remoteSourceControl"` against public GitHub repos:

| Identity | Repo | Version |
|---|---|---|
| `app-check` | google/app-check | 11.3.2 |
| `appauth-ios` | openid/AppAuth-iOS | 3.0.0 |
| `googlesignin-ios` | google/GoogleSignIn-iOS | 10.0.0 |
| `googleutilities` | google/GoogleUtilities | 8.1.5 |
| `gtm-session-fetcher` | google/gtm-session-fetcher | 5.3.1 |
| `gtmappauth` | google/GTMAppAuth | 6.0.0 |
| `interop-ios-for-google-sdks` | google/interop-ios-for-google-sdks | 101.0.0 |
| `lottie-ios` | airbnb/lottie-ios | 4.6.1 |
| `promises` | google/promises | 2.4.1 |
| `rive-ios` | rive-app/rive-ios | 6.29.0 |
| `supabase-swift` | supabase/supabase-swift | 2.55.4 |
| `swift-asn1` | apple/swift-asn1 | 1.7.3 |
| `swift-clocks` | pointfreeco/swift-clocks | 1.1.1 |
| `swift-concurrency-extras` | pointfreeco/swift-concurrency-extras | 1.4.3 |
| `swift-crypto` | apple/swift-crypto | 4.5.2 |
| `swift-http-types` | apple/swift-http-types | 1.8.0 |
| `swift-issue-reporting` | pointfreeco/swift-issue-reporting | 2.1.2 |
| `xctest-dynamic-overlay` | pointfreeco/xctest-dynamic-overlay | 1.13.1 |

There is no `Package.swift`, no `Podfile`, no `Cartfile`, no `Gemfile`, and no vendored `Pods/` or `Packages/` directory — all sources are fetched remotely by Xcode/SPM at build time.

## Conventions and Constraints

- **Version pinning**: Every dependency is pinned to both a semantic version tag and a concrete git revision SHA in `Package.resolved`. This ensures reproducible builds regardless of upstream tag movement.
- **No private registries or mirrors**: All packages resolve from public GitHub URLs; there is no `.swiftpm/config` registry configuration, no `GOPRIVATE` equivalent, and no custom index configured.
- **Lockfile committed**: `Package.resolved` is tracked in the repository, so collaborators get deterministic dependency resolution without needing to agree on floating versions.
- **Agent skills locked separately**: The `.agents/skills/rive-animation/` skill is pinned via `skills-lock.json` (versioned schema with `computedHash`), independent of SPM.
- **CI gap**: The GitHub Actions workflow runs `swift build -v` and `swift test -v` at the repository root, which will fail because there is no `Package.swift` at the root (the Xcode project is under `Moko/`). The `context.md` notes this as a known issue.