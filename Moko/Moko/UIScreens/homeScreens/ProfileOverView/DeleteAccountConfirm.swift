import SwiftUI
import Auth

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
        .background(ProfilePalette.background)
        .navigationTitle("Delete account")
        .navigationBarTitleDisplayMode(.large)
        .tint(ProfilePalette.accent)
    }
}

struct ProfileOverViewDeleteReauthentication: View {
    @State private var email = ""
    @State private var password = ""
    @State private var error: String?
    @State private var isLoading = false
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
                            MokoFlossLoadingView(size: 30)
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
        .background(ProfilePalette.background)
        .navigationTitle("Verify identity")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isVerified) {
            ProfileOverViewDeleteFinalConfirmation()
        }
        .task {
            if let user = try? await AuthService().getCurrentUser() { email = user.email ?? "" }
        }
        .tint(ProfilePalette.accent)
    }

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
