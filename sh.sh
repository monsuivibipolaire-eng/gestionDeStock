#!/bin/bash

# Script pour implémenter saisie multi-produits par bon d'entrée (FormArray + ProductLine[])
# Usage: ./implement-multi-products-entry-voucher.sh [-d dry-run] [-h help]
# Logs: multi-products-entry.log ; Backups: *.backup.multi
# Output: Entry Voucher avec lignes produits dynamiques (add/remove) + total bon

DRY_RUN=false
LOG_FILE="multi-products-entry.log"

show_help() {
  echo "Usage: $0 [OPTIONS]"
  echo "  -d : Dry-run (simulation)"
  echo "  -h : Aide"
  exit 0
}

while getopts "dh" opt; do
  case $opt in
    d) DRY_RUN=true; echo "Mode dry-run." ;;
    h) show_help ;;
    *) echo "Option invalide. -h pour aide." && exit 1 ;;
  esac
done

> "$LOG_FILE"
echo "$(date): Implémentation multi-produits Entry Voucher (FormArray lignes)..." | tee -a "$LOG_FILE"

MODEL_FILE="src/app/models/entry-voucher.ts"
SERVICE_FILE="src/app/services/entry-voucher.service.ts"
COMPONENT_TS="src/app/components/entry-voucher/entry-voucher.component.ts"
COMPONENT_HTML="src/app/components/entry-voucher/entry-voucher.component.html"

# Backups
for file in "$MODEL_FILE" "$SERVICE_FILE" "$COMPONENT_TS" "$COMPONENT_HTML"; do
  [ -f "$file" ] && [ "$DRY_RUN" = false ] && cp "$file" "${file}.backup.multi"
done
echo "Backups créés" | tee -a "$LOG_FILE"

# 1. Mise à jour model : EntryVoucher avec products: ProductLine[]
if [ "$DRY_RUN" = false ]; then
  cat > "$MODEL_FILE" << 'EOF'
import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;  // quantity * unitPrice
}

export interface EntryVoucher {
  id?: string;
  date: Timestamp | Date;
  supplier: string;
  products: ProductLine[];  // Lignes produits (tableau dynamique)
  totalAmount: number;  // Somme subtotals
  status: 'pending' | 'validated' | 'cancelled';
  notes?: string;
  createdAt?: Timestamp | Date;
}
EOF
  echo "UPDATED: $MODEL_FILE (ProductLine[] + totalAmount)" | tee -a "$LOG_FILE"
fi

# 2. Mise à jour service : Calcul totalAmount avant save
if [ "$DRY_RUN" = false ]; then
  cat > "$SERVICE_FILE" << 'EOF'
import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query, orderBy, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { EntryVoucher, ProductLine } from '../models/entry-voucher';

@Injectable({
  providedIn: 'root'
})
export class EntryVoucherService {
  constructor(private firestore: Firestore) {}

  getEntryVouchers(): Observable<EntryVoucher[]> {
    const vouchersRef = collection(this.firestore, 'entryVouchers');
    const q: Query = query(vouchersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<EntryVoucher[]>;
  }

  addEntryVoucher(voucher: Omit<EntryVoucher, 'id' | 'createdAt' | 'totalAmount'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'entryVouchers');
    const totalAmount = this.calculateTotal(voucher.products);
    const voucherData = {
      ...voucher,
      totalAmount,
      createdAt: Timestamp.now()
    };
    return addDoc(vouchersRef, voucherData).then(() => {});
  }

  updateEntryVoucher(id: string, voucher: Partial<EntryVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    const updateData = { ...voucher };
    if (voucher.products) {
      updateData.totalAmount = this.calculateTotal(voucher.products);
    }
    return updateDoc(voucherRef, updateData);
  }

  deleteEntryVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    return deleteDoc(voucherRef);
  }

  private calculateTotal(products: ProductLine[]): number {
    return products.reduce((sum, p) => sum + p.subtotal, 0);
  }
}
EOF
  echo "UPDATED: $SERVICE_FILE (calculateTotal pour totalAmount)" | tee -a "$LOG_FILE"
fi

# 3. Mise à jour component TS : FormArray products avec add/remove lignes
if [ "$DRY_RUN" = false ]; then
  cat > "$COMPONENT_TS" << 'EOF'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { EntryVoucher, ProductLine } from "../../models/entry-voucher";
