/* AUDIT TRANSVERSE (lot 7) — WCAG 2.2 AA + règles projet, sur TOUTES les surfaces ajoutées
   par les lots 1 à 6. Tout est mesuré sur les styles CALCULÉS, dans les deux thèmes.
     • plancher typographique 11px (règle projet, plus stricte que WCAG)
     • contraste : texte >= 4.5:1 (>= 3:1 si "grand texte"), composants/bordures >= 3:1
     • cibles : >= 44px en mode crise (règle projet), >= 24px partout (WCAG 2.5.8)
     • focus visible au CLAVIER (parcours Tab réel, pas un .focus() programmatique)
     • règles projet : jamais --soft en couleur de texte, « hors chemin » jamais par opacité seule
*/
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { extname } from 'node:path';
import { chromium } from 'playwright';

const ROOT = decodeURIComponent(new URL('../', import.meta.url).pathname);
const T = { '.html':'text/html','.js':'text/javascript','.json':'application/json',
  '.webmanifest':'application/manifest+json','.png':'image/png','.svg':'image/svg+xml','.ico':'image/x-icon' };
const srv = createServer(async (q,r)=>{ try{ let p=decodeURIComponent(q.url.split('?')[0]); if(p==='/')p='/index.html';
  const b=await readFile(ROOT+p.replace(/^\/+/,'')); r.writeHead(200,{'content-type':T[extname(p)]||'application/octet-stream'}); r.end(b);
} catch { r.writeHead(404); r.end('nf'); } });
const port = await new Promise(r=>srv.listen(0,()=>r(srv.address().port)));

const AUDIT = `(() => {
  const px=v=>parseFloat(v)||0;
  const parse=c=>{const m=String(c).match(/rgba?\\(([^)]+)\\)/);if(!m)return null;
    const p=m[1].split(',').map(x=>parseFloat(x));return {r:p[0],g:p[1],b:p[2],a:p.length>3?p[3]:1};};
  const over=(f,b)=>({r:f.r*f.a+b.r*(1-f.a),g:f.g*f.a+b.g*(1-f.a),b:f.b*f.a+b.b*(1-f.a),a:1});
  function bgOf(el){
    let e=el,acc=null;
    while(e&&e.nodeType===1){
      const c=parse(getComputedStyle(e).backgroundColor);
      if(c&&c.a>0){ acc=acc?over(acc,c):c; if(acc.a>=1||c.a>=1) return acc.a>=1?acc:over(acc,{r:255,g:255,b:255,a:1}); }
      e=e.parentElement;
    }
    const body=parse(getComputedStyle(document.body).backgroundColor)||{r:255,g:255,b:255,a:1};
    return acc?over(acc,body):body;
  }
  const lin=v=>{v/=255;return v<=0.03928?v/12.92:Math.pow((v+0.055)/1.055,2.4);};
  const lum=c=>0.2126*lin(c.r)+0.7152*lin(c.g)+0.0722*lin(c.b);
  const ratio=(a,b)=>{const l1=lum(a),l2=lum(b);const hi=Math.max(l1,l2),lo=Math.min(l1,l2);return (hi+0.05)/(lo+0.05);};
  const visible=el=>{const cs=getComputedStyle(el);
    if(cs.display==='none'||cs.visibility==='hidden'||px(cs.opacity)===0)return false;
    const r=el.getBoundingClientRect();return r.width>0&&r.height>0;};
  const ownText=el=>[...el.childNodes].some(n=>n.nodeType===3&&n.textContent.trim().length);

  const out={typo:[],contrast:[],targets:[],soft:[],misc:[]};
  const SCOPE='#crisisBand,#hdrCrisis,#crisisDock,#planModal,#refModal,.read-side,.annex-row,.cards,.list-edit,.pos-more';
  const roots=[...document.querySelectorAll(SCOPE)].filter(visible);
  const seen=new Set();
  roots.forEach(root=>{
    [root,...root.querySelectorAll('*')].forEach(el=>{
      if(seen.has(el)||!visible(el))return;seen.add(el);
      const cs=getComputedStyle(el);
      const fs=px(cs.fontSize);
      if(ownText(el)&&el.textContent.trim()){
        // plancher typographique (règle projet)
        if(fs&&fs<11) out.typo.push({sel:el.className||el.tagName,px:fs,txt:el.textContent.trim().slice(0,28)});
        // contraste du texte
        const fg=parse(cs.color); if(fg){
          const eff=fg.a<1?over(fg,bgOf(el)):fg;
          const rr=ratio(eff,bgOf(el));
          const big=fs>=24||(fs>=18.66&&px(cs.fontWeight)>=700);
          const need=big?3:4.5;
          if(rr<need-0.01) out.contrast.push({sel:el.className||el.tagName,px:fs,ratio:+rr.toFixed(2),need,txt:el.textContent.trim().slice(0,28)});
        }
        // règle projet : --soft est DÉCORATIF, jamais une couleur de texte
        const soft=getComputedStyle(document.documentElement).getPropertyValue('--soft').trim();
        if(soft){const s=parse(soft)||null;const f2=parse(cs.color);
          if(s&&f2&&Math.abs(s.r-f2.r)<2&&Math.abs(s.g-f2.g)<2&&Math.abs(s.b-f2.b)<2)
            out.soft.push({sel:el.className||el.tagName,txt:el.textContent.trim().slice(0,28)});}
      }
      // cibles interactives
      if(el.matches('button,[role="button"],a[href],summary,input,select,[tabindex="0"]')){
        const r=el.getBoundingClientRect();
        const cs2=getComputedStyle(el);
        const halo=cs2.position==='relative'?8:0;   // ::after inset:-4px du chrome
        const h=Math.round(r.height+halo),w=Math.round(r.width+halo);
        const crisis=document.body.classList.contains('view-read');
        const need=crisis?44:24;
        if(h<need||w<24) out.targets.push({sel:el.className||el.tagName,w,h,need,txt:(el.textContent||'').trim().slice(0,24)});
      }
    });
  });
  // « hors chemin » : jamais signalé par la seule opacité (règle projet + WCAG 1.4.1)
  document.querySelectorAll('.rail-lad .pl-line.off').forEach(el=>{
    const o=px(getComputedStyle(el).opacity);
    if(o<1) out.misc.push({sel:'.rail-lad .pl-line.off',pb:'opacité '+o+' — hors chemin doit être en encre + mention'});
  });
  return out;
})()`;

