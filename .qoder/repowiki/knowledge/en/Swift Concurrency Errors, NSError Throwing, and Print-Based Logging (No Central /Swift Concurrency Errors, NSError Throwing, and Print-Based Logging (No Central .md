---
kind: error_handling
name: Swift Concurrency Errors, NSError Throwing, and Print-Based Logging (No Central Error Type System)
category: error_handling
scope:
    - '**'
source_files:
    - Moko/Moko/AuthService.swift
    - Moko/Moko/GoogleAuthService.swift
    - Moko/Moko/Features/QuestLibrary/QuestLibraryService.swift
    - Moko/Moko/Features/Audio/DebriefSoundPlayer.swift
    - Moko/Moko/Models/CalmDownModel.swift
    - Moko/Moko/ContentView.swift
    - Moko/Moko/Models/QuestProgress.swift
---

# Error Handling in Moko

## What system/approach is used

The codebase uses **native Swift error handling** with no custom error type hierarchy, no centralized error domain, and no logging framework:

- `async throws` / `try await` for network/auth operations.
- `do { ... } catch { ... }` blocks around I/O that cannot be propagated to callers (e.g. AVFoundation audio, SwiftData saves).
- `NSError(domain:code:userInfo:)` thrown from UI-facing auth helpers.
- `print(...)` as the sole diagnostic output — there is no structured logger, no log levels, no crash reporter.
- No `fatalError` usage except one in `Models/QuestProgress.swift` during database creation; no `assert`, no `precondition`, no `panic/recover` (not applicable on iOS), no middleware layer.

## Key files and packages

| File | Role |
|---|---|
| `Moko/Moko/AuthService.swift` | Throws `URLError(.badServerResponse)` when the Supabase Edge Function returns a non-2xx status; otherwise propagates Supabase `AuthError`s via `async throws`. |
| `Moko/Moko/GoogleAuthService.swift` | Throws `NSError(domain: "GoogleAuth", code: 1 or 2, userInfo: [NSLocalizedDescriptionKey])` for missing window presenter and missing ID token. |
| `Moko/Moko/SupabaseManager.swift` | Singleton holding the `SupabaseClient`; does not wrap errors. |
| `Moko/Moko/Features/QuestLibrary/QuestLibraryService.swift` | Service method `fetchQuests()` returns `async throws`; `QuestLibraryStore.load()` catches `CancellationError` silently and maps all other errors to a user-facing `errorMessage` string (`"Couldn't load quests. Check your connection and try again."`). |
| `Moko/Moko/Features/Audio/DebriefSoundPlayer.swift` | Catches `AVAudioPlayer` init errors and prints them; swallows the failure so playback never crashes the app. |
| `Moko/Moko/Models/CalmDownModel.swift` | `ModelContext.logCalmDown(_:)` wraps `save()` in `do/catch` and prints failures. |
| `Moko/Moko/ContentView.swift` | Uses `try?` to swallow errors from `modelContext.save()` and `auth.getCurrentUser()`. |
| `Moko/Moko/Models/QuestProgress.swift` | Contains a single `fatalError("Could not create the database: …")` path. |
| `Moko/Moko/UIScreens/relaxScreens/ImageryGuide/GuideSessionView.swift` | Prints AVAudioSession configuration and AVPlayer load failures; no user-facing error state. |

## Architecture and conventions

1. **Layered throwing**: Thin service methods (`AuthService`, `QuestLibraryService.fetchQuests`) are declared `async throws` and let underlying SDK errors bubble up. View-model/store layers (`QuestLibraryStore`) then decide whether to surface the error to the user or suppress it.

2. **Store-level error state**: The only place an error is surfaced to the UI is `QuestLibraryStore.errorMessage: String?`, set inside the `catch` block of `load()`. Other components do not expose typed error state to views.

3. **Silent suppression of cancellations**: `QuestLibraryStore.load()` explicitly matches `catch is CancellationError { return }` so task cancellation during a refresh does not produce an error message.

4. **Swallow-and-print fallbacks**: For fire-and-forget I/O (audio playback, SwiftData persistence) the pattern is `do { ... } catch { print(...) }` — the operation fails silently from the caller's perspective while leaving a console trace.

5. **`try?` at call sites**: `ContentView` uses `try?` for both `auth.getCurrentUser()` and `modelContext.save()`, converting any thrown error into `nil` and continuing execution. This means auth lookup failures and SwiftData save failures are effectively ignored by the flow controller.

6. **Domain-scoped `NSError`**: `GoogleAuthService` defines its own error domain (`"GoogleAuth"`) with integer codes 1 (no presenter) and 2 (no ID token). These are the only places in the repo where `NSError` is constructed directly rather than relying on a library's `Error` type.

7. **No central error abstraction**: There is no `enum AppError`, no `struct ValidationError`, no shared error formatter, and no protocol like `AppErrorType`. Each module invents its own error representation (or none at all).

8. **No panic/recover or middleware**: The app is SwiftUI-based with no server-side request pipeline; there is no global error interceptor, no `@MainActor` error handler, and no `defer`-based cleanup around failing operations beyond the store's `isLoading` flag reset.

## Conventions and constraints

- **Observed convention**: Network/auth calls are exposed as `async throws` and left unhandled at the service boundary; higher layers decide whether to convert the error into UI state or ignore it.
- **Observed convention**: Non-propagatable I/O (AVFoundation, SwiftData) is wrapped in `do/catch` with `print` diagnostics and no user notification.
- **Observed convention**: User-visible error messages are plain `String` values stored in store properties (e.g. `errorMessage`), not localized resources or typed error payloads.
- **Constraint enforced by code**: `GoogleAuthService.signIn()` will throw `NSError(domain: "GoogleAuth", code: 1)` if no foreground `UIWindowScene`/`UIWindow`/root `UIViewController` can be found before presenting Google Sign-In; this is a hard precondition check, not a recoverable path.
- **Constraint enforced by code**: `AuthService.deleteAccount()` throws `URLError(.badServerResponse)` whenever the HTTP response status is outside `200..<300`; successful responses are accepted without inspecting the body.
- **Constraint enforced by code**: `QuestLibraryStore.load()` treats `CancellationError` as non-fatal and returns immediately, while all other errors set `errorMessage` after ensuring the loader remains visible for a minimum duration via `keepLoaderVisible(since:)`.
- **Constraint enforced by code**: `fatalError` is used exactly once in `Models/QuestProgress.swift` for database creation failure, making it unrecoverable at runtime.