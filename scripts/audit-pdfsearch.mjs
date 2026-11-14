/* AUDIT — CHERCHER DANS LES DOCUMENTS PDF (v5.2.0)
 *
 * Ce que ce harnais mesure, et pourquoi il ne pouvait pas être remplacé par des tests unitaires :
 * `tests.html` couvre l'index inversé comme STRUCTURE (construire, rouvrir, chercher — sur des
 * mots posés à la main). Il ne peut rien dire du CHEMIN : joindre un vrai PDF, en extraire le
 * texte par pdf.js, ranger l'index, le relire au démarrage suivant, le trouver depuis la
 * recherche de l'accueil, et ouvrir le document À LA PAGE.
 *
 * ⚠ LE TÉMOIN LE PLUS IMPORTANT EST LE 4ᵉ : « pdf.js n'est pas chargé quand on tape ». C'est la
 * contrainte qui a décidé de toute l'architecture (règle 13 : 1 773 Ko chargés paresseusement,
 * JAMAIS au démarrage — et taper une lettre dans la recherche n'est pas plus une raison de les
 * charger que d'ouvrir une fiche). Il se mesure sur une page RECHARGÉE : dans la session qui
 * vient d'indexer, pdf.js est légitimement en mémoire, et le contrôle passerait au vert sans
 * rien prouver.
 *
 * Le PDF de test est FABRIQUÉ ici (une trentaine de lignes, xref calculé) : dépendre d'un
 * fichier binaire commité rendrait le harnais opaque, et le dépôt n'en sert aucun.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce, remplir } from './harness.mjs';

/* Un PDF minimal, deux pages, texte Helvetica — de quoi exercer getTextContent pour de vrai.
   Les offsets de la table xref sont calculés, pas devinés : pdf.js sait reconstruire un xref
   cassé, et l'on mesurerait alors sa tolérance au lieu de notre chaîne.
   ⚠ LA PAGE EST LARGE (1200 pt) ET HAUTE (1600 pt), ET CE N'EST PAS DÉCORATIF. La HAUTEUR fait
   que le document ne tient pas dans la fenêtre : sans elle, « ouvrir à la page 2 » serait vrai
   sans rien faire, et le témoin d'atterrissage ne rencontrerait pas son cas. La LARGEUR — trouvé à la mesure : avec la
   MediaBox de 300 pt d'un premier jet, une ligne de 56 caractères en Helvetica 12 DÉBORDE la
   page, et pdf.js CLIPPE les glyphes qui en sortent. `getTextContent` rendait alors « dilut »
   pour « dilution », donc un corpus tronqué en silence — le harnais aurait mesuré ce qu'il
   trouvait au lieu de ce qu'il a écrit. Le témoin « le corpus est intact » plus bas ferme
   définitivement ce piège. */
function pdfDeuxPages(l1, l2) {
  const objs = [
    '<</Type/Catalog/Pages 2 0 R>>',
    '<</Type/Pages/Kids[3 0 R 4 0 R]/Count 2>>',
    '<</Type/Page/Parent 2 0 R/MediaBox[0 0 1200 1600]/Resources<</Font<</F1 5 0 R>>>>/Contents 6 0 R>>',
    '<</Type/Page/Parent 2 0 R/MediaBox[0 0 1200 1600]/Resources<</Font<</F1 5 0 R>>>>/Contents 7 0 R>>',
    '<</Type/Font/Subtype/Type1/BaseFont/Helvetica>>',
  ];
  const flux = t => `BT /F1 12 Tf 20 1500 Td (${t.replace(/[()\\]/g, s => '\\' + s)}) Tj ET`;
  [l1, l2].forEach(t => { const s = flux(t); objs.push(`<</Length ${s.length}>>\nstream\n${s}\nendstream`); });

  let out = '%PDF-1.4\n';
  const off = [];
  objs.forEach((o, i) => { off.push(out.length); out += `${i + 1} 0 obj\n${o}\nendobj\n`; });
  const xref = out.length;
  out += `xref\n0 ${objs.length + 1}\n0000000000 65535 f \n`
       + off.map(o => String(o).padStart(10, '0') + ' 00000 n \n').join('')
       + `trailer\n<</Size ${objs.length + 1}/Root 1 0 R>>\nstartxref\n${xref}\n%%EOF\n`;
  return Buffer.from(out, 'latin1');
}

const { srv, port } = await serveApp();
const browser = await moteur().launch();
const ctx = await browser.newContext({ viewport: { width: 900, height: 900 } });
const page = await ctx.newPage();
const URL_APP = `http://localhost:${port}/index.html`;

let ok = 0, ko = 0;
const t = (c, m, d) => { console.log((c ? '  ✓ ' : '  ✗ ') + m + (c || d === undefined ? '' : '\n      ' + d)); c ? ok++ : ko++; };
const sec = s => console.log(`\n══ ${s} — moteur ${NOM_MOTEUR} ══`);

const NOM_HOSTILE = `x"><img src=x onerror=alert(1)>'&<b>proto</b>`;
const PDF = pdfDeuxPages('adrenaline intramusculaire cuisse anterolaterale dilution',
                         'surveillance scope oxygene remplissage vasculaire adrenaline titree');

