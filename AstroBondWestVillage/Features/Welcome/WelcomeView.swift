import SwiftUI

struct WelcomeView: View {
    @Environment(SessionStore.self) private var session

    @State private var showSplash = true
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: Double = 18
    @State private var wheelRotation: Double = 0
    @State private var showRegisterOptions = false
    @State private var acceptedTerms = false
    @State private var showTermsNotice = false
    @State private var emphasizeTerms = false
    @State private var showRequiredTag = false
    @State private var showLegal = false
    @State private var showLogin = false
    @State private var screen: Screen = .landing
    @State private var contactMethod: SignupContactMethod = .email
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var isWorking = false
    @State private var signUpError: String?

    private let gold = Color(hex: "#C8A56E")
    private let lavender = ABColor.lavender

    private enum Screen: Equatable {
        case landing
        case contact
        case password
    }

    var body: some View {
        ZStack {
            switch screen {
            case .landing:
                landing
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .contact:
                SignupContactStepView(
                    method: contactMethod,
                    email: $email,
                    phone: $phone,
                    isValid: contactMethod == .email ? isEmailValid : isPhoneValid,
                    onBack: goLanding,
                    onHome: goLanding,
                    onContinue: { withAnimation(.easeInOut(duration: 0.45)) { screen = .password } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            case .password:
                SignupPasswordStepView(
                    password: $password,
                    errorMessage: signUpError,
                    isSubmitting: isWorking,
                    onBack: { withAnimation(.easeInOut(duration: 0.45)) { screen = .contact } },
                    onHome: goLanding,
                    onContinue: { Task { await completeSignUp() } }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }

            if showSplash {
                WelcomeSplashView {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: screen)
        .sheet(isPresented: $showLogin) {
            AuthSheetView()
                .environment(session)
        }
        .sheet(isPresented: $showLegal) {
            NavigationStack { LegalAgreementView() }
                
        }
    }

    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        return trimmed.contains("@") && trimmed.contains(".") && trimmed.count >= 6
    }

    private var isPhoneValid: Bool {
        phone.filter(\.isNumber).count >= 10
    }

    private func goLanding() {
        withAnimation(.easeInOut(duration: 0.45)) {
            screen = .landing
            signUpError = nil
            isWorking = false
        }
    }

    @MainActor
    private func completeSignUp() async {
        guard password.count >= 6, !isWorking else { return }
        isWorking = true
        signUpError = nil
        defer { isWorking = false }

        if contactMethod == .phone {
            signUpError = "Telefon kaydı henüz açık değil. E-posta ile kaydol."
            return
        }

        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let ok = await session.signUp(email: trimmed, password: password)
        if !ok {
            signUpError = session.lastError ?? "Hesap oluşturulamadı."
        }
    }

    // MARK: - Landing

    private var landing: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let wheelSize = min(h * 0.34, 280)

            ZStack {
                CosmicBackdrop()

                CosmicMatchWheel(
                    rotation: wheelRotation,
                    isSpinning: false,
                    size: wheelSize
                )
                .allowsHitTesting(false)
                .position(x: w / 2, y: h * 0.40)
                .opacity(contentOpacity)

                OrbitRing(gold: gold)
                    .frame(width: wheelSize + 86, height: wheelSize + 86)
                    .rotationEffect(.degrees(wheelRotation))
                    .position(x: w / 2, y: h * 0.40)
                    .opacity(contentOpacity * 0.85)

                VStack(spacing: 0) {
                    logoBlock
                        .padding(.top, 18)

                    Spacer(minLength: 36)

                    ZStack {
                        if showRegisterOptions {
                            registerOptions
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            initialButtons
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.4), value: showRegisterOptions)
                    .padding(.horizontal, 24)
                    .padding(.top, 22)

                    legalText
                        .padding(.horizontal, 32)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                .offset(y: contentOffset)
                .opacity(contentOpacity)
            }
            .overlay(alignment: .topLeading) {
                if showRegisterOptions {
                    backButton
                        .padding(.leading, 20)
                        .padding(.top, 58)
                        .transition(.opacity)
                }
            }
        }
        .ignoresSafeArea(edges: [.top, .bottom])
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                contentOpacity = 1
                contentOffset = 0
            }
            withAnimation(.linear(duration: 60).repeatForever(autoreverses: false)) {
                wheelRotation = 360
            }
        }
    }

    private var logoBlock: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .trim(from: 0.0, to: 0.78)
                    .stroke(
                        LinearGradient(
                            colors: [gold.opacity(0.95), gold.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                    )
                    .frame(width: 38, height: 38)
                    .rotationEffect(.degrees(130))

                Text("✦")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(gold)
                    .offset(y: -1)

                Circle().fill(gold.opacity(0.85)).frame(width: 3, height: 3).offset(x: -27, y: -6)
                Circle().fill(gold.opacity(0.85)).frame(width: 3, height: 3).offset(x: 27, y: -6)
            }
            .padding(.top, 48)

            Text("ASTROBOND")
                .font(ABFont.display(16, weight: .regular))
                .tracking(8)
                .foregroundStyle(ABColor.ink.opacity(0.96))
                .padding(.leading, 9)

            Text("BAĞ GÖRÜNENDEN ÖNCE BAŞLAR")
                .font(ABFont.body(7.5, weight: .medium))
                .tracking(3.4)
                .foregroundStyle(Color(hex: "#E4E2F2"))
                .padding(.leading, 3.4)
        }
    }

