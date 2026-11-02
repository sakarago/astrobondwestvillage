import SwiftUI
import UIKit

@MainActor
@Observable
final class ChatViewModel {
    let conversation: ConversationSummary
    var messages: [ChatMessage] = []
    var isSending = false
    var error: String?
    var photoUnlocked = false
    var mySun: ZodiacSign?
    var myMoon: ZodiacSign?
    var myRising: ZodiacSign?
    var myName: String = "Sen"
    var myPhotoURL: String?
    var myCartoonAvatarId: String?
    var showBondSummary = false
    var myChart: NatalChart?

    private let messaging = MessagingService()
    private let profiles = ProfileService()
    private var observeTask: Task<Void, Never>?

    init(conversation: ConversationSummary) {
        self.conversation = conversation
    }

    var otherAsCard: MatchCard {
        MatchCard(
            id: conversation.otherUserId,
            displayName: conversation.otherName,
            age: 0,
            city: nil,
            sunSign: conversation.otherSunSign,
            moonSign: nil,
            risingSign: nil,
            bio: "",
            photoURL: conversation.otherPhotoURL,
            cartoonAvatarId: conversation.otherCartoonAvatarId
        )
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
        if let snap = try? await profiles.fetchSnapshot(userId: myUserId) {
            mySun = snap.sunSign
            myMoon = snap.moonSign
            myRising = snap.risingSign
            if !snap.displayName.trimmingCharacters(in: .whitespaces).isEmpty {
                myName = snap.displayName
            }
            myPhotoURL = snap.photoURL
            myCartoonAvatarId = snap.cartoonAvatarId
        }
        myChart = try? await ChartService.shared.ensureOwnChart(userId: myUserId)
    }

