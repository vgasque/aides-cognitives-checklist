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
  .ds-scope{background:var(--amb);color:var(--ink);padding:20px 22px 26px;font-family:var(--f-ui)}
  .ds-lab{font:700 10px/1 var(--f-mono);letter-spacing:1.5px;text-transform:uppercase;color:var(--ink-soft);margin:0 0 16px}
  .ds-row{display:flex;gap:10px;flex-wrap:wrap;align-items:center;margin:0 0 14px}
  .ds-col{display:flex;flex-direction:column;gap:12px;margin:0 0 14px}
  .ds-cap{font-size:11px;color:var(--ink-soft);margin:-6px 0 14px}
  .ds-item{display:flex;flex-direction:column;gap:5px;align-items:flex-start}
  .ds-item>small{font:600 10px/1.3 var(--f-mono);color:var(--ink-soft)}
  .ds-sw{width:104px;border:1px solid var(--line);border-radius:9px;overflow:hidden;background:var(--work)}
  .ds-sw>i{display:block;height:44px}
  .ds-sw>b{display:block;font:600 9.5px/1.3 var(--f-mono);padding:5px 7px;color:var(--ink);word-break:break-all}
  .ds-sw>small{display:block;font-size:9.5px;line-height:1.3;padding:0 7px 6px;color:var(--ink-soft)}
  .ds-fix>*,.ds-fix>*>*{position:static!important;inset:auto!important;transform:none!important}
  .ds-fix #sessionDock{padding:0;pointer-events:auto}
  .ds-capt+.ds-cap{margin-top:10px}
  .ds-static .toast{position:static;left:auto;bottom:auto;transform:none;opacity:1;pointer-events:auto;max-width:520px}
  .ds-static #alerts,.ds-static .alerts{position:static;padding:0;align-items:flex-start}
  .ds-type{margin:0 0 16px}
  .ds-type>small{display:block;font:600 10px/1 var(--f-mono);color:var(--ink-soft);margin-bottom:4px}
  /* (L'habillage .ds-reader, qui ramenait le mode lecteur plein écran dans le flux de l'aperçu,
   * est PARTI AVEC LUI — la surface a été retirée au lot T14, v5.0.0. Ce build publiait encore sa
   * fiche : on montrait un composant inexistant, dont plus aucune classe rm-* n'avait de règle.
   * Même défaut que la démo planDemo corrigée en v4.31.1 — règle 14, la purge emporte la doc.
   * ⚠ Ce bloc vit DANS un littéral gabarit : pas de backticks ici, ils le termineraient. */
`;

const esc = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');
/* Captures du DOM RÉEL (design/capture.mjs) : les surfaces de crise ne s'écrivent plus à la main. */
const cap = n => { try { return readFileSync(join(ROOT, 'design', 'captures', n + '.html'), 'utf8').trim(); }
  catch (e) { console.error(`✗ design/captures/${n}.html manquant — lancer node design/capture.mjs`); process.exit(1); } };
const crise = h => `<div class="ov-wrap"><div class="ov-journal">${h}</div></div>`;
/* ✓ de l'app (uiIcon('check')) — pastilles d'étape faite, cases cochées, chips du fil. */
const chk = (s = 13, sw = 3.2) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"><path d="M4 12l5 5L20 6"/></svg>`;

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
/* Tokens ACTUELS, rangés par registre (règle 8). ⚠ La liste citait encore 31 alias purgés en A416
   (v5.38.1) : leurs pastilles étaient vides. `colorsCheck` (plus bas) refuse désormais un token absent. */
const COLOR_ROWS = [
  ['Matières', [['amb', 'ambiance — fond de page'], ['amb-2', 'pistes, champs, fonds neutres'], ['work', 'matière de travail — cartes, feuilles'], ['work-line', 'bord des cartes'], ['paper', 'la Page (papier)']]],
  ['Encres et filets', [['ink', 'texte'], ['ink-2', 'texte secondaire'], ['ink-3', 'DÉCORATIF seul — jamais du texte'], ['line', 'filets doux'], ['line-strong', 'bordures ≥ 3:1 (champs, cases)'], ['ctl-line', 'contour de composant']]],
  ['Action — bleu', [['act', 'l’action et le bloc courant'], ['primary-soft', 'fonds bleus, notices système'], ['primary-100', 'survol, sélection'], ['primary-200', 'bord des notices'], ['on-primary', 'texte sur bleu']]],
  ['Fait — vert', [['ok', 'fait, système nominal'], ['ok-soft', 'fonds verts'], ['done-line', 'étape cochée — bord']]],
  ['Se tromper — ambre', [['warn', 'dose, seuil, échéance — texte'], ['warn-line', 'bord ambre'], ['warn-soft', 'fonds ambres'], ['verify-line', 'bord doux ambre'], ['alarm-bd', 'alarme de minuteur'], ['bolt', 'éclair de complication'], ['bolt-edge', 'contour de l’éclair']]],
  ['Tue si oublié — rouge', [['crit', 'CRITIQUE, alarme active — texte'], ['crit-line', 'bord rouge'], ['crit-soft', 'fonds rouges'], ['critical-line', 'bord doux rouge']]],
  ['Système — quai et capsule sombres', [['sys', 'matière système'], ['sys-hi', 'survol système'], ['sys-ink', 'texte système'], ['sys-ink-2', 'texte système secondaire'], ['sys-line', 'filets système'], ['ok-sys', 'vert sur système'], ['warn-sys', 'ambre sur système'], ['crit-sys', 'rouge sur système']]],
  ['Voiles', [['scrim-soft', 'voile léger'], ['scrim', 'voile des fenêtres'], ['scrim-full', 'voile plein écran']]],
];
const colorsDemo = `
${COLOR_ROWS.map(([t, row]) => `<p class="ds-cap" style="margin:0 0 6px;font-weight:700">${t}</p><div class="ds-row">${row.map(([v, n]) => swatch(v, n)).join('')}</div>`).join('')}
<p class="ds-cap">TROIS ROUGES distincts, jamais fusionnés : --crit (texte, CRITIQUE, alarme active), --crit-line (bords rouges) et le rouge d’une CATÉGORIE de la palette — liseré/pastille, jamais un signal d’alerte. Rien de permanent n’est rouge (A406).</p>
<div class="ds-row" style="align-items:flex-end">
  <div class="ds-item"><span class="acc-sw a-clinique on"></span><small>défaut — bleu clinique</small></div>
  <div class="ds-item"><span class="acc-sw a-teal"></span><small>sarcelle</small></div>
  <div class="ds-item"><span class="acc-sw a-violet"></span><small>violet</small></div>
  <div class="ds-item"><span class="acc-sw a-indigo"></span><small>indigo</small></div>
  <div class="ds-item"><span class="acc-sw a-framboise"></span><small>framboise</small></div>
  <div class="ds-item"><span class="acc-sw a-ardoise"></span><small>ardoise</small></div>
</div>
<p class="ds-cap">Registres FIXES (règle 8) : rouge = ce qui TUE si on l’oublie, et l’alarme active ; ambre = là où l’on risque de SE TROMPER (dose, seuil, échéance) ; vert = fait, ou système nominal ; bleu = l’action et le bloc courant. Ce qui tourne normalement n’a PAS de couleur. Une couleur n’est jamais seule : toujours un glyphe et un mot. --ink-3 est DÉCORATIF seulement (texte secondaire = --ink-2). COULEUR D’ACCENT par utilisateur (v4.5) : 5 nuances AA + bleu par défaut, CONNECTÉ seulement ; portée = accueil entier + en-tête de toutes les vues ; le contenu clinique (crise, protocoles, éditeurs) reste bleu clinique ; jamais de vert/ambre/rouge en accent (registres réservés).</p>`;