    private var backButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.4)) {
                showRegisterOptions = false
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(ABColor.ink.opacity(0.95))
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(ABColor.veil.opacity(0.06))
                        .background(.ultraThinMaterial.opacity(0.6), in: Circle())
                )
                .overlay(Circle().strokeBorder(ABColor.veil.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var initialButtons: some View {
        VStack(spacing: 12) {
            GlowCTAButton(title: "Kaydol", lavender: lavender) {
                guard acceptedTerms else {
                    promptForTermsAcceptance()
                    return
                }
                withAnimation(.easeInOut(duration: 0.4)) {
                    showRegisterOptions = true
                }
            }
            GlowCTAButton(title: "Zaten Üyeyim", lavender: lavender) {
                showLogin = true
            }
        }
        .padding(.bottom, 36)
    }

    private var registerOptions: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                GlowCTAButton(title: "E-posta ile Devam Et", lavender: lavender) {
                    guard acceptedTerms else {
                        promptForTermsAcceptance()
                        return
                    }
                    contactMethod = .email
                    withAnimation(.easeInOut(duration: 0.45)) { screen = .contact }
                }
                GlowCTAButton(title: "Telefon No. ile Devam Et", lavender: lavender) {
                    guard acceptedTerms else {
                        promptForTermsAcceptance()
                        return
                    }
                    contactMethod = .phone
                    withAnimation(.easeInOut(duration: 0.45)) { screen = .contact }
                }
            }

            HStack(spacing: 12) {
                Rectangle().fill(ABColor.veil.opacity(0.14)).frame(height: 1)
                Text("veya şununla devam et")
                    .font(ABFont.body(13.5))
                    .foregroundStyle(Color(hex: "#8E8FA3"))
                    .fixedSize()
                Rectangle().fill(ABColor.veil.opacity(0.14)).frame(height: 1)
            }
            .padding(.top, 18)

            HStack(spacing: 14) {
                SocialButton(label: "Google") {
                    Text("G")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(ABColor.ink)
                }
                SocialButton(label: "Apple") {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 19))
                        .foregroundStyle(ABColor.ink)
                }
            }
            .padding(.top, 16)
        }
    }

    private var legalText: some View {
        VStack(alignment: .leading, spacing: 10) {
            if showTermsNotice {
                Text("Devam etmek için sözleşmeyi onaylamalısın.")
                    .font(ABFont.body(12, weight: .medium))
                    .foregroundStyle(ABColor.ink.opacity(0.96))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(lavender.opacity(0.18))
                            .background(.ultraThinMaterial.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(lavender.opacity(0.65), lineWidth: 1.2)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(alignment: .top, spacing: 10) {
                Button {
                    acceptedTerms.toggle()
                    if acceptedTerms {
                        showRequiredTag = false
                        showTermsNotice = false
                    }
                } label: {
                    Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(acceptedTerms ? lavender : lavender.opacity(0.92))
                        .scaleEffect(emphasizeTerms ? 1.14 : 1.0)
                        .animation(.spring(response: 0.28, dampingFraction: 0.55), value: emphasizeTerms)
                }
                .buttonStyle(.plain)
                .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    if showRequiredTag {
                        HStack(spacing: 4) {
                            Text("*")
                                .font(ABFont.body(13, weight: .bold))
                                .foregroundStyle(lavender)
                            Text("Zorunlu")
                                .font(ABFont.body(11.5, weight: .semibold))
                                .foregroundStyle(lavender.opacity(0.95))
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    Text(legalAttributed)
                        .font(ABFont.body(12.5))
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                        .contentShape(Rectangle())
                        .onTapGesture { showLegal = true }
                }

                Spacer(minLength: 0)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showTermsNotice)
    }

    private var legalAttributed: AttributedString {
        var text = AttributedString("Devam ederek Hizmet Şartları'nı ve Gizlilik Politikası'nı kabul etmiş olursun.")
        text.foregroundColor = Color(hex: "#8E8FA3")
        if let terms = text.range(of: "Hizmet Şartları") {
            text[terms].foregroundColor = lavender
        }
        if let privacy = text.range(of: "Gizlilik Politikası") {
            text[privacy].foregroundColor = lavender
        }
        return text
    }

    private func promptForTermsAcceptance() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showTermsNotice = true
            showRequiredTag = true
        }
        emphasizeTerms = true

        Task {
            try? await Task.sleep(for: .milliseconds(650))
            emphasizeTerms = false
            try? await Task.sleep(for: .milliseconds(1800))
            await MainActor.run {
                guard !acceptedTerms else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    showTermsNotice = false
                }
            }
        }
    }
}

