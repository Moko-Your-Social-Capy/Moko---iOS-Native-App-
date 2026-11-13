---
kind: build_system
name: Xcode + SwiftPM Build System with GitHub Actions CI
category: build_system
scope:
    - '**'
source_files:
    - .github/workflows/swift.yml
    - Moko/Moko.xcodeproj/project.pbxproj
    - Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - Secrets.example.xcconfig
    - Moko/.agents/skills/rive-animation/tools/frame_diff.py
    - Moko/.agents/skills/rive-animation/tools/thin_keys.py
    - supabase/migrations/20261101120000_create_quest_library.sql
---

## Build Approach

Moko is a native iOS app built exclusively through **Xcode** (`Moko/Moko.xcodeproj`) and the **Swift Package Manager (SPM)** for dependency resolution. There are no Makefiles, Dockerfiles, shell build scripts, or custom toolchains in the repository.

### Primary build entry points
- **Local development**: `xcodebuild` / Xcode IDE against `Moko/Moko.xcodeproj`. The project declares one target named `Moko` producing `com.apple.product-type.application` (`Moko.app`).
- **CI**: GitHub Actions workflow `.github/workflows/swift.yml`, which runs on `macos-latest`, checks out the repo, then executes `swift build -v` followed by `swift test -v`. This exercises the SPM package graph but does not invoke Xcode to build the `.app`.

### Dependency management
Dependencies are declared as remote Swift packages pinned in `Moko/Moko.xcodeproj/project.pbxproj` under `packageReferences`:
- `supabase-swift` v2.55.4
- `GoogleSignIn-iOS` v10.0.0
- `lottie-ios` v4.6.1
- `rive-ios` v6.29.0

The resolved lockfile is committed at `Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, pinning every transitive dependency (e.g., `app-check` 11.3.2, `appauth-ios` 3.0.0, `swift-crypto` 4.5.2, `pointfreeco/*` utilities) to exact revisions and versions. No `Package.swift` exists at the repo root — only the Xcode workspace's SPM resolver state is tracked.

### Rive animation build pipeline
Rive animations live under `RiveProjects/` and `Moko/Resources/Animations/`. Each Rive project contains a `scene.rml` source plus a `rive.yaml` manifest and a generated `build/` directory. The `.agents/skills/rive-animation/` skill documents the tooling (`frame_diff.py`, `thin_keys.py`) used to build and review `.rml` → `.riv` assets. These compiled `.riv` files are bundled as resources into the `Moko` target.

### Supabase migrations
Database schema changes are versioned SQL migrations under `supabase/migrations/` (timestamp-prefixed filenames like `20261101120000_create_quest_library.sql`). The `supabase/.temp/cli-latest` file indicates use of the Supabase CLI for local dev; there is no automated migration step in CI.

### Secrets
`Secrets.example.xcconfig` provides the template for per-developer secrets; it is gitignored and consumed by the Xcode build via an `.xcconfig` include. No CI secret injection is present in the workflow.

## Key Files
- `.github/workflows/swift.yml` — CI definition (checkout → `swift build` → `swift test`)
- `Moko/Moko.xcodeproj/project.pbxproj` — Xcode project: single `Moko` target, framework dependencies, SPM package references, build settings (Clang warnings enabled, ARC on, gnu++20 C++ standard)
- `Moko/Moko.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — committed SPM lockfile pinning all transitive deps
- `Moko/SupabaseManager.swift`, `Moko/AuthService.swift`, `Moko/GoogleAuthService.swift` — runtime integration points for backend services
- `RiveProjects/*/scene.rml`, `RiveProjects/*/rive.yaml` — Rive animation sources
- `Moko/.agents/skills/rive-animation/tools/frame_diff.py`, `thin_keys.py` — Rive asset optimization/review tools
- `supabase/migrations/*.sql` — versioned database schema
- `Secrets.example.xcconfig` — secrets template

## Architecture & Conventions
- Single-target Xcode app (`Moko.app`) with filesystem-synchronized groups (`PBXFileSystemSynchronizedRootGroup` over `Moko/`), so adding Swift files automatically includes them without editing the `.pbxproj`.
- All third-party libraries come from SPM remote repos; vendored frameworks are absent.
- Rive animation projects are kept separate from app code under `RiveProjects/` and compiled into `.riv` bundles consumed at runtime.
- Database schema evolves via timestamped SQL migration files rather than an ORM or migration tooling integrated into the build.
- CI is intentionally minimal: it validates that the Swift package graph compiles and tests pass, but does not produce an IPA or run UI tests.

## Conventions & Constraints
- **CI trigger**: The GitHub Actions workflow runs only on pushes and pull requests targeting the `main` branch (`.github/workflows/swift.yml` lines 7–10).
- **CI environment**: Jobs run on `macos-latest` using `actions/checkout@v4`; the build commands are `swift build -v` and `swift test -v` (no `xcodebuild`).
- **Dependency pinning**: All SPM dependencies are locked in `Package.resolved` and committed to the repo, ensuring reproducible builds across developers and CI.
- **Build configuration**: The Xcode project enables aggressive Clang static analysis flags (`CLANG_WARN_*` set to `YES` or `YES_AGGRESSIVE`), ARC, modules, and uses the `gnu++20` C++ standard (in `project.pbxproj` XCBuildConfiguration).
- **Rive asset flow**: Animation sources (`scene.rml` + `rive.yaml`) live under `RiveProjects/`; compiled `.riv` assets are checked in under `Moko/Resources/Animations/` and referenced by the app. The `.agents/skills/rive-animation/` skill documents the review/build process for these assets.