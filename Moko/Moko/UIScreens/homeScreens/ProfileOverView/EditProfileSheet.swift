//
//  EditProfileSheet.swift
//  Moko
//
//  Profile → Edit: change the photo, display name, username and age range.
//  Changes are kept in @State while editing and are saved to SwiftData only
//  when the user taps Save.
//

import SwiftUI
import PhotosUI
import SwiftData
import UIKit

struct ProfileOverViewEditProfile: View {
    // Closes this sheet.
    @Environment(\.dismiss) private var dismiss
    // The SwiftData "database" we save the profile into.
    @Environment(\.modelContext) private var modelContext
    // @Query reads every saved Profile. The app only ever keeps one.
    @Query private var profiles: [Profile]
    
    // Haptic feedback for validation
    @State private var feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    // Copies of the profile fields that the form edits.
    @State private var name = ""
    @State private var handle = ""
    @State private var ageRange = ""
    // The photo picked from the library, and its compressed bytes.
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    // Shows the "Choose a Moko avatar" menu.
    @State private var showAvatarChoices = false
    // Only show "Enter a display name" after the user has tried to save.
    @State private var showValidation = false
    // A message shown if saving to the database fails.
    @State private var saveError: String?
    
    // Loading state for save operation
    @State private var isSaving = false

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
            return "Username can only contain letters, numbers, underscores, and hyphens."
        }
        return nil
    }
    
    private var isValidForm: Bool {
        nameError == nil && handleError == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(alignment: .center, spacing: 16) {
                        avatarPreview
                            .frame(width: 96, height: 96)
                        VStack(alignment: .leading, spacing: 10) {
                            PhotosPicker(selection: $photoItem, matching: .images) {
                                Label(photoData == nil ? "Choose Photo" : "Change Photo", systemImage: "photo")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(MokoScreenTheme.Colors.dataVioletDeep, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(MokoScreenTheme.Colors.textOnBrand)

                            Button {
                                showAvatarChoices = true
                            } label: {
                                Label("Choose Moko", systemImage: "pawprint")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(MokoScreenTheme.Colors.dataVioletLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(MokoScreenTheme.Colors.textBody)

                            if photoData != nil {
                                Button(role: .destructive) {
                                    photoData = nil
                                    photoItem = nil
                                } label: {
                                    Label("Remove Photo", systemImage: "trash")
                                        .font(.subheadline.weight(.medium))
                                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(MokoScreenTheme.Colors.error)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Profile photo")
                        .mokoText(MokoScreenTheme.Typeface.sectionHeader)
                } footer: {
                    Text("Preview shows the centered square crop that will be saved.")
                        .mokoText(MokoScreenTheme.Typeface.caption)
                }

                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Display name")
                            .mokoText(MokoScreenTheme.Typeface.fieldLabel)
                            .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        
                        TextField("Required", text: $name)
                            .mokoText(MokoScreenTheme.Typeface.body)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(nameError != nil && showValidation ? MokoScreenTheme.Colors.error : MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
                                    )
                            )
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 30 { name = String(newValue.prefix(30)) }
                            }
                        
                        if showValidation, let nameError {
                            Text(nameError)
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .foregroundStyle(MokoScreenTheme.Colors.error)
                                .accessibilityAddTraits(.isStaticText)
                                .padding(.horizontal, 4)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username (optional)")
                            .mokoText(MokoScreenTheme.Typeface.fieldLabel)
                            .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        
                        TextField("username", text: $handle)
                            .mokoText(MokoScreenTheme.Typeface.body)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(handleError != nil && showValidation ? MokoScreenTheme.Colors.error : MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
                                    )
                            )
                            .onChange(of: handle) { _, newValue in
                                // Remove spaces from username
                                if newValue.contains(" ") {
                                    handle = newValue.replacingOccurrences(of: " ", with: "")
                                }
                            }
                        
                        if showValidation, let handleError {
                            Text(handleError)
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .foregroundStyle(MokoScreenTheme.Colors.error)
                                .accessibilityAddTraits(.isStaticText)
                                .padding(.horizontal, 4)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age range (optional)")
                            .mokoText(MokoScreenTheme.Typeface.fieldLabel)
                            .foregroundStyle(MokoScreenTheme.Colors.textBody)
                        
                        Menu {
                            Button("Prefer not to say") { ageRange = "" }
                            Divider()
                            ForEach(["13–17", "18–24", "25–34", "35–44", "45+"], id: \.self) { range in
                                Button(range) { ageRange = range }
                            }
                        } label: {
                            HStack {
                                Text(ageRange.isEmpty ? "Select age range" : ageRange)
                                    .mokoText(MokoScreenTheme.Typeface.body)
                                    .foregroundStyle(ageRange.isEmpty ? MokoScreenTheme.Colors.textMuted : MokoScreenTheme.Colors.textBody)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(MokoScreenTheme.Colors.textMuted)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(MokoScreenTheme.Colors.canvasTop.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(MokoScreenTheme.Colors.borderSubtle, lineWidth: 1)
                                    )
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                } header: {
                    Text("Your details")
                        .mokoText(MokoScreenTheme.Typeface.sectionHeader)
                }

                if let saveError {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(MokoScreenTheme.Colors.error)
                            
                            Text(saveError)
                                .mokoText(MokoScreenTheme.Typeface.caption)
                                .foregroundStyle(MokoScreenTheme.Colors.error)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(MokoBackdrop())
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .close) { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Close")
                    .foregroundStyle(MokoScreenTheme.Colors.textBody)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: MokoScreenTheme.Colors.textOnBrand))
                        } else {
                            Text("Save")
                                .mokoText(MokoScreenTheme.Typeface.button)
                        }
                    }
                    .mokoButtonStyle(.primary, isLoading: isSaving, isDisabled: !isValidForm)
                    .disabled(!isValidForm || isSaving)
                }
            }
            .confirmationDialog("Choose a Moko avatar", isPresented: $showAvatarChoices, titleVisibility: .visible) {
                Button("Calm Moko") { 
                    photoData = compressedAvatar(named: "profile_empty_moko")
                    feedbackGenerator.impactOccurred()
                }
                Button("Waving Moko") { 
                    photoData = compressedAvatar(named: "welcome_moko")
                    feedbackGenerator.impactOccurred()
                }
                Button("Cancel", role: .cancel) { }
            }
            // Fill the form with the saved profile when the sheet opens.
            .onAppear(perform: loadProfile)
            // `.task(id:)` runs again every time `photoItem` changes, i.e. after the user picks a photo.
            .task(id: photoItem) { await loadPhoto() }
        }
        .tint(MokoScreenTheme.Colors.dataVioletDeep)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }

    private var avatarPreview: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("profile_empty_moko")
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            }
        }
        .frame(width: 96, height: 96)
        .background(MokoScreenTheme.Colors.canvasTop.opacity(0.1), in: Circle())
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(MokoScreenTheme.Colors.dataVioletLight.opacity(0.3), lineWidth: 2)
        )
        .overlay(
            Circle()
                .stroke(MokoScreenTheme.Colors.canvasTop, lineWidth: 6)
                .blendMode(.overlay)
        )
        .accessibilityLabel("Profile photo preview")
        .onTapGesture {
            showAvatarChoices = true
            feedbackGenerator.impactOccurred()
        }
    }

    /// Copies the saved profile into the form fields.
    private func loadProfile() {
        guard let profile = profiles.first else { return }
        name = profile.username
        handle = profile.handle ?? ""
        ageRange = profile.ageRange ?? inferredAgeRange(profile.age)
        photoData = profile.profileImageData
    }

    /// Older profiles stored only an age number. This turns it into one of the picker's ranges.
    private func inferredAgeRange(_ age: Int) -> String {
        switch age {
        case 13..<18: "13–17"
        case 18..<25: "18–24"
        case 25..<35: "25–34"
        case 35..<45: "35–44"
        case 45...: "45+"
        default: ""
        }
    }

    /// The opposite of `inferredAgeRange`: one age number for a range (0 means "not given").
    private func representativeAge(_ range: String) -> Int {
        switch range {
        case "13–17": 15
        case "18–24": 21
        case "25–34": 30
        case "35–44": 40
        case "45+": 50
        default: 0
        }
    }

    /// Reads the picked photo from the library and shrinks it. `try?` turns a failure into `nil`.
    private func loadPhoto() async {
        guard let raw = try? await photoItem?.loadTransferable(type: Data.self),
              let image = UIImage(data: raw) else { return }
        photoData = centeredSquareJPEG(image)
    }

    /// Turns a Moko picture from Assets into avatar bytes.
    private func compressedAvatar(named name: String) -> Data? {
        guard let image = UIImage(named: name) else { return nil }
        return centeredSquareJPEG(image)
    }

    /// Crops the middle square of an image, resizes it to 512 x 512 and saves it as a JPEG.
    /// A small image keeps the database small.
    private func centeredSquareJPEG(_ image: UIImage) -> Data? {
        let side: CGFloat = 512
        let format = UIGraphicsImageRendererFormat.default()
        // Scale 1 means 512 real pixels, not 512 x 3 on a Retina screen.
        format.scale = 1
        // UIGraphicsImageRenderer is a blank canvas. We draw the photo on it, centred and filling it.
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).jpegData(withCompressionQuality: 0.78) { _ in
            let source = image.size
            let scale = side / min(source.width, source.height)
            let drawSize = CGSize(width: source.width * scale, height: source.height * scale)
            let rect = CGRect(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2, width: drawSize.width, height: drawSize.height)
            image.draw(in: rect)
        }
    }

    /// Checks the name, updates (or creates) the Profile, then saves to disk.
    private func save() {
        showValidation = true
        
        guard isValidForm else {
            // Play haptic feedback for validation error
            feedbackGenerator.impactOccurred(intensity: 0.7)
            return
        }
        
        isSaving = true
        feedbackGenerator.impactOccurred(intensity: 0.5)
        
        let normalizedHandle = trimmedHandle.isEmpty ? nil : trimmedHandle
        let savedAge = representativeAge(ageRange)
        
        // Simulate network delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            do {
                if let profile = profiles.first {
                    profile.username = trimmedName
                    profile.handle = normalizedHandle
                    profile.ageRange = ageRange.isEmpty ? nil : ageRange
                    profile.age = savedAge
                    profile.profileImageData = photoData
                    profile.updatedAt = .now
                } else {
                    // No profile yet (e.g. the user skipped onboarding), so make one.
                    modelContext.insert(Profile(
                        username: trimmedName,
                        handle: normalizedHandle,
                        ageRange: ageRange.isEmpty ? nil : ageRange,
                        age: savedAge,
                        profileImageData: photoData
                    ))
                }
                
                // Write the changes to disk
                try modelContext.save()
                
                // Success haptic
                let successGenerator = UINotificationFeedbackGenerator()
                successGenerator.notificationOccurred(.success)
                
                // Close the sheet after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    dismiss()
                }
                
            } catch {
                isSaving = false
                saveError = "Your changes could not be saved. Please try again."
                
                // Error haptic
                let errorGenerator = UINotificationFeedbackGenerator()
                errorGenerator.notificationOccurred(.error)
            }
        }
    }
}

#Preview {
    ProfileOverViewEditProfile().modelContainer(for: Profile.self, inMemory: true)
}
