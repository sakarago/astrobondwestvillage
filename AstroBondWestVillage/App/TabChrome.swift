import SwiftUI

private struct HideTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    var hideTabBar: Binding<Bool>? {
        get { self[HideTabBarKey.self] }
        set { self[HideTabBarKey.self] = newValue }
    }
}

private struct ActiveTabKey: EnvironmentKey {
    static let defaultValue: Binding<Int>? = nil
}

extension EnvironmentValues {
    /// Lets a tab body observe which tab is currently selected, even though
    /// `MainTabView` keeps all four tab bodies mounted at once (it toggles
    /// opacity rather than swapping views) — without this, a tab's own
    /// `.task` only ever runs once and can't tell when it becomes active again.
    var activeTab: Binding<Int>? {
        get { self[ActiveTabKey.self] }
        set { self[ActiveTabKey.self] = newValue }
    }
}

private struct CompactTabBarKey: EnvironmentKey {
    static let defaultValue: Binding<Bool>? = nil
}

extension EnvironmentValues {
    /// Shrinks the floating tab bar while the Eşleşme wheel is spinning or
    /// showing a reveal, matching the original Cosmic Match chrome.
    var compactTabBar: Binding<Bool>? {
        get { self[CompactTabBarKey.self] }
        set { self[CompactTabBarKey.self] = newValue }
    }
}
