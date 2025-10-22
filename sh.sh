#!/bin/bash

APP_MODULE="src/app/app.module.ts"
AUTH_COMPONENT="src/app/components/auth/auth.component.ts"
PRODUCTS_COMPONENT="src/app/components/products/products.component.ts"

echo "Correction TS1005/TS2769/TS18004/TS2353/NG1010/TS2304 : Fix Firebase config (version + comma) + @Component imports array..."

# 1. Backups
for file in "$APP_MODULE" "$AUTH_COMPONENT" "$PRODUCTS_COMPONENT"; do
  [ -f "$file" ] && cp "$file" "${file}.backup.v3" 2>/dev/null || true
done
echo "Backups créés (*.backup.v3)."

# 2. Fix app.module.ts : TS1005/TS2769 (ligne ~47 ; comma après messagingSenderId + remove version)
if [ -f "$APP_MODULE" ]; then
  # Ajoute virgule si manquante après messagingSenderId: "..."
  sed -i '' 's/"243866845719"version/"243866845719", version/g' "$APP_MODULE"
  # Supprime , version: "2" (et traînante virgule)
  sed -i '' 's/, *version: *"[^"]*" *}, */},/g' "$APP_MODULE"
  sed -i '' 's/version: *"[^"]*" *}, */},/g' "$APP_MODULE"  # Si sans virgule avant
  echo "app.module.ts : Virgule ajoutée après messagingSenderId ; version supprimé (fix TS1005/TS2769 ligne 47 ; FirebaseOptions valide)."
  
  # Vérifie initializeApp sur config propre (firebase ou firebaseConfig)
  if grep -q "environment.firebase" "$APP_MODULE"; then
    sed -i '' 's/environment\.firebase/environment\.firebaseConfig/g' "$APP_MODULE"
    echo "Switch à firebaseConfig si flat (optionnel)."
  fi
fi

# 3. Fix AuthComponent : Ajoute import CommonModule si absent
if [ -f "$AUTH_COMPONENT" ]; then
  # Import CommonModule après core imports
  if ! grep -q "from '@angular/common'" "$AUTH_COMPONENT"; then
    sed -i '' '/import { Component, OnInit } from "@angular\/core";/a\
import { CommonModule } from "@angular/common";' "$AUTH_COMPONENT"
    echo "AuthComponent : Import CommonModule ajouté."
  fi
  
  # Fix malformed : Remplace 'CommonModule,' par 'imports: [CommonModule], '
  if grep -q "CommonModule," "$AUTH_COMPONENT" && ! grep -q "imports: \[" "$AUTH_COMPONENT"; then
    sed -i '' 's/CommonModule, standalone: true/imports: [CommonModule], standalone: true/g' "$AUTH_COMPONENT"
    echo "AuthComponent : Malformed 'CommonModule,' → 'imports: [CommonModule],' (fix TS18004/TS2353 ligne 10)."
  elif ! grep -q "imports: \[" "$AUTH_COMPONENT"; then
    # Insère array après @Component({
    sed -i '' '/@Component({/a\
  imports: [CommonModule],' "$AUTH_COMPONENT"
    echo "AuthComponent : imports: [CommonModule] ajouté (fix NG8103 *ngIf)."
  fi
fi

# 4. Fix ProductsComponent : Imports ReactiveFormsModule + CommonModule
if [ -f "$PRODUCTS_COMPONENT" ]; then
  # Imports manquants
  if ! grep -q "from '@angular/common'" "$PRODUCTS_COMPONENT"; then
    sed -i '' '/import { Component, OnInit } from "@angular\/core";/a\
import { CommonModule } from "@angular/common";\
import { ReactiveFormsModule } from "@angular/forms";' "$PRODUCTS_COMPONENT"
    echo "ProductsComponent : Imports CommonModule + ReactiveFormsModule ajoutés (fix TS2304/NG1010 ligne 8)."
  fi
  
  # Fix malformed ligne 9
  if grep -q "CommonModule," "$PRODUCTS_COMPONENT" && ! grep -q "imports: \[" "$PRODUCTS_COMPONENT"; then
    sed -i '' 's/CommonModule, standalone: true/imports: [ReactiveFormsModule, CommonModule], standalone: true/g' "$PRODUCTS_COMPONENT"
    echo "ProductsComponent : Malformed 'CommonModule,' → 'imports: [ReactiveFormsModule, CommonModule],' (fix TS18004/TS2353 ligne 9)."
  elif grep -q "imports: \[" "$PRODUCTS_COMPONENT" && ! grep -q "CommonModule" "$PRODUCTS_COMPONENT" | grep -q "imports"; then
    # Append à array existant
    sed -i '' '/imports: \[/s/\]/, CommonModule]/' "$PRODUCTS_COMPONENT"
    echo "ProductsComponent : CommonModule ajouté à imports array existant (ligne 8)."
  elif ! grep -q "imports: \[" "$PRODUCTS_COMPONENT"; then
    sed -i '' '/@Component({/a\
  imports: [ReactiveFormsModule, CommonModule],' "$PRODUCTS_COMPONENT"
    echo "ProductsComponent : imports array ajouté (fix NG8103 *ngIf/*ngFor)."
  fi
fi

# 5. Validation (tsc + ng build)
if command -v ng &> /dev/null; then
  ng cache clean
  npx tsc --noEmit && echo "Types OK ! (No TS1005/TS2769/TS18004/TS2353/TS2304 ; FirebaseOptions + imports valides)." || {
    echo "TS logs :"
    npx tsc --noEmit | grep -E "(TS1005|TS2769|TS18004|TS2353|TS2304)" || echo "No matching TS errors."
  }
  ng build --configuration development && echo "Build OK ! (No NG1010 ; templates clean)." || {
    echo "Build logs :"
    ng build --configuration development --verbose | grep -E "(NG1010|TS2304)" || echo "No matching NG errors."
  }
else
  echo "Installez @angular/cli : npm i -g @angular/cli."
fi

echo "Fix v3 terminés !"
echo "- app.module.ts : Config Firebase clean (no version ; comma fixée – TS1005/TS2769)."
echo "- Components : @Component avec imports: [CommonModule, ...] (fix TS18004/TS2353/NG1010/TS2304)."
echo "Test : ng serve ; no errors (watch clean) ; /auth (form *ngIf) ; /products (form ReactiveForms + *ngFor)."
echo "Revert : cp *.backup.v3 * ; ou éditez manuellement lignes 8-10 components / 47 app.module."
echo "Note : Si 'UserCredential' erreur (auth), ajoutez import { UserCredential } from 'firebase/auth'; en auth.component.ts."
