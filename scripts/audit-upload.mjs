/* AUDIT — LES ENTRÉES DE FICHIER (v5.0.0, chantier « uploads »).
 *
 * POURQUOI CE HARNAIS EXISTE. Quatre chemins d'upload cohabitaient (import .json/.zip, document
 * PDF, image d'aide, image de référence) avec quatre niveaux de rigueur : le PDF vérifiait sa
 * signature, l'import vérifiait la sienne, les DEUX chemins d'image ne vérifiaient rien qu'un
 * `accept` — c'est-à-dire une INDICATION donnée au sélecteur de fichier, jamais une garantie —
 * et ils avaient déjà divergé (60 images maximum d'un côté, aucun plafond de l'autre).
 *
 * CE QU'IL MESURE, ET DANS QUEL ORDRE. D'abord la TABLE (`UP_KINDS`) : c'est elle qui rend
 * « chaque champ reste unique » exécutable, puisque l'`accept` affiché et la signature vérifiée
 * sortent de la même ligne et ne PEUVENT donc plus diverger. Ensuite les REFUS : un fichier
 * refusé en silence est pire qu'un fichier accepté à tort — on croit avoir joint quelque chose.
 * Enfin le GARDE GLOBAL : avant ce chantier, un fichier lâché à 3 px d'une zone faisait NAVIGUER
 * le navigateur vers ce fichier, donc disparaître l'écran d'édition en cours.
 *
 * ÉCRIT AVANT LES CORRECTIFS QU'IL COUVRE (protocole d'`audit-budget`, v5.0.0) : livré seul, il
 * est ROUGE. Un harnais écrit après coup mesure ce qu'on vient d'écrire, pas ce qu'on voulait
 * empêcher.
 *
 * ⚠ `new DataTransfer()` est le seul moyen de simuler un dépôt de fichier. Il existe sur Chromium
 * (moteur par défaut) et sur WebKit récent ; si le constructeur manquait, la sonde le DIT au lieu
 * de compter des contrôles verts sur un dépôt qui n'a jamais eu lieu.
 */
import { serveApp, moteur, NOM_MOTEUR, amorce } from './harness.mjs';

const { port, srv } = await serveApp();
const br = await moteur().launch();
const p = await br.newPage({ viewport: { width: 390, height: 900 } });
let ok = 0, ko = 0;
const t = (n, c, d) => { if (c) { ok++; console.log('  ✓ ' + n); } else { ko++; console.log('  ✗ ' + n + (d ? ' — ' + d : '')); } };
p.on('pageerror', e => { ko++; console.log('  ✗ ERREUR PAGE : ' + e.message); });
console.log(`\n═══ AUDIT UPLOADS — ${NOM_MOTEUR} ═══`);
await p.goto(`http://localhost:${port}/index.html`);
await amorce(p);

/* Fabriques d'octets, en contexte page. Chaque en-tête est la SIGNATURE RÉELLE du format —
   c'est tout l'objet de ce chantier : on ne croit ni l'extension ni le type déclaré. */
/* `var` et non `const` : les déclarations lexicales d'un eval direct restent dans la portée de
   l'eval — seules les `var` remontent dans la fonction appelante, et c'est là qu'on en a besoin. */
const FIXTURES = `
  var B=a=>new Uint8Array(a);
  var A=s=>[...s].map(c=>c.charCodeAt(0));
  var FX={
    pdf:  ()=>B([...A('%PDF-1.7'),10,37,37,69,79,70]),
    png:  ()=>B([0x89,0x50,0x4E,0x47,0x0D,0x0A,0x1A,0x0A,0,0,0,13]),
    jpeg: ()=>B([0xFF,0xD8,0xFF,0xE0,0,16,74,70,73,70]),
    heic: ()=>B([0,0,0,0x18,...A('ftypheic'),0,0,0,0]),
    svg:  ()=>B(A('<svg xmlns="http://www.w3.org/2000/svg"></svg>')),
    json: ()=>B(A('{"version":3,"fiches":[]}')),
    zip:  ()=>B([0x50,0x4B,3,4,20,0,0,0,0,0]),
    txt:  ()=>B(A('bonjour, ceci n est pas un format connu')),
  };
  var mk=(kind,nom,type)=>new File([FX[kind]()],nom,{type:type||''});
`;

