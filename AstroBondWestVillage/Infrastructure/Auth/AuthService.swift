import Foundation
import Supabase

struct AppUser: Equatable, Sendable {
    let id: String
    let email: String?
}

enum AuthServiceError: LocalizedError {
    case invalidCredentials
    case network(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "E-posta veya şifre hatalı."
        case .network(let message):
            return message
        }
    }
}

protocol AuthServing: Sendable {
    func currentUser() async -> AppUser?
    func signIn(email: String, password: String) async throws -> AppUser
    func signUp(email: String, password: String) async throws -> AppUser
    func sendPasswordReset(email: String) async throws
    func establishSession(from url: URL) async throws -> AppUser
    func updatePassword(_ password: String) async throws
    func signOut() async throws
    func deleteAccount() async throws
}

final class SupabaseAuthService: AuthServing, @unchecked Sendable {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }

    func currentUser() async -> AppUser? {
        guard let session = try? await withTimeout(seconds: 12, {
            try await self.client.auth.session
        }) else { return nil }
        return map(session.user)
    }

    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let session = try await client.auth.signIn(email: email, password: password)
            return map(session.user)
        } catch {
            throw AuthServiceError.invalidCredentials
        }
    }

    func signUp(email: String, password: String) async throws -> AppUser {
        do {
            let response = try await client.auth.signUp(email: email, password: password)
            guard let session = response.session else {
                throw AuthServiceError.invalidCredentials
            }
            return map(session.user)
        } catch let error as AuthServiceError {
            throw error
        } catch {
            throw AuthServiceError.network(error.localizedDescription)
        }
    }

    /// Asks Supabase to mail a real recovery link to this address.
    func sendPasswordReset(email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(email, redirectTo: AuthRedirect.reset)
        } catch {
            throw AuthServiceError.network(Self.resetMessage(for: error))
        }
    }

    func establishSession(from url: URL) async throws -> AppUser {
        do {
            let session = try await client.auth.session(from: url)
            return map(session.user)
        } catch {
            throw AuthServiceError.network("Sıfırlama bağlantısı geçersiz veya süresi dolmuş.")
        }
    }

    func updatePassword(_ password: String) async throws {
        do {
            _ = try await client.auth.update(user: UserAttributes(password: password))
        } catch {
            throw AuthServiceError.network(Self.resetMessage(for: error))
        }
    }

    func signOut() async throws {
        do {
            try await client.auth.signOut()
        } catch {
            throw AuthServiceError.network(error.localizedDescription)
        }
    }

    func deleteAccount() async throws {
        do {
            try await client.rpc("delete_own_account").execute()
        } catch {
            throw AuthServiceError.network(error.localizedDescription)
        }
    }

    private func map(_ user: User) -> AppUser {
        AppUser(id: user.id.uuidString.lowercased(), email: user.email)
    }

    private static func describe(_ error: Error) -> String {
        if let auth = error as? AuthError { return auth.message }
        return (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
    }

    private static func resetMessage(for error: Error) -> String {
        let raw = describe(error).lowercased()
        if raw.contains("rate") || raw.contains("too many") || raw.contains("429") {
            return "Çok sık denendi. Birkaç dakika sonra tekrar dene."
        }
        if raw.contains("weak") || raw.contains("password") {
            return "Daha güçlü bir şifre seç."
        }
        return "İşlem tamamlanamadı. Bağlantını kontrol edip tekrar dene."
    }
}

private func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    _ operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw AuthServiceError.network("Bağlantı zaman aşımı")
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
