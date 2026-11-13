---
kind: external_dependency
name: Supabase — Auth + Edge Functions + Storage for Moko
slug: supabase
category: external_dependency
category_hints:
    - vendor_identity
    - sdk_real_api
    - auth_protocol
scope:
    - '**'
---

### Supabase
- Role: authentication backend, edge functions (delete-account), and storage/buckets backing the Quest Library imagery.
- Integration points:
  - `Moko/Moko/SupabaseManager.swift` holds the client URL and anon key; secrets are currently hardcoded there instead of being read from `Secrets.xcconfig`.
  - `Moko/Moko/AuthService.swift` / `GoogleAuthService.swift` drive sign-in flows against Supabase auth.
  - Server-side logic lives under `Moko/Moko/supabase/functions/delete-account/index.ts`; migrations live at repo root under `supabase/migrations/`.
- Auth protocol: Supabase uses an anonymous public key on the client (`SUPABASE_ANON_KEY`) — never a `service_role` key. The README explicitly forbids committing the service role key to the app.
- Verify exact method/params against the official Supabase Swift SDK docs when wiring new endpoints.