/* Dépôt RÉEL : DragEvent + DataTransfer, sur la cible demandée. Rend ce que la page a montré
   (message visible + annonce lecteur d'écran) ET si le dépôt a été neutralisé — c'est cette
   dernière valeur qui dit qu'on ne navigue pas vers le fichier. */
const DROP = `
  var deposer = async function(sel,files){
    const el=sel==='body'?document.body:document.querySelector(sel);
    if(!el)return {err:'cible introuvable : '+sel};
    if(typeof DataTransfer!=='function')return {err:'DataTransfer indisponible sur ce moteur'};
    const dt=new DataTransfer();files.forEach(f=>dt.items.add(f));
    el.dispatchEvent(new DragEvent('dragenter',{dataTransfer:dt,bubbles:true,cancelable:true}));
    const ev=new DragEvent('drop',{dataTransfer:dt,bubbles:true,cancelable:true});
    el.dispatchEvent(ev);
    await new Promise(r=>setTimeout(r,320));
    const to=document.querySelector('.toast');
    return {neutralise:ev.defaultPrevented,
      msg:(to?to.textContent:'')||'',
      sr:(document.getElementById('srLive')||{}).textContent||''};
  };
`;

const dispo = await p.evaluate(() => typeof DataTransfer === 'function');
if (!dispo) { console.log(`  ! DataTransfer indisponible sur ${NOM_MOTEUR} — les dépôts ne peuvent pas être simulés.`); }

/* ══ 1. LA TABLE : une entrée = un accept + une signature + un plafond ══════════════════════ */
console.log('\n── la table fermée ──');
const table = await p.evaluate(() => {
  if (typeof UP_KINDS === 'undefined') return { absente: true };
  const ks = Object.keys(UP_KINDS);
  return { absente: false, kinds: ks,
    complets: ks.filter(k => { const K = UP_KINDS[k]; return K && K.accept && typeof K.sniff === 'function' && K.max > 0; }),
    accepts: ks.map(k => UP_KINDS[k].accept || '') };
});
t('UP_KINDS existe', !table.absente);
t('les trois natures sont déclarées (pdf · image · data)',
  !table.absente && ['pdf', 'image', 'data'].every(k => table.kinds.includes(k)), JSON.stringify(table.kinds));
t('chaque nature porte accept + sniff + plafond (ils ne peuvent pas diverger)',
  !table.absente && table.complets.length === table.kinds.length,
  table.absente ? '' : `${table.complets.length}/${table.kinds.length}`);
t('aucun accept fourre-tout « image/* » (le SVG y entrerait)',
  !table.absente && !table.accepts.some(a => /image\/\*|\*\/\*/.test(a)), JSON.stringify(table.accepts));

