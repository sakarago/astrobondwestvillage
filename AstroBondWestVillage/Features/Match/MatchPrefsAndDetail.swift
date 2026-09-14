import SwiftUI

struct MatchPrefsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State var prefs: MatchPrefsStore.Snapshot
    let onSave: (MatchPrefsStore.Snapshot) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        section("Bağ türü") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(MatchIntent.allCases) { intent in
                                    Button {
                                        prefs.intent = intent
                                    } label: {
                                        VStack(alignment: .leading, spacing: 6) {
                                            Image(systemName: intent.iconName)
                                                .foregroundStyle(ABColor.lavenderSoft)
                                            Text(intent.titleTR)
                                                .font(ABFont.body(15, weight: .semibold))
                                                .foregroundStyle(ABColor.ink)
                                            Text(intent.subtitle)
                                                .font(ABFont.body(12))
                                                .foregroundStyle(ABColor.inkMuted)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(14)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .strokeBorder(
                                                    prefs.intent == intent
                                                        ? ABColor.lavenderSoft.opacity(0.8)
                                                        : Color.white.opacity(0.12),
                                                    lineWidth: prefs.intent == intent ? 1.4 : 1
                                                )
                                        )
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(prefs.intent == intent ? ABColor.lavender.opacity(0.2) : Color.white.opacity(0.04))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        section("Cinsiyet tercihleri") {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], spacing: 8) {
                                ForEach(Gender.allCases.filter { $0 != .preferNotSay }) { gender in
                                    let on = prefs.preferredGenders.contains(gender)
                                    Button {
                                        if on {
                                            prefs.preferredGenders.removeAll { $0 == gender }
                                        } else {
                                            prefs.preferredGenders.append(gender)
                                        }
                                    } label: {
                                        Text(gender.labelTR)
                                            .font(ABFont.body(13, weight: .semibold))
                                            .foregroundStyle(on ? Color.white : ABColor.inkMuted)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 10)
                                            .background(Capsule().fill(on ? ABColor.lavender.opacity(0.45) : Color.white.opacity(0.06)))
                                            .overlay(Capsule().strokeBorder(Color.white.opacity(on ? 0.35 : 0.12), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        section("Yaş aralığı") {
                            Toggle("Filtrele", isOn: $prefs.ageEnabled)
                                .tint(ABColor.lavender)
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.ink)
                            if prefs.ageEnabled {
                                HStack {
                                    Text("\(prefs.ageMin)")
                                        .foregroundStyle(ABColor.inkMuted)
                                    Slider(
                                        value: Binding(
                                            get: { Double(prefs.ageMin) },
                                            set: { prefs.ageMin = Int($0) }
                                        ),
                                        in: 18...60,
                                        step: 1
                                    )
                                    .tint(ABColor.lavenderSoft)
                                    Text("\(prefs.ageMax)")
                                        .foregroundStyle(ABColor.inkMuted)
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(prefs.ageMax) },
                                        set: { prefs.ageMax = max(prefs.ageMin, Int($0)) }
                                    ),
                                    in: 18...70,
                                    step: 1
                                )
                                .tint(ABColor.lavenderSoft)
                            }
                        }

                        section("Konum") {
                            Toggle("Şehir filtresi", isOn: $prefs.locationEnabled)
                                .tint(ABColor.lavender)
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.ink)
                            if prefs.locationEnabled {
                                TextField("Şehir", text: $prefs.searchCity)
                                    .font(ABFont.body(15))
                                    .foregroundStyle(ABColor.ink)
                                    .padding(12)
                                    .crystalPlate(cornerRadius: 14)
                                Text("Mesafe ≈ \(Int(prefs.maxDistanceKm)) km")
                                    .font(ABFont.body(13))
                                    .foregroundStyle(ABColor.inkMuted)
                                Slider(value: $prefs.maxDistanceKm, in: 10...500, step: 10)
                                    .tint(ABColor.lavenderSoft)
                            }
                        }

                        CrystalCTAButton(title: "Kaydet") {
                            onSave(prefs)
                            dismiss()
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(ABColor.inkMuted)
                }
                ToolbarItem(placement: .principal) {
                    Text("Eşleşme tercihleri")
                        .font(ABFont.body(16, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(ABFont.body(11, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(ABColor.inkMuted)
            VStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(16)
            .crystalPlate(cornerRadius: 22)
        }
    }
}

struct MatchDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let card: MatchCard
    let mySun: ZodiacSign?
    let intent: MatchIntent

    private var report: BondStory.Report {
        BondStory.report(mySun: mySun, their: card, intent: intent)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CosmicBackdrop()
                ScrollView {
                    VStack(spacing: 18) {
                        PersonAvatar(
                            name: card.displayName,
                            photoURL: card.photoURL,
                            sunSign: card.sunSign,
                            unlocked: false,
                            size: 84
                        )
                        Text(card.displayName)
                            .font(ABFont.display(28))
                            .foregroundStyle(ABColor.ink)
                        Text(report.headline)
                            .font(ABFont.body(14))
                            .foregroundStyle(ABColor.inkMuted)
                            .multilineTextAlignment(.center)

                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.12), lineWidth: 10)
                                .frame(width: 120, height: 120)
                            Circle()
                                .trim(from: 0, to: CGFloat(report.overall) / 100)
                                .stroke(
                                    AngularGradient(
                                        colors: [ABColor.lavenderSoft, ABColor.lavender, Color.white.opacity(0.5)],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                )
                                .frame(width: 120, height: 120)
                                .rotationEffect(.degrees(-90))
                            VStack(spacing: 2) {
                                Text("\(report.overall)")
                                    .font(ABFont.display(28))
                                    .foregroundStyle(ABColor.ink)
                                Text(report.title)
                                    .font(ABFont.body(11, weight: .semibold))
                                    .foregroundStyle(ABColor.lavenderSoft)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 90)
                            }
                        }
                        .padding(.vertical, 8)

                        VStack(spacing: 12) {
                            ForEach(report.dimensions) { dim in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(dim.title)
                                            .font(ABFont.body(14, weight: .semibold))
                                            .foregroundStyle(ABColor.ink)
                                        Spacer()
                                        Text("\(dim.score)")
                                            .font(ABFont.body(13, weight: .bold))
                                            .foregroundStyle(ABColor.lavenderSoft)
                                    }
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(Color.white.opacity(0.08))
                                            Capsule()
                                                .fill(ABColor.lavender.opacity(0.7))
                                                .frame(width: geo.size.width * CGFloat(dim.score) / 100)
                                        }
                                    }
                                    .frame(height: 6)
                                    Text(dim.blurb)
                                        .font(ABFont.body(12))
                                        .foregroundStyle(ABColor.inkMuted)
                                }
                            }
                        }
                        .padding(16)
                        .crystalPlate(cornerRadius: 22)

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Aspekt notları")
                                .font(ABFont.body(13, weight: .semibold))
                                .foregroundStyle(ABColor.ink)
                            ForEach(report.aspects, id: \.self) { line in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("✧")
                                        .foregroundStyle(ABColor.lavenderSoft)
                                    Text(line)
                                        .font(ABFont.body(13))
                                        .foregroundStyle(ABColor.inkMuted)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .crystalPlate(cornerRadius: 22)
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                        .foregroundStyle(ABColor.inkMuted)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