const browser = await chromium.launch();
const errs=[]; let fails=0, checks=0;
const report=(label,arr,fmt)=>{ checks++; if(!arr.length){return;} fails++;
  console.log('  ✗ '+label);
  arr.slice(0,6).forEach(x=>console.log('      '+fmt(x)));
  if(arr.length>6)console.log('      … +'+(arr.length-6)+' autres'); };

// ---- surfaces à auditer -------------------------------------------------
const SURFACES = [
  { nom:'bibliothèque',        w:1100, prep:null },
  { nom:'lecture étroite',     w:390,  prep:'read' },
  { nom:'lecture + rail',      w:1280, prep:'read' },
  { nom:'feuille Plan',        w:1280, prep:'plan' },
  { nom:'feuille Consulter',   w:1280, prep:'ref'  },
  { nom:'éditeur',             w:1100, prep:'edit' },
];

for (const theme of ['light','dark']) {
  console.log('\n══════ THÈME '+(theme==='dark'?'SOMBRE':'CLAIR')+' ══════');
  for (const S of SURFACES) {
    const page = await browser.newPage({ viewport:{width:S.w,height:900}, colorScheme:theme });
    page.on('pageerror',e=>errs.push(`${S.nom}/${theme}: ${e.message}`));
    page.on('console',m=>{ if(m.type()==='error') errs.push(`${S.nom}/${theme}: ${m.text()}`); });
    await page.goto(`http://localhost:${port}/index.html`);
    await page.waitForFunction(()=>!document.querySelector('.boot-load'),null,{timeout:10000});
    await page.evaluate(async(kind)=>{
      const w=[...document.querySelectorAll('button')].find(b=>/Commencer/.test(b.textContent)); if(w)w.click();
      await new Promise(r=>setTimeout(r,120));
      const s=[...document.querySelectorAll('button')].find(b=>b.textContent.includes("fiches d'exemple")); if(s)s.click();
      await new Promise(r=>setTimeout(r,320));
      const a=[...document.querySelectorAll('button')].find(b=>b.textContent.trim()==='Toutes'); if(a)a.click();
      if(!kind)return;
      const c=[...document.querySelectorAll('.card-open')].find(x=>/Arrêt cardiaque/.test(x.textContent));
      const id=c.dataset.open;
      const f=fiches.find(x=>x.id===id);
      f.posology=['△ **ADRÉNALINE — IV** : 1 mg / 3–5 min','**Remplissage** : cristalloïdes','**O₂** : haut débit','**Amiodarone** : 300 mg'];
      f.references=['Réanimation — recommandations 2023.'];
      if(kind==='edit'){openEdit(id);await new Promise(r=>setTimeout(r,350));return;}
      c.click();
      document.getElementById('sessStart').click();
      await new Promise(r=>setTimeout(r,300));
      if(kind==='plan'){document.getElementById('planBtn').click();await new Promise(r=>setTimeout(r,300));}
      if(kind==='ref'){const rb=document.getElementById('refBtn');if(rb)rb.click();await new Promise(r=>setTimeout(r,300));}
    }, S.prep);
    await page.waitForTimeout(250);

    const res = await page.evaluate(AUDIT);
    console.log(`\n── ${S.nom} (${S.w}px)`);
    const before=fails;
    report('typo < 11px', res.typo, x=>`${x.px}px · ${x.sel} · « ${x.txt} »`);
    report('contraste insuffisant', res.contrast, x=>`${x.ratio}:1 (seuil ${x.need}) · ${x.px}px · ${x.sel} · « ${x.txt} »`);
    report('cible trop petite', res.targets, x=>`${x.w}×${x.h} (seuil ${x.need}) · ${x.sel} · « ${x.txt} »`);
    report('--soft utilisé comme couleur de TEXTE', res.soft, x=>`${x.sel} · « ${x.txt} »`);
    report('règle projet', res.misc, x=>`${x.sel} — ${x.pb}`);

    // ---- focus visible : VRAIES touches Tab (`:focus-visible` ne s'applique qu'au clavier —
    //      un .focus() programmatique produisait des faux positifs). ------------------------
    const nom=el=>el;
    await page.evaluate(()=>{document.body.focus?.();});
    const badFocus=[];const vus=new Set();
    for(let i=0;i<60;i++){
      await page.keyboard.press('Tab');
      const info=await page.evaluate(()=>{
        const el=document.activeElement;
        if(!el||el===document.body)return null;
        const cs=getComputedStyle(el);
        const outl=e=>{const c=getComputedStyle(e);
          return c.outlineStyle!=='none'&&(parseFloat(c.outlineWidth)||0)>0;};
        // L'anneau peut être porté par un ANCÊTRE (motif .card:has(.card-open:focus-visible) :
        // le bouton pose outline:none, la CARTE porte l'anneau — 3 niveaux au-dessus).
        // Sur un ancêtre on n'accepte QUE l'outline : son box-shadow est en général une simple
        // élévation permanente, qui masquerait un vrai défaut.
        const cs0=getComputedStyle(el);
        let ring3=outl(el)||(cs0.boxShadow&&cs0.boxShadow!=='none');
        let a=el.parentElement;for(let k=0;k<4&&a&&!ring3;k++,a=a.parentElement){if(outl(a))ring3=true;}
        const ow=parseFloat(cs.outlineWidth)||0, os=cs.outlineStyle, sh=cs.boxShadow;
        const cls=(typeof el.className==='string'?el.className:(el.getAttribute('class')||''))||el.tagName;
        const key=cls+'|'+(el.textContent||'').trim().slice(0,20);
        return {key,cls,
          txt:((el.textContent||el.getAttribute('aria-label')||'').trim().slice(0,26)),
          vis:ring3};
      });
      if(!info)break;
      if(vus.has(info.key))break; vus.add(info.key);
      if(!info.vis)badFocus.push(info.cls+' | '+info.txt);
    }
    checks++;
    if(badFocus.length){fails++;
      console.log(`  ✗ focus NON visible au clavier (${badFocus.length}/${vus.size})`);
      [...new Set(badFocus)].slice(0,6).forEach(x=>console.log('      '+x));
    }
    if(fails===before)console.log('  ✓ conforme');
    await page.close();
  }
}
await browser.close(); srv.close();
if(errs.length){console.log('\nErreurs page :');[...new Set(errs)].forEach(e=>console.log('  '+e));}
console.log(`\n${checks-fails}/${checks} contrôles OK${fails?` — ${fails} ÉCHEC(S)`:''}${errs.length?` — ${errs.length} erreur(s)`:''}`);
process.exit(fails||errs.length?1:0);
