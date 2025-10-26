#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Ajout de la description dans les impressions ===${NC}\n"

# Fonction pour ajouter getdescription
add_get_description_method() {
    local file=$1
    local component_name=$2
    
    # Vérifier si la méthode existe déjà
    if grep -q "getdescription" "$file"; then
        echo "  ✓ Méthode getdescription déjà présente dans $component_name"
        return
    fi
    
    # Ajouter la méthode avant la dernière accolade
    sed -i.bak '/^}$/i\
\
  getdescription(productId: string): string {\
    let description = "";\
    this.products.subscribe(products => {\
      const product = products.find(p => p.id === productId);\
      description = product?.description || "Aucune description";\
    });\
    return description;\
  }\
' "$file"
    
    echo -e "${GREEN}  ✓ Méthode getdescription ajoutée à $component_name${NC}"
}

# Fonction pour modifier le HTML d'impression
modify_print_html() {
    local file=$1
    local component_name=$2
    
    echo "  → Modification du HTML d'impression dans $component_name..."
    
    # Backup
    cp "$file" "${file}.backup.description"
    
    # Modifier printItem - ajouter colonne Description dans thead
    sed -i '' 's/<th>Produit<\/th>/<th>Produit<\/th><th>Description<\/th>/g' "$file" 2>/dev/null || \
    sed -i 's/<th>Produit<\/th>/<th>Produit<\/th><th>Description<\/th>/g' "$file"
    
    # Modifier printItem - ajouter cellule description dans tbody
    # Chercher: <td>${p.description}</td>
    # Remplacer par: <td>${p.description}</td><td class="description">${this.getdescription(p.productId)}</td>
    
    sed -i '' 's/<td>\${p\.description}<\/td>/<td>${p.description}<\/td><td class="description">${this.getdescription(p.productId)}<\/td>/g' "$file" 2>/dev/null || \
    sed -i 's/<td>\${p\.description}<\/td>/<td>${p.description}<\/td><td class="description">${this.getdescription(p.productId)}<\/td>/g' "$file"
    
    # Ajuster colspan pour le total (était 3, maintenant 5)
    sed -i '' 's/th colspan="3">Total/th colspan="4">Total/g' "$file" 2>/dev/null || \
    sed -i 's/th colspan="3">Total/th colspan="4">Total/g' "$file"
    
    # Ajouter style CSS pour description
    sed -i '' 's/th { background: #f3f4f6; }/th { background: #f3f4f6; }\n    .description { font-size: 11px; color: #666; font-style: italic; max-width: 200px; }/g' "$file" 2>/dev/null || \
    sed -i 's/th { background: #f3f4f6; }/th { background: #f3f4f6; }\n    .description { font-size: 11px; color: #666; font-style: italic; max-width: 200px; }/g' "$file"
    
    echo -e "${GREEN}  ✓ HTML d'impression modifié${NC}"
}

# Modifier printList également
modify_print_list_html() {
    local file=$1
    local component_name=$2
    
    echo "  → Modification du printList dans $component_name..."
    
    # Ajouter description dans la liste imprimée (optionnel - affiche juste le nom)
    # On peut garder la liste simple sans description pour ne pas surcharger
    
    echo -e "${GREEN}  ✓ printList conservé simple (sans description)${NC}"
}

# Traiter entry-voucher.component.ts
ENTRY_FILE="./src/app/components/entry-voucher/entry-voucher.component.ts"
if [ -f "$ENTRY_FILE" ]; then
    echo -e "\n${YELLOW}[1/2] Traitement de entry-voucher...${NC}"
    add_get_description_method "$ENTRY_FILE" "EntryVoucherComponent"
    modify_print_html "$ENTRY_FILE" "EntryVoucherComponent"
else
    echo "⚠ Fichier $ENTRY_FILE introuvable"
fi

# Traiter exit-voucher.component.ts
EXIT_FILE="./src/app/components/exit-voucher/exit-voucher.component.ts"
if [ -f "$EXIT_FILE" ]; then
    echo -e "\n${YELLOW}[2/2] Traitement de exit-voucher...${NC}"
    add_get_description_method "$EXIT_FILE" "ExitVoucherComponent"
    modify_print_html "$EXIT_FILE" "ExitVoucherComponent"
else
    echo "⚠ Fichier $EXIT_FILE introuvable"
fi

echo -e "\n${GREEN}=== Terminé ===${NC}"
echo ""
echo "Modifications appliquées:"
echo "✓ Méthode getdescription() ajoutée aux composants"
echo "✓ Colonne 'Description' ajoutée dans les tableaux d'impression"
echo "✓ Style CSS pour description (police petite, italique, grise)"
echo "✓ Colspan du total ajusté (3 → 4)"
echo ""
echo "Note: Les fichiers backup ont été créés (.backup.description)"
