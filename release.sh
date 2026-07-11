#!/usr/bin/env bash
# Prépare une nouvelle version : synchronise le numéro dans index.html + sw.js, ébauche l'entrée
# CHANGELOG, vérifie syntaxe et tests. NE COMMITTE PAS : la rédaction des notes de version et le
# commit restent à la charge de l'humain ou de l'IA (voir CLAUDE.md), ce script élimine seulement
# l'erreur mécanique (versions désynchronisées = mise à jour du service worker cassée).
#
# Usage :   ./release.sh 3.1.0
set -euo pipefail

VER="${1:-}"
if [[ ! "$VER" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Usage : ./release.sh X.Y.Z"; exit 1
fi
cd "$(dirname "$0")"

# 1. Mettre à jour les versions dans les sources.
#    macOS (BSD sed) et Linux (GNU sed) : on écrit dans un fichier temporaire, plus portable que -i.
update() { # fichier  regex-perl
  perl -pe "$2" "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
update index.html "s/const APP_VERSION='[0-9.]+';/const APP_VERSION='$VER';/"
update sw.js      "s/const CACHE = 'aides-cognitives-v[0-9.]+';/const CACHE = 'aides-cognitives-v$VER';/"
update package.json 's/"version": "[0-9.]+"/"version": "'"$VER"'"/'

# 2. Vérifier que les trois valeurs correspondent bien maintenant.
grep -q "const APP_VERSION='$VER';" index.html || { echo "Échec MAJ index.html"; exit 1; }
grep -q "aides-cognitives-v$VER'" sw.js       || { echo "Échec MAJ sw.js"; exit 1; }
grep -q "\"version\": \"$VER\"" package.json  || { echo "Échec MAJ package.json"; exit 1; }
echo "Versions mises à jour → $VER (index.html + sw.js + package.json)"

# 3. Insérer une entrée CHANGELOG si la version n'y est pas déjà.
DATE="$(date +%Y-%m-%d)"
if [[ -f CHANGELOG.md ]] && ! grep -q "## \[$VER\]" CHANGELOG.md; then
  perl -0pe "s/(# Journal des modifications\n)/\$1\n## [$VER] — $DATE\n- (à compléter)\n/" CHANGELOG.md > CHANGELOG.md.tmp && mv CHANGELOG.md.tmp CHANGELOG.md
  echo "Entrée CHANGELOG ajoutée pour $VER (pensez à la compléter)."
fi

# 4. Vérification de syntaxe (sans dépendance) : garde-fou OBLIGATOIRE.
node scripts/check-syntax.mjs || { echo "Syntaxe invalide — publication interrompue."; exit 1; }

# 5. Tests fonctionnels si Playwright est installé. On distingue :
#    - tests en ÉCHEC (code 1) -> on bloque la publication ;
#    - Playwright ABSENT (code 2) -> simple avertissement (les tests tournent en CI de toute façon).
if command -v npm >/dev/null 2>&1 && [[ -f package.json ]]; then
  echo "Exécution des tests…"
  # « || rc=$? » : sous set -e, « npm test; rc=$? » quitterait le script AVANT de capturer le code
  # de retour — la distinction échec/Playwright-absent ci-dessous ne s'exécuterait jamais.
  rc=0; npm test --silent || rc=$?
  if [[ $rc -eq 1 ]]; then echo "Tests en échec — publication interrompue."; exit 1;
  elif [[ $rc -ne 0 ]]; then echo "⚠ Tests non exécutés (Playwright absent : 'npm install && npx playwright install chromium'). La CI les rejouera."; fi
fi

# 6. Build de distribution : dist/ (commentaires retirés, ~102 Ko gzip au lieu de ~181) est la
#    forme à déployer ; le régénérer ici évite de mettre en ligne un dist/ périmé d'une version
#    précédente (vu à l'audit v4.0.0 : un dist/ local v3.5.0 sans pdf.js traînait encore).
if command -v npm >/dev/null 2>&1 && [[ -d node_modules ]]; then
  npm run build --silent || { echo "Build dist/ en échec — publication interrompue."; exit 1; }
else
  echo "⚠ dist/ non régénéré (node_modules absent) : 'npm install && npm run build' avant tout déploiement de dist/."
fi

# 7. Fin : le commit (avec de VRAIES notes de version) et le tag restent à faire — cf. CLAUDE.md.
echo ""
echo "Préparation v$VER terminée. Reste à faire (humain ou IA) :"
echo "  1. compléter l'entrée CHANGELOG.md de $VER ;"
echo "  2. git add -A && git commit -m \"v$VER : <résumé des changements>\" ;"
echo "  3. git tag v$VER   (puis git push && git push --tags)."
