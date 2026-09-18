import SwiftUI

/// Original onboarding “doğum haritan hesaplanıyor” step — Swiss Ephemeris runs
/// underneath; this is the reveal, not a second calculator.
struct ChartCalculationStepView: View {
    let chart: NatalChart?
    let isLoading: Bool
    let errorMessage: String?
    var onBack: () -> Void
    var onContinue: () -> Void

    @State private var hasRouted = false
    @State private var minTimeElapsed = false
    @State private var spin = false
    @State private var counterSpin = false
    @State private var pulse = false
    @State private var glow = false
    @State private var phaseIndex = 0
    @State private var showSuccess = false

    private let gold = Color(hex: "#C9CFD9")
    private let phases = [
        "Gezegen konumları hesaplanıyor",
        "Evlerin hizalanışı çiziliyor",
        "Yükselen burcun bulunuyor",
        "Haritan şekilleniyor"
    ]

    var body: some View {
        ZStack {
            if let errorMessage {
                errorState(errorMessage)
            } else if showSuccess {
                ScrollView(showsIndicators: false) {
                    successState
                }
                .transition(.opacity.combined(with: .scale(scale: 0.92)))
            } else {
                creationState
            }
        }
        .onAppear { startAnimations() }
        .onChange(of: chart != nil) { _, _ in routeIfReady() }
        .onChange(of: isLoading) { _, _ in routeIfReady() }
        .onChange(of: minTimeElapsed) { _, _ in routeIfReady() }
    }

    private var creationState: some View {
        VStack(spacing: 44) {
            cosmicLoader
            VStack(spacing: 16) {
                Text("DOĞUM HARİTAN")
                    .font(ABFont.body(11, weight: .medium))
                    .tracking(3.2)
                    .foregroundStyle(gold.opacity(0.9))

                Text("AstroBond Profilin Oluşturuluyor")
                    .font(ABFont.display(22, weight: .regular))
                    .foregroundStyle(ABColor.ink)
                    .multilineTextAlignment(.center)

                Text(phases[phaseIndex])
                    .font(ABFont.body(15))
                    .foregroundStyle(ABColor.inkMuted)
                    .multilineTextAlignment(.center)
                    .id(phaseIndex)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .animation(.easeInOut(duration: 0.5), value: phaseIndex)

                HStack(spacing: 8) {
                    ForEach(0..<phases.count, id: \.self) { i in
                        Capsule()
                            .fill(i <= phaseIndex ? gold : Color.white.opacity(0.18))
                            .frame(width: i == phaseIndex ? 22 : 7, height: 7)
                            .animation(.spring(duration: 0.5), value: phaseIndex)
                    }
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 36)
        }
    }

    private var cosmicLoader: some View {
        ZStack {
            Circle()
                .stroke(gold.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [1.5, 6]))
                .frame(width: 216, height: 216)
                .overlay(orbitNodes(radius: 108, count: 16, color: gold))
                .rotationEffect(.degrees(spin ? 360 : 0))

            Circle()
                .strokeBorder(gold.opacity(0.22), lineWidth: 1)
                .frame(width: 158, height: 158)
                .overlay(orbitingDots(radius: 79, count: 3))
                .rotationEffect(.degrees(counterSpin ? -360 : 0))

            Circle()
                .fill(
                    RadialGradient(
                        colors: [gold.opacity(0.35), .clear],
                        center: .center, startRadius: 2, endRadius: 95
                    )
                )
                .frame(width: 190, height: 190)
                .scaleEffect(pulse ? 1.12 : 0.82)
                .opacity(glow ? 0.95 : 0.5)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.white, Color(hex: "#E4E8EF"), Color(hex: "#7E848F")],
                        center: .center, startRadius: 1, endRadius: 30
                    )
                )
                .frame(width: 46, height: 46)
                .shadow(color: gold.opacity(0.85), radius: glow ? 24 : 10)
                .scaleEffect(pulse ? 1.08 : 0.92)

            Text("✦")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(hex: "#23262C"))
        }
        .frame(width: 220, height: 220)
    }

    private func orbitNodes(radius: CGFloat, count: Int, color: Color) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(color.opacity(i % 2 == 0 ? 0.85 : 0.4))
                    .frame(width: i % 2 == 0 ? 4 : 2.5, height: i % 2 == 0 ? 4 : 2.5)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(count) * 360))
            }
        }
    }

    private func orbitingDots(radius: CGFloat, count: Int) -> some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 5, height: 5)
                    .shadow(color: gold.opacity(0.9), radius: 4)
                    .offset(y: -radius)
                    .rotationEffect(.degrees(Double(i) / Double(count) * 360))
            }
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Color(hex: "#9AA0AB"))
            Text(message)
                .font(ABFont.body(15))
                .foregroundStyle(Color.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            GlowCTAButton(title: "Geri Dön", action: onBack)
                .padding(.horizontal, 40)
        }
    }

    private var successState: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("ASTROBOND")
                    .font(ABFont.body(11, weight: .medium))
                    .tracking(3.2)
                    .foregroundStyle(gold.opacity(0.9))
                Text("Haritan Hazırlandı")
                    .font(ABFont.display(22, weight: .regular))
                    .foregroundStyle(ABColor.ink)
                if let chart {
                    HStack(spacing: 16) {
                        signChip("☉", chart.sunSign)
                        signChip("☽", chart.moonSign)
                        signChip("↑", chart.risingSign)
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.top, 18)
            .padding(.horizontal, 24)

            if let chart {
                ChartWheelView(chart: chart)
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .padding(8)
                    .background(Color.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            GlowCTAButton(title: "Devam Et") {
                onContinue()
            }
            .padding(.horizontal, 28)
            .padding(.top, 18)
            .padding(.bottom, 28)
        }
    }

    private func signChip(_ glyph: String, _ sign: ZodiacSign) -> some View {
        VStack(spacing: 4) {
            Text(glyph)
                .font(.system(size: 13))
                .foregroundStyle(gold)
            Text(sign.glyph)
                .font(.system(size: 22))
                .foregroundStyle(.white)
            Text(sign.labelTR)
                .font(ABFont.body(11, weight: .medium))
                .foregroundStyle(ABColor.inkMuted)
        }
    }

    private func startAnimations() {
        withAnimation(.linear(duration: 18).repeatForever(autoreverses: false)) { spin = true }
        withAnimation(.linear(duration: 12).repeatForever(autoreverses: false)) { counterSpin = true }
        withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulse = true }
        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true)) { glow = true }

        Task {
            for _ in 1..<phases.count {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                await MainActor.run {
                    if phaseIndex < phases.count - 1 { phaseIndex += 1 }
                }
            }
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            await MainActor.run { minTimeElapsed = true }
        }
    }

    private func routeIfReady() {
        guard !hasRouted, minTimeElapsed, !isLoading, chart != nil else { return }
        hasRouted = true
        withAnimation(.easeInOut(duration: 0.5)) {
            showSuccess = true
        }
    }
}
