/* CE QUI COLLE SOUS L'EN-TÊTE LIT UN SEUL TOKEN (v5.12.1).
 *
 * POURQUOI. Le décalage « sous l'en-tête » était recopié dans cinq règles (`#crisisDock`,
 * `#refBar`, `.ed-grab`, la barre de sélection, l'en-tête lui-même). La v5.12.0 a fait suivre le
 * viewport visuel au chrome collant — clavier ouvert, un `sticky` calé sur le viewport de MISE EN
 * PAGE passe au-dessus de l'écran — mais n'a corrigé que TROIS de ces cinq sites. `#refBar`, la
 * barre de recherche d'une référence, est restée sur l'ancien calcul et continuait donc de
 * disparaître exactement dans le cas qu'on venait de réparer : « l'en-tête apparaît maintenant
 * mais pas le bandeau recherche sur iPad/iPhone ».
 *
 * C'est la faute que ce dépôt paie le plus souvent, et qu'il a déjà nommée ailleurs (MUTE_SEL, la
 * table MIME des harnais, les listes tenues à la main) : une règle répartie dans n sites finit
 * corrigée dans n−2, en silence. Le remède est le même partout — UN token, un seul lecteur par
 * site — et ce contrôle rend le remède auto-exécutoire.
 *
 * CE QUI EST MESURÉ. Toute propriété `top` qui s'ancre sur la hauteur de l'en-tête doit tenir
 * compte du viewport visuel — soit par `--hdr-off` (le token qui porte les deux), soit en ajoutant
 * `--vvt` elle-même. `--hdr-h` reste libre partout ailleurs (hauteurs, `padding-top` de
 * compensation) : ce n'est pas la variable qui est proscrite, c'est son usage comme ORIGINE d'une
 * couche collante sans le décalage du clavier.
 *
 * EXEMPTIONS NOMMÉES ET MOTIVÉES, comme dans check-type et check-paliers — une exemption anonyme
 * rouvrirait la porte qu'on vient de fermer.
 *
 * VÉRIFIÉ CAPABLE D'ÉCHOUER (leçon v4.31.1) : la règle `#refBar` remise dans son état d'avant
 * (`top:var(--hdr-h,64px)`) fait rougir ce contrôle, qui la nomme ; fichier restauré à l'octet.
 */
import { readFileSync } from 'node:fs';

const src = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const css = src.slice(src.indexOf('<style>'), src.lastIndexOf('</style>'))
               .replace(/\/\*[\s\S]*?\*\//g, '');          // les commentaires CITENT la règle

/* On lit les DÉCLARATIONS `top:` (jamais `padding-top`, `scroll-padding-top`, `--azr-top`…) :
   le motif exige un début de déclaration — accolade, point-virgule ou début de bloc. */
/* `.azrail` — LE RAIL A→Z. Son haut est MESURÉ puis GELÉ dans `--azr-top` (v5.6 : une géométrie
   de chrome ne se dérive jamais d'un état qui dépend du défilement — sinon ses lettres, qui sont
   CENTRÉES, se déplacent de 26 px sous le doigt). Lui faire suivre `--vvt` déplacerait son HAUT
   sans déplacer son BAS, donc grandirait sa boîte et redéplacerait ces mêmes lettres : un
   demi-correctif pire que le défaut. Et le cas ne se rencontre pas — clavier ouvert, on TAPE dans
   la recherche, on ne vise pas une lettre du rail. Décision revue le jour où le rail devra rester
   utilisable pendant la frappe. */
const EXEMPTIONS = [{ sel: /\.azrail/, pourquoi: 'haut gelé par mesure (v5.6) ; le suivre déplacerait ses lettres centrées' }];

const fautes = [];
for (const m of css.matchAll(/[{;]\s*top\s*:\s*([^;}]+)/g)) {
  const val = m[1];
  if (!/--hdr-h/.test(val)) continue;
  if (/--hdr-off|--vvt/.test(val)) continue;          // le décalage du clavier est pris en compte
  // Contexte : le sélecteur qui précède, pour NOMMER la règle en défaut.
  const avant = css.slice(0, m.index);
  const sel = (avant.slice(avant.lastIndexOf('}') + 1).trim().split('\n').pop() || '').trim();
  if (EXEMPTIONS.some(e => e.sel.test(sel))) continue;
  fautes.push({ sel: sel.slice(0, 90), val: val.trim().slice(0, 80) });
}

if (fautes.length) {
  console.error('✗ check-stick : ' + fautes.length + ' règle(s) posent leur ORIGINE sur --hdr-h au'
    + ' lieu de --hdr-off (elles ne suivront pas le viewport visuel, donc disparaîtront clavier ouvert) :');
  fautes.forEach(f => console.error('   · ' + (f.sel || '(sélecteur non isolé)') + '  →  top:' + f.val));
  console.error('   Remède : top:var(--hdr-off) — le token porte --hdr-h ET --vvt (cf. :root).');
  process.exit(1);
}

const lus = [...css.matchAll(/[{;]\s*top\s*:\s*[^;}]*--hdr-off/g)].length;
console.log('✓ check-stick : ' + lus + ' couche(s) collante(s) sous l’en-tête, toutes sur --hdr-off'
  + ' (elles suivent l’en-tête ET le viewport visuel) ; ' + EXEMPTIONS.length + ' exemption(s) motivée(s).');
