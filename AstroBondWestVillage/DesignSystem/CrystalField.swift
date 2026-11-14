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
                        .textFieldStyle(.plain)
                }
            }
            .font(ABFont.body(16))
            .foregroundStyle(ABColor.ink)
            .frame(minHeight: 22)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white.opacity(0.04))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                ABColor.rim.opacity(0.45),
                                ABColor.lavenderSoft.opacity(0.25),
                                ABColor.rim.opacity(0.08)
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
