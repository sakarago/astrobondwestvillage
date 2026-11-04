import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// On-device AI (Apple Foundation Models — free, private, offline) that turns the template notes in
/// `DiscoverContent` into richer, chart-specific prose. Falls back to the template text whenever the model
/// isn't available (older iPhone, Apple Intelligence off, non-Turkish locale, timeout, odd output).
/// Results are cached per user + day + note, so a page reads the same all day and opens instantly next time.
enum DiscoverAI {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return false }
        let model = SystemLanguageModel.default
        guard case .available = model.availability else { return false }
        return model.supportsLocale(Locale(identifier: "tr_TR"))
        #else
        return false
        #endif
    }

    // MARK: Public

    /// Returns the note with AI-written intro/sections, or the original note if AI can't help.
    /// `didUseAI` tells the UI whether to show the "yapay zekâ" label.
    static func enrich(_ note: DiscoverNote, sky: UserSky) async -> (note: DiscoverNote, usedAI: Bool) {
        guard !note.sections.isEmpty, note.sections.count <= 6 else { return (note, false) }
        let draft = note.sections.enumerated().map { "\($0.offset + 1). \($0.element.heading): \($0.element.text)" }.joined(separator: "\n")
        let facts = """
        Sayfa: \(note.title) (\(note.eyebrow))
        Taslak giriş: \(note.intro)
        Taslak bölümler:
        \(draft)
        """
        let task = """
        Yukarıdaki taslağı bu kişiye özel, zengin ve sıcak bir anlatıma dönüştür. Tam olarak \(note.sections.count + 1) paragraf yaz: \
        önce 1 giriş paragrafı, sonra taslaktaki bölümlerin her biri için sırayla birer paragraf. \
        Taslaktaki bilgileri (burç, ev, tarih, sayı) koru; kişinin haritasındaki burçlara somut göndermeler yap.
        """
        let key = "note.\(stable("\(note.eyebrow)|\(note.title)"))"
        guard let parts = await parts(key: key, sky: sky, facts: facts, task: task, count: note.sections.count + 1) else {
            return (note, false)
        }
        var out = note
        out = DiscoverNote(
            backdrop: note.backdrop, icon: note.icon, eyebrow: note.eyebrow, title: note.title, intro: parts[0],
            sections: zip(note.sections, parts.dropFirst()).map { NoteSection(heading: $0.heading, text: $1) }
        )
        return (out, true)
    }

    /// Rich version of the daily card result: title, message body and a reflective question.
    static func cardResult(_ base: DiscoverContent.CardResult, card: Int, sky: UserSky) async -> (result: DiscoverContent.CardResult, usedAI: Bool) {
        let which = ["Güneş", "Ay", "Yükselen"][min(max(card, 0), 2)]
        let facts = """
        Çekilen kart: \(which) Kartı
        Taslak başlık: \(base.title)
        Taslak mesaj: \(base.body)
        Taslak soru: \(base.question)
        """
        let task = """
        Bu kişiye bugünün kartı için özel bir mesaj yaz. Tam olarak 3 parça yaz: \
        1) en fazla 9 kelimelik şiirsel bir başlık, 2) 3-4 cümlelik sıcak ve somut bir mesaj \
        (kişinin \(which) burcuna ve haritasına gönderme yap), 3) kişinin kendine sorması için tek bir içe dönük soru ("?" ile biter).
        """
        let key = "card.\(card).\(stable(base.title))"
        guard let p = await parts(key: key, sky: sky, facts: facts, task: task, count: 3, wordsEach: 80),
              p[2].hasSuffix("?") else { return (base, false) }
        return (.init(title: p[0], body: p[1], question: p[2]), true)
    }

    // MARK: Core

    private static func chartFacts(_ sky: UserSky) -> String {
        var f: [String] = []
        let df = DateFormatter(); df.locale = Locale(identifier: "tr_TR"); df.dateFormat = "d MMMM yyyy, EEEE"
        f.append("Bugün: \(df.string(from: Date()))")
        if !sky.firstName.isEmpty { f.append("Kişinin adı: \(sky.firstName)") }
        if let s = sky.sun { f.append("Güneş: \(s.labelTR)") }
        if let s = sky.moon { f.append("Ay: \(s.labelTR)") }
        if let s = sky.rising { f.append("Yükselen: \(s.labelTR)") }
        if let s = sky.venus { f.append("Venüs: \(s.labelTR)") }
        if let s = sky.mars { f.append("Mars: \(s.labelTR)") }
        if let s = sky.mercury { f.append("Merkür: \(s.labelTR)") }
        if let e = sky.dominantElement { f.append("Baskın element: \(e.labelTR)") }
        return f.joined(separator: " · ")
    }

    private static func cacheKey(_ sky: UserSky, _ key: String) -> String {
        let c = Calendar.current
        return "wv.ai.\(sky.userId).\(c.component(.year, from: Date())).\(c.ordinality(of: .day, in: .year, for: Date()) ?? 0).\(key)"
    }

    private static func stable(_ s: String) -> String {
        var h: UInt64 = 14695981039346656037
        for b in s.utf8 { h ^= UInt64(b); h &*= 1099511628211 }
        return String(h, radix: 36)
    }

    private static func parts(key: String, sky: UserSky, facts: String, task: String, count: Int, wordsEach: Int = 70) async -> [String]? {
        let ck = cacheKey(sky, key)
        if let cached = UserDefaults.standard.stringArray(forKey: ck), cached.count == count { return cached }
        guard isAvailable else { return nil }
        guard let raw = await generate(facts: chartFacts(sky) + "\n" + facts, task: task, wordsEach: wordsEach) else { return nil }
        let parsed = raw
            .components(separatedBy: "---")
            .map { clean($0) }
            .filter { !$0.isEmpty }
        guard parsed.count == count, parsed.allSatisfy({ $0.count >= 8 && $0.count <= 900 }) else { return nil }
        UserDefaults.standard.set(parsed, forKey: ck)
        return parsed
    }

    private static func clean(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”' \n"))
    }

    private static func generate(facts: String, task: String, wordsEach: Int) async -> String? {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return nil }
        let session = LanguageModelSession(instructions: """
            Sen AstroBond adlı bir astroloji ve tanışma uygulamasının sıcak, şiirsel ama somut yazan Türkçe astroloji yazarısın. \
            Yalnızca Türkçe yaz. Her paragraf en fazla \(wordsEach) kelime olsun. Paragrafları yalnızca tek satırlık "---" ile ayır. \
            Başlık, numara, madde işareti, emoji, markdown ya da tırnak kullanma. Kesin gelecek tahmini, sağlık/tıp tavsiyesi, \
            korkutucu, cinsel ya da kırıcı içerik yazma; astrolojiyi eğlence ve içgörü olarak sun. \
            "Sen" diye hitap et, tekrarlardan ve klişelerden kaçın.
            """)
        let prompt = "\(facts)\n\nGörev: \(task)"
        return await withTaskGroup(of: String?.self) { group in
            group.addTask {
                guard let out = try? await session.respond(to: prompt) else { return nil }
                return out.content
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: 20_000_000_000)
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
        #else
        return nil
        #endif
    }
}
