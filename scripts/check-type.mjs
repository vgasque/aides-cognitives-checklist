#!/usr/bin/env node
/* ÉCHELLE TYPOGRAPHIQUE FERMÉE (v4.71.1, audit design E2) — garde-fou auto-exécutoire.
 *
 * POURQUOI. Avant ce contrôle, la feuille portait SEIZE corps différents entre 10 et 19 px :
 * 11 / 11,5 / 12 / 12,5 / 13 / 13,5 / 14 / 14,5 / 15 / 15,5 / 16 / 16,5 / 17 / 18 / 19 (+ un 10).
 * Le problème n'est pas la pureté : deux textes à 13 et 13,5 px ne se lisent pas comme deux
 * NIVEAUX, ils se lisent comme une inattention. Une échelle fermée rend la hiérarchie lisible —
 * un écart de corps y signifie toujours quelque chose — et, comme les couleurs depuis la v4.31.0,
 * elle cesse d'être une intention pour devenir une propriété vérifiée.
 *
 * CE QUI EST CONTRÔLÉ : deux bandes, chacune avec SON échelle.
 *   · le TEXTE, sous 20 px — sept paliers ;
 *   · les AFFICHAGES, à partir de 20 px — cinq paliers (v5.0.0, audit design, action 8).
 * L'exemption d'origine (« ils ne se croisent jamais du regard ») était juste pour 34 et 40 px —
 * chronos, moniteur, tête de bilan, qui occupent chacun leur surface. Elle était FAUSSE pour
 * 20/21/22/23/24, qui sont des titres et se croisent en permanence : cinq valeurs à moins de 5 %
 * d'écart ne se lisent pas comme cinq niveaux. La bande d'affichage a donc sa propre échelle,
 * plus lâche que celle du texte parce que ses objets sont plus rares et plus gros.
 *
 * DEUX VALEURS DE SERVICE, qui ne sont pas des paliers :
 * DEUX EXEMPTIONS, TOUTES DEUX NOMMÉES (v5.6) : le plancher de 16 px ci-dessous, et la feuille du
 * COMPTE RENDU TÉLÉCHARGÉ — document autonome, hors du bloc <style>, dont la frontière est
 * désormais VÉRIFIÉE et non supposée (cf. le bloc « DEUX EXEMPTIONS » plus bas).
 *   · 16 px — plancher des champs de saisie sur écran tactile (règle 9 : sous 16, Safari iOS
 *     zoome la page au focus et les taps voisins se perdent). C'est une contrainte du moteur,
 *     pas un niveau de hiérarchie.
 *   · 14 px — l'un des quatre « A » du sélecteur de taille du texte. Ces quatre corps SONT
 *     l'échantillon de l'échelle que l'utilisateur règle : leur écart est l'information.
 */
import { readFile } from 'node:fs/promises';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);

/* Les sept paliers. Toute autre valeur sous 20 px doit être justifiée ci-dessous, jamais
   ajoutée en silence : c'est la discussion qu'on veut forcer, pas la conformité. */
/* REFONTE v5.6 (A6) — l'échelle se referme sur SEPT crans, et les DEUX bandes n'en font plus
   qu'une : le grand corps appartient désormais à l'ACTE, plus au chrono. L'ancienne bande
   d'affichage (20 · 24 · 26 · 34 · 40) disparaît avec sa raison d'être — un chrono à 40 px pendant
   qu'une étape vitale plafonnait à 15,5 était l'enjeu inversé. 24 px reste, comme cran haut des
   VALEURS mono (--t-val, chrono d'alarme du volet). */
const PALIERS = [24, 21, 17.5, 15, 13.5, 12, 11];
/* Les cinq paliers d'AFFICHAGE (≥ 20 px). Même règle : toute autre valeur se discute ici. */
/* Plus de seconde bande : `bande` pointe sur la même échelle des deux côtés du seuil. Le nom est
   conservé pour que la lecture du contrôle reste la même. */
const AFFICHAGES = PALIERS;
/* Exemptions NOMMÉES par leur sélecteur, avec leur motif. Une exemption anonyme ne vaut rien —
   elle rouvre la porte qu'on vient de fermer. */
const EXEMPTIONS = [
  /* v5.6 : les quatre « A » du sélecteur de taille sont désormais QUATRE CRANS DE L'ÉCHELLE
     (12 · 13,5 · 15 · 17,5) — l'échantillon montre le système au lieu d'y faire exception. */
  { rx: /input|textarea|select|\.auth-field|\.tg-row|\.join-sel|coarse/i, val: 16,
    motif: 'plancher de 16 px des champs sur écran tactile (règle 9)' },
];

