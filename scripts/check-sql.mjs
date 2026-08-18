#!/usr/bin/env node
/* SQL — garde-fou de syntaxe minimal (v4.44.1).
 *
 * POURQUOI CE FICHIER EXISTE. `supabase/schema.sql` et `supabase/rls-tests.sql` n'étaient
 * couverts par RIEN : ils ne sont ni servis, ni chargés par les tests, et l'erreur ne se voit
 * qu'au moment où on les colle dans l'éditeur SQL de Supabase — c'est-à-dire chez l'utilisateur,
 * sur une instance de production. C'est exactement ce qui vient d'arriver : une édition
 * automatisée a transformé `as $$` en `as $` sur DEUX fonctions trigger, et rien ne l'a vu.
 *
 * LA CAUSE MÉRITE D'ÊTRE ÉCRITE, parce qu'elle se reproduira : `String.prototype.replace()`
 * interprète `$$` DANS LA CHAÎNE DE REMPLACEMENT comme un dollar littéral unique (au même titre
 * que `$&`, `` $` ``, `$'` et `$1`). Un script de patch qui réinjecte du SQL contenant `$$` le
 * mutile donc en silence. Le remède, côté script : passer une FONCTION de remplacement (elle ne
 * subit aucune substitution), ou `split().join()`.
 *
 * ET LE CONTRÔLE QUI AVAIT ÉTÉ FAIT NE POUVAIT PAS L'ATTRAPER : il comptait les occurrences de
 * `$$` et vérifiait la parité. Or un `$$` amputé en `$` ne matche plus le motif — il disparaît du
 * compte des deux côtés, et la parité reste vraie. Un contrôle qui ne peut pas voir le défaut
 * qu'il est censé couvrir vaut zéro (leçon v4.31.1). D'où le contrôle par RUNS de dollars.
 */
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const FICHIERS = ['supabase/schema.sql', 'supabase/rls-tests.sql'];
const fautes = [];
let nDoBlocs = 0;
let nCaps = 0;
let nFonctions = 0, nDelims = 0;

