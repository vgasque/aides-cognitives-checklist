/* AUDIT — LE BUDGET D'ÉCRAN (v5.0.0, lot T4).
 *
 * POURQUOI CE HARNAIS EXISTE. Les seize harnais du dépôt mesurent des PROPRIÉTÉS — un contraste,
 * une cible, un ordre, un débordement. Aucun ne mesure une RÉPARTITION, et c'est pourtant le
 * défaut central relevé par l'audit structurel : sur un téléphone en session, l'écran est un
 * budget fini, et il était dépensé par des objets qui ne conduisent pas le soin. Un défaut de
 * répartition ne se voit dans aucune propriété prise isolément — chaque objet est légitime, c'est
 * leur SOMME qui ne l'est pas. D'où une mesure de somme.
 *
 * TROIS BUDGETS, ET LE DEUXIÈME EST LE SEUL QUI COMPTE VRAIMENT :
 *
 *   1. LE CHROME PERMANENT ≤ 30 % de la hauteur. En-tête + rangée de commandes + quai d'état :
 *      trois couches collantes qui ne quittent jamais l'écran. Chacune est justifiée (SPEC §5,
 *      ECP/ECAM v4.25.0) ; leur cumul, lui, n'a jamais été borné.
 *
 *   2. AU MOINS UNE ÉTAPE COCHABLE ENTIÈREMENT VISIBLE au démarrage de la session, SANS DÉFILER.
 *      C'est le seul contrôle dont l'échec est un défaut CLINIQUE et pas esthétique : une
 *      checklist qui n'affiche aucune ligne à cocher à l'instant où l'on démarre le soin n'est
 *      pas une checklist, c'est un sommaire. Zéro étape visible = rouge, sans discussion.
 *
 *   3. LA PILE D'ACTIONS ≤ 25 % de la carte du bloc courant, sur un bloc de taille doctrinale.
 *      Mesuré à 34 % avant épuration : les boutons prenaient le tiers de l'objet qu'ils servent.
 *
 * CE QU'IL NE MESURE PAS, ET POURQUOI. Il ne juge NI l'ordre NI l'utilité d'aucun objet — deux
 * dispositions opposées peuvent tenir le même budget. C'est délibéré : un harnais qui encoderait
 * un ordre figerait une décision de conception dans un contrôle automatique, et le prochain
 * arbitrage se ferait alors contre l'outil au lieu de se faire contre la doctrine.
 *
 * PIÈGE DE MÉTHODE RENCONTRÉ (et il vaut pour tout harnais de RÉPARTITION) : mesurer la fiche
 * d'exemple ne prouve rien si elle est plus courte que le cas doctrinal. Le budget n°3 est borné
 * à « bloc ≥ 4 items » — un bloc de deux lignes rend n'importe quelle pile d'actions
 * proportionnellement énorme, et l'on mesurerait alors la fiche, pas l'application.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
let ok = 0, ko = 0;
const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };

console.log(`═══ BUDGET D'ÉCRAN — moteur ${NOM_MOTEUR} ═══`);

/* Les deux formats qui comptent : le plancher servi (320 × 640, WCAG 1.4.10 « Reflow ») et le
   téléphone médian. Au-delà de 780 px le rail existe et la question ne se pose plus. */
const FORMATS = [
  { w: 320, h: 640, nom: 'plancher servi' },
  { w: 390, h: 844, nom: 'téléphone médian' },
];

/* ⚠ LE RÉGLAGE DE TAILLE DU TEXTE EST BALAYÉ (audit externe v5.10.0) — ET C'EST LUI QUI CASSAIT.
 * Ce harnais ne mesurait qu'à 100 %, alors que l'application offre QUATRE crans et qu'ils
 * multiplient toutes les échelles tout en divisant toutes les largeurs. Mesuré avant correction :
 * à 320 × 640 × 130 %, chrome 41,3 % et ZÉRO étape cochable — c'est-à-dire les deux budgets
 * violés d'un coup, sur la configuration choisie par la population qui en a le plus besoin
 * (presbytie, gants, lumière directe). Un budget qui ne se vérifie qu'au réglage par défaut ne
 * borne rien : il borne le cas facile.
 * 90 % n'est pas balayé — il rend de la place, il n'en prend pas ; le sweep va du nominal au pire.
 * DEUX SEUILS, ET LEUR ASYMÉTRIE EST LE POINT : le budget de CHROME se détend d'un cran au-delà
 * de 100 % (l'utilisateur a demandé de plus gros caractères, il accepte d'en voir moins), mais
 * « au moins une étape cochable » NE SE DÉTEND JAMAIS — c'est le seul contrôle dont l'échec est
 * clinique, et une checklist sans ligne à cocher n'est pas une checklist quel que soit le
 * réglage. */
