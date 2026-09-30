import Foundation
import AVFoundation
import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

/// L'ALARME D'UN MINUTEUR — port de `beep()` (§13 de la spécification du moteur).
///
/// Une tonalité sinusoïdale de 880 Hz, enveloppe de 2 s (0,0001 → 0,32 en 20 ms, 0,28 → 0,24 à
/// 1,8 s, puis extinction à 2 s), et la vibration [500, 200, 500, 200, 500] ms.
/// DÉCISION NATIVE (question Q10) : la session audio est `.playback` — l'alarme d'un minuteur
/// vital RESTE AUDIBLE même bouton latéral sur silencieux, ce que la PWA ne pouvait pas faire
/// (d'où son avertissement « silencieux ? », devenu sans objet ici). Elle se mélange aux autres
/// sons (`mixWithOthers`) : elle ne coupe pas la musique d'un collègue, elle s'y ajoute.
@MainActor
final class Alarm {
    static let shared = Alarm()
    var soundOn = true
    private var player: AVAudioPlayer?
    private lazy var toneData: Data = Alarm.makeTone()

    /// À appeler au premier geste (équivalent d'`ensureAudio`) : prépare la session audio.
    func prepare() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        if player == nil { player = try? AVAudioPlayer(data: toneData) ; player?.prepareToPlay() }
    }

    func beep() {
        vibrate()
        guard soundOn else { return }
        prepare()
        player?.currentTime = 0
        player?.play()
    }

    /// Accusé haptique d'un geste accompli (coche, compteur +) — `tick()` de la PWA.
    func tick() {
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif
    }

    private func vibrate() {
        #if os(iOS)
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
        for d in [0.7, 1.4] {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) { g.notificationOccurred(.warning) }
        }
        #endif
    }

    /// Tonalité PCM 16 bits mono en WAV, générée une fois.
    static func makeTone() -> Data {
        let rate = 44_100.0, dur = 2.0
        let n = Int(rate * dur)
        var samples = [Int16](repeating: 0, count: n)
        for i in 0..<n {
            let t = Double(i) / rate
            let g: Double
            if t < 0.02 { g = 0.0001 * pow(0.32 / 0.0001, t / 0.02) }
            else if t < 1.8 { g = 0.28 * pow(0.24 / 0.28, (t - 0.02) / 1.78) }
            else { g = 0.24 * pow(0.0001 / 0.24, (t - 1.8) / 0.2) }
            samples[i] = Int16(max(-1, min(1, sin(2 * .pi * 880 * t) * g)) * 32_000)
        }
        var d = Data()
        func u32(_ v: UInt32) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 4)) }
        func u16(_ v: UInt16) { var x = v.littleEndian; d.append(Data(bytes: &x, count: 2)) }
        let byteCount = UInt32(n * 2)
        d.append(contentsOf: Array("RIFF".utf8)); u32(36 + byteCount); d.append(contentsOf: Array("WAVE".utf8))
        d.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1); u32(UInt32(rate)); u32(UInt32(rate) * 2); u16(2); u16(16)
        d.append(contentsOf: Array("data".utf8)); u32(byteCount)
        samples.withUnsafeBytes { d.append(contentsOf: $0) }
        return d
    }
}

/// NOTIFICATIONS LOCALES — là où la PWA ne pouvait rien en arrière-plan : chaque minuteur à
/// échéance qui tourne est programmé auprès du système quand l'app passe en arrière-plan, et
/// tout est annulé au retour (l'état calculé depuis l'horloge murale reste la source de vérité).
enum Notifier {
    static func requestPermission() {
        // Mode démo (captures d'écran de la CI) : pas de dialogue système par-dessus l'écran.
        if ProcessInfo.processInfo.arguments.contains("-ac-demo") { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    /// `dueAt` en ms depuis l'époque.
    static func schedule(id: String, title: String, body: String, dueAt: Double) {
        let delay = (dueAt - Date().timeIntervalSince1970 * 1000) / 1000
        guard delay > 0.5 else { return }
        let c = UNMutableNotificationContent()
        c.title = title
        c.body = body
        c.sound = .default
        #if os(iOS)
        c.interruptionLevel = .timeSensitive
        #endif
        let req = UNNotificationRequest(identifier: "ac-" + id, content: c,
                                        trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false))
        UNUserNotificationCenter.current().add(req)
    }
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
