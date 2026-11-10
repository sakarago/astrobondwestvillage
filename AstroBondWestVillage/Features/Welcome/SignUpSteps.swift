import SwiftUI

enum SignupContactMethod {
    case email
    case phone
}

struct SignupShell<Content: View, Bottom: View>: View {
    var icon: String
    var title: String
    var subtitle: String
    var progressCurrent: Int
    var progressTotal: Int
    var onBack: () -> Void
    var onHome: () -> Void
    @ViewBuilder var content: () -> Content
    @ViewBuilder var bottom: () -> Bottom

    private let gold = Color(hex: "#C8A56E")

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                HStack {
                    chromeButton("chevron.left", action: onBack)
                    Spacer()
                    chromeButton("house", action: onHome)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer(minLength: 8)

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
                        .foregroundStyle(ABColor.ink.opacity(0.95))
                        .padding(.leading, 6.5)
                }
                .offset(y: -10)

                Spacer(minLength: 28)

                VStack(spacing: 14) {
                    ZStack {
                        Circle().fill(ABColor.veil.opacity(0.08))
                        Circle().strokeBorder(ABColor.veil.opacity(0.22), lineWidth: 1)
                        Image(systemName: icon)
                            .font(.system(size: 21, weight: .light))
                            .foregroundStyle(Color(hex: "#C9CFD9"))
                    }
                    .frame(width: 54, height: 54)

                    Text(title)
                        .font(ABFont.display(26))
                        .foregroundStyle(ABColor.ink)
                        .multilineTextAlignment(.center)

                    Text(subtitle)
                        .font(ABFont.body(13))
                        .foregroundStyle(ABColor.inkMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)

                    content()
                        .padding(.top, 4)
                }
                .padding(.vertical, 26)
                .padding(.horizontal, 20)
                .crystalPlate(cornerRadius: 30)
                .padding(.horizontal, 26)

                Spacer()

                bottom()
                    .padding(.horizontal, 26)
                    .padding(.bottom, 12)

                VStack(spacing: 8) {
                    HStack(spacing: 7) {
                        ForEach(0..<progressTotal, id: \.self) { i in
                            Capsule()
                                .fill(
                                    i == progressCurrent - 1
                                        ? gold
                                        : (i < progressCurrent - 1 ? gold.opacity(0.55) : ABColor.veil.opacity(0.18))
                                )
                                .frame(width: i == progressCurrent - 1 ? 18 : 7, height: 7)
                        }
                    }
                    Text("\(progressCurrent) / \(progressTotal)")
                        .font(ABFont.body(11.5, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(gold.opacity(0.75))
                }
                .padding(.bottom, 22)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 25)
                .onEnded { value in
                    if value.translation.width > 80, abs(value.translation.height) < 60 {
                        onBack()
                    }
                }
        )
    }

    private func chromeButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(gold.opacity(0.9))
                .frame(width: 38, height: 38)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().strokeBorder(gold.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct SignupContactStepView: View {
    let method: SignupContactMethod
    @Binding var email: String
    @Binding var phone: String
    let isValid: Bool
    var onBack: () -> Void
    var onHome: () -> Void
    var onContinue: () -> Void
    @FocusState private var isFieldFocused: Bool

    private var icon: String { method == .phone ? "phone" : "envelope" }
    private var title: String { method == .phone ? "Telefon" : "E-posta" }
    private var placeholder: String { method == .phone ? "Telefon numarası" : "E-posta adresi" }
    private var keyboard: UIKeyboardType { method == .phone ? .phonePad : .emailAddress }
    private var contentType: UITextContentType { method == .phone ? .telephoneNumber : .emailAddress }
    private var validMessage: String { method == .phone ? "Telefon numarası geçerli" : "E-posta adresi geçerli" }
    private var invalidMessage: String { method == .phone ? "Geçerli bir telefon numarası gir" : "Geçerli bir e-posta adresi gir" }
    private var text: Binding<String> { method == .phone ? $phone : $email }
    private var value: String { method == .phone ? phone : email }
    private let gold = Color(hex: "#C8A56E")

    var body: some View {
        SignupShell(
            icon: icon,
            title: title,
            subtitle: "Hesabını güvende tutmak ve sana ulaşabilmek için kullanacağız.",
            progressCurrent: 1,
            progressTotal: 2,
            onBack: onBack,
            onHome: onHome
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(gold.opacity(0.7))

                    ZStack(alignment: .leading) {
                        if value.isEmpty {
                            Text(placeholder)
                                .font(ABFont.body(16.5))
                                .foregroundStyle(Color(hex: "#9AA0AB").opacity(0.7))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: text)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .keyboardType(keyboard)
                            .textContentType(contentType)
                            .font(ABFont.body(16.5))
                            .foregroundStyle(ABColor.ink)
                            .tint(Color(hex: "#9AA0AB"))
                            .focused($isFieldFocused)
                    }
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 22)
                .glowInputSurface()
                .contentShape(Capsule())
                .onTapGesture { isFieldFocused = true }

                if !value.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(isValid ? Color(hex: "#A8F0C6") : Color(hex: "#9AA0AB"))
                        Text(isValid ? validMessage : invalidMessage)
                            .font(ABFont.body(12, weight: .medium))
                            .foregroundStyle(isValid ? Color(hex: "#A8F0C6").opacity(0.9) : Color(hex: "#9AA0AB"))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
        } bottom: {
            GlowCTAButton(title: "Devam Et", isEnabled: isValid, action: onContinue)
        }
        .onAppear { isFieldFocused = true }
    }
}