for (const rel of FICHIERS) {
  const p = join(ROOT, rel);
  if (!existsSync(p)) { fautes.push(`${rel} : introuvable`); continue; }
  const sql = readFileSync(p, 'utf8');
  const lignes = sql.split('\n');

  /* 1. RUNS DE DOLLARS. Un délimiteur de corps est `$$` ou `$nom$`. Un dollar ISOLÉ, entouré de
        non-dollars, n'a aucune raison d'exister hors d'une chaîne — et c'est la signature exacte
        du `$$` mutilé. On ignore les commentaires de ligne. */
  lignes.forEach((l, i) => {
    const code = l.replace(/--.*$/, '');
    for (const m of code.matchAll(/\$+/g)) {
      const av = code[m.index - 1], ap = code[m.index + m[0].length];
      // `$nom$` : un dollar suivi d'un identifiant puis d'un dollar — forme légitime.
      if (m[0].length === 1 && /[A-Za-z_]/.test(ap || '')) continue;
      // Dollar PRÉCÉDÉ d'une lettre : c'est l'ANCRE DE FIN D'UNE REGEX (`'…\.pdf$'`), pas un
      // délimiteur. Tolérance étroite et voulue — la mutilation que ce contrôle traque produit
      // toujours un `$` précédé d'une espace ou d'un début de ligne (`as $$` -> `as $`), jamais
      // d'une lettre, donc elle reste attrapée. Préférer malgré tout une validation sans ancre
      // quand c'est possible : moins d'exceptions à raisonner (cf. share_open dans schema.sql).
      if (m[0].length === 1 && /[A-Za-z_]/.test(av || '')) continue;
      if (m[0].length !== 2)
        fautes.push(`${rel}:${i + 1} — suite de ${m[0].length} dollar(s) « ${m[0]} » : un délimiteur de corps s'écrit « $$ »\n        ${l.trim().slice(-72)}`);
    }
  });

  /* 2. APPARIEMENT. Chaque `$$` ouvre ou ferme un corps : leur nombre doit être PAIR, et chaque
        `create … function` doit être suivi d'exactement une paire avant le `;` terminal. */
  const delims = (sql.match(/\$\$/g) || []).length;
  nDelims += delims;
  if (delims % 2) fautes.push(`${rel} : ${delims} délimiteurs « $$ » — nombre IMPAIR, un corps n'est pas refermé`);

  const fns = [...sql.matchAll(/create\s+(?:or\s+replace\s+)?function\s+([a-z0-9_.]+)/gi)];
  nFonctions += fns.length;
  for (const f of fns) {
    // Du nom de la fonction jusqu'au prochain `$$`, il ne doit y avoir NI `;` NI autre `create`.
    const apres = sql.slice(f.index + f[0].length);
    const iDelim = apres.indexOf('$$');
    if (iDelim < 0) { fautes.push(`${rel} : « ${f[1]} » n'a pas de corps délimité par « $$ »`); continue; }
    const entete = apres.slice(0, iDelim);
    if (/;/.test(entete.replace(/--.*$/gm, '')))
      fautes.push(`${rel} : l'en-tête de « ${f[1]} » contient un « ; » avant son corps — délimiteur probablement mutilé`);
  }

  /* 3. SURFACE NON AUTHENTIFIÉE — LISTE BLANCHE.
        Le rôle `anon` est utilisable par n'importe qui : la clé publishable est en clair dans
        index.html. Le projet lui ouvre TROIS fonctions nommées, et rien d'autre.
        Le scénario redouté n'est pas la malveillance, c'est le dépannage : PostgREST accompagne
        un refus 42501 d'un `hint` qui nomme le grant manquant, et la réponse la plus répandue en
        ligne est la forme GLOBALE. À trois heures du matin, devant un partage qui ne marche pas,
        ce qui se colle dans l'éditeur SQL est `grant execute on all functions … to anon` — et
        rien, jusqu'ici, ne l'aurait vu passer en revue. */
  /* 4. ORDRE DE DÉFINITION — le piège propre aux fonctions `language sql`.
        Une fonction SQL est intégralement RÉSOLUE À SA CRÉATION : elle ne peut référencer aucun
        objet déclaré plus bas dans le fichier, sous peine d'un `42P01: relation … does not exist`
        au collage. Une fonction `language plpgsql`, elle, n'analyse son corps qu'à la première
        exécution et n'a donc pas cette contrainte — d'où une asymétrie qui ne se voit pas à la
        relecture, et qui a déjà coûté deux re-créations de `get_instance_stats`.
        Le défaut ne se manifeste QUE dans l'éditeur SQL de Supabase, c'est-à-dire sur une
        instance de production : exactement le trou que ce fichier existe pour fermer. */
  const defAt = new Map();
  for (const m of sql.matchAll(/create\s+table\s+(?:if\s+not\s+exists\s+)?public\.([a-z0-9_]+)/gi))
    if (!defAt.has(m[1].toLowerCase())) defAt.set(m[1].toLowerCase(), m.index);
  for (const m of sql.matchAll(/create\s+(?:or\s+replace\s+)?function\s+public\.([a-z0-9_]+)/gi))
    if (!defAt.has(m[1].toLowerCase())) defAt.set(m[1].toLowerCase(), m.index);
  for (const m of sql.matchAll(/create\s+(?:or\s+replace\s+)?function\s+public\.([a-z0-9_]+)/gi)) {
    const open = sql.indexOf('$$', m.index);
    if (open < 0) continue;
    if (!/language\s+sql\b/i.test(sql.slice(m.index, open))) continue;   // plpgsql : hors contrainte
    const close = sql.indexOf('$$', open + 2);
    const corps = sql.slice(open + 2, close < 0 ? sql.length : close);
    const vus = new Set();
    for (const r of corps.matchAll(/\bpublic\.([a-z0-9_]+)/gi)) {
      const nom = r[1].toLowerCase();
      if (vus.has(nom)) continue;
      vus.add(nom);
      const at = defAt.get(nom);
      if (at !== undefined && at > m.index)
        fautes.push(`${rel} : « ${m[1]} » est en « language sql » et référence « public.${nom} », défini PLUS BAS dans le fichier — résolution à la création, donc 42P01 au collage. Déplacer la fonction après, ou la re-créer une seconde fois.`);
    }
  }

  const ANON_FN_OK = ['share_join', 'share_pull', 'share_push'];
  lignes.forEach((l, i) => {
    const code = l.replace(/--.*$/, '').trim();
    if (!/^grant\b/i.test(code)) return;
    if (/\bon\s+all\s+(functions|tables|sequences|routines)\b/i.test(code))
      fautes.push(`${rel}:${i + 1} — « grant … on all … » est refusé quel que soit le rôle : accorder objet par objet\n        ${code.slice(0, 72)}`);
    if (!/\bto\b[^;]*\banon\b/i.test(code)) return;
    if (/^grant\s+usage\s+on\s+schema\s+public\s+to\s+anon\s*;?$/i.test(code)) return;   // seule exception non-fonction
    const m = code.match(/\bon\s+function\s+public\.([a-z0-9_]+)\s*\(/i);
    if (!m || !ANON_FN_OK.includes(m[1]))
      fautes.push(`${rel}:${i + 1} — grant à « anon » hors liste blanche (${ANON_FN_OK.join(', ')})\n        ${code.slice(0, 72)}`);
  });
}

/* ── VARIABLES DE BLOC plpgsql NON DÉCLARÉES ──────────────────────────────────────────────────
   `rls-tests.sql` n'est ni servi, ni chargé par les tests : sa seule épreuve est le COLLAGE DANS
   L'ÉDITEUR SQL, donc sur une instance réelle. Une variable oubliée dans le `declare` y coûte un
   aller-retour complet — c'est arrivé (« column v_share does not exist »), sur des sections
   ajoutées à un bloc déjà long dont les conventions de nommage n'étaient pas relues.
   PostgreSQL, lui, ne le dit qu'à l'EXÉCUTION de la ligne fautive : un test placé en fin de bloc
   peut donc casser après trois minutes de travail réussi. Le contrôle est statique et trivial —
   collecter ce qui est déclaré, collecter ce qui est employé, comparer. Il ne prétend pas
   remplacer un vrai analyseur : il attrape la faute qui a été commise deux fois. */
for (const rel of FICHIERS) {
  const pf = join(ROOT, rel);
  if (!existsSync(pf)) continue;
  const txt = readFileSync(pf, 'utf8');
  const rx = /\bdo\s+\$\$\s*declare\b([\s\S]*?)\bbegin\b([\s\S]*?)\bend\s*\$\$/gi;
  let m, nBloc = 0;
  while ((m = rx.exec(txt))) {
    nBloc++;
    const decl = new Set();
    // Une déclaration est « nom type … ; » en début de ligne — on ne prend que le premier mot.
    m[1].split('\n').forEach(l => {
      const c = l.replace(/--.*$/, '').trim();
      const d = c.match(/^([a-z_][a-z0-9_]*)\s+/i);
      if (d) decl.add(d[1].toLowerCase());
    });
    if (!decl.size) continue;               // pas un bloc à variables : rien à dire
    const corps = m[2].replace(/--.*$/gm, '').replace(/'(?:[^']|'')*'/g, "''");
    const vus = new Set();
    let u; const rxu = /\b(v_[a-z0-9_]+)\b/gi;
    while ((u = rxu.exec(corps))) vus.add(u[1].toLowerCase());
    const debut = txt.slice(0, m.index).split('\n').length;
    for (const v of vus) if (!decl.has(v))
      fautes.push(`${rel}: bloc « do $$ » ligne ~${debut} — variable « ${v} » EMPLOYÉE mais jamais DÉCLARÉE\n        (PostgreSQL ne le dira qu'à l'exécution de la ligne fautive, donc sur votre instance)`);
  }
  if (nBloc) nDoBlocs += nBloc;
}

