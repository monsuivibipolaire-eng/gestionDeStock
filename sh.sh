#!/bin/bash

# Script COMPLET pour corriger productName/description et boucle infinie
# dans ExitVoucherComponent (.ts et .html)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Correction Complète ExitVoucherComponent ===${NC}\n"

TS_FILE="./src/app/components/exit-voucher/exit-voucher.component.ts"
HTML_FILE="./src/app/components/exit-voucher/exit-voucher.component.html"

# --- Vérifier les fichiers ---
if [ ! -f "$TS_FILE" ]; then echo -e "${RED}ERREUR: $TS_FILE introuvable.${NC}"; exit 1; fi
if [ ! -f "$HTML_FILE" ]; then echo -e "${RED}ERREUR: $HTML_FILE introuvable.${NC}"; exit 1; fi

# --- Créer backups ---
echo "  → Création backups (.bak.exit_complete_fix)..."
cp "$TS_FILE" "$TS_FILE.bak.exit_complete_fix"
cp "$HTML_FILE" "$HTML_FILE.bak.exit_complete_fix"

# --- Modifier le fichier TypeScript (.ts) ---
echo "  → Modification de $TS_FILE..."

# 1. Assurer la présence et l'initialisation de productList
if ! grep -q "productList: Product\[\] = \[\];" "$TS_FILE"; then
    if ! grep -q 'products\$!: Observable<Product\[\]>;' "$TS_FILE"; then
        echo -e "${YELLOW}    ⚠ Ligne 'products$!: Observable<Product[]>;' non trouvée. L'ajout de productList pourrait échouer.${NC}"
    else
        sed -i.tmp '/products\$!: Observable<Product\[\]>;/a\
  productList: Product[] = []; // Cache synchrone' "$TS_FILE" && rm "${TS_FILE}.tmp"
        echo -e "${GREEN}    ✓ Propriété productList ajoutée.${NC}"
    fi
else
    echo -e "${YELLOW}    ✓ Propriété productList déjà présente.${NC}"
fi
if ! grep -q "this\.productList = products;" "$TS_FILE"; then
    if ! grep -q 'this\.products\$ = this\.productsService\.getProducts();' "$TS_FILE"; then
         echo -e "${YELLOW}    ⚠ Ligne 'this.products$ = this.productsService.getProducts();' non trouvée. L'ajout du subscribe pourrait échouer.${NC}"
    else
        # Insère le subscribe s'il manque dans ngOnInit
        perl -i -0777 -pe '
          s{(ngOnInit\(\):\s*void\s*\{.*?)(\n\s*this\.products\$ = this\.productsService\.getProducts\(\);)}
           {$1$2\n    this.products$.subscribe((products) => {\n      this.productList = products;\n    });}s
        ' "$TS_FILE"
        echo -e "${GREEN}    ✓ Initialisation de productList dans ngOnInit ajoutée/vérifiée.${NC}"
    fi
else
     echo -e "${YELLOW}    ✓ Initialisation de productList déjà présente.${NC}"
fi

# 2. Réécrire COMPLETEMENT getProductName et getDescription pour garantir l'utilisation de productList
echo "  → Réécriture de getProductName et getDescription (synchrones)..."
perl -i -0777 -pe '
    # Supprime anciennes versions
    s{\n\s*(\/\/.*?|\/\*.*?\*\/)?\s*(async\s+)?getProductName\(productId:\s*string\).*?^\s*\}\n}{}msg;
    s{\n\s*(\/\/.*?|\/\*.*?\*\/)?\s*(async\s+)?getDescription\(productId:\s*string\).*?^\s*\}\n}{}msg;

    # Ajoute les versions synchrones correctes avant la dernière accolade de classe
    s{(\n\s*\}\s*$)}
      \n
      getProductName(productId: string): string {
        const product = this.productList.find(p => p.id === productId);
        return product ? product.name : "Produit_Inconnu";
      }
      \n
      getDescription(productId: string): string {
        const prod = this.productList.find(p => p.id === productId);
        return prod?.description \|\| "Pas_de_description";
      }
    $1}m;
' "$TS_FILE"
echo -e "${GREEN}    ✓ Méthodes getProductName et getDescription réécrites.${NC}"

# 3. Ajouter getSubtotal si elle manque
echo "  → Vérification/Ajout de getSubtotal..."
if ! grep -q "getSubtotal(line: any): number" "$TS_FILE"; then
    perl -i -0777 -pe '
    s{(\n\s*\}\s*$)}
      \n
      getSubtotal(line: any): number {
        const quantity = line && typeof line.quantity === "number" ? line.quantity : 0;
        const unitPrice = line && typeof line.unitPrice === "number" ? line.unitPrice : 0;
        return quantity * unitPrice;
      }
    $1}m;
    ' "$TS_FILE"
    echo -e "${GREEN}    ✓ Méthode getSubtotal ajoutée.${NC}"
else
    echo -e "${YELLOW}    ✓ Méthode getSubtotal déjà présente.${NC}"
fi


