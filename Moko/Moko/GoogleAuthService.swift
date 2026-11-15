//
//  GoogleAuthService.swift
//  Moko
//
//  "Continue with Google": shows Google's sign-in sheet, then hands the
//  Google token to Supabase so the user gets a normal Moko account.
//

import Foundation
import GoogleSignIn
import Supabase
import Auth
import UIKit

final class GoogleAuthService {
    private let supabase = SupabaseManager.shared.client

    /// Our app's IDs from the Google Cloud console.
    /// `clientID` is the iOS app, `serverClientID` is the one Supabase checks.
    private let configuration = GIDConfiguration(
        clientID: "431501174320-7d0a18atrmlqedt15le8039j21qdkdih.apps.googleusercontent.com",
        serverClientID: "431501174320-5fihd9ep0guqbkd8t4ihosg8ije0uo6j.apps.googleusercontent.com"
    )

    /// The two things that can go wrong before Supabase is even called.
    enum GoogleAuthError: LocalizedError {
        case noPresenter
        case missingIDToken

        var errorDescription: String? {
            switch self {
            case .noPresenter: "Unable to find a view controller for Google Sign-In."
            case .missingIDToken: "Google did not return an ID token."
            }
        }
    }

    // @MainActor: this touches windows and screens, which must happen on the main thread.
    @MainActor
    func signIn() async throws {
        // Google's SDK is UIKit-based and needs a UIViewController to show its sheet on.
        // SwiftUI has no option for this, so we look up the app's current window.
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: \.isKeyWindow),
            let presenter = window.rootViewController
        else {
            throw GoogleAuthError.noPresenter
        }

        GIDSignIn.sharedInstance.configuration = configuration

        // Shows the Google sheet and waits until the user finishes or cancels.
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenter)

        guard let idToken = result.user.idToken?.tokenString else {
            throw GoogleAuthError.missingIDToken
        }

        // Swap Google's tokens for a Supabase session (this signs the user in to Moko).
        try await supabase.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
        )
    }
}
