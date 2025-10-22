#!/bin/bash

# Script pour corriger outputPath Firebase Hosting (détecte /browser auto) + re-deploy
# Usage: ./fix-firebase-path.sh
# Fix: index.html non trouvé dans dist/gestion-stock-app (Angular 17+ /browser)

LOG_FILE="firebase-path-fix.log"
FIREBASE_JSON="firebase.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

> "$LOG_FILE"
log_info "$(date): Détection chemin correct dist..."

# 1. Détection outputPath Angular
if [ -f "angular.json" ]; then
    BASE_OUTPUT=$(grep -A10 '"build":' angular.json | grep '"outputPath"' | sed 's/.*: *"\(.*\)".*/\1/' | head -1)
    log_info "outputPath angular.json : $BASE_OUTPUT"
else
    log_error "angular.json non trouvé"
    exit 1
fi

# 2. Cherche index.html dans les chemins possibles
POSSIBLE_PATHS=(
    "$BASE_OUTPUT/browser"
    "$BASE_OUTPUT"
    "dist/gestion-stock-app/browser"
    "dist/gestion-stock-app"
)

CORRECT_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/index.html" ]; then
        CORRECT_PATH="$path"
        log_info "✅ index.html trouvé dans : $CORRECT_PATH"
        break
    fi
done

if [ -z "$CORRECT_PATH" ]; then
    log_error "index.html non trouvé dans aucun dossier dist"
    log_info "Chemins testés :"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  - $path ($([ -d "$path" ] && echo "existe mais vide" || echo "n'existe pas"))"
    done
    log_info "Lancez d'abord : ng build --configuration production"
    exit 1
fi

# 3. Liste contenu dossier correct (debug)
log_info "Contenu de $CORRECT_PATH :"
ls -lh "$CORRECT_PATH" | head -10 | tee -a "$LOG_FILE"

# 4. Backup et mise à jour firebase.json
if [ -f "$FIREBASE_JSON" ]; then
    cp "$FIREBASE_JSON" "${FIREBASE_JSON}.backup.pathfix"
    log_info "Backup : ${FIREBASE_JSON}.backup.pathfix"
fi

cat > "$FIREBASE_JSON" << EOF
{
  "hosting": {
    "public": "$CORRECT_PATH",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(jpg|jpeg|gif|png|svg|webp|js|css|woff|woff2|ttf|eot)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
EOF
log_info "✅ firebase.json mis à jour (public: $CORRECT_PATH)"

# 5. Vérification finale
if grep -q "\"public\": \"$CORRECT_PATH\"" "$FIREBASE_JSON"; then
    log_info "✅ firebase.json valide"
else
    log_error "firebase.json invalide après mise à jour"
    exit 1
fi

# 6. Re-deploy Firebase Hosting
log_info "Re-deploy Firebase Hosting..."
if command -v firebase &> /dev/null; then
    firebase deploy --only hosting 2>&1 | tee -a "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        echo ""
        log_info "✅ DEPLOY SUCCESS !"
        
        # Récupère Project ID pour afficher URL
        if [ -f ".firebaserc" ]; then
            PROJECT_ID=$(grep -o '"default": *"[^"]*"' .firebaserc | sed 's/.*: *"\(.*\)".*/\1/')
            echo "=========================================="
            echo "  🚀 App déployée avec succès !"
            echo "=========================================="
            echo "URL : https://$PROJECT_ID.web.app"
            echo "      https://$PROJECT_ID.firebaseapp.com"
            echo ""
        fi
    else
        log_error "Deploy échoué"
        exit 1
    fi
else
    log_error "firebase CLI non installé : npm i -g firebase-tools"
    exit 1
fi

log_info "Logs : $LOG_FILE"
