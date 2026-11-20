import SwiftUI

/// Birth date and time, set with glass wheels instead of the system compact picker.
struct BirthMomentPicker: View {
    @Binding var birthDate: Date
    @Binding var timeKnown: Bool
    @Binding var hour: Int
    @Binding var minute: Int

    private let gold = Color(hex: "#C8A56E")
    private let months = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "tr_TR")
        return calendar
    }

    private var maxDate: Date {
        calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    private var minDate: Date {
        calendar.date(byAdding: .year, value: -90, to: Date()) ?? Date()
    }

    private var day: Int { calendar.component(.day, from: birthDate) }
    private var month: Int { calendar.component(.month, from: birthDate) }
    private var year: Int { calendar.component(.year, from: birthDate) }

    private var daysInMonth: Int {
        let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? birthDate
        return calendar.range(of: .day, in: .month, for: start)?.count ?? 31
    }

    private var years: [Int] {
        let start = calendar.component(.year, from: minDate)
        let end = calendar.component(.year, from: maxDate)
        return Array(start...end).reversed()
    }

    private var sun: ZodiacSign {
        ZodiacSign.sunSign(month: month, day: day)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            datePlaque
            wheelRow(labels: ["GÜN", "AY", "YIL"]) {
                wheel(Array(1...daysInMonth), selection: dayBinding) { Text("\($0)") }
                wheel(Array(1...12), selection: monthBinding) { Text(months[$0 - 1]) }
                wheel(years, selection: yearBinding) { Text(String($0)) }
            }

            timeCard

            if timeKnown {
                timePlaque
                wheelRow(labels: ["SAAT", "DAKİKA"]) {
                    wheel(Array(0...23), selection: $hour) { Text(String(format: "%02d", $0)) }
                    wheel(Array(0...59), selection: $minute) { Text(String(format: "%02d", $0)) }
                }
            }
        }
        .onAppear(perform: clampDate)
    }

    private var datePlaque: some View {
        HStack(alignment: .center, spacing: 18) {
            HStack(alignment: .center, spacing: 10) {
                Text("\(day)")
                    .font(ABFont.display(52, weight: .regular))
                    .foregroundStyle(ABColor.ink)
                VStack(alignment: .leading, spacing: 2) {
                    Text(months[month - 1].uppercased(with: Locale(identifier: "tr_TR")))
                        .font(ABFont.display(20, weight: .regular))
                        .foregroundStyle(ABColor.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(String(year))
                        .font(ABFont.body(14, weight: .medium))
                        .foregroundStyle(ABColor.warm.opacity(0.75))
                }
            }
            VStack(spacing: 4) {
                Text(sun.glyph)
                    .font(.system(size: 22))
                Text(sun.labelTR)
                    .font(ABFont.body(12, weight: .semibold))
                    .foregroundStyle(gold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 68, height: 68)
            .background(Circle().fill(gold.opacity(0.12)))
            .overlay(Circle().strokeBorder(gold.opacity(0.45), lineWidth: 1))
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .amberSegment(corner: 24)
    }

    private var timeCard: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) { timeKnown.toggle() }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: timeKnown ? "clock.fill" : "clock")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(gold)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(gold.opacity(0.12)))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Doğum saatini biliyorum")
                        .font(ABFont.body(15, weight: .semibold))
                        .foregroundStyle(ABColor.ink)
                    Text(timeKnown ? "Yükselen burcun bu saatle çizilir." : "Bilmiyorsan harita öğlen saatiyle çizilir.")
                        .font(ABFont.body(12.5))
                        .foregroundStyle(ABColor.inkMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: timeKnown ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(timeKnown ? gold : ABColor.inkMuted.opacity(0.7))
            }
            .padding(14)
            .amberSegment(corner: 22)
        }
        .buttonStyle(.plain)
    }

    private var timePlaque: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(String(format: "%02d", hour))
            Text(":")
                .foregroundStyle(gold)
            Text(String(format: "%02d", minute))
        }
        .font(ABFont.display(44, weight: .regular))
        .foregroundStyle(ABColor.ink)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func wheelRow<Content: View>(labels: [String], @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            HStack {
                ForEach(labels, id: \.self) { label in
                    Text(label)
                        .font(ABFont.label(11))
                        .tracking(1.4)
                        .foregroundStyle(ABColor.warm.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 132)
            .clipped()
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(gold.opacity(0.55), lineWidth: 1)
                    .frame(height: 34)
                    .allowsHitTesting(false)
            }
            .amberSegment(corner: 20)
        }
    }

    private func wheel<Item: Hashable, Label: View>(
        _ items: [Item],
        selection: Binding<Item>,
        @ViewBuilder label: @escaping (Item) -> Label
    ) -> some View {
        Picker("", selection: selection) {
            ForEach(items, id: \.self) { item in
                label(item)
                    .font(ABFont.body(18, weight: .medium))
                    .foregroundStyle(ABColor.ink)
                    .tag(item)
            }
        }
        .pickerStyle(.wheel)
        .frame(minWidth: 0, maxWidth: .infinity)
        .clipped()
    }

    private var dayBinding: Binding<Int> {
        Binding(get: { day }, set: { setDate(day: $0, month: month, year: year) })
    }

    private var monthBinding: Binding<Int> {
        Binding(get: { month }, set: { setDate(day: day, month: $0, year: year) })
    }

    private var yearBinding: Binding<Int> {
        Binding(get: { year }, set: { setDate(day: day, month: month, year: $0) })
    }

    private func setDate(day: Int, month: Int, year: Int) {
        let start = calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? birthDate
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 28
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = min(day, count)
        var date = calendar.date(from: comps) ?? birthDate
        if date > maxDate { date = maxDate }
        if date < minDate { date = minDate }
        birthDate = date
    }

    private func clampDate() {
        if birthDate > maxDate { birthDate = maxDate }
        if birthDate < minDate { birthDate = minDate }
    }
}

extension View {
    /// Warm glass with a light along the top edge, in the match yes/no palette.
    func amberSegment(corner: CGFloat = 22) -> some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return background {
            ZStack {
                shape.fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "#F6E7CF").opacity(0.16),
                            Color(hex: "#E2C48A").opacity(0.08),
                            Color(hex: "#6E4524").opacity(0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                shape.fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.16), Color.white.opacity(0.03), .clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
            }
        }
        .overlay(
            shape.strokeBorder(
                LinearGradient(
                    colors: [
                        Color(hex: "#FFF6E4").opacity(0.42),
                        ABColor.warm.opacity(0.28),
                        Color(hex: "#C9A56A").opacity(0.18)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
        )
        .shadow(color: ABColor.warm.opacity(0.10), radius: 10, y: 5)
    }
}
