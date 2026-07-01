# Modèle — fiche de registre des activités de traitement (RGPD, art. 30)

> Modèle à adapter puis à intégrer au registre de votre établissement. Non juridique.
> À faire valider par votre DPO (délégué à la protection des données).

| Rubrique | Contenu proposé (à adapter) |
|---|---|
| **Nom du traitement** | Application « Aides cognitives » — support de checklists cliniques |
| **Responsable de traitement** | [Établissement / service], représenté par [nom, fonction] |
| **DPO** | [nom, e-mail] |
| **Finalité** | Mise à disposition et partage d'aides cognitives (checklists) rédigées par les professionnels ; synchronisation multi-appareils optionnelle |
| **Base légale** | Intérêt légitime de l'établissement (organisation des soins) / mission d'intérêt public |
| **Catégories de personnes** | Professionnels de santé utilisateurs (comptes). **Aucun patient.** |
| **Catégories de données** | Adresse e-mail professionnelle (compte) ; contenu des fiches rédigées ; préférences (thème, épingles) ; horodatages de sessions. **Aucune donnée de santé de patient.** |
| **Données sensibles** | Aucune (pas de donnée patient, pas de donnée de santé identifiante) |
| **Destinataires** | Membres des bibliothèques partagées (contenu d'équipe) ; sous-traitants techniques (ci-dessous) |
| **Sous-traitants** | Supabase (hébergement base + auth) ; Brevo (envoi des e-mails de code) ; hébergeur statique [GitHub/Netlify/Cloudflare/intranet] |
| **Transferts hors UE** | À éviter : choisir la région UE (Francfort) pour Supabase. Vérifier la localisation de l'hébergeur statique. |
| **Durée de conservation** | Comptes : tant qu'actif ; suppression à la demande (fonction intégrée « Supprimer mon compte »). Sessions : locales à l'appareil. Fiches partagées : durée d'exploitation de la bibliothèque. |
| **Droits des personnes** | Accès/rectification : via l'app. Effacement : « Supprimer mon compte » (efface fiches et catégories personnelles + le compte). Contact DPO pour les autres droits. |
| **Mesures de sécurité** | HTTPS ; isolation des données par politiques RLS (serveur) ; authentification par code e-mail à usage unique ; CSP et en-têtes de sécurité ; aucune dépendance tierce chargée ; pas de traceur/analytics. |
| **Analyse d'impact (AIPD)** | A priori non requise (pas de donnée de santé de patient, pas de traitement à grande échelle de données sensibles). À confirmer avec le DPO. |

## Notes
- Le point déterminant pour le RGPD : **l'application ne traite pas de données de patients**.
  Les seules données personnelles sont celles des **professionnels utilisateurs** (e-mail + contenu
  qu'ils produisent). Veiller à ce que cela reste vrai (ne jamais saisir de donnée patient).
- La fonction « Supprimer mon compte » couvre le droit à l'effacement pour l'espace personnel ;
  les contributions à des bibliothèques partagées restent (contenu collectif) — à mentionner dans
  l'information des utilisateurs.
