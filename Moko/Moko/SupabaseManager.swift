//
//  SupabaseManager.swift
//  Moko
//
//  The one connection to our Supabase backend (accounts, quests, imagery guides).
//  Every service uses `SupabaseManager.shared.client` instead of making its own.
//

import Foundation
import Supabase

final class SupabaseManager {
    /// One shared copy for the whole app (a "singleton").
    static let shared = SupabaseManager()

    /// Address of our Supabase project. Edge Functions live under this too.
    static let projectURL: URL = {
        // `URL(string:)` returns nil only if the text is not a valid web address.
        // This text never changes, so if it fails we made a typo and want to know right away.
        guard let url = URL(string: "https://qyxnhmnfzcxbtphzwsiq.supabase.co") else {
            fatalError("The Supabase project URL is not a valid URL.")
        }
        return url
    }()

    /// The public ("publishable") key. It is safe in the app; Supabase row rules protect the data.
    static let publishableKey = "sb_publishable_FQ9z4QOjVYI-KUG_sRnujQ_kRI-In5P"

    /// The Supabase client: use `.auth` for sign in and `.from("table")` for data.
    let client: SupabaseClient

    // `private init` stops anyone from making a second copy by accident.
    private init() {
        client = SupabaseClient(
            supabaseURL: Self.projectURL,
            supabaseKey: Self.publishableKey
        )
    }
}
