//
//  AuthService.swift
//  Moko
//
//  Created by user@37 on 22/10/26.
//



import Foundation
import Supabase
import Auth
import Foundation

final class AuthService {
    private let supabase = SupabaseManager.shared.client

    // Create a new account
    func signUp(email: String, password: String) async throws {
        try await supabase.auth.signUp(
            email: email,
            password: password
        )
    }

    // Sign in with an existing account
    func signIn(email: String, password: String) async throws {
        try await supabase.auth.signIn(
            email: email,
            password: password
        )
    }

    // Sign out
    func signOut() async throws {
        try await supabase.auth.signOut()
    }

    // Get the currently signed-in user
    func getCurrentUser() async throws -> User {
        try await supabase.auth.session.user
    }

    /// Calls the authenticated Supabase Edge Function. The function must be
    /// deployed with SUPABASE_SERVICE_ROLE_KEY configured on the server.
    func deleteAccount() async throws {
        let session = try await supabase.auth.session
        var request = URLRequest(url: URL(string: "https://qyxnhmnfzcxbtphzwsiq.supabase.co/functions/v1/delete-account")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("sb_publishable_FQ9z4QOjVYI-KUG_sRnujQ_kRI-In5P", forHTTPHeaderField: "apikey")
        request.httpBody = Data("{}".utf8)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
