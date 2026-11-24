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
    var city: CityOption = CityOption.defaultCity
    var district: District = CityOption.defaultCity.districts[0]
    var step = 0
    var isSaving = false
    var errorMessage: String?
    var calculatedChart: NatalChart?
    var didAttemptChartSave = false

    private let profiles = ProfileService()

    var canContinueName: Bool {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    func selectCity(_ newCity: CityOption) {
        city = newCity
        district = newCity.districts.first ?? District(id: newCity.id, name: newCity.name, latitude: 0, longitude: 0)
    }

    func save(userId: String) async -> Bool {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            calculatedChart = try await profiles.completeOnboarding(
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
                if model.step == 1 {
                    HStack {
                        Button { model.step -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(ABColor.ink)
                                .frame(width: 36, height: 36)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.horizontal, 16)
                } else if model.step == 0 {
                    progress
                        .padding(.top, 16)
                        .padding(.horizontal, 28)
                }

                TabView(selection: $model.step) {
                    nameGenderStep.tag(0)
                    birthStep.tag(1)
                    chartStep.tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: model.step)

                if model.step == 0 {
                    VStack(spacing: 0) {
                            footer
                                .padding(.horizontal, 28)
                                .padding(.top, 8)
                                .padding(.bottom, 28)

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
        }
    }

    private var progress: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(i <= model.step ? ABColor.lavenderSoft : ABColor.veil.opacity(0.15))
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
        GeometryReader { geo in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer(minLength: 22)
                    VStack(spacing: 6) {
                        Text("HARİTA BİLGİLERİ")
                            .font(ABFont.display(20, weight: .regular))
                            .tracking(1.4)
                            .foregroundStyle(ABColor.ink)
                        Text("Tarih ve saat haritanı çizer. İkisi de gizli kalır.")
                            .font(ABFont.body(14))
                            .foregroundStyle(ABColor.warm.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .amberSegment(corner: 22)

                    Spacer(minLength: 22)
                    BirthMomentPicker(
                        birthDate: $model.birthDate,
                        timeKnown: $model.timeKnown,
                        hour: $model.hour,
                        minute: $model.minute
                    )
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 22)
                    BirthPlacePicker(city: $model.city, district: $model.district, warm: true)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 22)
                    Button {
                        Task { await advance() }
                    } label: {
                        Text("Devam")
                            .font(ABFont.body(15, weight: .medium))
                            .foregroundStyle(ABColor.ink)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .amberSegment(corner: 22)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 28)
                }
                .padding(.horizontal, 20)
                .frame(width: geo.size.width, alignment: .center)
                .frame(minHeight: geo.size.height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .background {
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
                    .offset(y: -28)
            }
            .ignoresSafeArea()
        }
    }

    private var chartStep: some View {
        ChartCalculationStepView(
            chart: model.calculatedChart,
            isLoading: model.isSaving,
            errorMessage: model.errorMessage,
            onBack: {
                model.didAttemptChartSave = false
                model.errorMessage = nil
                model.step = 1
            },
            onContinue: {
                Task { await session.markOnboardingComplete() }
            }
        )
        .task(id: model.step) {
            guard model.step == 2 else { return }
            guard let userId = session.user?.id else { return }
            guard !model.didAttemptChartSave else { return }
            model.didAttemptChartSave = true
            _ = await model.save(userId: userId)
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
                title: "Devam",
                isEnabled: model.canContinueName
            ) {
                Task { await advance() }
            }
        }
    }

    private func advance() async {
        if model.step < 2 {
            model.step += 1
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
                        .fill(selected ? ABColor.lavender.opacity(0.28) : ABColor.veil.opacity(0.06))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            selected ? ABColor.lavenderSoft.opacity(0.55) : ABColor.veil.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
