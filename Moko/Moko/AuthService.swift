//
//  AuthService.swift
//  Moko
//
//  Email accounts: sign up, sign in, sign out, read the current user and
//  delete the account. All of it goes through Supabase Auth.
//

import Foundation
import Supabase
import Auth

final class AuthService {
    private let supabase = SupabaseManager.shared.client

    /// Creates a new account with email and password.
    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(
            email: email,
            password: password
        )
    }

    /// Signs in to an existing account.
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }

    /// Signs out on this phone. Data stays saved on the server.
    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    /// The signed-in user. Throws if nobody is signed in.
    func getCurrentUser() async throws -> User {
        try await supabase.auth.session.user
    }

    /// Calls the authenticated Supabase Edge Function. The function must be
    /// deployed with SUPABASE_SERVICE_ROLE_KEY configured on the server.
    /// (Code: `supabase/functions/delete-account/index.ts`.)
    func deleteAccount() async throws {
        // The session holds the user's login token, which proves who is asking.
        let session = try await supabase.auth.session

        let url = SupabaseManager.projectURL.appending(path: "functions/v1/delete-account")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseManager.publishableKey, forHTTPHeaderField: "apikey")
        request.httpBody = Data("{}".utf8)

        // Send the request and wait for the answer.
        let (_, response) = try await URLSession.shared.data(for: request)

        // Any status outside 200–299 means the server said no.
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