/* ══ 2. LES SIGNATURES : le CONTENU décide, jamais l'extension ══════════════════════════════ */
console.log('\n── les signatures ──');
const sig = await p.evaluate(async (fx) => {
  eval(fx);
  if (typeof acceptFile !== 'function') return { absente: true };
  const r = async (kind, f) => (await acceptFile(kind, f)).ok;
  return { absente: false,
    pdfOk:        await r('pdf',   mk('pdf', 'doc.pdf', 'application/pdf')),
    jsonEnPdf:    await r('pdf',   mk('json', 'piege.pdf', 'application/pdf')),
    pdfEnJson:    await r('data',  mk('pdf', 'piege.json', 'application/json')),
    pngEnPdf:     await r('pdf',   mk('png', 'piege.pdf', 'application/pdf')),
    jsonOk:       await r('data',  mk('json', 'export.json', 'application/json')),
    zipOk:        await r('data',  mk('zip', 'export.zip', 'application/zip')),
    txtEnJson:    await r('data',  mk('txt', 'notes.json', 'application/json')),
    pngOk:        await r('image', mk('png', 'schema.png', 'image/png')),
    jpegOk:       await r('image', mk('jpeg', 'photo.jpg', 'image/jpeg')),
    heicOk:       await r('image', mk('heic', 'IMG_0042.HEIC', 'image/heic')),
    svgRefuse:    await r('image', mk('svg', 'schema.svg', 'image/svg+xml')),
    pdfEnImage:   await r('image', mk('pdf', 'piege.png', 'image/png')) };
}, FIXTURES);
t('un vrai PDF passe', !sig.absente && sig.pdfOk === true);
t('un JSON renommé .pdf est refusé', !sig.absente && sig.jsonEnPdf === false);
t('une image renommée .pdf est refusée', !sig.absente && sig.pngEnPdf === false);
t('un PDF renommé .json est refusé', !sig.absente && sig.pdfEnJson === false);
t('un texte quelconque renommé .json est refusé', !sig.absente && sig.txtEnJson === false);
t('un vrai .json et un vrai .zip passent', !sig.absente && sig.jsonOk === true && sig.zipOk === true);
t('PNG et JPEG passent', !sig.absente && sig.pngOk === true && sig.jpegOk === true);
t('HEIC passe (photothèque iPhone — la cible principale)', !sig.absente && sig.heicOk === true);
t('SVG est refusé (seul format image à surface active)', !sig.absente && sig.svgRefuse === false);
t('un PDF renommé .png est refusé', !sig.absente && sig.pdfEnImage === false);

/* ══ 3. LES PLAFONDS ════════════════════════════════════════════════════════════════════════ */
console.log('\n── les plafonds ──');
const plaf = await p.evaluate(async () => {
  if (typeof acceptFile !== 'function' || typeof UP_KINDS === 'undefined') return { absente: true };
  // Fichier surdimensionné SANS l'allouer : un Blob de taille déclarée suffit, la porte lit
  // `file.size` AVANT de lire le moindre octet — et c'est exactement ce qu'on veut vérifier.
  const gros = (kind, n) => { const b = new Blob([new Uint8Array(8)]);
    Object.defineProperty(b, 'size', { value: n }); Object.defineProperty(b, 'name', { value: 'gros' });
    return b; };
  const r = async (k) => (await acceptFile(k, gros(k, UP_KINDS[k].max + 1))).ok;
  return { absente: false, pdf: await r('pdf'), image: await r('image'), data: await r('data'),
    maxImport: UP_KINDS.data.max, maxImg: UP_KINDS.image.max };
});
t('un import au-delà du plafond est refusé (aucun plafond avant ce chantier)',
  !plaf.absente && plaf.data === false);
t('une image au-delà du plafond est refusée (aucun plafond avant ce chantier)',
  !plaf.absente && plaf.image === false);
t('un PDF au-delà du plafond est refusé', !plaf.absente && plaf.pdf === false);

/* ══ 4. LE GARDE GLOBAL : un dépôt hors zone ne fait pas naviguer ═══════════════════════════
   Le PDF déposé ici est aussi ce qui CONSTRUIT le cas des contrôles suivants : la section
   « Documents » est masquée tant qu'elle est vide (v4.76.0), donc sa zone de dépôt n'existe pas
   encore. On la fait naître par un vrai geste plutôt qu'en fabriquant l'état à la main. */
console.log('\n── le garde global ──');
await p.evaluate(async () => { newFiche(); render(); await new Promise(r => setTimeout(r, 350)); });
const hors = await p.evaluate(async (src) => {
  eval(src.fx); eval(src.drop);
  const avant = location.href;
  const r = await deposer('body', [mk('pdf', 'perdu.pdf', 'application/pdf')]);
  await new Promise(r2 => setTimeout(r2, 400));
  return { ...r, memeUrl: location.href === avant,
    docs: ((state.draft || {}).docs || []).length,
    zone: !!document.querySelector('.up-drop[data-upkind="pdf"]') };
}, { fx: FIXTURES, drop: DROP });
t('un fichier déposé hors zone est NEUTRALISÉ (sans quoi le navigateur y navigue)',
  hors.neutralise === true, JSON.stringify(hors));
