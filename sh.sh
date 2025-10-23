#!/bin/bash

# FIX DÉFINITIF - Deploy correct avec vérification base-href
# Usage: ./deploy-correct.sh

echo "=== DEPLOY GITHUB PAGES - FIX DÉFINITIF ==="

REPO_NAME="gestionDeStock"
USERNAME="monsuivibipolaire-eng"

# 1. Nettoyer complètement dist
echo "1. Nettoyage complet dist..."
rm -rf dist/

# 2. Build avec base-href
echo "2. Build avec base-href..."
ng build --configuration production --base-href="/$REPO_NAME/"

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build réussi"

# 3. Trouver le BON dossier avec index.html
echo ""
echo "3. Recherche dossier contenant index.html..."

POSSIBLE_DIRS=(
    "dist/browser"
    "dist/gestion-stock-app/browser"
    "dist/gestion-stock-app"
    "dist"
)

DIST_DIR=""
for dir in "${POSSIBLE_DIRS[@]}"; do
    if [ -f "$dir/index.html" ]; then
        DIST_DIR="$dir"
        echo "✅ Trouvé: $DIST_DIR"
        break
    fi
done

if [ -z "$DIST_DIR" ]; then
    echo "❌ index.html introuvable dans dist"
    exit 1
fi

# 4. VÉRIFICATION CRITIQUE du base-href
echo ""
echo "4. Vérification base-href dans $DIST_DIR/index.html..."
BASE_HREF_CONTENT=$(cat "$DIST_DIR/index.html" | grep "base href")
echo "Contenu: $BASE_HREF_CONTENT"

if echo "$BASE_HREF_CONTENT" | grep -q "href=\"/$REPO_NAME/\""; then
    echo "✅ Base href CORRECT: /$REPO_NAME/"
elif echo "$BASE_HREF_CONTENT" | grep -q "href=\"/\""; then
    echo "❌ ERREUR: Base href est '/' au lieu de '/$REPO_NAME/'"
    echo ""
    echo "SOLUTION:"
    echo "  1. Modifiez angular.json:"
    echo "     \"configurations\": {"
    echo "       \"production\": {"
    echo "         \"baseHref\": \"/$REPO_NAME/\""
    echo "       }"
    echo "     }"
    echo ""
    echo "  2. Ou utilisez:"
    echo "     ng build --configuration production --base-href=\"/$REPO_NAME/\""
    exit 1
else
    echo "⚠️ Base href non reconnu: $BASE_HREF_CONTENT"
    read -p "Continuer quand même ? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# 5. Copier 404.html et .nojekyll
cp "$DIST_DIR/index.html" "$DIST_DIR/404.html"
touch "$DIST_DIR/.nojekyll"
echo "✅ 404.html et .nojekyll créés"

# 6. Afficher liste fichiers à déployer
echo ""
echo "5. Fichiers à déployer:"
ls -la "$DIST_DIR/" | head -20

# 7. Deploy
echo ""
echo "6. Déploiement sur gh-pages..."
cd "$DIST_DIR"

git init
git add -A
git commit -m "Deploy $(date +'%Y-%m-%d %H:%M:%S')"
git branch -M gh-pages

# Supprimer remote si existe
git remote remove origin 2>/dev/null

git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"
git push -f origin gh-pages

DEPLOY_STATUS=$?

cd - > /dev/null

if [ $DEPLOY_STATUS -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "  ✅ DÉPLOIEMENT RÉUSSI"
    echo "=========================================="
    echo ""
    echo "URL: https://$USERNAME.github.io/$REPO_NAME/"
    echo ""
    echo "ACTIONS:"
    echo "  1. Attendre 2-3 minutes (GitHub Pages build)"
    echo "  2. Vérifier: https://github.com/$USERNAME/$REPO_NAME/settings/pages"
    echo "     Source doit être: gh-pages / (root)"
    echo "  3. Vider cache navigateur (Ctrl+Shift+R / Cmd+Shift+R)"
    echo "  4. Visiter URL"
    echo ""
    echo "Vérification dans navigateur:"
    echo "  - F12 (DevTools) → Network"
    echo "  - Recharger page"
    echo "  - Vérifier que fichiers JS sont chargés depuis:"
    echo "    https://$USERNAME.github.io/$REPO_NAME/main-*.js"
    echo "    (et PAS depuis https://$USERNAME.github.io/main-*.js)"
else
    echo ""
    echo "❌ Déploiement échoué"
    echo "Essayez manuellement:"
    echo "  cd $DIST_DIR"
    echo "  git init && git add -A && git commit -m 'Deploy'"
    echo "  git branch -M gh-pages"
    echo "  git remote add origin https://github.com/$USERNAME/$REPO_NAME.git"
    echo "  git push -f origin gh-pages"
fi
