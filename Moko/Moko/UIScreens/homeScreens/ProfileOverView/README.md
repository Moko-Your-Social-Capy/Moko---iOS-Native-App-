# Profile Screens - SwiftUI Implementation

This folder contains SwiftUI implementations of all profile-related screens based on the design prototype.

## Screen List

| File | Description | Prototype Reference |
|------|-------------|---------------------|
| `ProfileOverView.swift` | Profile Overview with statistics and quick actions | `Profile - Overview - Light.png` |
| `ProfileOverViewEditProfile.swift` | Edit Profile Sheet modal | `Edit Profile - Sheet - Light.png` |
| `ProfileOverViewAchievementsList.swift` | Achievements list view | `Achievements - List - Light.png` |
| `ProfileOverViewAchievementDetailUnlocked.swift` | Single achievement detail (unlocked state) | `Achievement - Detail unlocked - Light.png` |
| `ProfileOverViewSettingsOverview.swift` | Settings overview with navigation grouping | `Settings - Overview - Light.png` |
| `ProfileOverViewNotifications.swift` | Notifications settings page | `Notifications - Light.png` |
| `ProfileOverViewAccountAndData.swift` | Account & Data management screen | `Account & Data - Light.png` |
| `ProfileOverViewDeleteAccountConfirm.swift` | Delete account confirmation dialog | `Delete account - Confirm - Light.png` |
| `ProfileOverViewDeleteAccountFinalConfirm.swift` | Final confirmation with expanded warnings | `Delete account - Final confirmation - Light.png` |
| `ProfileOverViewSignOutConfirmation.swift` | Sign out confirmation screen | `Sign out - Confirmation - Light.png` |

## Design System

All screens follow the same design system established in existing code:

- **Background**: `#F2F2F7` (soft gray-blue)
- **Primary Green**: `#1B422F` (brand green)
- **Title Dark**: `#2F2A28` (dark text for headings)
- **Subtext Gray**: `#6F6762` (lighter text)

## Usage

Navigate to these screens from the main profile view using navigation:

```swift
NavigationStack {
    ProfileOverViewAchievementsList()
}
```

Or use `.sheet()` for modal presentations:

```swift
ProfileOverViewEditProfile(profileName: user.name, profileImageURL: imageURL)
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
```

## Files Created

- `ProfileOverView.swift` - Profile overview with header, stats, and quick actions
- `ProfileOverViewEditProfile.swift` - Edit profile sheet with all options
- `ProfileOverViewAchievementsList.swift` - List of achievements by category
- `ProfileOverViewAchievementDetailUnlocked.swift` - Detailed view of an unlocked achievement
- `ProfileOverViewSettingsOverview.swift` - General settings navigation
- `ProfileOverViewNotifications.swift` - Notification preferences and toggles
- `ProfileOverViewAccountAndData.swift` - Account management and storage data
- `ProfileOverViewDeleteAccountConfirm.swift` - Confirm delete account action
- `ProfileOverViewDeleteAccountFinalConfirm.swift` - Final confirmation with expanded warnings
- `ProfileOverViewSignOutConfirmation.swift` - Sign out confirmation dialog
