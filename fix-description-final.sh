#!/bin/bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Correction: Ajout de la description dans les impressions ===${NC}\n"

# Entry Voucher Component
ENTRY_FILE="./src/app/components/entry-voucher/entry-voucher.component.ts"

if [ -f "$ENTRY_FILE" ]; then
    echo "Traitement de entry-voucher.component.ts..."
    
    # Backup
    cp "$ENTRY_FILE" "${ENTRY_FILE}.backup.desc2"
    
    # Ajouter la méthode getdescription juste avant le dernier }
    # Vérifier si elle n'existe pas déjà
    if ! grep -q "getdescription" "$ENTRY_FILE"; then
        # Trouver la dernière ligne avec } et ajouter la méthode avant
        perl -i -pe 'BEGIN{undef $/;} s/(\n\}$)/\n\n  getdescription(productId: string): string {\n    let description = "";\n    this.products.pipe(take(1)).subscribe(products => {\n      const product = products.find(p => p.id === productId);\n      description = product?.description || "Sans description";\n    });\n    return description;\n  }\n$1/smg' "$ENTRY_FILE"
        
        echo -e "${GREEN}✓ Méthode getdescription ajoutée${NC}"
    else
        echo -e "${YELLOW}✓ Méthode getdescription déjà présente${NC}"
    fi
    
    # Vérifier si take est importé
    if ! grep -q "import.*take.*from 'rxjs/operators'" "$ENTRY_FILE" && ! grep -q "import.*take.*from 'rxjs'" "$ENTRY_FILE"; then
        # Ajouter l'import de take
        sed -i '' '1i\
import { take } from '\''rxjs/operators'\'';
' "$ENTRY_FILE" 2>/dev/null || sed -i '1i\import { take } from '\''rxjs/operators'\'';' "$ENTRY_FILE"
        echo -e "${GREEN}✓ Import 'take' ajouté${NC}"
    fi
    
else
    echo -e "${RED}✗ Fichier $ENTRY_FILE introuvable${NC}"
fi

# Exit Voucher Component
EXIT_FILE="./src/app/components/exit-voucher/exit-voucher.component.ts"

if [ -f "$EXIT_FILE" ]; then
    echo "Traitement de exit-voucher.component.ts..."
    
    # Backup
    cp "$EXIT_FILE" "${EXIT_FILE}.backup.desc2"
    
    # Ajouter la méthode getdescription
    if ! grep -q "getdescription" "$EXIT_FILE"; then
        perl -i -pe 'BEGIN{undef $/;} s/(\n\}$)/\n\n  getdescription(productId: string): string {\n    let description = "";\n    this.products.pipe(take(1)).subscribe(products => {\n      const product = products.find(p => p.id === productId);\n      description = product?.description || "Sans description";\n    });\n    return description;\n  }\n$1/smg' "$EXIT_FILE"
        
        echo -e "${GREEN}✓ Méthode getdescription ajoutée${NC}"
    else
        echo -e "${YELLOW}✓ Méthode getdescription déjà présente${NC}"
    fi
    
    # Vérifier si take est importé
    if ! grep -q "import.*take.*from 'rxjs/operators'" "$EXIT_FILE" && ! grep -q "import.*take.*from 'rxjs'" "$EXIT_FILE"; then
        sed -i '' '1i\
import { take } from '\''rxjs/operators'\'';
' "$EXIT_FILE" 2>/dev/null || sed -i '1i\import { take } from '\''rxjs/operators'\'';' "$EXIT_FILE"
        echo -e "${GREEN}✓ Import 'take' ajouté${NC}"
    fi
    
else
    echo -e "${RED}✗ Fichier $EXIT_FILE introuvable${NC}"
fi

echo -e "\n${GREEN}=== Terminé ===${NC}"
echo "Relancez: ng serve"
