import SwiftUI

struct ProfileHomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var snapshot: ProfileSnapshot?
    @State private var error: String?
    @State private var chartMode: ChartMode = .circle

    private let profiles = ProfileService()

    private enum ChartMode: String, CaseIterable {
        case circle = "Çember"
        case table = "Tablo"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                ScrollView {
                    VStack(spacing: 20) {
                        HStack {
                            Text("Profil")
                                .font(ABFont.display(30))
                                .foregroundStyle(ABColor.ink)
                            Spacer()
                            NavigationLink {
                                SettingsView()
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(ABColor.ink)
                                    .frame(width: 42, height: 42)
                                    .crystalPlate(cornerRadius: 14)
                            }
                            .buttonStyle(.plain)
                        }

                        if let snapshot {
                            profileCard(snapshot)
                            bigThree(snapshot)
                            chartSection(snapshot)
                        } else if error == nil {
                            ProgressView().tint(ABColor.lavenderSoft)
                        }

                        if let error {
                            Text(error)
                                .font(ABFont.body(13))
                                .foregroundStyle(Color(hex: "#C69A9A"))
                        }

                        CrystalCTAButton(title: "Çıkış Yap") {
                            Task { await session.signOut() }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 130)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await load() }
        }
    }

    private func load() async {
        guard let id = session.user?.id else { return }
        do {
            snapshot = try await profiles.fetchSnapshot(userId: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func profileCard(_ snap: ProfileSnapshot) -> some View {
        VStack(spacing: 12) {
            PersonAvatar(
                name: snap.displayName,
                photoURL: snap.photoURL,
                sunSign: snap.sunSign,
                unlocked: true,
                size: 84
            )
            Text(snap.displayName.isEmpty ? "İsimsiz" : snap.displayName)
                .font(ABFont.display(24))
                .foregroundStyle(ABColor.ink)
            if let email = session.user?.email {
                Text(email)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
            }
            HStack(spacing: 12) {
                Text("\(snap.age)")
                Text(snap.gender.labelTR)
                if let place = snap.placeLabel {
                    Text(place)
                }
            }
            .font(ABFont.body(13, weight: .medium))
            .foregroundStyle(ABColor.inkMuted)

            if !snap.bio.isEmpty {
                Text(snap.bio)
                    .font(ABFont.body(14))
                    .foregroundStyle(ABColor.ink.opacity(0.85))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .crystalPlate(cornerRadius: 28)
    }

    private func bigThree(_ snap: ProfileSnapshot) -> some View {
        HStack(spacing: 10) {
            planetPill("☉ Güneş", snap.sunSign)
            planetPill("☽ Ay", snap.moonSign ?? snap.sunSign)
            planetPill("↑ Yükselen", snap.risingSign ?? snap.sunSign)
        }
    }

    private func planetPill(_ title: String, _ sign: ZodiacSign?) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(ABFont.body(11, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted)
            Text(sign.map { "\($0.glyph) \($0.labelTR)" } ?? "—")
                .font(ABFont.body(13, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .crystalPlate(cornerRadius: 18)
    }

    private func chartSection(_ snap: ProfileSnapshot) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("Doğum Haritan")
                    .font(ABFont.display(20))
                    .foregroundStyle(ABColor.ink)
                Spacer()
                Picker("", selection: $chartMode) {
                    ForEach(ChartMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            Text("V1 yaklaşık burç motoru. Detaylı ev/gezegen tablosu ephemeris ile genişleyecek.")
                .font(ABFont.body(12))
                .foregroundStyle(ABColor.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            if chartMode == .circle {
                CosmicMatchWheel(
                    rotation: 8,
                    isSpinning: false,
                    size: 268,
                    showsPointer: false,
                    interactive: false,
                    mySeed: snap.userId
                )
            } else {
                chartTable(snap)
            }

            if let sun = snap.sunSign {
                Text(sunBlurb(sun))
                    .font(ABFont.body(14))
                    .foregroundStyle(ABColor.ink.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(18)
        .crystalPlate(cornerRadius: 28)
    }

    private func chartTable(_ snap: ProfileSnapshot) -> some View {
        VStack(spacing: 0) {
            tableRow("Güneş", snap.sunSign)
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            tableRow("Ay", snap.moonSign ?? snap.sunSign)
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            tableRow("Yükselen", snap.risingSign ?? snap.sunSign)
            Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
            ForEach(Array(ZodiacSign.allCases.enumerated()), id: \.offset) { i, sign in
                if i < 4 {
                    tableRow("Ev \(i + 1)", sign == snap.sunSign ? snap.sunSign : nil, placeholder: elementHint(i))
                    if i < 3 {
                        Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func tableRow(_ label: String, _ sign: ZodiacSign?, placeholder: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(ABFont.body(14, weight: .medium))
                .foregroundStyle(ABColor.inkMuted)
            Spacer()
            if let sign {
                Text("\(sign.glyph)  \(sign.labelTR)")
                    .font(ABFont.body(14, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
            } else if let placeholder {
                Text(placeholder)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted.opacity(0.8))
            } else {
                Text("—")
                    .foregroundStyle(ABColor.inkMuted)
            }
        }
        .padding(.vertical, 12)
    }

    private func elementHint(_ i: Int) -> String {
        ["Ateş vurgusu", "Toprak zemini", "Hava diyaloğu", "Su derinliği"][i]
    }

    private func sunBlurb(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Koç güneşi: doğrudan enerji, cesaret ve ilk adım."
        case .taurus: return "Boğa güneşi: istikrar, duyusal bağ ve sabır."
        case .gemini: return "İkizler güneşi: merak, sohbet ve çift yönlü zihin."
        case .cancer: return "Yengeç güneşi: koruma, sezgi ve duygusal yuva."
        case .leo: return "Aslan güneşi: yaratıcılık, görünürlük ve cömert kalp."
        case .virgo: return "Başak güneşi: incelik, hizmet ve pratik zeka."
        case .libra: return "Terazi güneşi: denge, ilişki ve estetik uyum."
        case .scorpio: return "Akrep güneşi: derinlik, dönüşüm ve yoğun bağ."
        case .sagittarius: return "Yay güneşi: keşif, anlam ve geniş ufuk."
        case .capricorn: return "Oğlak güneşi: yapı, disiplin ve uzun vadeli hedef."
        case .aquarius: return "Kova güneşi: özgünlük, topluluk ve gelecek vizyonu."
        case .pisces: return "Balık güneşi: empati, hayal ve sınır ötesi bağ."
        }
    }
}
