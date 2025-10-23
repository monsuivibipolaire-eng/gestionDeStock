#!/bin/bash

# Script pour ajouter filtres avancés + Imprimer Liste dans Exit Voucher
# Usage: ./add-exit-filters-print.sh
# Logs: exit-filters.log ; Backups: *.backup.exitfilters

LOG_FILE="exit-filters.log"
GREEN='\033[0;32m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

> "$LOG_FILE"
log_info "$(date): Ajout filtres avancés + Imprimer Liste dans Exit Voucher..."

EXIT_TS="src/app/components/exit-voucher/exit-voucher.component.ts"
EXIT_HTML="src/app/components/exit-voucher/exit-voucher.component.html"

# Backups
cp "$EXIT_TS" "${EXIT_TS}.backup.exitfilters"
cp "$EXIT_HTML" "${EXIT_HTML}.backup.exitfilters"
log_info "Backups créés"

# 1. Vérifier/Créer model exit-voucher.ts
EXIT_MODEL="src/app/models/exit-voucher.ts"
mkdir -p "src/app/models"

cat > "$EXIT_MODEL" << 'EOF'
import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface ExitVoucher {
  id?: string;
  voucherNumber: string;
  date: Timestamp | Date;
  customer: string;
  destination?: string;
  products: ProductLine[];
  totalAmount: number;
  notes?: string;
  createdAt?: Date;
}
EOF
log_info "✅ Model exit-voucher.ts créé/mis à jour"

# 2. Vérifier/Créer service exit-vouchers.service.ts
EXIT_SERVICE="src/app/services/exit-vouchers.service.ts"
mkdir -p "src/app/services"

cat > "$EXIT_SERVICE" << 'EOF'
import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { ExitVoucher } from '../models/exit-voucher';

@Injectable({
  providedIn: 'root'
})
export class ExitVouchersService {
  constructor(private firestore: Firestore) {}

  getExitVouchers(): Observable<ExitVoucher[]> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    const q: Query = query(vouchersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<ExitVoucher[]>;
  }

  addExitVoucher(voucher: Omit<ExitVoucher, 'id' | 'createdAt'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    return addDoc(vouchersRef, { 
      ...voucher, 
      createdAt: Timestamp.now() 
    }).then(() => {});
  }

  updateExitVoucher(id: string, voucher: Partial<ExitVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    return updateDoc(voucherRef, voucher as any);
  }

  deleteExitVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    return deleteDoc(voucherRef);
  }

  generateVoucherNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `SRT-${year}${month}${day}-${random}`;
  }
}
EOF
log_info "✅ Service exit-vouchers.service.ts créé/mis à jour"

# 3. Génération exit-voucher.component.ts
cat > "$EXIT_TS" << 'EOFTS'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { NgSelectModule } from '@ng-select/ng-select';
import { ExitVoucher, ProductLine } from "../../models/exit-voucher";
import { ExitVouchersService } from '../../services/exit-vouchers.service';
import { ProductsService } from '../../services/products.service';
import { CustomersService } from '../../services/customers.service';
import { Product } from '../../models/product';
import { Customer } from '../../models/customer';

@Component({
  selector: 'app-exit-voucher',
  templateUrl: './exit-voucher.component.html',
  styleUrls: ['./exit-voucher.component.scss'],
  imports: [ReactiveFormsModule, NgSelectModule, CommonModule, FormsModule],
  standalone: true
})
export class ExitVoucherComponent implements OnInit {
  vouchers$!: Observable<ExitVoucher[]>;
  filteredVouchers$!: Observable<ExitVoucher[]>;
  products$!: Observable<Product[]>;
  customers$!: Observable<Customer[]>;
  voucherForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  showForm = false;
  expandedVoucherId: string | null = null;
  
  // Filtres
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  selectedCustomer: string | null = null;
  selectedCustomer$ = new BehaviorSubject<string | null>(null);
  dateFrom: string | null = null;
  dateFrom$ = new BehaviorSubject<string | null>(null);
  dateTo: string | null = null;
  dateTo$ = new BehaviorSubject<string | null>(null);
  minAmount: number | null = null;
  minAmount$ = new BehaviorSubject<number | null>(null);
  maxAmount: number | null = null;
  maxAmount$ = new BehaviorSubject<number | null>(null);
  sortBy: 'date' | 'customer' | 'amount' = 'date';
  sortBy$ = new BehaviorSubject<'date' | 'customer' | 'amount'>('date');
  sortOrder: 'asc' | 'desc' = 'desc';
  sortOrder$ = new BehaviorSubject<'asc' | 'desc'>('desc');

