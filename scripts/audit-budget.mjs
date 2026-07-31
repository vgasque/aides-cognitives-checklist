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
import { serveApp, moteur, NOM_MOTEUR } from './harness.mjs';

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

for (const fmt of FORMATS) {
  console.log(`\n── ${fmt.w} × ${fmt.h} (${fmt.nom}) ──`);
  const p = await br.newPage({ viewport: { width: fmt.w, height: fmt.h }, hasTouch: true });
  p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
  await p.goto(`http://localhost:${port}/index.html`);
  await p.waitForFunction(() => !document.querySelector('.boot-load'));
  await p.evaluate(async () => {
    const w = m => new Promise(r => setTimeout(r, m));
    const b = [...document.querySelectorAll('button')].find(x => /Commencer/.test(x.textContent)); if (b) b.click(); await w(200);
    const s = [...document.querySelectorAll('button')].find(x => x.textContent.includes("fiches d'exemple")); if (s) s.click(); await w(700);
  });

  const r = await p.evaluate(async () => {
    const w = m => new Promise(r => setTimeout(r, m));
    const f = fiches.find(x => /Anaphylaxie/i.test(x.title)) || fiches[0];
    openRead(f.id); await w(400);
    const b = document.getElementById('sessStart'); if (b) b.click(); await w(700);
    /* ON NE DÉFILE PAS. Tout le contrôle porte sur ce qui est à l'écran À L'INSTANT du
       démarrage : c'est la seule chose que quelqu'un les mains prises va voir. */
    const H = innerHeight;
    const hOf = s => { const e = document.querySelector(s); if (!e) return 0; const q = e.getBoundingClientRect(); return q.height; };
    const chrome = hOf('header.bar') + hOf('#crisisCtrl') + hOf('#cbTimers');

    /* Une étape « visible » est une étape ENTIÈREMENT dans le viewport et sous le chrome
       collant — une ligne à moitié cachée derrière le quai n'est pas cochable de confiance. */
    const bas = (() => { let m = 0; for (const s of ['header.bar', '#crisisCtrl', '#cbTimers']) { const e = document.querySelector(s); if (!e) continue; const q = e.getBoundingClientRect(); if (q.height && q.bottom > m) m = q.bottom; } return m; })();
    const etapes = [...document.querySelectorAll('.ov-wrap ol.steps li[data-ck], .nav-wrap ol.steps li[data-ck], ol.steps li[data-ck]')];
    const visibles = etapes.filter(e => { const q = e.getBoundingClientRect(); return q.top >= bas - 1 && q.bottom <= H + 1; });

    /* La carte du bloc courant et sa pile d'actions. La pile = tout ce qui, DANS la carte, est
       un contrôle d'avancement, d'exception ou de traçabilité — pas les cases à cocher, qui
       SONT le contenu. */
    const carte = document.querySelector('.ov-block.cur') || document.querySelector('.ov-block');
    let cardH = 0, pileH = 0, nItems = 0;
    if (carte) {
      cardH = carte.getBoundingClientRect().height;
      nItems = carte.querySelectorAll('ol.steps li[data-ck]').length;
      const sel = '[data-ovnext],[data-ovopt],[data-cxback],.ov-actions,.cx-btn,.tk-add,.ov-row';
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
    };
  });

  console.log(`     chrome ${r.chrome} px / ${r.H} · carte ${r.cardH} px · ${r.nItems} item(s) · 1ʳᵉ étape à y=${r.premiereY}`);
  t(`chrome permanent ≤ 30 % de la hauteur`, r.pctChrome <= 30, `${r.pctChrome} % (${r.chrome} px)`);
  t(`au moins UNE étape cochable entièrement visible sans défiler`, r.nVisibles >= 1,
    `${r.nVisibles} sur ${r.nEtapes} — 1ʳᵉ à y=${r.premiereY} pour un pli à ${r.H}`);
  /* Borné au cas DOCTRINAL : sous 4 items, le ratio mesure la fiche et non l'application. */
  if (r.nItems >= 4) t(`pile d'actions ≤ 25 % de la carte du bloc`, r.pctPile <= 25, `${r.pctPile} % (${r.pileH} px sur ${r.cardH})`);
  else console.log(`  · pile d'actions : non mesurée (bloc de ${r.nItems} item(s), sous le cas doctrinal de 4)`);
  await p.close();
}

await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} contrôles de budget OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`);
process.exit(ko ? 1 : 0);