private struct SocialButton<Icon: View>: View {
    let label: String
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: {}) {
            HStack(spacing: 10) {
                icon()
                Text(label)
                    .font(ABFont.body(16.5, weight: .semibold))
                    .foregroundStyle(ABColor.ink.opacity(0.95))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ABColor.veil.opacity(0.05))
                    .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(ABColor.veil.opacity(0.13), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct OrbitRing: View {
    let gold: Color

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let r = size / 2 - 2

            ZStack {
                Circle()
                    .stroke(
                        gold.opacity(0.40),
                        style: StrokeStyle(lineWidth: 1, dash: [1.5, 6])
                    )
                    .frame(width: r * 2, height: r * 2)
                    .position(center)

                ForEach(0..<16, id: \.self) { i in
                    let angle = Double(i) * 22.5
                    let rad = angle * .pi / 180
                    Circle()
                        .fill(gold.opacity(i % 2 == 0 ? 0.85 : 0.45))
                        .frame(width: i % 2 == 0 ? 4 : 2.5, height: i % 2 == 0 ? 4 : 2.5)
                        .shadow(color: gold.opacity(0.6), radius: 3)
                        .position(
                            x: center.x + cos(rad) * r,
                            y: center.y + sin(rad) * r
                        )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private struct WelcomeSplashView: View {
    let onFinish: () -> Void

    @State private var grown = false
    @State private var visible = false
    private let gold = Color(hex: "#C8A56E")

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let planetPoint = CGPoint(x: w / 2, y: h * 0.40)
            let centerPoint = CGPoint(x: w / 2, y: h / 2)

            ZStack {
                CosmicBackdrop()

                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .trim(from: 0.0, to: 0.78)
                            .stroke(
                                LinearGradient(
                                    colors: [gold.opacity(0.95), gold.opacity(0.55)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(130))

                        Text("✦")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(gold)
                            .offset(y: -35)

                        Circle().fill(gold.opacity(0.85)).frame(width: 3.5, height: 3.5).offset(x: -31, y: -7)
                        Circle().fill(gold.opacity(0.85)).frame(width: 3.5, height: 3.5).offset(x: 31, y: -7)
                    }

                    Text("ASTROBOND")
                        .font(ABFont.display(22, weight: .regular))
                        .tracking(9)
                        .foregroundStyle(ABColor.ink.opacity(0.97))
                        .padding(.leading, 10)

                    Text("BAĞ GÖRÜNENDEN ÖNCE BAŞLAR")
                        .font(ABFont.body(7.5, weight: .medium))
                        .tracking(3.6)
                        .foregroundStyle(Color(hex: "#E4E2F2"))
                        .padding(.leading, 3.6)
                }
                .scaleEffect(grown ? 1.0 : 0.015)
                .opacity(visible ? 1 : 0)
                .position(grown ? centerPoint : planetPoint)
                .shadow(color: gold.opacity(grown ? 0.0 : 0.9), radius: grown ? 0 : 6)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            visible = true
            withAnimation(.easeOut(duration: 3.0)) {
                grown = true
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 3_400_000_000)
            onFinish()
        }
    }
}

#Preview {
    WelcomeView()
        .environment(SessionStore())
}
