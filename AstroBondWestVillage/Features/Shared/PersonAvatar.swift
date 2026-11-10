import SwiftUI

struct PersonAvatar: View {
    var name: String
    var photoURL: String?
    var cartoonAvatarId: String? = nil
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

            Group {
                if unlocked, let photoURL, let url = URL(string: photoURL), !photoURL.isEmpty {
                    // Small avatars use the 256px thumbnail when one exists; legacy URLs fall back to the full image.
                    let thumb = size <= 120 ? ProfilePhotoService.thumbURL(for: url) : nil
                    CachedAsyncImage(primary: thumb ?? url, fallback: thumb == nil ? nil : url) {
                        fallbackFace
                    }
                } else {
                    fallbackFace
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        }
        .frame(width: size, height: size)
        .overlay(
            Circle().strokeBorder(
                LinearGradient(
                    colors: [ABColor.veil.opacity(0.55), ABColor.lavenderSoft.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1.2
            )
        )
    }

    @ViewBuilder
    private var fallbackFace: some View {
        if let cartoon = CartoonAvatar.from(id: cartoonAvatarId) {
            CartoonAvatarView(avatar: cartoon, size: size)
        } else {
            initials
        }
    }

    private var initials: some View {
        Group {
            if let sunSign {
                Text(sunSign.glyph)
                    .font(.system(size: size * 0.38))
                    .foregroundStyle(ABColor.ink.opacity(0.9))
            } else {
                Text(String(name.prefix(1)).uppercased())
                    .font(ABFont.body(size * 0.36, weight: .semibold))
                    .foregroundStyle(ABColor.ink.opacity(0.9))
            }
        }
    }
}
