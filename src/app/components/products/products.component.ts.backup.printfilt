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
