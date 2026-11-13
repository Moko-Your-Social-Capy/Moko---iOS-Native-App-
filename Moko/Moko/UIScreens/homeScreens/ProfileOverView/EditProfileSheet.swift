import SwiftUI
import PhotosUI
import SwiftData
import UIKit

struct ProfileOverViewEditProfile: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    @State private var name = ""
    @State private var handle = ""
    @State private var ageRange = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    @State private var showAvatarChoices = false
    @State private var showValidation = false
    @State private var saveError: String?

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var nameError: String? {
        if trimmedName.isEmpty { return "Enter a display name." }
        if trimmedName.count > 30 { return "Use 30 characters or fewer." }
        return nil
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
                                    .background(ProfilePalette.lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(ProfilePalette.text)

                            Button {
                                showAvatarChoices = true
                            } label: {
                                Label("Choose Moko", systemImage: "pawprint")
                                    .font(.subheadline.weight(.semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .frame(maxWidth: .infinity, minHeight: 48)
                                    .background(ProfilePalette.lime, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(ProfilePalette.text)

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
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                } header: {
                    Text("Profile photo")
                } footer: {
                    Text("Preview shows the centered square crop that will be saved.")
                }

                Section("Your details") {
                    LabeledContent("Display name") {
                        TextField("Required", text: $name)
                            .multilineTextAlignment(.leading)
                            .textInputAutocapitalization(.words)
                            .onChange(of: name) { _, newValue in
                                if newValue.count > 30 { name = String(newValue.prefix(30)) }
                            }
                    }
                    if showValidation, let nameError {
                        Text(nameError)
                            .font(.footnote)
                            .foregroundStyle(ProfilePalette.error)
                            .accessibilityAddTraits(.isStaticText)
                    }
                    LabeledContent("Username (optional)") {
                        TextField("username", text: $handle)
                            .multilineTextAlignment(.leading)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    Picker("Age range (optional)", selection: $ageRange) {
                        Text("Prefer not to say").tag("")
                        ForEach(["13–17", "18–24", "25–34", "35–44", "45+"], id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                }

                if let saveError {
                    Section {
                        Text(saveError).foregroundStyle(ProfilePalette.error)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(ProfilePalette.background)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Dismissal is a cross, not a "Cancel" title: this is a sheet, so the system
                    // close affordance is the expected control (role `.close` is iOS 26+).
                    // No explicit frame/buttonStyle — the toolbar sizes and shapes it like the
                    // system close button (a fixed 44 pt frame stretched the glass capsule).
                    Button(role: .close) { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close")
                    .font(.body.weight(.medium))
                    .foregroundStyle(ProfilePalette.text)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(ProfilePalette.text)
                        .frame(minWidth: 44, minHeight: 44)
                        .buttonStyle(.plain)
                }
            }
            .confirmationDialog("Choose a Moko avatar", isPresented: $showAvatarChoices, titleVisibility: .visible) {
                Button("Calm Moko") { photoData = compressedAvatar(named: "profile_empty_moko") }
                Button("Waving Moko") { photoData = compressedAvatar(named: "welcome_moko") }
                Button("Cancel", role: .cancel) { }
            }
            .onAppear(perform: loadProfile)
            .task(id: photoItem) { await loadPhoto() }
        }
        .tint(ProfilePalette.accent)
    }

    private var avatarPreview: some View {
        Group {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Image("profile_empty_moko")
                    .resizable().scaledToFit()
                    .padding(8)
            }
        }
        .frame(width: 96, height: 96)
        .background(ProfilePalette.grouped, in: Circle())
        .clipShape(Circle())
        .overlay(Circle().stroke(ProfilePalette.accent.opacity(0.22), lineWidth: 1))
        .accessibilityLabel("Profile photo preview")
    }

    private func loadProfile() {
        guard let profile = profiles.first else { return }
        name = profile.username
        handle = profile.handle ?? ""
        ageRange = profile.ageRange ?? inferredAgeRange(profile.age)
        photoData = profile.profileImageData
    }

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

    private func loadPhoto() async {
        guard let raw = try? await photoItem?.loadTransferable(type: Data.self),
              let image = UIImage(data: raw) else { return }
        photoData = centeredSquareJPEG(image)
    }

    private func compressedAvatar(named name: String) -> Data? {
        guard let image = UIImage(named: name) else { return nil }
        return centeredSquareJPEG(image)
    }

    private func centeredSquareJPEG(_ image: UIImage) -> Data? {
        let side: CGFloat = 512
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).jpegData(withCompressionQuality: 0.78) { _ in
            let source = image.size
            let scale = side / min(source.width, source.height)
            let drawSize = CGSize(width: source.width * scale, height: source.height * scale)
            let rect = CGRect(x: (side - drawSize.width) / 2, y: (side - drawSize.height) / 2, width: drawSize.width, height: drawSize.height)
            image.draw(in: rect)
        }
    }

    private func save() {
        showValidation = true
        guard nameError == nil else { return }
        let normalizedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedAge = representativeAge(ageRange)
        if let profile = profiles.first {
            profile.username = trimmedName
            profile.handle = normalizedHandle.isEmpty ? nil : normalizedHandle
            profile.ageRange = ageRange.isEmpty ? nil : ageRange
            profile.age = savedAge
            profile.profileImageData = photoData
            profile.updatedAt = .now
        } else {
            modelContext.insert(Profile(username: trimmedName, handle: normalizedHandle.isEmpty ? nil : normalizedHandle,
                                        ageRange: ageRange.isEmpty ? nil : ageRange, age: savedAge, profileImageData: photoData))
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Your changes could not be saved. Try again."
        }
    }
}

#Preview {
    ProfileOverViewEditProfile().modelContainer(for: Profile.self, inMemory: true)
}
