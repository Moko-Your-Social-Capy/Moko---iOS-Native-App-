
import Foundation
import GoogleSignIn
import Supabase
import Auth
import UIKit

final class GoogleAuthService {
    private let supabase = SupabaseManager.shared.client

    @MainActor
    func signIn() async throws {
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: \.isKeyWindow),
            let presenter = window.rootViewController
        else {
            throw NSError(
                domain: "GoogleAuth",
                code: 1,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Unable to find a view controller for Google Sign-In."
                ]
            )
        }

        let configuration = GIDConfiguration(
            clientID: "431501174320-7d0a18atrmlqedt15le8039j21qdkdih.apps.googleusercontent.com",
            serverClientID: "431501174320-5fihd9ep0guqbkd8t4ihosg8ije0uo6j.apps.googleusercontent.com"
        )

        GIDSignIn.sharedInstance.configuration = configuration

        let result = try await GIDSignIn.sharedInstance
            .signIn(withPresenting: presenter)

        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(
                domain: "GoogleAuth",
                code: 2,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Google did not return an ID token."
                ]
            )
        }

        let accessToken = result.user.accessToken.tokenString

        try await supabase.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(
                provider: .google,
                idToken: idToken,
                accessToken: accessToken
            )
        )
    }
}
