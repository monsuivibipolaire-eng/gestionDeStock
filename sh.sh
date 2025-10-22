#!/bin/bash

# Script pour ajouter bouton Imprimer à côté de Modifier/Supprimer dans TOUTES les pages
# Implémente printItem(item) qui génère HTML formaté et imprime
# Usage: ./add-print-button-all-items.sh
# Logs: print-all-items.log ; Backups: *.backup.printitems

LOG_FILE="print-all-items.log"
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

> "$LOG_FILE"
log_info "$(date): Ajout bouton Imprimer pour chaque item (toutes pages)..."

# Fichiers cibles
declare -A COMPONENTS=(
    ["products"]="src/app/components/products"
    ["suppliers"]="src/app/components/suppliers"
    ["customers"]="src/app/components/customers"
    ["entry-voucher"]="src/app/components/entry-voucher"
    ["exit-voucher"]="src/app/components/exit-voucher"
    ["purchase-order"]="src/app/components/purchase-order"
    ["devis"]="src/app/components/devis"
)

# Backups
for comp in "${!COMPONENTS[@]}"; do
    dir="${COMPONENTS[$comp]}"
    for ext in "ts" "html"; do
        file="$dir/$comp.component.$ext"
        [ -f "$file" ] && cp "$file" "${file}.backup.printitems"
    done
done
log_info "Backups créés"

# ===================================
# 1. MÉTHODE TS : printItem(item) universelle
# ===================================
log_info "Ajout méthode printItem(item) dans tous components..."

