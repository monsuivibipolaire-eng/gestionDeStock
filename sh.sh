#!/bin/bash

# Script COMPLET CORRIGÉ V2 pour harmoniser PurchaseOrderComponent et DevisComponent
# avec Entry/Exit Voucher (productList, getters sync, onSubmit, onProductSelected, accordion, print)

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Harmonisation PurchaseOrder & Devis Components (Corrigé V2) ===${NC}\n"

# --- Fonction pour modifier le fichier TypeScript (.ts) ---
modify_component_ts() {
    local file=$1
    local component_name=$2
    local model_name=$3 # 'PurchaseOrder' or 'Devis'
    local service_name=$4 # 'ordersService' or 'devisService'
    local number_prop=$5 # 'orderNumber' or 'quoteNumber'
    local related_entity=$6 # 'supplier' or 'customer'
    local related_service=$7 # 'suppliersService' or 'customersService'
    local related_observable=$8 # 'suppliers$' or 'customers$'
    local expanded_prop=$9 # 'expandedOrderId' or 'expandedDevisId'

    echo "  → Modification de $component_name ($file)..."
    cp "$file" "$file.bak.harmonize_v3" # Backup

    # 1. Assurer productList et initialisation
    echo "    [1/6] Vérification/Ajout productList..."
    if ! grep -q "productList: Product\[\] = \[\];" "$file"; then
        if ! grep -q 'products\$!: Observable<Product\[\]>;' "$file"; then
             echo -e "${YELLOW}      ⚠ Ligne 'products$!: Observable<Product[]>;' non trouvée. Impossible d'ajouter productList automatiquement.${NC}"
        else
            sed -i.tmp '/products\$!: Observable<Product\[\]>;/a\
  productList: Product[] = []; // Cache synchrone' "$file" && rm "${file}.tmp"
            echo -e "${GREEN}      ✓ Propriété productList ajoutée.${NC}"
        fi
    else
        echo -e "${YELLOW}      ✓ Propriété productList déjà présente.${NC}"
    fi
    if ! grep -q "this\.productList = products;" "$file"; then
         if ! grep -q 'this\.products\$ = this\.productsService\.getProducts();' "$file"; then
             echo -e "${YELLOW}      ⚠ Ligne 'this.products$ = this.productsService.getProducts();' non trouvée. Impossible d'ajouter le subscribe automatiquement.${NC}"
         else
            perl -i -0777 -pe '
              s{(ngOnInit\(\):\s*void\s*\{.*?)(\n\s*this\.products\$ = this\.productsService\.getProducts\(\);)}
               {$1$2\n    this.products$.subscribe((products) => {\n      this.productList = products;\n    });}s
            ' "$file"
            echo -e "${GREEN}      ✓ Initialisation de productList dans ngOnInit ajoutée/vérifiée.${NC}"
        fi
    else
         echo -e "${YELLOW}      ✓ Initialisation de productList déjà présente.${NC}"
    fi

    # 2. Réécrire getProductName, getDescription, getSubtotal (synchrones)
    echo "    [2/6] Réécriture getters (getProductName, getDescription, getSubtotal)..."
    perl -i -0777 -pe '
        s{\n\s*(\/\/.*?|\/\*.*?\*\/)?\s*(async\s+)?getProductName\(productId:\s*string\).*?^\s*\}\n}{}msg;
        s{\n\s*(\/\/.*?|\/\*.*?\*\/)?\s*(async\s+)?getDescription\(productId:\s*string\).*?^\s*\}\n}{}msg;
        s{\n\s*(\/\/.*?|\/\*.*?\*\/)?\s*getSubtotal\(line:\s*any\).*?^\s*\}\n}{}msg;
        s{(\n\s*\}\s*$)}
          {
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
          \n
          getSubtotal(line: any): number {
            const quantity = line && typeof line.quantity === "number" ? line.quantity : 0;
            const unitPrice = line && typeof line.unitPrice === "number" ? line.unitPrice : 0;
            return quantity * unitPrice;
          }
        $1}m;
    ' "$file"
    echo -e "${GREEN}      ✓ Getters synchrones assurés.${NC}"

    # 3. Ajouter onProductSelected
    echo "    [3/6] Ajout onProductSelected..."
    if ! grep -q "onProductSelected(event: Event, index: number)" "$file"; then
        perl -i -0777 -pe '
          s{
            (^\s*addProductLine\(\):\s*void\s*\{)
          }
          {
            qq{\n
              onProductSelected(event: Event, index: number): void {
                const selectElement = event.target as HTMLSelectElement;
                const productId = selectElement.value;
                const productLine = this.productsFormArray.at(index);

                if (!productId || !productLine) {
                  productLine?.patchValue({ unitPrice: 0 });
                  return;
                }
                const selectedProduct = this.productList.find(p => p.id === productId);
                if (selectedProduct) {
                  productLine.patchValue({ unitPrice: selectedProduct.price });
                } else {
                  productLine.patchValue({ unitPrice: 0 });
                  console.warn(`Produit non trouvé dans productList: ${productId}`);
                }
              }
              \n\n
            } . $1
          }me;
        ' "$file"
        echo -e "${GREEN}      ✓ Méthode onProductSelected ajoutée.${NC}"
    else
        echo -e "${YELLOW}      ✓ Méthode onProductSelected déjà présente.${NC}"
    fi

    # 4. Réécrire le bloc .map() dans onSubmit
    echo "    [4/6] Réécriture du bloc .map() dans onSubmit..."
     perl -i -0777 -pe "
       s{
         (formValue\.products\.map\(\s*\(\s*p\s*:\s*any\s*\)\s*=>\s*)
         .*? # Ancien contenu
         (\)\s*;\s*\n) # Fin de l'instruction map
       }
       {\$1 . # Colle le début capturé
         qq{{\n} .
         qq{      const product = this.productList.find(prod => prod.id === p.productId);\n} .
         qq{      const productName = product ? product.name : 'Produit_Inconnu';\n} .
         qq{      const description = product ? (product.description \|\| 'Pas_de_description') : 'Pas_de_description';\n} .
         qq{      const subtotal = (p.quantity \|\| 0) * (p.unitPrice \|\| 0);\n} .
         qq{\n} .
         qq{      return {\n} .
         qq{        ...p,\n} .
         qq{        productName: productName,\n} .
         qq{        description: description,\n} .
         qq{        subtotal: subtotal,\n} .
         qq{      };\n} .
         qq{    })} . # Fin de la fonction map et de l appel à map()
         \$2 # Colle la fin capturée
       }smeg;
     " "$file"
    echo -e "${GREEN}      ✓ Bloc .map() dans onSubmit réécrit.${NC}"

    # 5. Ajouter toggleExpand
    echo "    [5/6] Ajout toggleExpand..."
     if ! grep -q "toggleExpand(" "$file"; then
         perl -i -0777 -pe "
             s{(\n\s*\}\s*\$)} # Avant la dernière accolade
              {
                \n
                toggleExpand(itemId: string): void {
                  this.${expanded_prop} = this.${expanded_prop} === itemId ? null : itemId;
                }
              \$1}m;
         " "$file"
         echo -e "${GREEN}      ✓ Méthode toggleExpand ajoutée.${NC}"
     else
          echo -e "${YELLOW}      ✓ Méthode toggleExpand déjà présente.${NC}"
     fi

     # 6. Ajouter méthodes printList et printItem (squelettes)
     echo "    [6/6] Ajout squelettes printList et printItem..."
      if ! grep -q "printList(): void" "$file"; then
         perl -i -0777 -pe "
            s{(\n\s*\}\s*\$)} # Avant la dernière accolade
            {
              # --- Print Methods ---
              \n
              printList(): void {
                this.filtered${model_name}s\$.pipe(take(1)).subscribe(items => {
                  if (!items || items.length === 0) {
                    alert('Aucun élément à imprimer.');
                    return;
                  }
                  this.generatePrintHTML(items);
                });
              }
              \n
              printItem(item: any): void {
                 this.filtered${model_name}s\$.pipe(take(1)).subscribe(items => {
                    if (!items) return;
                    const singleItem = items.find((v) => v.id === item.id);
                    if (!singleItem) return;
                    console.log('Impression item individuel demandé pour: ', singleItem);
                    alert('Logique printItem à vérifier/compléter dans le code source.');
                 });
              }
              \n
              generatePrintHTML(items: ${model_name}[]): void {
                 console.log('Génération HTML pour impression liste: ', items);
                 alert('Logique generatePrintHTML à vérifier/compléter dans le code source.');
              }

            \$1}m;
         " "$file"
         echo -e "${GREEN}      ✓ Squelettes printList/printItem/generatePrintHTML ajoutés (vérifiez le code!).${NC}"
      else
           echo -e "${YELLOW}      ✓ Méthodes printList/printItem déjà présentes.${NC}"
      fi
}

