#!/bin/bash

# Script universel pour corriger NG6008 : Move TOUS standalone components de declarations vers imports
# Usage: ./fix-all-ng6008-standalone.sh
# Logs: ng6008-all-fix.log ; Backup: app.module.ts.backup.ng6008all

APP_MODULE="src/app/app.module.ts"
LOG_FILE="ng6008-all-fix.log"

> "$LOG_FILE"
echo "$(date): Fix NG6008 ALL standalone components (declarations → imports)..." | tee -a "$LOG_FILE"

# Backup
if [ -f "$APP_MODULE" ]; then
  cp "$APP_MODULE" "${APP_MODULE}.backup.ng6008all"
  echo "BACKUP: $APP_MODULE" | tee -a "$LOG_FILE"
fi

# Liste des composants standalone connus (ajoutez si nouveaux)
STANDALONE_COMPONENTS=(
  "PurchaseOrderComponent"
  "ExitVoucherComponent"
  "EntryVoucherComponent"
  "ProductsComponent"
  "AuthComponent"
)

# Fix : Remove de declarations, add à imports
if [ -f "$APP_MODULE" ]; then
  # Supprime tous standalone components de declarations: []
  for component in "${STANDALONE_COMPONENTS[@]}"; do
    sed -i '' "/declarations: \[/,/\]/ s/${component},\{0,1\}//g" "$APP_MODULE"
    echo "REMOVED: $component de declarations" | tee -a "$LOG_FILE"
  done
  
  # Nettoie virgules traînantes en declarations
  sed -i '' '/declarations: \[/,/\]/ s/,,/,/g' "$APP_MODULE"
  sed -i '' '/declarations: \[/,/\]/ s/\[,/\[/g' "$APP_MODULE"
  sed -i '' '/declarations: \[/,/\]/ s/,\]/\]/g' "$APP_MODULE"
  sed -i '' '/declarations: \[/,/\]/ s/\[ \]/\[AppComponent\]/g' "$APP_MODULE"  # Garde AppComponent si vide
  
  # Ajoute standalone components à imports: [] (après provideFirestore ou RouterModule)
  if grep -q "provideFirestore" "$APP_MODULE"; then
    TARGET_LINE="provideFirestore"
  elif grep -q "RouterModule.forRoot" "$APP_MODULE"; then
    TARGET_LINE="RouterModule.forRoot"
  else
    TARGET_LINE="imports: \["
  fi
  
  # Check si déjà présents en imports (évite doublons)
  for component in "${STANDALONE_COMPONENTS[@]}"; do
    if ! grep -q "imports:.*$component" "$APP_MODULE" && ! grep -A20 "imports: \[" "$APP_MODULE" | grep -q "$component"; then
      sed -i '' "/$TARGET_LINE/a\\
    $component," "$APP_MODULE"
      echo "ADDED: $component à imports: []" | tee -a "$LOG_FILE"
    else
      echo "SKIPPED: $component déjà en imports" | tee -a "$LOG_FILE"
    fi
  done
  
  # Assure import statements en haut du fichier (si absents)
  COMPONENT_PATHS=(
    "PurchaseOrderComponent:./components/purchase-order/purchase-order.component"
    "ExitVoucherComponent:./components/exit-voucher/exit-voucher.component"
    "EntryVoucherComponent:./components/entry-voucher/entry-voucher.component"
    "ProductsComponent:./components/products/products.component"
    "AuthComponent:./components/auth/auth.component"
  )
  
  for item in "${COMPONENT_PATHS[@]}"; do
    component="${item%%:*}"
    path="${item##*:}"
    if ! grep -q "import.*$component" "$APP_MODULE"; then
      sed -i '' "/import { NgModule }/a\\
import { $component } from '$path';" "$APP_MODULE"
      echo "ADDED: import { $component }" | tee -a "$LOG_FILE"
    fi
  done
fi

# Validation
if command -v ng &> /dev/null; then
  ng cache clean
  echo "Validation..." | tee -a "$LOG_FILE"
  npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE" && echo "TS OK!" | tee -a "$LOG_FILE"
  ng build --configuration development 2>&1 | tee -a "$LOG_FILE" && echo "BUILD OK (no NG6008)!" | tee -a "$LOG_FILE" || {
    echo "Build échoué ; vérifiez errors:" | tee -a "$LOG_FILE"
    ng build --configuration development --verbose 2>&1 | grep -E "NG6008|ERROR" | tee -a "$LOG_FILE"
  }
fi

echo "Fix NG6008 ALL terminé ! Logs: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Test: ng serve → /purchase-order, /exit-voucher, /entry-voucher, /products, /auth (toutes routes OK)"
echo "Vérifiez: grep -A10 'declarations:' src/app/app.module.ts (doit avoir seulement AppComponent)"
echo "Vérifiez: grep -A25 'imports:' src/app/app.module.ts (doit inclure tous 5 standalone components)"
echo "Revert: cp ${APP_MODULE}.backup.ng6008all $APP_MODULE"
