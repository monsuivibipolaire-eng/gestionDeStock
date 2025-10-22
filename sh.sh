#!/bin/bash

COMPONENT_TS="src/app/components/products/products.component.ts"

# Backup
cp "$COMPONENT_TS" "${COMPONENT_TS}.backup.formsmodule"

# Supprime ligne FormsModule existante si présente (évite duplicate)
sed -i '' '/import { FormsModule } from/d' "$COMPONENT_TS"

# Ajoute import FormsModule après ReactiveFormsModule (ligne 2)
sed -i '' '2a\
import { FormsModule } from '\''@angular/forms'\'';' "$COMPONENT_TS"

echo "FIX APPLIED: FormsModule importé en ligne 3"
ng cache clean
ng build --configuration development && echo "BUILD OK!"