  constructor(
    private vouchersService: ExitVouchersService,
    private productsService: ProductsService,
    private customersService: CustomersService,
    private fb: FormBuilder,
    private router: Router
  ) {
    const today = new Date().toISOString().split('T')[0];
    this.voucherForm = this.fb.group({
      voucherNumber: [this.vouchersService.generateVoucherNumber(), Validators.required],
      date: [today, Validators.required],
      customer: ['', Validators.required],
      destination: [''],
      products: this.fb.array([this.createProductLine()]),
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadVouchers();
    this.products$ = this.productsService.getProducts();
    this.customers$ = this.customersService.getCustomers();
    
    this.filteredVouchers$ = combineLatest([
      this.vouchers$,
      this.searchTerm$,
      this.selectedCustomer$,
      this.dateFrom$,
      this.dateTo$,
      this.minAmount$,
      this.maxAmount$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([vouchers, term, customer, dateFrom, dateTo, minAmount, maxAmount, sortBy, sortOrder]) => {
        let filtered = vouchers;
        
        if (term) {
          filtered = filtered.filter(v =>
            v.voucherNumber.toLowerCase().includes(term.toLowerCase())
          );
        }
        
        if (customer) {
          filtered = filtered.filter(v => v.customer === customer);
        }
        
        if (dateFrom) {
          const fromDate = new Date(dateFrom);
          filtered = filtered.filter(v => {
            const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);
            return vDate >= fromDate;
          });
        }
        
        if (dateTo) {
          const toDate = new Date(dateTo);
          toDate.setHours(23, 59, 59);
          filtered = filtered.filter(v => {
            const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);
            return vDate <= toDate;
          });
        }
        
        if (minAmount !== null) {
          filtered = filtered.filter(v => (v.totalAmount || 0) >= minAmount);
        }
        
        if (maxAmount !== null) {
          filtered = filtered.filter(v => (v.totalAmount || 0) <= maxAmount);
        }
        
        filtered = filtered.sort((a, b) => {
          let compareValue = 0;
          if (sortBy === 'date') {
            const dateA = a.date instanceof Timestamp ? a.date.toDate().getTime() : new Date(a.date).getTime();
            const dateB = b.date instanceof Timestamp ? b.date.toDate().getTime() : new Date(b.date).getTime();
            compareValue = dateA - dateB;
          } else if (sortBy === 'customer') {
            compareValue = a.customer.localeCompare(b.customer);
          } else if (sortBy === 'amount') {
            compareValue = (a.totalAmount || 0) - (b.totalAmount || 0);
          }
          return sortOrder === 'asc' ? compareValue : -compareValue;
        });
        
        return filtered;
      })
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
    this.vouchers$ = this.vouchersService.getExitVouchers();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onCustomerFilterChange(customer: string | null): void {
    this.selectedCustomer = customer;
    this.selectedCustomer$.next(customer);
  }

  onDateFromChange(date: string | null): void {
    this.dateFrom = date;
    this.dateFrom$.next(date);
  }

  onDateToChange(date: string | null): void {
    this.dateTo = date;
    this.dateTo$.next(date);
  }

  onMinAmountChange(amount: number | null): void {
    this.minAmount = amount;
    this.minAmount$.next(amount);
  }

  onMaxAmountChange(amount: number | null): void {
    this.maxAmount = amount;
    this.maxAmount$.next(amount);
  }

  onSortChange(sortBy: 'date' | 'customer' | 'amount'): void {
    if (this.sortBy === sortBy) {
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = sortBy;
      this.sortOrder = this.sortBy === 'date' ? 'desc' : 'asc';
    }
    this.sortBy$.next(this.sortBy);
    this.sortOrder$.next(this.sortOrder);
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.searchTerm$.next('');
    this.selectedCustomer = null;
    this.selectedCustomer$.next(null);
    this.dateFrom = null;
    this.dateFrom$.next(null);
    this.dateTo = null;
    this.dateTo$.next(null);
    this.minAmount = null;
    this.minAmount$.next(null);
    this.maxAmount = null;
    this.maxAmount$.next(null);
    this.sortBy = 'date';
    this.sortBy$.next('date');
    this.sortOrder = 'desc';
    this.sortOrder$.next('desc');
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
      voucherNumber: formValue.voucherNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      customer: formValue.customer,
      destination: formValue.destination,
      products: productsWithNames,
      totalAmount: this.calculateTotal(),
      notes: formValue.notes
    };
    
    if (this.isEditing && this.editingId) {
      this.vouchersService.updateExitVoucher(this.editingId, voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.vouchersService.addExitVoucher(voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch((err: any) => {
        this.errorMessage = "Erreur lors de l'ajout.";
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editVoucher(voucher: ExitVoucher): void {
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
      voucherNumber: voucher.voucherNumber,
      date: dateStr,
      customer: voucher.customer,
      destination: voucher.destination,
      notes: voucher.notes
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteVoucher(id: string, voucherNumber: string): void {
    if (confirm(`Supprimer le bon "${voucherNumber}" ?`)) {
      this.isLoading = true;
      this.vouchersService.deleteExitVoucher(id).then(() => {
        this.loadVouchers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productsFormArray.clear();
    this.productsFormArray.push(this.createProductLine());
    const today = new Date().toISOString().split('T')[0];
    this.voucherForm.patchValue({
      voucherNumber: this.vouchersService.generateVoucherNumber(),
      date: today,
      customer: '',
      destination: '',
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

  printList(): void {
    this.filteredVouchers$.pipe(take(1)).subscribe(vouchers => {
      if (vouchers.length === 0) {
        alert('Aucun bon à imprimer.');
        return;
      }
      this.generatePrintHTML(vouchers);
    });
  }

  generatePrintHTML(vouchers: ExitVoucher[]): void {
    const printWindow = window.open("", "_blank", "width=900,height=700");
    if (!printWindow) {
      alert("❌ Popup bloquée !");
      return;
    }

    const today = new Date().toLocaleDateString("fr-FR", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });

    const totalVouchers = vouchers.length;
    const totalAmount = vouchers.reduce((sum, v) => sum + (v.totalAmount || 0), 0);
    const totalProducts = vouchers.reduce((sum, v) => sum + v.products.length, 0);

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.selectedCustomer) filters.push(`Client: ${this.selectedCustomer}`);
    if (this.dateFrom) filters.push(`Date Début: ${new Date(this.dateFrom).toLocaleDateString('fr-FR')}`);
    if (this.dateTo) filters.push(`Date Fin: ${new Date(this.dateTo).toLocaleDateString('fr-FR')}`);
    if (this.minAmount !== null) filters.push(`Montant Min: ${this.minAmount} DT`);
    if (this.maxAmount !== null) filters.push(`Montant Max: ${this.maxAmount} DT`);
    const sortLabels: any = { date: "Date", customer: "Client", amount: "Montant" };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === "asc" ? "↑" : "↓"})`);

    const rows = vouchers.map((v, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${v.voucherNumber}</td>
        <td>${this.formatDate(v.date)}</td>
        <td>${v.customer}</td>
        <td>${v.products.length}</td>
        <td>${(v.totalAmount || 0).toFixed(2)} DT</td>
      </tr>
    `).join("");

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Bons de Sortie - ${today}</title>
        <style>
          @page { margin: 15mm; size: A4 landscape; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 15px; font-size: 10pt; }
          .header { text-align: center; margin-bottom: 15px; border-bottom: 2px solid #dc2626; padding-bottom: 10px; }
          .header h1 { font-size: 20pt; color: #dc2626; margin: 0 0 5px 0; }
          .filters { background: #fef2f2; padding: 8px; margin-bottom: 12px; border-left: 3px solid #dc2626; }
          .filters h3 { font-size: 11pt; margin: 0 0 5px 0; }
          .filters ul { list-style: none; padding: 0; margin: 0; }
          .filters li { font-size: 9pt; margin: 2px 0; }
          .stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin-bottom: 15px; }
          .stat { background: #f9fafb; border: 1px solid #e5e7eb; padding: 8px; text-align: center; }
          .stat .label { font-size: 8pt; color: #666; }
          .stat .value { font-size: 14pt; font-weight: bold; color: #dc2626; }
          table { width: 100%; border-collapse: collapse; }
          thead { background: #dc2626; color: white; }
          th, td { padding: 6px 8px; text-align: left; border: 1px solid #ddd; font-size: 9pt; }
          tbody tr:nth-child(even) { background: #f9fafb; }
          tfoot { background: #fef2f2; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>📤 Bons de Sortie - Liste</h1>
          <p>Date d'impression : ${today}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqués</h3>
          <ul>${filters.map(f => `<li>• ${f}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Bons</div><div class="value">${totalVouchers}</div></div>
          <div class="stat"><div class="label">Total Produits</div><div class="value">${totalProducts}</div></div>
          <div class="stat"><div class="label">Montant Total</div><div class="value">${totalAmount.toFixed(2)} DT</div></div>
        </div>
        <table>
          <thead>
            <tr><th>#</th><th>N° Bon</th><th>Date</th><th>Client</th><th>Produits</th><th>Montant</th></tr>
          </thead>
          <tbody>${rows}</tbody>
          <tfoot>
            <tr><td colspan="4">TOTAL (${totalVouchers} bons)</td><td>${totalProducts}</td><td>${totalAmount.toFixed(2)} DT</td></tr>
          </tfoot>
        </table>
      </body>
      </html>
    `;

    printWindow.document.write(html);
    printWindow.document.close();
    printWindow.focus();
    setTimeout(() => printWindow.print(), 500);
  }

  printItem(item: any): void {
    this.filteredVouchers$.pipe(take(1)).subscribe(vouchers => {
      const voucher = vouchers.find(v => v.id === item.id);
      if (!voucher) return;
      
      const printWindow = window.open("", "_blank", "width=800,height=600");
      if (!printWindow) return;

      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Bon de Sortie ${voucher.voucherNumber}</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { text-align: center; border-bottom: 2px solid #000; }
            table { width: 100%; border-collapse: collapse; margin: 15px 0; }
            th, td { padding: 8px; border: 1px solid #ddd; }
            th { background: #f3f4f6; }
          </style>
        </head>
        <body>
          <h1>Bon de Sortie N° ${voucher.voucherNumber}</h1>
          <table>
            <tr><th>Date</th><td>${this.formatDate(voucher.date)}</td></tr>
            <tr><th>Client</th><td>${voucher.customer}</td></tr>
            ${voucher.destination ? `<tr><th>Destination</th><td>${voucher.destination}</td></tr>` : ''}
          </table>
          <h3>Produits</h3>
          <table>
            <thead>
              <tr><th>Produit</th><th>Quantité</th><th>Prix Unit.</th><th>Sous-total</th></tr>
            </thead>
            <tbody>
              ${voucher.products.map(p => `
                <tr>
                  <td>${p.productName}</td>
                  <td>${p.quantity}</td>
                  <td>${p.unitPrice.toFixed(2)} DT</td>
                  <td>${p.subtotal.toFixed(2)} DT</td>
                </tr>
              `).join("")}
            </tbody>
            <tfoot>
              <tr><th colspan="3">Total</th><th>${(voucher.totalAmount || 0).toFixed(2)} DT</th></tr>
            </tfoot>
          </table>
        </body>
        </html>
      `;
      
      printWindow.document.write(html);
      printWindow.document.close();
      setTimeout(() => {
        printWindow.print();
        printWindow.close();
      }, 250);
    });
  }
}
EOFTS

log_info "✅ exit-voucher.component.ts généré"

# 4. Génération exit-voucher.component.html (copie structure entry avec adaptations)
cat > "$EXIT_HTML" << 'EOFHTML'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Bons de Sortie (Multi-Produits)</h1>

  <div *ngIf="errorMessage" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <strong>Erreur :</strong> {{ errorMessage }}
    <button (click)="errorMessage = ''" class="float-right">&times;</button>
  </div>

  <div class="flex flex-col md:flex-row justify-between items-center mb-4 gap-4">
    <input type="text" [ngModel]="searchTerm" (ngModelChange)="onSearchChange($event)"
           placeholder="🔍 Rechercher par numéro bon..." class="w-full md:w-1/3 px-4 py-2 border rounded-lg" />
    <div class="flex gap-2">
      <button (click)="printList()" class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-lg flex items-center space-x-2 no-print">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path>
        </svg>
        <span>Imprimer Liste</span>
      </button>
      <button (click)="toggleForm()" class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-lg no-print">
        <span *ngIf="!showForm">+ Ajouter Bon</span>
        <span *ngIf="showForm">Fermer</span>
      </button>
    </div>
  </div>

  <!-- Filtres Avancés -->
  <div class="bg-white shadow-md rounded-lg p-4 mb-6 no-print">
    <h3 class="text-lg font-semibold mb-3 flex items-center">
      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path>
      </svg>
      Filtres Avancés
    </h3>
    
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Client</label>
        <ng-select [ngModel]="selectedCustomer" (ngModelChange)="onCustomerFilterChange($event)"
                   [items]="(customers$ | async) ?? []" bindLabel="name" bindValue="name"
                   placeholder="Tous" [clearable]="true" class="w-full"></ng-select>
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Date Début</label>
        <input type="date" [ngModel]="dateFrom" (ngModelChange)="onDateFromChange($event)" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Date Fin</label>
        <input type="date" [ngModel]="dateTo" (ngModelChange)="onDateToChange($event)" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Trier par</label>
        <select [ngModel]="sortBy" (ngModelChange)="onSortChange($event)" class="w-full px-3 py-2 border rounded-lg">
          <option value="date">Date {{ sortBy === 'date' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="customer">Client {{ sortBy === 'customer' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="amount">Montant {{ sortBy === 'amount' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
        </select>
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Montant Min (DT)</label>
        <input type="number" [ngModel]="minAmount" (ngModelChange)="onMinAmountChange($event)" placeholder="0" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Montant Max (DT)</label>
        <input type="number" [ngModel]="maxAmount" (ngModelChange)="onMaxAmountChange($event)" placeholder="10000" class="w-full px-3 py-2 border rounded-lg" />
      </div>
    </div>
    
    <div class="mt-4">
      <button (click)="clearFilters()" class="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded-lg">
        Réinitialiser Filtres
      </button>
    </div>
  </div>

  <!-- Formulaire (structure identique entry avec customer) -->
  <div *ngIf="showForm" class="bg-white shadow-md rounded-lg p-6 mb-6 no-print">
    <h2 class="text-2xl font-semibold mb-4">{{ isEditing ? 'Modifier' : 'Nouveau' }} Bon de Sortie</h2>
    <form [formGroup]="voucherForm" (ngSubmit)="onSubmit()" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">N° Bon *</label>
          <input formControlName="voucherNumber" type="text" class="w-full px-4 py-2 border rounded-lg bg-gray-100" readonly />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Date *</label>
          <input formControlName="date" type="date" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Client *</label>
          <ng-select formControlName="customer" [items]="(customers$ | async) ?? []" bindLabel="name" bindValue="name" placeholder="-- Sélectionnez --" [searchable]="true" [clearable]="true" class="w-full"></ng-select>
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Destination</label>
          <input formControlName="destination" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
      </div>

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
              <label class="block text-sm text-gray-600 mb-1">Prix Unit. (DT) *</label>
              <input formControlName="unitPrice" type="number" step="0.01" class="w-full px-3 py-2 border rounded" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">Sous-total</label>
              <input [value]="calculateSubtotal(i) | number:'1.2-2'" readonly class="w-full px-3 py-2 border rounded bg-gray-100" />
            </div>
            <div class="md:col-span-2 flex gap-2">
              <button type="button" (click)="addProductLine()" class="bg-blue-500 text-white px-3 py-2 rounded">+</button>
              <button type="button" (click)="removeProductLine(i)" [disabled]="productsFormArray.length === 1"
                      class="bg-red-500 text-white px-3 py-2 rounded disabled:bg-gray-300">-</button>
            </div>
          </div>
        </div>
        <div class="mt-4 bg-red-50 p-4 rounded">
          <div class="flex justify-between text-xl font-bold">
            <span>Total :</span>
            <span class="text-red-600">{{ calculateTotal() | number:'1.2-2' }} DT</span>
          </div>
        </div>
      </div>

      <div>
        <label class="block text-gray-700 font-medium mb-2">Notes</label>
        <textarea formControlName="notes" rows="2" class="w-full px-4 py-2 border rounded-lg"></textarea>
      </div>

      <div class="flex gap-4">
        <button type="submit" [disabled]="isLoading || voucherForm.invalid"
                class="bg-red-600 hover:bg-red-700 text-white font-bold py-2 px-6 rounded-lg disabled:bg-gray-400">
          <span *ngIf="isLoading">Enregistrement...</span>
          <span *ngIf="!isLoading">{{ isEditing ? 'Mettre à jour' : 'Créer Bon' }}</span>
        </button>
        <button type="button" (click)="resetForm()" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-lg">Annuler</button>
      </div>
    </form>
  </div>

  <!-- Liste Accordions -->
  <div *ngIf="!isLoading" class="space-y-4">
    <div *ngFor="let voucher of filteredVouchers$ | async" class="bg-white shadow rounded-lg overflow-hidden voucher-card" [attr.data-id]="voucher.id">
      <div class="px-6 py-4 flex justify-between items-center cursor-pointer hover:bg-gray-50"
           (click)="toggleExpand(voucher.id!)">
        <div class="flex-1 grid grid-cols-4 gap-4">
          <div><strong>N° :</strong> {{ voucher.voucherNumber }}</div>
          <div><strong>Date:</strong> {{ formatDate(voucher.date) }}</div>
          <div><strong>Client:</strong> {{ voucher.customer }}</div>
          <div><strong>Total:</strong> {{ voucher.totalAmount | number:'1.2-2' }} DT</div>
        </div>
        <button class="text-red-600 no-print">{{ expandedVoucherId === voucher.id ? '▼' : '►' }}</button>
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
              <td class="px-4 py-2">{{ line.unitPrice | number:'1.2-2' }} DT</td>
              <td class="px-4 py-2 font-semibold">{{ line.subtotal | number:'1.2-2' }} DT</td>
            </tr>
            <tr class="bg-red-50 font-bold">
              <td colspan="3" class="px-4 py-2 text-right">Total :</td>
              <td class="px-4 py-2 text-red-600">{{ voucher.totalAmount | number:'1.2-2' }} DT</td>
            </tr>
          </tbody>
        </table>
        <div class="mt-4 flex gap-2 no-print">
          <button (click)="editVoucher(voucher)" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded">Modifier</button>
          <button (click)="deleteVoucher(voucher.id!, voucher.voucherNumber)" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded">Supprimer</button>
          <button (click)="printItem(voucher)" class="bg-purple-600 hover:bg-purple-700 text-white px-4 py-2 rounded">Imprimer ce Bon</button>
        </div>
      </div>
    </div>
    <div *ngIf="(filteredVouchers$ | async)?.length === 0" class="text-center py-8 text-gray-500">
      Aucun bon trouvé.
    </div>
  </div>
</div>
EOFHTML

log_info "✅ exit-voucher.component.html généré"

# 5. Fix route Exit Voucher (loadComponent lazy)
APP_MODULE="src/app/app.module.ts"
if grep -q "ExitVoucherComponent" "$APP_MODULE"; then
    sed -i '' "s|{ path: 'exit-voucher', component: ExitVoucherComponent }|{ path: 'exit-voucher', loadComponent: () => import('./components/exit-voucher/exit-voucher.component').then(m => m.ExitVoucherComponent) }|" "$APP_MODULE"
    sed -i '' '/import.*ExitVoucherComponent.*from/d' "$APP_MODULE"
    sed -i '' '/ExitVoucherComponent,/d' "$APP_MODULE"
    log_info "✅ Route Exit Voucher corrigée (loadComponent lazy)"
fi

# Validation
if command -v ng &> /dev/null; then
    log_info "Validation..."
    ng cache clean
    npx tsc --noEmit 2>&1 | tee -a "$LOG_FILE"
    if [ $? -eq 0 ]; then
        log_info "✅ TS OK!"
    fi
fi

echo ""
echo "=========================================="
echo "  ✅ Filtres + Imprimer Liste (Exit Voucher)"
echo "=========================================="
echo "Fonctionnalités :"
echo "  - Filtres : Recherche, Client, Dates, Montant, Tri"
echo "  - Bouton 'Imprimer Liste' (bons filtrés)"
echo "  - Bouton 'Imprimer ce Bon' (individuel)"
echo "  - Route lazy loading (loadComponent)"
echo ""
echo "Test :"
echo "  1. RESTART: ng serve"
echo "  2. /exit-voucher → Filtres fonctionnent"
echo "  3. Click 'Imprimer Liste' → Popup bons filtrés"
echo ""
echo "Logs : $LOG_FILE"
echo "Revert : cp *.backup.exitfilters *"