{const manquants = COLOR_ROWS.flatMap(([, r]) => r.map(([v]) => v)).filter(v => !new RegExp('--' + v + ':').test(appCss));
 if (manquants.length) { console.error('✗ Couleurs : tokens absents de index.html → ' + manquants.join(', ')); process.exit(1); }}
const typeDemo = `
<div class="ds-type"><small>Marque / titre d’en-tête — .brand-name · 18px / 800</small><span style="font-size:18px;font-weight:800;letter-spacing:-.2px">Aides cognitives</span></div>
<div class="ds-type"><small>Titre du bandeau de crise — #crisisBand .cb-ttl · 18px / 800 (registre ALERTE)</small><span style="font-size:18px;font-weight:800;letter-spacing:-.2px">Choc anaphylactique</span></div>
<div class="ds-type"><small>Titre de fiche — .read-head h2 · 24px / 680</small><span style="font-size:24px;font-weight:680;line-height:1.18">Choc anaphylactique</span></div>
<div class="ds-type"><small>Question de décision — .question · 16px / 700 (18px &lt; 560px)</small><span style="font-size:16px;font-weight:700;line-height:1.3">Le patient est-il conscient&nbsp;?</span></div>
<div class="ds-type"><small>Titre de section — .block-h · 11px / 800 capitales espacées (registre UNIQUE de titres)</small><span class="block-h" style="margin:0">Prise en charge</span></div>
<div class="ds-type"><small>Corps d’étape — ol.steps .txt · 16px</small><span style="font-size:16px;line-height:1.45">Allonger le patient, surélever les jambes.</span></div>
<div class="ds-type"><small>Contenu rédigé — .md-body · 15px / 1.55</small><span style="font-size:15px;line-height:1.55">Texte courant des protocoles (mini-Markdown).</span></div>
<div class="ds-type"><small>Temps — .tm-val · mono 26px / 700 tabular-nums (34px dans le rail de crise ≥ 1000px)</small><span style="font-family:var(--f-mono);font-size:26px;font-weight:700;letter-spacing:1px;font-variant-numeric:tabular-nums">04:32</span></div>
<div class="ds-type"><small>Étiquette — .tag · 11px / 600 (plancher de l’app)</small><span class="tag">Adulte</span></div>
<div class="ds-type"><small>Statut — .status-tag · 10.5px / 700 (pilule-capitale graisseuse : exception unique au plancher, spec canvas)</small><span class="status-tag">✓ Validée</span></div>
<p class="ds-cap">Police système (var(--f-ui)) ; mono (var(--f-mono)) réservée aux valeurs qui défilent (chronos, compteurs, numéros d’étape). Plancher typographique 11px pour tout texte courant — app consultée sous stress ; seules les pilules-capitales à forte graisse (.status-tag, .tm-label) descendent à 10.5px.</p>`;

const shapeDemo = `
<div class="ds-row">
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--work);border:1px solid var(--line);border-radius:var(--r-4)"></div><small>--r-4 14px · cartes</small></div>
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--work);border:1px solid var(--line);border-radius:var(--r-3)"></div><small>--r-3 11px · boutons, champs</small></div>
  <div class="ds-item"><div style="width:88px;height:56px;background:var(--work);border:1px solid var(--line);border-radius:var(--r-1)"></div><small>--r-1 9px · petits contrôles</small></div>
  <div class="ds-item"><div style="width:88px;height:36px;background:var(--work);border:1px solid var(--line);border-radius:20px"></div><small>20px · pastilles / tags</small></div>
</div>
<div class="ds-row">
  <div class="ds-item"><div style="width:120px;height:64px;background:var(--work);border-radius:var(--r-4);box-shadow:var(--shadow-work)"></div><small>--shadow-work · cartes</small></div>
  <div class="ds-item"><div style="width:120px;height:64px;background:var(--work);border-radius:var(--r-4);box-shadow:var(--shadow-work)"></div><small>--shadow-work · survol / flottant</small></div>
</div>
<div class="ds-col" style="font-size:13px;line-height:1.6;max-width:560px">
  <div><b>Breakpoints (échelle FERMÉE)</b> : 430 / 560 / 640 / 780 / 900 / 1000 / 1200 px — aucun nouveau palier sans décision explicite (référence : AGENTS.md, § Largeurs).</div>
  <div><b>Largeurs par vue</b> : accueil = sidebar 255px + grille ≤ 1320px, COQUE FIXE ≥ 780 (seuls la sidebar et le contenu défilent) ; fiche ≤ 860px + rail minuteurs 320 → 360px ; protocole ≤ 780px ; éditeurs alignés sur leur lecture + aperçu sticky 360px (≥ 1000).</div>
  <div><b>Cibles tactiles</b> : ≥ 32 px partout, ≥ 44 px pour les contrôles du mode crise ; halo cliquable (::after) quand le contrôle visuel est plus petit (boutons 36–40px de la barre, pastilles de chips).</div>
  <div><b>Focus clavier</b> : outline 2px var(--act), offset 2px, sur tout contrôle.</div>
  <div><b>Anti-accident</b> : geste « maintenir » (jauge --crit-line) pour le destructif en crise ; garde temporelle 700 ms (.guarded, opacité réduite) entre deux boutons « retour » empilés (logique ECAM).</div>
</div>`;

