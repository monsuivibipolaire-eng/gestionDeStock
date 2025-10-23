#!/bin/bash

# Script pour ajouter filtres avancés dans Products (nom, prix min/max, stock, tri)
# Usage: ./add-products-advanced-filters.sh
# Logs: products-filters.log ; Backups: *.backup.prodfilters

LOG_FILE="products-filters.log"
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

> "$LOG_FILE"
log_info "$(date): Ajout filtres avancés dans Products..."

PRODUCTS_TS="src/app/components/products/products.component.ts"
PRODUCTS_HTML="src/app/components/products/products.component.html"

# Backups
cp "$PRODUCTS_TS" "${PRODUCTS_TS}.backup.prodfilters"
cp "$PRODUCTS_HTML" "${PRODUCTS_HTML}.backup.prodfilters"
log_info "Backups créés"

# ===================================
# 1. PRODUCTS TS : Ajout filtres + logique
# ===================================
log_info "Génération products.component.ts avec filtres avancés..."

cat > "$PRODUCTS_TS" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
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
  
  // Filtres
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  minPrice: number | null = null;
  minPrice$ = new BehaviorSubject<number | null>(null);
  maxPrice: number | null = null;
  maxPrice$ = new BehaviorSubject<number | null>(null);
  stockFilter: 'all' | 'rupture' | 'low' | 'ok' = 'all';
  stockFilter$ = new BehaviorSubject<'all' | 'rupture' | 'low' | 'ok'>('all');
  sortBy: 'name' | 'price' | 'quantity' = 'name';
  sortBy$ = new BehaviorSubject<'name' | 'price' | 'quantity'>('name');
  sortOrder: 'asc' | 'desc' = 'asc';
  sortOrder$ = new BehaviorSubject<'asc' | 'desc'>('asc');
  
  showForm = false;

  constructor(
    private productsService: ProductsService,
    private fb: FormBuilder
  ) {
    this.productForm = this.fb.group({
      name: ['', Validators.required],
      price: [0, [Validators.required, Validators.min(0)]],
      quantity: [0, [Validators.required, Validators.min(0)]],
      description: ['']
    });
  }

  ngOnInit(): void {
    this.loadProducts();
    
    // Filtrage réactif (combine tous les filtres)
    this.filteredProducts$ = combineLatest([
      this.products$,
      this.searchTerm$,
      this.minPrice$,
      this.maxPrice$,
      this.stockFilter$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([products, term, minPrice, maxPrice, stockFilter, sortBy, sortOrder]) => {
        let filtered = products;
        
        // Filtre par nom (recherche)
        if (term) {
          filtered = filtered.filter(p =>
            p.name.toLowerCase().includes(term.toLowerCase())
          );
        }
        
        // Filtre par prix min
        if (minPrice !== null) {
          filtered = filtered.filter(p => (p.price || 0) >= minPrice);
        }
        
        // Filtre par prix max
        if (maxPrice !== null) {
          filtered = filtered.filter(p => (p.price || 0) <= maxPrice);
        }
        
        // Filtre par stock
        if (stockFilter === 'rupture') {
          filtered = filtered.filter(p => (p.quantity || 0) === 0);
        } else if (stockFilter === 'low') {
          filtered = filtered.filter(p => (p.quantity || 0) > 0 && (p.quantity || 0) < 10);
        } else if (stockFilter === 'ok') {
          filtered = filtered.filter(p => (p.quantity || 0) >= 10);
        }
        
        // Tri
        filtered = filtered.sort((a, b) => {
          let compareValue = 0;
          if (sortBy === 'name') {
            compareValue = a.name.localeCompare(b.name);
          } else if (sortBy === 'price') {
            compareValue = (a.price || 0) - (b.price || 0);
          } else if (sortBy === 'quantity') {
            compareValue = (a.quantity || 0) - (b.quantity || 0);
          }
          return sortOrder === 'asc' ? compareValue : -compareValue;
        });
        
        return filtered;
      })
    );
  }

  loadProducts(): void {
    this.products$ = this.productsService.getProducts();
  }

  // Méthodes filtres
  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onMinPriceChange(value: number | null): void {
    this.minPrice = value;
    this.minPrice$.next(value);
  }

  onMaxPriceChange(value: number | null): void {
    this.maxPrice = value;
    this.maxPrice$.next(value);
  }

  onStockFilterChange(filter: 'all' | 'rupture' | 'low' | 'ok'): void {
    this.stockFilter = filter;
    this.stockFilter$.next(filter);
  }

  onSortChange(sortBy: 'name' | 'price' | 'quantity'): void {
    if (this.sortBy === sortBy) {
      // Toggle order si même champ
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = sortBy;
      this.sortOrder = 'asc';
    }
    this.sortBy$.next(this.sortBy);
    this.sortOrder$.next(this.sortOrder);
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.searchTerm$.next('');
    this.minPrice = null;
    this.minPrice$.next(null);
    this.maxPrice = null;
    this.maxPrice$.next(null);
    this.stockFilter = 'all';
    this.stockFilter$.next('all');
    this.sortBy = 'name';
    this.sortBy$.next('name');
    this.sortOrder = 'asc';
    this.sortOrder$.next('asc');
  }

  onSubmit(): void {
    if (this.productForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
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
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.productsService.addProduct(formValue).then(() => {
        this.resetForm();
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout.';
        console.error(err);
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
    if (confirm(`Supprimer le produit "${name}" ?`)) {
      this.isLoading = true;
      this.productsService.deleteProduct(id).then(() => {
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productForm.reset({ price: 0, quantity: 0 });
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

  printList(): void {
    window.print();
  }

  printItem(item: any): void {
    const printWindow = window.open("", "_blank", "width=800,height=600");
    if (!printWindow) return;

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Fiche Produit</title>
        <style>
          @page { margin: 20mm; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 20px; }
          h1 { text-align: center; border-bottom: 2px solid #000; padding-bottom: 10px; }
          table { width: 100%; border-collapse: collapse; margin: 15px 0; }
          th, td { padding: 8px; text-align: left; border: 1px solid #ddd; }
          th { background: #f3f4f6; font-weight: bold; }
        </style>
      </head>
      <body>
        <h1>Fiche Produit</h1>
        <table>
          <tr><th>Nom</th><td>${item.name || 'N/A'}</td></tr>
          <tr><th>Prix</th><td>${item.price || 0} DT</td></tr>
          <tr><th>Quantité</th><td>${item.quantity || 0}</td></tr>
          <tr><th>Description</th><td>${item.description || 'N/A'}</td></tr>
        </table>
      </body>
      </html>
    `;
    
    printWindow.document.write(html);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => {
      printWindow.print();
      printWindow.close();
    }, 250);
  }
}
EOF
log_info "✅ products.component.ts généré (filtres avancés)"

# ===================================
# 2. PRODUCTS HTML : Interface filtres + table
# ===================================
log_info "Génération products.component.html avec UI filtres..."

cat > "$PRODUCTS_HTML" << 'EOF'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Gestion des Produits</h1>

  <div *ngIf="errorMessage" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <strong>Erreur :</strong> {{ errorMessage }}
    <button (click)="errorMessage = ''" class="float-right">&times;</button>
  </div>

  <!-- Barre recherche + boutons -->
  <div class="flex flex-col md:flex-row justify-between items-center mb-4 gap-4">
    <input type="text" [ngModel]="searchTerm" (ngModelChange)="onSearchChange($event)"
           placeholder="🔍 Rechercher par nom..." class="w-full md:w-1/3 px-4 py-2 border rounded-lg" />
    <div class="flex gap-2">
      <button (click)="printList()" class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-lg flex items-center space-x-2 no-print">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path>
        </svg>
        <span>Imprimer Liste</span>
      </button>
      <button (click)="toggleForm()" class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-lg no-print">
        <span *ngIf="!showForm">+ Ajouter un Produit</span>
        <span *ngIf="showForm">Fermer</span>
      </button>
    </div>
  </div>

  <!-- Filtres Avancés (collapsible) -->
  <div class="bg-white shadow-md rounded-lg p-4 mb-6 no-print">
    <h3 class="text-lg font-semibold mb-3 flex items-center">
      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path>
      </svg>
      Filtres Avancés
    </h3>
    
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <!-- Prix Min/Max -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Prix Min (DT)</label>
        <input type="number" [ngModel]="minPrice" (ngModelChange)="onMinPriceChange($event)" 
               placeholder="0" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Prix Max (DT)</label>
        <input type="number" [ngModel]="maxPrice" (ngModelChange)="onMaxPriceChange($event)" 
               placeholder="1000" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      
      <!-- Filtre Stock -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">État Stock</label>
        <select [ngModel]="stockFilter" (ngModelChange)="onStockFilterChange($event)" 
                class="w-full px-3 py-2 border rounded-lg">
          <option value="all">Tous</option>
          <option value="rupture">En Rupture (0)</option>
          <option value="low">Stock Bas (&lt; 10)</option>
          <option value="ok">Stock OK (≥ 10)</option>
        </select>
      </div>
      
      <!-- Tri -->
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Trier par</label>
        <select [ngModel]="sortBy" (ngModelChange)="onSortChange($event)" 
                class="w-full px-3 py-2 border rounded-lg">
          <option value="name">Nom {{ sortBy === 'name' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="price">Prix {{ sortBy === 'price' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="quantity">Quantité {{ sortBy === 'quantity' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
        </select>
      </div>
    </div>
    
    <div class="mt-4">
      <button (click)="clearFilters()" class="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded-lg">
        Réinitialiser Filtres
      </button>
    </div>
  </div>

  <!-- Formulaire Produit -->
  <div *ngIf="showForm" class="bg-white shadow-md rounded-lg p-6 mb-6 no-print">
    <h2 class="text-2xl font-semibold mb-4">{{ isEditing ? 'Modifier' : 'Nouveau' }} Produit</h2>
    <form [formGroup]="productForm" (ngSubmit)="onSubmit()" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Nom *</label>
          <input formControlName="name" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Prix (DT) *</label>
          <input formControlName="price" type="number" step="0.01" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Quantité *</label>
          <input formControlName="quantity" type="number" class="w-full px-4 py-2 border rounded-lg" />
        </div>
      </div>
      <div>
        <label class="block text-gray-700 font-medium mb-2">Description</label>
        <textarea formControlName="description" rows="2" class="w-full px-4 py-2 border rounded-lg"></textarea>
      </div>
      <div class="flex gap-4">
        <button type="submit" [disabled]="isLoading || productForm.invalid"
                class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg disabled:bg-gray-400">
          {{ isEditing ? 'Mettre à jour' : 'Ajouter' }}
        </button>
        <button type="button" (click)="resetForm()" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-lg">Annuler</button>
      </div>
    </form>
  </div>

  <!-- Table Produits -->
  <div *ngIf="!isLoading" class="bg-white shadow-md rounded-lg overflow-hidden">
    <table class="min-w-full divide-y divide-gray-200">
      <thead class="bg-gray-50">
        <tr>
          <th (click)="onSortChange('name')" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase cursor-pointer hover:bg-gray-100">
            Nom {{ sortBy === 'name' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}
          </th>
          <th (click)="onSortChange('price')" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase cursor-pointer hover:bg-gray-100">
            Prix {{ sortBy === 'price' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}
          </th>
          <th (click)="onSortChange('quantity')" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase cursor-pointer hover:bg-gray-100">
            Quantité {{ sortBy === 'quantity' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}
          </th>
          <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Description</th>
          <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase no-print">Actions</th>
        </tr>
      </thead>
      <tbody class="bg-white divide-y divide-gray-200" *ngIf="filteredProducts$ | async as products">
        <tr *ngFor="let product of products" class="hover:bg-gray-50">
          <td class="px-6 py-4 text-sm font-medium text-gray-900">{{ product.name }}</td>
          <td class="px-6 py-4 text-sm text-gray-500">{{ product.price | number:'1.2-2' }} DT</td>
          <td class="px-6 py-4 text-sm">
            <span [ngClass]="{
              'bg-red-100 text-red-800': (product.quantity || 0) === 0,
              'bg-yellow-100 text-yellow-800': (product.quantity || 0) > 0 && (product.quantity || 0) < 10,
              'bg-green-100 text-green-800': (product.quantity || 0) >= 10
            }" class="px-2 py-1 rounded">
              {{ product.quantity || 0 }}
            </span>
          </td>
          <td class="px-6 py-4 text-sm text-gray-500">{{ product.description || 'N/A' }}</td>
          <td class="px-6 py-4 text-right text-sm font-medium no-print">
            <button (click)="editProduct(product)" class="text-indigo-600 hover:text-indigo-900 mr-4">Modifier</button>
            <button (click)="deleteProduct(product.id!, product.name)" class="text-red-600 hover:text-red-900 mr-4">Supprimer</button>
            <button (click)="printItem(product)" class="text-purple-600 hover:text-purple-900">Imprimer</button>
          </td>
        </tr>
        <tr *ngIf="products.length === 0">
          <td colspan="5" class="px-6 py-8 text-center text-gray-500">Aucun produit trouvé.</td>
        </tr>
      </tbody>
    </table>
  </div>
</div>
EOF
log_info "✅ products.component.html généré (UI filtres avancés)"

# ===================================
# 3. VALIDATION
# ===================================
if command -v ng &> /dev/null; then
    log_info "Validation compilation..."
    ng cache clean
    npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_info "✅ TS OK!"
    else
        log_info "⚠️  Erreurs TS (vérifiez logs)"
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Filtres Avancés Ajoutés (Products)"
echo "=========================================="
echo "Filtres disponibles :"
echo "  1. Recherche par nom (input text)"
echo "  2. Prix Min / Prix Max (inputs number)"
echo "  3. État Stock (select: Tous/Rupture/Bas/OK)"
echo "  4. Tri (select: Nom/Prix/Quantité + ordre asc/desc)"
echo "  5. Click headers table → Toggle tri"
echo ""
echo "Features :"
echo "  - Filtrage réactif (combineLatest RxJS)"
echo "  - Badges stock colorés (rouge=0, jaune<10, vert≥10)"
echo "  - Bouton 'Réinitialiser Filtres'"
echo "  - Headers table cliquables (tri toggle)"
echo "  - Icons flèches ↑↓ tri actuel"
echo ""
echo "Test :"
echo "  1. ng serve"
echo "  2. /products → Section 'Filtres Avancés'"
echo "  3. Prix Min: 10, Prix Max: 100 → Table filtre"
echo "  4. Stock: 'En Rupture' → Affiche quantité = 0"
echo "  5. Click header 'Prix' → Tri prix croissant/décroissant"
echo ""
echo "Logs : $LOG_FILE"
echo "Revert : cp *.backup.prodfilters *"