# --- Fonction pour modifier le fichier HTML ---
modify_template_html() {
    local file=$1
    local component_name=$2
    local expanded_prop=$3
    local item_var=$4
    local model_name_plural=$5
    local number_prop=$6
    local related_entity=$7
    local edit_method="edit${model_name_plural^}"
    local delete_method="delete${model_name_plural^}"

    echo "  → Modification du template $component_name ($file)..."
    cp "$file" "$file.bak.harmonize_v3" # Backup

    # 1. Ajouter (change) au select productId dans le formulaire
    echo "    [1/3] Ajout (change) au select produit..."
    if ! grep -q '(change)="onProductSelected($event, i)"' "$file"; then
      perl -i -pe '
        s{(<select\s+formControlName="productId"\s*.*?)(>)
         }
         {$1 . q{ (change)="onProductSelected($event, i)"} . $2
         }ge;
      ' "$file"
      echo -e "${GREEN}      ✓ Événement (change) ajouté.${NC}"
    else
        echo -e "${YELLOW}      ✓ Événement (change) déjà présent.${NC}"
    fi

    # 2. Remplacer la structure d'affichage principale par Accordion
    echo "    [2/3] Application structure Accordion..."
    perl -i -0777 -pe 's{<table.*?<tbody.*?<\/tbody>\s*<\/table>}{}sx;' "$file"
    perl -i -0777 -pe 's{<div\s+\*ngIf="!isLoading"\s+class="space-y-4">.*?<\/div>\s*(<div\s+\*ngIf="\(\w+\$\s*\|\s*async\)\?\.length\s*===\s*0".*?<\/div>)}{$1}sx;' "$file"

     perl -i -0777 -pe '
        # CORRECTION: Suppression des commentaires internes qui causaient l erreur shell
        s{(</button>\s*</div>\s*</div>\s*(?:|)?)}
         {$1\n\n  \n  <div *ngIf="!isLoading" class="space-y-4">\n    \n\n    \n    <div *ngIf="(filtered'${model_name_plural}'$ | async)?.length === 0" class="text-center py-8 text-gray-500">\n      Aucun élément trouvé.\n    </div>\n\n  </div>\n}s;

        s{()}
         {
          <div *ngFor="let '$item_var' of filtered'${model_name_plural}'$ | async" class="bg-white shadow rounded-lg overflow-hidden voucher-card" [attr.data-id]="'$item_var'.id">
            <div class="px-6 py-4 flex justify-between items-center cursor-pointer hover:bg-gray-50"
                 (click)="toggleExpand('$item_var'.id!)">
              <div class="flex-1 grid grid-cols-5 gap-4">
                <div><strong>N° :</strong> {{ '$item_var'.'$number_prop' }}</div>
                <div><strong>Date:</strong> {{ formatDate('$item_var'.date) }}</div>
                <div><strong>'$related_entity':</strong> {{ '$item_var'.'$related_entity' }}</div>
                <div>
                    <span *ngIf="'$item_var'.status" [ngClass]="getStatusClass('$item_var'.status)" class="px-2 py-1 rounded text-xs">{{ getStatusLabel('$item_var'.status) }}</span>
                </div>
                <div><strong>Total:</strong> {{ '$item_var'.totalAmount | number:\x271.2-2\x27 }} DT</div>
              </div>
              <button class="text-blue-600 no-print">{{ '$expanded_prop' === '$item_var'.id ? \x27▼\x27 : \x27►\x27 }}</button>
            </div>

            <div *ngIf="'$expanded_prop' === '$item_var'.id" class="px-6 py-4 bg-gray-50 border-t">
              <table class="min-w-full">
                <thead class="bg-gray-100">
                  <tr>
                    <th class="px-4 py-2 text-left text-sm">Produit</th>
                    <th class="px-4 py-2 text-left text-sm">Description</th>
                    <th class="px-4 py-2 text-left text-sm">Quantité</th>
                    <th class="px-4 py-2 text-left text-sm">Prix Unit.</th>
                    <th class="px-4 py-2 text-left text-sm">Sous-total</th>
                  </tr>
                </thead>
                <tbody>
                  <tr *ngFor="let line of '$item_var'?.products" class="border-t">
                    <td class="px-4 py-2">{{ line.productName }}</td>
                    <td class="px-4 py-2 text-xs text-gray-600">{{ line.description }}</td>
                    <td class="px-4 py-2">{{ line.quantity }}</td>
                    <td class="px-4 py-2">{{ line.unitPrice | number:\x271.2-2\x27 }} DT</td>
                    <td class="px-4 py-2 font-semibold">{{ line.subtotal | number:\x271.2-2\x27 }} DT</td>
                  </tr>
                  <tr class="bg-blue-50 font-bold">
                    <td colspan="4" class="px-4 py-2 text-right">Total :</td>
                    <td class="px-4 py-2 text-blue-600">{{ '$item_var'.totalAmount | number:\x271.2-2\x27 }} DT</td>
                  </tr>
                </tbody>
              </table>
              <div class="mt-4 flex gap-2 no-print">
                 <button (click)="'$edit_method'('$item_var')" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded">Modifier</button>
                 <button (click)="'$delete_method'('$item_var'.id!, '$item_var'.'$number_prop')" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded">Supprimer</button>
                 <button (click)="printItem('$item_var')" class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded">Imprimer</button>
              </div>
            </div>
          </div>
         }s;
    ' "$file"
    echo -e "${GREEN}      ✓ Structure Accordion appliquée (vérification manuelle INDISPENSABLE).${NC}"

    # 3. Remplacer les appels de fonction dans l'expansion
    echo "    [3/3] Remplacement appels de fonction dans expansion..."
    perl -i -0777 -pe '
      s{
        (\*ngIf="'$expanded_prop'\s*===\s*'$item_var'\.id".*?<tbody.*?>)
        (.*?) # Contenu tbody
        (<\/tbody>)
      }
      {
        my $start = $1;
        my $content = $2;
        my $end = $3;
        $content =~ s/\{\{\s*getProductName\(line\.productId\)\s*\}\}/{{ line.productName }}/g;
        $content =~ s/\{\{\s*getDescription\(line\.productId\)\s*\}\}/{{ line.description }}/g;
        $content =~ s/\{\{\s*getSubtotal\(line\)\s*\|\s*number:\s*'\''1\.2-2'\''\s*\}\}/{{ line.subtotal | number:\x271.2-2\x27 }}/g;
        $start . $content . $end;
      }gsex;
    ' "$file"
    echo -e "${GREEN}      ✓ Appels de fonction remplacés par accès direct.${NC}"

}