const ZOOMS = [100, 115, 130];
const seuilChrome = z => (z <= 100 ? 30 : 36);

/* ⚠ L'ENVELOPPE DE SUPPORT EST DÉCLARÉE ICI, ET C'EST LA PREMIÈRE FOIS QU'ELLE L'EST QUELQUE PART.
 * Le dossier déclare servir 320 px — mais 320 px de QUOI ? Sous le réglage de texte, la mise en
 * page dispose de `largeur ÷ zoom` (règle 10) : un appareil de 320 px au plus grand réglage n'offre
 * plus que 246 × 492 px CSS, soit moins que le plancher de WCAG 1.4.10 « Reflow » et moins que ce
 * que le projet dit servir. Mesuré : dans cette seule configuration, le préambule (chapeau des
 * memory items, ligne de confirmation, en-tête de carte) coûte 309 px visuels d'une zone utile de
 * 403 — la première étape naît donc sous le dock. Ce n'est PAS un défaut de chrome : le chrome y a
 * déjà rendu tout ce qu'il pouvait rendre (28,6 % au nominal après compaction). Y gagner encore
 * demande de RETIRER DU CONTENU du préambule, c'est-à-dire de rouvrir A3 et A110 — une décision de
 * conception, pas un correctif.
 * ⚠ L'ENVELOPPE PORTE SUR L'APPAREIL, PAS SUR LA LARGEUR EFFECTIVE — et l'écrire dans l'autre sens
 * a été essayé puis mesuré FAUX. Un plancher exprimé en px CSS effectifs met HORS PORTÉE le cas le
 * plus courant du parc (390 × 844 au plus grand réglage = 300 px CSS), c'est-à-dire précisément
 * celui que ce balayage existe pour couvrir : le harnais se serait excusé du cas réel pour ne
 * garder que le cas facile. L'enveloppe est donc « tout appareil ≥ 320 px, à TOUS les réglages de
 * texte » — la lecture exigeante, et celle qu'implique la règle 10. */
const DEV_FLOOR = 320;

