import Foundation
import Supabase

class SupabaseConfig {
    static let shared = SupabaseConfig()

    let client: SupabaseClient

    private init() {
        do {
            let supabaseURL = try AppRuntimeConfig.supabaseURL()
            let supabaseAnonKey = try AppRuntimeConfig.supabaseAnonKey()

            self.client = SupabaseClient(
                supabaseURL: supabaseURL,
                supabaseKey: supabaseAnonKey
            )
        } catch {
            fatalError("Failed to initialize Supabase client: \(error.localizedDescription)")
        }
    }
}
