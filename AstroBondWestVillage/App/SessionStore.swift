import Foundation
import Observation

@MainActor
@Observable
final class SessionStore {
    enum Phase: Equatable {
        case loading
        case welcome
        case onboarding
        case main
    }

    private(set) var phase: Phase = .loading
    private(set) var user: AppUser?
    var lastError: String?
    /// Recovery link opened the app; the person still has to choose a new password.
    var isChoosingNewPassword = false
    /// Login sheet is up, so the new-password form replaces that sheet instead of stacking another one.
    var isLoginSheetPresented = false
    /// Presented from the root only when the login sheet is not already covering the screen.
    var showResetSheet = false
    private var didFinishPasswordReset = false
    private var handledAuthURL: String?
    private var isOpeningResetLink = false

    private let auth: AuthServing
    private let profiles = ProfileService()

    init(auth: AuthServing = SupabaseAuthService()) {
        self.auth = auth
    }

    func bootstrap() async {
        phase = .loading
        if let user = await auth.currentUser() {
            self.user = user
            if isChoosingNewPassword || isOpeningResetLink {
                phase = .welcome
            } else {
                await routeAuthenticated(userId: user.id)
            }
        } else {
            self.user = nil
            phase = .welcome
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        lastError = nil
        do {
            let user = try await auth.signIn(email: email, password: password)
            self.user = user
            await routeAuthenticated(userId: user.id)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func signUp(email: String, password: String) async -> Bool {
        lastError = nil
        do {
            let user = try await auth.signUp(email: email, password: password)
            self.user = user
            phase = .onboarding
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func markOnboardingComplete() async {
        phase = .main
    }

    func requestPasswordReset(email: String) async -> Bool {
        lastError = nil
        do {
            try await auth.sendPasswordReset(email: email)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func handleAuthURL(_ url: URL) async {
        guard url.scheme?.lowercased() == AuthRedirect.appCallback.scheme?.lowercased() else { return }
        let key = url.absoluteString
        guard handledAuthURL != key else { return }
        handledAuthURL = key
        isOpeningResetLink = true
        defer { isOpeningResetLink = false }
        lastError = nil
        do {
            let user = try await auth.establishSession(from: url)
            self.user = user
            didFinishPasswordReset = false
            isChoosingNewPassword = true
            showResetSheet = !isLoginSheetPresented
        } catch {
            handledAuthURL = nil
            lastError = error.localizedDescription
        }
    }

    func setNewPassword(_ password: String) async -> Bool {
        lastError = nil
        do {
            try await auth.updatePassword(password)
            didFinishPasswordReset = true
            isChoosingNewPassword = false
            showResetSheet = false
            if let user {
                await routeAuthenticated(userId: user.id)
            }
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    func cancelPasswordReset() async {
        guard !didFinishPasswordReset else {
            didFinishPasswordReset = false
            return
        }
        guard isChoosingNewPassword || showResetSheet else { return }
        isChoosingNewPassword = false
        showResetSheet = false
        await signOut()
    }

    func signOut() async {
        lastError = nil
        do {
            try await auth.signOut()
        } catch {
            lastError = error.localizedDescription
        }
        user = nil
        phase = .welcome
    }

    func freezeAccount() async {
        guard let id = user?.id else { return }
        lastError = nil
        do {
            try await profiles.setFrozen(userId: id, frozen: true)
            try await auth.signOut()
            user = nil
            phase = .welcome
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteAccount() async {
        lastError = nil
        do {
            try await auth.deleteAccount()
            try? await auth.signOut()
            user = nil
            phase = .welcome
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func routeAuthenticated(userId: String) async {
        if isChoosingNewPassword || isOpeningResetLink {
            phase = .welcome
            return
        }
        // Unfreeze if they return after freezing.
        try? await profiles.setFrozen(userId: userId, frozen: false)
        do {
            if let snap = try await profiles.fetchSnapshot(userId: userId), snap.hasBirthData {
                _ = try? await ChartService.shared.ensureOwnChart(userId: userId)
                phase = .main
            } else {
                phase = .onboarding
            }
        } catch {
            // Fail open to onboarding so the user can finish profile setup.
            phase = .onboarding
        }
    }
}
