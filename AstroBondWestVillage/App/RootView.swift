import SwiftUI
import UIKit

struct RootView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            switch session.phase {
            case .loading:
                ZStack {
                    CosmicBackdrop()
                    ProgressView()
                        .tint(ABColor.lavenderSoft)
                }
            case .welcome:
                WelcomeView()
            case .onboarding:
                OnboardingFlowView()
            case .main:
                MainTabView()
            }
        }
        .environment(\.locale, Locale(identifier: "tr_TR"))
        .preferredColorScheme(.dark)
        .background(SwipeUpHidesKeyboard())
        .animation(.easeInOut(duration: 0.28), value: session.phase)
        .task {
            AppLanguageStore.shared.language = .tr
            await session.bootstrap()
        }
        .onOpenURL { url in
            Task { await session.handleAuthURL(url) }
        }
        .sheet(isPresented: Binding(
            get: { session.showResetSheet },
            set: { presented in
                if !presented {
                    Task { await session.cancelPasswordReset() }
                }
            }
        )) {
            ResetPasswordSheet()
                .onOpenURL { url in
                    Task { await session.handleAuthURL(url) }
                }
        }
    }
}

#Preview {
    RootView()
        .environment(SessionStore())
}

/// Swipe up anywhere, including sheets, drops the keyboard without pressing return.
private struct SwipeUpHidesKeyboard: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.install(on: uiView)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private var observer: NSObjectProtocol?

        deinit {
            if let observer { NotificationCenter.default.removeObserver(observer) }
        }

        func install(on view: UIView) {
            if observer == nil {
                observer = NotificationCenter.default.addObserver(
                    forName: UIWindow.didBecomeVisibleNotification,
                    object: nil,
                    queue: .main
                ) { [weak self] note in
                    guard let window = note.object as? UIWindow else { return }
                    self?.addGesture(to: window)
                }
            }
            DispatchQueue.main.async { [weak self, weak view] in
                guard let window = view?.window else { return }
                self?.addGesture(to: window)
            }
        }

        private func addGesture(to window: UIWindow) {
            let name = "astrobond.swipeUpHidesKeyboard"
            if window.gestureRecognizers?.contains(where: { $0.name == name }) == true { return }
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handle))
            pan.name = name
            pan.cancelsTouchesInView = false
            pan.delaysTouchesBegan = false
            pan.delaysTouchesEnded = false
            pan.delegate = self
            window.addGestureRecognizer(pan)
        }

        @objc private func handle(_ pan: UIPanGestureRecognizer) {
            guard pan.state == .ended, let view = pan.view else { return }
            let travel = pan.translation(in: view)
            let speed = pan.velocity(in: view)
            guard travel.y < -36, abs(travel.y) > abs(travel.x), speed.y < 0 else { return }
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
