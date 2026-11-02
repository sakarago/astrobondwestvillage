import SwiftUI

struct DiscoverHomeView: View {
    @State private var page = 0

    private let pages: [DiscoverPage] = [
        .init(
            eyebrow: "BUGÜN",
            title: "Çark seni bekliyor",
            body: "Günlük hakkınla yeni bir bağ aç. Geç veya kabul et — kararın Mesajlar’a akar.",
            icon: "heart.circle"
        ),
        .init(
            eyebrow: "BAĞ",
            title: "Niyetini seç",
            body: "Romantik, ilişki, iş veya arkadaş. Eşleşme tercihleri çarkın altından ayarlanır.",
            icon: "slider.horizontal.3"
        ),
        .init(
            eyebrow: "SOHBET",
            title: "Fotoğraf kapısı",
            body: "Gerçek profil fotoğrafı \(PhotoGate.unlockAfterMessageCount) mesaj sonra açılır. Önce bağ, sonra yüz.",
            icon: "lock.open"
        ),
        .init(
            eyebrow: "HARİTA",
            title: "Güneş, Ay, Yükselen",
            body: "Profilinde Güneş, Ay, Yükselen ve ayrıntılı doğum haritan seni bekler.",
            icon: "sparkles"
        ),
        .init(
            eyebrow: "GÜVEN",
            title: "Kontrol sende",
            body: "Ayarlardan profil düzenle, bildirimleri yönet, hesabı dondur veya sil.",
            icon: "shield"
        ),
        .init(
            eyebrow: "RİTİM",
            title: "Az ama anlamlı",
            body: "Günde birkaç eşleşme. Spam yok — bilinçli seçim var.",
            icon: "moon.stars"
        ),
        .init(
            eyebrow: "YENİ YÜZ",
            title: "Yeni yüzey",
            body: "Kristal cam, kozmik derinlik, aynı ürün ruhu. Eski arayüz değil — yeni bir gövde.",
            icon: "building.columns"
        )
    ]

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                HStack {
                    Text("Keşfet")
                        .font(ABFont.display(30))
                        .foregroundStyle(ABColor.ink)
                    Spacer()
                    Text("\(page + 1)/\(pages.count)")
                        .font(ABFont.body(13, weight: .semibold))
                        .foregroundStyle(ABColor.inkMuted)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        DiscoverCard(page: item)
                            .padding(.horizontal, 20)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .padding(.bottom, 100)
            }
        }
    }
}

private struct DiscoverPage: Identifiable {
    let id = UUID()
    let eyebrow: String
    let title: String
    let body: String
    let icon: String
}

private struct DiscoverCard: View {
    let page: DiscoverPage

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: page.icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft)
                Spacer()
                Text("ASTROBOND")
                    .font(ABFont.body(11, weight: .bold))
                    .tracking(1.6)
                    .foregroundStyle(ABColor.inkMuted)
            }

            Text(page.eyebrow)
                .font(ABFont.body(12, weight: .bold))
                .tracking(1.4)
                .foregroundStyle(ABColor.lavenderSoft)

            Text(page.title)
                .font(ABFont.display(28))
                .foregroundStyle(ABColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.8)

            Text(page.body)
                .font(ABFont.body(16))
                .foregroundStyle(ABColor.inkMuted)
                .lineSpacing(5)

            Spacer()

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            ABColor.lavender.opacity(0.35),
                            Color(hex: "#2A2038").opacity(0.5),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 140)
                .overlay {
                    Image(systemName: "sparkle")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .crystalPlate(cornerRadius: 28)
        .padding(.vertical, 24)
    }
}
