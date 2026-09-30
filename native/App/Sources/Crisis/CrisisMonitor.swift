import SwiftUI
import AidesCore

// MODE MONITEUR (`#monMode`, B2 §18) — l'appareil POSÉ, lisible à 2 m. AUCUNE commande : un tap
// n'importe où (ou Échap) revient. Le grand chiffre : un échu l'emporte, sinon le minuteur qui
// tourne le plus proche de sa fin (`monPick`). La bande : passé ARRIVÉ (points nommés), avenir DATÉ
// (minuteurs qui tournent), tours suivants PROJETÉS en tirets ; ce qui n'a pas d'heure se liste
// « sans heure ». Rien n'est prédit : un jalon compté n'y entre jamais (`monBandData`).

struct CrMonitorView: View {
    let R: RuntimeSession
    let vs: CrisisViewState
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = model.rev
        let now = JS.now()
        let timers = R.orderedTimers
        let pick = CrisisPure.monPick(timers, now: now)
        let showBand = timers.count >= 2 || !R.events.isEmpty
        GeometryReader { g in
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(R.startedAt > 0 ? Fmt.ms(now - R.startedAt) : "—")
                        .font(.system(size: min(46, max(30, g.size.width * 0.07)), weight: .bold, design: .monospaced).monospacedDigit())
                        .foregroundStyle(R.exercise ? T.act : T.ok)
                        .accessibilityLabel(either(R.exercise, "Exercice", "Session") + " — durée " + Fmt.ms(now - R.startedAt))
                    Spacer()
                    Text("TAP = REVENIR").aFont(TypeScale.meta, .bold).tracking(0.8).foregroundStyle(T.ink2)
                }
                Spacer(minLength: 8)
                if let t = pick {
                    let due = t.isDue
                    Text(t.name).font(.system(size: min(22, max(15, g.size.width * 0.034)), weight: .bold)).foregroundStyle(T.ink2)
                    Text(t.display(now))
                        .font(.system(size: digitSize(g.size, band: showBand), weight: .bold, design: .monospaced).monospacedDigit())
                        .tracking(-2)
                        .foregroundStyle(due ? T.warnLine : T.ink)
                        .lineLimit(1).minimumScaleFactor(0.3)
                        .accessibilityLabel(t.name + " : " + t.display(now))
                    if due {
                        Text("△ ÉCHU — À RÉÉVALUER").aFont(TypeScale.item, .heavy).foregroundStyle(T.warn)
                    }
                } else {
                    Text("Aucun minuteur en cours").aFont(TypeScale.stepL, .bold).foregroundStyle(T.ink2)
                }
                Spacer(minLength: 8)
                if showBand { CrMonBand(R: R, now: now, width: g.size.width - 28) }
            }
            .padding(14)
        }
        .background(T.amb.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture { dismiss() }
        .onKeyPress(.escape) { dismiss(); return .handled }
        .onKeyPress(.space) { dismiss(); return .handled }
        .onKeyPress(.return) { dismiss(); return .handled }
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toucher pour revenir")
        .onAppear { model.applyWake(crisisOnScreen: true) }
    }

    /// Le chiffre ne recouvre JAMAIS la bande : plafond pris sur la hauteur restante, plancher 64 pt.
    private func digitSize(_ s: CGSize, band: Bool) -> CGFloat {
        let reserve: CGFloat = band ? 230 : 90
        let byH = max(64, (s.height - reserve) * 0.55)
        return min(190, min(s.width * 0.2, byH))
    }
}

/// La bande des évènements : « −2 min » · « maintenant » · « +5 min ».
struct CrMonBand: View {
    let R: RuntimeSession
    let now: Double
    let width: CGFloat
    @Environment(AppModel.self) private var model