/* -- ACCES DIRECT A UNE TABLE SOUS LE ROLE `anon` ------------------------------------------
   `anon` n'a AUCUN privilege de table, par construction : c'est tout l'objet du 13, et le schema
   le revoque explicitement. Toute lecture ou ecriture DIRECTE d'une table pendant qu'il est actif
   est donc une erreur certaine — « permission denied », a l'execution, sur une instance reelle.
   La regle est volontairement BORNEE A `anon` : sous `authenticated`, interroger une table est
   legitime et c'est meme ainsi qu'on prouve que la RLS filtre (14.19 lit l'historique d'Alice
   sous Bob et attend zero ligne). Un controle plus large produirait des faux positifs sur les
   tests memes qui font le travail.
   Les appels de FONCTION ne comptent pas : `share_join`, `share_pull` et `share_push` sont
   `security definer` et c'est precisement leur raison d'etre. */
for (const rel of FICHIERS) {
  const pf = join(ROOT, rel);
  if (!existsSync(pf)) continue;
  const lignes = readFileSync(pf, 'utf8').split('\n');
  let anon = false;
  lignes.forEach((l, i) => {
    const c = l.replace(/--.*$/, '');
    if (/\bset\s+local\s+role\s+anon\b/i.test(c)) { anon = true; return; }
    if (/\breset\s+role\b/i.test(c) || /\bset\s+local\s+role\s+(?!anon)\w+/i.test(c)) { anon = false; return; }
    if (!anon) return;
    const m = c.match(/\b(?:from|join|into|update)\s+public\.([a-z0-9_]+)\s*(?!\()/i);
    if (m)
      fautes.push(`${rel}:${i + 1} — table « public.${m[1]} » lue en DIRECT sous le role « anon », qui n'a aucun privilege de table\n`
        + `        ${c.trim().slice(0, 76)}\n`
        + `        (PostgreSQL repond « permission denied » a l'execution : reprendre les droits par « reset role », puis restituer)`);
  });
}

/* ── LES CAPACITÉS DU CLIENT ET DU SERVEUR DOIVENT COÏNCIDER ─────────────────────────────────
   `SHARE_KINDS_ANY` / `SHARE_KINDS_LEAD` (index.html) et `share_kind_allowed` (schema.sql) sont
   DEUX ÉCRITURES DE LA MÊME RÈGLE, dans deux langages. Elles ont divergé : le redécoupage de la
   v4.55.0 a été porté des deux côtés, mais l'assertion qui l'éprouve ne l'a pas été — et le défaut
   n'est apparu qu'au collage dans l'éditeur SQL, sur une instance réelle.
   UNE DIVERGENCE EST SILENCIEUSE ET ASYMÉTRIQUE : si le client est plus permissif, un geste part
   et le serveur le jette sans que l'auteur le sache — c'est « cocher dans le vide en croyant
   contribuer », le pire mode de défaillance nommé au plan. Si c'est le serveur, un geste
   parfaitement légitime est refusé sans raison lisible.
   Le contrôle est statique : on lit les deux listes et on les compare. */
{
  const idx = join(ROOT, 'index.html'), sch = join(ROOT, 'supabase/schema.sql');
  if (existsSync(idx) && existsSync(sch)) {
    const js = readFileSync(idx, 'utf8'), sq = readFileSync(sch, 'utf8');
    /* [a-zA-Z_]\w* et non [a-z_]+ (v5.14.14) : les clés camelCase (`elapsedMs`, `navSeq`)
       étaient invisibles DES DEUX CÔTÉS — une divergence sur elles n'aurait jamais rougi. Les
       genres, tous en minuscules, ne changent pas. */
    const mots = t => [...t.matchAll(/'([a-zA-Z_]\w*)'/g)].map(x => x[1]).sort();
    const liste = (txt, rx) => { const m = txt.match(rx); return m ? mots(m[1]) : null; };
    const cAny  = liste(js, /const SHARE_KINDS_ANY\s*=\s*\[([\s\S]*?)\]/);
    const cLead = liste(js, /const SHARE_KINDS_LEAD\s*=\s*\[([\s\S]*?)\]/);
    /* Cote SQL, on parcourt les branches et on les CLASSE par le role qui suit, au lieu de
       deviner leur ordre. `[^)]*` s'arrete au premier `)` : les listes de genres n'en
       contiennent pas, alors qu'une expression gourmande avalait la branche precedente — elle
       rendait un melange des deux, et le controle accusait une divergence inexistante. */
    let sAny = null, sLead = null;
    const RX = /when p_kind in \(([^)]*)\)[\s\S]{0,600}?then p_role\s*(?:in\s*\(([^)]*)\)|=\s*'([a-z]+)')/g;
    for (const m of sq.matchAll(RX)) {
      const roles = (m[2] || m[3] || '');
      if (/scribe/.test(roles)) { if (!sAny) sAny = mots(m[1]); }
      else if (/lead/.test(roles)) { if (!sLead) sLead = mots(m[1]); }
    }
    const cmp = (nom, a, b) => {
      if (!a || !b) { fautes.push(`capacités « ${nom} » : liste introuvable d'un côté (client ${a ? 'ok' : 'ABSENT'}, serveur ${b ? 'ok' : 'ABSENT'})`); return; }
      const seulA = a.filter(x => !b.includes(x)), seulB = b.filter(x => !a.includes(x));
      if (seulA.length || seulB.length)
        fautes.push(`capacités « ${nom} » : le CLIENT et le SERVEUR divergent\n`
          + `        client seul : ${seulA.join(', ') || '—'}\n`
          + `        serveur seul : ${seulB.join(', ') || '—'}\n`
          + `        (une divergence ne se voit qu'à l'usage : un geste part et disparaît, ou est refusé sans raison lisible)`);
    };
    cmp('ouvert aux deux rôles', cAny, sAny);
    cmp('réservé au lead', cLead, sLead);
    if (cAny && cLead) nCaps = cAny.length + cLead.length;
    /* PARITÉ DES CLÉS DE PAYLOAD (v5.14.14, A216) — la leçon jumelle des genres, payée au prix
       fort : la v5.14.5 a ajouté le GENRE `sig` (parité 20/20 verte) sans étendre la liste
       blanche des CLÉS de `share_push` — le serveur amputait `o` (offre) et `a` (réponse), et
       l'appariement silencieux mourait en silence pendant que le hub du harnais, qui ne
       filtrait rien, restait vert. La liste vit désormais des deux côtés (SHARE_PAYLOAD_KEYS,
       que le hub applique) et TOUTE divergence est rouge. */
    const cKeys = liste(js, /const SHARE_PAYLOAD_KEYS\s*=\s*\[([\s\S]*?)\]/);
    /* DEUX « where k in ( » vivent dans le schéma : celui de la FICHE (share_open) et celui du
       PAYLOAD (share_push) — l'ancrage sur `jsonb_each(e->'payload')` désigne le bon sans
       dépendre de leur ordre. */
    const mKeys = sq.match(/jsonb_each\(e->'payload'\)[\s\S]*?where k in \(([\s\S]*?)\)\)/);
    const sKeys = mKeys ? mots(mKeys[1].replace(/\/\*[\s\S]*?\*\//g, '')) : null;
    cmp('clés de payload autorisées', cKeys, sKeys);
    if (cKeys) nCaps += cKeys.length;
  }
}

