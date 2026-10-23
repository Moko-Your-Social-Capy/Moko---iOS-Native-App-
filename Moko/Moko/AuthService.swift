//
//  AuthService.swift
//  Moko
//
//  Created by user@37 on 22/10/26.
//



import Foundation
import Supabase
import Auth

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
}
