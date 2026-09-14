import Foundation
import Supabase

final class SupabaseClientProvider: @unchecked Sendable {
    static let shared = SupabaseClientProvider()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseCredentials.urlString) else {
            fatalError("Invalid Supabase URL")
        }
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseCredentials.anonKey
        )
    }
}
