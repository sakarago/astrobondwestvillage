import SwiftUI

struct PersonAvatar: View {
    var name: String
    var photoURL: String?
    var sunSign: ZodiacSign?
    var unlocked: Bool
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [ABColor.lavender.opacity(0.45), Color(hex: "#2A2438")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if unlocked, let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        initials
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                initials
            }
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.55), ABColor.lavenderSoft.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
        )
    }

    private var initials: some View {
        Group {
            if let sunSign {
                Text(sunSign.glyph)
                    .font(.system(size: size * 0.38))
                    .foregroundStyle(.white.opacity(0.9))
            } else {
                Text(String(name.prefix(1)).uppercased())
                    .font(ABFont.body(size * 0.36, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}