# 4. Réécrire COMPLETEMENT le bloc .map() dans onSubmit pour recherche synchrone directe
echo "  → Réécriture du bloc .map() dans onSubmit..."
perl -i -0777 -pe '
  s{
    (^\s*const\s+productsWithNames.*?formValue\.products\.map\(\s*\(p:\s*any\)\s*=>\s*)
    .*? # Contenu potentiellement corrompu
    (;\s*$) # Fin de l instruction map
  }
  {
    $1 . # Colle le début
    # --- Code correct pour la fonction map ---
    "{\n" .
    "      const product = this.productList.find(prod => prod.id === p.productId);\n" .
    "      const productName = product ? product.name : \x27Produit_Inconnu\x27;\n" .
    "      const description = product ? (product.description \|\| \x27Pas_de_description\x27) : \x27Pas_de_description\x27;\n" .
    "      const subtotal = (p.quantity \|\| 0) * (p.unitPrice \|\| 0);\n" .
    "\n" .
    "      return {\n" .
    "        ...p,\n" .
    "        productName: productName,\n" .
    "        description: description,\n" .
    "        subtotal: subtotal,\n" .
    "      };\n" .
    "    })" . # Fin de la fonction map et de l appel à map()
    # --- Fin Code correct ---
    $2 # Colle la fin ;
  }meg;
' "$TS_FILE"

# Vérification
if grep -q "const product = this.productList.find(prod => prod.id === p.productId);" "$TS_FILE" && grep -q "productName: productName," "$TS_FILE" && grep -q "description: description," "$TS_FILE"; then
    echo -e "${GREEN}    ✓ Bloc .map() dans onSubmit réécrit avec recherche synchrone directe.${NC}"
else
    echo -e "${RED}    ✗ Échec de la réécriture du bloc .map(). Vérification manuelle requise.${NC}"
fi

# --- Modifier le fichier HTML (.html) ---
echo "  → Modification de $HTML_FILE..."

# Remplacer les appels DANS LA BOUCLE *ngFor de l'expansion
perl -i -0777 -pe '
  s{
    # Début section et ligne *ngFor
    (\*ngIf="expandedVoucherId\s*===\s*voucher\.id".*?<tr\s+\*ngFor="let\s+line\s+of\s+voucher\?\.products\s*\|\|\s*\[\]".*?>)
    (.*?) # Contenu de la boucle
    (</tr>) # Fin de la ligne tr
  }
  {
    my $start = $1;
    my $content = $2;
    my $end = $3;
    # Remplacements ciblés
    $content =~ s/\{\{\s*getProductName\(line\.productId\)\s*\}\}/{{ line.productName }}/g;
    $content =~ s/\{\{\s*getDescription\(line\.productId\)\s*\}\}/{{ line.description }}/g;
    $content =~ s/\{\{\s*getSubtotal\(line\)\s*\|\s*number:\s*'\''1\.2-2'\''\s*\}\}/{{ line.subtotal | number:\x271.2-2\x27 }}/g;
    # Tentative de réorganisation des TDs (basée sur la structure probable: ID, Nom, Desc, Qte, PU, ST)
    # SI VOTRE ORDRE EST DIFFERENT, AJUSTEZ MANUELLEMENT LE HTML APRES LE SCRIPT
    $content =~ s{
        # Capture les TDs existantes (flexible)
        .*?
        (<td.*?\/td>\s*) # TD 1 (supposé ID)
        (<td.*?\/td>\s*) # TD 2 (supposé Ancien Nom/Desc)
        (<td.*?\/td>\s*) # TD 3 (supposé Ancien Nom/Desc ou Quantité)
        (<td.*?\/td>\s*) # TD 4 (supposé Quantité ou Prix)
        (<td.*?\/td>\s*) # TD 5 (supposé Prix ou Sous-total)
        (<td.*?\/td>\s*) # TD 6 (supposé Sous-total)
        .*?
    }
    { # Réécrit les TDs dans l ordre attendu avec les bonnes variables
        qq{
            <td class="px-4 py-2 text-xs font-mono">{{ line.productId }}</td>
            <td class="px-4 py-2">{{ line.productName }}</td>
            <td class="px-4 py-2 description">{{ line.description }}</td>
            <td class="px-4 py-2">{{ line.quantity }}</td>
            <td class="px-4 py-2">{{ line.unitPrice | number:'1.2-2' }} DT</td>
            <td class="px-4 py-2 font-semibold">{{ line.subtotal | number:'1.2-2' }} DT</td>
        }
    }sxe;

    $start . $content . $end;
  }gsex;
' "$HTML_FILE"

echo -e "${GREEN}    ✓ Template HTML modifié pour utiliser les propriétés directes dans l'expansion (vérifiez l'ordre des TDs).${NC}"


echo -e "\n${GREEN}=== Script Terminé ===${NC}"
echo "Les fichiers '$TS_FILE' et '$HTML_FILE' ont été modifiés."
echo "**ACTION REQUISE :** Vérifiez manuellement la structure des `<td>` dans la boucle `*ngFor` de `$HTML_FILE` (section \*ngIf=\"expandedVoucherId === voucher.id\") pour vous assurer que l'ordre des colonnes (ID, Nom, Description, Quantité, Prix Unit., Sous-total) est correct."
echo "Relancez 'ng serve' et testez à nouveau."