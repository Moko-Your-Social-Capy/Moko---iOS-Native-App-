//
//  EditProfileSheet.swift
//  Moko
//
//  Profile → Edit. What can change here:
//    • profile photo        (editable: tap the photo or "Change photo")
//    • display name         (editable, loaded from the saved profile)
//    • username             (editable, loaded from the saved profile)
//  Shown but NOT editable: age and the sign-in method.
//
//  Changes stay in @State while editing and are written to SwiftData only on Save.
//

import SwiftUI
import PhotosUI
import SwiftData
import UIKit

// MARK: - Sign-in method

/// How the user signed in. Shown read-only on the edit screen.
///
/// `current()` is a placeholder that reads two UserDefaults keys. Replace its body
/// with your real auth source (AuthService / GoogleAuthService / Supabase session)
/// and keep the rest of the file as it is.
enum SignInMethod {
    case apple
    case google
    case email(String?)
    case unknown

    static func current() -> SignInMethod {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "moko.signInMethod") {
        case "apple":  return .apple
        case "google": return .google
        case "email":  return .email(defaults.string(forKey: "moko.signInEmail"))
        default:       return .unknown
        }
    }

    var title: String {
        switch self {
        case .apple:   return "Apple"
        case .google:  return "Google"
        case .email:   return "Email"
        case .unknown: return "Not available"
        }
    }

    var detail: String? {
        if case .email(let address) = self { return address }
        return nil
    }

    var symbol: String {
        switch self {
        case .apple:   return "apple.logo"
        case .google:  return "g.circle.fill"
        case .email:   return "envelope.fill"
        case .unknown: return "person.crop.circle"
        }
    }

    var isEmail: Bool {
        if case .email = self { return true }
        return false
    }
}

// MARK: - Screen

struct ProfileOverViewEditProfile: View {
    // Shown only for email accounts. Pass the action that opens your change-password flow.
    var onChangePassword: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    // The app only ever keeps one Profile.
    @Query private var profiles: [Profile]

    // Editable copies of the profile.
    @State private var name = ""
    @State private var handle = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    // Read-only.
    @State private var age = 0

    // Only show validation messages after the user has tried to save.
    @State private var showValidation = false
    @State private var saveError: String?
    @State private var isSaving = false

    private let signInMethod = SignInMethod.current()
    /// false: no banner, the photo sits centred with a "Change photo" button.
    /// true:  a light-green banner behind the title, with the photo straddling its edge.
    private let showsBanner = false
    private let bannerHeight: CGFloat = 150
    private let avatarSize: CGFloat = 96

