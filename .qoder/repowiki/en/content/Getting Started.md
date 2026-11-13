# Getting Started

<cite>
**Referenced Files in This Document**
- [README.md](file://README.md)
- [Secrets.example.xcconfig](file://Secrets.example.xcconfig)
- [.gitignore](file://.gitignore)
- [SupabaseManager.swift](file://Moko/Moko/SupabaseManager.swift)
- [GoogleAuthService.swift](file://Moko/Moko/GoogleAuthService.swift)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Installation](#installation)
4. [Configure Dependencies](#configure-dependencies)
5. [Configure Supabase and Google Sign-In](#configure-supabase-and-google-sign-in)
6. [Build and Run](#build-and-run)
7. [Verification Checklist](#verification-checklist)
8. [Troubleshooting](#troubleshooting)
9. [Environment-Specific Notes](#environment-specific-notes)
10. [Security Guidelines](#security-guidelines)
11. [Next Steps](#next-steps)

## Introduction
This guide helps you set up the Moko iOS app locally, install required dependencies, configure Supabase credentials, and run the app in Xcode. It also includes troubleshooting steps for common setup issues and verification checks to confirm a successful build.

Moko is a SwiftUI-based iOS wellness app that uses Lottie animations and Supabase for authentication. The repository provides an example secrets template and a `.gitignore` rule to keep your credentials out of version control.

**Section sources**
- [README.md:1-20](file://README.md#L1-L20)
- [README.md:211-241](file://README.md#L211-L241)

## Prerequisites
Before starting, ensure your development environment meets these requirements:

- **Xcode 15 or later**: Required by the project and CI configuration.
- **iOS 17.0+ deployment target**: SwiftData and other features require iOS 17+.
- **Apple Developer account**: Needed for signing, device testing, and Apple services.
- **Git**: To clone the repository.
- **Internet connection**: To fetch package dependencies (Lottie, Supabase, Google Sign-In).

If you are new to Xcode, open the project first and let Xcode install any missing components when prompted.

**Section sources**
- [README.md:213-218](file://README.md#L213-L218)

## Installation
Follow these steps to clone the repository and open the project in Xcode:

1. Open Terminal and navigate to your preferred workspace directory.
2. Clone the repository:
   - `git clone https://github.com/Moko-Your-Social-Capy/Moko---iOS-Native-App-.git`
3. Enter the project directory:
   - `cd Moko---iOS-Native-App-`
4. Open the Xcode project:
   - `open Moko/Moko.xcodeproj`

Xcode will load the project and may prompt you to select a scheme and destination simulator.

**Section sources**
- [README.md:219-225](file://README.md#L219-L225)

## Configure Dependencies
The app depends on third-party packages. You must add them through Xcode’s Package Manager.

### Add Lottie
1. In Xcode, go to **File → Add Package Dependencies**.
2. Enter the Lottie package URL:
   - `https://github.com/airbnb/lottie-ios`
3. Choose the appropriate version and click **Add Package**.

### Verify Package Resolution
After adding Lottie, resolve packages:
- Go to **Product → Resolve Package Dependencies**.
- Ensure there are no errors in the Package Resolution log.

If packages fail to resolve, check your internet connection and try again. If Xcode reports a version mismatch, update Xcode to 15 or later.

**Section sources**
- [README.md:227-228](file://README.md#L227-L228)

## Configure Supabase and Google Sign-In
The app integrates with Supabase for authentication and supports Google Sign-In. You must provide your own credentials.

### Create Secrets.xcconfig
1. Copy the provided template into a local secrets file:
   - `cp Secrets.example.xcconfig Secrets.xcconfig`
2. Open `Secrets.xcconfig` in a text editor.
3. Replace placeholder values with your actual credentials:
   - `SUPABASE_URL`: Your Supabase project URL.
   - `SUPABASE_PUBLISHABLE_KEY`: Your Supabase publishable key.
   - `GOOGLE_IOS_CLIENT_ID`: Your Google iOS client ID.
   - `GOOGLE_WEB_CLIENT_ID`: Your Google web client ID.

Important:
- `Secrets.xcconfig` is ignored by Git. Do not commit it.
- Never include a Supabase service role key in the app. Only use the public anon/publishable key on the client.

### Update Supabase Configuration in Code
The current implementation contains hardcoded Supabase values. Replace those with values from your environment or configuration system:

- File: `Moko/Moko/SupabaseManager.swift`
- Replace the hardcoded URL and key with values sourced from your configuration.

For Google Sign-In:
- File: `Moko/Moko/GoogleAuthService.swift`
- Replace the hardcoded Google client IDs with your configured values.

### Set Up Supabase Project
1. Create a Supabase project if you do not have one.
2. Enable email/password or other providers as needed.
3. Generate a publishable/anon key for client-side access.
4. Store the key securely and never share it publicly.

### Set Up Google Sign-In
1. Create a Google Cloud project.
2. Enable the Google Sign-In API.
3. Configure OAuth consent screen and create OAuth client IDs for iOS and Web.
4. Add your app bundle identifier to allowed identifiers.
5. Use the generated client IDs in `Secrets.xcconfig` and `GoogleAuthService.swift`.

**Section sources**
- [README.md:228-239](file://README.md#L228-L239)
- [Secrets.example.xcconfig:1-4](file://Secrets.example.xcconfig#L1-L4)
- [SupabaseManager.swift:11-18](file://Moko/Moko/SupabaseManager.swift#L11-L18)
- [GoogleAuthService.swift:30-33](file://Moko/Moko/GoogleAuthService.swift#L30-L33)

## Build and Run
After dependencies and secrets are configured:

1. Select the **Moko** scheme in Xcode.
2. Choose an iPhone simulator or a physical device.
3. Press **⌘R** to build and run.

If this is your first time running on a device, sign in with your Apple Developer account and authorize code signing.

**Section sources**
- [README.md:240-241](file://README.md#L240-L241)

## Verification Checklist
Use this checklist to confirm your setup is correct:

- [ ] Xcode version is 15 or later.
- [ ] Deployment target is iOS 17.0 or later.
- [ ] Lottie package is added and resolved without errors.
- [ ] `Secrets.xcconfig` exists and contains valid values.
- [ ] `Secrets.xcconfig` is not committed to Git.
- [ ] Supabase URL and publishable key are updated in the app code.
- [ ] Google client IDs are updated in the app code.
- [ ] The app builds successfully.
- [ ] The app launches in the selected simulator or device.
- [ ] Authentication flows can be tested with your configured providers.

**Section sources**
- [README.md:213-241](file://README.md#L213-L241)
- [.gitignore:1](file://.gitignore#L1)

## Troubleshooting

### Missing Dependencies
**Symptoms:**
- Build fails with “Package not found” or unresolved imports.
- Lottie symbols are missing.

**Resolution:**
- Add Lottie via **File → Add Package Dependencies**.
- Resolve packages using **Product → Resolve Package Dependencies**.
- Confirm Xcode is 15 or later.

**Section sources**
- [README.md:227-228](file://README.md#L227-L228)

### Signing Problems
**Symptoms:**
- “No signing certificate found.”
- “Team is not authorized.”
- App launches but crashes due to provisioning issues.

**Resolution:**
- Sign in with your Apple Developer account in Xcode.
- Select a valid team under the project’s Signing & Capabilities settings.
- For simulator builds, disable automatic signing if needed during development.
- For device builds, ensure your device is trusted and registered with your Apple Developer account.

**Section sources**
- [README.md:217-218](file://README.md#L217-L218)

### Simulator Configuration Issues
**Symptoms:**
- No simulators available.
- Build succeeds but cannot launch on the selected simulator.

**Resolution:**
- Install the required iOS SDK in Xcode Preferences → Platforms.
- Create an iPhone simulator matching iOS 17+.
- Clear Derived Data if the project state is corrupted.

**Section sources**
- [README.md:215-216](file://README.md#L215-L216)

### Supabase Errors
**Symptoms:**
- Network requests fail.
- Authentication returns invalid credentials.

**Resolution:**
- Verify `SUPABASE_URL` points to your active Supabase project.
- Verify `SUPABASE_PUBLISHABLE_KEY` is correct and has proper RLS policies.
- Replace hardcoded values in `SupabaseManager.swift` with your configuration.
- Test Supabase connectivity outside the app using Postman or curl.

**Section sources**
- [SupabaseManager.swift:11-18](file://Moko/Moko/SupabaseManager.swift#L11-L18)

### Google Sign-In Errors
**Symptoms:**
- Google Sign-In shows invalid client ID.
- Redirect fails or returns no ID token.

**Resolution:**
- Confirm both iOS and Web client IDs are correct.
- Ensure your app bundle identifier is registered in Google Cloud.
- Replace hardcoded client IDs in `GoogleAuthService.swift` with your configured values.
- Test OAuth flow in a browser with your client IDs.

**Section sources**
- [GoogleAuthService.swift:30-33](file://Moko/Moko/GoogleAuthService.swift#L30-L33)

### Secrets Not Loaded
**Symptoms:**
- App compiles but runtime configuration is missing.
- Supabase initialization fails at runtime.

**Resolution:**
- Ensure `Secrets.xcconfig` exists in the project root.
- Confirm the file is included in the build configuration.
- Validate that placeholders were replaced with real values.
- Check that `Secrets.xcconfig` is not accidentally committed.

**Section sources**
- [Secrets.example.xcconfig:1-4](file://Secrets.example.xcconfig#L1-L4)
- [.gitignore:1](file://.gitignore#L1)

## Environment-Specific Notes
- **Development vs Production**: Keep separate credentials for development and production environments. Avoid committing environment-specific files.
- **Local Development**: Use test Supabase projects and sandbox Google accounts.
- **CI Builds**: The repository’s CI skips code signing during tests. Local development should enable signing for device testing.
- **SwiftData Requirement**: iOS 17+ is required because SwiftData is used in the app.

**Section sources**
- [README.md:215-218](file://README.md#L215-L218)
- [README.md:287-293](file://README.md#L287-L293)

## Security Guidelines
- Never commit `Secrets.xcconfig`.
- Never include Supabase service role keys in the app.
- Use only public anon/publishable keys on the client.
- Rotate credentials regularly.
- Restrict Supabase RLS policies to allow only necessary operations.
- Keep Google client IDs scoped to your app bundle identifier.

**Section sources**
- [README.md:239-239](file://README.md#L239-L239)
- [.gitignore:1](file://.gitignore#L1)

## Next Steps
After verifying the build and run:

- Explore the UI screens and animation features.
- Test authentication flows with your configured providers.
- Review the architecture and feature structure in the repository documentation.
- Begin contributing by following the contribution guidelines.

**Section sources**
- [README.md:313-320](file://README.md#L313-L320)