for (const fmt of FORMATS) for (const zoom of ZOOMS) {
  console.log(`\n── ${fmt.w} × ${fmt.h} (${fmt.nom}) · texte ${zoom} % ──`);
  const p = await br.newPage({ viewport: { width: fmt.w, height: fmt.h }, hasTouch: true });
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await p.goto(`http://localhost:${port}/index.html`);
  await amorce(p);

  const r = await p.evaluate(async (zoom) => {
    const w = m => new Promise(r => setTimeout(r, m));
    const f = fiches.find(x => /Anaphylaxie/i.test(x.title)) || fiches[0];
    openRead(f.id); await w(400);
    const b = document.getElementById('sessStart'); if (b) b.click(); await w(700);
    /* Le zoom se pose APRÈS le démarrage : c'est l'ordre réel — on règle la taille du texte une
       fois pour toutes, puis on ouvre une fiche. Le poser avant ne changerait rien à la
       géométrie, mais `applyZoom` recale des mesures (paliers, fil collant) et l'on veut que ce
       recalage ait eu lieu sur la page DE CRISE, pas sur l'accueil. */
    applyZoom(zoom); await w(400);
    /* ON NE DÉFILE PAS. Tout le contrôle porte sur ce qui est à l'écran À L'INSTANT du
       démarrage : c'est la seule chose que quelqu'un les mains prises va voir. */
    const H = innerHeight;
    const hOf = s => { const e = document.querySelector(s); if (!e) return 0; const q = e.getBoundingClientRect(); return q.height; };
    /* ⚠ LE DOCK EST DU CHROME PERMANENT, ET IL N'ÉTAIT PAS COMPTÉ (audit externe v5.10.0).
       En v5.6 la rangée de COMMANDES a quitté le haut de l'écran pour devenir le dock bas — et le
       budget est resté calibré sur les TROIS couches d'avant tout en n'en mesurant plus que DEUX.
       Le seuil de 30 % n'a pas bougé, mais ce qu'il borne a perdu un tiers : le budget s'est
       assoupli tout seul, en silence, au moment précis où l'on déplaçait la couche. Or le dock
       est `position:fixed`, il existe pendant toute la session, il ne défile pas et il RÉSERVE sa
       hauteur au bas du flux : c'est la définition même du chrome permanent. Il compte. */
    const chrome = hOf('header.bar') + hOf('#crisisDock') + hOf('#sessionDock');

    /* Une étape « visible » est une étape ENTIÈREMENT dans la ZONE UTILE : sous les couches
       collantes du haut ET au-dessus du dock. Une ligne à moitié cachée derrière le quai ou
       derrière le dock n'est pas cochable de confiance — et le contrôle bornait le bas au
       VIEWPORT, donc comptait comme visibles des étapes que le dock recouvre. */
    const bas = (() => { let m = 0; for (const s of ['header.bar', '#crisisDock']) { const e = document.querySelector(s); if (!e) continue; const q = e.getBoundingClientRect(); if (q.height && q.bottom > m) m = q.bottom; } return m; })();
    const dk = document.getElementById('sessionDock');
    const plafondBas = (dk && dk.getBoundingClientRect().height) ? dk.getBoundingClientRect().top : H;
    const etapes = [...document.querySelectorAll('.ov-wrap ol.steps li[data-ck], .nav-wrap ol.steps li[data-ck], ol.steps li[data-ck]')];
    const visibles = etapes.filter(e => { const q = e.getBoundingClientRect(); return q.top >= bas - 1 && q.bottom <= plafondBas + 1; });

    /* La carte du bloc courant et sa pile d'actions. La pile = tout ce qui, DANS la carte, est
       un contrôle d'avancement, d'exception ou de traçabilité — pas les cases à cocher, qui
       SONT le contenu. */
    const carte = document.querySelector('.ov-block.cur') || document.querySelector('.ov-block');
    let cardH = 0, pileH = 0, nItems = 0;
    if (carte) {
      cardH = carte.getBoundingClientRect().height;
      nItems = carte.querySelectorAll('ol.steps li[data-ck]').length;
      const sel = '[data-ovnext],[data-ovopt],[data-cxback],.ov-actions,.cx-row .blk-act,.ov-row';
      const vus = new Set(); let acc = 0;
      carte.querySelectorAll(sel).forEach(e => {
        if ([...vus].some(v => v.contains(e))) return;   // ne pas compter un bouton ET sa rangée
        vus.add(e); acc += e.getBoundingClientRect().height;
      });
      pileH = acc;
    }
    return {
      H, chrome: Math.round(chrome), pctChrome: +(chrome / H * 100).toFixed(1),
      nEtapes: etapes.length, nVisibles: visibles.length,
      premiereY: etapes.length ? Math.round(etapes[0].getBoundingClientRect().top) : null,
      cardH: Math.round(cardH), pileH: Math.round(pileH), nItems,
      pctPile: cardH ? +(pileH / cardH * 100).toFixed(1) : 0,
      zf: +(getComputedStyle(document.documentElement).getPropertyValue('--zf') || 1),
    };
  }, zoom);

  const sc = seuilChrome(zoom);
  const cssW = Math.round(fmt.w / (zoom / 100)), cssH = Math.round(fmt.h / (zoom / 100));
  console.log(`     ${cssW} × ${cssH} px CSS effectifs · chrome ${r.chrome} px / ${r.H} · carte ${r.cardH} px · ${r.nItems} item(s) · 1ʳᵉ étape à y=${r.premiereY}`);
  t(`le réglage de texte est bien appliqué (--zf = ${zoom / 100})`, Math.abs(r.zf - zoom / 100) < .001, `--zf = ${r.zf}`);
  t(`chrome permanent ≤ ${sc} % de la hauteur`, r.pctChrome <= sc, `${r.pctChrome} % (${r.chrome} px)`);
  t(`au moins UNE étape cochable entièrement visible sans défiler`, r.nVisibles >= 1,
    `${r.nVisibles} sur ${r.nEtapes} — 1ʳᵉ à y=${r.premiereY} pour un pli à ${r.H}`);
  if (fmt.w < DEV_FLOOR) console.log(`  · appareil sous le plancher déclaré (${DEV_FLOOR} px)`);
  /* Borné au cas DOCTRINAL : sous 4 items, le ratio mesure la fiche et non l'application. */
  if (r.nItems >= 4) t(`pile d'actions ≤ 25 % de la carte du bloc`, r.pctPile <= 25, `${r.pctPile} % (${r.pileH} px sur ${r.cardH})`);
  else console.log(`  · pile d'actions : non mesurée (bloc de ${r.nItems} item(s), sous le cas doctrinal de 4)`);
  await p.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles de budget OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`);
process.exit(ko ? 1 : 0);
