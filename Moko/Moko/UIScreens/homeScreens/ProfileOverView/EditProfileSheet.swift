//
//  ProfileOverViewEditProfile.swift
//  Moko
//
//  Edit Profile sheet (matches the "Edit Profile · Sheet · Light" prototype).
//  Show it with:
//      .sheet(isPresented: $showEditProfile) { ProfileOverViewEditProfile() }
//  Saves into the SwiftData Profile model (creates it the first time),
//  so Profile and Overview update automatically.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ProfileOverViewEditProfile: View {

    private let screenBg = Color(red: 242/255, green: 242/255, blue: 247/255)   // #F2F2F7
    private let deepGreen = Color(red: 27/255, green: 66/255, blue: 47/255)     // #1B422F

    @Environment(\.dismiss) private var dismiss

    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]

    // Editing copies, only saved when Save is tapped
    @State private var name = ""
    @State private var age = 24
    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var isValid: Bool { (3...20).contains(trimmedName.count) }

    var body: some View {
        NavigationStack {
            Form {
                // Photo
                Section {
                    VStack(spacing: 10) {
                        avatar
                        PhotosPicker("Choose Photo", selection: $photoItem, matching: .images)
                            .font(.subheadline.bold())
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }

                Section {
                    LabeledContent("Username") {
                        TextField("Username", text: $name)
                            .multilineTextAlignment(.leading)
                    }
                    Stepper("Age  \(age)", value: $age, in: 13...99)
                } footer: {
                    Text("Username is 3–20 characters. Age is shown on your profile.\nOnly the photo you choose is shared with MOKO. No email, phone or address is stored here.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(screenBg)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let profile = profiles.first {
                    name = profile.username
                    age = profile.age >= 13 ? profile.age : 24   // new account: age not set yet
                    photoData = profile.profileImageData
                }
            }
            .task(id: photoItem) {
                if let data = try? await photoItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoData = image.jpegData(compressionQuality: 0.8)
                }
            }
        }
        .tint(deepGreen)
    }

    private func save() {
        if let profile = profiles.first {
            profile.username = trimmedName
            profile.age = age
            profile.profileImageData = photoData
            profile.updatedAt = .now
        } else {
            modelContext.insert(Profile(username: trimmedName, age: age, profileImageData: photoData))
        }
        do { try modelContext.save() } catch { print("Profile save failed:", error) }
        dismiss()
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 96, height: 96)
            .background(Color(.systemGray5))
            .clipShape(Circle())

            Image(systemName: "camera.fill")
                .font(.caption)
                .foregroundStyle(deepGreen)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.white))
        }
    }
}

#Preview {
    ProfileOverViewEditProfile()
        .modelContainer(for: Profile.self, inMemory: true)
}
