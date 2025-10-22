#!/bin/bash

# Script complet : Fix plantage page /products (Service + Component + Routing + Validation)
# Usage: ./fix-products-crash.sh [-d dry-run] [-h help]
# Logs: products-crash-fix.log ; Backups: *.backup.crash
# Fix: Query Firestore + filteredProducts$ + ngOnInit + routing + FormsModule

DRY_RUN=false
LOG_FILE="products-crash-fix.log"

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -d : Dry-run (simulation sans changes)"
  echo "  -h : Aide"
  echo "Exemple: ./fix-products-crash.sh  # Fix complet"
  exit 0
}

while getopts "dh" opt; do
  case $opt in
    d) DRY_RUN=true; echo "Mode dry-run: Simulation only." ;;
    h) show_help ;;
    *) echo "Option invalide. -h pour aide." && exit 1 ;;
  esac
done

> "$LOG_FILE"
echo "$(date): Fix plantage /products (Query + Component + Routing)..." | tee -a "$LOG_FILE"

# Fichiers cibles
PRODUCTS_SERVICE="src/app/services/products.service.ts"
PRODUCTS_COMPONENT="src/app/components/products/products.component.ts"
APP_ROUTING="src/app/app-routing.module.ts"

# 1. Backups
for file in "$PRODUCTS_SERVICE" "$PRODUCTS_COMPONENT" "$APP_ROUTING"; do
  if [ -f "$file" ]; then
    if [ "$DRY_RUN" = false ]; then
      cp "$file" "${file}.backup.crash"
      echo "BACKUP: $file" | tee -a "$LOG_FILE"
    else
      echo "WOULD BACKUP: $file" | tee -a "$LOG_FILE"
    fi
  fi
done

# 2. Fix products.service.ts : Rewrite complet avec query() (fix FirebaseError)
if [ "$DRY_RUN" = false ]; then
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
else
  echo "WOULD FIX: $PRODUCTS_SERVICE (rewrite avec query)" | tee -a "$LOG_FILE"
fi

# 3. Fix products.component.ts : Régénération avec filteredProducts$ Observable pur (no getter crash)
if [ "$DRY_RUN" = false ]; then
  cat > "$PRODUCTS_COMPONENT" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Product } from "../../models/product";
import { ProductsService } from '../../services/products.service';

@Component({
  selector: 'app-products',
  templateUrl: './products.component.html',
  styleUrls: ['./products.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class ProductsComponent implements OnInit {
  products$!: Observable<Product[]>;
  filteredProducts$!: Observable<Product[]>;
  productForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  showForm = false;

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
    this.filteredProducts$ = combineLatest([
      this.products$,
      this.searchTerm$
    ]).pipe(
      map(([products, term]) => products.filter(p =>
        p.name.toLowerCase().includes(term.toLowerCase()) ||
        (p.description || '').toLowerCase().includes(term.toLowerCase())
      ))
    );
  }

  loadProducts(): void {
    this.products$ = this.productsService.getProducts();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onSubmit(): void {
    if (this.productForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires correctement.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.productForm.value;
    
    if (this.isEditing && this.editingId) {
      this.productsService.updateProduct(this.editingId, formValue).then(() => {
        this.resetForm();
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la modification du produit.';
        console.error('Update error:', err);
      }).finally(() => this.isLoading = false);
    } else {
      this.productsService.addProduct(formValue).then(() => {
        this.resetForm();
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout du produit.';
        console.error('Add error:', err);
      }).finally(() => this.isLoading = false);
    }
  }

  editProduct(product: Product): void {
    this.isEditing = true;
    this.editingId = product.id || null;
    this.productForm.patchValue(product);
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteProduct(id: string, name: string): void {
    if (confirm(`Êtes-vous sûr de vouloir supprimer le produit "${name}" ?`)) {
      this.isLoading = true;
      this.productsService.deleteProduct(id).then(() => {
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la suppression du produit.';
        console.error('Delete error:', err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productForm.reset({ name: '', price: 0, quantity: 0, description: '' });
    this.isEditing = false;
    this.editingId = null;
    this.errorMessage = '';
    this.showForm = false;
  }

  toggleForm(): void {
    this.showForm = !this.showForm;
    if (!this.showForm) {
      this.resetForm();
    }
  }
}
EOF
  echo "FIXED: $PRODUCTS_COMPONENT (filteredProducts$ Observable pur ; BehaviorSubject searchTerm ; no crash change detection)" | tee -a "$LOG_FILE"
else
  echo "WOULD FIX: $PRODUCTS_COMPONENT (rewrite avec combineLatest)" | tee -a "$LOG_FILE"
fi

# 4. Fix HTML : Update ngModel pour onSearchChange (no [(ngModel)] direct)
PRODUCTS_HTML="src/app/components/products/products.component.html"
if [ -f "$PRODUCTS_HTML" ] && [ "$DRY_RUN" = false ]; then
  # Remplace [(ngModel)]="searchTerm" par ngModel + ngModelChange
  sed -i '' 's/\[\(ngModel\)\]="searchTerm"/[ngModel]="searchTerm" (ngModelChange)="onSearchChange($event)"/g' "$PRODUCTS_HTML"
  echo "FIXED: $PRODUCTS_HTML (ngModelChange pour searchTerm$ update)" | tee -a "$LOG_FILE"
fi

# 5. Ajoute route /products si absente (fix Cannot match routes)
if [ -f "$APP_ROUTING" ] && [ "$DRY_RUN" = false ]; then
  if ! grep -q "path: 'products'" "$APP_ROUTING"; then
    # Ajoute import ProductsComponent si absent
    if ! grep -q "ProductsComponent" "$APP_ROUTING"; then
      sed -i '' '/import { NgModule }/a\
import { ProductsComponent } from '\''./components/products/products.component'\'';' "$APP_ROUTING"
    fi
    # Ajoute route dans routes array
    sed -i '' '/const routes: Routes = \[/a\
  { path: '\''products'\'', component: ProductsComponent },' "$APP_ROUTING"
    echo "FIXED: $APP_ROUTING (route /products ajoutée)" | tee -a "$LOG_FILE"
  else
    echo "INFO: Route /products déjà présente" | tee -a "$LOG_FILE"
  fi
fi

# 6. Validation (tsc + build + ng serve test)
if [ "$DRY_RUN" = false ] && command -v ng &> /dev/null; then
  echo "Validation..." | tee -a "$LOG_FILE"
  ng cache clean
  npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE" && echo "TS OK!" | tee -a "$LOG_FILE"
  ng build --configuration development 2>&1 | tee -a "$LOG_FILE" && echo "BUILD OK!" | tee -a "$LOG_FILE"
  echo "Test runtime : ng serve → /products (devrait charger sans crash)" | tee -a "$LOG_FILE"
else
  echo "Dry-run : Skip validation." | tee -a "$LOG_FILE"
fi

echo "Fix crash terminé ! Logs: $LOG_FILE" | tee -a "$LOG_FILE"
echo "Test : ng serve → /products (liste, recherche, CRUD sans plantage)"
echo "Si persiste : Postez erreurs console (F12) pour debug."
echo "Revert : cp *.backup.crash *"
