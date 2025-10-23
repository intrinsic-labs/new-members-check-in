import Foundation
import Supabase

// Supabase configuration singleton
class SupabaseConfig {
    static let shared = SupabaseConfig()

    let client: SupabaseClient

    private init() {
        // TODO: Replace with your actual Supabase URL and anon key
        let supabaseURL = URL(string: "https://xfpynuflzqllxqzecazt.supabase.co")!
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhmcHludWZsenFsbHhxemVjYXp0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjExODIxMzEsImV4cCI6MjA3Njc1ODEzMX0.iXKc__ZpQijrN9ZRJwR026scwV1KO4WqJhBj2L-aDgM"

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey
        )
    }
}
