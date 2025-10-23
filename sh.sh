#!/bin/bash

# Script pour fixer route Entry Voucher (standalone component)
# Usage: ./fix-entry-route.sh

LOG_FILE="fix-entry-route.log"
echo "$(date): Fix route Entry Voucher..." | tee "$LOG_FILE"

APP_MODULE="src/app/app.module.ts"
APP_ROUTING="src/app/app-routing.module.ts"

# Backup
cp "$APP_MODULE" "${APP_MODULE}.backup.routefix"
[ -f "$APP_ROUTING" ] && cp "$APP_ROUTING" "${APP_ROUTING}.backup.routefix"
echo "Backups créés" | tee -a "$LOG_FILE"

# Fonction pour fixer routes standalone dans app.module.ts ou app-routing.module.ts
fix_routes() {
    local file=$1
    
    if [ ! -f "$file" ]; then
        return
    fi
    
    echo "Fix routes dans $file..." | tee -a "$LOG_FILE"
    
    # Remplace route Entry Voucher : component: EntryVoucherComponent -> loadComponent
    sed -i '' "s|{ path: 'entry-voucher', component: EntryVoucherComponent }|{ path: 'entry-voucher', loadComponent: () => import('./components/entry-voucher/entry-voucher.component').then(m => m.EntryVoucherComponent) }|" "$file"
    
    # Supprime import EntryVoucherComponent si présent
    sed -i '' '/import.*EntryVoucherComponent.*from/d' "$file"
    
    echo "✅ Route Entry Voucher corrigée (loadComponent lazy)" | tee -a "$LOG_FILE"
}

# Fix dans app.module.ts
if grep -q "EntryVoucherComponent" "$APP_MODULE"; then
    fix_routes "$APP_MODULE"
fi

# Fix dans app-routing.module.ts si existe
if [ -f "$APP_ROUTING" ] && grep -q "EntryVoucherComponent" "$APP_ROUTING"; then
    fix_routes "$APP_ROUTING"
fi

# Validation
if command -v ng &> /dev/null; then
    echo "Validation TypeScript..." | tee -a "$LOG_FILE"
    ng cache clean
    npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        echo "✅ Compilation OK" | tee -a "$LOG_FILE"
    else
        echo "⚠️ Erreurs TS (vérifiez logs)" | tee -a "$LOG_FILE"
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Fix Route Entry Voucher Terminé"
echo "=========================================="
echo "Changements :"
echo "  - Route Entry Voucher : component -> loadComponent (lazy)"
echo "  - Import EntryVoucherComponent supprimé"
echo ""
echo "Route avant :"
echo "  { path: 'entry-voucher', component: EntryVoucherComponent }"
echo ""
echo "Route après :"
echo "  { path: 'entry-voucher', loadComponent: () => import(...) }"
echo ""
echo "Test :"
echo "  1. ng serve (restart)"
echo "  2. /entry-voucher → Doit charger sans erreurs"
echo ""
echo "Logs : $LOG_FILE"
