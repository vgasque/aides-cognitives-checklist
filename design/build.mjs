#!/usr/bin/env node
/*
 * Génère le design system (design/ds/) à partir du CSS RÉEL de index.html :
 * tokens, palette de catégories et styles de composants sont EXTRAITS du
 * monofichier — jamais recopiés à la main. Chaque fiche (preview HTML
 * autonome) montre le composant dans les deux thèmes, côte à côte.
 *
 *   node design/build.mjs
 *
 * Le dossier design/ n'est PAS servi par la PWA (hors ASSETS de sw.js, hors
 * de sw.js) : c'est un export destiné au projet « Design System » de claude.ai
 * (synchronisation via l'outil DesignSync de Claude Code).
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(ROOT, 'design', 'ds');
const html = readFileSync(join(ROOT, 'index.html'), 'utf8');

/* ---- Extraction depuis index.html ---- */
const styleStart = html.indexOf('<style>') + '<style>'.length;
const styleEnd = html.indexOf('</style>');
if (styleStart < 7 || styleEnd < 0) throw new Error('Bloc <style> introuvable');
const appCss = html.slice(styleStart, styleEnd);

const rootTokens = (appCss.match(/:root\{[^}]+\}/) || [])[0];
const darkTokens = (appCss.match(/html\[data-theme="dark"\]\{--[^}]+\}/) || [])[0];
const paletteM = html.match(/const PALETTE=\[([^\]]+)\]/);
if (!rootTokens || !darkTokens || !paletteM) throw new Error('Tokens ou PALETTE introuvables');
const PALETTE = paletteM[1].split(',').map(s => s.replace(/['"\s]/g, ''));

/* Le CSS de l'app est réutilisé tel quel ; seul le sélecteur de thème est
 * élargi (html[data-theme] -> [data-theme]) pour permettre deux thèmes
 * côte à côte dans une même page d'aperçu. */
const scopedCss = appCss.replaceAll('html[data-theme="dark"]', '[data-theme="dark"]');

/* ---- Habillage propre aux fiches (préfixe ds- : jamais de collision) ---- */
const dsCss = `
  body{margin:0;padding:0}
  .ds-scope{background:var(--bg);color:var(--ink);padding:20px 22px 26px;font-family:var(--sans)}
  .ds-lab{font:700 10px/1 var(--mono);letter-spacing:1.5px;text-transform:uppercase;color:var(--ink-soft);margin:0 0 16px}
  .ds-row{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:0 0 14px}
  .ds-col{display:flex;flex-direction:column;gap:12px;margin:0 0 14px}
  .ds-cap{font-size:11px;color:var(--ink-soft);margin:-6px 0 14px}
  .ds-item{display:flex;flex-direction:column;gap:5px;align-items:flex-start}
  .ds-item>small{font:600 10px/1.3 var(--mono);color:var(--ink-soft)}
  .ds-sw{width:104px;border:1px solid var(--line);border-radius:9px;overflow:hidden;background:var(--surface)}
  .ds-sw>i{display:block;height:44px}
  .ds-sw>b{display:block;font:600 9.5px/1.3 var(--mono);padding:5px 7px;color:var(--ink);word-break:break-all}
  .ds-sw>small{display:block;font-size:9.5px;line-height:1.3;padding:0 7px 6px;color:var(--ink-soft)}
  .ds-static .toast{position:static;left:auto;bottom:auto;transform:none;opacity:1;pointer-events:auto;max-width:520px}
  .ds-static #alerts,.ds-static .alerts{position:static;padding:0;align-items:flex-start}
  .ds-type{margin:0 0 16px}
  .ds-type>small{display:block;font:600 10px/1 var(--mono);color:var(--ink-soft);margin-bottom:4px}
`;

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

function page(title, demo) {
  return `<!doctype html><html lang="fr"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${esc(title)} — Aides cognitives</title>
<style>${scopedCss}</style><style>${dsCss}</style></head><body>
<div class="ds-scope" data-theme="light"><p class="ds-lab">Thème clair</p>
${demo}</div>
<div class="ds-scope" data-theme="dark"><p class="ds-lab">Thème sombre</p>
${demo}</div>
</body></html>`;
}

/* ---- Démos (classes réelles de l'app) ---- */

const swatch = (v, note) => `<div class="ds-sw"><i style="background:var(--${v})"></i><b>--${v}</b>${note ? `<small>${note}</small>` : ''}</div>`;
const colorsDemo = `
<div class="ds-row">${[
  ['ink', 'texte'], ['ink-soft', 'texte secondaire'], ['soft', 'DÉCORATIF seul — jamais du texte'],
  ['bg', 'fond de page'], ['surface', 'cartes'], ['surface-2', 'panneaux'], ['surface-3', 'badges neutres'],
  ['line', 'bordures douces'], ['line-hover', 'bordures de cartes'], ['line-strong', 'bordures ≥ 3:1 (champs, cases)'], ['input-bg', 'fond des champs'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<div class="ds-row">${[
  ['primary', 'bleu clinique — identité / action'], ['primary-dk', 'texte accent'], ['primary-hi', 'survol des boutons remplis'],
  ['primary-soft', 'fonds bleus'], ['primary-100', 'fonds de tags'], ['primary-200', 'bordures douces'], ['primary-300', 'bordures marquées'],
  ['on-primary', 'texte sur primary'], ['link', 'liens + minuteur en cours'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<div class="ds-row">${[
  ['ok', 'confirmation / issue positive'], ['ok-soft', 'fonds verts'],
  ['verify', 'décision / attente — texte'], ['verify-bd', 'bordures ambrées'], ['verify-hi', 'emphase ambrée (échu)'],
  ['verify-soft', 'fonds ambrés'], ['verify-line', 'bordures douces ambrées'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<div class="ds-row">${[
  ['critical', 'TEXTE / icônes vital-destructif'], ['critical-bd', 'BORDURES rouges'], ['critical-soft', 'fonds vermillon'], ['critical-line', 'bordures douces vermillon'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<p class="ds-cap">TROIS ROUGES distincts, jamais fusionnés : --critical (texte/icônes), --critical-bd (bordures des cartes et bandeaux rouges), et le rouge « Urgences » de PALETTE (#b6382f) — couleur de CATÉGORIE (liseré/pastille), jamais un signal d’alerte.</p>
<div class="ds-row">${[
  ['done-bg', 'étape cochée — fond'], ['done-line', 'étape cochée — bordure'], ['done-ink', 'étape cochée — texte'],
  ['tag-bg', 'pilules neutres — fond'], ['tag-ink', 'pilules neutres — texte'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<div class="ds-row">${[
  ['alert', 'banderole d’alerte'], ['alert-hi', 'alerte vive'], ['alert-strong', 'bordure alerte'], ['alert-ink', 'texte sur alerte'],
  ['alarm', 'jauge du geste « maintenir »'], ['rt-card', 'toast ardoise (fixe)'], ['rt-line', 'bordure du toast (fixe)'], ['rt-ink', 'texte du toast (fixe)'],
].map(([v, n]) => swatch(v, n)).join('')}</div>
<div class="ds-row" style="align-items:flex-end">
  <div class="ds-item"><span class="acc-sw a-clinique on"></span><small>défaut — bleu clinique</small></div>
  <div class="ds-item"><span class="acc-sw a-teal"></span><small>sarcelle</small></div>
  <div class="ds-item"><span class="acc-sw a-violet"></span><small>violet</small></div>
  <div class="ds-item"><span class="acc-sw a-indigo"></span><small>indigo</small></div>
  <div class="ds-item"><span class="acc-sw a-framboise"></span><small>framboise</small></div>
  <div class="ds-item"><span class="acc-sw a-ardoise"></span><small>ardoise</small></div>
</div>
<p class="ds-cap">Sémantique FIXE : erreur / danger / arrêt d’un processus vivant = --critical ; décision / attente / avertissement = --verify ; confirmation = --ok — jamais l’inverse. --soft est DÉCORATIF seulement (texte secondaire = --ink-soft). COULEUR D’ACCENT par utilisateur (v4.5) : 5 nuances AA + bleu par défaut, CONNECTÉ seulement ; portée = accueil entier + en-tête de toutes les vues ; le contenu clinique (crise, protocoles, éditeurs) reste bleu clinique ; jamais de vert/ambre/rouge en accent (registres réservés).</p>`;

const typeDemo = `
<div class="ds-type"><small>Marque / titre d’en-tête — .brand-name · 18px / 800</small><span style="font-size:18px;font-weight:800;letter-spacing:-.2px">Aides cognitives</span></div>
<div class="ds-type"><small>Titre du bandeau de crise — #crisisBand .cb-ttl · 18px / 800 (registre ALERTE)</small><span style="font-size:18px;font-weight:800;letter-spacing:-.2px">Choc anaphylactique</span></div>
<div class="ds-type"><small>Titre de fiche — .read-head h2 · 24px / 680</small><span style="font-size:24px;font-weight:680;line-height:1.18">Choc anaphylactique</span></div>
<div class="ds-type"><small>Question de décision — .question · 16px / 700 (18px &lt; 560px)</small><span style="font-size:16px;font-weight:700;line-height:1.3">Le patient est-il conscient&nbsp;?</span></div>
<div class="ds-type"><small>Titre de section — .block-h · 11px / 800 capitales espacées (registre UNIQUE de titres)</small><span class="block-h" style="margin:0">Prise en charge</span></div>
<div class="ds-type"><small>Corps d’étape — ol.steps .txt · 16px</small><span style="font-size:16px;line-height:1.45">Allonger le patient, surélever les jambes.</span></div>
<div class="ds-type"><small>Contenu rédigé — .md-body · 15px / 1.55</small><span style="font-size:15px;line-height:1.55">Texte courant des protocoles (mini-Markdown).</span></div>
<div class="ds-type"><small>Temps — .tm-val · mono 26px / 700 tabular-nums (34px dans le rail de crise ≥ 1000px)</small><span style="font-family:var(--mono);font-size:26px;font-weight:700;letter-spacing:1px;font-variant-numeric:tabular-nums">04:32</span></div>
<div class="ds-type"><small>Étiquette — .tag · 11px / 600 (plancher de l’app)</small><span class="tag">Adulte</span></div>
<div class="ds-type"><small>Statut — .status-tag · 10.5px / 700 (pilule-capitale graisseuse : exception unique au plancher, spec canvas)</small><span class="status-tag">✓ Validée</span></div>
<p class="ds-cap">Police système (var(--sans)) ; mono (var(--mono)) réservée aux valeurs qui défilent (chronos, compteurs, numéros d’étape). Plancher typographique 11px pour tout texte courant — app consultée sous stress ; seules les pilules-capitales à forte graisse (.status-tag, .tm-label) descendent à 10.5px.</p>`;

const shapeDemo = `
<div class="ds-row">
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--surface);border:1px solid var(--line);border-radius:var(--radius)"></div><small>--radius 14px · cartes</small></div>
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--surface);border:1px solid var(--line);border-radius:var(--radius-md)"></div><small>--radius-md 11px · boutons, champs</small></div>
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--surface);border:1px solid var(--line);border-radius:var(--radius-sm)"></div><small>--radius-sm 9px · petits contrôles</small></div>
  <div class="ds-item"><div style="width:88px;height:36px;background:var(--surface);border:1px solid var(--line);border-radius:20px"></div><small>20px · pastilles / tags</small></div>
</div>
<div class="ds-row">
  <div class="ds-item"><div style="width:120px;height:64px;background:var(--surface);border-radius:var(--radius);box-shadow:var(--shadow)"></div><small>--shadow · cartes</small></div>
  <div class="ds-item"><div style="width:120px;height:64px;background:var(--surface);border-radius:var(--radius);box-shadow:var(--shadow-lg)"></div><small>--shadow-lg · survol / flottant</small></div>
</div>
<div class="ds-col" style="font-size:13px;line-height:1.6;max-width:560px">
  <div><b>Breakpoints (échelle FERMÉE)</b> : 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px — aucun nouveau palier sans décision explicite (référence : AGENTS.md, § Largeurs).</div>
  <div><b>Largeurs par vue</b> : accueil = sidebar 255px + grille ≤ 1320px, COQUE FIXE ≥ 780 (seuls la sidebar et le contenu défilent) ; fiche ≤ 860px + rail minuteurs 320 → 360px ; protocole ≤ 780px ; éditeurs alignés sur leur lecture + aperçu sticky 360px (≥ 1000).</div>
  <div><b>Cibles tactiles</b> : ≥ 32 px partout, ≥ 44 px pour les contrôles du mode crise ; halo cliquable (::after) quand le contrôle visuel est plus petit (boutons 36–40px de la barre, pastilles de chips).</div>
  <div><b>Focus clavier</b> : outline 2px var(--primary), offset 2px, sur tout contrôle.</div>
  <div><b>Anti-accident</b> : geste « maintenir » (jauge --alarm) pour le destructif en crise ; garde temporelle 700 ms (.guarded, opacité réduite) entre deux boutons « retour » empilés (logique ECAM).</div>
</div>`;

const catDemo = `
<div class="ds-row">${PALETTE.map(c => `<div class="ds-item"><span style="width:34px;height:34px;border-radius:8px;background:${c};display:block"></span><small>${c}</small></div>`).join('')}</div>
<p class="ds-cap">PALETTE : 13 teintes de catégories (choisies par l’utilisateur, jamais de nouvelle teinte codée en dur hors :root/PALETTE).</p>
<div class="ds-row">${PALETTE.slice(0, 5).map((c, i) => `<span class="tag cat" style="--c:${c}">Catégorie ${i + 1}</span>`).join('')}</div>
<p class="ds-cap">.tag.cat — étiquette teintée (color-mix : fond 15 % en clair, 26 % + texte éclairci en sombre) : lecture de fiche.</p>
<div class="ds-row"><span class="tag cat neutral">Urgences</span><span class="tag cat neutral">Voies aériennes</span></div>
<p class="ds-cap">.tag.cat.neutral — sur les CARTES d’accueil la pilule de catégorie est NEUTRE (--tag-bg/--tag-ink) : la couleur de catégorie ne vit que dans le liseré gauche de la carte (audit v4.5 : trop de pastilles colorées nuisait à la hiérarchie).</p>
<div class="ds-row">${PALETTE.slice(5, 9).map((c, i) => `<button class="catchip colored" style="--catcol:${c}">Filtre ${i + 1}</button>`).join('')}</div>
<p class="ds-cap">.catchip.colored — pastille de filtre teintée, lisible dans les deux thèmes via color-mix.</p>`;

const buttonsDemo = `
<div class="ds-row"><button class="btn primary">Enregistrer</button><button class="btn">Annuler</button><button class="btn danger">Supprimer</button><button class="btn" disabled>Désactivé</button><button class="btn sm">Petit (.sm)</button></div>
<p class="ds-cap">.btn — 44px min ; UN SEUL bouton rempli (--primary) par écran ; .danger = liseré vermillon, fond au survol seulement.</p>
<div class="ds-row"><button class="btn-new" style="min-height:44px"><svg class="tic" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M12 5v14M5 12h14"/></svg> Créer</button><button class="btn-new tonal" style="min-height:44px">Créer (tonal)</button><button class="add-line" style="width:220px">+ Ajouter une ligne</button><button class="btn">Gérer les catégories</button></div>
<p class="ds-cap">Grammaire des boutons de gestion : POINTILLÉ = créer (.btn-new, .add-line), CONTOUR = gérer / secondaire, PLEIN = action primaire. « Créer » passe en tonal (--primary-soft) quand un « Reprendre » plein est déjà affiché.</p>
<div class="ds-row"><button class="btn cont idle" aria-disabled="true" style="max-width:300px">Cochez les étapes restantes (2)</button><button class="btn cont okay" style="max-width:300px">Continuer — réévaluation à 5 min →</button></div>
<p class="ds-cap">.btn.cont — UN bouton, deux états : inactif il DIT pourquoi (et combien il reste — jamais muet), actif il ANNONCE la destination (champ nextLbl du bloc) et passe au registre CONFIRMATION (--ok) ; dernier bloc = « Terminer l’algorithme ✓ » (qui n’arrête PAS la session).</p>
<div class="ds-row"><button class="btn btn-hold"><span class="tmr-lab">Recommencer</span><span class="tmr-hint">Maintenir</span></button><button class="back"><svg class="tic" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M15 18l-6-6 6-6"/></svg> Retour</button><button class="linkbtn">Gérer</button><button class="tlink">Exporter</button></div>
<p class="ds-cap">.btn-hold — geste « maintenir » anti-accidentel (jauge --alarm) ; .back, .linkbtn, .tlink — actions secondaires ; un « retour » venant d’apparaître sous le doigt est inhibé 700 ms (.guarded).</p>
<div class="ds-row"><button class="mini">↑</button><button class="mini">↓</button><button class="mini del">×</button></div>
<p class="ds-cap">.mini — micro-contrôles d’éditeur.</p>`;

const chipsDemo = `
<div class="ds-row"><button class="catchip on">Toutes</button><button class="catchip">Aucune</button><button class="catchip">Adulte</button><button class="catchip mgr">Gérer…</button></div>
<p class="ds-cap">.catchip — filtres de catégories ; .on = sélection neutre (encre pleine) ; .mgr = action en retrait (pointillés).</p>
<div class="ds-row"><span class="status-tag">✓ Validée</span><span class="status-tag">△ À relire</span><span class="status-tag">○ Brouillon</span><span class="tag todo">△ À compléter</span><span class="tag live">● En cours</span><span class="tag sess">3 sauvegardées</span><span class="tag flow">Algorithme</span><span class="tag libtag"><svg class="tic" width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h7l2 3h7v13H4z"/></svg> Bibliothèque SMUR</span></div>
<p class="ds-cap">.status-tag — pilule ACHROMATIQUE unique pour les 3 statuts (--tag-bg/--tag-ink), affichée sur cartes, lecture et éditeurs (y compris « ✓ Validée ») ; .tag.todo est cliquable (souligné pointillé = affordance détail) ; .tag.live = session vive (vert --ok, état annoncé en texte).</p>
<div class="ds-row"><span class="sync-chip off">Hors ligne</span><span class="sync-chip ok">Synchronisé</span><span class="sync-chip busy">Synchro…</span><span class="sync-chip pending">En attente</span><span class="sync-chip err">Erreur</span></div>
<p class="ds-cap">.sync-chip — état de synchro, jamais bloquant : ok = --ok, attente = --verify, erreur = --critical, inactif = --line-strong.</p>
<div class="ds-row">
  <span class="bar-acct on ini-on" style="position:static"><span class="acct-ini">VG</span><span class="acct-dot"></span></span>
  <span class="bar-acct" style="position:static"><svg class="ic-outline" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="3.6"/><path d="M5.5 20.5v-1a5 5 0 015-5h3a5 5 0 015 5v1"/></svg></span>
</div>
<p class="ds-cap">.bar-acct — connecté : INITIALES de l’e-mail (2 lettres, .acct-ini) + pastille d’état ; déconnecté : icône personne en contour, sans initiales. La couleur n’est jamais seule (initiales + chip texte ailleurs).</p>
<div class="ds-row"><span class="rel-chip">Fiche liée <button class="rel-x">×</button></span><span class="ro-badge">Lecture seule</span><span class="pend-badge pending">En attente</span><span class="pend-badge rejected">Refusé</span></div>`;

const cardsDemo = `
<div class="cards" style="max-width:560px">
  <article class="card" style="--c:${PALETTE[4]}"><div class="card-body"><h2><button class="card-open">Choc anaphylactique</button></h2><div class="card-meta"><span class="tag live">● En cours</span><span class="status-tag">✓ Validée</span><span class="tag cat neutral">Urgence vitale</span><span class="card-date" style="font-family:var(--mono)">ANA-01</span><span class="card-date">03/2026</span></div></div><button class="pinbtn on" aria-label="Épinglé">★</button><svg class="chev" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 6l6 6-6 6"/></svg></article>
  <article class="card" style="--c:${PALETTE[6]}"><div class="card-body"><h2><button class="card-open">Intubation difficile</button></h2><div class="card-meta"><span class="status-tag">○ Brouillon</span><span class="tag todo">△ À compléter</span><span class="tag cat neutral">Voies aériennes</span><span class="card-date stale">01/2024 · à revoir</span></div></div><button class="pinbtn" aria-label="Épingler">☆</button><svg class="chev" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M9 6l6 6-6 6"/></svg></article>
  <div class="empty"><b>Aucune fiche</b>Créez votre première aide cognitive.<br><button class="btn primary" style="margin-top:14px">Créer</button></div>
</div>
<p class="ds-cap">.card — le TITRE est le vrai bouton (::after étiré) ; épingle et badges restent cliquables au-dessus. Carte SOBRE (audit v4.5) : la couleur de catégorie ne vit que dans le LISERÉ, la pilule est neutre ; le code mono est un repère de recherche ; date périmée = --critical « à revoir » ; session vive = « ● En cours » vert.</p>`;

const formsDemo = `
<div style="max-width:520px">
  <div class="ds-row" style="flex-wrap:nowrap"><div class="search" style="flex:1"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg><input placeholder="Rechercher une fiche…"></div><button class="btn-new">Créer</button></div>
  <div class="field"><label>Titre de la fiche</label><input type="text" value="Choc anaphylactique"></div>
  <div class="row2">
    <div class="field"><label>Catégorie</label><select><option>Urgence vitale</option></select></div>
    <div class="field"><label>Validation <span class="hint">MM/AAAA</span></label><input type="text" value="03/2026"></div>
  </div>
  <div class="field"><label>Contexte local</label><textarea rows="3">Chariot d’urgence : salle 2. Adrénaline au réfrigérateur.</textarea></div>
  <div class="field"><label>Catégories</label><div class="catpick"><button class="catpill on">Adulte</button><button class="catpill">Pédiatrie</button><button class="catpill colored" style="--catcol:${PALETTE[2]}">Toxicologie</button></div></div>
  <input class="auth-field auth-code" value="482913" aria-label="Code reçu">
</div>
<p class="ds-cap">Fond des champs = --input-bg (jamais codé en dur) ; bordure --line-strong (≥ 3:1) ; focus = outline 2px --primary ; police 16px (anti-zoom iOS).</p>`;

const listsDemo = `
<div style="max-width:560px">
  <div class="forget-strip"><div class="block-h h-forget"><span class="pip"></span>Ne pas oublier</div><ul class="forget-list"><li>Retirer l’allergène (perfusion, latex…)</li><li>Noter l’heure de la première adrénaline</li></ul></div>
  <div class="nav-wrap"><div class="node-title">Bloc · Mesures immédiates — <span>1/3</span> coché</div>
    <ol class="steps">
      <li class="done" role="checkbox" aria-checked="true"><span class="box">✓</span><span class="txt">Arrêter l’exposition à l’allergène</span></li>
      <li class="crit" role="checkbox" aria-checked="false"><span class="box"></span><span class="txt">Adrénaline IM 0,5&nbsp;mg face antéro-latérale de cuisse</span></li>
      <li class="vigil" role="checkbox" aria-checked="false"><span class="box"></span><span class="txt">Surveiller la pression artérielle en continu</span></li>
    </ol>
    <div class="flow-ctrl"><button class="btn cont idle" aria-disabled="true">Cochez les étapes restantes (2)</button></div>
  </div>
  <div class="flow-nav"><button id="navBack">‹ Bloc précédent</button><button class="btn-hold"><span class="tmr-lab">↺ Recommencer</span><span class="tmr-hint">maintenir</span></button></div>
  <div class="flow-end">Algorithme terminé — surveillance en cours</div>
  <section class="block" style="margin-top:16px"><div class="block-h h-verify"><span class="sec-badge"><svg class="sec-ic" width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="var(--verify)" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v5l3 2"/></svg></span>Vérifier</div>
    <ul class="flat verify"><li>Pression artérielle toutes les 5 min</li><li>Signes de bronchospasme</li></ul>
  </section>
  <section class="block"><div class="block-h h-diff"><span class="pip"></span>Diagnostics différentiels</div>
    <ul class="flat diff"><li>Malaise vagal</li><li>Œdème de Quincke isolé</li></ul>
  </section>
</div>
<p class="ds-cap">Étapes 64px, case 36px à DROITE ; cochée = vert doux --done-* (texte lisible, pas de biffure agressive) ; ⚠ critique = rouge --critical ; △ vigilance = ambre. Le titre du bloc porte le compte vivant « n/t coché ». .flow-nav TOUJOURS présente (Précédent désactivé au 1er bloc ; Recommencer = maintenir). .flow-end = fin d’algorithme, registre CONFIRMATION — elle n’arrête PAS la session. Un SEUL registre de titres (.block-h, petites capitales) ; couleur sémantique portée par pip + badge, jamais seule.</p>`;

const decisionDemo = `
<div style="max-width:560px">
  <div class="crumbs"><button class="cb">Début<span class="cb-n">1</span></button><button class="cb">Conscience<span class="cb-n">2</span></button><button class="cb cur">Respiration<span class="cb-n">3</span></button></div>
  <div class="nav-wrap dec">
    <div class="node-title">Décision · Respiration</div>
    <div class="question">Le patient respire-t-il normalement&nbsp;?</div>
    <div class="options">
      <button class="opt"><span class="ftxt">Oui, respiration normale</span><span class="arr">›</span></button>
      <button class="opt"><span class="ftxt">Respiration anormale ou pauses</span><span class="arr">›</span></button>
    </div>
  </div>
  <div class="options" style="margin-top:10px"><button class="opt taken" disabled><span class="ftxt">Choix déjà pris (relecture du parcours)</span><span class="arr">✓</span></button></div>
  <div class="flow-nav"><button id="navBack">‹ Bloc précédent</button><button class="btn-hold"><span class="tmr-lab">↺ Recommencer</span><span class="tmr-hint">maintenir</span></button></div>
</div>
<p class="ds-cap">Décision = carte AMBRE (liseré 4px, registre ATTENTION : une décision demande l’attention) ; options 64px — MÊME hauteur que les étapes, pas d’encadré bleu autour des blocs. Fil d’Ariane = CURSEUR non destructif (revisiter un bloc ne tronque pas le parcours). l’issue positive est portée par .flow-end (voir Listes).</p>`;

const noticesDemo = `
<div style="max-width:560px">
  <div class="notice"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5v.5"/></svg>Contenu rédigé par vous : vérifiez vos sources avant usage clinique.<button class="notice-x">×</button></div>
  <div class="notice sync-err"><svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="9"/><path d="M12 8v5M12 16.5v.5"/></svg>Échec de synchronisation — toucher pour réessayer.<button class="notice-x">×</button></div>
  <div class="ds-static"><div class="alert-toast"><span class="at-ic">⏱</span><span class="at-tx"><b>Minuteur terminé</b><span>Adrénaline — cycle de 5 min écoulé</span></span><button class="at-x">×</button></div></div>
  <div class="ds-static" style="margin-top:12px"><div class="toast on">Synchronisation terminée — 3 fiches mises à jour.<span class="t-life" style="animation-duration:6s"></span></div></div>
</div>
<p class="ds-cap">.notice = information (ambre) / erreur (vermillon) ; .alert-toast = banderole AMBRE VIF pulsée (distincte du chrome) ; .toast = confirmation non bloquante avec barre de vie.</p>`;

const headerDemo = `
<div style="max-width:560px;border:1px solid var(--line);border-radius:12px;overflow:hidden">
  <header class="bar home" style="position:static">
    <div class="id-row"><div class="brand"><span class="brand-name">Aides cognitives</span></div><button class="bar-acct on ini-on" style="position:static"><span class="acct-ini">VG</span><span class="acct-dot"></span></button></div>
  </header>
</div>
<p class="ds-cap">Barre d’accueil CLAIRE (couleur du fond) : recherche FIXE, boutons 40px (halo 44px), menu ⋯, compte en initiales. Connecté, la couleur d’ACCENT du compte teinte l’accueil entier et l’en-tête de toutes les vues — le contenu clinique reste bleu.</p>
<div style="max-width:560px;border:1px solid var(--line);border-radius:12px;overflow:hidden;margin-top:16px">
  <header class="bar titled ttl-on crisis" style="position:static">
    <div class="id-row"><button class="back">‹</button><button id="cbTimers" style="position:static"><span class="seg"><span class="seg-l">Adré</span><span class="seg-t">04:32</span></span><span class="cbt-n">+1</span><span class="seg glb"><span class="seg-l seg-sess">● Session</span><span class="seg-t">12:07</span></span></button><button class="bar-acct on ini-on" style="position:static"><span class="acct-ini">VG</span><span class="acct-dot"></span></button></div>
    <div id="crisisBand"><span class="cb-ttl">Choc anaphylactique</span><span class="cb-tag">■ Mode crise</span></div>
  </header>
</div>
<p class="ds-cap">En crise : bandeau TITRE permanent au registre ALERTE (fond --critical-soft + « ■ MODE CRISE » : texte, couleur ET position) ; minuteurs segmentés dans la barre à TOUTES les largeurs, suivis du chrono GLOBAL « ● Session » (temps écoulé depuis la 1ʳᵉ action). UNE seule zone fixe, en haut — jamais en bas.</p>
<div class="more-menu" style="position:static;margin-top:16px">
  <button class="mm-row">Modifier</button>
  <button class="mm-row">Versions</button>
  <div class="mm-sep" role="separator"></div>
  <button class="mm-row">Dupliquer</button>
  <button class="mm-row">Exporter (.json)</button>
  <button class="mm-row">Exporter en PDF</button>
  <div class="mm-sep" role="separator"></div>
  <button class="mm-row">Historique des sessions (3)</button>
  <div class="mm-sep" role="separator"></div>
  <button class="mm-row danger">Terminer la session…</button>
</div>
<p class="ds-cap">.more-menu — menu ⋯ (262px, rangées 44px, séparateurs entre groupes) : TOUTES les actions secondaires de lecture ; remplace les barres « Autorat » de bas de page. L’action destructrice est DERNIÈRE et rouge — jamais première, jamais pleine.</p>`;

const runtimeDemo = `
<div style="max-width:560px">
  <div class="rt-panel">
    <div class="rt-head"><b>Minuteurs &amp; compteurs</b><button class="rt-sound">🔊 Son</button></div>
    <div class="rt-grid">
      <div class="tmcard"><div class="tm-label">Adrénaline</div><div class="tm-val">03:47</div><div class="tm-bar-wrap"><div class="tm-bar" style="width:76%"></div></div><div class="tm-cyc">Cycles : 1</div><div class="tm-ctrl"><button class="tm-btn tm-main run">Pause</button><button class="tm-btn tm-reset" disabled><span class="tmr-lab">↺ 05:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="tmcard paused"><div class="tm-label">Remplissage — en pause</div><div class="tm-val">01:12</div><div class="tm-bar-wrap"><div class="tm-bar" style="width:40%"></div></div><div class="tm-cyc">Cycles : 0</div><div class="tm-ctrl"><button class="tm-btn tm-main">Relancer</button><button class="tm-btn tm-reset"><span class="tmr-lab">↺ 03:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="tmcard due"><div class="tm-label">■ Rythme — à réévaluer</div><div class="tm-val">00:00</div><div class="tm-bar-wrap"><div class="tm-bar" style="width:0%"></div></div><div class="tm-cyc">Cycles : 2</div><div class="tm-ctrl"><button class="tm-btn tm-main">Relancer</button><button class="tm-btn tm-reset"><span class="tmr-lab">↺ 02:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="cncard"><div class="tm-label">Adrénaline (doses)</div><div class="cn-val">3</div><div class="cn-ctrl"><button class="cn-btn">−</button><button class="cn-btn">+</button></div><div class="cn-note">＋ relance le minuteur « Adrénaline »</div><button class="cn-reset tm-reset"><span class="tmr-lab">Remettre à zéro</span><span class="tmr-hint">maintenir</span></button></div>
    </div>
    <div class="tm-mini" style="margin-top:10px"><span class="tmm-l">PA</span><span class="tmm-t">04:12</span><button class="tmm-b">⟲</button><button class="tmm-b">✕</button></div>
    <button class="rt-add">＋ Minuteur</button>
  </div>
</div>
<p class="ds-cap">Le panneau suit le THÈME (plus de panneau sombre forcé). L’état change le TEXTE de l’étiquette (« — en pause », « ■ … — à réévaluer »), jamais la couleur seule ; échu = AMBRE (--verify-bd/--verify-hi, pas de rouge : c’est une attente, pas une erreur) ; barre 4px du temps RESTANT — elle SE VIDE. « ↺ 05:00 » annonce ce que redonnera la réinitialisation (geste maintenir, DÉSACTIVÉ pendant que ça tourne). En crise : rail à droite ≥ 1000px (temps 34px), panneau repliable en étroit. .tm-mini = minuteur AD HOC (rangée 48px, ⟲ relance, ✕ retire) ajouté en session sans modifier la fiche.</p>`;

const sessionDemo = `
<div style="max-width:560px">
  <div class="live-sessions"><div class="ls-card"><span class="sess-dot"></span><div class="ls-info" role="button" tabindex="0"><b class="ls-k">Session en cours</b><span class="ls-t">Choc anaphylactique</span></div><span class="ls-chrono">14:32</span><button class="btn sm primary">Reprendre</button><button class="ls-end">Terminer</button></div></div>
</div>
<p class="ds-cap">Carte de session vive (accueil) : liseré primaire, point pulsé + « Session en cours » (état ANNONCÉ en texte), CHRONO mono vivant, « Reprendre » = seul bouton plein ; « Terminer » = TEXTE rouge, jamais plein, jamais premier (registre « raccrocher » : l’arrêt stoppe les minuteurs — ne pas le « corriger » en ambre). En lecture : plus de bandeau session dans le contenu — « Terminer la session… » vit dans le menu ⋯ (rangée danger) et l’« Historique des sessions » s’ouvre en MODALE (Rouvrir / supprimer). La carte d’accueil de la fiche porte « ● En cours ».</p>`;

const modalDemo = `
<div style="max-width:560px">
  <div class="ai-card dlg-480" style="box-shadow:var(--shadow-lg)">
    <div class="ai-top"><h3>Créer une aide cognitive</h3><button class="ai-x">×</button></div>
    <div class="ds-col" style="margin:0">
      <button class="crt-card"><span class="crt-ic" aria-hidden="true">✎</span><span><span class="crt-t">Rédiger moi-même</span><br><span class="crt-d">Éditeur complet : étapes, décisions, minuteurs, images.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
      <button class="crt-card" id="crtIA"><span class="crt-ic" aria-hidden="true">✦</span><span><span class="crt-t">Avec l’IA</span><br><span class="crt-d">Prompt à copier dans une IA, puis importer le JSON généré.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
      <button class="crt-card"><span class="crt-ic" aria-hidden="true">⤓</span><span><span class="crt-t">Importer un fichier</span><br><span class="crt-d">.json exporté ou généré — la fiche arrive en Brouillon.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
    </div>
  </div>
  <div class="ai-card dlg-480" style="box-shadow:var(--shadow-lg);margin-top:16px">
    <div class="ai-top"><h3>Bibliothèque SMUR</h3><button class="ai-x">×</button></div>
    <div class="mem-list"><div class="mem-row"><span class="mem-avatar">VG</span><span class="mem-info"><span class="mem-email">victor@chu.fr <span class="mem-you">(vous)</span></span></span><span class="mem-act"><span class="ro-badge">Propriétaire</span></span></div></div>
    <div class="dlg-actions"><button class="btn primary">Enregistrer</button><button class="btn">Fermer</button></div>
    <div class="mem-danger"><p class="mem-section-h danger-h">Zone sensible</p><button class="btn danger">Supprimer la bibliothèque…</button></div>
  </div>
</div>
<p class="ds-cap">.dlg-480 — gabarit UNIQUE des fenêtres de gestion (480px, titre 17px/800, croix 44px, Échap / tap hors carte, focus géré) ; plein écran &lt; 640px SAUF .dlg-confirm (confirmations 420px, TOUJOURS centrées). La ZONE SENSIBLE est séparée par un filet et vient en DERNIER, jamais près des actions courantes. Dialogue Créer : 3 méthodes en cartes 64px (glyphes ✎ ✦ ⤓), carte « Reprendre le brouillon » quand un brouillon auto-enregistré existe.</p>`;

/* ---- Fiches ---- */
const cards = [
  { path: 'foundations/colors.html', name: 'Couleurs & tokens', group: 'Fondations', subtitle: 'Neutres, bleu clinique, sémantiques, statuts, accents — 2 thèmes', h: 1750, demo: colorsDemo, title: 'Couleurs' },
  { path: 'foundations/typography.html', name: 'Typographie', group: 'Fondations', subtitle: 'Registres réels — plancher 11px, mono pour les chronos', h: 1350, demo: typeDemo, title: 'Typographie' },
  { path: 'foundations/shape.html', name: 'Formes, ombres & règles', group: 'Fondations', subtitle: 'Rayons, ombres, breakpoints fermés (430→1200), largeurs par vue', h: 1100, demo: shapeDemo, title: 'Formes & règles' },
  { path: 'foundations/categories.html', name: 'Palette des catégories', group: 'Fondations', subtitle: '13 teintes PALETTE + pilule neutre des cartes', h: 1050, demo: catDemo, title: 'Catégories' },
  { path: 'components/buttons.html', name: 'Boutons', group: 'Composants', subtitle: 'primary / tonal / pointillé / Continuer 2 états / maintenir', h: 1250, demo: buttonsDemo, title: 'Boutons' },
  { path: 'components/chips.html', name: 'Pastilles, tags & états', group: 'Composants', subtitle: 'Filtres, statuts achromatiques, synchro, compte en initiales', h: 1200, demo: chipsDemo, title: 'Pastilles & tags' },
  { path: 'components/cards.html', name: 'Cartes de bibliothèque', group: 'Composants', subtitle: 'Carte sobre : liseré couleur, pilule neutre, code mono, session vive', h: 1100, demo: cardsDemo, title: 'Cartes' },
  { path: 'components/forms.html', name: 'Formulaires', group: 'Composants', subtitle: 'Recherche, champs, sélecteur de catégories, code OTP', h: 1350, demo: formsDemo, title: 'Formulaires' },
  { path: 'components/lists.html', name: 'Listes de fiche', group: 'Composants', subtitle: 'Ne pas oublier, étapes 64px, Continuer, fin d’algorithme', h: 1900, demo: listsDemo, title: 'Listes' },
  { path: 'components/decision.html', name: 'Nœud de décision', group: 'Composants', subtitle: 'Carte ambre, options 64px, fil d’Ariane non destructif', h: 1250, demo: decisionDemo, title: 'Décision' },
  { path: 'components/notices.html', name: 'Notices, alertes & toasts', group: 'Composants', subtitle: 'Information, erreur de synchro, banderole ambre, toast', h: 1100, demo: noticesDemo, title: 'Notices & alertes' },
  { path: 'components/header.html', name: 'Barre d’en-tête', group: 'Composants', subtitle: 'Accueil (accent), bandeau de crise ALERTE, menu ⋯', h: 1600, demo: headerDemo, title: 'En-tête' },
  { path: 'components/runtime.html', name: 'Panneau temps réel', group: 'Composants', subtitle: 'Cartes à état textuel, échu ambre, ad hoc — suivent le thème', h: 1500, demo: runtimeDemo, title: 'Temps réel' },
  { path: 'components/session.html', name: 'Sessions', group: 'Composants', subtitle: 'Carte de session vive ; Terminer via menu ⋯, historique en modale', h: 800, demo: sessionDemo, title: 'Sessions' },
  { path: 'components/modal.html', name: 'Modale', group: 'Composants', subtitle: 'dlg-480, dialogue Créer, zone sensible, confirmations 420px', h: 1500, demo: modalDemo, title: 'Modale' },
];

for (const c of cards) {
  const marker = `<!-- @dsCard group="${c.group}" name="${c.name}" subtitle="${c.subtitle}" viewport="760x${c.h}" -->`;
  const file = marker + '\n' + page(c.title, c.demo);
  const out = join(OUT, c.path);
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, file);
  console.log('  ✓', c.path, `(${(file.length / 1024).toFixed(0)} ko)`);
}

/* tokens.css : extraction brute, pour référence machine */
mkdirSync(join(OUT, 'tokens'), { recursive: true });
writeFileSync(join(OUT, 'tokens', 'tokens.css'),
  `/* Tokens extraits de index.html (source de vérité) — ne pas éditer ici. */\n${rootTokens}\n\n/* Thème sombre */\n${darkTokens.replace('html[data-theme="dark"]', '[data-theme="dark"]')}\n\n/* Palette des catégories (PALETTE, index.html) */\n:root{${PALETTE.map((c, i) => `--cat-${i + 1}:${c}`).join(';')}}\n`);
console.log('  ✓ tokens/tokens.css');

console.log(`\nGénéré dans design/ds/ — ${cards.length} fiches + tokens.css`);