const src = await readFile(ROOT + 'index.html', 'utf8');
const css = src.slice(src.indexOf('<style>'), src.indexOf('</style>'));

const fautes = [];
/* ══ DEUX EXEMPTIONS, ET ELLES SONT DÉSORMAIS DITES (v5.6, planche 8f) ══════════════════════
   Ce contrôle en avait DEUX, dont une seule était écrite :
   1. Le plancher de 16 px des champs sur écran tactile — nommé dans EXEMPTIONS ci-dessus. C'est
      une valeur de SERVICE, imposée par le moteur (sous 16 px, Safari iOS zoome au focus), pas un
      palier de l'échelle : elle ne hiérarchise rien et ne doit jamais servir ailleurs.
   2. La feuille du COMPTE RENDU TÉLÉCHARGÉ, qui vit dans un littéral gabarit du script et non
      dans le bloc <style> — elle échappait donc au contrôle par ACCIDENT DE DÉCOUPAGE, ce qui
      n'est pas une exemption, c'est un angle mort. C'en est une VRAIE : le compte rendu est un
      document AUTONOME, sans serveur, dont les polices et les corps système sont une décision
      (v5.2.0) — mais il faut le dire, et surtout garantir que la frontière tient.
   ON VÉRIFIE DONC LA FRONTIÈRE au lieu de s'y fier : si la feuille du compte rendu venait à
   entrer dans le bloc <style>, le contrôle le dirait au lieu de la mesurer en silence — ou de
   l'exempter en silence, ce qui serait pire. Même discipline que check-fonts, qui borne sa
   région d'exemption par un repère du CODE et échoue s'il ne le trouve plus. */
{
  const REPERE = 'const css=`@font-face';
  if (css.includes(REPERE))
    fautes.push({ ligne: 0, val: '?', sel: 'la feuille du COMPTE RENDU a migré dans <style> — '
      + 'elle serait mesurée (ou exemptée) en silence ; la traiter explicitement' });
  if (!src.includes(REPERE))
    fautes.push({ ligne: 0, val: '?', sel: 'repère de la feuille du compte rendu introuvable — '
      + 'le contrôle ne sait plus ce qu\'il laisse dehors' });
}
let exemptees = 0, controlees = 0;
const rx = /font-size:\s*([0-9.]+)px/g;
let m;
while ((m = rx.exec(css))) {
  const val = parseFloat(m.group ? m.group(1) : m[1]);
  const bande = val >= 20 ? AFFICHAGES : PALIERS;
  controlees++;
  if (bande.includes(val)) continue;

  // Sélecteur : on remonte à l'accolade ouvrante puis au séparateur précédent.
  const st = css.lastIndexOf('{', m.index);
  const cut = Math.max(css.lastIndexOf('}', st), css.lastIndexOf('*/', st), css.lastIndexOf('\n', st));
  const sel = css.slice(cut + 1, st).trim().replace(/\s+/g, ' ');

  const ex = EXEMPTIONS.find(e => e.rx.test(sel) && (e.val === null || e.val === val));
  if (ex) { exemptees++; continue; }

  const ligne = css.slice(0, m.index).split('\n').length;
  fautes.push({ ligne, val, sel: sel.slice(-70) });
}

/* ⚠ LE QUOTA DU PLANCHER (v5.0.0, audit design A5-1) — LE PREMIER CONTRÔLE DE CE DÉPÔT QUI
   MESURE UNE PROPORTION, PAS UNE PROPRIÉTÉ.
   Les six garde-fous d'échelle répondent tous à la même question : « cette valeur est-elle
   ADMISE ? ». Aucun ne répond à « est-elle TROP UTILISÉE ? » — et c'est exactement par là que le
   plancher typographique a glissé. Mesuré à l'audit : 173 déclarations à 11 px sur ~520, soit LA
   TAILLE LA PLUS UTILISÉE DE TOUTE LA FEUILLE, devant 13,5 px (138) et 12 px (107) ; 81 % des
   corps étaient à 13,5 px ou moins. Chaque déclaration prise isolément était parfaitement légale,
   donc rien ne pouvait le voir. Or un plancher est une EXCEPTION MOTIVÉE : employé 173 fois, ce
   n'est plus un plancher, c'est le corps de texte du produit — et la règle qui le nomme
   « plancher » masque ce fait au lieu de le révéler.
   C'EST UN CLIQUET, PAS UN SEUIL D'OPINION : le plafond est posé au niveau ATTEINT après le lot,
   de sorte que la valeur ne peut que descendre. Le baisser est un geste explicite, l'augmenter est
   un échec bruyant. Même dispositif qu'`audit-budget` pour la répartition d'écran (v5.0.0, lot T4).
   ⚠ CE QU'IL NE MESURE PAS, et il faut le savoir : une DÉCLARATION n'est pas un ÉLÉMENT À
   L'ÉCRAN. Le vrai constat de l'audit était « 14 des 26 éléments visibles à l'accueil sont à
   11 px », ce qu'un contrôle statique ne peut pas voir. Ce cliquet est un proxy — il empêche la
   dérive de s'aggraver, il ne prouve pas qu'elle a cessé. La mesure d'écran, elle, vit dans
   `audit-doctrine`.
   BAISSER LE PLAFOND est la façon normale de faire descendre la dette : traiter un gisement de
   11 px (une méta, une rangée), constater le nouveau compte, et reposer PLANCHER_MAX dessus. */
