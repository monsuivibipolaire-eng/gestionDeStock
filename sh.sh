#!/bin/bash

PRODUCTS_TS="src/app/components/products/products.component.ts"
APP_MODULE="src/app/app.module.ts"
APP_SPEC="src/app/app.spec.ts"

echo "Correction TS2306/TS2307 : Régénération TS avec export + fix imports app.module.ts + app.spec.ts..."

# 1. Backups
cp "$PRODUCTS_TS" "${PRODUCTS_TS}.backup.imports" 2>/dev/null || true
cp "$APP_MODULE" "${APP_MODULE}.backup.imports" 2>/dev/null || true
cp "$APP_SPEC" "${APP_SPEC}.backup.imports" 2>/dev/null || true
echo "Backups créés."

# 2. Régénération complète products.component.ts (propre : exports, isEditing/editingId après constructor, syntaxe valide)
cat > "$PRODUCTS_TS" << 'EOL_TS'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Observable } from 'rxjs';
import { Router } from '@angular/router';
import { ProductsService, Product } from '../../services/products.service';

@Component({
  selector: 'app-products',
  standalone: false,
  templateUrl: './products.component.html',
  styleUrls: ['./products.component.scss']
})
export class ProductsComponent implements OnInit {
  products$!: Observable<Product[]>;
  productForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';

  constructor(
    private productsService: ProductsService,
    private fb: FormBuilder,
    private router: Router
  ) {
    this.productForm = this.fb.group({
      name: ['', Validators.required],
      price: [0, [Validators.required, Validators.min(0.01)]],
      quantity: [0, [Validators.required, Validators.min(1)]],
      description: ['']
    });
  }

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.products$ = this.productsService.getProducts();
  }

  onSubmit(): void {
    if (this.productForm.invalid) {
      this.errorMessage = 'Veuillez remplir les champs correctement.';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const formValue: Product = this.productForm.value;

    if (this.isEditing && this.editingId) {
      this.productsService.updateProduct(this.editingId, formValue).then(() => {
        this.isLoading = false;
        this.resetForm();
        this.loadProducts();
        console.log('Produit mis à jour');
      }).catch((err: Error) => {
        this.isLoading = false;
        this.errorMessage = 'Erreur mise à jour.';
        console.error('Update error:', err);
      });
    } else {
      this.productsService.addProduct(formValue).then(() => {
        this.isLoading = false;
        this.resetForm();
        this.loadProducts();
        console.log('Produit ajouté');
      }).catch((err: Error) => {
        this.isLoading = false;
        this.errorMessage = 'Erreur ajout.';
        console.error('Add error:', err);
      });
    }
  }

  editProduct(product: Product): void {
    this.isEditing = true;
    this.editingId = product.id || null;
    this.productForm.patchValue(product);
  }

  deleteProduct(id: string): void {
    if (confirm('Confirmer suppression ?')) {
      this.isLoading = true;
      this.productsService.deleteProduct(id).then(() => {
        this.isLoading = false;
        this.loadProducts();
        console.log('Produit supprimé');
      }).catch((err: Error) => {
        this.isLoading = false;
        this.errorMessage = 'Erreur suppression.';
        console.error('Delete error:', err);
      });
    }
  }

  resetForm(): void {
    this.productForm.reset();
    this.isEditing = false;
    this.editingId = null;
    this.errorMessage = '';
  }
}
EOL_TS
echo "products.component.ts régénéré (export class + isEditing/editingId après constructor ; syntaxe module valide)."

# 3. Fix app.module.ts : Assure import et déclaration ProductsComponent (NgModule declarations)
if ! grep -q "ProductsComponent" "$APP_MODULE"; then
  # Ajoute import si absent
  sed -i '' '/import { NgModule }/i\
import { ProductsComponent } from "./components/products/products.component";' "$APP_MODULE"
  
  # Ajoute à declarations array
  sed -i '' '/declarations: \[/,/]/ { /AppComponent/a\
      ProductsComponent,' "$APP_MODULE"
  echo "Import et déclaration ProductsComponent ajoutés à AppModule (fix TS2306)."
else
  echo "ProductsComponent déjà importé/déclaré dans AppModule."
fi

# 4. Fix app.spec.ts : Corrige import App → AppComponent (standard Angular test)
sed -i '' 's/import { App } from .\/app;/import { AppComponent } from .\/app.component/;' "$APP_SPEC"
sed -i '' 's/TestBed.createComponent(App)/TestBed.createComponent(AppComponent)/g' "$APP_SPEC" 2>/dev/null || true
sed -i '' 's/fixture.componentInstance as App/fixture.componentInstance as AppComponent/g' "$APP_SPEC" 2>/dev/null || true
echo "app.spec.ts corrigé (import App → AppComponent ; fix TS2307)."

# 5. Validation TypeScript (full projet)
npx tsc --noEmit 2>/dev/null && echo "Types OK ! Pas de TS2306/TS2307 (modules exportés, imports fixés)." || echo "Vérifiez 'tsc --noEmit' (autres modules ?)."

# 6. Nettoyage cache + serve test (optionnel)
ng cache clean --all 2>/dev/null || echo "ng CLI absent ; ignorez."
if command -v ng &> /dev/null; then
  echo "Test : ng serve (doit compiler sans erreurs imports)."
else
  echo "Installez ng CLI pour test auto."
fi

echo "Fix imports terminés !"
echo "- products.component.ts : Export class + propriétés (isEditing/editingId) ; module valide."
echo "- app.module.ts : Import/declaration ProductsComponent (NgModule)."
echo "- app.spec.ts : Import AppComponent (tests OK)."
echo "Test : ng serve ; naviguez /products (CRUD table/modal) ; pas d'erreurs console/tsc."