struct SignupPasswordStepView: View {
    @Binding var password: String
    var errorMessage: String?
    var isSubmitting: Bool
    var onBack: () -> Void
    var onHome: () -> Void
    var onContinue: () -> Void
    @FocusState private var isPasswordFieldFocused: Bool

    private let gold = Color(hex: "#C8A56E")

    var body: some View {
        SignupShell(
            icon: "lock.shield",
            title: "Şifre Belirle",
            subtitle: "Güçlü ama hatırlaması kolay bir şifre seç.",
            progressCurrent: 2,
            progressTotal: 2,
            onBack: onBack,
            onHome: onHome
        ) {
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(gold.opacity(0.7))

                    SecureField("Parola", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textContentType(.newPassword)
                        .font(ABFont.body(17, weight: .medium))
                        .foregroundStyle(ABColor.ink)
                        .focused($isPasswordFieldFocused)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 18)
                .glowInputSurface()
                .contentShape(Capsule())
                .onTapGesture { isPasswordFieldFocused = true }

                HStack {
                    Text("Büyük harf ve rakam eklemek güvenliği artırır.")
                        .font(ABFont.body(11.5))
                        .foregroundStyle(ABColor.ink.opacity(0.55))
                    Spacer()
                }
                .padding(.horizontal, 4)

                if !password.isEmpty {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            ForEach(0..<4, id: \.self) { i in
                                Capsule()
                                    .fill(i < passwordStrength ? strengthColor : ABColor.veil.opacity(0.10))
                                    .frame(height: 4)
                            }
                        }
                        HStack {
                            Text(strengthLabel)
                                .font(ABFont.body(11.5, weight: .medium))
                                .foregroundStyle(strengthColor)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 4)
                }

                if let errorMessage, !errorMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "#E0A0A0"))
                        Text(errorMessage)
                            .font(ABFont.body(12, weight: .medium))
                            .foregroundStyle(Color(hex: "#E0A0A0"))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
        } bottom: {
            GlowCTAButton(
                title: isSubmitting ? "Hesap oluşturuluyor..." : "Devam Et",
                isEnabled: password.count >= 6 && !isSubmitting,
                showSparkle: false,
                action: onContinue
            )
        }
        .onAppear { isPasswordFieldFocused = true }
    }

    private var passwordStrength: Int {
        var score = 0
        if password.count >= 6 { score += 1 }
        if password.count >= 8 { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        return score
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0...1: return Color(hex: "#B07A7A")
        case 2: return gold
        case 3: return Color(hex: "#E4D2A8")
        default: return Color(hex: "#A8F0C6")
        }
    }

    private var strengthLabel: String {
        switch passwordStrength {
        case 0...1: return "Zayıf"
        case 2: return "Orta"
        case 3: return "İyi"
        default: return "Güçlü"
        }
    }
}
