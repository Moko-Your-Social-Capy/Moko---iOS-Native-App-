

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(
                string: "https://qyxnhmnfzcxbtphzwsiq.supabase.co"
            )!,
            supabaseKey: "sb_publishable_FQ9z4QOjVYI-KUG_sRnujQ_kRI-In5P"
        )
    }
}
