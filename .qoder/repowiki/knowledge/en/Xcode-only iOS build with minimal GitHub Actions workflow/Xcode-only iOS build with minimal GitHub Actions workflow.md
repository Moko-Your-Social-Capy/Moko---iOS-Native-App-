---
kind: build_system
name: Xcode-only iOS build with minimal GitHub Actions workflow
category: build_system
scope:
    - '**'
source_files:
    - .github/workflows/swift.yml
    - Moko/Moko.xcodeproj/project.pbxproj
    - Secrets.example.xcconfig
    - context.md
---

## Build System Overview

Moko is a native SwiftUI iOS app built exclusively through Xcode — there are no Makefiles, `Package.swift`, Dockerfiles, shell build scripts, or custom toolchains at the repository root. The only automated build entry point is a single GitHub Actions workflow.

## Key Files

- `.github/workflows/swift.yml` — the sole CI pipeline; runs on `macos-latest`, checks out the repo, then executes `swift build -v` and `swift test -v`.
- `Moko/Moko.xcodeproj/project.pbxproj` — the Xcode project definition (target, schemes, dependencies).
- `Secrets.example.xcconfig` — template for secrets consumed by the Xcode build via an `.xcconfig` file.
- `context.md` — notes that the README's documented `swift test` command does not work because there is no `Package.swift` at the repo root, and that the CI workflow is broken for this reason.

## Architecture and Conventions

1. **Xcode as the single source of truth.** All compilation, linking, code signing, and asset processing go through `Moko.xcodeproj`. There is no Swift Package Manager manifest at the repo root; the only SPM usage appears under `Moko/Moko.xcodeproj/xcshareddata/swiftpm/Package.resolved`, indicating SPM packages are managed as Xcode dependencies rather than as a top-level package.
2. **CI mirrors the README but is inconsistent with reality.** The workflow triggers on push/PR to `main`, uses `actions/checkout@v4`, and runs `swift build` / `swift test`. Because the project has no `Package.swift`, these commands fail — the workflow effectively only validates that `swift` is installed on the runner, not that the app builds.
3. **No containerization or cross-compilation.** There are no `Dockerfile`s, no Linux/macOS dual targets, and no `xcrun xcodebuild` invocations in CI. Builds are expected to run on macOS with Xcode tooling.
4. **Secrets via `.xcconfig`.** `Secrets.example.xcconfig` documents how runtime secrets (e.g., Supabase keys) are injected into the Xcode build; developers are expected to copy it to a local `.xcconfig` file excluded from version control.
5. **Rive animation projects are separate mini-repos.** Each Rive scene lives under `RiveProjects/<Name>/` with its own `rive.yaml` and `scene.rml`; compiled `.riv` assets land under `Moko/Moko/Resources/Animations/`. These are authored outside the Xcode build and committed as precompiled artifacts.
6. **Supabase migrations are deployed separately.** SQL files under `supabase/migrations/` and seed data under `supabase/seed.sql` and `supabase/imagery_guides_seed.sql` are managed via the Supabase CLI (see `supabase/.temp/cli-latest`), not via the Xcode build.

## Conventions and Constraints

- The project is built with Xcode; there is no equivalent command-line build script at the repo root. Any automation must target `Moko.xcodeproj` directly (e.g., `xcodebuild` or `xcodebuild test`).
- The existing GitHub Actions workflow (`swift build` / `swift test`) does not actually compile the iOS app because there is no `Package.swift` — this is acknowledged as broken in `context.md`.
- Secrets are not baked into the repo; they are supplied via a local `.xcconfig` file derived from `Secrets.example.xcconfig`.
- No release/packaging step (IPA/App Store Connect upload) is present in the repository — only a build-and-test surface exists in CI.