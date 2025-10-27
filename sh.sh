#!/bin/bash

# Script pour auto-remplir le prix unitaire lors de la sélection du produit
# SPÉCIFIQUEMENT pour EntryVoucherComponent

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Ajout Auto-remplissage Prix Unitaire (Bon d'Entrée) ===${NC}\n"

TS_FILE="./src/app/components/entry-voucher/entry-voucher.component.ts"
HTML_FILE="./src/app/components/entry-voucher/entry-voucher.component.html"
COMPONENT_NAME="EntryVoucherComponent"

# --- Vérifier les fichiers ---
if [ ! -f "$TS_FILE" ]; then echo -e "${RED}ERREUR: $TS_FILE introuvable.${NC}"; exit 1; fi
if [ ! -f "$HTML_FILE" ]; then echo -e "${RED}ERREUR: $HTML_FILE introuvable.${NC}"; exit 1; fi

# --- Créer backups ---
echo "  → Création backups (.bak.autoprice_entry)..."
cp "$TS_FILE" "$TS_FILE.bak.autoprice_entry"
cp "$HTML_FILE" "$HTML_FILE.bak.autoprice_entry"

# --- Modifier le fichier TypeScript (.ts) ---
echo "  → Modification de $COMPONENT_NAME ($TS_FILE)..."

# Vérifier si la méthode onProductSelected existe déjà
if grep -q "onProductSelected(event: Event, index: number)" "$TS_FILE"; then
    echo -e "${YELLOW}    ✓ Méthode onProductSelected déjà présente.${NC}"
else
    # Ajouter la méthode onProductSelected avant addProductLine
    perl -i -0777 -pe '
      s{
        # Trouve le début de la méthode addProductLine
        (^\s*addProductLine\(\):\s*void\s*\{)
      }
      {
        # Insère la nouvelle méthode AVANT addProductLine
        qq{\n
          onProductSelected(event: Event, index: number): void {
            const selectElement = event.target as HTMLSelectElement;
            const productId = selectElement.value;
            const productLine = this.productsFormArray.at(index);

            if (!productId || !productLine) {
              productLine?.patchValue({ unitPrice: 0 }); // Reset prix si pas de sélection
              return;
            }

            // Trouve le produit dans la liste synchrone productList
            const selectedProduct = this.productList.find(p => p.id === productId);

            if (selectedProduct) {
              // Met à jour le prix unitaire dans le formulaire pour cette ligne
              productLine.patchValue({ unitPrice: selectedProduct.price });
            } else {
              // Si produit non trouvé (devrait pas arriver si productList est à jour)
              productLine.patchValue({ unitPrice: 0 });
              console.warn(`Produit non trouvé dans productList: ${productId}`);
            }
          }
          \n\n
        } . $1 # Réinsère le début de addProductLine trouvé
      }me; # m=multiligne, e=eval replacement
    ' "$TS_FILE"

    # Vérification
    if grep -q "onProductSelected(event: Event, index: number)" "$TS_FILE"; then
        echo -e "${GREEN}    ✓ Méthode onProductSelected ajoutée.${NC}"
    else
        echo -e "${RED}    ✗ Échec de l'ajout de la méthode onProductSelected. Vérification manuelle requise.${NC}"
    fi
fi

# --- Modifier le fichier HTML (.html) ---
echo "  → Modification du template $COMPONENT_NAME ($HTML_FILE)..."

# Ajouter (change)="onProductSelected($event, i)" au select du productId s'il n'existe pas déjà
if ! grep -q '(change)="onProductSelected($event, i)"' "$HTML_FILE"; then
  # Utilise perl pour plus de robustesse avec les sauts de ligne potentiels
  perl -i -pe '
    s{(<select\s+formControlName="productId"\s*.*?)(>) # Capture le début de la balise select et la fin >
     }
     {$1 . q{ (change)="onProductSelected($event, i)"} . $2 # Insère l événement avant le > final
     }ge; # g=global, e=eval
  ' "$HTML_FILE"

   # Vérification
    if grep -q '(change)="onProductSelected($event, i)"' "$HTML_FILE"; then
         echo -e "${GREEN}    ✓ Événement (change) ajouté au select productId.${NC}"
    else
         echo -e "${RED}    ✗ Échec de l'ajout de l'événement (change). Vérification manuelle requise.${NC}"
    fi
else
    echo -e "${YELLOW}    ✓ Événement (change) déjà présent sur select productId.${NC}"
fi

echo -e "\n${GREEN}=== Script Terminé ===${NC}"
echo "Le composant Bon d'Entrée a été modifié."
echo "Le prix unitaire devrait maintenant se remplir automatiquement lors de la sélection du produit."
echo "Des backups (.bak.autoprice_entry) ont été créés."
echo "Vérifiez les modifications et relancez 'ng serve'."