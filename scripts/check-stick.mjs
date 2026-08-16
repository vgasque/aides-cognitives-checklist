/* LE CHROME DE PAGE NE POURSUIT PAS LE VIEWPORT VISUEL — IL SE RETIRE (v5.13.0).
 *
 * HISTOIRE, parce qu'elle EST la règle, et qu'elle a coûté onze versions.
 * Sur iOS, ouvrir le clavier logiciel ne rétrécit pas le viewport de MISE EN PAGE : il PANORAMIQUE
 * le viewport visuel à l'intérieur. Or `position:fixed` ET `position:sticky` se calent tous deux
 * sur le premier — les DEUX sortent donc de l'écran. La v5.12.0 a voulu les y ramener en ajoutant
 * le décalage (`--vvt`) à leur `top`, et ce contrôle a d'abord servi à IMPOSER ce décalage. Ce qui
 * a suivi, retour d'usage après retour d'usage : en-tête absent, en-tête poussé vers le bas avec
 * du contenu au-dessus, volet qui saute à chaque frappe. Poursuivre une cible que le système
 * déplace pendant qu'on la vise ne peut pas marcher — au mieux on remplace une disparition par des
 * sauts.
 *
 * LA RÈGLE RETENUE (décision de l'auteur) : pendant que le clavier est ouvert, le chrome de PAGE
 * redevient du flux (`html.kbd … {position:static}`) et défile avec le contenu. Rien ne peut
 * sauter, puisque plus rien n'essaie de tenir une position ; et le navigateur garde le champ
 * focalisé visible, ce qu'il fait mieux que nous.
 *
 * CE QUI EST DONC MESURÉ, et c'est l'INVERSE de ce que ce fichier contrôlait :
 *   1. aucune ORIGINE (`top:`) de chrome de page ne lit `--vvt` — on ne poursuit plus rien ;
 *   2. la classe `html.kbd` existe ET libère au moins l'en-tête — sans quoi la règle serait écrite
 *      mais sans effet, et c'est justement la moitié qu'on oublie.
 * Les COUCHES PLEIN ÉCRAN gardent `--vvt` et sont hors de portée : une modale, la visionneuse ou
 * l'écran d'invité RECOUVRENT la page, elles n'ont pas de flux où retomber (v5.10.9, confirmée à
 * l'usage). Elles se reconnaissent à leur `height` calée sur `--vvh`.
 *
 * VÉRIFIÉ CAPABLE D'ÉCHOUER DANS LES DEUX SENS : `--vvt` réintroduit dans le `top` de l'en-tête
 * -> rouge ; règle `html.kbd` retirée -> rouge. Fichier restauré à l'octet.
 */
import { readFileSync } from 'node:fs';

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = src.slice(src.indexOf('<style>'), src.lastIndexOf('</style>'))
               .replace(/\/\*[\s\S]*?\*\//g, '');          // les commentaires CITENT la règle

const fautes = [];

/* 1. Aucune ORIGINE de chrome ne poursuit le viewport. Une règle qui pose `height` sur `--vvh` est
      une couche plein écran : elle n'a pas de flux où retomber, elle est hors sujet. */
for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
  const sel = m[1].trim().split('\n').pop().trim(), corps = m[2];
  const top = /(?:^|;)\s*top\s*:\s*([^;]+)/.exec(corps);
  if (!top || !/--vvt/.test(top[1])) continue;
  if (/--vvh/.test(corps)) continue;                        // couche plein écran (cf. en-tête)
  fautes.push({ sel, quoi: 'poursuit le viewport visuel (`--vvt` dans son `top`)',
    remede: 'le chrome de page ne poursuit rien : il se retire via `html.kbd`' });
}

/* 2. Et la règle qui LIBÈRE existe vraiment. */
/* ⚠ FRONTIÈRE DE MOT OBLIGATOIRE : sans `(?![\w-])`, un sélecteur renommé `html.kbdX` satisfaisait
   encore le motif (le `[^{]*` enjambait le suffixe) — le contrôle restait vert alors que la règle
   ne s'appliquait plus. Vu à la vérification de capacité d'échouer, pas en le relisant. */
const KBD = /html\.kbd(?![\w-])/;
const libere = new RegExp(KBD.source + '[^{]*\\{[^}]*position\\s*:\\s*static').test(css)
            && new RegExp(KBD.source + '[^{]*header\\.bar').test(css);
if (!libere) fautes.push({ sel: 'html.kbd',
  quoi: 'la règle qui libère le chrome est absente ou ne couvre pas `header.bar`',
  remede: 'sans elle, le chrome reste épinglé hors de l’écran clavier ouvert' });

if (fautes.length) {
  console.error('✗ check-stick : ' + fautes.length + ' problème(s) d’ancrage du chrome :');
  fautes.forEach(f => console.error('   · ' + f.sel.slice(0, 80) + '\n       ' + f.quoi + '\n       ' + f.remede));
  process.exit(1);
}

const couches = [...css.matchAll(/(?:^|;)\s*top\s*:\s*[^;]*--vvt/g)].length;
const n = (css.match(/html\.kbd(?![\w-])/g) || []).length;
console.log('✓ check-stick : aucun chrome de page ne poursuit le viewport visuel ; ' + n
  + ' sélecteur(s) le libèrent sous clavier ; ' + couches + ' couche(s) plein écran gardent le décalage.');