/* UN RENOMMAGE QUI SE VISE LUI-MÊME (v5.0.0, lot T9 — défaut VÉCU, signalé par l'utilisateur).
   `alter table public.cognitive_aids rename to cognitive_aids` : Postgres répond « relation
   does not exist » et la migration entière échoue — sur l'instance de PRODUCTION, puisque c'est
   le seul endroit où ce fichier s'exécute.
   LA CAUSE N'EST PAS UNE FAUTE DE FRAPPE, C'EST UNE MÉTHODE : le renommage a été fait par
   remplacement en masse de l'ancien nom par le nouveau, et le remplacement a aussi réécrit
   L'INTÉRIEUR de la chaîne `execute` du bloc de migration — la seule ligne du fichier qui devait
   garder l'ANCIEN nom. C'est la famille du piège `String.replace()` / « $$ » déjà consignée dans
   ce script : un patch scripté mutile en silence ce qu'il ne distingue pas.
   Le contrôle est donc étroit et sûr : un `rename to` dont la source et la cible portent le même
   identifiant est TOUJOURS une faute, jamais une intention. */
{
  const RX = /alter\s+table\s+(?:if\s+exists\s+)?([a-z_][\w.]*)\s+rename\s+to\s+([a-z_]\w*)/gi;
  for (const f of FICHIERS) {
    const chemin = join(ROOT, f); if (!existsSync(chemin)) continue;
    const src = readFileSync(chemin, 'utf8');
    for (const m of src.matchAll(RX)) {
      const de = m[1].split('.').pop().toLowerCase(), vers = m[2].toLowerCase();
      if (de === vers) fautes.push(`${f} : « alter table ${m[1]} rename to ${m[2]} » — la source et la cible `
        + `sont le MÊME identifiant. Postgres échouera (« relation does not exist ») et la migration `
        + `s'arrêtera là. Cause typique : un remplacement en masse a réécrit l'intérieur d'une chaîne `
        + `« execute », c'est-à-dire la seule ligne qui devait garder l'ANCIEN nom.`);
    }
  }
}

if (fautes.length) {
  console.error('✗ check-sql : ' + fautes.length + ' problème(s).\n');
  for (const f of fautes) console.error('    ' + f);
  console.error('\n  Rappel : dans un script de patch, `String.replace()` transforme « $$ » du');
  console.error('  REMPLACEMENT en un seul « $ ». Utiliser une fonction de remplacement, ou split/join.');
  process.exit(1);
}
console.log(`✓ check-sql : ${nFonctions} fonction(s), ${nDelims} délimiteur(s) « $$ » appariés, `
  + `${nDoBlocs} bloc(s) « do $$ » à variables toutes déclarées, `
  + `${nCaps} capacité(s) de partage identiques client/serveur, aucun dollar isolé.`);