t('… et l’écran ne change pas d’URL', hors.memeUrl === true);
t('… et le PDF est ROUTÉ vers les documents (le contenu décide, pas la zone visée)',
  hors.docs === 1, JSON.stringify(hors));

/* ══ 5. LE REFUS SE DIT ═════════════════════════════════════════════════════════════════════ */
console.log('\n── un refus s’annonce ──');
t('la zone de dépôt PDF existe maintenant (cas construit par un vrai geste)', hors.zone === true);
const refus = await p.evaluate(async (src) => {
  eval(src.fx); eval(src.drop);
  return await deposer('.up-drop[data-upkind="pdf"]', [mk('json', 'export.json', 'application/json')]);
}, { fx: FIXTURES, drop: DROP });
t('déposer un .json sur la zone PDF : le dépôt est neutralisé', refus.neutralise === true, JSON.stringify(refus));
t('… et un message le DIT', !refus.err && /[A-Za-zÀ-ÿ]/.test(refus.msg || refus.sr), JSON.stringify(refus));
t('… le message nomme ce qui est attendu ici', !refus.err && /PDF/i.test(refus.msg + ' ' + refus.sr), JSON.stringify(refus));
t('… et rien n’a été ajouté', await p.evaluate(() => ((state.draft || {}).docs || []).length) === 1);

/* ══ 6. DÉPÔT MULTIPLE : ce qui est ignoré se dit ═══════════════════════════════════════════ */
console.log('\n── dépôt multiple ──');
const multi = await p.evaluate(async (src) => {
  eval(src.fx); eval(src.drop);
  const r = await deposer('.up-drop[data-upkind="pdf"]', [mk('pdf', 'a.pdf', 'application/pdf'),
                                                          mk('json', 'b.pdf', 'application/pdf'),
                                                          mk('png', 'c.pdf', 'application/pdf')]);
  await new Promise(r2 => setTimeout(r2, 400));
  return { ...r, docs: ((state.draft || {}).docs || []).length };
}, { fx: FIXTURES, drop: DROP });
t('3 fichiers dont 2 refusés : le compte des ignorés est annoncé',
  !multi.err && /2\b/.test(multi.msg + ' ' + multi.sr), JSON.stringify(multi.msg));
t('… et le seul valide est bien ajouté (jamais « files[0] » en silence)',
  multi.docs === 2, JSON.stringify(multi.docs));

/* ══ 7. LES SURFACES ════════════════════════════════════════════════════════════════════════ */
console.log('\n── les surfaces ──');
await p.setViewportSize({ width: 320, height: 640 });
await p.evaluate(async () => { render(); await new Promise(r => setTimeout(r, 400)); });
const surf = await p.evaluate(() => {
  const zs = [...document.querySelectorAll('.up-drop')];
  const box = zs.map(z => { const r = z.getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height) }; });
  return { n: zs.length, box,
    deborde: zs.some(z => { const r = z.getBoundingClientRect(); return r.right > innerWidth + 0.5 || r.left < -0.5; }) };
});
t('au moins une zone de dépôt est visible en permanence dans l’éditeur', surf.n > 0, JSON.stringify(surf));
t('cible ≥ 44 px à 320 px', surf.n > 0 && surf.box.every(b => b.h >= 44), JSON.stringify(surf.box));
t('aucune zone ne déborde à 320 px', surf.n > 0 && surf.deborde === false, JSON.stringify(surf.box));

/* ══ 8. ACCESSIBILITÉ DU COMPOSANT ══════════════════════════════════════════════════════════
   Une surface NEUVE n'est dans le champ d'aucune sonde existante tant que personne ne l'y met —
   « un défaut hors scope n'est pas un défaut absent » (leçon v4.75.0, où trois poignées ⠿ ont
   vécu sous le seuil AA pendant des versions faute d'être dans un périmètre mesuré). Le harnais
   qui possède le composant mesure donc son contraste, dans les DEUX thèmes. */