    var body: some View {
        let labs = Report.eventLabels(R.events, R.fiche, tags: model.library.tags, extras: crExtras(R))
        let marks = R.events.map { Live.EventMark(t: $0.t, voided: $0.isVoid) }
        let data = Live.monBandData(R.orderedTimers.map(CrisisPure.run), events: marks, now: now, labels: labs)
        let older = R.events.filter { !$0.isVoid && now - $0.t > Live.monPastMs }.count
        let lastEv = R.events.last { !$0.isVoid }
        let w = max(1, width)
        VStack(alignment: .leading, spacing: 6) {
            // Passé : les trois derniers repères NOMMÉS, chacun à son instant.
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 22 * CGFloat(max(1, min(3, data.past.filter { !$0.lab.isEmpty }.count))))
                ForEach(Array(data.past.enumerated()), id: \.offset) { i, p in
                    let named = !p.lab.isEmpty
                    HStack(spacing: 4) {
                        Circle().fill(i == data.past.count - 1 ? T.ink : T.ink2).frame(width: 8, height: 8)
                        if named {
                            Text(JS.prefix(p.lab, 18)).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink).lineLimit(1)
                            Text(Fmt.hm(p.t)).aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink3)
                        } else if p.n > 1 {
                            Text("×\(p.n)").aFont(TypeScale.cap, .bold).foregroundStyle(T.ink2)
                        }
                    }
                    .fixedSize()
                    .offset(x: CGFloat(p.x) * w, y: CGFloat(namedRow(data.past, i)) * 22)
                }
            }
            if older > 0 {
                Text("+ \(older) repère" + either(older > 1, "s", "") + " avant").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            } else if data.past.isEmpty, let e = lastEv {
                Text("‹ " + (e.label.isEmpty ? "Repère" : e.label) + "  il y a " + ageTxt(now - e.t)).aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            }
            // L'axe : −2 min … maintenant … +5 min.
            ZStack(alignment: .leading) {
                Capsule().fill(T.amb2).frame(height: 6)
                Rectangle().fill(T.ok).frame(width: 2, height: 18).offset(x: CGFloat(Live.monNow) * w)
            }
            HStack {
                Text("−2 min"); Spacer(); Text("maintenant"); Spacer(); Text("+5 min")
            }
            .aFont(TypeScale.meta, .semibold, .mono).foregroundStyle(T.ink2)
            // Avenir DATÉ : une rangée par minuteur qui tourne (au plus 4).
            ForEach(Array(data.dated.prefix(4).enumerated()), id: \.offset) { _, d in
                ZStack(alignment: .leading) {
                    ForEach(Array(d.ghosts.enumerated()), id: \.offset) { _, gx in
                        Rectangle().fill(T.ink3).frame(width: 1, height: 14).offset(x: CGFloat(gx) * w)
                    }
                    Text(d.lab).aFont(TypeScale.meta, .bold).foregroundStyle(T.ink)
                        .padding(.leading, 6)
                        .overlay(alignment: .leading) { Rectangle().fill(T.ink).frame(width: 2) }
                        .fixedSize()
                        .offset(x: min(CGFloat(d.x) * w, w - 120))
                }
                .frame(height: 22)
            }
            if data.dated.count > 4 {
                Text("+ \(data.dated.count - 4) minuteur" + either(data.dated.count - 4 > 1, "s", "") + " plus tard").aFont(TypeScale.meta, .medium).foregroundStyle(T.ink2)
            }
            if data.dated.contains(where: { !$0.ghosts.isEmpty }) {
                Text("┄ tours suivants — si rien n'est touché").aFont(TypeScale.cap, .medium).foregroundStyle(T.ink2)
            }
            if !data.sans.isEmpty {
                CrWrap(spacing: 6) {
                    Text("SANS HEURE").aFont(TypeScale.cap, .heavy).foregroundStyle(T.ink2)
                    ForEach(Array(data.sans.enumerated()), id: \.offset) { _, s in
                        Text(s.lab + " · " + s.val).aFont(TypeScale.meta, .bold)
                            .foregroundStyle(s.kind == "due" ? T.warn : T.ink)
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(s.kind == "due" ? T.warnSoft : T.amb2, in: Capsule())
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    /// Le plus récent en bas, les plus anciens montent.
    private func namedRow(_ past: [Live.BandPast], _ i: Int) -> Int {
        let named = past.indices.filter { !past[$0].lab.isEmpty }
        guard let k = named.firstIndex(of: i) else { return max(0, min(2, named.count - 1)) }
        return k - max(0, named.count - 3)
    }
    /// `monAge` : « 7 min », « 1 h 05 ».
    private func ageTxt(_ ms: Double) -> String {
        let m = Int(ms / 60_000)
        if m < 60 { return "\(m) min" }
        let h = m / 60, r = m % 60
        return "\(h) h " + either(r < 10, "0\(r)", "\(r)")
    }
}
