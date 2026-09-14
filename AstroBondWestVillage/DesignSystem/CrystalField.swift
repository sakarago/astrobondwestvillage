import SwiftUI

struct CrystalField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ABFont.label(12))
                .foregroundStyle(ABColor.inkMuted)

            Group {
                if isSecure {
                    SecureField("", text: $text)
                        .textContentType(contentType ?? .password)
                } else {
                    TextField("", text: $text)
                        .textContentType(contentType)
                        .keyboardType(keyboard)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(ABFont.body(16))
            .foregroundStyle(ABColor.ink)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                Capsule(style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.45),
                                ABColor.lavenderSoft.opacity(0.25),
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}