console.log('\n── accessibilité du composant ──');
await p.setViewportSize({ width: 390, height: 900 });
const CONTRASTE = `
  var lin=c=>{c/=255;return c<=0.03928?c/12.92:Math.pow((c+0.055)/1.055,2.4);};
  var rgb=s=>{const m=String(s).match(/[\\d.]+/g)||[0,0,0];return [+m[0],+m[1],+m[2],m[3]===undefined?1:+m[3]];};
  var lum=c=>0.2126*lin(c[0])+0.7152*lin(c[1])+0.0722*lin(c[2]);
  var ratio=(a,b)=>{const l1=lum(a),l2=lum(b);return (Math.max(l1,l2)+0.05)/(Math.min(l1,l2)+0.05);};
  // Fond EFFECTIF : la zone est en background:none, on remonte jusqu'au premier fond opaque.
  var fondDe=function(el){let n=el;while(n&&n!==document.documentElement){
    const c=rgb(getComputedStyle(n).backgroundColor);if(c[3]>0.99)return c;n=n.parentElement;}
    return rgb(getComputedStyle(document.body).backgroundColor);};
  var mesure=function(){const z=document.querySelector('.up-drop');if(!z)return null;
    const f=fondDe(z),t=z.querySelector('.up-t'),d=z.querySelector('.up-d');
    return {titre:+ratio(rgb(getComputedStyle(t).color),f).toFixed(2),
            sous:+ratio(rgb(getComputedStyle(d).color),f).toFixed(2),
            corpsSous:parseFloat(getComputedStyle(d).fontSize)};};
`;
for (const theme of ['light', 'dark']) {
  const c = await p.evaluate(async (src) => {
    eval(src.ct);
    document.documentElement.setAttribute('data-theme', src.th);
    await new Promise(r => setTimeout(r, 120));
    return mesure();
  }, { ct: CONTRASTE, th: theme });
  t(`[${theme}] libellé de la zone ≥ 4.5:1`, !!c && c.titre >= 4.5, c ? String(c.titre) : 'zone absente');
  t(`[${theme}] sous-ligne « ce qui est accepté » ≥ 4.5:1`, !!c && c.sous >= 4.5, c ? String(c.sous) : 'zone absente');
  t(`[${theme}] sous-ligne au-dessus du plancher de 11 px`, !!c && c.corpsSous >= 11, c ? String(c.corpsSous) : '');
}
await p.evaluate(() => document.documentElement.setAttribute('data-theme', 'light'));
/* Anneau de focus sous de VRAIES touches Tab : `.focus()` programmatique ne déclenche pas
   `:focus-visible` et produit des faux positifs en série (leçon d'`audit-a11y`).
   ⚠ AUTO-DIAGNOSTIC PLUTÔT QU'UNE LISTE DE MOTEURS : Safari ne tabule pas vers les boutons tant
   que « Navigation au clavier complète » est désactivée (défaut système), donc la MESURE est
   impossible sur WebKit — ce n'est pas un défaut de l'application. On le constate en regardant
   si la tabulation atteint le moindre bouton SUR CET ÉCRAN ; si elle n'en atteint aucun, on
   avertit au lieu d'échouer. Un allowlist par nom de moteur se périmerait en silence. */
const foc = await (async () => {
  await p.evaluate(() => { window.scrollTo(0, 0); if (document.body.focus) document.body.focus(); });
  let vuBouton = false;
  for (let i = 0; i < 400; i++) {
    await p.keyboard.press('Tab');
    const r = await p.evaluate(() => {
      const a = document.activeElement;
      if (!a || !a.tagName) return null;
      const btn = a.tagName === 'BUTTON';
      if (!a.classList || !a.classList.contains('up-drop')) return { autre: btn };
      const cs = getComputedStyle(a);
      return { trouve: true, clavier: btn,
        outline: cs.outlineStyle !== 'none' && parseFloat(cs.outlineWidth) > 0 };
    });
    if (r && r.autre) vuBouton = true;
    if (r && r.trouve) return r;
  }
  return { trouve: false, vuBouton };
})();
if (!foc.trouve && !foc.vuBouton) {
  console.log(`  ! focus clavier non mesurable sur ${NOM_MOTEUR} : la tabulation n’atteint AUCUN bouton`
    + ' de cet écran (comportement Safari par défaut), le contrôle est ignoré et non compté.');
} else {
  t('la zone est atteignable au clavier et c’est un vrai <button>', foc.clavier === true, JSON.stringify(foc));
  t('… avec un anneau de focus visible', foc.outline === true, JSON.stringify(foc));
}