const catDemo = `
<div class="ds-row">${PALETTE.map(c => `<div class="ds-item"><span style="width:34px;height:34px;border-radius:8px;background:${c};display:block"></span><small>${c}</small></div>`).join('')}</div>
<p class="ds-cap">PALETTE : 13 teintes de catégories (choisies par l’utilisateur, jamais de nouvelle teinte codée en dur hors :root/PALETTE).</p>
<div class="ds-row">${PALETTE.slice(0, 5).map((c, i) => `<span class="tag cat" style="--c:${c};--catcol:${c}"><span class="cat-dot"></span>Catégorie ${i + 1}</span>`).join('')}</div>
<p class="ds-cap">.tag.cat — pastille + étiquette teintée ≤ 15 % avec texte de la couleur (règle SPEC crise §1 : jamais d’aplat ; la couleur n’est jamais seule) : lecture de fiche.</p>
<div class="ds-row"><span class="tag cat neutral" style="--catcol:${PALETTE[8]}"><span class="cat-dot"></span>Urgences</span><span class="tag cat neutral" style="--catcol:${PALETTE[3]}"><span class="cat-dot"></span>Voies aériennes</span></div>
<p class="ds-cap">.tag.cat.neutral — sur les CARTES d’accueil la pilule reste NEUTRE (--amb-2/--ink-2) : le liseré gauche 4px porte la couleur, la pastille l’identifie dans la méta.</p>
<div class="ds-row">${PALETTE.slice(5, 9).map((c, i) => `<button class="catchip"><span class="cat-dot" style="--catcol:${c}"></span>Filtre ${i + 1}</button>`).join('')}</div>
<p class="ds-cap">.catchip — la couleur de catégorie ne vit qu’en PASTILLE à anneau (SPEC crise §1a, v4.3.0) ; la sélection est le bleu système, jamais la couleur.</p>`;

const plus = (s = 14) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><path d="M12 5v14M5 12h14"/></svg>`;
const buttonsDemo = `
<div class="ds-row"><button class="btn primary">Enregistrer</button><button class="btn">Annuler</button><button class="btn danger">Supprimer</button><button class="btn" disabled>Désactivé</button><button class="btn sm">Petit (.sm)</button></div>
<p class="ds-cap">.btn — 44px min ; UN SEUL bouton rempli (--act) par écran ; .danger = liseré vermillon, fond au survol seulement.</p>
<div class="ds-row"><button class="rang-btn">${plus(16)}Ajouter des aides</button><button class="catmenu-new" style="width:240px">＋ Nouvelle collection…</button><button class="add-line" style="width:220px">+ Ajouter une ligne</button></div>
<p class="ds-cap">Grammaire des boutons de gestion : POINTILLÉ = créer (.catmenu-new, .add-line), FOND NEUTRE --amb-2 = commande de liste (.rang-btn : Affichage, Sélectionner, Ajouter des aides — M 40, A375), CONTOUR = secondaire, PLEIN = action primaire, un seul par écran.</p>
<div class="ds-row"><button class="btn cont idle" aria-disabled="true" style="max-width:300px">Cochez les étapes restantes (2)</button><button class="btn cont okay" style="max-width:300px">Continuer — réévaluation à 5 min →</button></div>
<p class="ds-cap">.btn.cont — UN bouton, deux états : inactif il DIT pourquoi (et combien il reste — jamais muet), actif il ANNONCE la destination (champ nextLbl du bloc) au bleu de l’ACTION (--act, A406 : le vert reste « fait ») ; dernier bloc = « Terminer l’algorithme ✓ » (qui n’arrête PAS la session).</p>
<div class="ds-row"><button class="btn-end-sess"><span class="tmr-lab">Terminer</span><span class="es-hold">maintenir 1,2 s</span></button><button class="back"><svg class="tic" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M15 18l-6-6 6-6"/></svg> Retour</button><button class="linkbtn">Gérer</button><button class="tlink">Exporter</button></div>
<p class="ds-cap">Geste « maintenir » anti-accidentel (holdToReset) : « Terminer » se maintient 1,2 s et le dit DANS le bouton (A346, A460) ; relâcher avant la fin annule. .back, .linkbtn, .tlink — actions secondaires ; un « retour » venant d’apparaître sous le doigt est inhibé 700 ms (.guarded).</p>
<div class="ds-row"><button class="mini">↑</button><button class="mini">↓</button><button class="mini del">×</button></div>
<p class="ds-cap">.mini — micro-contrôles d’éditeur.</p>`;

const chipsDemo = `
<div class="ds-row"><button class="catchip on">Toutes</button><button class="catchip"><span class="cat-dot" style="--catcol:${PALETTE[0]}"></span>Adulte</button><button class="catchip"><span class="cat-dot" style="--catcol:${PALETTE[6]}"></span>Pédiatrie</button><button class="catchip mgr">Gérer…</button></div>
<p class="ds-cap">.catchip — filtres de catégories : pastille .cat-dot à anneau + nom ; .on = sélection BLEU SYSTÈME (jamais la couleur de la catégorie, v4.3.0) ; .mgr = action en retrait (pointillés).</p>
<div class="ds-row"><span class="status-tag">✓ Validée</span><span class="status-tag">△ À relire</span><span class="status-tag">○ Brouillon</span><span class="tag todo">△ À compléter</span><span class="tag live">● En cours</span><span class="tag sess">3 sauvegardées</span><span class="tag flow">Algorithme</span><span class="tag libtag"><svg class="tic" width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><path d="M4 4h7l2 3h7v13H4z"/></svg> Bibliothèque SMUR</span></div>
<p class="ds-cap">.status-tag — pilule ACHROMATIQUE unique pour les 3 statuts (--amb-2/--ink-2), affichée sur cartes, lecture et éditeurs (y compris « ✓ Validée ») ; .tag.todo est cliquable (souligné pointillé = affordance détail) ; .tag.live = session vive (vert --ok, état annoncé en texte).</p>
<div class="ds-row"><span class="sync-chip off">Hors ligne</span><span class="sync-chip ok">Synchronisé</span><span class="sync-chip busy">Synchro…</span><span class="sync-chip pending">En attente</span><span class="sync-chip err">Erreur</span></div>
<p class="ds-cap">.sync-chip — état de synchro, jamais bloquant : ok = --ok, attente = --warn, erreur = --crit, inactif = --line-strong.</p>
<div class="ds-row">
  <span class="bar-acct on ini-on" style="position:static"><span class="acct-ini">VG</span><span class="acct-dot"></span></span>
  <span class="bar-acct" style="position:static"><svg class="ic-outline" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="3.6"/><path d="M5.5 20.5v-1a5 5 0 015-5h3a5 5 0 015 5v1"/></svg></span>
