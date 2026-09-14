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
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Mode switcher — always visible so login isn't hidden behind signup.
                        HStack(spacing: 8) {
                            modeTab("Giriş", selected: mode == .signIn) { mode = .signIn }
                            modeTab("Kaydol", selected: mode == .signUp) { mode = .signUp }
                        }

                        Text(mode == .signUp ? "Hesap oluştur" : "Giriş yap")
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
                            contentType: .username
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

                        CrystalCTAButton(
                            title: isWorking ? "Bekle…" : (mode == .signUp ? "Kaydol" : "Giriş Yap"),
                            isEnabled: canSubmit
                        ) {
                            Task { await submit() }
                        }
                    }
                    .padding(24)
                    .crystalPlate(cornerRadius: 28)
                    .padding(20)
                    .padding(.bottom, 40)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(ABColor.inkMuted)
                }
            }
        }
        .onAppear {
            session.lastError = nil
            focused = .email
        }
        .onChange(of: mode) { _, _ in
            session.lastError = nil
        }
    }

    private func modeTab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? ABColor.ink : ABColor.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? ABColor.lavender.opacity(0.30) : Color.white.opacity(0.06))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? ABColor.lavenderSoft.opacity(0.55) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func submit() async {
        guard canSubmit else { return }
        isWorking = true
        defer { isWorking = false }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ok: Bool
        switch mode {
        case .signIn:
            ok = await session.signIn(email: trimmed, password: password)
        case .signUp:
            ok = await session.signUp(email: trimmed, password: password)
        }
        if ok { dismiss() }
    }
}
