#!/bin/bash

# Script de nettoyage des fichiers backup dans le projet Angular
# Couleurs pour l'affichage
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Nettoyage des fichiers backup ===${NC}\n"

# Compteur de fichiers
count=0

# Afficher d'abord les fichiers qui seront supprimés
echo -e "${YELLOW}Fichiers qui seront supprimés:${NC}"

# Trouver tous les fichiers backup
find ./src/app -type f \( \
    -name "*.backup.*" -o \
    -name "*.bak" -o \
    -name "*.OLD_BACKUP" \
\) | while read file; do
    echo "  - $file"
    ((count++))
done

# Compter le nombre total de fichiers
total=$(find ./src/app -type f \( \
    -name "*.backup.*" -o \
    -name "*.bak" -o \
    -name "*.OLD_BACKUP" \
\) | wc -l)

echo -e "\n${YELLOW}Total: $total fichier(s)${NC}\n"

# Demander confirmation
read -p "Voulez-vous supprimer ces fichiers? (o/N): " confirm

if [[ $confirm =~ ^[oO]$ ]]; then
    # Supprimer les fichiers
    find ./src/app -type f \( \
        -name "*.backup.*" -o \
        -name "*.bak" -o \
        -name "*.OLD_BACKUP" \
    \) -delete
    
    echo -e "\n${GREEN}✓ $total fichier(s) supprimé(s) avec succès!${NC}"
else
    echo -e "\n${RED}✗ Opération annulée${NC}"
    exit 0
fi

# Optionnel: supprimer aussi le 404.html s'il existe
if [ -f "./404.html" ]; then
    read -p "Supprimer également 404.html? (o/N): " del_404
    if [[ $del_404 =~ ^[oO]$ ]]; then
        rm ./404.html
        echo -e "${GREEN}✓ 404.html supprimé${NC}"
    fi
fi

echo -e "\n${GREEN}=== Nettoyage terminé ===${NC}"