</div>
<p class="ds-cap">.bar-acct — connecté : INITIALES de l’e-mail (2 lettres, .acct-ini) + pastille d’état ; déconnecté : icône personne en contour, sans initiales. La couleur n’est jamais seule (initiales + chip texte ailleurs).</p>
<div class="ds-row"><span class="rel-chip">Fiche liée <button class="rel-x">×</button></span><span class="ro-badge">Lecture seule</span><span class="pend-badge pending">En attente</span><span class="pend-badge rejected">Refusé</span></div>`;

const cardsDemo = `
<div class="ds-capt" style="max-width:420px">${cap('accueil')}</div>
<p class="ds-cap">Capture réelle, accueil au téléphone (A347, A389, A475) : tuiles d’Accès direct (liseré de catégorie 6 px), rangée « Mes collections · à vous seul », ligne de COMPTE qui porte « Sélectionner », puis les cartes rangées par catégorie — identité à gauche (nature · discriminant · ● catégorie · bibliothèque), UN état en mots à droite (A338, A422), étoile d’épinglage. La couleur de catégorie ne vit que dans le liseré et la pastille.</p>`;

const formsDemo = `
<div style="max-width:520px">
  <div class="ds-row" style="flex-wrap:nowrap"><div class="search" style="flex:1"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></svg><input placeholder="Rechercher une aide, un protocole…"></div></div>
  <div class="field"><label>Titre de la fiche</label><input type="text" value="Choc anaphylactique"></div>
  <div class="row2">
    <div class="field"><label>Catégorie</label><select><option>Urgence vitale</option></select></div>
    <div class="field"><label>Validation <span class="hint">MM/AAAA</span></label><input type="text" value="03/2026"></div>
  </div>
  <div class="field"><label>Contexte local</label><textarea rows="3">Chariot d’urgence : salle 2. Adrénaline au réfrigérateur.</textarea></div>
  <div class="field"><label>Catégorie</label><div class="cat-picker"><button class="cat-chip-selected" style="--catcol:${PALETTE[2]}"><span class="cat-dot"></span>Toxicologie</button><button class="cat-chip-other">Autre…</button></div></div>
  <input class="auth-field auth-code" value="482913" aria-label="Code reçu">
</div>
<p class="ds-cap">Fond des champs = --work (jamais codé en dur) ; bordure --line-strong (≥ 3:1) ; focus = outline 2px --act ; police 16px (anti-zoom iOS).</p>`;

const listsDemo = `
<div class="ds-capt" style="max-width:620px">${crise(cap('etapes'))}
  <section class="block" style="margin-top:16px"><div class="block-h h-diff"><span class="pip"></span>Diagnostics différentiels</div>
    <ul class="flat diff"><li>Malaise vagal</li><li>Œdème de Quincke isolé</li></ul>
  </section>
</div>
<p class="ds-cap">Capture réelle (A345) : toutes les étapes partagent le même corps et la même colonne, case à DROITE ; le danger est un MOT — étiquette CRITIQUE (--crit) ou VIGILANCE (--warn) + bordure de case au registre + texte .sr-only, jamais un glyphe ⚠/△. Sous l’étape, en gris : la réponse attendue (« challenge :: réponse »). « Continuer » ne s’active qu’étapes cochées, et dit pourquoi tant qu’il ne l’est pas ; « Vérifier » ouvre la passe de constat.</p>`;

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
<div class="ds-capt ds-fix" style="max-width:420px;border:1px solid var(--line);border-radius:12px;overflow:hidden">${cap('entete-accueil')}</div>
<p class="ds-cap">Capture réelle, accueil au téléphone : marque, puis Sessions · Créer · Moi en pastilles de 40 px portant leur MOT dessous (A461) ; « Moi » porte les initiales du compte une fois connecté (ici déconnecté : l’icône). Au bureau ces portes vivent dans la colonne gauche et l’en-tête ne porte que la recherche et « Créer ».</p>
<div class="ds-capt ds-fix" style="max-width:420px;margin-top:16px">${cap('capsule')}</div>
<p class="ds-cap">Capture réelle, la CAPSULE d’état (matière système, en haut, jamais occultée) : chrono de session puis minuteurs et compteurs en tuiles, ordre FIXE, constants d’abord (A347, A462). Au bureau large (≥ 1440 px) elle monte dans l’en-tête.</p>
<div class="ds-capt ds-fix" style="max-width:420px;margin-top:16px;position:relative">${cap('quai')}</div>
<p class="ds-cap">Capture réelle, le QUAI au pouce : quatre touches de largeur égale, position CONSTANTE — Fin · Tout voir · Complications · Horodater (A346, A354, A412). « Horodater » est la seule REMPLIE ; « Fin » porte le ■ rouge système et ouvre une confirmation qui se MAINTIENT 1,2 s.</p>
<div class="ds-capt ds-fix" style="max-width:340px;margin-top:16px">${cap('menu')}</div>
<p class="ds-cap">Capture réelle, menu ⋯ en session (ancré au bureau, feuille basse sous 780 px — A361) : il ne répète pas le quai (A337), tuiles d’ouverture, intertitres, « L’aide › » replié en session (Modifier, Ajouter à une collection…, exports) — hors session ces rangées sont à plat, et « Ajouter à une collection… » reste actif quand « Modifier » est grisé (lecture seule).</p>`;