try {
  sec('joindre un PDF et l’indexer');
  await page.goto(URL_APP);
  await amorce(page);

  // Ouvrir l'éditeur de la fiche d'exemple par le VRAI chemin (menu ⋯ → Modifier).
  await page.evaluate(() => {
    const c = [...document.querySelectorAll('.card-open')].find(x => /Anaphylaxie/i.test(x.textContent));
    c.click();
  });
  await page.waitForFunction(() => document.body.classList.contains('view-read'));
  await page.click('#hdrMore');
  await page.waitForSelector('#moreMenu:not([hidden])');
  await page.evaluate(() => [...document.querySelectorAll('.more-menu button')].find(b => /^Modifier/.test(b.textContent.trim())).click());
  await page.waitForFunction(() => document.body.classList.contains('view-edit'));

  // Porte « ＋ » → Document : c'est elle qui arme `pickFile`, donc le callback de destination.
  await page.click('.ed-door');
  await page.waitForSelector('#addModal.on, .ai-modal.on');
  const [chooser] = await Promise.all([
    page.waitForEvent('filechooser'),
    page.evaluate(() => {
      const b = [...document.querySelectorAll('.ai-modal.on button')].find(x => /Document/i.test(x.textContent));
      if (!b) throw new Error('porte ＋ : aucune entrée « Document »');
      b.click();
    }),
  ]);
  /* ⚠ NOM HOSTILE, DÉLIBÉRÉMENT : le nom d'un document est une donnée entrante (il vient d'un
     fichier, et il est ÉDITABLE dans la rangée). Il traverse la rangée de résultat, un `title=`
     et un attribut — c'est le seul texte non maîtrisé de tout ce chantier, l'index n'exposant
     jamais le contenu du PDF. `esc()` est la SEULE barrière du projet (règle 4). */
  await chooser.setFiles({ name: NOM_HOSTILE + '.pdf', mimeType: 'application/pdf', buffer: PDF });

  /* Un rouge NON REPRODUIT (une fois, passe à pool 6 sur 4 cœurs ; 0 sur 6 exécutions chargées depuis) n'a laissé
     que « Timeout 15000ms exceeded ». Au prochain, l'échec dit OÙ en était l'app : vue, fenêtres ouvertes, porte
     de fichier encore armée, documents du brouillon. */
  await page.waitForFunction(() => document.querySelectorAll('[data-attname]').length > 0, null, { timeout: 15000 })
    .catch(async e => {
      const ou = await page.evaluate(() => ({ vue: state.view, fenetres: _openModals().map(m => m.id),
        porteArmee: typeof _upCtx !== 'undefined' && !!_upCtx, docs: ((state.draft || {}).docs || []).length,
        pile: history.state && history.state.d })).catch(x => 'illisible : ' + x.message.split('\n')[0]);
      throw new Error(`${e.message.split('\n')[0]} — état de l'app : ${JSON.stringify(ou)}`);
    });
  t(true, 'le document est joint à la fiche');

  const attId = await page.evaluate(() => (state.draft.docs || [])[0].id);
  /* ⚠ `attIx` est un `const` du script classique de l'app : il n'est PAS une propriété de
     `window`. Jusqu'en v5.39.1 ces trois attentes testaient `window.attIx` — toujours faux —
     et payaient leur plafond entier (20 + 10 + 30 s) à chaque passe ; mesuré : l'index est prêt
     en 1 à 85 ms. Plafonds inchangés : un index qui n'arrive pas échoue comme avant. */
  await page.waitForFunction(id => typeof attIx !== 'undefined' && attIx.has(id), attId, { timeout: 20000 })
    .catch(() => {});
  const ix = await page.evaluate(id => {
    const h = attIx.get(id);
    return h ? { none: !!h.none, n: h.n | 0, pages: h.pages | 0 } : null;
  }, attId);
  t(!!ix, 'il est INDEXÉ sans qu’on l’ait demandé (à l’ajout)', String(ix));
  t(ix && !ix.none && ix.pages === 2, 'les deux pages sont vues', JSON.stringify(ix));
  t(ix && ix.n >= 8, 'le dictionnaire porte les mots du document (' + (ix && ix.n) + ' distincts)');
  /* ⚠ LE FIXTURE SE VÉRIFIE LUI-MÊME : tous les mots que les recherches ci-dessous emploient
     doivent être RÉELLEMENT dans l'index. Sans ce contrôle, un PDF de test qui perd des glyphes
     ferait échouer les recherches pour une raison qui n'est pas celle qu'on mesure. */
  const mots = await page.evaluate(id => {
    const h = attIx.get(id);
    return h && !h.none ? ['anterolaterale', 'dilution', 'remplissage', 'surveillance'].filter(m => h.txt.indexOf(m) < 0) : ['(pas d’index)'];
  }, attId);
  t(mots.length === 0, 'témoin : le corpus de test est INTACT (aucun mot perdu à l’extraction)', 'manquants : ' + mots.join(', '));

  // Sortir de l'éditeur (l'écriture est continue : le document est déjà dans la fiche).
  await page.click('#hdrBack');
  await page.waitForFunction(() => !document.body.classList.contains('view-edit'));

  sec('le poids : un index, pas une copie du texte');
  const poids = await page.evaluate(async id => {
    const rec = await IDB.getIx(id);
    return rec ? { dict: rec.dict.byteLength, post: rec.post.byteLength, terms: rec.terms } : null;
  }, attId);
  t(!!poids && poids.dict > 0 && poids.post > 0, 'l’index rangé porte un dictionnaire ET des postings', JSON.stringify(poids));
  const rec = await page.evaluate(async id => { const r = await IDB.getIx(id); return r ? Object.keys(r) : []; }, attId);
  t(rec.indexOf('txt') < 0 && rec.indexOf('text') < 0,
    'AUCUN texte n’est conservé (c’est un index, pas une photocopie)', rec.join(','));

  sec('trouver depuis la recherche — sur une page RECHARGÉE');
  await page.goto(URL_APP);
  await page.waitForFunction(() => typeof fiches !== 'undefined' && !!document.querySelector('.card-open'));
  await page.waitForFunction(id => typeof attIx !== 'undefined' && attIx.has(id), attId, { timeout: 10000 }).catch(() => {});
  t(await page.evaluate(id => attIx.has(id), attId), 'l’index est relu au démarrage suivant');

  /* FENÊTRE DU TÉMOIN, rendue EXPLICITE (v5.39.2) : l'attente cassée ci-dessus donnait au témoin
     `_pdfjs === null` 10 s d'observation après le démarrage — il prouvait donc aussi, sans le
     dire, que rien ne charge pdf.js dans les 10 s qui suivent (règle 13 : jamais au démarrage ;
     la file d'indexation part au repos, plafond 2,5 s). On garde ces 10 s pour ne rien affaiblir. */
  await page.waitForTimeout(10000);
  const pdfAvant = await page.evaluate(() => _pdfjs === null);
  await remplir(page, 'anterolaterale');
  await page.waitForFunction(() => document.querySelectorAll('.doc-hit').length > 0, null, { timeout: 5000 })
    .catch(() => {});
  const hit = await page.evaluate(() => {
    const b = document.querySelector('.doc-hit');
    return b ? { txt: b.textContent.replace(/\s+/g, ' ').trim(), pg: b.dataset.docpg, id: b.dataset.docgo } : null;
  });
  t(!!hit, 'le mot du PDF sort un résultat « Dans les documents »', String(hit));
  t(!!hit && hit.pg === '1', 'il annonce la PAGE (1 ici)', hit && hit.pg);
  t(!!hit && hit.txt.indexOf('proto') >= 0, 'il nomme le document', hit && hit.txt);
  /* Le nom hostile ne doit avoir produit NI balise, NI attribut, NI script. */
  const inj = await page.evaluate(() => {
    const b = document.querySelector('.doc-hit');
    const nom = b.querySelector('b');
    return { nom: nom ? nom.textContent : '',
             img: document.querySelectorAll('.doc-hit img, .doc-hit script').length,
             gras: document.querySelectorAll('.doc-hit b b').length,
             echappe: b.innerHTML.indexOf('&lt;') >= 0,
             attrs: [...b.querySelectorAll('*')].some(x => x.hasAttribute('onerror') || x.hasAttribute('src')) };
  });
  /* ⚠ LE TÉMOIN D'ABORD : sans lui, un nom nettoyé en amont ferait passer le contrôle au vert
     sans que la barrière ait jamais été sollicitée. `safeFileName` ne retire NI < NI > NI " —
     c'est bien `esc()` qui protège, et c'est ce qu'on mesure. */
  t(/[<">]/.test(inj.nom), 'témoin : le nom hostile atteint bien le DOM (sinon rien n’est mesuré)', JSON.stringify(inj));
  t(inj.img === 0 && inj.gras === 0 && !inj.attrs && inj.echappe,
    'le nom du document ne peut RIEN injecter (balise, attribut, script)', JSON.stringify(inj));
  t(!!hit && /Anaphylaxie/.test(hit.txt), 'et la fiche qui le porte', hit && hit.txt);

  /* ⚠ LE TÉMOIN QUI TIENT L'ARCHITECTURE. */
  t(pdfAvant && await page.evaluate(() => _pdfjs === null),
    'pdf.js n’est PAS chargé par la frappe (1 773 Ko, règle 13)');

  // Un mot de la SECONDE page : la granularité par page est ce qui rend le résultat utile.
  await remplir(page, 'remplissage');
  await page.waitForTimeout(300);
  const pg2 = await page.evaluate(() => { const b = document.querySelector('.doc-hit'); return b ? b.dataset.docpg : null; });
  t(pg2 === '2', 'un mot de la 2ᵉ page renvoie à la page 2', String(pg2));

  // Conjonction : les deux mots ne sont sur AUCUNE page commune -> aucun document.
  await remplir(page, 'anterolaterale remplissage');
  await page.waitForTimeout(300);
  t(await page.evaluate(() => document.querySelectorAll('.doc-hit').length === 0),
    'deux mots de pages différentes ne rendent aucun document (ET logique)');

  // Un mot absent : ni faux positif, ni erreur.
  await remplir(page, 'zzintrouvable');
  await page.waitForTimeout(300);
  t(await page.evaluate(() => document.querySelectorAll('.doc-hit').length === 0), 'un mot absent ne rend rien');

  sec('ouvrir le document à la page');
  await remplir(page, 'remplissage');
  await page.waitForFunction(() => document.querySelectorAll('.doc-hit').length > 0, null, { timeout: 5000 });
  await page.click('.doc-hit');
  await page.waitForFunction(() => document.getElementById('pdfModal').classList.contains('on'), null, { timeout: 20000 });
  await page.waitForFunction(() => document.querySelectorAll('#pdfScroll .pdf-page').length >= 2, null, { timeout: 20000 });
  await page.waitForTimeout(400);
  /* ⚠ ON MESURE LA PROPRIÉTÉ, PAS LE MÉCANISME : exiger `scrollTop === offsetTop-8` rougit sur un
     correctif juste — quand le document est court, la position demandée est CLAMPÉE par le bas du
     défilement, et la page visée est alors visible sans que le calcul ait « échoué ». Ce qu'on
     doit garantir est qu'elle est À L'ÉCRAN et qu'on n'est pas resté en tête. */
  const vue = await page.evaluate(() => {
    const sc = document.getElementById('pdfScroll');
    const p2 = sc.querySelector('.pdf-page[data-p="2"]');
    return { top: sc.scrollTop, p2: p2 ? p2.offsetTop : -1, h: sc.clientHeight,
             max: sc.scrollHeight - sc.clientHeight };
  });
  const hautP2 = vue.p2 - vue.top;
  t(vue.max > 0, 'témoin : le document DÉBORDE la fenêtre (sinon il n’y a rien à mesurer)', JSON.stringify(vue));
  t(vue.p2 > 0 && hautP2 >= 0 && hautP2 < vue.h, 'le haut de la page 2 est À L’ÉCRAN', JSON.stringify(vue));
  t(vue.top > 0 && (Math.abs(vue.top - (vue.p2 - 8)) <= 2 || vue.top >= vue.max - 1),
    'la visionneuse n’est pas restée en tête de document', JSON.stringify(vue));
  t(await page.evaluate(() => _pdfjs !== null), 'témoin : pdf.js n’est chargé QUE là, sur un geste');

  sec('le porteur du document est un résultat, et l’entité cherche dans ses annexes');
  await page.evaluate(() => closePdfViewer());
  /* Le mot « remplissage » ne vit QUE dans le PDF : la fiche doit pourtant sortir dans la liste
     (v5.3.0 — le document qui correspond fait correspondre son porteur), avec l'extrait « dans
     ‹nom› · p. n ». */
  await remplir(page, '');
  await remplir(page, 'remplissage');
  await page.waitForTimeout(400);
  const listeDoc = await page.evaluate(() => ({
    rangees: document.querySelectorAll('.dir-row').length,
    fiche: [...document.querySelectorAll('.dir-t')].some(x => /Anaphylaxie/.test(x.textContent)),
    snip: (() => { const c = [...document.querySelectorAll('.card-snip')].find(x => /dans/.test(x.textContent)); return c ? c.textContent.replace(/\s+/g, ' ').trim() : ''; })(),
  }));
  t(listeDoc.fiche, 'la FICHE porteuse sort dans la liste pour un mot qui ne vit que dans son PDF', JSON.stringify(listeDoc));
  t(/p\. 2/.test(listeDoc.snip) && /proto/.test(listeDoc.snip), 'son extrait dit le document et la page', listeDoc.snip);

  // Le champ de la feuille « Toute la fiche » couvre les documents joints de la fiche.
  await remplir(page, '');
  await page.evaluate(() => { const c = [...document.querySelectorAll('.card-open')].find(x => /Anaphylaxie/i.test(x.textContent)); c.click(); });
  await page.waitForFunction(() => document.body.classList.contains('view-read'));
  await page.evaluate(() => { const b = document.getElementById('allBtn'); if (!b) throw new Error('allBtn absent'); b.click(); });
  await page.waitForFunction(() => !!document.getElementById('pfQ'), null, { timeout: 8000 });
  await page.fill('#pfQ', 'remplissage');
  await page.waitForFunction(() => { const b = document.getElementById('pfDocs'); return b && !b.hidden && b.querySelector('.doc-hit'); }, null, { timeout: 5000 }).catch(() => {});
  const pfd = await page.evaluate(() => { const b = document.getElementById('pfDocs'); return b && !b.hidden ? b.textContent.replace(/\s+/g, ' ').trim() : '(vide)'; });
  t(/passage/.test(pfd) && /p\. 2/.test(pfd), 'le champ de la feuille « Toute la fiche » trouve dans le PDF joint', pfd);
  // … et un mot absent replie la zone au lieu de la laisser mentir.
  await page.fill('#pfQ', 'zzintrouvable');
  await page.waitForTimeout(300);
  t(await page.evaluate(() => document.getElementById('pfDocs').hidden), '… et se replie sur un mot absent');

  sec('surligner et naviguer les occurrences dans la visionneuse');
  await page.fill('#pfQ', 'adrenaline');
  await page.waitForFunction(() => { const b = document.getElementById('pfDocs'); return b && !b.hidden && b.querySelector('[data-pfdoc]'); }, null, { timeout: 5000 });
  await page.click('#pfDocs [data-pfdoc]');
  await page.waitForFunction(() => document.getElementById('pdfModal').classList.contains('on'), null, { timeout: 20000 });
  await page.waitForFunction(() => document.querySelectorAll('#pdfScroll .pdf-hl').length > 0, null, { timeout: 20000 }).catch(() => {});
  /* A745 : on compte quand TOUTES les pages à l'écran ont posé leurs calques (texte lu) — sous charge, la page 2 posait
     les siens après le premier comptage, et les témoins « même nombre après zoom » comparaient 2 à 1. */
  await page.waitForFunction(() => _pv && _pv.pages.filter(s => s.vis).every(s => s.ov && s.tc), null, { timeout: 20000 }).catch(() => {});
  const hl = await page.evaluate(() => ({
    n: document.querySelectorAll('#pdfScroll .pdf-hl').length,
    pill: !document.getElementById('pdfHl').hidden,
    count: document.getElementById('pdfHlCount').textContent,
  }));
  t(hl.n > 0, 'les occurrences sont SURLIGNÉES sur la page rendue (' + hl.n + ' rectangle(s))', JSON.stringify(hl));

  /* LA PILULE NAÎT EN FONDU, SA RÉSERVE NON (v5.6, planche 10d/4). Deux moitiés : l'entrée joue à
     l'apparition, et elle ne REJOUE pas — `pdfHlSync` est appelée à chaque page peinte, une classe
     laissée en place rejouerait l'entrée pendant tout le défilement (A68/1). */
  const naiss = await page.evaluate(() => {
    const el = document.getElementById('pdfHl');
    return { cls: el.classList.contains('hl-in'),
             anim: getComputedStyle(el).animationName,
             reserve: getComputedStyle(el.closest('.pdf-card')).getPropertyValue('--pdfhl-r').trim() }; });
  t(naiss.cls && naiss.anim === 'hlIn', 'la pilule d’occurrences entre en fondu', JSON.stringify(naiss));
  t(/^\d+(\.\d+)?px$/.test(naiss.reserve) && parseFloat(naiss.reserve) > 0,
    '… et sa bande est réservée d’un coup, jamais animée', naiss.reserve);
  await page.evaluate(() => { pdfHlSync(); pdfHlSync(); });
  await page.waitForTimeout(60);
  t(await page.evaluate(() => document.getElementById('pdfHl').classList.contains('hl-in')) === true,
    '… et une resynchronisation ne la fait pas renaître (la classe reste, l’animation ne rejoue pas)');
  t(hl.pill && /1 \/ /.test(hl.count), 'la pilule ‹ n/N › est visible et compte', JSON.stringify(hl));
  /* Les rectangles couvrent du contenu réel : chacun est DANS la boîte de sa page. */
  t(await page.evaluate(() => [...document.querySelectorAll('.pdf-hl')].every(d => {
      const r = d.getBoundingClientRect(), pr = d.closest('.pdf-page').getBoundingClientRect();
      return r.width >= 4 && r.top >= pr.top - 1 && r.bottom <= pr.bottom + 1 && r.left >= pr.left - 1 && r.right <= pr.right + 1;
    })), 'chaque rectangle vit dans la boîte de sa page');
  /* A742 — ZOOM + PUIS − SANS ATTENDRE : on revient à l'échelle déjà rendue, donc AUCUN nouveau rendu ne repose les
     calques. Le surlignage doit revenir quand même (il disparaissait pour de bon). */
  await page.evaluate(() => { pdfZoom('in'); pdfZoom('out'); });
  await page.waitForFunction(() => document.querySelectorAll('#pdfScroll .pdf-hl').length > 0, null, { timeout: 5000 }).catch(() => {});
  const apresZoom = await page.evaluate(() => ({ n: document.querySelectorAll('#pdfScroll .pdf-hl').length,
    dedans: [...document.querySelectorAll('.pdf-hl')].every(d => { const r = d.getBoundingClientRect(), pr = d.closest('.pdf-page').getBoundingClientRect();
      return r.top >= pr.top - 1 && r.bottom <= pr.bottom + 1 && r.left >= pr.left - 1 && r.right <= pr.right + 1; }) }));
  t(apresZoom.n === hl.n && apresZoom.dedans, 'zoom + puis − : le surlignage revient, à sa place (A742)', JSON.stringify(apresZoom) + ' / avant ' + hl.n);
  /* A744 — LES CALQUES SONT ATTACHÉS À LA PAGE : posés en pourcentage, ce sont les MÊMES nœuds avant et après un zoom
     (rien n'est retiré ni recalculé), et ils survivent à la libération du canevas. */
  const memes = await page.evaluate(async () => {
    const avant = [...document.querySelectorAll('#pdfScroll .pdf-hl')];
    const pct = avant.every(d => /%$/.test(d.style.left) && /%$/.test(d.style.top) && /%$/.test(d.style.width) && /%$/.test(d.style.height));
    pdfZoom('in'); pdfZoom('in'); await new Promise(r => setTimeout(r, 300));   // horloge : laisse passer un rendu
    pdfZoom('out'); pdfZoom('out'); await new Promise(r => setTimeout(r, 300));   // horloge : idem, retour à l'échelle de départ
    const apres = [...document.querySelectorAll('#pdfScroll .pdf-hl')];
    const s = _pv.pages.find(x => x.el.querySelector('.pdf-hl'));
    releasePdfPage(s); const sansCanevas = s.el.querySelectorAll('.pdf-hl').length; s.vis = true; await renderPdfPage(s);
    return { pct, memes: avant.length === apres.length && avant.every((d, k) => d === apres[k]), sansCanevas, canevasPremier: s.el.firstChild === s.canvas }; });
  t(memes.pct && memes.memes && memes.sansCanevas > 0 && memes.canevasPremier, 'les calques sont en pourcentage de la page : mêmes nœuds après zoom, présents sans canevas (A744)', JSON.stringify(memes));
  /* A743 — LE RENDU QUI ÉCHOUE NE DOIT PAS EMPORTER LE SURLIGNAGE : on fait échouer le prochain rendu de chaque page
     (comme un canevas trop grand sur iOS), on zoome, et les rectangles doivent être là, à la nouvelle échelle. */
  const sansRendu = await page.evaluate(async () => {
    const w0 = document.querySelector('#pdfScroll .pdf-hl').getBoundingClientRect().width;
    _pv.pages.forEach(s => { if (s.page) { const r = s.page.render; s.page.render = () => { s.page.render = r; return { promise: Promise.reject(new Error('rendu refusé')) }; }; } });
    pdfZoom('in'); await new Promise(r => setTimeout(r, 400));   // horloge : laisse le rendu refusé aboutir
    const els = [...document.querySelectorAll('#pdfScroll .pdf-hl')];
    const r = { n: els.length, plusLarge: els.length ? els[0].getBoundingClientRect().width > w0 : false,
      dedans: els.every(d => { const a = d.getBoundingClientRect(), p = d.closest('.pdf-page').getBoundingClientRect(); return a.top >= p.top - 1 && a.bottom <= p.bottom + 1 && a.left >= p.left - 1 && a.right <= p.right + 1; }) };
    pdfZoom('out'); await new Promise(r => setTimeout(r, 400));   // horloge : retour à l'échelle de départ avant la suite
    return r; });
  t(sansRendu.n === hl.n && sansRendu.plusLarge && sansRendu.dedans, 'zoom dont le rendu échoue : le surlignage suit l’échelle quand même (A743)', JSON.stringify(sansRendu));
  /* A745 — LES BOUTONS DE ZOOM GARDENT LA PAGE REGARDÉE AU CENTRE : sans ancrage, la position restait la même en
     pixels dans un document agrandi, donc sur une AUTRE page (et le mot surligné sortait de l'écran). */
  const ancre = await page.evaluate(async () => {
    const sc = document.getElementById('pdfScroll'), y0 = sc.scrollTop;
    const ou = () => { const cy = sc.scrollTop + sc.clientHeight / 2; let k = 0; _pv.pages.forEach((p, n) => { if (p.el.offsetTop <= cy) k = n; });
      const el = _pv.pages[k].el; return { p: k + 1, f: (cy - el.offsetTop) / el.offsetHeight }; };
    const el2 = _pv.pages[1].el; sc.scrollTop = el2.offsetTop + el2.offsetHeight * 0.6 - sc.clientHeight / 2;
    const avant = ou(); pdfZoom('in'); pdfZoom('in'); const grand = ou();
    pdfZoom('out'); pdfZoom('out'); pdfZoom('out'); const petit = ou();
    pdfZoom('in'); sc.scrollTop = y0; await new Promise(r => setTimeout(r, 300));   // horloge : remise en état (échelle et défilement) avant la suite
    return { avant, grand, petit }; });
  t(ancre.avant.p === 2 && ancre.grand.p === 2 && Math.abs(ancre.grand.f - ancre.avant.f) < 0.03,
    'zoom + aux boutons : la page regardée reste au centre de l’écran (A745)', JSON.stringify(ancre));
  t(ancre.petit.p === 2 || ancre.petit.f > 0.9, '… et au zoom − aussi (ou le document tient alors entier)', JSON.stringify(ancre.petit));
  /* A746 — LA PLACE DU MOT EST MESURÉE, PLUS ESTIMÉE AU NOMBRE DE LETTRES. Page 2 : « adrenaline » est au milieu de
     la ligne ; sa vraie abscisse = 20 pt + la largeur Helvetica 12 pt de ce qui précède. */
  const align = await page.evaluate(() => {
    const ligne = 'surveillance scope oxygene remplissage vasculaire adrenaline titree', k = ligne.indexOf('adrenaline');
    const cx = document.createElement('canvas').getContext('2d'); cx.font = '12px Helvetica';
    const vrai = 20 + cx.measureText(ligne.slice(0, k)).width, vraiL = cx.measureText('adrenaline').width;
    const s = _pv.pages[1], d = s.el.querySelector('.pdf-hl');
    const x = parseFloat(d.style.left) / 100 * s.vp.width, w = parseFloat(d.style.width) / 100 * s.vp.width;
    const f = pdfHlFrac('illlliiii adrenaline WWWWMMMM', 10, 10, 'sans-serif');
    return { ecartX: Math.round((x - vrai) * 10) / 10, ecartL: Math.round((w - vraiL) * 10) / 10, etroit: Math.round(f[0] * 100) / 100,
      decompose: pdfNormMap('re\u0301fractaire').map[2] }; });
  t(Math.abs(align.ecartX) <= 3 && Math.abs(align.ecartL) <= 3, 'le rectangle tombe sur le mot, à 3 pt près (A746)', JSON.stringify(align));
  t(align.etroit < 0.2, '… un mot après des lettres étroites n’est plus décalé (au prorata des lettres : 0,36)', JSON.stringify(align));
  t(align.decompose === 3, '… et un accent décomposé ne décale pas les index', JSON.stringify(align));
  /* A747 — UNE PAGE À L'ÉCRAN N'EST JAMAIS LAISSÉE À UNE AUTRE ÉCHELLE : quand le défilement se pose, elle est redessinée
     (c'est ce qui laissait l'image floue après un pincer). */
  const filet = await page.evaluate(async () => {
    const sc = document.getElementById('pdfScroll'), s = _pv.pages.find(x => x.vis && x.canvas);
    s.renderedW = 1; sc.scrollTop += 2; await new Promise(r => setTimeout(r, 700));   // horloge : le filet attend 140 ms que le défilement se pose, puis le rendu
    const ok = s.renderedW === _pv.cssW; sc.scrollTop -= 2; await new Promise(r => setTimeout(r, 300));   // horloge : remise en place avant la suite
    return { ok, renduW: s.renderedW, cssW: _pv.cssW }; });
  t(filet.ok, 'défilement posé : une page à l’écran restée à une autre échelle est redessinée (A747)', JSON.stringify(filet));
  /* A748 — LA VIGNETTE DE DÉTAIL : rien à zoom ordinaire ; à 400 %, la zone visible est redessinée à pleine
     définition par-dessus l'image de base, sous les calques ; elle part avec la page. */
  const tuile = await page.evaluate(async () => {
    const sc = document.getElementById('pdfScroll'), z0 = _pv.z, y0 = sc.scrollTop;
    /* Attendre que TOUT soit posé : rendus de base finis, puis 200 ms de répit de la vignette, puis son dessin. En CI
       (machine lente), sortir dès « rendus finis » laissait la vignette encore dans son délai : faux rouge. On attend
       donc qu'une vignette existe (cas positif) ou, faute d'en voir, 1 s pleine après les rendus (cas négatif). */
    const rendus = () => _pv.pages.every(s => !s.vis || !s.canvas || s.renderedW === _pv.cssW);
    const attendre = async (veut) => { let calme = 0;
      for (let k = 0; k < 300; k++) { await new Promise(r => setTimeout(r, 50));   // horloge : sondage de fin de rendu (15 s au plus)
        if (veut && _pv.pages.some(s => s.tile) && !_pv.tileTask) return;
        calme = (rendus() && !_pv.tileTask) ? calme + 1 : 0;
        if (!veut && calme >= 20) return; } };
    await attendre(false);
    const ordinaire = _pv.pages.filter(s => s.tile).length;
    _pv.z = 4; pdfRescale(); await attendre(true);
    const s = _pv.pages.find(x => x.tile), W = s ? s.el.offsetWidth : 1, H = s ? s.el.offsetHeight : 1;
    const r = s && { x0: parseFloat(s.tile.style.left) / 100 * W, y0: parseFloat(s.tile.style.top) / 100 * H,
      w: parseFloat(s.tile.style.width) / 100 * W, h: parseFloat(s.tile.style.height) / 100 * H };
    const v = s && pdfVisRect(sc, s);
    const res = { ordinaire, aFort: !!s,
      dense: s ? +(s.tile.width / r.w / Math.min(3, devicePixelRatio)).toFixed(2) : 0,
      base: s ? +(s.canvas.width / W).toFixed(2) : 0,
      couvre: !!(s && v && r.x0 <= v.x0 + 1 && r.y0 <= v.y0 + 1 && r.x0 + r.w >= v.x1 - 1 && r.y0 + r.h >= v.y1 - 1),
      ordre: !!(s && s.tile.previousElementSibling === s.canvas && [...s.el.querySelectorAll('.pdf-hl,.pdf-lnk')].every(o => s.tile.compareDocumentPosition(o) & 4)) };
    if (s) { releasePdfPage(s); res.libere = !s.tile && !s.el.querySelector('.pdf-tile'); }
    res.diag = { cache: document.hidden, coeurs: navigator.hardwareConcurrency, dpr: devicePixelRatio, plafond: PDF_TILE_PX,
      pages: _pv.pages.filter(x => x.vis).map(x => [!!x.canvas, x.renderedW, x.canvas && x.canvas.width]).join(' ') };
    _pv.z = z0; pdfRescale(); sc.scrollTop = y0; await attendre(false);
    return res; });
  t(tuile.ordinaire === 0, 'zoom ordinaire : aucune vignette de détail, aucun dessin de plus (A748)', JSON.stringify(tuile));
  t(tuile.aFort && tuile.dense >= 0.85 && tuile.dense > tuile.base, '400 % : la zone visible est redessinée à pleine définition (A748)', JSON.stringify(tuile));
  t(tuile.couvre && tuile.ordre, '… elle couvre ce qu’on voit, entre l’image de base et les calques', JSON.stringify(tuile));
  t(tuile.libere === true, '… et part avec le canevas de la page', JSON.stringify(tuile));
  // Naviguer : « adrenaline » est sur les DEUX pages — › doit changer de page d'occurrence.
  const y0 = await page.evaluate(() => document.getElementById('pdfScroll').scrollTop);
  await page.click('#pdfHlNext');
  await page.waitForTimeout(200);
  const nav2 = await page.evaluate(() => ({ y: document.getElementById('pdfScroll').scrollTop, c: document.getElementById('pdfHlCount').textContent }));
  t(nav2.y !== y0 && /2 \/ /.test(nav2.c), '« › » mène à la page d’occurrence suivante', JSON.stringify({ y0, nav2 }));
  await page.evaluate(() => closePdfViewer());
  t(await page.evaluate(() => document.getElementById('pdfHl').hidden), 'la pilule s’éteint avec la visionneuse');
  /* Ouvert depuis sa RANGÉE (sans recherche) : ni surlignage ni pilule — on vient LIRE. La rangée
     de documents d'une FICHE vit dans la feuille « Consulter » (v4.25.3), pas dans le flux : on y
     va par le vrai bouton. */
  /* A367 : la liste des documents vit dans la carte « Références » de la page — « Documents · n » l'ouvre (la carte « Parcours » d'abord, repliée d'office). */
  /* Ici la fiche est en mode « Toute la fiche » : pas d'écran d'entrée, donc pas de lien « Documents » —
     la carte Références vit sous la fiche, on l'ouvre par sa tête. */
  await page.evaluate(async () => { const dl = document.querySelector('[data-prelink="docs"]');
    if (dl) { dl.click(); return; }
    const h = document.querySelector('[data-prefold="refs"]'); if (!h) throw new Error('ni lien « Documents » ni carte Références');
    if (h.getAttribute('aria-expanded') !== 'true') h.click(); });
  await page.waitForFunction(() => !!document.querySelector('[data-sf="refs"]:not(.closed) [data-att]'), null, { timeout: 8000 });
  await page.evaluate(() => { document.querySelector('[data-sf="refs"] [data-att]').click(); });
  await page.waitForFunction(() => document.getElementById('pdfModal').classList.contains('on'), null, { timeout: 20000 }).catch(() => {});
  await page.waitForTimeout(500);
  const lireSeul = await page.evaluate(() => ({
    on: document.getElementById('pdfModal').classList.contains('on'),
    hl: document.querySelectorAll('.pdf-hl').length, pill: document.getElementById('pdfHl').hidden }));
  t(lireSeul.on && lireSeul.hl === 0 && lireSeul.pill, 'ouvert depuis sa rangée : ni surlignage ni pilule (on vient lire)', JSON.stringify(lireSeul));
  await page.evaluate(() => closePdfViewer());
  // La feuille « Consulter » est restée dessous : on la ferme par son ✕ avant de sortir.
  await page.click('#hdrBack');
  await page.waitForFunction(() => document.body.classList.contains('view-home'));

  sec('résilience — réinitialiser l’index');
  await page.evaluate(() => closePdfViewer());
  /* Un enregistrement d'une AUTRE version (le cas du prochain `IX_V`) : il doit être JETÉ et le
     document redevenir indexable — jamais rester dans `attIx` sous forme de `null`, ce qui le
     rendrait invisible à la recherche ET non ré-indexable, en silence et pour toujours. */
  const apresVersion = await page.evaluate(async id => {
    const rec = await IDB.getIx(id);
    await IDB.putIx(Object.assign({}, rec, { v: rec.v + 1 }));
    attIx.clear();
    await ixLoadAll();
    const rangee = attIx.has(id);
    const pend = (await ixPending()).indexOf(id) >= 0;
    return { rangee, pend };
  }, attId);
  t(!apresVersion.rangee, 'un index d’une autre version n’est PAS gardé', JSON.stringify(apresVersion));
  t(apresVersion.pend, '… et le document redevient « à indexer » (état visible, geste possible)', JSON.stringify(apresVersion));

  /* RATTRAPAGE AUTOMATIQUE (v5.3.0, vécu sur la PWA de l'auteur) : un document présent mais non
     indexé se rattrape AU DÉMARRAGE, sans aucun clic. On recharge la page avec l'index encore
     absent (il vient d'être jeté ci-dessus) et l'on attend : `ixLoadAll` doit mettre en file. */
  await page.goto(URL_APP);
  await page.waitForFunction(() => typeof fiches !== 'undefined' && !!document.querySelector('.card-open'));
  await page.waitForFunction(id => typeof attIx !== 'undefined' && attIx.has(id), attId, { timeout: 30000 }).catch(() => {});
  t(await page.evaluate(id => attIx.has(id), attId),
    'un document non indexé se rattrape AU DÉMARRAGE, sans clic (auto-indexation)');

  // Réindexation globale : elle reconstruit réellement, et la recherche remarche après.
  await page.evaluate(() => ixResetAll());
  await page.waitForFunction(id => attIx.has(id), attId, { timeout: 30000 }).catch(() => {});
  t(await page.evaluate(id => attIx.has(id), attId), 'ixResetAll() reconstruit l’index');
  await remplir(page, '');
  await remplir(page, 'remplissage');
  await page.waitForTimeout(400);
  t(await page.evaluate(() => document.querySelectorAll('.doc-hit').length === 1),
    '… et la recherche retrouve le document après réindexation');

} catch (e) {
  t(false, 'exception : ' + (e && e.message));
} finally {
  console.log(`\n${ok}/${ok + ko} contrôles recherche-documents ${ko ? '— ' + ko + ' ÉCHEC(S)' : 'OK'}`);
  await browser.close();
  srv.close();
  process.exit(ko ? 1 : 0);
}
