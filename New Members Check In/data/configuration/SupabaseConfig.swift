import Foundation
import Supabase

// Supabase configuration singleton
class SupabaseConfig {
    static let shared = SupabaseConfig()

    let client: SupabaseClient

    private init() {
        // TODO: Replace with your actual Supabase URL and anon key
        let supabaseURL = URL(string: "https://example-project-id.supabase.co")!
        let supabaseAnonKey = "REDACTED_SUPABASE_ANON_KEY"

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
}