const runtimeDemo = `
<div style="max-width:560px">
  <div class="rt-panel">
    <div class="rt-head"><b>Minuteurs &amp; compteurs</b><button class="rt-sound">🔊 Son</button></div>
    <div class="rt-grid">
      <div class="tmcard"><div class="tm-label">Adrénaline</div><div class="tm-val">03:47</div><div class="tm-bar-wrap"><div class="tm-bar" style="transform:scaleX(0.7600)"></div></div><div class="tm-cyc">Cycles : 1</div><div class="tm-ctrl"><button class="tm-btn tm-main run">Pause</button><button class="tm-btn tm-reset" disabled><span class="tmr-lab">↺ 05:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="tmcard paused"><div class="tm-label">Remplissage — en pause</div><div class="tm-val">01:12</div><div class="tm-bar-wrap"><div class="tm-bar" style="transform:scaleX(0.4000)"></div></div><div class="tm-cyc">Cycles : 0</div><div class="tm-ctrl"><button class="tm-btn tm-main">Relancer</button><button class="tm-btn tm-reset"><span class="tmr-lab">↺ 03:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="tmcard due"><div class="tm-label">■ Rythme — à réévaluer</div><div class="tm-val">00:00</div><div class="tm-bar-wrap"><div class="tm-bar" style="transform:scaleX(0.0000)"></div></div><div class="tm-cyc">Cycles : 2</div><div class="tm-ctrl"><button class="tm-btn tm-main">Relancer</button><button class="tm-btn tm-reset"><span class="tmr-lab">↺ 02:00</span><span class="tmr-hint">maintenir</span></button></div></div>
      <div class="cncard"><div class="tm-label">Adrénaline (doses)</div><div class="cn-val">3</div><div class="cn-ctrl"><button class="cn-btn">−</button><button class="cn-btn">+</button></div><div class="cn-note">＋ relance le minuteur « Adrénaline »</div><button class="cn-reset tm-reset"><span class="tmr-lab">Remettre à zéro</span><span class="tmr-hint">maintenir</span></button></div>
    </div>
    <div class="tm-mini" style="margin-top:10px"><span class="tmm-l">PA</span><span class="tmm-t">04:12</span><button class="tmm-b">⟲</button><button class="tmm-b">✕</button></div>
    <button class="rt-add">＋ Minuteur</button>
  </div>
</div>
<p class="ds-cap">Le panneau suit le THÈME (plus de panneau sombre forcé). L’état change le TEXTE de l’étiquette (« — en pause », « ■ … — à réévaluer »), jamais la couleur seule ; échu = AMBRE (--warn-line/--warn-line, pas de rouge : c’est une attente, pas une erreur) ; barre 4px du temps RESTANT — elle SE VIDE. « ↺ 05:00 » annonce ce que redonnera la réinitialisation (geste maintenir, DÉSACTIVÉ pendant que ça tourne). En crise : rail à droite ≥ 1000px (temps 34px), panneau repliable en étroit. .tm-mini = minuteur AD HOC (rangée 48px, ⟲ relance, ✕ retire) ajouté en session sans modifier la fiche.</p>`;

const sessionDemo = `
<div style="max-width:560px">
  <div class="live-sessions"><div class="ls-card"><span class="sess-dot"></span><div class="ls-info" role="button" tabindex="0"><b class="ls-k">Session en cours</b><span class="ls-t">Choc anaphylactique</span></div><span class="ls-chrono">14:32</span><button class="btn sm primary">Reprendre</button><button class="ls-end">Terminer</button></div></div>
  <div class="last-sess" style="margin-top:12px"><span class="lsr-ic" aria-hidden="true">${chk(15, 3)}</span><div class="lsr-tx"><b>Session terminée</b> — Arrêt cardiaque adulte · 12 min · 5/6 blocs ✓</div><button class="btn sm">Compte-rendu</button><button class="notice-x" aria-label="Masquer le bilan">×</button></div>
</div>
<p class="ds-cap">CARTE-BILAN DE FIN DE SESSION (.last-sess, v4.16.3, décision utilisateur) : après « Terminer », l’accueil affiche une carte ÉPHÉMÈRE au registre CONFIRMATION — titre · durée · k/n blocs ✓ + « Compte-rendu ». Elle vit en MÉMOIRE seulement (lastEndedSession, jamais persistée : la vérité archivée est la session) et disparaît d’un tap ou au démarrage de la session suivante — le débriefing est DISPONIBLE, jamais imposé (ECAM).</p>
<p class="ds-cap">Carte de session vive (accueil) : liseré primaire, point pulsé + « Session en cours » (état ANNONCÉ en texte), CHRONO mono vivant, « Reprendre » = seul bouton plein ; « Terminer » = TEXTE rouge, jamais plein, jamais premier (registre « raccrocher » : l’arrêt stoppe les minuteurs — ne pas le « corriger » en ambre). En lecture : plus de bandeau session dans le contenu — « Terminer la session… » vit dans le menu ⋯ (rangée danger) et l’« Historique des sessions » s’ouvre en MODALE (Rouvrir / supprimer). La carte d’accueil de la fiche porte « ● En cours ».</p>`;