# --- Traitement Purchase Order ---
echo -e "\n${YELLOW}[1/2] Traitement de PurchaseOrderComponent...${NC}"
modify_component_ts \
    "./src/app/components/purchase-order/purchase-order.component.ts" \
    "PurchaseOrderComponent" \
    "Order" \
    "ordersService" \
    "orderNumber" \
    "supplier" \
    "suppliersService" \
    "suppliers$" \
    "expandedOrderId"

modify_template_html \
    "./src/app/components/purchase-order/purchase-order.component.html" \
    "PurchaseOrderComponent" \
    "expandedOrderId" \
    "order" \
    "Orders" \
    "orderNumber" \
    "supplier"


# --- Traitement Devis ---
echo -e "\n${YELLOW}[2/2] Traitement de DevisComponent...${NC}"
modify_component_ts \
    "./src/app/components/devis/devis.component.ts" \
    "DevisComponent" \
    "Devis" \
    "devisService" \
    "quoteNumber" \
    "customer" \
    "customersService" \
    "customers$" \
    "expandedDevisId"

modify_template_html \
    "./src/app/components/devis/devis.component.html" \
    "DevisComponent" \
    "expandedDevisId" \
    "devis" \
    "Devis" \
    "quoteNumber" \
    "customer"


echo -e "\n${GREEN}=== Script Terminé (Corrigé V2) ===${NC}"
# --- MESSAGES ECHO CORRIGÉS ---
echo "**ACTIONS REQUISES :**"
echo "1. Vérifiez attentivement les fichiers .ts et .html modifiés pour corriger toute erreur syntaxique éventuelle."
echo "2. Assurez-vous que les noms des méthodes (\`editOrder\`/\`deleteOrder\`, \`editDevis\`/\`deleteDevis\`) et les variables (\`filteredOrders\$\`, \`filteredDevis\$\`) correspondent bien à votre code existant dans les templates HTML."
echo "3. La structure HTML de l'accordion a été insérée; vérifiez qu'elle s'intègre correctement et adaptez les classes CSS ou la structure si nécessaire."
echo "4. Implémentez/Adaptez la logique des méthodes \`printItem\` et \`generatePrintHTML\` dans les deux composants (.ts)."
echo "Relancez 'ng serve' après vérification."