    private typealias Theme = MokoScreenTheme

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedHandle: String { handle.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var nameError: String? {
        if trimmedName.isEmpty { return "Enter a display name." }
        if trimmedName.count > 30 { return "Use 30 characters or fewer." }
        return nil
    }

    private var handleError: String? {
        guard !trimmedHandle.isEmpty else { return nil }
        if trimmedHandle.count < 3 { return "Username must be at least 3 characters." }
        if trimmedHandle.count > 20 { return "Username must be 20 characters or fewer." }
        if !trimmedHandle.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }) {
            return "Use only letters, numbers, underscores and hyphens."
        }
        return nil
    }

    private var isValidForm: Bool { nameError == nil && handleError == nil }

    // MARK: Body

    var body: some View {
        ZStack {
            MokoBackdrop()

            VStack(spacing: 0) {
                if showsBanner {
                    bannerSection
                        .zIndex(1)           // keeps the avatar above the scrolling form
                } else {
                    headerBar
                }

                ScrollView {
                    VStack(spacing: Theme.Space.gapCard) {
                        if !showsBanner { photoBlock }
                        detailsCard
                        accountCard
                        if let saveError {
                            Text(saveError)
                                .mokoText(Theme.Typeface.caption)
                                .foregroundStyle(Theme.Colors.error)
                        }
                    }
                    .padding(.horizontal, Theme.Space.page)
                    .padding(.top, showsBanner ? avatarSize / 2 + Theme.Space.s7   // clears the avatar
                                               : Theme.Space.s2)
                    .padding(.bottom, Theme.Space.s6)
                }
                .scrollDismissesKeyboard(.interactively)
                .safeAreaInset(edge: .bottom, spacing: 0) { actionBar }
            }
        }
        .onAppear(perform: loadProfile)
        // Each runs again whenever its picker changes, i.e. after the user picks an image.
        .task(id: photoItem) { await loadPhoto() }
        .interactiveDismissDisabled(isSaving)
        .tint(Theme.Colors.dataVioletDeep)
    }

    // MARK: Banner + avatar

    private var bannerSection: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                bannerBackground
                    .ignoresSafeArea(edges: .top)

                headerBar
            }

            avatarButton
                .offset(y: avatarSize / 2 + 5)     // half of the ringed avatar hangs below the banner
        }
        .frame(height: bannerHeight)
    }

    private var bannerBackground: some View {
        ZStack {
            LinearGradient(colors: [Theme.Colors.lightSage, Theme.Colors.tileLilac],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0,
                                          bottomLeadingRadius: Theme.Radius.hero,
                                          bottomTrailingRadius: Theme.Radius.hero,
                                          topTrailingRadius: 0,
                                          style: .continuous))
        .shadow(color: Theme.Elevation.ambientColor, radius: 14, x: 0, y: 6)
    }

    private var headerBar: some View {
        HStack {
            Text("Edit profile")
                .mokoText(Theme.Typeface.title2)
                .foregroundStyle(Theme.Colors.textTitle)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textTitle)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Theme.Colors.surfaceWhite.opacity(0.85)))
                    .shadow(color: Theme.Elevation.ambientColor, radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, Theme.Space.s4)
        .padding(.bottom, showsBanner ? 0 : Theme.Space.s2)
        .frame(maxHeight: showsBanner ? .infinity : nil, alignment: .top)
    }

    /// No-banner layout: centred photo plus an explicit button to change it.
    private var photoBlock: some View {
        VStack(spacing: Theme.Space.s3) {
            avatarButton

            PhotosPicker(selection: $photoItem, matching: .images) {
                HStack(spacing: Theme.Space.s1) {
                    Image(systemName: "photo")
                        .font(.system(size: 13, weight: .semibold))
                    Text(photoData == nil ? "Add photo" : "Change photo")
                        .mokoText(Theme.Typeface.button)
                }
                .foregroundStyle(Theme.Colors.dataVioletDeep)
                .padding(.horizontal, Theme.Space.s5)
                .frame(minHeight: 44)
                .background(Capsule().fill(Theme.Colors.surfaceLavender))
                .shadow(color: Theme.Elevation.ambientColor.opacity(0.5), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, Theme.Space.s2)
    }

    /// Tapping the avatar opens the photo library.
    private var avatarButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                avatarImage
                    .frame(width: avatarSize, height: avatarSize)
                    .clipShape(Circle())
                    .padding(5)
                    .background(Circle().fill(Theme.Colors.surfaceWhite))
                    .shadow(color: Theme.Elevation.ambientColor, radius: 10, x: 0, y: 4)

                Image(systemName: "camera.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textOnBrand)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.Colors.dataVioletDeep))
                    .shadow(color: Theme.Elevation.ambientColor, radius: 6, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(photoData == nil ? "Choose profile photo" : "Change profile photo")
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else if UIImage(named: "profile_empty_moko") != nil {
            Image("profile_empty_moko")
                .resizable()
                .scaledToFit()
                .padding(10)
                .background(Theme.Colors.surfaceLavender)
        } else {
            Image(systemName: "person.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.Colors.dataVioletDeep)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.surfaceLavender)
        }
    }

    // MARK: Cards

    /// Editable: display name and username, plus a link to remove the photo.
    private var detailsCard: some View {
        card {
            fieldGroup(title: "Display name",
                       error: showValidation ? nameError : nil) {
                TextField("Required", text: $name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .onChange(of: name) { _, newValue in
                        if newValue.count > 30 { name = String(newValue.prefix(30)) }
                    }
            }

            fieldGroup(title: "Username",
                       error: showValidation ? handleError : nil) {
                HStack(spacing: Theme.Space.s1) {
                    Text("@")
                        .foregroundStyle(Theme.Colors.textMuted)
                    TextField("username", text: $handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: handle) { _, newValue in
                            if newValue.contains(" ") {
                                handle = newValue.replacingOccurrences(of: " ", with: "")
                            }
                        }
                }
            }

            if photoData != nil {
                removeLink("Remove photo") {
                    photoData = nil
                    photoItem = nil
                }
            }
        }
    }

    /// Read-only: age and sign-in method.
    private var accountCard: some View {
        card {
            readOnlyRow(title: "Age",
                        value: age > 0 ? "\(age)" : "Not set",
                        symbol: "lock.fill",
                        note: "Age can't be changed here.")

            signInRow
        }
    }

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s5) {
            content()
        }
        .padding(Theme.Space.cardHorizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Colors.surfaceWhite)
                .shadow(color: Theme.Elevation.ambientColor,
                        radius: Theme.Elevation.ambientRadius,
                        x: 0,
                        y: Theme.Elevation.ambientOffset)
        )
    }

    private func removeLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .mokoText(Theme.Typeface.caption)
                .foregroundStyle(Theme.Colors.error)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// A label above a rounded text field. No outline: the field is a soft tinted block.
    private func fieldGroup<Content: View>(
        title: String,
        error: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text(title)
                .mokoText(Theme.Typeface.fieldLabel)
                .foregroundStyle(Theme.Colors.textMuted)

            content()
                .mokoText(Theme.Typeface.body)
                .foregroundStyle(Theme.Colors.textTitle)
                .padding(.horizontal, Theme.Space.s4)
                .frame(minHeight: 52)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                        .fill(error == nil ? Theme.Colors.surfaceLavender
                                           : Theme.Colors.error.opacity(0.10))
                )

            if let error {
                Text(error)
                    .mokoText(Theme.Typeface.caption)
                    .foregroundStyle(Theme.Colors.error)
                    .padding(.horizontal, Theme.Space.s1)
            }
        }
    }

    // MARK: Read-only rows

    private func readOnlyRow(title: String, value: String, symbol: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text(title)
                .mokoText(Theme.Typeface.fieldLabel)
                .foregroundStyle(Theme.Colors.textMuted)

            HStack {
                Text(value)
                    .mokoText(Theme.Typeface.body)
                    .foregroundStyle(Theme.Colors.textBody)
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Colors.lockedInk)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, Theme.Space.s4)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                    .fill(Theme.Colors.lockedSurface)
            )

            Text(note)
                .mokoText(Theme.Typeface.caption)
                .foregroundStyle(Theme.Colors.textMuted)
                .padding(.horizontal, Theme.Space.s1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) \(value), not editable")
    }

    private var signInRow: some View {
        VStack(alignment: .leading, spacing: Theme.Space.s2) {
            Text("Sign-in method")
                .mokoText(Theme.Typeface.fieldLabel)
                .foregroundStyle(Theme.Colors.textMuted)

            HStack(spacing: Theme.Space.s3) {
                Image(systemName: signInMethod.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.dataVioletDeep)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.Colors.dataVioletLight.opacity(0.55)))

                VStack(alignment: .leading, spacing: 2) {
                    Text(signInMethod.title)
                        .mokoText(Theme.Typeface.cardTitle)
                        .foregroundStyle(Theme.Colors.textTitle)
                    if let detail = signInMethod.detail {
                        Text(detail)
                            .mokoText(Theme.Typeface.caption)
                            .foregroundStyle(Theme.Colors.textMuted)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }

                Spacer(minLength: 0)

                if case .unknown = signInMethod {} else {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Theme.Colors.dataVioletDeep)
                        .accessibilityHidden(true)
                }
            }
            .padding(Theme.Space.s3)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                    .fill(Theme.Colors.surfaceLavender)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Signed in with \(signInMethod.title)")
        }
    }

    // MARK: Pinned buttons

    private var actionBar: some View {
        VStack(spacing: Theme.Space.s2) {
            Button(action: save) {
                Group {
                    if isSaving {
                        ProgressView().tint(Theme.Colors.textOnBrand)
                    } else {
                        Text("Save")
                            .mokoText(Theme.Typeface.button)
                    }
                }
                .foregroundStyle(Theme.Colors.textOnBrand)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(
                    Capsule()
                        .fill(Theme.Colors.dataVioletDeep)
                        .shadow(color: Theme.Elevation.ambientColor, radius: 10, x: 0, y: 4)
                )
                .opacity(isValidForm ? 1 : 0.5)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
            .accessibilityLabel("Save profile")

            // Only email accounts have a password to change.
            if signInMethod.isEmail, let onChangePassword {
                Button(action: onChangePassword) {
                    Text("Change password")
                        .mokoText(Theme.Typeface.button)
                        .foregroundStyle(Theme.Colors.textBody)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Capsule().fill(Theme.Colors.surfaceLavender))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Theme.Space.page)
        .padding(.top, Theme.Space.s3)
        .padding(.bottom, Theme.Space.s3)
        .background(.ultraThinMaterial)
    }

    // MARK: Data

    /// Copies the saved profile into the form.
    private func loadProfile() {
        guard let profile = profiles.first else { return }
        name = profile.username
        handle = profile.handle ?? ""
        age = profile.age
        photoData = profile.profileImageData
    }

    /// Reads the picked profile photo from the library and shrinks it to a square.
    private func loadPhoto() async {
        guard let raw = try? await photoItem?.loadTransferable(type: Data.self),
              let image = UIImage(data: raw) else { return }
        photoData = centeredJPEG(image, size: CGSize(width: 512, height: 512), quality: 0.78)
    }

    /// Crops the middle of an image to `size` and saves it as a JPEG, which keeps the database small.
    private func centeredJPEG(_ image: UIImage, size: CGSize, quality: CGFloat) -> Data? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1     // `size` is real pixels, not points
        return UIGraphicsImageRenderer(size: size, format: format)
            .jpegData(withCompressionQuality: quality) { _ in
                let source = image.size
                let scale = max(size.width / source.width, size.height / source.height)
                let drawSize = CGSize(width: source.width * scale, height: source.height * scale)
                let rect = CGRect(x: (size.width - drawSize.width) / 2,
                                  y: (size.height - drawSize.height) / 2,
                                  width: drawSize.width, height: drawSize.height)
                image.draw(in: rect)
            }
    }

    /// Checks the form, updates (or creates) the Profile, then saves to disk.
    /// Age is never written here: it is read-only.
    private func save() {
        showValidation = true
        guard isValidForm else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }

        isSaving = true
        saveError = nil
        let normalizedHandle = trimmedHandle.isEmpty ? nil : trimmedHandle

        if let profile = profiles.first {
            profile.username = trimmedName
            profile.handle = normalizedHandle
            profile.profileImageData = photoData
            profile.updatedAt = .now
        } else {
            // No profile yet (e.g. the user skipped onboarding), so make one.
            modelContext.insert(Profile(
                username: trimmedName,
                handle: normalizedHandle,
                ageRange: nil,
                age: 0,
                profileImageData: photoData
            ))
        }

        do {
            try modelContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            dismiss()
        } catch {
            isSaving = false
            saveError = "Your changes could not be saved. Please try again."
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

#Preview {
    ProfileOverViewEditProfile(onChangePassword: {})
        .modelContainer(for: Profile.self, inMemory: true)
}
