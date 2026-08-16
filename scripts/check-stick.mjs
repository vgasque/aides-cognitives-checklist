/* CE QUI EST `sticky` NE SE DÉCALE PAS — CE QUI EST `fixed`, SI (v5.12.1, RÈGLE INVERSÉE en v5.12.10).
 *
 * HISTOIRE, parce qu'elle EST la règle. La v5.12.0 a fait suivre le décalage du viewport visuel
 * (`--vvt`, non nul seulement quand un clavier LOGICIEL est ouvert) à tout le chrome collant, pour
 * réparer une barre de recherche qui disparaissait. Ce contrôle a d'abord servi à imposer ce
 * décalage PARTOUT — et il a fallu quatre versions de retours d'usage, dont deux vidéos, pour voir
 * qu'il ne fallait l'imposer qu'à la MOITIÉ :
 *
 *   · `position:sticky` vit DANS LE FLUX. Quand le clavier s'ouvre, le système fait défiler la PAGE
 *     pour amener le champ focalisé sous les yeux, et un élément collant suit son document. Lui
 *     ajouter le décalage le compte DEUX FOIS : il descend dans la zone visible et laisse voir du
 *     contenu au-dessus de lui (capturé à t = 5,0 s sur la première vidéo de l'auteur).
 *   · `position:fixed` est ancré au viewport de MISE EN PAGE et ne suit rien. Lui a bel et bien
 *     besoin du décalage — c'est le correctif v5.10.9 des couches plein écran, confirmé à l'usage,
 *     et c'est `#refBar`, dont la disparition avait ouvert tout ce dossier.
 *
 * CE QUI EST MESURÉ, par bloc de déclarations : si le bloc pose une ORIGINE (`top:`) dérivée d'une
 * hauteur de chrome (`--hdr-h`, `--stick-top`, `--quai-b`), alors
 *   - `position:fixed`  -> il DOIT porter le décalage (`--vvt`, directement ou via `--hdr-off`) ;
 *   - `position:sticky` -> il ne doit PAS le porter.
 * Ces variables restent libres partout ailleurs (hauteurs, `scroll-padding`, compensations) : ce
 * n'est pas la variable qui est réglementée, c'est l'ORIGINE d'une couche de chrome.
 *
 * EXEMPTIONS NOMMÉES ET MOTIVÉES, comme dans check-type et check-paliers.
 *
 * VÉRIFIÉ CAPABLE D'ÉCHOUER DANS LES DEUX SENS (leçon v4.31.1) : décalage retiré à `#refBar`
 * (fixe) -> rouge ; décalage ajouté à `#crisisDock` (collant) -> rouge. Fichier restauré à l'octet.
 */
import { readFileSync } from 'node:fs';

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = src.slice(src.indexOf('<style>'), src.lastIndexOf('</style>'))
               .replace(/\/\*[\s\S]*?\*\//g, '');          // les commentaires CITENT la règle

/* `.azrail` — LE RAIL A→Z. Son haut est MESURÉ puis GELÉ dans `--azr-top` (v5.6 : une géométrie de
   chrome ne se dérive jamais d'un état qui dépend du défilement — sinon ses lettres, qui sont
   CENTRÉES, se déplacent de 26 px sous le doigt). Lui faire suivre le viewport déplacerait son HAUT
   sans son BAS, donc grandirait sa boîte et redéplacerait ces lettres : un demi-correctif pire que
   le défaut. Et le cas ne se rencontre pas — clavier ouvert, on TAPE, on ne vise pas une lettre du
   rail. À revoir le jour où le rail devra rester utilisable pendant la frappe. */
const EXEMPTIONS = [{ sel: /\.azrail/, pourquoi: 'haut gelé par mesure (v5.6) ; le suivre déplacerait ses lettres centrées' }];

/* ⚠ `--hdr-off` COMPTE COMME UNE HAUTEUR DE CHROME, et l'oubli s'est vu à la vérification : sans
   lui, une règle COLLANTE écrite `top:var(--hdr-off)` ne mentionne littéralement aucune hauteur,
   donc échappait au contrôle — c'est-à-dire exactement la faute que la v5.12.10 vient de retirer
   de six règles. Un contrôle qui ne voit pas la forme qu'a prise le défaut ne vaut rien. */
const HAUTEUR = /--hdr-h|--hdr-off|--stick-top|--quai-b/;
const DECALAGE = /--vvt|--hdr-off/;

const fautes = [];
for (const m of css.matchAll(/([^{}]+)\{([^{}]*)\}/g)) {
  const sel = m[1].trim().split('\n').pop().trim(), corps = m[2];
  const top = /(?:^|;)\s*top\s*:\s*([^;]+)/.exec(corps);
  if (!top || !HAUTEUR.test(top[1])) continue;
  if (EXEMPTIONS.some(e => e.sel.test(sel))) continue;
  const fixe = /position\s*:\s*fixed/.test(corps), collant = /position\s*:\s*sticky/.test(corps);
  const porte = DECALAGE.test(top[1]);
  if (fixe && !porte) fautes.push({ sel, val: top[1].trim(), quoi: 'FIXE sans décalage — elle disparaîtra clavier ouvert' });
  if (collant && porte) fautes.push({ sel, val: top[1].trim(), quoi: 'COLLANTE avec décalage — compté deux fois, elle descendra dans l’écran' });
}

if (fautes.length) {
  console.error('✗ check-stick : ' + fautes.length + ' règle(s) de chrome mal ancrée(s) :');
  fautes.forEach(f => console.error('   · ' + (f.sel.slice(0, 80) || '(sélecteur non isolé)')
    + '\n       top:' + f.val.slice(0, 80) + '\n       ' + f.quoi));
  console.error('   Règle : `fixed` porte le décalage (--vvt / --hdr-off), `sticky` ne le porte pas.');
  process.exit(1);
}

const n = [...css.matchAll(/(?:^|;)\s*top\s*:\s*[^;]*(?:--hdr-h|--stick-top|--quai-b)[^;]*/g)].length;
console.log('✓ check-stick : ' + n + ' origine(s) de chrome, chacune ancrée selon son `position` '
  + '(`fixed` avec décalage, `sticky` sans) ; ' + EXEMPTIONS.length + ' exemption(s) motivée(s).');
