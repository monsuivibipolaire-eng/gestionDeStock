#!/bin/bash

# ============================================
# Script de déploiement Angular avec gestion d'erreurs
# ============================================

echo "========================================"
echo "Déploiement Angular"
echo "========================================"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ============================================
# 1. Vérifier que node_modules existe
# ============================================

echo -e "${YELLOW}1. Vérification des dépendances...${NC}"

if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}Installation des dépendances...${NC}"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Échec de l'installation des dépendances${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Dépendances OK${NC}"

# ============================================
# 2. Nettoyer les anciens builds
# ============================================

echo -e "${YELLOW}2. Nettoyage des anciens builds...${NC}"

if [ -d "dist" ]; then
    rm -rf dist
fi

if [ -d ".angular" ]; then
    rm -rf .angular
fi

echo -e "${GREEN}✓ Nettoyage terminé${NC}"

# ============================================
# 3. Build de production
# ============================================

echo -e "${YELLOW}3. Build de production...${NC}"

ng build --configuration production

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Échec du build${NC}"
    echo ""
    echo "Erreurs possibles :"
    echo "  - Erreur de syntaxe TypeScript"
    echo "  - Module manquant"
    echo "  - Erreur de configuration"
    exit 1
fi

echo -e "${GREEN}✓ Build réussi${NC}"

# ============================================
# 4. Vérifier que dist existe
# ============================================

echo -e "${YELLOW}4. Vérification des fichiers générés...${NC}"

if [ ! -d "dist" ]; then
    echo -e "${RED}✗ Le dossier dist n'a pas été créé${NC}"
    exit 1
fi

# Trouver le dossier de build (peut être dist/nom-projet ou dist/browser)
BUILD_DIR=$(find dist -name "index.html" -type f -exec dirname {} \; | head -n 1)

if [ -z "$BUILD_DIR" ]; then
    echo -e "${RED}✗ Impossible de trouver index.html dans dist${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Fichiers générés dans : $BUILD_DIR${NC}"

# ============================================
# 5. Déploiement Firebase (si configuré)
# ============================================

if [ -f "firebase.json" ]; then
    echo -e "${YELLOW}5. Déploiement Firebase...${NC}"
    
    # Vérifier si firebase-tools est installé
    if ! command -v firebase &> /dev/null; then
        echo -e "${YELLOW}Installation de firebase-tools...${NC}"
        npm install -g firebase-tools
    fi
    
    # Déployer
    firebase deploy
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Déploiement Firebase réussi${NC}"
    else
        echo -e "${RED}✗ Échec du déploiement Firebase${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}5. firebase.json non trouvé - Déploiement Firebase ignoré${NC}"
fi

# ============================================
# FIN
# ============================================

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Déploiement terminé avec succès !${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Fichiers générés dans : $BUILD_DIR"
echo ""