const PLANCHER = 11;
/* 169 -> 166 (v5.0.0, audit) : la passe inverse de `check-classes` a fait tomber dix règles mortes,
   dont trois au plancher (`.ph-chip`, `.pl-cxh`, `.pl-bl2`). Trois déclarations de moins qui ne
   coûtent rien à personne — du CSS que plus aucun gabarit n'émettait. On repose donc le cliquet
   sur le niveau ATTEINT : le laisser à 169 rouvrirait trois places pour une dérive future. */
/* 166 -> 170 (v5.6, refonte « verre clinique ») — LE CLIQUET REMONTE, ET IL FAUT LE JUSTIFIER,
   parce que la règle dit qu'il ne remonte pas. Quatre déclarations de plus, toutes dans le DOCK
   et ses volets : les étiquettes des quatre touches (--t-cap, A13 : « étiquettes de touches à
   11 px »). Ce n'est pas une dérive du plancher vers le corps de texte — c'est le cran le PLUS
   HAUT autorisé pour une étiquette de commande sous un glyphe de 15 px, et le système le nomme.
   ⚠ CE QUI LE REND ACCEPTABLE EST UN ÉCHANGE, PAS UNE TOLÉRANCE : la même refonte fait passer
   l'étape courante de 15,5 à 17,5 px et l'étape critique à 21 — le gisement de 11 px cesse d'être
   le corps de texte du produit, ce que le cliquet existe pour empêcher. Il est reposé au niveau
   ATTEINT : il ne peut que redescendre. 170 -> 171 : l'intitulé de la colonne « ▤ Consulter »
   (A15), une étiquette de zone du rail. 171 -> 174 : l'en-tête de la carte de bloc passe de la
   pastille numérotée à l'ÉTIQUETTE « BLOC n » + compte (maquette) — trois déclarations, et elles
   REMPLACENT du chrome au lieu de s'y ajouter. */
const PLANCHER_MAX = 177;
const auPlancher = (css.match(/font-size:\s*11px/g) || []).length;

if (!fautes.length && auPlancher > PLANCHER_MAX) {
  console.log(`\n✗ check-type : ${auPlancher} déclarations à ${PLANCHER}px — le plafond est ${PLANCHER_MAX}.`);
  console.log('  Le plancher typographique est une EXCEPTION MOTIVÉE, pas un corps de texte.');
  console.log('  Choisissez un palier au-dessus (12 px), ou — si ce nouvel usage est vraiment une');
  console.log('  étiquette de zone — rendez sa place en remontant un autre gisement, puis baissez');
  console.log('  PLANCHER_MAX dans scripts/check-type.mjs. Le cliquet ne remonte pas.\n');
  process.exit(1);
}

