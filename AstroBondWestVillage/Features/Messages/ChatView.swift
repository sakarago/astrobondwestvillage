import SwiftUI

@MainActor
@Observable
final class ChatViewModel {
    let conversation: ConversationSummary
    var messages: [ChatMessage] = []
    var draft = ""
    var isSending = false
    var error: String?
    var photoUnlocked = false

    private let messaging = MessagingService()
    private var observeTask: Task<Void, Never>?

    init(conversation: ConversationSummary) {
        self.conversation = conversation
    }

    func load(myUserId: String) async {
        error = nil
        do {
            messages = try await messaging.fetchMessages(conversationId: conversation.id)
            photoUnlocked = PhotoGate.isUnlocked(messageCount: messages.count)
            await messaging.markRead(conversationId: conversation.id, myUserId: myUserId)
            startObserving()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func send(myUserId: String) async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        error = nil
        defer { isSending = false }
        do {
            let msg = try await messaging.sendMessage(conversationId: conversation.id, text: text)
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
            draft = ""
            photoUnlocked = PhotoGate.isUnlocked(messageCount: messages.count)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func stop() {
        observeTask?.cancel()
        observeTask = nil
    }

    private func startObserving() {
        observeTask?.cancel()
        observeTask = Task {
            for await msg in messaging.observeMessages(conversationId: conversation.id) {
                if Task.isCancelled { break }
                if !messages.contains(where: { $0.id == msg.id }) {
                    messages.append(msg)
                    photoUnlocked = PhotoGate.isUnlocked(messageCount: messages.count)
                }
            }
        }
    }
}

struct ChatView: View {
    @Environment(SessionStore.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var model: ChatViewModel
    @FocusState private var focused: Bool

    init(conversation: ConversationSummary) {
        _model = State(initialValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        ZStack {
            CosmicBackdrop()

            VStack(spacing: 0) {
                header
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if !model.photoUnlocked {
                                Text("Gerçek fotoğraf \(PhotoGate.unlockAfterMessageCount) mesaj sonra açılır · \(model.messages.count)/\(PhotoGate.unlockAfterMessageCount)")
                                    .font(ABFont.body(12))
                                    .foregroundStyle(ABColor.inkMuted)
                                    .padding(.vertical, 8)
                            }

                            ForEach(groupedMessages, id: \.day) { group in
                                Text(group.label)
                                    .font(ABFont.body(11, weight: .semibold))
                                    .foregroundStyle(ABColor.inkMuted)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)

                                ForEach(group.messages) { msg in
                                    bubble(msg)
                                        .id(msg.id)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: model.messages.count) { _, _ in
                        if let last = model.messages.last?.id {
                            withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                }

                if let error = model.error {
                    Text(error)
                        .font(ABFont.body(12))
                        .foregroundStyle(Color(hex: "#C69A9A"))
                        .padding(.horizontal)
                }

                composer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let id = session.user?.id {
                await model.load(myUserId: id)
            }
        }
        .onDisappear { model.stop() }
    }

    private var groupedMessages: [(day: Date, label: String, messages: [ChatMessage])] {
        let cal = Calendar.current
        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateStyle = .medium
        let grouped = Dictionary(grouping: model.messages) { cal.startOfDay(for: $0.sentAt) }
        return grouped.keys.sorted().map { day in
            let label: String
            if cal.isDateInToday(day) {
                label = "Bugün"
            } else if cal.isDateInYesterday(day) {
                label = "Dün"
            } else {
                label = df.string(from: day)
            }
            return (day, label, grouped[day] ?? [])
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            PersonAvatar(
                name: model.conversation.otherName,
                photoURL: model.conversation.otherPhotoURL,
                sunSign: model.conversation.otherSunSign,
                unlocked: model.photoUnlocked,
                size: 40
            )

            VStack(alignment: .leading, spacing: 2) {
                Text(model.conversation.otherName)
                    .font(ABFont.display(18))
                    .foregroundStyle(ABColor.ink)
                if let sign = model.conversation.otherSunSign {
                    Text("\(sign.glyph) \(sign.labelTR)")
                        .font(ABFont.body(12))
                        .foregroundStyle(ABColor.inkMuted)
                }
            }
            Spacer()
            Menu {
                Button("Bağ özeti yakında") {}
                Button("Sessize al", role: .none) {}
                Button("Engelle", role: .destructive) {}
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ABColor.ink)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial.opacity(0.35))
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        let mine = msg.senderId == session.user?.id
        return HStack {
            if mine { Spacer(minLength: 40) }
            Text(msg.text)
                .font(ABFont.body(15))
                .foregroundStyle(ABColor.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(mine ? ABColor.lavender.opacity(0.32) : Color.white.opacity(0.08))
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(mine ? 0.25 : 0.12), lineWidth: 1)
                )
            if !mine { Spacer(minLength: 40) }
        }
    }

    private var canSend: Bool {
        !model.isSending && !model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Mesaj yaz…", text: $model.draft, axis: .vertical)
                .lineLimit(1...5)
                .font(ABFont.body(15))
                .foregroundStyle(ABColor.ink)
                .tint(ABColor.lavenderSoft)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    Capsule(style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    Capsule(style: .continuous)
                        .fill(Color.white.opacity(0.05))
                }
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(focused ? 0.55 : 0.32),
                                    ABColor.lavenderSoft.opacity(focused ? 0.5 : 0.22),
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: focused ? 1.4 : 1
                        )
                )
                .shadow(color: Color.black.opacity(0.28), radius: 10, y: 4)
                .animation(.easeOut(duration: 0.18), value: focused)
                .focused($focused)

            Button {
                Task {
                    if let id = session.user?.id {
                        await model.send(myUserId: id)
                    }
                }
            } label: {
                Image(systemName: model.isSending ? "hourglass" : "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(canSend ? Color(hex: "#15131F") : ABColor.inkMuted.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background {
                        Circle().fill(
                            canSend
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [ABColor.lavenderSoft, ABColor.lavender],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                : AnyShapeStyle(Color.white.opacity(0.07))
                        )
                    }
                    .overlay(
                        Circle().strokeBorder(Color.white.opacity(canSend ? 0.55 : 0.12), lineWidth: 1.1)
                    )
                    .shadow(color: canSend ? ABColor.lavender.opacity(0.55) : .clear, radius: 12, y: 5)
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .animation(.spring(response: 0.32, dampingFraction: 0.7), value: canSend)
        }
        .padding(.horizontal, 14)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(0.6)
            LinearGradient(
                colors: [Color(hex: "#0A0810").opacity(0), Color(hex: "#0A0810").opacity(0.5)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.18), Color.white.opacity(0.03)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
    }
}
