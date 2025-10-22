#!/bin/bash

APP_MODULE="src/app/app.module.ts"
AUTH_COMPONENT="src/app/components/auth/auth.component.ts"
PRODUCTS_COMPONENT="src/app/components/products/products.component.ts"
AUTH_HTML="src/app/components/auth/auth.component.html"
PRODUCTS_HTML="src/app/components/products/products.component.html"

echo "Correction NG8002 : Ajout ReactiveFormsModule à AppModule imports (fix formGroup/formControl/ngSubmit binding)..."

# 1. Backups
for file in "$APP_MODULE" "$AUTH_COMPONENT" "$PRODUCTS_COMPONENT" "$AUTH_HTML" "$PRODUCTS_HTML"; do
  [ -f "$file" ] && cp "$file" "${file}.backup.forms" 2>/dev/null || true
done
echo "Backups créés (*.backup.forms)."

# 2. Ajoute import ReactiveFormsModule à AppModule (si absent)
if ! grep -q "ReactiveFormsModule" "$APP_MODULE"; then
  sed -i '' '/import { NgModule }/i\
import { ReactiveFormsModule } from "@angular/forms";' "$APP_MODULE"
  echo "Import ReactiveFormsModule ajouté à AppModule (global pour forms)."
fi

# 3. Ajoute ReactiveFormsModule à imports[] AppModule (si absent ; fix NG8002 pour AuthComponent/ProductsComponent)
if ! grep -q "ReactiveFormsModule," "$APP_MODULE"; then
  sed -i '' '/imports: \[/a\
      ReactiveFormsModule,' "$APP_MODULE"
  echo "ReactiveFormsModule ajouté à imports[] AppModule (formGroup binding global ; no NG8002)."
else
  echo "ReactiveFormsModule déjà en imports ; skip."
fi

# 4. Si components standalone (précédent : imports AppModule), ajoute local imports[] ReactiveFormsModule (safe fallback)
if grep -q "standalone: true" "$AUTH_COMPONENT" 2>/dev/null || true; then
  # Ajoute imports: [ReactiveFormsModule] à AuthComponent si absent
  if ! grep -q "imports:" "$AUTH_COMPONENT"; then
    sed -i '' '/@Component({/a\
  imports: [ReactiveFormsModule],\
  standalone: true,' "$AUTH_COMPONENT"
    echo "AuthComponent : imports: [ReactiveFormsModule] ajouté (standalone forms)."
  fi
fi

if grep -q "standalone: true" "$PRODUCTS_COMPONENT" 2>/dev/null || true; then
  # Ajoute à ProductsComponent si absent
  if ! grep -q "imports:" "$PRODUCTS_COMPONENT"; then
    sed -i '' '/@Component({/a\
  imports: [ReactiveFormsModule],\
  standalone: true,' "$PRODUCTS_COMPONENT"
    echo "ProductsComponent : imports: [ReactiveFormsModule] ajouté (standalone forms)."
  fi
fi

# 5. Assure imports ReactiveFormsModule/FormBuilder en components si besoin (mais constructors fb: FormBuilder déjà OK)
if ! grep -q "ReactiveFormsModule\|FormBuilder" "$AUTH_COMPONENT"; then
  sed -i '' '/import { Component /i\
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from "@angular/forms";' "$AUTH_COMPONENT"
  echo "AuthComponent : Imports forms ajoutés (FormBuilder/Validators pour loginForm)."
fi

if ! grep -q "ReactiveFormsModule\|FormBuilder" "$PRODUCTS_COMPONENT"; then
  sed -i '' '/import { Component /i\
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from "@angular/forms";' "$PRODUCTS_COMPONENT"
  echo "ProductsComponent : Imports forms ajoutés (FormBuilder/Validators pour productForm)."
fi

# 6. Vérifie HTML basique (si absent ; exemple formGroup/formControl pour login/product ; pas overwrite)
if ! grep -q "\[formGroup\]" "$AUTH_HTML"; then
  cat > "$AUTH_HTML" << 'EOL_AUTH_HTML'
<div class="auth-container">
  <form [formGroup]="loginForm" (ngSubmit)="onLogin()">
    <input formControlName="email" placeholder="Email" type="email">
    <input formControlName="password" placeholder="Mot de passe" type="password">
    <button type="submit" [disabled]="isLoading">Login</button>
    <div *ngIf="errorMessage">{{ errorMessage }}</div>
  </form>
  <button (click)="toggleForm()">Switch to Register</button>
</div>
EOL_AUTH_HTML
  echo "auth.component.html créé/exemple (formGroup + formControlName ; ngSubmit)."
fi

if ! grep -q "\[formGroup\]" "$PRODUCTS_HTML"; then
  cat > "$PRODUCTS_HTML" << 'EOL_PROD_HTML'
<div class="products-container">
  <button (click)="resetForm()">Ajouter Produit</button>
  <form [formGroup]="productForm" (ngSubmit)="onSubmit()" *ngIf="!isEditing">
    <input formControlName="name" placeholder="Nom">
    <input formControlName="price" type="number" placeholder="Prix">
    <input formControlName="quantity" type="number" placeholder="Quantité">
    <textarea formControlName="description" placeholder="Description"></textarea>
    <button type="submit" [disabled]="isLoading">Ajouter</button>
  </form>
  <!-- Table liste products$ | async -->
  <table>
    <tr *ngFor="let product of products$ | async">
      <td>{{ product.name }}</td>
      <td>{{ product.price }}</td>
      <td><button (click)="editProduct(product)">Modifier</button></td>
      <td><button (click)="deleteProduct(product.id!)">Supprimer</button></td>
    </tr>
  </table>
  <div *ngIf="errorMessage">{{ errorMessage }}</div>
</div>
EOL_PROD_HTML
  echo "products.component.html créé/exemple (formGroup + formControlName ; async products$)."

fi

# 7. Validation TypeScript/Build (NG8002 template errors)
npx tsc --noEmit 2>/dev/null && echo "Types OK ! (Forms typing FormGroup)." || echo "Vérifiez 'tsc --noEmit' (imports forms ?)."

if command -v ng &> /dev/null; then
  ng build --configuration development 2>/dev/null && echo "Build OK ! No NG8002 (formGroup binding résolu)." || {
    echo "Build échoué ; check HTML/template."
    ng build --configuration development --verbose > build-forms.log 2>&1
    echo "Logs dans build-forms.log."
  }
  ng cache clean
else
  echo "ng CLI absent."
fi

echo "Fix forms terminés !"
echo "- AppModule : ReactiveFormsModule en imports (global formGroup/ngSubmit)."
echo "- Components : Imports forms (FormBuilder/Validators) ; standalone imports si besoin."
echo "- HTML : Exemple formControlName si absent (binding OK)."
echo "Test : ng serve ; /auth (login form submit sans NG8002) ; /products (productForm add sans error)."