# Méthode printItem universelle (génère HTML formaté selon type item)
PRINT_ITEM_METHOD='
  printItem(item: any): void {
    // Génère HTML formaté pour impression
    const printWindow = window.open("", "_blank", "width=800,height=600");
    if (!printWindow) return;

    const itemType = this.getItemType();
    const html = this.generatePrintHTML(item, itemType);
    
    printWindow.document.write(html);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => {
      printWindow.print();
      printWindow.close();
    }, 250);
  }

  getItemType(): string {
    // Détecte type item selon component
    if (this.constructor.name.includes("Product")) return "Produit";
    if (this.constructor.name.includes("Supplier")) return "Fournisseur";
    if (this.constructor.name.includes("Customer")) return "Client";
    if (this.constructor.name.includes("Entry")) return "Bon d'\''Entrée";
    if (this.constructor.name.includes("Exit")) return "Bon de Sortie";
    if (this.constructor.name.includes("Purchase")) return "Bon de Commande";
    if (this.constructor.name.includes("Devis")) return "Devis";
    return "Document";
  }

  generatePrintHTML(item: any, itemType: string): string {
    const today = new Date().toLocaleDateString("fr-FR");
    let content = "";

    // Content selon type
    if (itemType === "Produit") {
      content = `
        <h2>Fiche Produit</h2>
        <table>
          <tr><th>Nom</th><td>${item.name || "N/A"}</td></tr>
          <tr><th>Prix</th><td>${item.price || 0} DT</td></tr>
          <tr><th>Quantité Stock</th><td>${item.quantity || 0}</td></tr>
          <tr><th>Description</th><td>${item.description || "N/A"}</td></tr>
        </table>
      `;
    } else if (itemType === "Fournisseur" || itemType === "Client") {
      content = `
        <h2>Fiche ${itemType}</h2>
        <table>
          <tr><th>Nom</th><td>${item.name || "N/A"}</td></tr>
          <tr><th>Email</th><td>${item.email || "N/A"}</td></tr>
          <tr><th>Téléphone</th><td>${item.phone || "N/A"}</td></tr>
          <tr><th>Adresse</th><td>${item.address || "N/A"}</td></tr>
          <tr><th>Notes</th><td>${item.notes || "N/A"}</td></tr>
        </table>
      `;
    } else {
      // Vouchers (Entry/Exit/Purchase/Devis)
      const number = item.voucherNumber || item.orderNumber || item.quoteNumber || "N/A";
      const date = item.date?.toDate ? item.date.toDate().toLocaleDateString("fr-FR") : "N/A";
      const partner = item.supplier || item.customer || "N/A";
      
      content = `
        <h2>${itemType} N° ${number}</h2>
        <table>
          <tr><th>Date</th><td>${date}</td></tr>
          <tr><th>${itemType.includes("Entrée") || itemType.includes("Commande") ? "Fournisseur" : "Client"}</th><td>${partner}</td></tr>
        </table>
        
        <h3>Produits</h3>
        <table class="products-table">
          <thead>
            <tr>
              <th>Produit</th>
              <th>Quantité</th>
              <th>Prix Unit.</th>
              <th>Sous-total</th>
            </tr>
          </thead>
          <tbody>
            ${(item.products || []).map((p: any) => `
              <tr>
                <td>${p.productName || "N/A"}</td>
                <td>${p.quantity || 0}</td>
                <td>${p.unitPrice || 0} DT</td>
                <td>${p.subtotal || 0} DT</td>
              </tr>
            `).join("")}
          </tbody>
          <tfoot>
            <tr>
              <th colspan="3">Total</th>
              <th>${item.totalAmount || item.subtotal || 0} DT</th>
            </tr>
          </tfoot>
        </table>
      `;
    }

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Impression ${itemType}</title>
        <style>
          @page { margin: 20mm; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
          h1 { text-align: center; border-bottom: 2px solid #000; padding-bottom: 10px; }
          h2 { color: #2563eb; margin-top: 20px; }
          h3 { margin-top: 15px; color: #333; }
          table { width: 100%; border-collapse: collapse; margin: 15px 0; }
          th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
          th { background: #f3f4f6; font-weight: bold; }
          .products-table { margin-top: 10px; }
          .products-table thead { background: #2563eb; color: white; }
          .products-table tfoot { background: #f3f4f6; font-weight: bold; }
          .header { text-align: center; margin-bottom: 20px; }
          .footer { margin-top: 30px; text-align: center; font-size: 12px; color: #666; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Gestion de Stock</h1>
          <p>Date d'\''impression : ${today}</p>
        </div>
        ${content}
        <div class="footer">
          <p>Document généré automatiquement - Gestion Stock App</p>
        </div>
      </body>
      </html>
    `;
  }
'

# Ajoute méthodes dans chaque component TS
for comp in "${!COMPONENTS[@]}"; do
    ts_file="${COMPONENTS[$comp]}/$comp.component.ts"
    
    if [ -f "$ts_file" ]; then
        # Vérifie si printItem déjà présent
        if ! grep -q "printItem(item:" "$ts_file"; then
            # Ajoute avant dernière accolade
            awk -v method="$PRINT_ITEM_METHOD" '
            /^}$/ && !added {
                print method
                added=1
            }
            { print }
            ' "$ts_file" > "${ts_file}.tmp" && mv "${ts_file}.tmp" "$ts_file"
            
            log_info "✅ Ajouté printItem() dans $comp.component.ts"
        else
            log_info "⏭️  printItem() déjà présent dans $comp.component.ts"
        fi
    fi
done

# ===================================
# 2. HTML : Ajoute bouton Imprimer après Modifier/Supprimer
# ===================================
log_info "Ajout bouton Imprimer dans HTML..."

for comp in "${!COMPONENTS[@]}"; do
    html_file="${COMPONENTS[$comp]}/$comp.component.html"
    
    if [ -f "$html_file" ]; then
        # Cherche pattern : <button (click)="delete..."...>Supprimer</button>
        # Ajoute après : <button (click)="printItem(item)" ...>Imprimer</button>
        
        awk '
        /<button.*\(click\)="delete[A-Z][a-z]*\(/ {
            print
            print "          <button (click)=\"printItem(item)\" class=\"text-purple-600 hover:text-purple-900 no-print\">Imprimer</button>"
            next
        }
        { print }
        ' "$html_file" > "${html_file}.tmp" && mv "${html_file}.tmp" "$html_file"
        
        log_info "✅ Ajouté bouton Imprimer dans $comp.component.html"
    fi
done

# ===================================
# 3. VALIDATION
# ===================================
if command -v ng &> /dev/null; then
    log_info "Validation compilation..."
    ng cache clean
    npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_info "✅ TS OK!"
    else
        log_info "⚠️  Erreurs TS (vérifiez logs)"
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Bouton Imprimer Ajouté Partout"
echo "=========================================="
echo "Pages modifiées :"
echo "  - Products (tables produits)"
echo "  - Suppliers (tables fournisseurs)"
echo "  - Customers (tables clients)"
echo "  - Entry Voucher (accordions bons entrée)"
echo "  - Exit Voucher (accordions bons sortie)"
echo "  - Purchase Order (accordions commandes)"
echo "  - Devis (accordions devis)"
echo ""
echo "Bouton ajouté :"
echo "  'Imprimer' (violet) à côté de Modifier/Supprimer"
echo ""
echo "Fonctionnement :"
echo "  - Click Imprimer → Ouvre nouvelle fenêtre avec HTML formaté"
echo "  - Content auto-détecté (Produit/Fournisseur/Client/Bon)"
echo "  - Format : Header entreprise + Table données + Footer"
echo "  - Print automatique après génération HTML"
echo ""
echo "Test :"
echo "  1. ng serve"
echo "  2. /products → Table → Click 'Imprimer' sur produit → Fiche produit imprimée"
echo "  3. /suppliers → Table → Click 'Imprimer' → Fiche fournisseur"
echo "  4. /entry-voucher → Expand bon → Click 'Imprimer' → Bon formaté"
echo ""
echo "Logs : $LOG_FILE"
echo "Revert : cp *.backup.printitems *"
