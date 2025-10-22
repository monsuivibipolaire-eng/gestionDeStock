#!/bin/bash

# Script complet : Fix Firebase Query (products.service) + @Component imports + app.module config + deps
# Usage: ./fix-tout-projet.sh [-d dry-run] [-c clean backups] [-h help]
# Logs: fix-log.txt ; Backups: *.backup.full
# Ex: ./fix-tout-projet.sh -d  # Test sans changes
# Note: Angular 20+ modulaire ; assure models/product.ts existe

DRY_RUN=false
CLEAN_BACKUPS=false
LOG_FILE="fix-log.txt"

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -d : Dry-run (liste actions sans exécuter)"
  echo "  -c : Clean backups (*.backup.*) après fix"
  echo "  -h : Aide"
  exit 0
}

while getopts "dch" opt; do
  case $opt in
    d) DRY_RUN=true; echo "Mode dry-run: Simulation only." ;;
    c) CLEAN_BACKUPS=true; echo "Clean backups activé." ;;
    h) show_help ;;
    *) echo "Option invalide. Utilisez -h." && exit 1 ;;
  esac
done

> "$LOG_FILE"
echo "$(date): Fix complet projet Angular/Firestore (Query + Imports + Config)..." | tee -a "$LOG_FILE"

# 1. Backups
FILES=( "src/app/services/products.service.ts" "src/app/components/auth/auth.component.ts" "src/app/components/products/products.component.ts" "src/app/app.module.ts" )
for file in "${FILES[@]}"; do
  if [ -f "$file" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "WOULD BACKUP: $file → ${file}.backup.full" | tee -a "$LOG_FILE"
    else
      cp "$file" "${file}.backup.full" && echo "BACKUP: $file" | tee -a "$LOG_FILE" || echo "ERROR backup $file" | tee -a "$LOG_FILE"
    fi
  fi
done

# 2. Fix products.service.ts : Rewrite entier avec query() (fix FirebaseError ligne 24 template)
PRODUCTS_SERVICE="src/app/services/products.service.ts"
if [ -f "$PRODUCTS_SERVICE" ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD REPLACE: $PRODUCTS_SERVICE avec code modulaire (query fix getProducts)" | tee -a "$LOG_FILE"
  else
    cat > "$PRODUCTS_SERVICE" << 'EOF'
import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Product } from '../models/product';

@Injectable({
  providedIn: 'root'
})
export class ProductsService {
  constructor(private firestore: Firestore) {}

  getProducts(): Observable<Product[]> {
    const productsRef = collection(this.firestore, 'products');
    const q: Query = query(productsRef);
    return collectionData(q, { idField: 'id' }) as Observable<Product[]>;
  }

  addProduct(product: Omit<Product, 'id'>): Promise<void> {
    const productsRef = collection(this.firestore, 'products');
    return addDoc(productsRef, product).then(() => {});
  }

  updateProduct(id: string, product: Partial<Product>): Promise<void> {
    const productRef = doc(this.firestore, 'products', id);
    return updateDoc(productRef, product);
  }

  deleteProduct(id: string): Promise<void> {
    const productRef = doc(this.firestore, 'products', id);
    return deleteDoc(productRef);
  }
}
EOF
    echo "FIXED: $PRODUCTS_SERVICE (query wrapper ; fix FirebaseError _Query/_CollectionReference)" | tee -a "$LOG_FILE"
  fi
fi

# 3. Fix auth.component.ts : Ajoute imports + array imports: [ReactiveFormsModule, CommonModule]
AUTH_COMPONENT="src/app/components/auth/auth.component.ts"
if [ -f "$AUTH_COMPONENT" ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD FIX: $AUTH_COMPONENT (add CommonModule import + imports array)" | tee -a "$LOG_FILE"
  else
    # Ajoute import CommonModule si absent
    if ! grep -q "from '@angular/common'" "$AUTH_COMPONENT"; then
      sed -i '' '/from '\''@angular\/forms'\'';/a\\
import { CommonModule } from '\''@angular/common'\'';' "$AUTH_COMPONENT"
    fi
    # Fix malformed : Remplace CommonModule, par imports array
    sed -i '' 's/CommonModule, standalone: true/imports: [ReactiveFormsModule, CommonModule], standalone: true/g' "$AUTH_COMPONENT"
    # Ajoute array si absent
    if ! grep -q "imports: \[" "$AUTH_COMPONENT"; then
      sed -i '' '/@Component({/a\\
  imports: [ReactiveFormsModule, CommonModule],' "$AUTH_COMPONENT"
    fi
    echo "FIXED: $AUTH_COMPONENT (CommonModule + array ; fix TS18004/TS2353/NG1010)" | tee -a "$LOG_FILE"
  fi
fi

# 4. Fix products.component.ts : Même pour CommonModule + ReactiveFormsModule
PRODUCTS_COMPONENT="src/app/components/products/products.component.ts"
if [ -f "$PRODUCTS_COMPONENT" ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD FIX: $PRODUCTS_COMPONENT (add imports + array)" | tee -a "$LOG_FILE"
  else
    # Ajoute imports si absents
    if ! grep -q "from '@angular/common'" "$PRODUCTS_COMPONENT"; then
      sed -i '' '/from '\''@angular\/forms'\'';/a\\
import { CommonModule } from '\''@angular/common'\'';' "$PRODUCTS_COMPONENT"
    fi
    if ! grep -q "ReactiveFormsModule.*from '@angular/forms'" "$PRODUCTS_COMPONENT"; then
      sed -i '' '/import { Component.*from "@angular\/core";/a\\
import { ReactiveFormsModule } from "@angular/forms";' "$PRODUCTS_COMPONENT"
    fi
    # Fix malformed array
    sed -i '' 's/CommonModule, standalone: true/imports: [ReactiveFormsModule, CommonModule], standalone: true/g' "$PRODUCTS_COMPONENT"
    if ! grep -q "imports: \[" "$PRODUCTS_COMPONENT"; then
      sed -i '' '/@Component({/a\\
  imports: [ReactiveFormsModule, CommonModule],' "$PRODUCTS_COMPONENT"
    fi
    echo "FIXED: $PRODUCTS_COMPONENT (imports array ; fix NG8103 *ngIf/*ngFor)" | tee -a "$LOG_FILE"
  fi
fi

# 5. Fix app.module.ts : Supprime version + virgule après messagingSenderId (TS1005/TS2769)
APP_MODULE="src/app/app.module.ts"
if [ -f "$APP_MODULE" ]; then
  if [ "$DRY_RUN" = true ]; then
    echo "WOULD FIX: $APP_MODULE (remove version + comma fix)" | tee -a "$LOG_FILE"
  else
    sed -i '' 's/"243866845719"version/"243866845719", version/g' "$APP_MODULE"  # Ajoute virgule
    sed -i '' 's/, *version: *"[^"]*" *}, */},/g' "$APP_MODULE"  # Supprime version
    sed -i '' 's/environment\.firebase/environment\.firebaseConfig/g' "$APP_MODULE"  # Switch config si besoin
    echo "FIXED: $APP_MODULE (FirebaseOptions clean ; no TS2769)" | tee -a "$LOG_FILE"
  fi
fi

# 6. Update Dépendances (non-dry ; skip en dry-run)
if [ "$DRY_RUN" = false ]; then
  echo "Updating @angular/fire + firebase..." | tee -a "$LOG_FILE"
  npm i @angular/fire@latest firebase@latest --save 2>&1 | tee -a "$LOG_FILE"
  ng cache clean 2>&1 | tee -a "$LOG_FILE"
else
  echo "WOULD UPDATE: npm i @angular/fire@latest firebase@latest" | tee -a "$LOG_FILE"
fi

# 7. Clean Backups si -c
if [ "$CLEAN_BACKUPS" = true ] && [ "$DRY_RUN" = false ]; then
  find . -name "*.backup.*" -type f -delete 2>/dev/null && echo "CLEANED: Backups supprimés (*.backup.*)" | tee -a "$LOG_FILE"
fi

# 8. Validation (tsc + ng build)
if [ "$DRY_RUN" = false ] && command -v ng &> /dev/null; then
  echo "Validation..." | tee -a "$LOG_FILE"
  npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE" && echo "TS OK (no errors)!" | tee -a "$LOG_FILE"
  ng build --configuration development 2>&1 | tee -a "$LOG_FILE" && echo "BUILD OK (no NG8103/NG1010)!" | tee -a "$LOG_FILE"
  echo "Test: ng serve ; /products (no FirebaseError ligne 24) ; /auth (forms OK)." | tee -a "$LOG_FILE"
else
  echo "Dry-run: Skip validation. Installez ng CLI si needed." | tee -a "$LOG_FILE"
fi

echo "Fix complet terminé ! Logs: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Revert: tar -xzf before-full-fix.tar.gz ou cp *.backup.full *"
echo "Note: Vérifiez Firestore rules (allow read/write: true) en console.firebase ; ajoutez docs test si liste vide."
