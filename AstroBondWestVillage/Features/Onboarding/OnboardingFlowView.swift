import SwiftUI

@MainActor
@Observable
final class OnboardingViewModel {
    var displayName = ""
    var gender: Gender = .preferNotSay
    var seeking: Set<Gender> = [.woman, .man]
    var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    var timeKnown = false
    var hour = 12
    var minute = 0
    var city: CityOption = CityOption.presets[0]
    var district: District = CityOption.presets[0].districts[0]
    var step = 0
    var isSaving = false
    var errorMessage: String?

    private let profiles = ProfileService()

    var canContinueName: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    func selectCity(_ newCity: CityOption) {
        city = newCity
        district = newCity.districts.first ?? District(id: newCity.id, name: newCity.name, latitude: 0, longitude: 0)
    }

    func toggleSeeking(_ g: Gender) {
        if seeking.contains(g) {
            if seeking.count > 1 { seeking.remove(g) }
        } else {
            seeking.insert(g)
        }
    }

    func save(userId: String) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            try await profiles.completeOnboarding(
                userId: userId,
                displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                gender: gender,
                birthDate: min(birthDate, Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? birthDate),
                timeKnown: timeKnown,
                hour: hour,
                minute: minute,
                city: city,
                district: district,
                genderPrefs: Array(seeking)
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

struct OnboardingFlowView: View {
    @Environment(SessionStore.self) private var session
    @State private var model = OnboardingViewModel()

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                progress
                    .padding(.top, 16)
                    .padding(.horizontal, 28)

                TabView(selection: $model.step) {
                    nameGenderStep.tag(0)
                    birthStep.tag(1)
                    prefsStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: model.step)

                footer
                    .padding(.horizontal, 28)
                    .padding(.bottom, 36)
                    .padding(.top, 12)

                Button {
                    Task { await session.signOut() }
                } label: {
                    Text("Farklı hesapla giriş yap")
                        .font(ABFont.body(13, weight: .medium))
                        .foregroundStyle(ABColor.lavenderSoft)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 24)
            }
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= model.step ? ABColor.lavenderSoft : Color.white.opacity(0.15))
                    .frame(height: 4)
            }
        }
    }

    private var nameGenderStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                titleBlock("Sen kimsin?", "İsim ve cinsiyet — eşleşmeler için.")
                CrystalField(title: "İSİM", text: $model.displayName, contentType: .name)
                    .textInputAutocapitalization(.words)

                Text("CİNSİYET")
                    .font(ABFont.label(12))
                    .foregroundStyle(ABColor.inkMuted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(Gender.allCases) { g in
                        chip(g.labelTR, selected: model.gender == g) {
                            model.gender = g
                        }
                    }
                }
            }
            .padding(22)
            .crystalPlate(cornerRadius: 28)
            .padding(20)
        }
    }

    private var birthStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                titleBlock("Doğum bilgilerin", "Haritan için gerekli — gizli tutulur.")

                DatePicker(
                    "Doğum tarihi",
                    selection: $model.birthDate,
                    in: ...Calendar.current.date(byAdding: .year, value: -18, to: Date())!,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .tint(ABColor.lavenderSoft)
                .foregroundStyle(ABColor.ink)

                Toggle("Doğum saatimi biliyorum", isOn: $model.timeKnown)
                    .tint(ABColor.lavender)
                    .foregroundStyle(ABColor.ink)

                if model.timeKnown {
                    DatePicker(
                        "Saat",
                        selection: Binding(
                            get: {
                                Calendar.current.date(
                                    bySettingHour: model.hour,
                                    minute: model.minute,
                                    second: 0,
                                    of: Date()
                                ) ?? Date()
                            },
                            set: { date in
                                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                                model.hour = c.hour ?? 12
                                model.minute = c.minute ?? 0
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .tint(ABColor.lavenderSoft)
                }

                Text("ŞEHİR")
                    .font(ABFont.label(12))
                    .foregroundStyle(ABColor.inkMuted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CityOption.presets) { city in
                            chip("\(city.name)", selected: model.city == city) {
                                model.selectCity(city)
                            }
                            .frame(width: 130)
                        }
                    }
                }

                Text("SEMT / MAHALLE")
                    .font(ABFont.label(12))
                    .foregroundStyle(ABColor.inkMuted)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(model.city.districts) { d in
                        chip(d.name, selected: model.district.id == d.id) {
                            model.district = d
                        }
                    }
                }
            }
            .padding(22)
            .crystalPlate(cornerRadius: 28)
            .padding(20)
        }
    }

    private var prefsStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                titleBlock("Kimi arıyorsun?", "Eşleşme adaylarını filtreler.")
                Text("CİNSİYET TERCİHİ")
                    .font(ABFont.label(12))
                    .foregroundStyle(ABColor.inkMuted)
                ForEach([Gender.woman, .man, .nonBinary, .other], id: \.self) { g in
                    chip(g.labelTR, selected: model.seeking.contains(g)) {
                        model.toggleSeeking(g)
                    }
                }

                if let error = model.errorMessage {
                    Text(error)
                        .font(ABFont.body(13))
                        .foregroundStyle(Color(hex: "#C69A9A"))
                }
            }
            .padding(22)
            .crystalPlate(cornerRadius: 28)
            .padding(20)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if model.step > 0 {
                Button("Geri") {
                    model.step -= 1
                }
                .font(ABFont.body(15, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted)
                .frame(width: 80, height: 54)
            }

            CrystalCTAButton(
                title: model.isSaving ? "Kaydediliyor…" : (model.step == 2 ? "Haritamı oluştur" : "Devam"),
                isEnabled: model.step == 0 ? model.canContinueName : !model.isSaving
            ) {
                Task { await advance() }
            }
        }
    }

    private func advance() async {
        if model.step < 2 {
            model.step += 1
            return
        }
        guard let userId = session.user?.id else { return }
        if await model.save(userId: userId) {
            await session.markOnboardingComplete()
        }
    }

    private func titleBlock(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(ABFont.display(26))
                .foregroundStyle(ABColor.ink)
            Text(subtitle)
                .font(ABFont.body(14))
                .foregroundStyle(ABColor.inkMuted)
        }
    }

    private func chip(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(ABFont.body(14, weight: selected ? .semibold : .regular))
                .foregroundStyle(selected ? ABColor.ink : ABColor.inkMuted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    Capsule(style: .continuous)
                        .fill(selected ? ABColor.lavender.opacity(0.28) : Color.white.opacity(0.06))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? ABColor.lavenderSoft.opacity(0.55) : Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