import { EntryVoucherService } from '../../services/entry-voucher.service';
import { ProductsService } from '../../services/products.service';
import { Product } from '../../models/product';

@Component({
  selector: 'app-entry-voucher',
  templateUrl: './entry-voucher.component.html',
  styleUrls: ['./entry-voucher.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class EntryVoucherComponent implements OnInit {
  vouchers$!: Observable<EntryVoucher[]>;
  filteredVouchers$!: Observable<EntryVoucher[]>;
  products$!: Observable<Product[]>;
  voucherForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  showForm = false;
  expandedVoucherId: string | null = null;  // Pour accordion lignes produits

  constructor(
    private voucherService: EntryVoucherService,
    private productsService: ProductsService,
    private fb: FormBuilder,
    private router: Router
  ) {
    this.voucherForm = this.fb.group({
      date: [new Date().toISOString().split('T')[0], Validators.required],
      supplier: ['', Validators.required],
      products: this.fb.array([this.createProductLine()]),  // FormArray avec 1 ligne initiale
      status: ['pending', Validators.required],
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadVouchers();
    this.products$ = this.productsService.getProducts();
    this.filteredVouchers$ = combineLatest([
      this.vouchers$,
      this.searchTerm$
    ]).pipe(
      map(([vouchers, term]) => vouchers.filter(v =>
        v.supplier.toLowerCase().includes(term.toLowerCase())
      ))
    );
  }

  get productsFormArray(): FormArray {
    return this.voucherForm.get('products') as FormArray;
  }

  createProductLine(): FormGroup {
    return this.fb.group({
      productId: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      unitPrice: [0, [Validators.required, Validators.min(0.01)]]
    });
  }

  addProductLine(): void {
    this.productsFormArray.push(this.createProductLine());
  }

  removeProductLine(index: number): void {
    if (this.productsFormArray.length > 1) {
      this.productsFormArray.removeAt(index);
    }
  }

  calculateSubtotal(index: number): number {
    const line = this.productsFormArray.at(index).value;
    return (line.quantity || 0) * (line.unitPrice || 0);
  }

  calculateTotal(): number {
    return this.productsFormArray.controls.reduce((sum, control) => {
      const line = control.value;
      return sum + ((line.quantity || 0) * (line.unitPrice || 0));
    }, 0);
  }

  loadVouchers(): void {
    this.vouchers$ = this.voucherService.getEntryVouchers();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onSubmit(): void {
    if (this.voucherForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.voucherForm.value;
    
    const productsWithNames: ProductLine[] = formValue.products.map((p: any) => ({
      ...p,
      productName: this.getProductName(p.productId),
      subtotal: p.quantity * p.unitPrice
    }));
    
    const voucherData = {
      date: Timestamp.fromDate(new Date(formValue.date)),
      supplier: formValue.supplier,
      products: productsWithNames,
      status: formValue.status,
      notes: formValue.notes
    };
    
    if (this.isEditing && this.editingId) {
      this.voucherService.updateEntryVoucher(this.editingId, voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.voucherService.addEntryVoucher(voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editVoucher(voucher: EntryVoucher): void {
    this.isEditing = true;
    this.editingId = voucher.id || null;
    const dateStr = (voucher.date as Timestamp).toDate().toISOString().split('T')[0];
    
    this.productsFormArray.clear();
    voucher.products.forEach(p => {
      this.productsFormArray.push(this.fb.group({
        productId: [p.productId, Validators.required],
        quantity: [p.quantity, [Validators.required, Validators.min(1)]],
        unitPrice: [p.unitPrice, [Validators.required, Validators.min(0.01)]]
      }));
    });
    
    this.voucherForm.patchValue({
      date: dateStr,
      supplier: voucher.supplier,
      status: voucher.status,
      notes: voucher.notes
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteVoucher(id: string, supplier: string): void {
    if (confirm(`Supprimer le bon du fournisseur "${supplier}" ?`)) {
      this.isLoading = true;
      this.voucherService.deleteEntryVoucher(id).then(() => {
        this.loadVouchers();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productsFormArray.clear();
    this.productsFormArray.push(this.createProductLine());
    this.voucherForm.patchValue({
      date: new Date().toISOString().split('T')[0],
      supplier: '',
      status: 'pending',
      notes: ''
    });
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

  toggleExpand(voucherId: string): void {
    this.expandedVoucherId = this.expandedVoucherId === voucherId ? null : voucherId;
  }

  getProductName(productId: string): string {
    let productName = '';
    this.products$.subscribe(products => {
      const product = products.find(p => p.id === productId);
      productName = product ? product.name : 'Produit inconnu';
    });
    return productName;
  }

  formatDate(timestamp: Timestamp | Date): string {
    if (timestamp instanceof Timestamp) {
      return timestamp.toDate().toLocaleDateString('fr-FR');
    }
    return new Date(timestamp).toLocaleDateString('fr-FR');
  }
}
EOF
  echo "UPDATED: $COMPONENT_TS (FormArray products + add/remove/calculate)" | tee -a "$LOG_FILE"
fi

# 4. Mise à jour HTML : Table lignes produits dynamique + accordion liste
if [ "$DRY_RUN" = false ]; then
  cat > "$COMPONENT_HTML" << 'EOF'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Bons d'Entrée (Multi-Produits)</h1>

  <div *ngIf="errorMessage" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <strong>Erreur :</strong> {{ errorMessage }}
    <button (click)="errorMessage = ''" class="float-right">&times;</button>
  </div>

  <div class="flex flex-col md:flex-row justify-between items-center mb-6 gap-4">
    <input type="text" [ngModel]="searchTerm" (ngModelChange)="onSearchChange($event)"
           placeholder="Rechercher par fournisseur..." class="w-full md:w-1/2 px-4 py-2 border rounded-lg" />
    <button (click)="toggleForm()" class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-lg">
      <span *ngIf="!showForm">+ Ajouter un Bon</span>
      <span *ngIf="showForm">Fermer</span>
    </button>
  </div>

  <!-- Formulaire avec lignes produits dynamiques -->
  <div *ngIf="showForm" class="bg-white shadow-md rounded-lg p-6 mb-6">
    <h2 class="text-2xl font-semibold mb-4">{{ isEditing ? 'Modifier' : 'Nouveau' }} Bon d'Entrée</h2>
    <form [formGroup]="voucherForm" (ngSubmit)="onSubmit()" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Date *</label>
          <input formControlName="date" type="date" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Fournisseur *</label>
          <input formControlName="supplier" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
      </div>

      <!-- Lignes Produits (FormArray) -->
      <div class="border-t pt-4">
        <h3 class="text-lg font-semibold mb-3">Produits</h3>
        <div formArrayName="products" class="space-y-3">
          <div *ngFor="let product of productsFormArray.controls; let i = index" [formGroupName]="i"
               class="grid grid-cols-1 md:grid-cols-12 gap-3 items-end bg-gray-50 p-3 rounded">
            <div class="md:col-span-4">
              <label class="block text-sm text-gray-600 mb-1">Produit *</label>
              <select formControlName="productId" class="w-full px-3 py-2 border rounded">
                <option value="">-- Sélectionnez --</option>
                <option *ngFor="let p of products$ | async" [value]="p.id">{{ p.name }}</option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">Quantité *</label>
              <input formControlName="quantity" type="number" class="w-full px-3 py-2 border rounded" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">Prix Unit. (€) *</label>
              <input formControlName="unitPrice" type="number" step="0.01" class="w-full px-3 py-2 border rounded" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">Sous-total</label>
              <input [value]="calculateSubtotal(i) | number:'1.2-2'" readonly class="w-full px-3 py-2 border rounded bg-gray-100" />
            </div>
            <div class="md:col-span-2 flex gap-2">
              <button type="button" (click)="addProductLine()" class="bg-blue-500 text-white px-3 py-2 rounded hover:bg-blue-600">+</button>
              <button type="button" (click)="removeProductLine(i)" [disabled]="productsFormArray.length === 1"
                      class="bg-red-500 text-white px-3 py-2 rounded hover:bg-red-600 disabled:bg-gray-300">-</button>
            </div>
          </div>
        </div>
        <div class="mt-4 text-right">
          <span class="text-xl font-bold">Total Bon : {{ calculateTotal() | number:'1.2-2' }} €</span>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Statut</label>
          <select formControlName="status" class="w-full px-4 py-2 border rounded-lg">
            <option value="pending">En attente</option>
            <option value="validated">Validé</option>
            <option value="cancelled">Annulé</option>
          </select>
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Notes</label>
          <input formControlName="notes" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
      </div>

      <div class="flex gap-4">
        <button type="submit" [disabled]="isLoading || voucherForm.invalid"
                class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg disabled:bg-gray-400">
          <span *ngIf="isLoading">Enregistrement...</span>
          <span *ngIf="!isLoading">{{ isEditing ? 'Mettre à jour' : 'Ajouter' }}</span>
        </button>
        <button type="button" (click)="resetForm()" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-lg">Annuler</button>
      </div>
    </form>
  </div>

  <!-- Liste bons avec accordion lignes produits -->
  <div *ngIf="!isLoading" class="space-y-4">
    <div *ngFor="let voucher of filteredVouchers$ | async" class="bg-white shadow rounded-lg overflow-hidden">
      <div class="px-6 py-4 flex justify-between items-center cursor-pointer hover:bg-gray-50"
           (click)="toggleExpand(voucher.id!)">
        <div class="flex-1 grid grid-cols-4 gap-4">
          <div><strong>Date:</strong> {{ formatDate(voucher.date) }}</div>
          <div><strong>Fournisseur:</strong> {{ voucher.supplier }}</div>
          <div><strong>Total:</strong> {{ voucher.totalAmount | number:'1.2-2' }} €</div>
          <div><span [ngClass]="{
            'bg-yellow-100 text-yellow-800': voucher.status === 'pending',
            'bg-green-100 text-green-800': voucher.status === 'validated',
            'bg-red-100 text-red-800': voucher.status === 'cancelled'
          }" class="px-2 py-1 rounded">{{ voucher.status }}</span></div>
        </div>
        <button class="text-blue-600 hover:text-blue-800">
          {{ expandedVoucherId === voucher.id ? '▼' : '►' }}
        </button>
      </div>
      
      <div *ngIf="expandedVoucherId === voucher.id" class="px-6 py-4 bg-gray-50 border-t">
        <table class="min-w-full">
          <thead class="bg-gray-100">
            <tr>
              <th class="px-4 py-2 text-left text-sm">Produit</th>
              <th class="px-4 py-2 text-left text-sm">Quantité</th>
              <th class="px-4 py-2 text-left text-sm">Prix Unit.</th>
              <th class="px-4 py-2 text-left text-sm">Sous-total</th>
            </tr>
          </thead>
          <tbody>
            <tr *ngFor="let line of voucher.products" class="border-t">
              <td class="px-4 py-2">{{ line.productName }}</td>
              <td class="px-4 py-2">{{ line.quantity }}</td>
              <td class="px-4 py-2">{{ line.unitPrice | number:'1.2-2' }} €</td>
              <td class="px-4 py-2 font-semibold">{{ line.subtotal | number:'1.2-2' }} €</td>
            </tr>
          </tbody>
        </table>
        <div class="mt-4 flex gap-2">
          <button (click)="editVoucher(voucher)" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded">Modifier</button>
          <button (click)="deleteVoucher(voucher.id!, voucher.supplier)" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded">Supprimer</button>
        </div>
      </div>
    </div>
    <div *ngIf="(filteredVouchers$ | async)?.length === 0" class="text-center py-8 text-gray-500">
      Aucun bon d'entrée trouvé.
    </div>
  </div>
</div>
EOF
  echo "UPDATED: $COMPONENT_HTML (FormArray lignes + accordion + total)" | tee -a "$LOG_FILE"
fi

# Validation
if [ "$DRY_RUN" = false ] && command -v ng &> /dev/null; then
  ng cache clean
  npx tsc --noEmit && echo "TS OK!" | tee -a "$LOG_FILE"
  ng build --configuration development && echo "BUILD OK!" | tee -a "$LOG_FILE"
fi

echo "Multi-produits Entry Voucher terminé ! Logs: $LOG_FILE"
echo "Test: ng serve → /entry-voucher → Add (plusieurs lignes produits) → Accordion liste"