const modalDemo = `
<div style="max-width:560px">
  <div class="ai-card dlg-480" style="box-shadow:var(--shadow-work)">
    <div class="ai-top"><h3>Créer une aide cognitive</h3><button class="ai-x">×</button></div>
    <div class="ds-col" style="margin:0">
      <button class="crt-card"><span class="crt-ic" aria-hidden="true"><svg class="tic" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17 3a2.83 2.83 0 014 4L7.5 20.5 2 22l1.5-5.5z"/></svg></span><span><span class="crt-t">Rédiger moi-même</span><br><span class="crt-d">Éditeur complet : étapes, décisions, minuteurs, images.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
      <button class="crt-card" id="crtIA"><span class="crt-ic" aria-hidden="true"><svg class="tic" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path fill="currentColor" d="M11 4l1.7 4.3L17 10l-4.3 1.7L11 16l-1.7-4.3L5 10l4.3-1.7z"/><path fill="currentColor" d="M18.5 14.5l.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z"/></svg></span><span><span class="crt-t">Avec l’IA</span><br><span class="crt-d">Prompt à copier dans une IA, puis importer le JSON généré.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
      <button class="crt-card"><span class="crt-ic" aria-hidden="true"><svg class="tic" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v12M6 11l6 6 6-6"/><path d="M4 21h16"/></svg></span><span><span class="crt-t">Importer un fichier</span><br><span class="crt-d">.json exporté ou généré — la fiche arrive en Brouillon.</span></span><span class="crt-chev" aria-hidden="true">›</span></button>
    </div>
  </div>
  <div class="ai-card dlg-480" style="box-shadow:var(--shadow-work);margin-top:16px">
    <div class="ai-top"><h3>Bibliothèque SMUR</h3><button class="ai-x">×</button></div>
    <div class="dlg-actions"><button class="btn">Annuler</button><button class="btn primary">Enregistrer</button></div>
    <div class="mem-list"><div class="mem-row"><span class="mem-avatar">VG</span><span class="mem-info"><span class="mem-email">victor@chu.fr <span class="mem-you">(vous)</span></span></span><span class="mem-act"><span class="ro-badge">Propriétaire</span></span></div></div>
    <div class="mem-danger"><p class="mem-section-h danger-h">Zone sensible</p><button class="btn outline-danger">Supprimer la bibliothèque…</button></div>
  </div>
</div>
<p class="ds-cap">.dlg-480 — gabarit UNIQUE des fenêtres de gestion (480px, titre 17px/800, croix 44px, Échap / tap hors carte, focus géré) ; plein écran &lt; 640px SAUF .dlg-confirm (confirmations 420px, TOUJOURS centrées). Annuler/Enregistrer vivent SOUS LE CHAMP qu'ils enregistrent (le nom) — les changements de membres, eux, s'appliquent immédiatement ; la ZONE SENSIBLE est séparée par un filet et vient en DERNIER, jamais près des actions courantes. Dialogue Créer : 3 méthodes en cartes 82px (icônes SVG uiIcon 26px uniformes), carte « Reprendre le brouillon » quand un brouillon auto-enregistré existe.</p>
<div style="max-width:400px">
  <div class="ai-card endsess-dlg" style="box-shadow:var(--shadow-work)">
    <h3 class="dlg-title">Terminer la session ?</h3>
    <p class="dlg-context"><strong>Arrêt cardiaque adulte</strong> — session en cours depuis <strong>12 min</strong>.</p>
    <p class="dlg-consequences">Le chrono global et tous les minuteurs s'arrêtent. La session quitte l'accueil. Le déroulé horodaté reste consultable dans l'historique.</p>
    <div class="endsess-actions"><button class="btn-continue-sess">Poursuivre</button><button class="btn-end-sess">Terminer</button></div>
  </div>
</div>
<p class="ds-cap">Dialogue « Terminer la session ? » (SPEC crise §3, v4.3.0) — SEULE porte de sortie d'une session (menu ⋯, fin d'algorithme, ✕ du bandeau : jamais d'arrêt direct). Contexte (titre + durée) puis CONSÉQUENCES annoncées AVANT le choix ; « Poursuivre » = action sûre (contour, focus initial, Échap) ; « Terminer » = rouge système PLEIN (--crit-line), l'un des SEULS de l'app — même largeur : la grammaire contour/plein porte seule la différence. Toujours centré, même sur mobile.</p>
<div id="confirmModal" style="max-width:420px">
  <div class="ai-card" style="box-shadow:var(--shadow-work)">
    <div class="ai-top"><h3>Confirmer</h3><button class="ai-x" aria-label="Fermer">×</button></div>
    <p style="white-space:pre-line;font-size:14.5px;color:var(--ink)">Supprimer cette fiche ? Ses sessions archivées seront aussi supprimées.</p>
    <div style="display:flex;gap:9px;justify-content:flex-end;flex-wrap:wrap;margin-top:14px"><button class="btn">Annuler</button><button class="btn danger">Supprimer</button></div>
  </div>
</div>
<p class="ds-cap">Confirmation DESTRUCTRICE (v4.3.1) — #confirmModal en mode danger (supprimer une aide, un protocole, la bibliothèque…) reprend le registre du dialogue « Terminer la session » : bouton principal rouge PLEIN --crit-line + texte blanc, UNIQUEMENT dans la fenêtre de confirmation finale. Les boutons « Supprimer » de fin de formulaire et des zones sensibles restent en CONTOUR (.outline-danger / .btn.danger hors confirmation = liseré vermillon). ✕ / Échap / fond = abandon, distinct du bouton secondaire.</p>`;

/* ---- Parcours de soin : rail ①②③ + bascule Dynamique/Statique (v4.4.0, v4.16.0) ---- */
const carePathDemo = `
<div class="ds-capt" style="max-width:420px">${cap('demarrage')}</div>
<p class="ds-cap">Capture réelle, téléphone, avant la session (A330, A358, A366) : l’écran de démarrage se lit en chapitres — « Quand l’utiliser », « Ne pas oublier », « Parcours » —, cartes dépliables d’une seule fabrique (foldCardHtml), les cartes de session fermées d’office et annonçant leur compte. Rien ne démarre tant qu’on consulte. ⚠ Le rail ①②③ d’avant la v5.0 n’existe plus.</p>`;

/* ---- Journal de parcours + fil condensé (v4.9.0, v4.16.0 — modèle ECAM) ---- */
const journalDemo = `
<div class="ds-capt" style="max-width:620px">${cap('journal')}</div>
<p class="ds-cap">Capture réelle, en session : le journal EST la chronologie (ne JAMAIS poser un état temporel sur une carte spatiale). Un passage terminé se referme dans la ligne de progression ; le bout est toujours une carte dépliée. Une décision est une carte AMBRE DOUX, ses réponses en options pleine largeur.</p>`;

