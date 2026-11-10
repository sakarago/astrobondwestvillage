import SwiftUI

/// "Bir Soru Keşfet" panel → "Sana Özel Soru" card, shown over the chat.
struct QuestionDiscoverSheet: View {
    @Environment(\.dismiss) private var dismiss
    let userId: String
    /// Sends the question as a chat message.
    let onShare: (String) -> Void

    @State private var remaining = 0
    @State private var category: QuestionCategory?
    @State private var question: String?
    @State private var showLimit = false
    @State private var isLoading = false

    var body: some View {
        VStack(spacing: 16) {
            header
            if let category, isLoading, question == nil {
                questionSubtitle
                ProgressView()
                    .tint(Color(hex: "#F3C6D6"))
                    .frame(maxWidth: .infinity, minHeight: 330)
                    .background { cardBackground(category) }
                    .accessibilityLabel(category.title)
            } else if let question, let category {
                questionSubtitle
                questionCard(question, category: category)
                    .opacity(isLoading ? 0.4 : 1)
                actions(category: category, question: question)
                    .disabled(isLoading)
            } else {
                Text("Birbirinizi daha iyi tanımanız için seçilmiş sorulardan birini keşfet.")
                    .font(ABFont.body(13))
                    .foregroundStyle(ABColor.inkMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                grid
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background { CosmicBackdrop().ignoresSafeArea() }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .onAppear { remaining = DailyQuestionQuotaStore.shared.remaining(for: userId)
        }
        .alert("Günlük soru hakkın doldu", isPresented: $showLimit) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text("Kullanılmayan haklar ertesi güne devretmez. Yarın yeniden dene.")
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: question == nil ? "sparkle" : "sparkles")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(Color.adaptive(light: "#C0708E", dark: "#F3C6D6"))
            Text(question == nil ? "Bir Soru Keşfet" : "Sana Özel Soru")
                .font(ABFont.display(24, weight: .regular))
                .foregroundStyle(ABColor.ink)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text("Bugün").font(ABFont.body(10)).foregroundStyle(ABColor.inkMuted)
                Text("\(remaining)")
                    .font(ABFont.display(26, weight: .regular))
                    .foregroundStyle(Color.adaptive(light: "#C0708E", dark: "#F3C6D6"))
                Text("soru hakkın var.").font(ABFont.body(9)).foregroundStyle(ABColor.inkMuted)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ABColor.inkMuted)
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Kapat")
        }
    }

    private var grid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            ForEach(QuestionCategory.allCases) { cat in
                Button { pick(cat) } label: {
                    let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
                    ZStack {
                        Color.clear
                            .overlay { Image("q_\(cat.rawValue)").resizable().scaledToFill() }
                            .clipShape(shape)
                        shape.fill(LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.55)], startPoint: .top, endPoint: .bottom))
                        VStack(spacing: 6) {
                            Image(systemName: cat.icon)
                                .symbolRenderingMode(.monochrome)
                                .font(.system(size: 28, weight: .light))
                                .foregroundStyle(Color(hex: "#F3C6D6"))
                                .shadow(color: .black.opacity(0.4), radius: 4)
                            Text(cat.title)
                                .font(ABFont.display(18, weight: .regular))
                                .foregroundStyle(.white)
                            Text(cat.subtitle)
                                .font(ABFont.body(11))
                                .foregroundStyle(.white.opacity(0.82))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 8).padding(.top, 38)
                        shape.strokeBorder(
                            LinearGradient(colors: [Color(hex: "#E8B9A6").opacity(0.75), Color(hex: "#8B6E7E").opacity(0.4)],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                    }
                    .frame(height: 164)
                    .clipShape(shape)
                    .opacity(remaining == 0 ? 0.5 : 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func cardBackground(_ cat: QuestionCategory) -> some View {
        let shape = RoundedRectangle(cornerRadius: 26, style: .continuous)
        return ZStack {
            Color.clear.overlay { Image("q_\(cat.rawValue)").resizable().scaledToFill() }.clipShape(shape)
            shape.fill(LinearGradient(colors: [.black.opacity(0.15), .black.opacity(0.45)], startPoint: .top, endPoint: .bottom))
            shape.strokeBorder(
                LinearGradient(colors: [Color(hex: "#E8B9A6").opacity(0.7), Color(hex: "#8B6E7E").opacity(0.35)],
                               startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        }
    }

    private var questionSubtitle: some View {
        Text("Bu soru, birbirinizi daha iyi tanımanız için seçildi. Dilerseniz sohbetinizde paylaşın.")
            .font(ABFont.body(13))
            .foregroundStyle(ABColor.inkMuted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func questionCard(_ text: String, category: QuestionCategory) -> some View {
        VStack(spacing: 22) {
            Image(systemName: "sparkle")
                .font(.system(size: 34, weight: .ultraLight))
                .foregroundStyle(Color(hex: "#F1C9A0"))
                .shadow(color: Color(hex: "#F1C9A0").opacity(0.8), radius: 8)
            Text(text)
                .font(ABFont.display(26, weight: .regular))
                .foregroundStyle(Color(hex: "#F3D9D0"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                Capsule().fill(Color(hex: "#E8B9A6").opacity(0.6)).frame(width: 52, height: 1)
                Circle().strokeBorder(Color(hex: "#E8B9A6"), lineWidth: 1).frame(width: 6, height: 6)
                Capsule().fill(Color(hex: "#E8B9A6").opacity(0.6)).frame(width: 52, height: 1)
            }
        }
        .padding(.horizontal, 28).padding(.vertical, 34)
        .frame(maxWidth: .infinity, minHeight: 330)
        .background { cardBackground(category) }
        .id(text)
        .transition(.opacity)
    }

    private func actions(category: QuestionCategory, question: String) -> some View {
        VStack(spacing: 12) {
            Button {
                onShare(question)
                dismiss()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "paperplane")
                    Text("Sohbette Paylaş")
                }
                .font(ABFont.display(19, weight: .regular))
                .foregroundStyle(Color(hex: "#FFF1EA"))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(
                    Capsule().fill(LinearGradient(colors: [Color(hex: "#8A6068").opacity(0.75), Color(hex: "#3B2330").opacity(0.85)],
                                                  startPoint: .top, endPoint: .bottom))
                )
                .overlay(Capsule().strokeBorder(Color(hex: "#F0B9A8").opacity(0.9), lineWidth: 1.2))
                .shadow(color: Color(hex: "#E8A090").opacity(0.45), radius: 14)
            }
            .buttonStyle(.plain)
            Button {
                reroll(category, current: question)
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "shuffle")
                    Text("Başka Soru Göster")
                }
                .font(ABFont.display(18, weight: .regular))
                .foregroundStyle(Color(hex: "#F3D9D0"))
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Capsule().fill(Color.white.opacity(0.04)))
                .overlay(Capsule().strokeBorder(Color(hex: "#E8B9A6").opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func pick(_ cat: QuestionCategory) {
        load(cat, current: nil)
    }

    private func reroll(_ cat: QuestionCategory, current: String) {
        load(cat, current: current)
    }

    private func load(_ cat: QuestionCategory, current: String?) {
        guard !isLoading else { return }
        guard DailyQuestionQuotaStore.shared.consume(for: userId) else {
            showLimit = true
            return
        }
        remaining = DailyQuestionQuotaStore.shared.remaining(for: userId)
        isLoading = true
        category = cat
        Task {
            let next = await ConversationQuestions.next(in: cat, excluding: current)
            withAnimation(.easeInOut(duration: 0.25)) {
                question = next
                isLoading = false
            }
        }
    }
}