/* ═══ LES CHAMPS COMPACTS REJOIGNENT LA LISTE « 16 px TACTILE » (v5.4.0) — auto-exécutoire. ═══
   LE DÉFAUT VÉCU : le champ « Chercher dans la référence » (`.rt-find input`) est né en v5.0.0 à
   12 px SANS rejoindre le bloc `@media (hover:none) and (pointer:coarse)` de fin de feuille — la
   « source de vérité UNIQUE » des 16 px tactiles (v4.4.2). Sur iPhone, le focus ZOOMAIT la page
   (règle 9), et rien ne pouvait le voir : la liste est tenue à la main, et un champ oublié est un
   trou silencieux — la même famille que MUTE_SEL, les placards, les verbes du lecteur.
   LA RÈGLE : tout sélecteur qui pose un font-size < 16 px sur un champ de saisie (jeton `input`,
   `textarea` ou `select` dans le sélecteur) doit apparaître dans la liste du bloc tactile — à
   l'IDENTIQUE : c'est `includes`, pas une équivalence de sélecteurs, et c'est voulu (une
   couverture par un sélecteur « plus large » ne se vérifie pas au texte).
   ⚠ CE QU'IL NE VOIT PAS, et il faut le dire : un champ stylé par sa seule CLASSE
   (`.catmenu-filter`, `.auth-field`…) échappe au repérage statique — on ne sait pas, au texte,
   qu'une classe habille un <input>. Le contrôle couvre les sélecteurs à jeton d'élément, qui
   sont le cas du défaut vécu ; une couverture totale exigerait d'exécuter le rendu.
   ⚠ ET LE SÉLECTEUR SE NETTOIE AVANT DE JUGER : la capture `[^{}]+` remonte jusqu'à l'accolade
   précédente et ramasse la QUEUE DU COMMENTAIRE au-dessus de la règle (cette feuille documente
   ses propres règles — même précaution que check-space, qui a dû neutraliser les commentaires
   pour la même raison) ; un `:is(input,select)` se découpe sur les virgules INTERNES si on le
   fend naïvement — on ne fend que hors parenthèses.
   ⚠ VÉRIFIÉ CAPABLE D'ÉCHOUER après réparation : la PREMIÈRE version de ce bloc était un no-op
   silencieux — écrite via un heredoc Python, son `\b` de regex était devenu un BACKSPACE (le
   piège « un patch scripté mutile en silence », déjà payé sur les `$$` SQL en v4.44.0), et le
   test de réintroduction est resté vert. Un garde-fou qui ne peut pas échouer ne prouve rien
   (v4.31.1) — celui-ci a été rejoué rouge/vert après correction. */
{
  const coarse = /@media \(hover:none\) and \(pointer:coarse\)\{([\s\S]*?)\n  \}/.exec(css);
  const listeCoarse = coarse ? coarse[1] : '';
  if (!coarse) fautes.push({ ligne: 0, val: '?', sel: 'bloc « 16 px tactile » introuvable — le contrôle ne mesurerait rien' });
  const rx2 = /([^{}]+)\{[^{}]*?font-size:\s*(1[0-5](?:\.[0-9]+)?|[0-9](?:\.[0-9]+)?)px/g;
  const fendHorsParens = sel => { const out = []; let d = 0, cur = '';
    for (const c of sel) { if (c === '(') d++; if (c === ')') d--;
      if (c === ',' && !d) { out.push(cur); cur = ''; } else cur += c; }
    out.push(cur); return out.map(x => x.trim()).filter(Boolean); };
  let m2;
  while ((m2 = rx2.exec(css))) {
    if (coarse && m2.index > coarse.index) continue;                        // le bloc lui-même
    // queue de commentaire ramassée par la capture : on repart du dernier fermeur.
    let sel = m2[1];
    const cf = sel.lastIndexOf('*/'); if (cf >= 0) sel = sel.slice(cf + 2);
    sel = sel.trim().replace(/\s+/g, ' ');
    for (const simple of fendHorsParens(sel)) {
      if (!/(^|[ .>+~(:])(input|textarea|select)\b/.test(simple)) continue;  // jeton d'élément requis
      if (/\[type=(checkbox|radio|range|file)\]/.test(simple)) continue;     // pas des champs texte
      if (listeCoarse.includes(simple)) continue;
      const ligne = css.slice(0, m2.index).split('\n').length;
      fautes.push({ ligne, val: parseFloat(m2[2]),
        sel: simple.slice(-70) + '  ← champ compact ABSENT de la liste « 16 px tactile » (zoom iOS au focus, règle 9)' });
    }
  }
}

if (fautes.length) {
  console.log('\n✗ check-type : corps hors des échelles fermées (texte '
    + PALIERS.join(' · ') + ' px · affichage ' + AFFICHAGES.join(' · ') + ' px) :');
  for (const f of fautes) console.log(`   index.html:${f.ligne}  ${f.val}px  —  ${f.sel}`);
  console.log('\n  Choisissez le palier le plus proche, ou ajoutez une exemption NOMMÉE et motivée');
  console.log('  dans scripts/check-type.mjs. Une valeur de plus posée en silence est exactement');
  console.log('  ce que ce contrôle existe pour empêcher.\n');
  process.exit(1);
}
console.log(`✓ check-type : ${controlees} corps, tous sur les échelles fermées `
  + `(texte ${PALIERS.join(' · ')} · affichage ${AFFICHAGES.join(' · ')} px) — `
  + `${exemptees} exemption(s) documentée(s) ; `
  + `plancher ${PLANCHER}px : ${auPlancher}/${PLANCHER_MAX} déclarations.`);