/* ---- Plan de l'aide : « Se repérer », l'ÉCHELLE ECAM (v4.10.0 → v4.25.0) ----
   Cette démo a longtemps montré la vue « Détails » (organigramme hybride en .pl-nd/.pl-cols),
   SUPPRIMÉE en v4.25.0 : elle recopiait les étapes, donc rejouait la vue d'action au lieu d'être
   un synoptique. Le design system la publiait encore — et la publiait CASSÉE, sept de ses classes
   n'ayant plus aucune règle. Elle est ici reconstruite sur le balisage RÉELLEMENT émis par
   ovPlanLadderHtml (relevé sur l'app en session), seule vue du Plan qui subsiste. */
const planDemo = `
<div class="ds-capt" style="max-width:300px">${cap('parcours')}</div>
<p class="ds-cap">Capture réelle, colonne du cockpit en session (A376, A388, A450) : le parcours n’a plus qu’UN dessin (preFlowFlatHtml), en trois LIEUX — carte d’entrée, feuille « Se repérer », colonne et rail. La colonne naît REPLIÉE, bloc courant déplié ; les réglages de coche s’écrivent EN MOTS ; une décision garde sa ligne de branches, « SI réponse » à l’ambre, deux crans de branche au plus. ⚠ L’Échelle d’avant A376 est purgée.</p>`;

/* ---- La PAGE : l'aide entière sur une feuille (v5.10.0, lot « Page » ; arbre en colonnes depuis A344) ---- */
const staticDemo = `
<div class="ds-capt" style="width:740px;zoom:.96">${cap('page')}</div>
<p class="ds-cap">Capture réelle de la PAGE (A344, A391-A395) : l’aide entière sur une feuille de largeur A4 ; le NUMÉRO est l’ancre de tout trait, la colonne des numéros est la surface de dessin (tronc, fourche, rail) ; une sortie s’ÉCRIT « SI … ALLER À n » avant de se tracer en pointillé par la voie de droite ; la destination est une PASTILLE ; un trait ne croise jamais rien. Inerte côté cochage. ⚠ Les voies sont MESURÉES dans l’app : la capture fige leur tracé à la largeur d’auteur (740 px), d’où la réduction à l’échelle plutôt qu’une remise en page.</p>`;

const challengeDemo = `
<div class="ds-capt" style="max-width:620px">${crise(cap('verification'))}</div>
<p class="ds-cap">Capture réelle de la passe « Vérifier » : elle redéroule TOUTES les étapes ; « Constaté ✓ » coche, « △ Écart » avance SANS cocher et ne décoche jamais (la coche est la trace). Le résultat s’affiche dès qu’il est prononcé. La réponse attendue (« challenge :: réponse ») s’y montre au passage.</p>`;

/* ---- Fiches ---- */
/* RANGEMENT (v5.50-v5.51, A475-A479) : collections, feuille à cases, barre de sélection en tiroir. */
const bmk = (s = 13) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3.5h12v17l-6-4-6 4z"/></svg>`;
const box = st => `<button type="button" class="mm-row" role="menuitemcheckbox" aria-checked="${st[0]}"><span class="mm-ic" aria-hidden="true"><span class="mm-box">${chk(14, 3)}</span></span><span class="mm-tx"><span class="mm-lb">${st[1]}</span><span class="mm-sub">${st[2]}</span></span></button>`;
const rangementDemo = `
<div class="coll-rail" style="max-width:420px"><div class="dir-h"><b>Mes collections</b><span class="dir-hs">à vous seul</span></div>
<div class="chiprow" role="group" aria-label="Mes collections"><button class="catchip coll-chip on" aria-pressed="true">${bmk()}Garde SMUR<span class="coll-n">9</span></button><button class="catchip coll-chip" aria-pressed="false">${bmk()}Bloc pédia<span class="coll-n">6</span></button><button class="catchip coll-new" aria-label="Nouvelle collection">${plus()}</button></div></div>
<p class="ds-cap">.coll-rail — au téléphone, sous l’Accès direct : les puces de catégorie (.catchip) avec le SIGNET (icône bookmark) ; absente tant qu’aucune collection n’existe. Au bureau, une section « Mes collections · à vous seul » de la colonne gauche (hsRow), Accès direct en tête.</p>
<div class="coll-head" style="max-width:560px"><div class="coll-ht"><span class="coll-k">${bmk()}Collection · à vous seul</span><h2 class="coll-t">Garde SMUR</h2><span class="coll-s">9 éléments venus de 3 bibliothèques — rien n’a été déplacé · 1 indisponible</span></div>
<div class="coll-acts"><button class="rang-btn">${plus(16)}Ajouter des aides</button><button class="rang-btn coll-more" aria-label="Gérer la collection">⋯</button></div></div>
<p class="ds-cap">.coll-head — une collection ouverte dit d’abord qu’elle est PERSONNELLE, puis d’où vient son contenu ; le filtre est aussi annoncé par une puce « Collection : … » (.af-bar). Supprimer une collection ne touche jamais aux aides.</p>
<div class="catmenu popmenu" role="menu" style="position:static;max-width:400px;max-height:none;overflow:visible">
<div class="popmenu-head"><div class="mm-ctx"><b>Arrêt cardiaque adulte</b><span>SAMU 31</span><div class="notice">${bmk(15)}<div>Vos collections sont à vous seul. L’élément reste dans SAMU 31 : seul votre rangement change.</div></div></div></div>
${box(['true', 'Accès direct', 'les tuiles en tête de l’accueil'])}${box(['mixed', 'Garde SMUR', '1 sur 3 · une partie de la sélection'])}${box(['false', 'Bloc pédia', '6 éléments'])}
<div class="catmenu-sep"></div><button type="button" class="catmenu-new">＋ Nouvelle collection…</button>
<div class="popmenu-foot" style="position:static"><button type="button" class="btn primary">Terminé</button></div></div>
<p class="ds-cap">« Ajouter à une collection… » — openPickMenu en mode multi : des CASES (.mm-box : vide · tiret « une partie » · coche), la feuille reste ouverte, chaque case agit aussitôt. Au menu ⋯ d’une aide, la rangée reste active quand « Modifier » est grisé (lecture seule). Déplacer vers une bibliothèque, lui, est un choix unique (rond) : il change QUI Y A ACCÈS.</p>
<div class="sel-bar" style="position:static;max-width:560px" data-n="3"><button type="button" class="dir-ck sel-ck" role="checkbox" aria-checked="mixed" aria-label="Tout cocher">${chk(15, 3)}<span class="sel-mix" aria-hidden="true"></span></button><span class="sel-n" role="status">3 cochés · deux bibliothèques</span><button type="button" class="btn sm primary sel-do">Actions</button><button type="button" class="btn sm sel-x" aria-label="Quitter la sélection"><span class="sel-g" aria-hidden="true">×</span></button></div>
<p class="ds-cap">.sel-bar — UNE ligne de 56 px à toutes les largeurs : case maîtresse à trois états, compte (seul élément élastique), « Actions » qui ouvre la feuille (Ajouter à une collection · Déplacer vers une bibliothèque · Ranger dans une catégorie · Exporter · Supprimer — libellés entiers), sortie en croix. Plus de dépliage sur la ligne (A476).</p>`;