    func send(myUserId: String, text: String) async -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return false }
        isSending = true
        error = nil
        defer { isSending = false }
        do {
            let msg = try await messaging.sendMessage(conversationId: conversation.id, text: trimmed)
            if !messages.contains(where: { $0.id == msg.id }) {
                messages.append(msg)
            }
            photoUnlocked = PhotoGate.isUnlocked(messageCount: messages.count)
            return true
        } catch {
            self.error = error.localizedDescription
            return false
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
    @Environment(\.hideTabBar) private var hideTabBar
    var onBack: (() -> Void)? = nil
    @State private var model: ChatViewModel
    @State private var draft = ""
    @State private var keyboardPad: CGFloat = 0
    @State private var isComposerFocused = false
    @State private var showSinastri = false
    @State private var showQuestions = false

    init(conversation: ConversationSummary, onBack: (() -> Void)? = nil) {
        self.onBack = onBack
        _model = State(initialValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        @Bindable var model = model
        Group {
            if showSinastri {
                MatchDetailSheet(
                    card: model.otherAsCard,
                    mySeed: session.user?.id ?? "self",
                    myName: model.myName,
                    myPhotoURL: model.myPhotoURL,
                    myCartoonAvatarId: model.myCartoonAvatarId,
                    mySun: model.mySun,
                    myMoon: model.myMoon,
                    myRising: model.myRising,
                    seedChart: model.myChart,
                    intent: MatchPrefsStore.shared.snapshot.intent,
                    onBack: { showSinastri = false }
                )
            } else {
                chatStack
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showQuestions) {
            QuestionDiscoverSheet(userId: session.user?.id ?? "self") { question in
                send(question)
            }
        }
        .task {
            hideTabBar?.wrappedValue = true
            if let id = session.user?.id {
                await model.load(myUserId: id)
            }
        }
        .onAppear { hideTabBar?.wrappedValue = true }
        .onDisappear {
            hideTabBar?.wrappedValue = false
            model.stop()
        }
    }

    private var chatStack: some View {
        VStack(spacing: 0) {
            header

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 18) {
                        if !model.photoUnlocked {
                            Text("Gerçek fotoğraf \(PhotoGate.unlockAfterMessageCount) mesaj sonra açılır · \(model.messages.count)/\(PhotoGate.unlockAfterMessageCount)")
                                .font(ABFont.body(12))
                                .foregroundStyle(ABColor.inkMuted)
                                .padding(.vertical, 8)
                        }

                        ForEach(groupedMessages, id: \.day) { group in
                            Text(group.label)
                                .font(ABFont.body(12, weight: .semibold))
                                .foregroundStyle(ABColor.inkMuted)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.white.opacity(0.06)))
                                .overlay(Capsule().strokeBorder(ABColor.lavenderSoft.opacity(0.6), lineWidth: 1))
                                .frame(maxWidth: .infinity)

                            ForEach(group.messages) { msg in
                                bubble(msg)
                                    .id(msg.id)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .scrollDismissesKeyboard(.interactively)
                .simultaneousGesture(TapGesture().onEnded { resignKeyboard() })
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
            }

            composer
                .padding(.bottom, keyboardPad)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .background {
            CosmicBackdrop()
                .ignoresSafeArea(.container)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) { note in
            let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
            withAnimation(.easeOut(duration: duration)) { keyboardPad = Self.bottomPad(for: note) }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.2)) { keyboardPad = 0 }
        }
    }

    private static func bottomPad(for note: Notification) -> CGFloat {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return 0 }
        let screen = UIScreen.main.bounds.height
        let keyboard = max(0, screen - frame.minY)
        guard keyboard > 1 else { return 0 }
        let home = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 34
        return max(0, keyboard - home)
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

    private func resignKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func goBack() {
        resignKeyboard()
        hideTabBar?.wrappedValue = false
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button(action: goBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ABColor.lavender)
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Geri")

            Spacer(minLength: 0)

            Button {
                resignKeyboard()
                showSinastri = true
            } label: {
                HStack(spacing: 10) {
                    PersonAvatar(
                        name: model.conversation.otherName,
                        photoURL: model.conversation.otherPhotoURL,
                        cartoonAvatarId: model.conversation.otherCartoonAvatarId,
                        sunSign: model.conversation.otherSunSign,
                        unlocked: model.photoUnlocked,
                        size: 44
                    )
                    VStack(spacing: 1) {
                        Text(model.conversation.otherName)
                            .font(ABFont.display(20))
                            .foregroundStyle(ABColor.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text("Sinastriyi gör")
                            .font(ABFont.body(12, weight: .medium))
                            .foregroundStyle(ABColor.inkMuted)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                circleIcon("phone")
                Menu {
                    Button("Profili Görüntüle", systemImage: "person") {
                        resignKeyboard()
                        showSinastri = true
                    }
                    Button("Sessize Al", systemImage: "bell.slash") {}
                    Button("Engelle", systemImage: "hand.raised", role: .destructive) {}
                } label: {
                    circleIcon("ellipsis")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            Color(hex: "#0A0A0C").opacity(0.7)
                .background(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        }
    }

    private func circleIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(ABColor.lavender)
            .frame(width: 38, height: 38)
            .background(Circle().fill(Color.white.opacity(0.06)))
            .overlay(Circle().strokeBorder(ABColor.lavenderSoft.opacity(0.7), lineWidth: 1))
            .shadow(color: ABColor.lavender.opacity(0.22), radius: 8)
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        let mine = msg.senderId == session.user?.id
        return HStack(alignment: .bottom, spacing: 10) {
            if mine {
                Spacer(minLength: 48)
                bubbleBody(msg, mine: true)
            } else {
                PersonAvatar(
                    name: model.conversation.otherName,
                    photoURL: model.conversation.otherPhotoURL,
                    cartoonAvatarId: model.conversation.otherCartoonAvatarId,
                    sunSign: model.conversation.otherSunSign,
                    unlocked: model.photoUnlocked,
                    size: 40
                )
                bubbleBody(msg, mine: false)
                Spacer(minLength: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private func bubbleBody(_ msg: ChatMessage, mine: Bool) -> some View {
        VStack(alignment: mine ? .trailing : .leading, spacing: 6) {
            Text(msg.text)
                .font(ABFont.body(16))
                .foregroundStyle(ABColor.ink)
                .multilineTextAlignment(mine ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                Text(timeString(msg.sentAt))
                    .font(ABFont.body(11))
                    .foregroundStyle(ABColor.inkMuted)
                if mine {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(ABColor.lavender)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: 280, alignment: mine ? .trailing : .leading)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(mine ? ABColor.lavender.opacity(0.18) : Color.white.opacity(0.06))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [ABColor.lavenderSoft, ABColor.lavender.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.1
                )
        )
        .shadow(color: ABColor.lavender.opacity(0.22), radius: 10)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private var canSend: Bool {
        !model.isSending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button {
                resignKeyboard()
                showQuestions = true
            } label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(ABColor.lavenderSoft)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                    .overlay(Circle().strokeBorder(ABColor.lavenderSoft.opacity(0.8), lineWidth: 1.2))
                    .shadow(color: ABColor.lavender.opacity(0.4), radius: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Soru keşfet")

            ChatComposerField(
                text: $draft,
                placeholder: "Mesaj yaz...",
                isFocused: $isComposerFocused,
                onSubmit: sendTapped
            )
            .frame(minHeight: 22, maxHeight: 72)

            Button(action: canSend ? sendTapped : resignKeyboard) {
                Image(systemName: canSend ? "paperplane.fill" : "chevron.down")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(canSend || isComposerFocused ? Color.white : ABColor.inkMuted)
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
                                : AnyShapeStyle(Color.white.opacity(isComposerFocused ? 0.12 : 0.06))
                        )
                    }
                    .overlay(Circle().strokeBorder(ABColor.lavenderSoft.opacity(0.7), lineWidth: 1))
                    .shadow(color: ABColor.lavender.opacity(canSend ? 0.28 : 0.12), radius: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canSend && !isComposerFocused)
            .accessibilityLabel(canSend ? "Gönder" : "Klavye kapat")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Capsule(style: .continuous).fill(Color.white.opacity(0.06)))
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [ABColor.lavenderSoft, ABColor.lavender.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
        )
        .shadow(color: ABColor.lavender.opacity(0.18), radius: 12)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    private func sendTapped() {
        let text = draft
        send(text) { draft = "" }
    }

    private func send(_ text: String, onSuccess: @escaping () -> Void = {}) {
        Task {
            guard let id = session.user?.id else {
                model.error = "Oturum bulunamadı."
                return
            }
            if await model.send(myUserId: id, text: text) {
                onSuccess()
                ConversationsStore.shared.upsert(
                    ConversationSummary(
                        id: model.conversation.id,
                        otherUserId: model.conversation.otherUserId,
                        otherName: model.conversation.otherName,
                        otherPhotoURL: model.conversation.otherPhotoURL,
                        otherCartoonAvatarId: model.conversation.otherCartoonAvatarId,
                        otherSunSign: model.conversation.otherSunSign,
                        lastMessage: text,
                        lastMessageAt: Date(),
                        unreadCount: 0
                    )
                )
            }
        }
    }
}

/// UIKit field so typing/focus isn't swallowed by SwiftUI material, keyboard
/// insets, or parent view refreshes — the SwiftUI TextField here kept
/// vanishing or refusing first responder.
private struct ChatComposerField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    @Binding var isFocused: Bool
    var onSubmit: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, isFocused: $isFocused, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.textColor = .white
        field.tintColor = UIColor(red: 0.79, green: 0.72, blue: 1.0, alpha: 1)
        field.font = .systemFont(ofSize: 16, weight: .regular)
        field.returnKeyType = .send
        field.autocorrectionType = .yes
        field.autocapitalizationType = .sentences
        field.enablesReturnKeyAutomatically = true
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.42)]
        )
        field.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged), for: .editingChanged)
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    func updateUIView(_ field: UITextField, context: Context) {
        context.coordinator.text = $text
        context.coordinator.isFocused = $isFocused
        context.coordinator.onSubmit = onSubmit
        if field.text != text {
            field.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>
        var isFocused: Binding<Bool>
        var onSubmit: () -> Void

        init(text: Binding<String>, isFocused: Binding<Bool>, onSubmit: @escaping () -> Void) {
            self.text = text
            self.isFocused = isFocused
            self.onSubmit = onSubmit
        }

        @objc func editingChanged(_ field: UITextField) {
            text.wrappedValue = field.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            isFocused.wrappedValue = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            isFocused.wrappedValue = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let trimmed = (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                textField.resignFirstResponder()
                return true
            }
            onSubmit()
            return false
        }
    }
}
