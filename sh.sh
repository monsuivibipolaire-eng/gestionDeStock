#!/bin/bash

# Deploy GitHub Pages - Version Finale Corrigée
# Usage: ./deploy-final.sh

echo "=== DEPLOY GITHUB PAGES - gestionDeStock ==="

# Paramètres
REPO_NAME="gestionDeStock"
USERNAME="monsuivibipolaire-eng"
DIST_DIR="dist/gestion-stock-app/browser"

echo "Repo: $REPO_NAME"
echo "Username: $USERNAME"
echo "URL: https://$USERNAME.github.io/$REPO_NAME/"
echo ""

# 1. Build avec base-href correct
echo "1. Build production avec base-href..."
ng build --configuration production --base-href="/$REPO_NAME/"

if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Build réussi"

# 2. Vérifier dist existe
if [ ! -d "$DIST_DIR" ]; then
    echo "❌ $DIST_DIR introuvable"
    exit 1
fi

echo "✅ Dist trouvé: $DIST_DIR"

# 3. Copier 404.html
cp "$DIST_DIR/index.html" "$DIST_DIR/404.html"
echo "✅ 404.html créé"

# 4. Vérifier contenu index.html
echo ""
echo "Vérification base href dans index.html..."
grep -n "base href" "$DIST_DIR/index.html"

# 5. Deploy
echo ""
echo "2. Déploiement sur gh-pages..."
cd "$DIST_DIR"

# Init git
git init
git add .
git commit -m "Deploy $(date +'%Y-%m-%d %H:%M')"

# Branch gh-pages
git branch -M gh-pages

# Remote (supprimer ancien si existe)
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$USERNAME/$REPO_NAME.git"

# Push force
git push -f origin gh-pages

cd ../../..

echo ""
echo "=========================================="
echo "  ✅ Déploiement Terminé"
echo "=========================================="
echo ""
echo "URL: https://$USERNAME.github.io/$REPO_NAME/"
echo ""
echo "Actions à faire:"
echo "  1. Attendre 2-3 minutes (build GitHub Pages)"
echo "  2. Vérifier: https://github.com/$USERNAME/$REPO_NAME/settings/pages"
echo "  3. Source doit être: gh-pages / (root)"
echo "  4. Visiter URL"
echo ""
echo "Si 404 persiste:"
echo "  - Vérifier que branch gh-pages existe"
echo "  - Vérifier GitHub Pages Settings activé"