const cards = [
  { path: 'foundations/colors.html', name: 'Couleurs & tokens', group: 'Fondations', subtitle: 'Neutres, bleu clinique, sémantiques, statuts, accents — 2 thèmes', h: 1750, demo: colorsDemo, title: 'Couleurs' },
  { path: 'foundations/typography.html', name: 'Typographie', group: 'Fondations', subtitle: 'Registres réels — plancher 11px, mono pour les chronos', h: 1350, demo: typeDemo, title: 'Typographie' },
  { path: 'foundations/shape.html', name: 'Formes, ombres & règles', group: 'Fondations', subtitle: 'Rayons, ombres, breakpoints fermés (430→1200), largeurs par vue', h: 1100, demo: shapeDemo, title: 'Formes & règles' },
  { path: 'foundations/categories.html', name: 'Palette des catégories', group: 'Fondations', subtitle: '13 teintes PALETTE + pilule neutre des cartes', h: 1050, demo: catDemo, title: 'Catégories' },
  { path: 'components/buttons.html', name: 'Boutons', group: 'Composants', subtitle: 'Plein / neutre / pointillé / Continuer 2 états / maintenir 1,2 s', h: 1250, demo: buttonsDemo, title: 'Boutons' },
  { path: 'components/chips.html', name: 'Pastilles, tags & états', group: 'Composants', subtitle: 'Filtres, statuts achromatiques, synchro, compte en initiales', h: 1200, demo: chipsDemo, title: 'Pastilles & tags' },
  { path: 'components/cards.html', name: 'Accueil : tuiles & cartes', group: 'Composants', subtitle: 'Capture réelle : Accès direct, Mes collections, cartes rangées par catégorie', h: 1100, demo: cardsDemo, title: 'Accueil' },
  { path: 'components/forms.html', name: 'Formulaires', group: 'Composants', subtitle: 'Recherche, champs, sélecteur de catégories, code OTP', h: 1350, demo: formsDemo, title: 'Formulaires' },
  { path: 'components/lists.html', name: 'Étapes d’un bloc', group: 'Mode crise', subtitle: 'Capture réelle : CRITIQUE / VIGILANCE en mots, réponse attendue, Continuer, Vérifier', h: 1900, demo: listsDemo, title: 'Étapes' },
  { path: 'components/decision.html', name: 'Nœud de décision', group: 'Composants', subtitle: 'Carte ambre, options 64px, fil d’Ariane non destructif', h: 1250, demo: decisionDemo, title: 'Décision' },
  { path: 'components/carepath.html', name: 'Écran de démarrage', group: 'Mode crise', subtitle: 'Capture réelle : chapitres, cartes dépliables, parcours à plat — avant la session', h: 1250, demo: carePathDemo, title: 'Écran de démarrage' },
  { path: 'components/journal.html', name: 'Journal de session', group: 'Mode crise', subtitle: 'Capture réelle : progression, passage courant, carte de décision', h: 1450, demo: journalDemo, title: 'Journal' },
  { path: 'components/plan.html', name: 'Parcours (Se repérer)', group: 'Mode crise', subtitle: 'Capture réelle : un dessin, trois lieux — colonne repliée, branches à deux crans', h: 1400, demo: planDemo, title: 'Parcours' },
  { path: 'components/static.html', name: 'La Page', group: 'Mode crise', subtitle: 'Capture réelle : l’arbre est le fil, feuille A4, voies et pastilles', h: 1450, demo: staticDemo, title: 'La Page' },
  { path: 'components/challenge.html', name: 'Vérifier (challenge-response)', group: 'Mode crise', subtitle: 'Capture réelle : passe de constat, Constaté ✓ / △ Écart', h: 1550, demo: challengeDemo, title: 'Vérifier' },
  { path: 'components/rangement.html', name: 'Rangement : collections & sélection', group: 'Composants', subtitle: 'Collections personnelles, feuille à cases, en-tête « à vous seul », barre de sélection en tiroir', h: 1250, demo: rangementDemo, title: 'Rangement' },
  { path: 'components/notices.html', name: 'Notices, alertes & toasts', group: 'Composants', subtitle: 'Information, erreur de synchro, banderole ambre, toast', h: 1100, demo: noticesDemo, title: 'Notices & alertes' },
  { path: 'components/header.html', name: 'En-tête, capsule & quai', group: 'Mode crise', subtitle: 'Captures réelles : en-tête d’accueil, capsule d’état, quai à quatre touches, menu ⋯', h: 1600, demo: headerDemo, title: 'En-tête' },
  { path: 'components/runtime.html', name: 'Panneau temps réel', group: 'Composants', subtitle: 'Cartes à état textuel, échu ambre, ad hoc — suivent le thème', h: 1500, demo: runtimeDemo, title: 'Temps réel' },
  { path: 'components/session.html', name: 'Sessions', group: 'Composants', subtitle: 'Carte de session vive ; Terminer via menu ⋯, historique en modale', h: 800, demo: sessionDemo, title: 'Sessions' },
  { path: 'components/modal.html', name: 'Modale', group: 'Composants', subtitle: 'dlg-480, dialogue Créer, Terminer la session ?, confirmations destructrices', h: 2150, demo: modalDemo, title: 'Modale' },
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
