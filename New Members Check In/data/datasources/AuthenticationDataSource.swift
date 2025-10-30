import Foundation
import Supabase

/// Pure data source for authentication operations
/// Handles all Supabase authentication API calls without managing state
class AuthenticationDataSource {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseConfig.shared.client) {
        self.client = client
    }

    /// Sign in with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: The authenticated session
    /// - Throws: Authentication errors from Supabase
    func signIn(email: String, password: String) async throws -> Session {
        return try await client.auth.signIn(email: email, password: password)
    }

    /// Sign out the current user
    /// - Throws: Sign out errors from Supabase
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Get the current session if available
    /// - Returns: The current session, or throws if no valid session exists
    /// - Throws: Session retrieval errors from Supabase
    func getSession() async throws -> Session {
        return try await client.auth.session
    }
}
