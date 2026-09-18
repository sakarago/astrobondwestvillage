import SwiftUI

struct AuthSheetView: View {
    enum Mode: String, Equatable {
        case signIn
        case signUp
    }

    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode
    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @FocusState private var focused: Field?

    private enum Field { case email, password }

    init(mode: Mode) {
        _mode = State(initialValue: mode)
    }

    private var canSubmit: Bool {
        email.contains("@") && email.contains(".") && email.count >= 6 && password.count >= 6 && !isWorking
    }

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(ABColor.ink)
                            .crystalIconBezel(size: 36, cornerRadius: 12)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kapat")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(mode == .signUp ? "Hesap oluştur" : "Giriş")
                            .font(ABFont.display(28))
                            .foregroundStyle(ABColor.ink)

                        Text(mode == .signUp
                             ? "E-posta ile kaydol, haritanı oluşturmaya başla."
                             : "Mevcut AstroBond hesabınla devam et.")
                            .font(ABFont.body(14))
                            .foregroundStyle(ABColor.inkMuted)

                        CrystalField(
                            title: "E-POSTA",
                            text: $email,
                            keyboard: .emailAddress,
                            contentType: .emailAddress
                        )
                        .focused($focused, equals: .email)

                        CrystalField(
                            title: "ŞİFRE",
                            text: $password,
                            isSecure: true,
                            contentType: mode == .signIn ? .password : .newPassword
                        )
                        .focused($focused, equals: .password)

                        if let error = session.lastError, !error.isEmpty {
                            Text(error)
                                .font(ABFont.body(13))
                                .foregroundStyle(Color(hex: "#C69A9A"))
                        }
                    }
                    .padding(24)
                    .crystalPlate(cornerRadius: 28)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                HStack(spacing: 10) {
                    AuthPillButton(
                        title: isWorking && mode == .signIn ? "Bekle…" : "Giriş",
                        emphasized: mode == .signIn,
                        isEnabled: canSubmit
                    ) {
                        Task { await submit(.signIn) }
                    }
                    AuthPillButton(
                        title: isWorking && mode == .signUp ? "Bekle…" : "Kaydol",
                        emphasized: mode == .signUp,
                        isEnabled: canSubmit
                    ) {
                        Task { await submit(.signUp) }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 28)
                .padding(.top, 8)
            }
        }
        .onAppear { session.lastError = nil }
    }

    @MainActor
    private func submit(_ next: Mode) async {
        guard canSubmit else { return }
        mode = next
        isWorking = true
        defer { isWorking = false }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ok: Bool
        switch next {
        case .signIn:
            ok = await session.signIn(email: trimmed, password: password)
        case .signUp:
            ok = await session.signUp(email: trimmed, password: password)
        }
        if ok { dismiss() }
    }
}
