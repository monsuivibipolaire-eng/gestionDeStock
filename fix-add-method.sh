#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Correction: Ajout getdescription ===${NC}\n"

# Entry Voucher
ENTRY_FILE="./src/app/components/entry-voucher/entry-voucher.component.ts"

if [ -f "$ENTRY_FILE" ]; then
    echo "Traitement de entry-voucher.component.ts..."
    
    cp "$ENTRY_FILE" "${ENTRY_FILE}.bak.method"
    
    # Vérifier si la méthode existe
    if ! grep -q "getdescription" "$ENTRY_FILE"; then
        # Ajouter import take si absent
        if ! grep -q "take" "$ENTRY_FILE"; then
            sed -i '1i\import { take } from '\''rxjs/operators'\'';' "$ENTRY_FILE"
        fi
        
        # Ajouter la méthode avant la dernière accolade
        # Trouver la dernière ligne et insérer avant
        total_lines=$(wc -l < "$ENTRY_FILE")
        head -n $((total_lines - 1)) "$ENTRY_FILE" > "${ENTRY_FILE}.tmp"
        
        cat >> "${ENTRY_FILE}.tmp" << 'METHODEOF'

  getdescription(productId: string): string {
    let description = "";
    this.products.pipe(take(1)).subscribe(products => {
      const product = products.find(p => p.id === productId);
      description = product?.description || "Sans description";
    });
    return description;
  }
}
METHODEOF
        
        mv "${ENTRY_FILE}.tmp" "$ENTRY_FILE"
        echo -e "${GREEN}✓ Méthode ajoutée à entry-voucher${NC}"
    else
        echo -e "${YELLOW}✓ Méthode déjà présente dans entry-voucher${NC}"
    fi
else
    echo -e "${RED}✗ $ENTRY_FILE introuvable${NC}"
fi

# Exit Voucher
EXIT_FILE="./src/app/components/exit-voucher/exit-voucher.component.ts"

if [ -f "$EXIT_FILE" ]; then
    echo "Traitement de exit-voucher.component.ts..."
    
    cp "$EXIT_FILE" "${EXIT_FILE}.bak.method"
    
    # Vérifier si la méthode existe
    if ! grep -q "getdescription" "$EXIT_FILE"; then
        # Ajouter import take si absent
        if ! grep -q "take" "$EXIT_FILE"; then
            sed -i '1i\import { take } from '\''rxjs/operators'\'';' "$EXIT_FILE"
        fi
        
        # Ajouter la méthode avant la dernière accolade
        total_lines=$(wc -l < "$EXIT_FILE")
        head -n $((total_lines - 1)) "$EXIT_FILE" > "${EXIT_FILE}.tmp"
        
        cat >> "${EXIT_FILE}.tmp" << 'METHODEOF'

  getdescription(productId: string): string {
    let description = "";
    this.products.pipe(take(1)).subscribe(products => {
      const product = products.find(p => p.id === productId);
      description = product?.description || "Sans description";
    });
    return description;
  }
}
METHODEOF
        
        mv "${EXIT_FILE}.tmp" "$EXIT_FILE"
        echo -e "${GREEN}✓ Méthode ajoutée à exit-voucher${NC}"
    else
        echo -e "${YELLOW}✓ Méthode déjà présente dans exit-voucher${NC}"
    fi
else
    echo -e "${RED}✗ $EXIT_FILE introuvable${NC}"
fi

echo -e "\n${GREEN}=== Terminé ===${NC}"
echo "L'erreur TS2339 devrait être corrigée maintenant."
echo "Angular va recompiler automatiquement."
