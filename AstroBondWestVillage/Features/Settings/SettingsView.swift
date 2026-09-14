import SwiftUI

struct SettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var snapshot: ProfileSnapshot?
    @State private var saveError: String?
    @State private var privateAccount = NotificationPrefsStore.shared.privateAccount
    @State private var dailyInsight = NotificationPrefsStore.shared.dailyInsight
    @State private var matchEnabled = NotificationPrefsStore.shared.newMatches
    @State private var messageEnabled = NotificationPrefsStore.shared.messages
    @State private var transitEnabled = NotificationPrefsStore.shared.transits
    @State private var language = AppLanguageStore.shared.language

    private let profiles = ProfileService()

    var body: some View {
        ZStack {
            CosmicBackdrop()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(ABColor.ink)
                                .frame(width: 36, height: 36)
                                .crystalPlate(cornerRadius: 12)
                        }
                        .buttonStyle(.plain)
                        Text("Ayarlar")
                            .font(ABFont.display(26))
                            .foregroundStyle(ABColor.ink)
                        Spacer()
                    }

                    if let saveError {
                        Text(saveError)
                            .font(ABFont.body(13))
                            .foregroundStyle(Color(hex: "#C69A9A"))
                            .padding(12)
                            .crystalPlate(cornerRadius: 16)
                    }

                    settingsCard {
                        NavigationLink {
                            EditProfileSettingsView(snapshot: snapshot) { updated in
                                snapshot = updated
                            }
                        } label: {
                            navRow("Profili Düzenle")
                        }
                        .buttonStyle(.plain)
                        divider
                        toggleRow("Gizli Hesap", $privateAccount) {
                            NotificationPrefsStore.shared.privateAccount = privateAccount
                        }
                        divider
                        NavigationLink { PremiumSettingsView() } label: { navRow("Premium") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink {
                            LanguageSettingsView(language: $language)
                        } label: {
                            navRow("Dil", value: language.displayName)
                        }
                        .buttonStyle(.plain)
                    }

                    sectionLabel("BİLDİRİMLER")
                    settingsCard {
                        toggleRow("Günlük İçgörü", $dailyInsight) {
                            NotificationPrefsStore.shared.dailyInsight = dailyInsight
                        }
                        divider
                        toggleRow("Yeni Eşleşmeler", $matchEnabled) {
                            NotificationPrefsStore.shared.newMatches = matchEnabled
                        }
                        divider
                        toggleRow("Mesajlar", $messageEnabled) {
                            NotificationPrefsStore.shared.messages = messageEnabled
                        }
                        divider
                        toggleRow("Transit Bildirimleri", $transitEnabled) {
                            NotificationPrefsStore.shared.transits = transitEnabled
                        }
                    }

                    settingsCard {
                        NavigationLink { BlockedUsersView() } label: { navRow("Engellenen Kullanıcılar") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink { HelpCenterView() } label: { navRow("Yardım Merkezi") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink { AboutView() } label: { navRow("Hakkımızda") }
                            .buttonStyle(.plain)
                        divider
                        NavigationLink { LegalAgreementView() } label: { navRow("Yasal Bilgilendirme") }
                            .buttonStyle(.plain)
                    }

                    settingsCard {
                        Button {
                            Task { await session.signOut() }
                        } label: {
                            navRow("Çıkış Yap")
                        }
                        .buttonStyle(.plain)
                        divider
                        NavigationLink {
                            ConfirmActionView(
                                title: "Hesabı Dondur",
                                bodyText: "Hesabın diğer kullanıcılara görünmez olur. Bir sonraki girişte otomatik çözülür.",
                                confirmTitle: "Dondur",
                                destructive: false
                            ) {
                                await session.freezeAccount()
                            }
                        } label: {
                            navRow("Hesabı Dondur")
                        }
                        .buttonStyle(.plain)
                        divider
                        NavigationLink {
                            ConfirmActionView(
                                title: "Hesabı Sil",
                                bodyText: "Profilin ve verilerin kalıcı olarak silinir. Bu işlem geri alınamaz.",
                                confirmTitle: "Hesabı Sil",
                                destructive: true
                            ) {
                                await session.deleteAccount()
                            }
                        } label: {
                            navRow("Hesabı Sil", tint: Color(hex: "#FF9F8F"))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
                .padding(.bottom, 40)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            guard let id = session.user?.id else { return }
            snapshot = try? await profiles.fetchSnapshot(userId: id)
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(ABFont.body(11, weight: .bold))
            .tracking(1.3)
            .foregroundStyle(ABColor.inkMuted)
            .padding(.leading, 4)
            .padding(.top, 4)
    }

    private func settingsCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .crystalPlate(cornerRadius: 22)
    }

    private func navRow(_ title: String, value: String? = nil, tint: Color = ABColor.ink) -> some View {
        HStack {
            Text(title).font(ABFont.body(16, weight: .medium)).foregroundStyle(tint)
            Spacer()
            if let value {
                Text(value).font(ABFont.body(14)).foregroundStyle(ABColor.inkMuted)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(ABColor.inkMuted.opacity(0.7))
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func toggleRow(_ title: String, _ isOn: Binding<Bool>, onChange: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(
            get: { isOn.wrappedValue },
            set: { isOn.wrappedValue = $0; onChange() }
        ))
        .font(ABFont.body(16, weight: .medium))
        .foregroundStyle(ABColor.ink)
        .tint(ABColor.lavender)
        .padding(.vertical, 10)
    }
}

// MARK: - Subpages

private struct EditProfileSettingsView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    let snapshot: ProfileSnapshot?
    let onSaved: (ProfileSnapshot) -> Void

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var bio = ""
    @State private var city: CityOption = CityOption.presets[0]
    @State private var district: District = CityOption.presets[0].districts[0]
    @State private var birthDate = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var isSaving = false
    @State private var error: String?

    private let profiles = ProfileService()

    var body: some View {
        ZStack {
            CosmicBackdrop()
            ScrollView {
                VStack(spacing: 16) {
                    settingsInner {
                        HStack(spacing: 12) {
                            field("Ad", $firstName)
                            field("Soyad", $lastName)
                        }
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("E-posta").font(ABFont.body(12, weight: .semibold)).foregroundStyle(ABColor.inkMuted)
                            Text(session.user?.email ?? "—")
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.inkMuted)
                        }
                        .padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                        DatePicker("Doğum tarihi", selection: $birthDate, in: ...eighteenYearsAgo, displayedComponents: .date)
                            .tint(ABColor.lavender)
                            .colorScheme(.dark)
                            .font(ABFont.body(15))
                            .foregroundStyle(ABColor.ink)
                            .padding(.vertical, 8)
                        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Doğum Yeri").font(ABFont.body(12, weight: .semibold)).foregroundStyle(ABColor.inkMuted)
                            HStack(spacing: 10) {
                                Menu {
                                    ForEach(CityOption.presets) { c in
                                        Button(c.name) {
                                            city = c
                                            district = c.districts.first ?? district
                                        }
                                    }
                                } label: { menuChip(city.name) }

                                Menu {
                                    ForEach(city.districts) { d in
                                        Button(d.name) { district = d }
                                    }
                                } label: { menuChip(district.name) }

                                Spacer(minLength: 0)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    settingsInner {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hakkında").font(ABFont.body(12, weight: .semibold)).foregroundStyle(ABColor.inkMuted)
                            TextField("Kısa bir bio", text: $bio, axis: .vertical)
                                .lineLimit(3...6)
                                .font(ABFont.body(15))
                                .foregroundStyle(ABColor.ink)
                        }
                        .padding(.vertical, 8)
                    }

                    if let error {
                        Text(error).font(ABFont.body(13)).foregroundStyle(Color(hex: "#C69A9A"))
                    }

                    CrystalCTAButton(title: isSaving ? "Kaydediliyor…" : "Kaydet", isEnabled: !isSaving) {
                        Task { await save() }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Profili Düzenle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { hydrate() }
    }

    private var eighteenYearsAgo: Date {
        Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private func hydrate() {
        guard let snapshot else { return }
        let parts = snapshot.displayName.split(separator: " ", maxSplits: 1).map(String.init)
        firstName = parts.first ?? snapshot.displayName
        lastName = parts.count > 1 ? parts[1] : ""
        bio = snapshot.bio

        // profiles.city is the metropolitan city; birth_data.city (owner-only)
        // is the neighbourhood/district — reverse-map both into the picker.
        if let districtName = snapshot.district, let owningCity = CityOption.city(containingDistrictNamed: districtName) {
            city = owningCity
            district = owningCity.districts.first(where: { $0.name == districtName }) ?? owningCity.districts[0]
        } else if let cityName = snapshot.city, let match = CityOption.presets.first(where: { $0.name == cityName }) {
            city = match
            district = match.districts.first ?? district
        }
        if let d = snapshot.birthDate { birthDate = d }
    }

    private func save() async {
        guard let id = session.user?.id else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }
        let name = [firstName, lastName]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        do {
            try await profiles.updateProfile(
                userId: id,
                displayName: name.isEmpty ? "Kullanıcı" : name,
                bio: bio,
                city: city,
                district: district,
                birthDate: birthDate
            )
            if let snap = try await profiles.fetchSnapshot(userId: id) {
                onSaved(snap)
            }
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func menuChip(_ text: String) -> some View {
        HStack(spacing: 6) {
            Text(text).font(ABFont.body(15)).foregroundStyle(ABColor.ink)
            Image(systemName: "chevron.down").font(.system(size: 10, weight: .semibold)).foregroundStyle(ABColor.inkMuted)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .crystalPlate(cornerRadius: 14)
    }

    private func field(_ title: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(ABFont.body(12, weight: .semibold)).foregroundStyle(ABColor.inkMuted)
            TextField("", text: text)
                .font(ABFont.body(15))
                .foregroundStyle(ABColor.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
    }

    private func settingsInner<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(16)
            .crystalPlate(cornerRadius: 20)
    }
}

private struct PremiumSettingsView: View {
    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(alignment: .leading, spacing: 14) {
                Text("Premium")
                    .font(ABFont.display(28))
                    .foregroundStyle(ABColor.ink)
                Text("West Village V1’de satın alma henüz açık değil. Günlük eşleşme kotası ve mesaj limiti ücretsiz planda çalışır.")
                    .font(ABFont.body(15))
                    .foregroundStyle(ABColor.inkMuted)
                Spacer()
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct LanguageSettingsView: View {
    @Binding var language: AppLanguage
    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(spacing: 12) {
                ForEach(AppLanguage.allCases) { lang in
                    Button {
                        language = lang
                        AppLanguageStore.shared.language = lang
                    } label: {
                        HStack {
                            Text(lang.displayName)
                                .font(ABFont.body(16, weight: .semibold))
                                .foregroundStyle(ABColor.ink)
                            Spacer()
                            if language == lang {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(ABColor.lavenderSoft)
                            }
                        }
                        .padding(16)
                        .crystalPlate(cornerRadius: 18)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Dil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct BlockedUsersView: View {
    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(spacing: 12) {
                Image(systemName: "hand.raised")
                    .font(.system(size: 28))
                    .foregroundStyle(ABColor.lavenderSoft)
                Text("Engellenen kimse yok")
                    .font(ABFont.body(16, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                Text("Sohbette engellediğin kişiler burada listelenir.")
                    .font(ABFont.body(14))
                    .foregroundStyle(ABColor.inkMuted)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(28)
        }
        .navigationTitle("Engellenenler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct HelpCenterView: View {
    private let faqs: [(String, String)] = [
        ("Günde kaç eşleşme alırım?", "Ücretsiz planda günde yaklaşık 3 yeni eşleşme hakkı vardır. Kota sunucu tarafında da doğrulanır."),
        ("Fotoğraf ne zaman görünür?", "Sohbette toplam \(PhotoGate.unlockAfterMessageCount) mesajdan sonra gerçek profil fotoğrafı açılır."),
        ("Doğum haritam doğru mu?", "V1 yaklaşık Güneş burcu kullanır. Tam ephemeris haritası sonraki sürümde gelecek."),
        ("Hesabımı nasıl silerim?", "Ayarlar → Hesabı Sil. Bu işlem geri alınamaz.")
    ]

    var body: some View {
        ZStack {
            CosmicBackdrop()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(faqs, id: \.0) { q, a in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(q).font(ABFont.body(15, weight: .semibold)).foregroundStyle(ABColor.ink)
                            Text(a).font(ABFont.body(14)).foregroundStyle(ABColor.inkMuted)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .crystalPlate(cornerRadius: 18)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Yardım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct AboutView: View {
    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(alignment: .leading, spacing: 14) {
                Text("AstroBond")
                    .font(ABFont.display(28))
                    .foregroundStyle(ABColor.ink)
                Text("West Village")
                    .font(ABFont.body(16, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft)
                Text("Astroloji temelli bağ keşfi. Yeni arayüz, aynı ürün ruhu.")
                    .font(ABFont.body(15))
                    .foregroundStyle(ABColor.inkMuted)
                Spacer()
            }
            .padding(24)
        }
        .navigationTitle("Hakkımızda")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct LegalAgreementView: View {
    var body: some View {
        ZStack {
            CosmicBackdrop()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Kullanım & KVKK")
                        .font(ABFont.display(24))
                        .foregroundStyle(ABColor.ink)
                    Text("AstroBond, doğum verilerini harita üretimi ve eşleşme için işler. Hassas doğum saati/yer bilgisi yalnızca sana aittir; profilde güvenli alanlar gösterilir. Verilerini Ayarlar’dan silebilir veya hesabını dondurabilirsin.")
                        .font(ABFont.body(14))
                        .foregroundStyle(ABColor.inkMuted)
                        .lineSpacing(4)
                }
                .padding(24)
            }
        }
        .navigationTitle("Yasal")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private struct ConfirmActionView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let bodyText: String
    let confirmTitle: String
    let destructive: Bool
    let action: () async -> Void

    @State private var busy = false

    var body: some View {
        ZStack {
            CosmicBackdrop()
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(ABFont.display(26))
                    .foregroundStyle(ABColor.ink)
                Text(bodyText)
                    .font(ABFont.body(15))
                    .foregroundStyle(ABColor.inkMuted)
                Spacer()
                CrystalCTAButton(title: busy ? "İşleniyor…" : confirmTitle, isEnabled: !busy) {
                    Task {
                        busy = true
                        await action()
                        busy = false
                        dismiss()
                    }
                }
            }
            .padding(24)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
