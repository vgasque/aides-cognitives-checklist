// Moteur d'expressions régulières natif (JSRegExp) contre V8 : les motifs sont les LITTÉRAUX de la
// PWA (recopiés tels quels), plus des motifs de garde (alternance, captures remises à zéro, /i,
// lookahead, quantificateurs paresseux). Chaque entrée joue exec / replace / split / matchAll.
const P = [
  /^```/, /^\s*$/, /^\s*\|.*\|\s*$/, /^\s*\|(?:\s*:?-{1,}:?\s*\|)+\s*$/, /^(#{1,3})\s+(.*)$/, /^(---+|\*\*\*+)\s*$/,
  /^!\[([^\]]{0,300})\]\(img:([A-Za-z0-9_-]{1,64})\)\s*$/, /^>\s?(.*)$/, /^\s{2,}(?:[-*]\s+|(\d{1,3})[.)]\s+)(.*)$/,
  /^[-*]\s+(.*)$/, /^\d{1,3}[.)]\s+(.*)$/, /^\[( |x|X)\](?:\s+|$)/, /^\s*\[!\s*([A-Za-zÀ-ÿ]{2,12})\s*\]\s*(.*)$/,
  /^\s*(⚠️|⚠|△|ℹ️|ℹ|✓|✔)\s*(.*)$/, /\*\*([^*\n]+)\*\*/g, /(^|[^*])\*([^*\n]+)\*(?!\*)/g, /==([^=\n]+)==/g, /(`[^`\n]+`)/,
  /\[([^\]\n]{1,200})\]\(([^()\s]{1,500})\)/g, /^https?:\/\/\S+$/i, /^att:([A-Za-z0-9_-]{1,64})$/, /["'<>`]/g,
  /[&<>"']/g, /\s+/, /[^a-z0-9]+/g, /^-|-$/g, /[̀-ͯ]/g, /\btoutes?\s+les\s+(\d{1,3})\s*(?:min\b|minutes\b)/i,
  /(?:^|[^\wàâäéèêëîïôöùûüç])(?:à|apr[èe]s)\s+(\d{1,3})\s*(?:min\b|minutes\b)/i, /\bq(\d{1,2})\s*h\b/i,
  /\b(?:renouvel|r[ée]p[ée]t|nouvelle\s+dose|seconde\s+dose|2e?\s+dose|nouveau\s+choc)/i,
  /g[ée]n[ée]r[ée]e?\s+par\s+IA|[àa]\s+(re)?lire\s+et\s+valider|[àa]\s+valider/i, /[àa] compl[eé]ter/i,
  /^([!?])\s(.*)$/s, /\s[·+]\s/g, /^(.*\S)\s*\(([^()]{2,})\)$/, /^(.*?)\s*\([^()]*\)$/, /\bper os\b/g, /\bintra veineuse?\b/g,
  // gardes du moteur
  /(a|ab)(c|bcd)(d*)/, /((a)|b)+/, /(z)((a+)?(b+)?(c))*/, /a{2,3}?/, /(?=(\w+))\w/, /(?!foo)bar/, /\Bxx\b/, /[^\S\n]+/g,
  /x*/g, /,/, /(-)/, /é/i, /[à-ÿ]+/i, /é|\x41/, /[\d.-]+/, /a.c/, /a.c/s, /^$/,
];
const S = [
  '', ' ', '# Titre', '### Trois  ', '#### non', '#\tTab', '# a\r', '#   b', '| a | b |', '|:--|--:|:-:|', '| - |', '|a|\rb|',
  '---', '***  ', '--*', '![Légende](img:abc_1)', '![x](img:bad id)', '> [!WARNING] Attention', '> [!constructor] x', '>',
  '  - sous', '  12. sous', '  1234. non', '- [x] fait', '- [ ]', '1) un', '[x]  reste', '⚠️ alerte', 'ℹ info',
  'a **gras** et *ital* ==surl== `code **x**`', '***a**', '*a**b*', 'x *y* *z*', '[lien](https://x.org/a?b=c) [att](att:doc_1) [bad](javascript:alert(1))',
  'HTTPS://EXEMPLE.fr', 'toutes les 3 min', 'Renouveler à 5 minutes', 'après 10 min', 'q4h', 'Q12 H', 'répéter', 'nouveau choc',
  'Fiche générée par IA le 1', 'À relire et valider', 'à compléter', 'A COMPLETER', '! urgent', '? peut-être', '!sans espace',
  'a · b + c', 'Adrénaline (IM)', 'Nom (précision longue)', 'per os', 'intra veineuse et intra veineux', 'abcd', 'abcbcdd', 'aaab',
  'zaacbbbcac', 'aaa', 'foobar barbar', 'axx xx', 'a \t\nb', 'É', 'ÉCRAN éclat', 'A', '1.2-3', 'a\nc abc', '😀 [😀](https://x) é',
  'a,b,,c', 'a-b-c', 'ſ K k', 'a b﻿c',
];
export const inputs = [];
// Une chaîne à paire de substitution n'est jouée que contre les motifs qui ne peuvent pas correspondre
// à VIDE : une coupe au milieu d'une paire produirait une moitié isolée, illisible en JSON.
for (const re of P) for (const s of S) {
  if (/[\ud800-\udfff]/.test(s) && (new RegExp(re.source, re.flags.replace('g', '')).test('') || /x\*/.test(re.source))) continue;
  inputs.push({ p: re.source, f: re.flags, s });
}
export function run(inputs) {
  return inputs.map(({ p, f, s }) => {
    const re = new RegExp(p, f.replace('g', ''));
    const m = re.exec(s);
    const g = new RegExp(p, f.includes('g') ? f : f + 'g');
    const all = [...s.matchAll(g)].map(x => [x.index, x[0].length]);
    return {
      m: m ? { i: m.index, g: [...m].map(x => (x === undefined ? null : x)) } : null,
      r: s.replace(new RegExp(p, f), '<$1|$&|$$>'),
      sp: s.split(new RegExp(p, f.replace('g', ''))).map(x => (x === undefined ? null : x)),
      all,
    };
  });
}
