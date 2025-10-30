import Foundation

@MainActor
class AuthUser: ObservableObject {
    enum CurrentView {
        case loginView, checkInView, missingMembersView, nothing
    }

    @Published var isCurrentlyViewing: CurrentView = .loginView
    @Published var isAuthenticated = false
    @Published var userEmail: String = ""
    @Published var errorMessage: String = ""
    @Published var isLoading = false

    private let authDataSource: AuthenticationDataSource
    private let keychain = KeychainManager.shared

    init(authDataSource: AuthenticationDataSource = AuthenticationDataSource()) {
        self.authDataSource = authDataSource
        Task {
            await restoreSessionIfAvailable()
        }
    }

    /// Attempt to restore a previous session from Keychain
    func restoreSessionIfAvailable() async {
        do {
            let session = try await authDataSource.getSession()
            if !session.isExpired {
                await MainActor.run {
                    self.isAuthenticated = true
                    self.userEmail = session.user.email ?? "Unknown"
                    self.isCurrentlyViewing = .checkInView
                }
            }
        } catch {
            print("No session to restore: \(error)")
        }
    }

    /// Sign in with email and password
    func signIn(email: String, password: String) async {
        await MainActor.run {
            self.isLoading = true
            self.errorMessage = ""
        }

        do {
            let session = try await authDataSource.signIn(email: email, password: password)

            await MainActor.run {
                self.isAuthenticated = true
                self.userEmail = session.user.email ?? email
                self.isCurrentlyViewing = .checkInView
                self.isLoading = false
            }

            print("Successfully signed in: \(email)")
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign in failed: \(error.localizedDescription)"
                self.isLoading = false
            }
            print("Sign in error: \(error)")
        }
    }

    /// Sign out and clear session
    func signOut() async {
        do {
            try await authDataSource.signOut()

            await MainActor.run {
                self.isAuthenticated = false
                self.userEmail = ""
                self.isCurrentlyViewing = .loginView
                self.errorMessage = ""
            }

            do {
                try keychain.delete()
            } catch {
                print("Failed to clear keychain: \(error)")
            }

            print("Successfully signed out")
        } catch {
            await MainActor.run {
                self.errorMessage = "Sign out failed: \(error.localizedDescription)"
            }
            print("Sign out error: \(error)")
        }
    }
}