/* ══ 9. LE GLISSER D'UNE POIGNÉE ⠿ N'EST PAS UN DÉPÔT DE FICHIER ════════════════════════════
   MK5-b annule déjà `dragstart` sur les poignées pour amorcer « prendre / poser ». Deux gestes
   qui se ressemblent ne doivent pas se déclencher l'un l'autre. */
console.log('\n── le glisser interne reste interne ──');
const poignee = await p.evaluate(async () => {
  const h = document.querySelector('[data-grab],[data-lgrab]');
  if (!h) return { absente: true };
  const dt = typeof DataTransfer === 'function' ? new DataTransfer() : null;
  if (dt) dt.setData('text/plain', 'x');
  h.dispatchEvent(new DragEvent('dragenter', { dataTransfer: dt, bubbles: true, cancelable: true }));
  await new Promise(r => setTimeout(r, 120));
  const ov = document.getElementById('upDrag');
  return { absente: false, overlayOuvert: !!(ov && ov.classList.contains('on')) };
});
t('glisser une poignée ⠿ n’ouvre pas la fenêtre de dépôt',
  poignee.absente || poignee.overlayOuvert === false, JSON.stringify(poignee));

// ════ A689-A690 · un document appartient à un seul espace (aller-retour IndexedDB réel) ════
/* Le réseau est BOUCHÉ dans la page (`storageReq`, `Sync.schedule`) : pas d'instance Supabase ici, et ce
   qu'on prouve est la DÉCISION — quel chemin est téléversé, lequel est mis en file de suppression — sur de
   vrais enregistrements IndexedDB. Aucune pause : chaque étape attend sa propre promesse. */
