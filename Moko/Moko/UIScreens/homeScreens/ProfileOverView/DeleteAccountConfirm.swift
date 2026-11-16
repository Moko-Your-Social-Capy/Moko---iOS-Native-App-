//
//  DeleteAccountConfirm.swift
//  Moko
//
//  Delete account, steps 1 and 2:
//  1. `ProfileOverViewDeleteAccountConfirm` lists what will be deleted.
//  2. `ProfileOverViewDeleteReauthentication` asks for the password again.
//  Step 3 is `ProfileOverViewDeleteFinalConfirmation` (DeleteAccountFinalConfirm.swift).
//

import SwiftUI
import Auth

/// Step 1: explains what will be deleted.
struct ProfileOverViewDeleteAccountConfirm: View {
    var body: some View {
        List {
            Section {
                Text("This permanently deletes your account and cannot be undone.")
                    .foregroundStyle(ProfilePalette.text)
                Label("Your profile and account details", systemImage: "person.crop.circle")
                Label("Quests, scores, streaks and badges", systemImage: "chart.bar")
                Label("Reflection text and calm-session history", systemImage: "text.alignleft")
                Label("Voice recordings, if you have any", systemImage: "waveform")
            } header: {
                Text("What will be deleted")
            } footer: {
                Text("Moko does not currently record voice reflections. Your local app data is cleared only after the server confirms account deletion.")
            }
            Section {
                NavigationLink {
                    ProfileOverViewDeleteReauthentication()
                } label: {
                    Text("Continue to verification")
                        .fontWeight(.semibold)
                        .frame(minHeight: 44)
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.large)
        .tint(ProfilePalette.accent)
    }
}

/// Step 2: the user signs in again so nobody else can delete their account.
struct ProfileOverViewDeleteReauthentication: View {
    // What the user types in the two fields.
    @State private var email = ""
    @State private var password = ""
    // A red message under the fields when sign-in fails. `nil` means no message.
    @State private var error: String?
    // True while we wait for Supabase, so the button shows a spinner.
    @State private var isLoading = false
    // Becomes true after a correct password and opens step 3.
    @State private var isVerified = false

    var body: some View {
        Form {
            Section {
                Text("Sign in again to confirm that it is you.")
                    .foregroundStyle(ProfilePalette.secondary)
                TextField("Email", text: $email)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                SecureField("Password", text: $password)
                    .textContentType(.password)
            } header: {
                Text("Verify your account")
            }
            if let error { Section { Text(error).foregroundStyle(ProfilePalette.error) } }
            Section {
                Button {
                    Task { await reauthenticate() }
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            MokoLoadingView()
                                .frame(width: 30, height: 30)
                        } else {
                            Text("Verify and continue").fontWeight(.semibold)
                        }
                        Spacer()
                    }.frame(minHeight: 44)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(MokoBackdrop())
        .navigationTitle("Verify identity")
        .navigationBarTitleDisplayMode(.inline)
        // When `isVerified` turns true, push the final step onto the navigation stack.
        .navigationDestination(isPresented: $isVerified) {
            ProfileOverViewDeleteFinalConfirmation()
        }
        // `.task` runs when the screen appears: fill in the email for the user.
        .task {
            if let user = try? await AuthService().getCurrentUser() { email = user.email ?? "" }
        }
        .tint(ProfilePalette.accent)
    }

    /// Signs in with the typed details. Success opens the final step.
    @MainActor private func reauthenticate() async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await AuthService().signIn(email: email, password: password)
            isVerified = true
        } catch {
            self.error = "We could not verify those details. Check them and try again."
        }
    }
}
