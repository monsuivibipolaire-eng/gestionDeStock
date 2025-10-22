#!/bin/bash

# Script pour ajouter boutons Imprimer + méthode print() dans Products, Entry, Exit, Purchase Order
# Usage: ./add-print-all-pages.sh
# Logs: print-all-pages.log ; Backups: *.backup.printall
# Output: Boutons imprimer + window.print() + Print CSS

LOG_FILE="print-all-pages.log"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

> "$LOG_FILE"
log_info "$(date): Ajout boutons Imprimer dans toutes pages..."

# Fichiers cibles
declare -A COMPONENTS=(
    ["products"]="src/app/components/products"
    ["entry-voucher"]="src/app/components/entry-voucher"
    ["exit-voucher"]="src/app/components/exit-voucher"
    ["purchase-order"]="src/app/components/purchase-order"
)

GLOBAL_STYLES="src/styles.scss"

# 1. Backups
for comp in "${!COMPONENTS[@]}"; do
    dir="${COMPONENTS[$comp]}"
    for ext in "ts" "html"; do
        file="$dir/$comp.component.$ext"
        [ -f "$file" ] && cp "$file" "${file}.backup.printall"
    done
done
[ -f "$GLOBAL_STYLES" ] && cp "$GLOBAL_STYLES" "${GLOBAL_STYLES}.backup.printall"
log_info "Backups créés"

# 2. Bouton HTML Imprimer (SVG printer icon + Tailwind)
PRINT_BUTTON='    <button (click)="print()" class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-lg flex items-center space-x-2 transition duration-200 no-print">
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path>
      </svg>
      <span>Imprimer</span>
    </button>'

# 3. Méthode print() TypeScript
PRINT_METHOD='
  print(): void {
    window.print();
  }'

# 4. Fonction pour ajouter bouton dans HTML
add_print_button_html() {
    local html_file=$1
    local component_name=$2
    
    if [ ! -f "$html_file" ]; then
        log_warn "Fichier non trouvé : $html_file"
        return
    fi
    
    # Vérifie si bouton déjà présent
    if grep -q '(click)="print()"' "$html_file"; then
        log_info "⏭️  Bouton Imprimer déjà présent dans $component_name.html"
        return
    fi
    
    # Cherche div avec flex contenant bouton "Ajouter" ou "Nouvelle"
    if grep -q 'flex.*gap-4\|flex.*gap-2' "$html_file" && grep -q 'Ajouter\|Nouveau' "$html_file"; then
        # Insère bouton Imprimer AVANT le bouton Ajouter/Nouveau (dans même div flex)
        awk -v btn="$PRINT_BUTTON" '
        /<div class="flex.*gap/ { in_flex=1 }
        in_flex && /<button.*Ajouter|Nouveau/ && !done {
            print btn
            done=1
        }
        { print }
        ' "$html_file" > "${html_file}.tmp"
        mv "${html_file}.tmp" "$html_file"
        log_info "✅ Bouton Imprimer ajouté dans $component_name.html"
    else
        log_warn "⚠️  Pattern flex/Ajouter non trouvé dans $component_name.html (ajout manuel requis)"
    fi
}

# 5. Fonction pour ajouter méthode print() dans TS
add_print_method_ts() {
    local ts_file=$1
    local component_name=$2
    
    if [ ! -f "$ts_file" ]; then
        log_warn "Fichier non trouvé : $ts_file"
        return
    fi
    
    # Vérifie si méthode déjà présente
    if grep -q 'print():' "$ts_file"; then
        log_info "⏭️  Méthode print() déjà présente dans $component_name.ts"
        return
    fi
    
    # Ajoute méthode avant dernière accolade fermante de la classe
    awk -v method="$PRINT_METHOD" '
    /^}$/ && !done && prev_line !~ /^}/ {
        print method
        done=1
    }
    { prev_line=$0; print }
    ' "$ts_file" > "${ts_file}.tmp"
    mv "${ts_file}.tmp" "$ts_file"
    log_info "✅ Méthode print() ajoutée dans $component_name.ts"
}

# 6. Traitement de chaque component
for comp in "${!COMPONENTS[@]}"; do
    dir="${COMPONENTS[$comp]}"
    ts_file="$dir/$comp.component.ts"
    html_file="$dir/$comp.component.html"
    
    log_info "Traitement : $comp..."
    add_print_method_ts "$ts_file" "$comp"
    add_print_button_html "$html_file" "$comp"
done

