#!/bin/bash

# Script pour corriger NG6008 : Move ExitVoucherComponent de declarations vers imports
# Usage: ./fix-ng6008-exit-voucher.sh
# Logs: ng6008-exit-fix.log ; Backup: app.module.ts.backup.ng6008exit

APP_MODULE="src/app/app.module.ts"
LOG_FILE="ng6008-exit-fix.log"

> "$LOG_FILE"
echo "$(date): Fix NG6008 ExitVoucherComponent (declarations → imports)..." | tee -a "$LOG_FILE"

# Backup
if [ -f "$APP_MODULE" ]; then
  cp "$APP_MODULE" "${APP_MODULE}.backup.ng6008exit"
  echo "BACKUP: $APP_MODULE" | tee -a "$LOG_FILE"
fi

# Fix : Remove de declarations, add à imports
if [ -f "$APP_MODULE" ]; then
  # Supprime ExitVoucherComponent de declarations: []
  sed -i '' '/declarations: \[/,/\]/ s/ExitVoucherComponent,\{0,1\}//g' "$APP_MODULE"
  echo "REMOVED: ExitVoucherComponent de declarations" | tee -a "$LOG_FILE"
  
  # Nettoie virgules traînantes
  sed -i '' '/declarations: \[/,/\]/ s/,,/,/g' "$APP_MODULE"
  sed -i '' '/declarations: \[/,/\]/ s/\[,/\[/g' "$APP_MODULE"
  sed -i '' '/declarations: \[/,/\]/ s/,\]/\]/g' "$APP_MODULE"
  
  # Ajoute à imports: [] (après EntryVoucherComponent si présent, sinon après RouterModule)
  if grep -q "EntryVoucherComponent," "$APP_MODULE"; then
    sed -i '' '/EntryVoucherComponent,/a\
    ExitVoucherComponent,' "$APP_MODULE"
  elif grep -q "RouterModule.forRoot" "$APP_MODULE"; then
    sed -i '' '/RouterModule.forRoot/a\
    ExitVoucherComponent,' "$APP_MODULE"
  else
    sed -i '' '/imports: \[/a\
    ExitVoucherComponent,' "$APP_MODULE"
  fi
  echo "ADDED: ExitVoucherComponent à imports: []" | tee -a "$LOG_FILE"
  
  # Assure import statement en haut du fichier
  if ! grep -q "import.*ExitVoucherComponent" "$APP_MODULE"; then
    sed -i '' '/import { NgModule }/a\
import { ExitVoucherComponent } from '\''./components/exit-voucher/exit-voucher.component'\'';' "$APP_MODULE"
    echo "ADDED: import { ExitVoucherComponent }" | tee -a "$LOG_FILE"
  fi
fi

# Validation
if command -v ng &> /dev/null; then
  ng cache clean
  npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE" && echo "TS OK!" | tee -a "$LOG_FILE"
  ng build --configuration development 2>&1 | tee -a "$LOG_FILE" && echo "BUILD OK (no NG6008)!" | tee -a "$LOG_FILE"
fi

echo "Fix NG6008 terminé ! Logs: $LOG_FILE"
echo "Test: ng serve → /exit-voucher (no NG6008 ; component loads)"
echo "Vérifiez: grep -A10 'declarations:' src/app/app.module.ts (seulement AppComponent)"
echo "Vérifiez: grep -A15 'imports:' src/app/app.module.ts (doit inclure ExitVoucherComponent)"
echo "Revert: cp ${APP_MODULE}.backup.ng6008exit $APP_MODULE"
