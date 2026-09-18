import SwiftUI

struct AuthSheetView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isWorking = false
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool

    private let gold = Color(hex: "#C8A56E")

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            VStack(spacing: 9) {
                                ZStack {
                                    Circle()
                                        .trim(from: 0.0, to: 0.78)
                                        .stroke(
                                            LinearGradient(
                                                colors: [gold.opacity(0.95), gold.opacity(0.5)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                        )
                                        .frame(width: 30, height: 30)
                                        .rotationEffect(.degrees(130))
                                    Text("✦")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(gold)
                                        .offset(y: -20)
                                }
                                Text("ASTROBOND")
                                    .font(ABFont.display(17, weight: .regular))
                                    .tracking(6.5)
                                    .foregroundStyle(Color.white.opacity(0.95))
                                    .padding(.leading, 6.5)
                            }
                            .padding(.top, 12)

                            VStack(spacing: 14) {
                                Text("Yolculuğa Devam Et")
                                    .font(ABFont.display(24))
                                    .foregroundStyle(.white)

                                Text("Google, Apple ya da e-posta ile giriş yap.")
                                    .font(ABFont.body(14))
                                    .foregroundStyle(Color.white.opacity(0.62))
                            }

                            HStack(spacing: 12) {
                                loginProvider("Google") {
                                    Text("G")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.white)
                                }
                                loginProvider("Apple") {
                                    Image(systemName: "apple.logo")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                            }
                            .padding(.horizontal, 28)

                            HStack(spacing: 12) {
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.8)
                                Text("veya e-posta ile")
                                    .font(ABFont.body(12))
                                    .foregroundStyle(Color.white.opacity(0.4))
                                Rectangle().fill(Color.white.opacity(0.1)).frame(height: 0.8)
                            }
                            .padding(.horizontal, 28)

                            VStack(spacing: 12) {
                                HStack(spacing: 10) {
                                    Image(systemName: "envelope")
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundStyle(gold.opacity(0.7))

                                    ZStack(alignment: .leading) {
                                        if email.isEmpty {
                                            Text("E-posta adresi")
                                                .font(ABFont.body(16.5))
                                                .foregroundStyle(Color(hex: "#9AA0AB").opacity(0.7))
                                                .allowsHitTesting(false)
                                        }
                                        TextField("", text: $email)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                            .keyboardType(.emailAddress)
                                            .textContentType(.username)
                                            .font(ABFont.body(16.5))
                                            .foregroundStyle(.white)
                                            .tint(Color(hex: "#9AA0AB"))
                                            .focused($isEmailFocused)
                                            .submitLabel(.next)
                                            .onSubmit { isPasswordFocused = true }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 22)
                                .glowInputSurface()
                                .contentShape(Capsule())
                                .onTapGesture { isEmailFocused = true }
                                .id("loginEmail")

                                HStack(spacing: 10) {
                                    Image(systemName: "lock")
                                        .font(.system(size: 15, weight: .light))
                                        .foregroundStyle(gold.opacity(0.7))

                                    ZStack(alignment: .leading) {
                                        if password.isEmpty {
                                            Text("Parola")
                                                .font(ABFont.body(16.5))
                                                .foregroundStyle(Color(hex: "#9AA0AB").opacity(0.7))
                                                .allowsHitTesting(false)
                                        }
                                        SecureField("", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .textContentType(.password)
                                            .font(ABFont.body(16.5))
                                            .foregroundStyle(.white)
                                            .tint(Color(hex: "#9AA0AB"))
                                            .focused($isPasswordFocused)
                                            .submitLabel(.go)
                                            .onSubmit { Task { await submit() } }
                                    }
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal, 22)
                                .glowInputSurface()
                                .contentShape(Capsule())
                                .onTapGesture { isPasswordFocused = true }
                                .id("loginPassword")

                                if let error = session.lastError, !error.isEmpty {
                                    Text(error)
                                        .font(ABFont.body(13))
                                        .foregroundStyle(Color(hex: "#9AA0AB"))
                                }
                            }
                            .padding(.horizontal, 28)

                            GlowCTAButton(
                                title: isWorking ? "Giriş yapılıyor..." : "Giriş Yap",
                                isEnabled: !isWorking,
                                action: { Task { await submit() } }
                            )
                            .padding(.horizontal, 28)
                            .id("loginButton")

                            Color.clear.frame(height: 120)
                        }
                        .padding(.bottom, 24)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: isPasswordFocused) { _, focused in
                        guard focused else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("loginButton", anchor: .bottom)
                        }
                    }
                    .onChange(of: isEmailFocused) { _, focused in
                        guard focused else { return }
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo("loginEmail", anchor: .center)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.white.opacity(0.3))
                            .font(.system(size: 22))
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Tamam") {
                        isEmailFocused = false
                        isPasswordFocused = false
                    }
                    .foregroundStyle(ABColor.lavenderSoft)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            session.lastError = nil
            isEmailFocused = true
        }
    }

    private func loginProvider<Icon: View>(_ label: String, @ViewBuilder icon: () -> Icon) -> some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                icon()
                Text(label)
                    .font(ABFont.body(15.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .glowInputSurface()
        }
        .buttonStyle(.plain)
    }

    @MainActor
    private func submit() async {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard trimmed.contains("@"), trimmed.contains("."), password.count >= 6, !isWorking else {
            session.lastError = "Geçerli bir e-posta ve şifre gir."
            return
        }
        isWorking = true
        defer { isWorking = false }
        if await session.signIn(email: trimmed, password: password) {
            dismiss()
        }
    }
}
