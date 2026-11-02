import Foundation

@MainActor
final class NotificationPrefsStore {
    static let shared = NotificationPrefsStore()
    private let d = UserDefaults.standard

    var dailyInsight: Bool {
        get { d.object(forKey: "wv.n.insight") as? Bool ?? true }
        set { d.set(newValue, forKey: "wv.n.insight") }
    }
    var newMatches: Bool {
        get { d.object(forKey: "wv.n.match") as? Bool ?? true }
        set { d.set(newValue, forKey: "wv.n.match") }
    }
    var messages: Bool {
        get { d.object(forKey: "wv.n.msg") as? Bool ?? true }
        set { d.set(newValue, forKey: "wv.n.msg") }
    }
    var transits: Bool {
        get { d.object(forKey: "wv.n.transit") as? Bool ?? true }
        set { d.set(newValue, forKey: "wv.n.transit") }
    }
    var privateAccount: Bool {
        get { d.bool(forKey: "wv.n.private") }
        set { d.set(newValue, forKey: "wv.n.private") }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case tr
    var id: String { rawValue }
    var displayName: String { "Türkçe" }
}

@MainActor
final class AppLanguageStore {
    static let shared = AppLanguageStore()
    private let key = "wv.lang"
    var language: AppLanguage {
        get { AppLanguage(rawValue: UserDefaults.standard.string(forKey: key) ?? "tr") ?? .tr }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }
}
