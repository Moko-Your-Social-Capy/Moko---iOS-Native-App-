
import SwiftUI
import Auth

struct ContentView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""
    @State private var isLoading = false
    @State private var isSignedIn = false

    private let auth = AuthService()
    private let googleAuth = GoogleAuthService()

    var body: some View {
        VStack(spacing: 20) {
            if isSignedIn {
                signedInView
            } else {
                loginView
            }
        }
        .padding(24)
    }

    private var loginView: some View {
        VStack(spacing: 20) {
            Text("Welcome to Moko")
                .font(.largeTitle.bold())

            Text("Sign in or create an account")
                .foregroundStyle(.secondary)

            TextField("Email address", text: $email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            SecureField("Password", text: $password)
                .textContentType(.password)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await authenticate(isSignup: true)
                }
            } label: {
                Text("Create Account")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Button {
                Task {
                    await authenticate(isSignup: false)
                }
            } label: {
                Text("Sign In")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)

                Text("OR")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(.quaternary)
            }

            Button {
                Task {
                    await signInWithGoogle()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                    Text("Continue with Google")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
            }

            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var signedInView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.green)

            Text("Welcome to Moko!")
                .font(.title.bold())

            Text(email.isEmpty ? "You're signed in." : email)
                .foregroundStyle(.secondary)

            Button("Sign Out") {
                Task {
                    await logout()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
            }

            if !message.isEmpty {
                Text(message)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
        }
    }

    @MainActor
    private func authenticate(isSignup: Bool) async {
        let cleanEmail = email.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !cleanEmail.isEmpty, !password.isEmpty else {
            message = "Please enter your email and password."
            return
        }

        guard password.count >= 6 else {
            message = "Password must contain at least 6 characters."
            return
        }

        isLoading = true
        message = ""
        defer { isLoading = false }

        do {
            if isSignup {
                try await auth.signUp(
                    email: cleanEmail,
                    password: password
                )

                do {
                    let user = try await auth.getCurrentUser()
                    email = user.email ?? cleanEmail
                    isSignedIn = true
                    message = ""
                } catch {
                    message = "Account created. Check your email to verify your account, then sign in."
                }
            } else {
                try await auth.signIn(
                    email: cleanEmail,
                    password: password
                )

                let user = try await auth.getCurrentUser()
                email = user.email ?? cleanEmail
                isSignedIn = true
                message = ""
            }
        } catch {
            message = error.localizedDescription
        }
    }

    @MainActor
    private func signInWithGoogle() async {
        isLoading = true
        message = ""
        defer { isLoading = false }

        do {
            try await googleAuth.signIn()

            let user = try await auth.getCurrentUser()
            email = user.email ?? ""
            password = ""
            isSignedIn = true
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }

    @MainActor
    private func logout() async {
        isLoading = true
        message = ""
        defer { isLoading = false }

        do {
            try await auth.signOut()
            isSignedIn = false
            password = ""
            message = ""
        } catch {
            message = error.localizedDescription
        }
    }
}

#Preview {
    ContentView()
}
