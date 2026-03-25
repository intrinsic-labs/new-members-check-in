import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()

    let client: SupabaseClient

    private init() {
        do {
            let supabaseURL = try AppRuntimeConfig.supabaseURL()
            let supabasePublishableKey = try AppRuntimeConfig.supabasePublishableKey()

            self.client = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: supabasePublishableKey
            )
        } catch {
            fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
        }
    }
}
