import SwiftUI
import PhotosUI

private enum ChartPresentationMode: String, CaseIterable {
    case table = "TABLO"
    case circle = "ÇEMBER"
}

struct ProfileHomeView: View {
    @Environment(SessionStore.self) private var session
    @State private var snapshot: ProfileSnapshot?
    @State private var natalChart: NatalChart?
    @State private var error: String?
    @State private var isLoading = true
    @State private var chartMode: ChartPresentationMode = .circle
    @State private var selectedPlanet: PlanetPosition?
    @State private var showPlanetDetail = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var expandedHouse: Int?
    @State private var expandedPlanet: Planet?
    @State private var expandedAspect: Int?

    private let profiles = ProfileService()
    private let lavender = Color(hex: "#9C8CFF")

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()

                if isLoading && snapshot == nil && natalChart == nil {
                    loadingView
                } else if let chart = natalChart {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            profileHeader(chart: chart)
                            chartSection(chart: chart)
                            cosmicProfileSection(chart: chart)
                            housesSection(chart: chart)
                            aspectsSection(chart: chart)
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                    }
                } else if let snapshot {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 30) {
                            snapshotHeader(snapshot)
                            fallbackChartSection(snapshot)
                        }
                        .padding(.top, 18)
                        .padding(.bottom, 120)
                    }
                } else {
                    emptyStateView
                }

                if natalChart == nil, snapshot == nil {
                    VStack {
                        HStack {
                            Spacer()
                            settingsButton
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task { await load() }
        .sheet(isPresented: $showPlanetDetail) {
            if let planet = selectedPlanet {
                ProfilePlanetDetailSheet(planet: planet)
                    .presentationDetents([.medium, .large])
            }
        }
        .task(id: selectedPhotoItem) {
            guard let selectedPhotoItem else { return }
            selectedPhotoData = try? await selectedPhotoItem.loadTransferable(type: Data.self)
        }
    }

    private func load() async {
        guard let id = session.user?.id else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            snapshot = try await profiles.fetchSnapshot(userId: id)
            natalChart = try await ChartService.shared.ensureOwnChart(userId: id)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .tint(Color(hex: "#CDD2DB"))
                .scaleEffect(1.4)
            Text("Haritan yükleniyor...")
                .font(ABFont.body(16))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 18) {
            Text("✦")
                .font(.system(size: 60))
                .foregroundStyle(Color(hex: "#CDD2DB"))
            Text("Henüz bir doğum haritan yok")
                .font(ABFont.display(22, weight: .regular))
                .foregroundStyle(.white)
            Text("Doğum bilgilerini girerek profilini tamamla.")
                .font(ABFont.body(16))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            if let error {
                Text(error)
                    .font(ABFont.body(12))
                    .foregroundStyle(Color(hex: "#C69A9A"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            Button {
                Task { await load() }
            } label: {
                Text("Yeniden Dene")
                    .font(ABFont.body(15, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
    }

    private var settingsButton: some View {
        NavigationLink {
            SettingsView()
        } label: {
            Image(systemName: "gearshape")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
        }
        .buttonStyle(.plain)
    }

    // MARK: Header

    private func profileHeader(chart: NatalChart) -> some View {
        HStack(alignment: .center, spacing: 14) {
            profileAvatar(sign: chart.sunSign)
            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(ABFont.display(22, weight: .regular))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.white, Color(hex: "#D9DCE6")],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                HStack(spacing: 8) {
                    bigThreeChip("☉", chart.sunSign.labelTR)
                    bigThreeChip("☽", chart.moonSign.labelTR)
                    bigThreeChip("↑", chart.risingSign.labelTR)
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
            settingsButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
    }

    private func snapshotHeader(_ snap: ProfileSnapshot) -> some View {
        HStack(alignment: .center, spacing: 14) {
            profileAvatar(sign: snap.sunSign ?? .aries)
            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(ABFont.display(22, weight: .regular))
                    .foregroundStyle(.white)
                HStack(spacing: 8) {
                    bigThreeChip("☉", snap.sunSign?.labelTR ?? "—")
                    bigThreeChip("☽", snap.moonSign?.labelTR ?? "—")
                    bigThreeChip("↑", snap.risingSign?.labelTR ?? "—")
                }
                .padding(.top, 4)
            }
            Spacer(minLength: 0)
            settingsButton
        }
        .padding(.horizontal, 28)
        .padding(.top, 30)
    }

    private var displayName: String {
        let name = snapshot?.displayName.trimmingCharacters(in: .whitespaces) ?? ""
        return name.isEmpty ? "İsimsiz" : name
    }

    private func bigThreeChip(_ symbol: String, _ name: String) -> some View {
        HStack(spacing: 3) {
            Text(symbol)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#CDD2DB"))
            Text(name)
                .font(ABFont.body(11, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.07)))
        .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 0.6))
    }

    private func profileAvatar(sign: ZodiacSign) -> some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let selectedPhotoData, let uiImage = UIImage(data: selectedPhotoData) {
                    Image(uiImage: uiImage).resizable().scaledToFill()
                } else {
                    PersonAvatar(
                        name: displayName,
                        photoURL: snapshot?.photoURL,
                        cartoonAvatarId: snapshot?.cartoonAvatarId,
                        sunSign: sign,
                        unlocked: true,
                        size: 60
                    )
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.85), lavender.opacity(0.55)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
            )
            .shadow(color: lavender.opacity(0.35), radius: 12, y: 5)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "plus")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(Color(hex: "#16161A"))
                    .padding(5)
                    .background(Color(hex: "#E4E8EF"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .offset(x: -1, y: -1)
        }
    }

    // MARK: Chart

    private func sectionHeader(_ overline: String, _ title: String, _ subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text("✦")
                    .font(.system(size: 9))
                    .foregroundStyle(lavender)
                Text(overline)
                    .font(ABFont.body(10.5, weight: .semibold))
                    .tracking(2.6)
                    .padding(.leading, 4)
                    .foregroundStyle(Color(hex: "#B7BDC7"))
                    .fixedSize(horizontal: true, vertical: false)
            }
            Text(title)
                .font(ABFont.display(24, weight: .regular))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color(hex: "#D2D7DF").opacity(0.8)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
            if let subtitle {
                Text(subtitle)
                    .font(ABFont.body(12.5))
                    .foregroundStyle(Color.white.opacity(0.45))
            }
        }
        .padding(.horizontal, 28)
    }

    private func chartSection(chart: NatalChart) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("GÖKYÜZÜ HARİTAN", "Doğum Haritası")
            chartModePicker
            if chartMode == .circle {
                ChartWheelView(chart: chart, onPlanetTap: { planet in
                    selectedPlanet = planet
                    showPlanetDetail = true
                })
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding(10)
                .background(Color.black.opacity(0.28))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            } else {
                tableChartCard(chart: chart)
            }
        }
    }

    private func fallbackChartSection(_ snap: ProfileSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("GÖKYÜZÜ HARİTAN", "Doğum Haritası")
            VStack(spacing: 12) {
                ProgressView()
                    .tint(Color(hex: "#CDD2DB"))
                Text("Haritan hesaplanıyor…")
                    .font(ABFont.body(13))
                    .foregroundStyle(Color.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                if let error {
                    Text(error)
                        .font(ABFont.body(12))
                        .foregroundStyle(Color(hex: "#C69A9A"))
                        .multilineTextAlignment(.center)
                    Button {
                        Task { await load() }
                    } label: {
                        Text("Yeniden Dene")
                            .font(ABFont.body(14, weight: .medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .padding(.horizontal, 20)
        }
    }

    private var chartModePicker: some View {
        HStack(spacing: 18) {
            ForEach(ChartPresentationMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { chartMode = mode }
                } label: {
                    VStack(spacing: 8) {
                        Text(mode.rawValue)
                            .font(ABFont.body(12, weight: .semibold))
                            .foregroundStyle(chartMode == mode ? .white : Color.white.opacity(0.4))
                            .fixedSize(horizontal: true, vertical: false)
                        Rectangle()
                            .fill(chartMode == mode ? lavender : Color.clear)
                            .frame(width: 44, height: 2)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func tableChartCard(chart: NatalChart) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(chart.planets.enumerated()), id: \.element.planet) { index, planet in
                Button {
                    selectedPlanet = planet
                    showPlanetDetail = true
                } label: {
                    HStack(spacing: 12) {
                        Text(planet.planet.glyph)
                            .font(.system(size: 18))
                            .foregroundStyle(planetTint(planet.planet))
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(planet.planet.name)
                                .font(ABFont.body(15, weight: .medium))
                                .foregroundStyle(.white)
                            Text("\(planet.sign.labelTR) • \(planet.house). Ev")
                                .font(ABFont.body(12))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        Spacer()
                        Text(degreeText(planet))
                            .font(ABFont.body(13, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                if index < chart.planets.count - 1 {
                    Divider().background(Color.white.opacity(0.08))
                }
            }
        }
        .padding(.horizontal, 28)
        .profileGlowBubble(cornerRadius: 28, tint: lavender)
        .padding(.horizontal, 28)
    }

    // MARK: Astral profile

    private func cosmicProfileSection(chart: NatalChart) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("RUHSAL İMZAN", "Astral Profil", "Bir gezegene dokun, yıldızların yorumunu oku")
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    elementPill("Element", chart.dominantElement.labelTR, elementColor(chart.dominantElement))
                    elementPill("Modalite", chart.dominantModality.labelTR, Color(hex: "#C9CFD9"))
                }
                ForEach(Array(chart.planets.prefix(7)), id: \.planet) { planet in
                    planetReadingRow(planet)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func elementPill(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 8, height: 8)
            VStack(alignment: .leading, spacing: 1) {
                Text(label.uppercased())
                    .font(ABFont.body(9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(Color.white.opacity(0.45))
                Text(value)
                    .font(ABFont.body(14, weight: .medium))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .profileGlowBubble(cornerRadius: 18, tint: color)
    }

    private func planetReadingRow(_ planet: PlanetPosition) -> some View {
        let tint = planetTint(planet.planet)
        let isOpen = expandedPlanet == planet.planet
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    expandedPlanet = isOpen ? nil : planet.planet
                }
            } label: {
                HStack(spacing: 12) {
                    Text(planet.planet.glyph)
                        .font(.system(size: 20))
                        .foregroundStyle(tint)
                        .frame(width: 30)
                        .shadow(color: tint.opacity(0.5), radius: 5)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(planet.planet.name) \(planet.sign.labelTR)")
                            .font(ABFont.body(15, weight: .medium))
                            .foregroundStyle(.white)
                        Text("\(planet.house). Ev\(planet.isRetrograde ? " • Retro ℞" : "")")
                            .font(ABFont.body(12))
                            .foregroundStyle(Color.white.opacity(0.45))
                    }
                    Spacer()
                    Text(degreeText(planet))
                        .font(ABFont.body(13, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.35))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 6) {
                    Rectangle().fill(tint.opacity(0.3)).frame(height: 0.8).padding(.bottom, 2)
                    Text(AstralReadings.planet(planet.planet, planet.sign))
                        .font(ABFont.body(13.5))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineSpacing(4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .profileGlowBubble(cornerRadius: 20, tint: tint)
    }

    // MARK: Houses

    private func housesSection(chart: NatalChart) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("YAŞAM ALANLARIN", "Evler", "Bir eve dokun, detaylı yorumu gör")
            VStack(spacing: 10) {
                ForEach(chart.houses, id: \.number) { house in
                    houseRow(house)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func houseRow(_ house: HouseEntity) -> some View {
        let tint = elementColor(house.sign.element)
        let isOpen = expandedHouse == house.number
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    expandedHouse = isOpen ? nil : house.number
                }
            } label: {
                HStack(spacing: 12) {
                    Text(house.romanNumeral)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: "#CDD2DB"))
                        .frame(width: 34, alignment: .center)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(house.sign.lineGlyph)
                                .font(.system(size: 13))
                                .foregroundStyle(tint)
                            Text(house.sign.labelTR)
                                .font(ABFont.body(14, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        Text(house.theme)
                            .font(ABFont.body(11.5))
                            .foregroundStyle(Color.white.opacity(0.5))
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.3))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle().fill(tint.opacity(0.3)).frame(height: 0.8)
                    Text("\(house.sign.labelTR), \(house.number). evinde")
                        .font(ABFont.body(14, weight: .semibold))
                        .foregroundStyle(Color(hex: "#CDD2DB"))
                    Text(AstralReadings.house(house: house.number, sign: house.sign))
                        .font(ABFont.body(13.5))
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineSpacing(4)
                    if !house.planets.isEmpty {
                        Divider().background(Color.white.opacity(0.08))
                        Text("Bu evdeki gezegenler")
                            .font(ABFont.body(12))
                            .foregroundStyle(Color.white.opacity(0.4))
                        HStack(spacing: 12) {
                            ForEach(house.planets, id: \.self) { planet in
                                HStack(spacing: 5) {
                                    Text(planet.glyph)
                                        .font(.system(size: 15))
                                        .foregroundStyle(planetTint(planet))
                                    Text(planet.name)
                                        .font(ABFont.body(12.5, weight: .medium))
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .padding(.top, 2)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .profileGlowBubble(cornerRadius: 20, tint: tint)
    }

    // MARK: Aspects

    private func aspectsSection(chart: NatalChart) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("GEZEGEN AÇILARI", "Açılar", "Bir karta dokun, yorum okunaklı hale gelsin")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(chart.aspects.prefix(6).enumerated()), id: \.offset) { index, aspect in
                        aspectCard(aspect, index: index)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 4)
            }
        }
    }

    private func aspectCard(_ aspect: AspectEntity, index: Int) -> some View {
        let harmonious = aspect.type.isHarmonious
        let tint = harmonious ? Color(hex: "#9C8CFF") : Color(hex: "#C6A0A0")
        let isOpen = expandedAspect == index
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(harmonious ? "Uyumlu Açı" : "Dinamik Açı")
                    .font(ABFont.body(11, weight: .semibold))
                    .tracking(0.8)
                    .foregroundStyle(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(tint.opacity(0.16))
                    .clipShape(Capsule())
                Spacer()
                Text(aspect.isExact ? "Tam" : String(format: "%.1f°", aspect.orb))
                    .font(ABFont.body(12))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            HStack(spacing: 10) {
                Text(aspect.planet1.glyph).foregroundStyle(planetTint(aspect.planet1))
                Text(aspect.type.glyph).foregroundStyle(tint)
                Text(aspect.planet2.glyph).foregroundStyle(planetTint(aspect.planet2))
                Text("\(aspect.planet1.name) – \(aspect.planet2.name)")
                    .font(ABFont.body(14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .font(.system(size: 18))
            Text(aspect.type.rawValue)
                .font(ABFont.body(12, weight: .semibold))
                .foregroundStyle(Color(hex: "#CDD2DB"))
            Text(AstralReadings.aspect(aspect))
                .font(ABFont.body(13))
                .foregroundStyle(Color.white.opacity(isOpen ? 0.82 : 0.55))
                .lineSpacing(4)
                .lineLimit(isOpen ? nil : 2)
            if !isOpen {
                Text("Devamını oku")
                    .font(ABFont.body(11, weight: .semibold))
                    .foregroundStyle(tint)
            }
        }
        .padding(18)
        .frame(width: isOpen ? 320 : 220, alignment: .leading)
        .profileGlowBubble(cornerRadius: 26, tint: tint)
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                expandedAspect = isOpen ? nil : index
            }
        }
    }

    // MARK: Helpers

    private func degreeText(_ planet: PlanetPosition) -> String {
        let d = Int(planet.degree)
        let m = Int((planet.degree - Double(d)) * 60)
        return String(format: "%d°%02d'", d, m)
    }

    private func planetTint(_ planet: Planet) -> Color {
        switch planet {
        case .sun: return Color(hex: "#C9B88C")
        case .moon: return Color(hex: "#AEB6C6")
        case .mercury: return Color(hex: "#A6C2B6")
        case .venus: return Color(hex: "#C6A9C0")
        case .mars: return Color(hex: "#C69A9A")
        case .jupiter: return Color(hex: "#B6A9D6")
        case .saturn: return Color(hex: "#9AA0AB")
        case .uranus: return Color(hex: "#9CB6C2")
        case .neptune: return Color(hex: "#A2A6CC")
        case .pluto: return Color(hex: "#A89AA0")
        }
    }

    private func elementColor(_ element: ZodiacSign.Element) -> Color {
        switch element {
        case .fire: return Color(hex: "#C48A6A")
        case .earth: return Color(hex: "#8FAE7A")
        case .air: return Color(hex: "#7AA0C4")
        case .water: return Color(hex: "#7A8EC4")
        }
    }
}

private enum AstralReadings {
    static func planet(_ planet: Planet, _ sign: ZodiacSign) -> String {
        let domain: String
        switch planet {
        case .sun: domain = "Güneş; öz benliğini, yaşam gücünü ve içindeki ışığı temsil eder"
        case .moon: domain = "Ay; duygusal dünyanı, içgüdülerini ve güvende hissettiğin yeri temsil eder"
        case .mercury: domain = "Merkür; düşünme ve iletişim biçimini, zihninin ritmini temsil eder"
        case .venus: domain = "Venüs; sevme biçimini, estetik anlayışını ve neye değer verdiğini temsil eder"
        case .mars: domain = "Mars; arzunu, irade gücünü ve harekete geçiş tarzını temsil eder"
        case .jupiter: domain = "Jüpiter; büyüme alanlarını, inancını ve şansının aktığı yönü temsil eder"
        case .saturn: domain = "Satürn; sorumluluklarını, sınırlarını ve olgunlaşma derslerini temsil eder"
        case .uranus: domain = "Uranüs; özgünlüğünü, ani uyanışlarını ve özgürlük ihtiyacını temsil eder"
        case .neptune: domain = "Neptün; hayal gücünü, sezgini ve ruhsal özlemini temsil eder"
        case .pluto: domain = "Plüton; dönüşüm gücünü, gölgeni ve yeniden doğuş kapasiteni temsil eder"
        }
        return "\(domain). \(signVoice(sign))"
    }

    static func signVoice(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Koç burcunda bu enerji cesur, doğrudan ve başlatıcıdır; beklemeyi sevmez, önce hamle yapar. İçindeki kıvılcım seni öncülüğe ve cesur risklere çağırır."
        case .taurus: return "Boğa burcunda bu enerji sabırlı, kararlı ve duyusaldır; aceleye gelmez, sağlam temeller kurar. İstikrar ve gerçek değer arayışı seni dengeye taşır."
        case .gemini: return "İkizler burcunda bu enerji meraklı, çevik ve iletişimcidir; fikirler arasında hızla gezinir. Çok yönlülüğün, öğrenme ve bağ kurma yeteneğini besler."
        case .cancer: return "Yengeç burcunda bu enerji derin duygusal, koruyucu ve sezgiseldir; kalpten hareket eder. Güven ve aidiyet ihtiyacın seni şefkatli bir limana dönüştürür."
        case .leo: return "Aslan burcunda bu enerji ışıltılı, cömert ve yaratıcıdır; görünmek ve ilham vermek ister. İçindeki sıcaklık ve gurur, sahneyi doğal biçimde sana açar."
        case .virgo: return "Başak burcunda bu enerji analitik, titiz ve hizmet odaklıdır; detayda mükemmeli arar. Pratik zekân, kaosu düzene çeviren sessiz bir güç taşır."
        case .libra: return "Terazi burcunda bu enerji uyumlu, estetik ve adildir; denge ve ilişki üzerinden var olur. Diplomatik inceliğin, karşındakini görme yeteneğinden doğar."
        case .scorpio: return "Akrep burcunda bu enerji yoğun, tutkulu ve dönüştürücüdür; yüzeyle yetinmez, derine iner. Sezgilerin ve kararlılığın, gölgeyi güce çevirme kapasitesi verir."
        case .sagittarius: return "Yay burcunda bu enerji iyimser, maceracı ve felsefidir; ufuklar seni çağırır. Özgürlük ve anlam arayışın, hayata geniş bir vizyonla bakmanı sağlar."
        case .capricorn: return "Oğlak burcunda bu enerji disiplinli, hedef odaklı ve dayanıklıdır; uzun vadeyi görür. Sabrın ve sorumluluk duygun, zamanla sağlam bir otorite inşa eder."
        case .aquarius: return "Kova burcunda bu enerji yenilikçi, bağımsız ve insancıldır; alışılmışın dışında düşünür. Özgün bakışın, geleceği bugünden sezme yeteneğiyle birleşir."
        case .pisces: return "Balık burcunda bu enerji sezgisel, empatik ve hayalperesttir; sınırlar onda yumuşar. Sanatsal ve ruhsal derinliğin, dünyayı kalbinle hissetmeni sağlar."
        }
    }

    static func house(house: Int, sign: ZodiacSign) -> String {
        let base: String
        switch house {
        case 1: base = "Birinci ev kimliğini, dış görünüşünü ve dünyaya verdiğin ilk izlenimi yönetir."
        case 2: base = "İkinci ev değerlerini, maddi kaynaklarını ve kendine biçtiğin değeri yönetir."
        case 3: base = "Üçüncü ev iletişim tarzını, öğrenme biçimini ve yakın çevrenle bağını yönetir."
        case 4: base = "Dördüncü ev evini, aile köklerini ve içsel güvenlik ihtiyacını yönetir."
        case 5: base = "Beşinci ev yaratıcılığını, romantik ifadeni ve hayattan aldığın hazzı yönetir."
        case 6: base = "Altıncı ev günlük rutinlerini, sağlığını ve çalışma disiplinini yönetir."
        case 7: base = "Yedinci ev ilişkilerini, ortaklıklarını ve bir partnerde aradıklarını yönetir."
        case 8: base = "Sekizinci ev dönüşümünü, paylaşılan kaynakları ve duygusal derinliğini yönetir."
        case 9: base = "Dokuzuncu ev inanç sistemini, uzak ufukları ve hayata bakış açını yönetir."
        case 10: base = "Onuncu ev kariyerini, toplumsal kimliğini ve otoriteyle ilişkini yönetir."
        case 11: base = "On birinci ev dostluklarını, topluluk içindeki yerini ve gelecek vizyonunu yönetir."
        case 12: base = "On ikinci ev bilinçaltını, gizli güçlerini ve ruhsal dünyanı yönetir."
        default: base = ""
        }
        return "\(base) \(sign.labelTR) burcunun yönetiminde, bu alana \(signFlavor(sign)) bir nitelik katarsın."
    }

    static func signFlavor(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "atılgan ve öncü"
        case .taurus: return "sabırlı ve istikrarlı"
        case .gemini: return "meraklı ve çok yönlü"
        case .cancer: return "duygusal ve koruyucu"
        case .leo: return "gururlu ve cömert"
        case .virgo: return "titiz ve çözüm odaklı"
        case .libra: return "dengeli ve uyumlu"
        case .scorpio: return "yoğun ve dönüştürücü"
        case .sagittarius: return "özgür ve idealist"
        case .capricorn: return "disiplinli ve hırslı"
        case .aquarius: return "yenilikçi ve bağımsız"
        case .pisces: return "sezgisel ve şefkatli"
        }
    }

    static func aspect(_ aspect: AspectEntity) -> String {
        let p1 = aspect.planet1.name
        let p2 = aspect.planet2.name
        switch aspect.type {
        case .conjunction:
            return "\(p1) ve \(p2) gökyüzünde aynı noktada birleşir; bu iki gücün enerjisi ayrılmaz biçimde harmanlanır. Hayatında bu temalar birlikte hareket eder, biri uyandığında diğeri de devreye girer. Bu birleşimi bilinçli yönetmek, onu en parlak gücüne dönüştürür."
        case .trine:
            return "\(p1) ile \(p2) arasında doğal ve akıcı bir uyum vardır; bu yetenek sana neredeyse çaba harcamadan gelir. İki gezegenin enerjisi birbirini besler ve zorlanmadan akar. Bu armağanı bilinçli kullandığında gerçek bir üstünlüğe dönüşür."
        case .sextile:
            return "\(p1) ile \(p2) sana fırsat kapıları açan destekleyici bir açı kurar. Uyum kendiliğinden gelmez ama küçük bir adımla harekete geçer. İnisiyatif aldığında bu potansiyel somut sonuçlara evrilir."
        case .square:
            return "\(p1) ile \(p2) arasında yaratıcı bir gerilim vardır; bu sürtünme seni rahatsız ettiği kadar büyütür de. İki güç birbirini zorlar ve bu içsel çekişme, üzerinde çalıştıkça olgunlaşır. Direncini ustalığa çevirmek bu açının asıl dersidir."
        case .opposition:
            return "\(p1) ile \(p2) karşı kutuplarda durur ve senden bir denge bulmanı ister. Bu eksen çoğu zaman ilişkiler üzerinden, başkalarının aynasında belirginleşir. İki ucu birbirine düşman değil tamamlayıcı görmek, bu açıyı bilgeliğe taşır."
        }
    }
}

// MARK: Planet sheet

private struct ProfilePlanetDetailSheet: View {
    let planet: PlanetPosition

    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                ScrollView {
                    VStack(spacing: 20) {
                        Text(planet.planet.glyph)
                            .font(.system(size: 44))
                            .padding(.top, 20)
                        Text(planet.planet.name)
                            .font(ABFont.display(26))
                            .foregroundStyle(.white)
                        Text("\(planet.sign.glyph) \(planet.sign.labelTR) · Ev \(planet.house)\(planet.isRetrograde ? " · ℞" : "")")
                            .font(ABFont.body(16, weight: .medium))
                            .foregroundStyle(Color(hex: "#CDD2DB"))
                        Text(String(format: "%.1f° %@", planet.degree, planet.sign.labelTR))
                            .font(ABFont.body(14))
                            .foregroundStyle(Color.white.opacity(0.5))
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ne Anlama Gelir?")
                                .font(ABFont.body(15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#CDD2DB"))
                            Text(AstralReadings.planet(planet.planet, planet.sign))
                                .font(ABFont.body(15))
                                .foregroundStyle(Color.white.opacity(0.82))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(18)
                        .crystalPlate(cornerRadius: 22)
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

private struct ProfileGlowBubble: ViewModifier {
    var cornerRadius: CGFloat
    var tint: Color

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "#D6CFFF").opacity(0.85), Color(hex: "#8F7FF7").opacity(0.45)],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 5
                        )
                        .blur(radius: 7)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .opacity(0.5)
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(hex: "#E2DDFF").opacity(0.75), Color(hex: "#8F7FF7").opacity(0.30)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color(hex: "#8F7FF7").opacity(0.30), radius: 16, y: 6)
    }
}

private extension View {
    func profileGlowBubble(cornerRadius: CGFloat, tint: Color) -> some View {
        modifier(ProfileGlowBubble(cornerRadius: cornerRadius, tint: tint))
    }
}
