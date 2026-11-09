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
                                .foregroundStyle(Self.roseSoft)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.black.opacity(0.35)))
                                .overlay(Capsule().strokeBorder(Self.rose.opacity(0.45), lineWidth: 1))
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
            Color.clear
                .overlay { Image("chat_bg").resizable().scaledToFill() }
                .clipped()
                .overlay(Color.black.opacity(0.22))
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

    private static let rose = Color(hex: "#E8B9A0")
    private static let roseSoft = Color(hex: "#F3D9C8")

    private var astroScore: Int {
        BondStory.report(
            mySun: model.mySun,
            their: model.otherAsCard,
            intent: MatchPrefsStore.shared.snapshot.intent,
            myChart: model.myChart,
            theirChart: nil
        ).overall
    }

    private func openSinastri() {
        resignKeyboard()
        showSinastri = true
    }

    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                AstroBondLogoMark(flare: true)
                HStack {
                    Button(action: goBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 19, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Geri")
                    Spacer()
                }
            }

            HStack(spacing: 12) {
                Button(action: openSinastri) {
                    HStack(spacing: 12) {
                        PersonAvatar(
                            name: model.conversation.otherName,
                            photoURL: model.conversation.otherPhotoURL,
                            cartoonAvatarId: model.conversation.otherCartoonAvatarId,
                            sunSign: model.conversation.otherSunSign,
                            unlocked: model.photoUnlocked,
                            size: 54
                        )
                        .overlay(Circle().strokeBorder(Self.rose, lineWidth: 1.6))
                        .shadow(color: Self.rose.opacity(0.35), radius: 8)

                        HStack(spacing: 6) {
                            Text(model.conversation.otherName)
                                .font(ABFont.display(21, weight: .regular))
                                .foregroundStyle(Color.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                            Text("☾").font(.system(size: 15)).foregroundStyle(Self.roseSoft)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ortak sinastriyi aç")

                Spacer(minLength: 8)

                Button(action: openSinastri) {
                    VStack(spacing: 2) {
                        HStack(spacing: 6) {
                            Image(systemName: "heart")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: "#F28B82"))
                            Text("%\(astroScore)")
                                .font(ABFont.display(20, weight: .regular))
                                .foregroundStyle(Color.white)
                        }
                        Text("Astro Uyum")
                            .font(ABFont.body(12, weight: .medium))
                            .foregroundStyle(Self.roseSoft.opacity(0.85))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.black.opacity(0.4)))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(Self.rose.opacity(0.55), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
        .padding(.bottom, 10)
        .background {
            LinearGradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.35)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)
        }
    }

    private func bubble(_ msg: ChatMessage) -> some View {
        let mine = msg.senderId == session.user?.id
        return HStack(alignment: .bottom, spacing: 10) {
            if mine {
                Spacer(minLength: 48)
                bubbleBody(msg, mine: true)
            } else {
                bubbleBody(msg, mine: false)
                Spacer(minLength: 48)
            }
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private func bubbleBody(_ msg: ChatMessage, mine: Bool) -> some View {
        let ink = Color(hex: "#2B2237")
        return VStack(alignment: mine ? .trailing : .leading, spacing: 6) {
            Text(msg.text)
                .font(ABFont.display(17, weight: .regular))
                .foregroundStyle(mine ? Color(hex: "#F6E9E1") : ink)
                .multilineTextAlignment(mine ? .trailing : .leading)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 5) {
                Text(timeString(msg.sentAt))
                    .font(ABFont.body(11))
                    .foregroundStyle(mine ? Self.roseSoft.opacity(0.7) : ink.opacity(0.5))
                if mine {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Self.rose)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 13)
        .frame(maxWidth: 300, alignment: mine ? .trailing : .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(mine ? Color.black.opacity(0.52) : Color(hex: "#D9C2B8").opacity(0.94))
        }
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(mine ? Self.rose.opacity(0.4) : Color.white.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, y: 3)
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
        HStack(spacing: 10) {
            ChatComposerField(
                text: $draft,
                placeholder: "Mesaj yaz...",
                isFocused: $isComposerFocused,
                onSubmit: sendTapped
            )
            .frame(height: 22)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule(style: .continuous).fill(Color.black.opacity(0.42)))
            .overlay(Capsule(style: .continuous).strokeBorder(Self.rose.opacity(0.45), lineWidth: 1))

            Button {
                resignKeyboard()
                showQuestions = true
            } label: {
                Image(systemName: "sparkle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .shadow(color: Self.roseSoft, radius: 6)
                    .frame(width: 54, height: 54)
                    .background(Circle().fill(Color.black.opacity(0.5)))
                    .overlay(
                        Circle().strokeBorder(
                            LinearGradient(colors: [Color(hex: "#FFE3CF"), Self.rose, Color(hex: "#C98A6E")], startPoint: .top, endPoint: .bottom),
                            lineWidth: 2.2
                        )
                    )
                    .shadow(color: Self.rose.opacity(0.7), radius: 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Soru keşfet")

            Button(action: canSend ? sendTapped : resignKeyboard) {
                Image(systemName: canSend ? "paperplane.fill" : (isComposerFocused ? "chevron.down" : "paperplane"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(canSend ? Color(hex: "#2B2237") : Color.white)
                    .frame(width: 46, height: 46)
                    .background {
                        Circle().fill(canSend ? AnyShapeStyle(Self.rose) : AnyShapeStyle(Color.black.opacity(0.45)))
                    }
                    .overlay(Circle().strokeBorder(Self.rose.opacity(0.55), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(!canSend && !isComposerFocused)
            .accessibilityLabel(canSend ? "Gönder" : "Klavye kapat")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background {
            LinearGradient(colors: [.clear, Color.black.opacity(0.55)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        }
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
        field.tintColor = UIColor(red: 0.91, green: 0.73, blue: 0.63, alpha: 1)
        field.font = UIFont(descriptor: UIFont.systemFont(ofSize: 16).fontDescriptor.withDesign(.serif) ?? UIFont.systemFont(ofSize: 16).fontDescriptor, size: 16)
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
