#!/bin/bash

# Script pour remplacer la méthode printItem dans ExitVoucherComponent
# avec la version complète pour l'impression individuelle.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== Correction Méthode printItem (Bon de Sortie) ===${NC}\n"

TS_FILE="./src/app/components/exit-voucher/exit-voucher.component.ts"
COMPONENT_NAME="ExitVoucherComponent"

# --- Vérifier le fichier ---
if [ ! -f "$TS_FILE" ]; then
    echo -e "${RED}ERREUR: Fichier $TS_FILE introuvable.${NC}"
    exit 1
fi

# --- Créer backup ---
echo "  → Création backup ($TS_FILE.bak.printitem_exit)..."
cp "$TS_FILE" "$TS_FILE.bak.printitem_exit"

# --- Contenu correct de la méthode printItem pour ExitVoucher ---
read -r -d '' CORRECT_PRINT_ITEM << 'EOF'
  printItem(item: any): void {
    // Use take(1) to get the current list snapshot
    this.filteredVouchers$.pipe(take(1)).subscribe((vouchers) => {
      // Find the specific voucher from the filtered list
      const voucher = vouchers.find((v) => v.id === item.id);
      if (!voucher) {
        console.error('Bon de sortie non trouvé pour impression:', item.id);
        alert('Erreur : Bon de sortie non trouvé.');
        return;
      }

      const printWindow = window.open('', '_blank', 'width=800,height=600');
      if (!printWindow) {
        alert('❌ Popup bloquée ! Veuillez autoriser les popups pour ce site.');
        return;
      }

      // Generate HTML for the single exit voucher
      const productRows = voucher.products.map(p => `
        <tr>
          <td>\${p.productName || 'N/A'}</td>
          <td class="description">\${this.getDescription(p.productId)}</td> {/* Use the helper method */}
          <td>\${p.quantity || 0}</td>
          <td>\${(p.unitPrice || 0).toFixed(2)} DT</td>
          <td>\${(p.subtotal || 0).toFixed(2)} DT</td>
        </tr>
      `).join('');

      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Bon de Sortie \${voucher.voucherNumber}</title>
          <style>
            /* Basic print styles - adapt colors if needed */
            body { font-family: Arial, sans-serif; padding: 20px; font-size: 10pt; }
            h1 { text-align: center; border-bottom: 2px solid #000; margin-bottom: 20px; padding-bottom: 10px; }
            .details-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
            .details-table th, .details-table td { padding: 8px; border: 1px solid #ddd; text-align: left; }
            .details-table th { background: #f3f4f6; width: 30%; }
            .products-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
            .products-table th, .products-table td { padding: 8px; border: 1px solid #ddd; text-align: left; }
            .products-table th { background: #f3f4f6; }
            .products-table tfoot th, .products-table tfoot td { font-weight: bold; background: #fee2e2; } /* Light red footer */
            .description { font-size: 9pt; color: #555; font-style: italic; max-width: 200px; word-wrap: break-word; }
            .total-amount { color: #dc2626; } /* Red total */
          </style>
        </head>
        <body>
          <h1>Bon de Sortie N° \${voucher.voucherNumber}</h1>
          <table class="details-table">
            <tr><th>Date</th><td>\${this.formatDate(voucher.date)}</td></tr>
            <tr><th>Client</th><td>\${voucher.customer}</td></tr>
            \${voucher.destination ? `<tr><th>Destination</th><td>\${voucher.destination}</td></tr>` : ''}
            \${voucher.notes ? `<tr><th>Notes</th><td>\${voucher.notes}</td></tr>` : ''}
          </table>

          <h3>Produits</h3>
          <table class="products-table">
            <thead>
              <tr>
                <th>Produit</th>
                <th>Description</th>
                <th>Quantité</th>
                <th>Prix Unit.</th>
                <th>Sous-total</th>
              </tr>
            </thead>
            <tbody>
              \${productRows}
            </tbody>
            <tfoot>
              <tr>
                <th colspan="4" style="text-align: right;">Total</th>
                <td class="total-amount">\${(voucher.totalAmount || 0).toFixed(2)} DT</td>
              </tr>
            </tfoot>
          </table>
        </body>
        </html>
      `;

      printWindow.document.write(html);
      printWindow.document.close(); // Important for some browsers

      // Use setTimeout to allow the content to render before printing
      setTimeout(() => {
        printWindow.focus(); // Ensure the window has focus
        printWindow.print();
        // printWindow.close(); // Optionally close after printing
      }, 250); // Delay may need adjustment
    });
  }
EOF

# --- Remplacer la méthode dans le fichier TypeScript ---
echo "  → Remplacement de la méthode printItem dans $COMPONENT_NAME ($TS_FILE)..."

# Utiliser perl pour remplacer toute la méthode printItem existante
perl -i -0777 -pe "
s{^\s*(async\s+)?printItem\(item:\s*any\):\s*void\s*\{.*?^\s*\}\n} # Trouve l'ancienne méthode (flexible)
{\$ENV{CORRECT_PRINT_ITEM}\n}smg # Remplace par la nouvelle méthode
" --export-var=CORRECT_PRINT_ITEM "$TS_FILE"

# Vérification (simple : cherche une ligne clé de la nouvelle méthode)
if grep -q "const voucher = vouchers.find((v) => v.id === item.id);" "$TS_FILE" && grep -q "<title>Bon de Sortie" "$TS_FILE"; then
    echo -e "${GREEN}    ✓ Méthode printItem remplacée avec succès.${NC}"
else
    echo -e "${RED}    ✗ Échec du remplacement de la méthode printItem. Vérification manuelle requise.${NC}"
    echo -e "      Assurez-vous que la méthode printItem(item: any): void {...} est correcte dans le fichier."
fi

echo -e "\n${GREEN}=== Script Terminé ===${NC}"
echo "La méthode 'printItem' dans '$TS_FILE' a été mise à jour pour les Bons de Sortie."
echo "Des backups (.bak.printitem_exit) ont été créés."
echo "Vérifiez les modifications et relancez 'ng serve'."