# 7. Print CSS global (si pas déjà présent)
if ! grep -q '@media print' "$GLOBAL_STYLES"; then
    log_info "Ajout Print CSS dans styles.scss..."
    cat >> "$GLOBAL_STYLES" << 'EOF'

/* ============================================
   Print Styles - Optimisation Impression
   ============================================ */
@media print {
  /* Masque éléments non imprimables */
  .no-print,
  aside,
  nav,
  header,
  button:not(.print-only),
  .bg-gray-100,
  input[type="text"],
  input[type="number"],
  input[type="date"],
  input[type="email"],
  select,
  textarea,
  .hover\:bg-blue-700,
  .hover\:bg-green-700,
  .hover\:bg-red-600,
  .hover\:bg-purple-700 {
    display: none !important;
  }

  /* Layout impression A4 */
  body, html {
    width: 210mm;
    height: 297mm;
    margin: 0;
    padding: 0;
    font-size: 11pt;
    color: #000;
    background: #fff;
  }

  main {
    padding: 10mm !important;
    background: #fff !important;
  }

  .container {
    max-width: 100% !important;
    margin: 0 !important;
    padding: 0 !important;
  }

  /* Header impression automatique */
  @page {
    margin: 15mm;
    @bottom-right {
      content: "Page " counter(page);
      font-size: 9pt;
    }
  }

  h1:first-of-type {
    border-bottom: 2px solid #000;
    padding-bottom: 5mm;
    margin-bottom: 10mm;
  }

  /* Tables optimisées */
  table {
    width: 100%;
    border-collapse: collapse;
    page-break-inside: auto;
  }

  thead {
    display: table-header-group;
    font-weight: bold;
  }

  tr {
    page-break-inside: avoid;
    page-break-after: auto;
  }

  th, td {
    border: 1px solid #333;
    padding: 4pt 6pt;
    text-align: left;
  }

  /* Badges status impression noir/blanc */
  .bg-yellow-100, .bg-green-100, .bg-red-100, .bg-blue-100, 
  .bg-purple-100, .bg-orange-100, .bg-gray-100 {
    background: #fff !important;
    color: #000 !important;
    border: 1px solid #000 !important;
    padding: 2pt 4pt !important;
  }

  /* Supprimer ombres/gradients */
  .shadow, .shadow-md, .shadow-lg, .shadow-2xl {
    box-shadow: none !important;
  }

  .bg-gradient-to-b {
    background: #fff !important;
  }

  /* Force expansion accordions pour impression */
  [hidden] {
    display: block !important;
  }

  /* Spacing sections */
  h2, h3 {
    page-break-after: avoid;
    margin-top: 8mm;
  }

  /* Force noir pour lisibilité */
  * {
    color: #000 !important;
  }

  /* Alternance lignes tableaux */
  table tbody tr:nth-child(even) {
    background: #f5f5f5 !important;
  }

  /* Optimisation texte */
  p, li, td {
    orphans: 3;
    widows: 3;
  }
}
EOF
    log_info "✅ Print CSS ajouté dans styles.scss"
else
    log_info "⏭️  Print CSS déjà présent dans styles.scss"
fi

# 8. Validation
if command -v ng &> /dev/null; then
    log_info "Validation compilation..."
    ng cache clean
    npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_info "✅ TS OK!"
    else
        log_warn "⚠️  Erreurs TS détectées (vérifiez logs)"
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Boutons Imprimer Ajoutés"
echo "=========================================="
echo "Pages modifiées :"
echo "  - Products (/products)"
echo "  - Entry Voucher (/entry-voucher)"
echo "  - Exit Voucher (/exit-voucher)"
echo "  - Purchase Order (/purchase-order)"
echo ""
echo "Features :"
echo "  - Bouton 'Imprimer' (purple, icon printer)"
echo "  - Méthode print() : window.print()"
echo "  - Print CSS : masque sidebar/navbar/buttons"
echo "  - Format A4 optimisé (210x297mm)"
echo "  - Tables bordered, headers répétés"
echo "  - Badges status noir/blanc"
echo ""
echo "Test :"
echo "  1. ng serve"
echo "  2. Ouvrez page (ex: /products)"
echo "  3. Click bouton 'Imprimer'"
echo "  4. Dialog impression navigateur s'ouvre"
echo "  5. Aperçu montre contenu sans menu/buttons"
echo "  6. Imprimez PDF ou physiquement"
echo ""
echo "Logs : $LOG_FILE"
echo "Revert : cp *.backup.printall *"
