---
kind: error_handling
name: Swift Error Handling in Moko iOS App
category: error_handling
scope:
    - '**'
source_files:
    - Moko/Moko/Features/AFM/MokoAFM.swift
    - Moko/Moko/AuthService.swift
    - Moko/Moko/GoogleAuthService.swift
    - Moko/Moko/SupabaseManager.swift
    - Moko/Moko/Features/QuestLibrary/QuestLibraryService.swift
    - Moko/Moko/ContentView.swift
    - Moko/Moko/Models/CalmDownModel.swift
    - Moko/Moko/Models/QuestProgress.swift
    - Moko/Moko/Features/Audio/DebriefSoundPlayer.swift
    - Moko/Moko/Models/QuestModels.swift
---

## Approach

The Moko iOS app uses idiomatic Swift error handling with `async throws` / `try await` across its service layer, plus a single domain-specific error type for the Apple Foundation Models (AFM) subsystem. There is no centralized error framework, no custom base error class, and no global panic/recover strategy — errors are propagated up to SwiftUI views or stored as user-facing strings.

## Key Files and Packages

- `Moko/Moko/Features/AFM/MokoAFM.swift` — defines `AFMError: Error, LocalizedError` (`unavailable(reason:)`, `generationFailed(String)`), the only typed error enum in the codebase; also contains the `AFM.generate<T>` retry loop that rethrows the last failure after exhausting retries.
- `Moko/Moko/AuthService.swift` — thin wrapper around Supabase auth; propagates `Supabase` errors via `async throws`; maps HTTP non-2xx responses from the delete-account edge function to `URLError(.badServerResponse)`.
- `Moko/Moko/GoogleAuthService.swift` — throws `NSError(domain: "GoogleAuth", code: 1|2, ...)` when no key window/view controller is available or when Google returns no ID token.
- `Moko/Moko/SupabaseManager.swift` — singleton holding the `SupabaseClient`; does not itself throw but exposes the client whose methods propagate errors upward.
- `Moko/Moko/Features/QuestLibrary/QuestLibraryService.swift` + `QuestLibraryStore` — `fetchQuests()` is `async throws`; `QuestLibraryStore.load()` catches `CancellationError` (swallows it) and all other errors, logs them via `print`, and stores a localized message in an `errorMessage: String?` property consumed by the view.
- `Moko/Moko/ContentView.swift` — top-level screen router; uses `try?` to swallow SwiftData save failures and `try? await auth.getCurrentUser()` to tolerate auth lookup failures during Google sign-in flow.
- `Moko/Moko/Models/CalmDownModel.swift`, `Moko/Moko/Models/QuestProgress.swift` — catch-and-print pattern for SwiftData persistence errors.
- `Moko/Moko/Features/Audio/DebriefSoundPlayer.swift` — `do/catch` around AVAudioSession configuration with `print` logging on failure.
- `Moko/Moko/Models/QuestModels.swift` — one use of `fatalError("Could not create the database: …")` at database initialization time.

## Architecture and Conventions

1. **Service-layer functions declare `async throws`** and let underlying SDK errors (`Supabase`, `FoundationModels`, `GoogleSignIn`) bubble up. The only place a domain-specific error is introduced is `AFMError` in `MokoAFM.swift`, which wraps both device-unavailability and generation failures and conforms to `LocalizedError` so callers can display `errorDescription` directly.

2. **Callers decide how to surface errors:**
   - `AuthService.deleteAccount()` converts an HTTP status outside `(200..<300)` into `URLError(.badServerResponse)` before throwing.
   - `GoogleAuthService.signIn()` constructs explicit `NSError` values with a `"GoogleAuth"` domain and numeric codes (1 = no presenter, 2 = no ID token).
   - `QuestLibraryStore.load()` catches `CancellationError` explicitly (returns silently) and otherwise sets `errorMessage` to a fixed user-facing string: `"Couldn't load quests. Check your connection and try again."` — the raw error is only logged via `print`.
   - Other call sites (e.g. `ContentView`) use `try?` to ignore errors entirely, treating them as "continue without data" rather than surfacing them.

3. **No global error middleware or handler.** There is no `AppDelegate`/`SceneDelegate` error interceptor, no `@MainActor` error handler, and no centralized logger. Errors are either swallowed, printed, or converted into UI state.

4. **Logging convention:** All error reporting goes through `print(...)` with a bracketed tag per subsystem (e.g. `[QuestLibrary]`, `[DebriefSoundPlayer]`, `[ImageryGuide]`, `[ImageryAudio]`). No structured logging framework is used.

5. **`fatalError` usage is limited to one location** (`QuestModels.swift` line 163) during database creation, indicating a truly unrecoverable setup failure.

6. **SwiftData persistence errors are consistently ignored** via `try? modelContext.save()` in `ContentView.finishOnboardingInfo`, `ContentView.mapAndSaveQuestionsToSwiftData`, `DailyMissionService`, and similar places — failures are silent from the user's perspective.

## Conventions and Constraints

- **Descriptive convention observed:** Service methods in this repo use `async throws` and do not wrap third-party errors in custom types, except for the AFM subsystem where `AFMError` is defined once and thrown from `AFM.generate` and `AFM.isAvailable` checks.
- **Descriptive convention observed:** User-facing error messages are kept as plain `String` properties on `@Observable` store classes (e.g. `QuestLibraryStore.errorMessage`) rather than passed up as typed errors to views.
- **Descriptive convention observed:** Cancellation is treated as non-error: `catch is CancellationError { return }` appears in `QuestLibraryStore.load()` and is the only explicit cancellation handling in the codebase.
- **Constraint enforced by the code:** `AuthService.deleteAccount()` requires the response status to be in `(200..<300)`; any other status causes `throw URLError(.badServerResponse)`. This is a hard check in the implementation.
- **Constraint enforced by the code:** `GoogleAuthService.signIn()` requires a foreground `UIWindowScene` with a root view controller; absence of one throws `NSError(domain: "GoogleAuth", code: 1)`.
- **Constraint enforced by the code:** `AFM.generate` throws `AFMError.unavailable(reason:)` whenever `SystemLanguageModel.default.isAvailable` is false, and rethrows the last caught error after exhausting the configured number of retries.
- **Constraint enforced by the code:** Database creation in `QuestModels.swift` calls `fatalError(...)`, making that path a hard crash if the SwiftData container cannot be created.