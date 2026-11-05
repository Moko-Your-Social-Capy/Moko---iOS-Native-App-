# App Store Connect privacy checklist

Complete these items before submitting Moko.

## Privacy policy

- [ ] Publish the current Privacy Policy at a stable public HTTPS URL.
- [ ] Add that URL to App Store Connect and to the app’s App Information.
- [ ] Keep the policy aligned with the exact production build and its enabled services.

## Privacy nutrition labels

Confirm each item against the final release build and the Supabase project configuration.

- Contact information: email address used for account sign-in.
- User content: profile details, quest notes, self-rated scores, and reflection text are stored locally in this build.
- Sensitive information: voice recordings are not implemented and are not collected in this build.
- Usage data: do not declare unless analytics or event logging is enabled in the release build.
- Purpose: app functionality and account authentication.
- Linked to the user: email/account details are linked to the account. Local app content is associated with the local profile on this device.
- Tracking: no tracking or advertising use is implemented in the inspected app code.

Review all third-party SDK behavior in App Store Connect before submission; these notes do not replace the SDK privacy manifests or the final privacy-label review.

## Account deletion reviewer notes

- Sign in using an account with email and password.
- Open Profile, Settings, Account Info, Delete Account.
- Review the warning, reauthenticate, then tap Delete permanently.
- The app calls the authenticated delete-account Supabase Edge Function. The function must be deployed with SUPABASE_SERVICE_ROLE_KEY configured as a server-side secret.
- Successful deletion clears local SwiftData and signs the user out. Network/server failure leaves local app data intact and displays an error.

## Before release

- [ ] Deploy and verify the delete-account Edge Function in the production Supabase project.
- [ ] Verify the App Store account-deletion flow with a real test account.
- [ ] Verify every collection, retention, and sharing statement against production services.
- [ ] Add a valid support email and public privacy policy URL.
- [ ] Complete App Privacy answers in App Store Connect.
