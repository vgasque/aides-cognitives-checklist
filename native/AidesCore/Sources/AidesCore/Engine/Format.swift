import Foundation

// FORMATS D'AFFICHAGE du moteur — fmtMs, fmtHMS, durTxt, autoSessName, tmLabelParts, tmName.

public enum Fmt {
    /// `fmtMs` : « mm:ss » sous l'heure, « h:mm:ss » au-delà (heures non complétées), plancher à la seconde.
    public static func ms(_ ms: Double) -> String {
        let s = max(0, Int((ms / 1000).rounded(.down)))
        let h = s / 3600, m = (s % 3600) / 60, sec = s % 60
        func p2(_ v: Int) -> String { v < 10 ? "0\(v)" : "\(v)" }
        return h > 0 ? "\(h):\(p2(m)):\(p2(sec))" : "\(p2(m)):\(p2(sec))"
    }
    static let hms: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "HH:mm:ss"; return f
    }()
    static let hm: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "HH:mm"; return f
    }()
    static let ddmmHM: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd/MM HH:mm"; return f
    }()
    static let full: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd/MM/yyyy HH:mm:ss"; return f
    }()
    static let dayOnly: DateFormatter = {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_FR"); f.dateFormat = "dd/MM/yyyy"; return f
    }()
    static func date(_ t: Double) -> Date { Date(timeIntervalSince1970: t / 1000) }
    /// `fmtHMS(t)` : heure murale « HH:MM:SS ».
    public static func hms(_ t: Double) -> String { hms.string(from: date(t)) }
    /// `fmtHM(t)` : « HH:MM ».
    public static func hm(_ t: Double) -> String { hm.string(from: date(t)) }
    /// `new Date(t).toLocaleString('fr-FR')` : « 30/09/2026 14:32:05 ».
    public static func localeString(_ t: Double) -> String { full.string(from: date(t)) }
    /// `sessStamp(t)` : « 30/09/2026 · 14:32 ».
    public static func sessStamp(_ t: Double) -> String { dayOnly.string(from: date(t)) + " · " + hm(t) }

    /// `durTxt(s)` : « 5 min », « 45 s », « 1 min 30 s ».
    public static func dur(_ s: Int) -> String {
        if s % 60 == 0 { return "\(s / 60) min" }
        if s < 60 { return "\(s) s" }
        return "\(s / 60) min \(s % 60) s"
    }
    /// `autoSessName(f)` : « Anaphylaxie — 30/09 14:32 ».
    public static func autoSessionName(_ title: String, now: Double) -> String {
        (title.isEmpty ? "Session" : title) + " — " + ddmmHM.string(from: date(now))
    }

    /// `tmLabelParts(label)` : « Nom (méta) » → (nom, méta).
    public static func labelParts(_ label: String) -> (name: String, meta: String) {
        // /^(.*\S)\s*\(([^()]{2,})\)$/
        guard label.hasSuffix(")"), let open = label.lastIndex(of: "(") else { return (label, "") }
        let inner = label[label.index(after: open)..<label.index(before: label.endIndex)]
        guard inner.count >= 2, !inner.contains("("), !inner.contains(")") else { return (label, "") }
        var head = String(label[..<open])
        while let l = head.unicodeScalars.last, JS.isSpace(l) { head.unicodeScalars.removeLast() }
        guard !head.isEmpty else { return (label, "") }
        return (head, String(inner))
    }
    /// `tmName(t)`.
    public static func timerName(label: String, type: TimerKind) -> String {
        let n = labelParts(label).name
        return n.isEmpty ? (type == .interval ? "Minuteur" : "Chronomètre") : n
    }
}
