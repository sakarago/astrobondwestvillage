import SwiftUI

struct ProfileHomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var snapshot: ProfileSnapshot?
    @State private var natalChart: NatalChart?
    @State private var error: String?
    @State private var chartMode: ChartMode = .circle

    private let profiles = ProfileService()

    private enum ChartMode: String, CaseIterable {
        case circle = "Çember"
        case table = "Doğum Haritan"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Profil")
                            .font(ABFont.display(24))
                            .foregroundStyle(ABColor.ink)
                        Spacer()
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(ABColor.ink)
                                .crystalIconBezel(size: 36, cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 10)

                    if let snapshot {
                        VStack(spacing: 8) {
                            profileCard(snapshot)
                            bigThree(snapshot)
                        }
                        .padding(.top, 22)

                        VStack(spacing: 10) {
                            chartModeSwitcher

                            if chartMode == .circle {
                                GeometryReader { geo in
                                    let side = min(geo.size.width, geo.size.height)
                                    Group {
                                        if let natalChart {
                                            ChartWheelView(chart: natalChart)
                                        } else {
                                            CosmicMatchWheel(
                                                rotation: 8,
                                                isSpinning: false,
                                                size: side,
                                                showsPointer: false,
                                                interactive: false,
                                                mySeed: snapshot.userId,
                                                mySun: snapshot.sunSign,
                                                myMoon: snapshot.moonSign,
                                                myRising: snapshot.risingSign,
                                                myChart: natalChart
                                            )
                                        }
                                    }
                                    .frame(width: side, height: side)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                ScrollView(showsIndicators: false) {
                                    VStack(spacing: 14) {
                                        if let natalChart {
                                            natalTable(natalChart)
                                        } else {
                                            chartTable(snapshot)
                                        }
                                        chartBlurbs(snapshot)
                                    }
                                    .padding(.bottom, 24)
                                }
                            }
                        }
                        .padding(.top, 18)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    } else if error == nil {
                        ProgressView().tint(ABColor.lavenderSoft)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    if let error {
                        Text(error)
                            .font(ABFont.body(13))
                            .foregroundStyle(Color(hex: "#C69A9A"))
                            .padding(.top, 12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 96)
            }
            .toolbar(.hidden, for: .navigationBar)
            .task { await load() }
        }
    }

    private func load() async {
        guard let id = session.user?.id else { return }
        do {
            snapshot = try await profiles.fetchSnapshot(userId: id)
            natalChart = try await ChartService.shared.ensureOwnChart(userId: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private var chartModeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(ChartMode.allCases, id: \.self) { mode in
                Button {
                    chartMode = mode
                } label: {
                    Text(mode.rawValue)
                        .font(ABFont.body(13, weight: .semibold))
                        .foregroundStyle(
                            chartMode == mode
                                ? Color(hex: "#15131F")
                                : ABColor.ink.opacity(0.82)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if chartMode == mode {
                                Capsule(style: .continuous)
                                    .fill(Color.white.opacity(0.92))
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.18))
        }
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.28), lineWidth: 1)
        )
    }

    private func profileCard(_ snap: ProfileSnapshot) -> some View {
        HStack(spacing: 12) {
            PersonAvatar(
                name: snap.displayName,
                photoURL: snap.photoURL,
                sunSign: snap.sunSign,
                unlocked: true,
                size: 48
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(snap.displayName.isEmpty ? "İsimsiz" : snap.displayName)
                    .font(ABFont.display(18))
                    .foregroundStyle(ABColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if let email = session.user?.email {
                    Text(email)
                        .font(ABFont.body(12))
                        .foregroundStyle(ABColor.inkMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                HStack(spacing: 6) {
                    Text("\(snap.age)")
                    Text(snap.gender.labelTR)
                    if let place = snap.placeLabel {
                        Text(place)
                    }
                }
                .font(ABFont.body(11, weight: .medium))
                .foregroundStyle(ABColor.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .crystalPlate(cornerRadius: 18)
    }

    private func bigThree(_ snap: ProfileSnapshot) -> some View {
        HStack(spacing: 10) {
            planetPill("☉ Güneş", snap.sunSign)
            planetPill("☽ Ay", snap.moonSign ?? snap.sunSign)
            planetPill("↑ Yükselen", snap.risingSign ?? snap.sunSign)
        }
    }

    private func planetPill(_ title: String, _ sign: ZodiacSign?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(ABFont.body(10, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted)
            Text(sign.map { "\($0.glyph) \($0.labelTR)" } ?? "—")
                .font(ABFont.body(12, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .crystalPlate(cornerRadius: 14)
    }

    private func chartBlurbs(_ snap: ProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let sun = snap.sunSign {
                Text(sunBlurb(sun))
                    .font(ABFont.body(14))
                    .foregroundStyle(ABColor.ink.opacity(0.9))
                Text("Element \(sun.element.labelTR.lowercased()) · Nitelik \(sun.modality.labelTR.lowercased()) · Yönetici \(sun.rulerTR)")
                    .font(ABFont.body(12, weight: .medium))
                    .foregroundStyle(ABColor.lavenderSoft)
            }
            if let moon = snap.moonSign {
                Text(placementBlurb(moon, title: "Ay"))
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
            }
            if let rising = snap.risingSign {
                Text(placementBlurb(rising, title: "Yükselen"))
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .crystalPlate(cornerRadius: 20)
    }

    private func natalTable(_ chart: NatalChart) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(chart.planets.enumerated()), id: \.element.planet) { idx, pos in
                tableRow(pos.planet.name, pos.sign, placeholder: pos.formatted)
                if idx < chart.planets.count - 1 { divider }
            }
            divider
            tableRow("Yükselen", chart.risingSign)
            divider
            tableRow("MC", chart.midheaven.sign)
            divider
            tableRow("Element · Nitelik", nil, placeholder: "\(chart.dominantElement.labelTR) · \(chart.dominantModality.labelTR)")
            divider
            Text("12 EV")
                .font(ABFont.body(10, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(ABColor.inkMuted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 12)
                .padding(.bottom, 2)
            ForEach(chart.houses, id: \.number) { house in
                tableRow("Ev \(house.number)", house.sign)
                if house.number < 12 { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }
            }
        }
        .padding(.vertical, 4)
    }

    private func chartTable(_ snap: ProfileSnapshot) -> some View {
        let ascendant = snap.risingSign ?? snap.sunSign
        return VStack(spacing: 0) {
            tableRow("Güneş", snap.sunSign)
            divider
            tableRow("Ay", snap.moonSign ?? snap.sunSign)
            divider
            tableRow("Yükselen", snap.risingSign ?? snap.sunSign)
            if let sun = snap.sunSign {
                divider
                tableRow("Element · Nitelik", nil, placeholder: "\(sun.element.labelTR) · \(sun.modality.labelTR)")
                divider
                tableRow("Yönetici gezegen", nil, placeholder: sun.rulerTR)
            }
            if let ascendant {
                divider
                Text("12 EV · YÜKSELEN'E GÖRE")
                    .font(ABFont.body(10, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(ABColor.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
                    .padding(.bottom, 2)
                ForEach(1...12, id: \.self) { house in
                    tableRow("Ev \(house)", ZodiacSign.houseSign(house, ascendant: ascendant))
                    if house < 12 { Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1) }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
    }

    /// Generic (works for any sign, no per-sign copywriting needed) blurb for
    /// Moon/Rising built straight from element + modality — real synthesis,
    /// not just a label restated.
    private func placementBlurb(_ sign: ZodiacSign, title: String) -> String {
        "\(title) \(sign.glyph) \(sign.labelTR): \(sign.element.labelTR) elementi (\(sign.element.blurbTR)) + \(sign.modality.labelTR.lowercased()) nitelik (\(sign.modality.blurbTR))."
    }

    private func tableRow(_ label: String, _ sign: ZodiacSign?, placeholder: String? = nil) -> some View {
        HStack {
            Text(label)
                .font(ABFont.body(14, weight: .medium))
                .foregroundStyle(ABColor.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            if let sign {
                Text("\(sign.glyph)  \(sign.labelTR)")
                    .font(ABFont.body(14, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            } else if let placeholder {
                Text(placeholder)
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .multilineTextAlignment(.trailing)
            } else {
                Text("—")
                    .foregroundStyle(ABColor.inkMuted)
            }
        }
        .padding(.vertical, 12)
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
