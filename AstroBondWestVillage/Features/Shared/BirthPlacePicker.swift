import SwiftUI

/// Searchable city + district picker covering all 81 provinces (and abroad extras).
struct BirthPlacePicker: View {
    @Binding var city: CityOption
    @Binding var district: District
    var compact: Bool = false
    var warm: Bool = false

    @State private var showCities = false
    @State private var showDistricts = false
    @State private var cityQuery = ""
    @State private var districtQuery = ""

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            Text("ŞEHİR")
                .font(ABFont.label(12))
                .foregroundStyle(warm ? ABColor.warm.opacity(0.8) : ABColor.inkMuted)

            Button {
                cityQuery = ""
                showCities = true
            } label: {
                fieldRow(title: "\(city.name), \(city.country)", icon: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)

            Text("SEMT / İLÇE")
                .font(ABFont.label(12))
                .foregroundStyle(warm ? ABColor.warm.opacity(0.8) : ABColor.inkMuted)
                .padding(.top, 4)

            Button {
                districtQuery = ""
                showDistricts = true
            } label: {
                fieldRow(title: district.name, icon: "magnifyingglass")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onChange(of: city.id) { _, _ in showDistricts = false }
        .sheet(isPresented: $showCities) {
            citySheet
        }
        .sheet(isPresented: $showDistricts) {
            districtSheet
        }
    }

    private func fieldRow(title: String, icon: String) -> some View {
        HStack {
            Text(title)
                .font(ABFont.body(15, weight: .medium))
                .foregroundStyle(ABColor.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 8)
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(warm ? ABColor.warm : ABColor.inkMuted)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .background {
            if !warm {
                Capsule(style: .continuous).fill(ABColor.veil.opacity(0.06))
            }
        }
        .overlay {
            if !warm {
                Capsule(style: .continuous)
                    .strokeBorder(ABColor.lavenderSoft.opacity(0.35), lineWidth: 1)
            }
        }
        .modifier(WarmFieldChrome(enabled: warm))
    }

    private var filteredCities: [CityOption] {
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let tr = Locale(identifier: "tr_TR")
        let pool = CityOption.presets
        if q.isEmpty { return pool }
        return pool.filter { $0.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: tr) != nil }
    }

    private var citySheet: some View {
        Group {
            if warm {
                warmPickerSheet(
                    title: "Şehir seç",
                    query: $cityQuery,
                    prompt: "İl ara — Çanakkale, Van…",
                    dismiss: { showCities = false }
                ) {
                    if filteredCities.isEmpty {
                        emptySearch
                    } else {
                        ForEach(filteredCities) { option in
                            Button {
                                city = option
                                district = option.districts.first ?? district
                                showCities = false
                            } label: {
                                warmRow(
                                    title: option.name,
                                    subtitle: option.country,
                                    selected: option.id == city.id
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                NavigationStack {
                    List {
                        ForEach(filteredCities) { option in
                            Button {
                                city = option
                                district = option.districts.first ?? district
                                showCities = false
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(option.name)
                                            .font(ABFont.body(16, weight: .medium))
                                            .foregroundStyle(ABColor.ink)
                                        Text(option.country)
                                            .font(ABFont.body(12))
                                            .foregroundStyle(ABColor.inkMuted)
                                    }
                                    Spacer()
                                    if option.id == city.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(ABColor.lavenderSoft)
                                    }
                                }
                            }
                            .listRowBackground(ABColor.veil.opacity(0.04))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(ABColor.space)
                    .navigationTitle("Şehir seç")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $cityQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "İl ara — Çanakkale, Van…")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Kapat") { showCities = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var filteredDistricts: [District] {
        let q = districtQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let tr = Locale(identifier: "tr_TR")
        if q.isEmpty { return city.districts }
        return city.districts.filter { $0.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: tr) != nil }
    }

    private var districtSheet: some View {
        Group {
            if warm {
                warmPickerSheet(
                    title: "Semt seç",
                    query: $districtQuery,
                    prompt: "İlçe ara",
                    dismiss: { showDistricts = false }
                ) {
                    if filteredDistricts.isEmpty {
                        emptySearch
                    } else {
                        ForEach(filteredDistricts) { option in
                            Button {
                                district = option
                                showDistricts = false
                            } label: {
                                warmRow(title: option.name, subtitle: nil, selected: option.id == district.id)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            } else {
                NavigationStack {
                    List {
                        ForEach(filteredDistricts) { option in
                            Button {
                                district = option
                                showDistricts = false
                            } label: {
                                HStack {
                                    Text(option.name)
                                        .font(ABFont.body(16, weight: .medium))
                                        .foregroundStyle(ABColor.ink)
                                    Spacer()
                                    if option.id == district.id {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(ABColor.lavenderSoft)
                                    }
                                }
                            }
                            .listRowBackground(ABColor.veil.opacity(0.04))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(ABColor.space)
                    .navigationTitle("Semt seç")
                    .navigationBarTitleDisplayMode(.inline)
                    .searchable(text: $districtQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "İlçe ara")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Kapat") { showDistricts = false }
                        }
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private var emptySearch: some View {
        Text("Sonuç yok")
            .font(ABFont.body(14))
            .foregroundStyle(ABColor.warm.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
    }

    private func warmRow(title: String, subtitle: String?, selected: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(ABFont.body(16, weight: .medium))
                    .foregroundStyle(ABColor.ink)
                if let subtitle {
                    Text(subtitle)
                        .font(ABFont.body(12))
                        .foregroundStyle(ABColor.warm.opacity(0.75))
                }
            }
            Spacer(minLength: 8)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "#C8A56E"))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .amberSegment(corner: 18)
    }

    private func warmPickerSheet<Rows: View>(
        title: String,
        query: Binding<String>,
        prompt: String,
        dismiss: @escaping () -> Void,
        @ViewBuilder rows: () -> Rows
    ) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text(title)
                    .font(ABFont.display(20, weight: .regular))
                    .foregroundStyle(ABColor.ink)
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                        .frame(width: 32, height: 32)
                        .amberSegment(corner: 16)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ABColor.warm)
                TextField("", text: query, prompt: Text(prompt).foregroundStyle(ABColor.warm.opacity(0.55)))
                    .font(ABFont.body(15))
                    .foregroundStyle(ABColor.ink)
                    .tint(ABColor.warm)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .amberSegment(corner: 22)

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    rows()
                }
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { birthSky }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground { birthSky }
    }

    private var birthSky: some View {
        ZStack {
            Image("reveal_bg")
                .resizable()
                .scaledToFill()
            LinearGradient(
                colors: [.clear, Color(hex: "#120A07").opacity(0.22)],
                startPoint: UnitPoint(x: 0.5, y: 0.78),
                endPoint: .bottom
            )
            RevealSkyDecor()
        }
        .ignoresSafeArea()
    }
}

private struct WarmFieldChrome: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.amberSegment(corner: 22)
        } else {
            content
        }
    }
}
