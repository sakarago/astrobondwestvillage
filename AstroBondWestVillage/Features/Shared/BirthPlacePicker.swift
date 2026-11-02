import SwiftUI

/// Searchable city + district picker covering all 81 provinces (and abroad extras).
struct BirthPlacePicker: View {
    @Binding var city: CityOption
    @Binding var district: District
    var compact: Bool = false

    @State private var showCities = false
    @State private var cityQuery = ""

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 10 : 12) {
            Text("ŞEHİR")
                .font(ABFont.label(12))
                .foregroundStyle(ABColor.inkMuted)

            Button {
                cityQuery = ""
                showCities = true
            } label: {
                HStack {
                    Text("\(city.name), \(city.country)")
                        .font(ABFont.body(15, weight: .medium))
                        .foregroundStyle(ABColor.ink)
                        .lineLimit(1)
                    Spacer(minLength: 8)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ABColor.inkMuted)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Capsule(style: .continuous).fill(Color.white.opacity(0.06)))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(ABColor.lavenderSoft.opacity(0.35), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Text("SEMT / İLÇE")
                .font(ABFont.label(12))
                .foregroundStyle(ABColor.inkMuted)
                .padding(.top, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(city.districts) { d in
                    Button {
                        district = d
                    } label: {
                        Text(d.name)
                            .font(ABFont.body(14, weight: district.id == d.id ? .semibold : .regular))
                            .foregroundStyle(district.id == d.id ? ABColor.ink : ABColor.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background {
                                Capsule(style: .continuous)
                                    .fill(district.id == d.id ? ABColor.lavender.opacity(0.28) : Color.white.opacity(0.06))
                            }
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        district.id == d.id ? ABColor.lavenderSoft.opacity(0.55) : Color.white.opacity(0.12),
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showCities) {
            citySheet
        }
    }

    private var filteredCities: [CityOption] {
        let q = cityQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let tr = Locale(identifier: "tr_TR")
        let pool = CityOption.presets
        if q.isEmpty { return pool }
        return pool.filter { $0.name.range(of: q, options: [.caseInsensitive, .diacriticInsensitive], locale: tr) != nil }
    }

    private var citySheet: some View {
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
                    .listRowBackground(Color.white.opacity(0.04))
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
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }
}
