// Build OPTIONNEL : produit dans dist/ une copie déployable ALLÉGÉE de l'app.
// - index.html : les commentaires des <script> inline sont retirés (terser, SANS compress ni
//   mangle : le code reste strictement identique, seuls commentaires/espaces superflus partent).
//   ~80 Ko de documentation inline en moins à parser sur mobile.
// - sw.js : même traitement.
// - Les autres fichiers servis (manifest, icônes, _headers, .nojekyll) sont copiés tels quels.
// Le dépôt reste la SOURCE (commentée, auditable) ; dist/ n'est qu'un artefact, jamais committé.
// Déployer dist/ est un choix, pas une obligation : servir la racine du dépôt fonctionne toujours.
// Usage : npm run build
import { readFile, writeFile, mkdir, copyFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { minify } from 'terser';

const ROOT = fileURLToPath(new URL('..', import.meta.url));
const DIST = ROOT + 'dist/';
await mkdir(DIST, { recursive: true });

// Réglages : NE PAS transformer le code (comportement identique garanti), seulement le texte.
const OPTS = { compress: false, mangle: false, format: { comments: false } };

// index.html : réécrit chaque bloc <script>…</script> inline, minifié.
let html = await readFile(ROOT + 'index.html', 'utf8');
const blocks = [...html.matchAll(/(<script>)([\s\S]*?)(<\/script>)/g)];
for (const m of blocks) {
  const out = await minify(m[2], OPTS);
  if (out.code == null) throw new Error('terser a échoué sur un <script> inline');
  html = html.replace(m[0], m[1] + out.code + m[3]);
}
await writeFile(DIST + 'index.html', html);

// sw.js minifié (mêmes réglages).
const sw = await minify(await readFile(ROOT + 'sw.js', 'utf8'), OPTS);
await writeFile(DIST + 'sw.js', sw.code);

// Fichiers servis, copiés tels quels.
const COPY = ['manifest.webmanifest', 'icon-192.png', 'icon-192-maskable.png', 'icon-512.png',
  'icon-512-maskable.png', 'apple-touch-icon.png', '_headers', '.nojekyll', 'LICENSE'];
for (const f of COPY) await copyFile(ROOT + f, DIST + f);

const before = (await readFile(ROOT + 'index.html')).length;
const after = html.length;
console.log(`dist/ prêt : index.html ${(before / 1024).toFixed(0)} Ko -> ${(after / 1024).toFixed(0)} Ko` +
  ` (−${(100 - after / before * 100).toFixed(0)} %). Vérifier avant déploiement : servir dist/ en http et ouvrir l'app.`);
