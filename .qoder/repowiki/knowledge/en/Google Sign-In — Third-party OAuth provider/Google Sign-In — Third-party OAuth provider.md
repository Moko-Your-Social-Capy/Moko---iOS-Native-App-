---
kind: external_dependency
name: Google Sign-In — Third-party OAuth provider
slug: google-sign-in
category: external_dependency
category_hints:
    - vendor_identity
    - auth_protocol
scope:
    - '**'
source_files:
    - Moko/Moko/GoogleAuthService.swift
---

### Google Sign-In (GoogleSignIn)
- Role: third-party sign-in provider wired through `GoogleAuthService.swift`, intended to integrate with Supabase auth.
- Status: listed as planned in the README feature table; the conversation notes that Sign in with Apple is only a stub and no `AuthenticationServices` usage exists anywhere in the codebase.
- Secrets: the Google client configuration is expected to come from `Secrets.xcconfig` but is currently hardcoded in `GoogleAuthService.swift`.