console.log('\n══ A689-A690 · un document appartient à un seul espace ══');
{
  const q = await br.newPage({ viewport: { width: 390, height: 900 } });
  await q.goto(`http://localhost:${port}/index.html`);
  await amorce(q);
  const r = await q.evaluate(async () => {
    if (typeof attPlan !== 'function' || !supportsAttachments()) return { absente: true };
    const pdf = n => { const u = new Uint8Array(64 + n); u.set([0x25, 0x50, 0x44, 0x46, 0x2d]); return u.buffer; };
    Auth.session = { access_token: 'x', refresh_token: 'y', expires_at: Date.now() / 1000 + 3600, user: { id: 'u1', email: 'moi@test.local' } };
    myLibraries = [{ id: 'libA', name: 'A', role: 'editor' }, { id: 'libR', name: 'R', role: 'viewer' }];
    const envois = [], suppr = [];
    storageReq = async (m, path) => { if (m === 'POST') { envois.push(path); return {}; } if (m === 'DELETE') { suppr.push(path); return {}; } throw Object.assign(new Error('404'), { status: 404 }); };
    Sync.schedule = () => {}; Sync.full = async () => {};
    setAttDelQueue([]);
    const aide = async (id, lib, docs) => { const f = blankFiche(); f.id = id; f.title = id; f.library = lib; f.docs = docs.map(d => ({ id: d, name: d + '.pdf', size: 69 })); f.dirty = false; fiches.push(f); await Data.put(f); return f; };
    const bin = (id, path, extra) => IDB.putAtt(Object.assign({ id, buf: pdf(5), size: 69, type: 'application/pdf', createdAt: 1, dirty: 0, remotePath: path }, extra || {}));
    const o = {};
    // 1. Dupliquer dans Perso, depuis une bibliothèque.
    const L1 = await aide('L1', 'libA', ['d1']); await bin('d1', 'l/libA/d1.pdf');
    await dupToPerso('f', L1);
    const cp = fiches.find(x => /\(copie\)/.test(x.title) && !x.library);
    const cid = cp && cp.docs[0] && cp.docs[0].id, crec = cid ? await IDB.getAtt(cid) : null, orec = await IDB.getAtt('d1');
    o.dup = { idNeuf: !!cid && cid !== 'd1', copie: !!crec && crec.scope === '' && crec.dirty === 1 && crec.remotePath === null && (await attBuf(crec)).byteLength === 69,
      origine: !!orec && orec.remotePath === 'l/libA/d1.pdf' && orec.dirty === 0, citeOrig: L1.docs[0].id === 'd1' };
    await Sync._syncAttachments();
    o.dupSync = { envois: envois.slice(), file: attDelQueue().slice() };
    // 2. L'attaque de l'audit : une ligne de bibliothèque (que je peux éditer) cite mon PDF personnel.
    const P = await aide('P', null, ['p1']); await bin('p1', 'u/u1/p1.pdf');
    await aide('X', 'libA', ['p1']);
    envois.length = 0;
    await Sync._syncAttachments();
    o.att1 = { envois: envois.slice(), file: attDelQueue().slice(), rec: (await IDB.getAtt('p1')).remotePath };
    P.deletedAt = Date.now(); await Data.put(P);          // mon aide personnelle supprimée : seule la ligne étrangère le cite
    await Sync._syncAttachments();
    const p1 = await IDB.getAtt('p1');
    o.att2 = { envois: envois.slice(), file: attDelQueue().slice(), etiq: p1.remotePath, binaire: !!(await attBuf(p1)) };
    // 3. MON déplacement Perso → bibliothèque : le binaire suit, l'ancien chemin part après.
    const M = await aide('M', null, ['m1']); await bin('m1', 'u/u1/m1.pdf');
    await entsMoveLib([{ kind: 'f', o: M }], 'libA');
    const m1 = await IDB.getAtt('m1'); o.dep = { scope: m1.scope, dirty: m1.dirty, id: M.docs[0].id };
    envois.length = 0; await Sync._syncAttachments();
    o.depSync = { envois: envois.slice(), file: attDelQueue().slice(), rec: (await IDB.getAtt('m1')).remotePath };
    // 4. Déplacer UN des deux éléments qui citent le même document : il emporte un exemplaire.
    const N1 = await aide('N1', null, ['n1']); await aide('N2', null, ['n1']); await bin('n1', 'u/u1/n1.pdf');
    await entsMoveLib([{ kind: 'f', o: N1 }], 'libA');
    const nid = N1.docs[0].id, nrec = await IDB.getAtt(nid), n1 = await IDB.getAtt('n1');
    o.cop = { idNeuf: nid !== 'n1', scope: nrec && nrec.scope, reste: n1.remotePath === 'u/u1/n1.pdf' && n1.dirty === 0 && typeof n1.scope !== 'string' };
    // 5. Simple lecteur d'une bibliothèque : jamais de téléversement, jamais de suppression chez elle.
    await aide('R', 'libR', ['r1']); await bin('r1', null, { dirty: 1 });
    envois.length = 0; await Sync._syncAttachments();
    o.lect = { envois: envois.filter(x => /libR/.test(x)), file: attDelQueue().filter(x => /libR/.test(x)) };
    // 6. Réparation de l'existant : binaire absent → on attend ; présent → l'élément Perso reçoit le sien.
    const Q1 = await aide('Q1', 'libA', ['q1']), Q2 = await aide('Q2', null, ['q1']);
    try { localStorage.removeItem(spaceKey('ac-att-split')); } catch (e) {}
    const r0 = await attRepairShared();
    o.rep0 = { ok: r0, drapeau: localStorage.getItem(spaceKey('ac-att-split')), cite: Q2.docs[0].id };
    await bin('q1', 'l/libA/q1.pdf');
    const r1 = await attRepairShared();
    const qid = Q2.docs[0].id, qrec = await IDB.getAtt(qid), q1 = await IDB.getAtt('q1');
    const disque = (await Data.getAll()).find(x => x.id === 'Q2');
    o.rep1 = { ok: r1, drapeau: localStorage.getItem(spaceKey('ac-att-split')), idNeuf: qid !== 'q1', copie: !!qrec && qrec.scope === '' && qrec.dirty === 1,
      origine: Q1.docs[0].id === 'q1' && !!q1 && q1.remotePath === 'l/libA/q1.pdf', disque: !!disque && disque.docs[0].id === qid && disque.dirty === true,
      perso: (await IDB.getAtt('p1')).remotePath };
    o.suppr = suppr.slice();
    return o;
  });
  if (r.absente) t('A689 : les fonctions existent et le stockage de documents est disponible', false, 'absent');
  else {
    t('A689 · « Dupliquer dans Perso » : la copie cite un document d’id NEUF, l’original garde le sien', r.dup.idNeuf && r.dup.citeOrig, JSON.stringify(r.dup));
    t('A689 · … le binaire est recopié (espace Perso, à envoyer), celui de la bibliothèque n’est pas touché', r.dup.copie && r.dup.origine, JSON.stringify(r.dup));
    t('A689 · … la synchro n’envoie QUE la copie, dans mon Perso, et ne supprime rien',
      r.dupSync.envois.length === 1 && /^u\/u1\//.test(r.dupSync.envois[0]) && r.dupSync.file.length === 0, JSON.stringify(r.dupSync));
    t('A689 · une ligne de bibliothèque qui cite mon PDF personnel : RIEN n’est téléversé, rien n’est supprimé, il reste chez moi',
      r.att1.envois.length === 0 && r.att1.file.length === 0 && r.att1.rec === 'u/u1/p1.pdf', JSON.stringify(r.att1));
    t('A689 · … même mon aide personnelle supprimée : réétiqueté, JAMAIS téléversé ; le binaire local est gardé',
      r.att2.envois.length === 0 && r.att2.file.length === 0 && r.att2.etiq === 'l/libA/p1.pdf' && r.att2.binaire, JSON.stringify(r.att2));
    t('A689 · MON déplacement Perso → bibliothèque : le binaire change d’espace, l’id est gardé', r.dep.scope === 'libA' && r.dep.dirty === 1 && r.dep.id === 'm1', JSON.stringify(r.dep));
    t('A689 · … téléversé au nouveau chemin, PUIS l’ancien mis en file de suppression',
      r.depSync.envois.includes('l/libA/m1.pdf') && r.depSync.file.includes('u/u1/m1.pdf') && r.depSync.rec === 'l/libA/m1.pdf', JSON.stringify(r.depSync));
    t('A689 · déplacer un élément dont le document reste cité là d’où il part : il emporte SON exemplaire', r.cop.idNeuf && r.cop.scope === 'libA' && r.cop.reste, JSON.stringify(r.cop));
    t('A689 · simple lecteur : aucun téléversement ni suppression dans la bibliothèque', r.lect.envois.length === 0 && r.lect.file.length === 0, JSON.stringify(r.lect));
    t('A690 · binaire absent de l’appareil : la réparation attend, le drapeau n’est pas posé', r.rep0.ok === false && !r.rep0.drapeau && r.rep0.cite === 'q1', JSON.stringify(r.rep0));
    t('A690 · binaire présent : l’élément Perso reçoit son exemplaire, l’original reste à la bibliothèque, drapeau posé',
      r.rep1.ok === true && r.rep1.drapeau === '1' && r.rep1.idNeuf && r.rep1.copie && r.rep1.origine, JSON.stringify(r.rep1));
    t('A690 · … l’élément réparé est enregistré « à envoyer » ; un binaire dont le foyer est mon Perso n’est pas copié', r.rep1.disque && r.rep1.perso === 'l/libA/p1.pdf', JSON.stringify(r.rep1));
    t('A690 · aucune suppression distante n’a été émise par la réparation', Array.isArray(r.suppr) && r.suppr.every(x => !/q1/.test(x)), JSON.stringify(r.suppr));
  }
  await q.close();
}


await p.close(); await br.close(); srv.close();
console.log(`\n${ok}/${ok + ko} OK${ko ? ` — ${ko} ÉCHEC(S)` : ''}`);
process.exit(ko ? 1 : 0);
