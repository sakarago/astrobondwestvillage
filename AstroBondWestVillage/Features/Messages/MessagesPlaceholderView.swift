import SwiftUI

struct MessagesPlaceholderView: View {
    var body: some View {
        VStack(spacing: 18) {
            Text("Mesajlar")
                .font(ABFont.display(28))
                .foregroundStyle(ABColor.ink)
            Text("West Village — yeni UI iskeleti")
                .font(ABFont.body(14))
                .foregroundStyle(ABColor.inkMuted)
            CrystalCTAButton(title: "Devam") {}
                .padding(.horizontal, 28)
                .padding(.top, 8)
        }
        .padding(24)
        .crystalPlate(cornerRadius: 28)
        .padding(.horizontal, 28)
    }
}
