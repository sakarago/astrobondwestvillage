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
                ProgressView()
                    .tint(ABColor.lavenderSoft)
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .crystalPlate(cornerRadius: 26)
                    .accessibilityLabel(category.title)
            } else if let question, let category {
                questionCard(question)
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
        .onAppear { remaining = DailyQuestionQuotaStore.shared.remaining(for: userId) }
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
                .foregroundStyle(ABColor.lavenderSoft)
            Text(question == nil ? "Bir Soru Keşfet" : "Sana Özel Soru")
                .font(ABFont.display(24, weight: .regular))
                .foregroundStyle(ABColor.ink)
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Text("Bugün").font(ABFont.body(10)).foregroundStyle(ABColor.inkMuted)
                Text("\(remaining)")
                    .font(ABFont.display(26, weight: .regular))
                    .foregroundStyle(ABColor.lavenderSoft)
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
                    VStack(spacing: 8) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 26, weight: .light))
                            .foregroundStyle(ABColor.lavenderSoft)
                        Text(cat.title)
                            .font(ABFont.body(16, weight: .semibold))
                            .foregroundStyle(ABColor.ink)
                        Text(cat.subtitle)
                            .font(ABFont.body(11))
                            .foregroundStyle(ABColor.inkMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity, minHeight: 128)
                    .crystalPlate(cornerRadius: 22)
                    .opacity(remaining == 0 ? 0.5 : 1)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func questionCard(_ text: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "sparkle")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(ABColor.lavenderSoft)
            Text(text)
                .font(ABFont.display(24, weight: .regular))
                .foregroundStyle(ABColor.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 240)
        .crystalPlate(cornerRadius: 26)
        .id(text)
        .transition(.opacity)
    }

    private func actions(category: QuestionCategory, question: String) -> some View {
        VStack(spacing: 12) {
            CrystalCTAButton(title: "Sohbette Paylaş") {
                onShare(question)
                dismiss()
            }
            Button {
                reroll(category, current: question)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "shuffle")
                    Text("Başka Soru Göster")
                }
                .font(ABFont.body(16, weight: .semibold))
                .foregroundStyle(ABColor.ink)
                .frame(maxWidth: .infinity, minHeight: 54)
                .crystalPlate(cornerRadius: 27)
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
