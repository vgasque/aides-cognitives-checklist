import SwiftUI
import AidesCore

// ÉCRAN DE BIENVENUE — port de `#welcomeModal` (C1 §2, A349) : montré une fois par appareil
// (`ac-onboarded`, clé GLOBALE). Trois portes : les exemples, créer, se connecter — et
// « Rejoindre une session ». Fermer (✕) vaut « c'est vu » (`done()`).
//
// La coque (`RootView`) remplace cet écran par l'accueil dès que `onboarded` passe à vrai : la
// porte choisie est donc CONFIÉE à l'accueil (`model.homeRequest`), qui l'ouvre en arrivant.

struct WelcomeView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ZStack {
            T.amb.ignoresSafeArea()
            ScrollView {
                VStack {
                    Spacer(minLength: 24)
                    card
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 16)
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button { model.finishOnboarding() } label: {
                    Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).frame(width: Ctrl.m, height: Ctrl.m)
                }
                .buttonStyle(.plain).foregroundStyle(T.ink2)
                .accessibilityLabel("Fermer")
            }
            Text(verbatim: "✓")
                .aFont(34, .heavy)
                .foregroundStyle(T.onPrimary)
                .frame(width: 56, height: 56)
                .background(T.act, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
                .accessibilityHidden(true)
            // Titre 38 : la SEULE exception nommée de l'échelle typographique (`check-type`).
            Text("Les bons gestes, cochés au bon moment.")
                .aFont(38, .heavy, .title)
                .foregroundStyle(T.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text("Parcours de crise à cocher, protocoles à relire : vos aides se déroulent avec le chrono et les minuteurs sous les yeux. Hors ligne, sur cet appareil.")
                .aFont(TypeScale.item, .regular).foregroundStyle(T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            BoldText(text: "**Vous rédigez, vous validez.** L'app ne contient aucun protocole imposé : vous restez responsable du contenu clinique. **Sans compte, rien ne quitte votre téléphone.**",
                     size: TypeScale.item, color: T.ink2)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 10) {
                Button("Découvrir avec 2 exemples") {
                    model.finishOnboarding()
                    model.addExamplesFromHome()
                }
                .buttonStyle(.a(.primary, Ctrl.l, full: true))
                Button("Créer une aide…") { go(.create) }
                    .buttonStyle(.a(.secondary, Ctrl.l, full: true))
                HStack(spacing: 16) {
                    Button("Me connecter") { go(.account) }
                    Text(verbatim: "·").foregroundStyle(T.ink3).accessibilityHidden(true)
                    Button("Rejoindre une session") { go(.join) }
                }
                .buttonStyle(.plain)
                .aFont(TypeScale.body, .bold)
                .foregroundStyle(T.act)
                .frame(minHeight: Ctrl.l)
            }
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: 480)
        .background(T.work, in: RoundedRectangle(cornerRadius: Radius.r4, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radius.r4, style: .continuous).strokeBorder(T.workLine))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    /// `done()` puis la porte : l'accueil prend le relais et ouvre la fenêtre demandée.
    private func go(_ r: HomeRequest) {
        model.homeRequest = r
        model.finishOnboarding()
    }
}
