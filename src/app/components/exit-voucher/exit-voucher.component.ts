import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { NgSelectModule } from '@ng-select/ng-select';
import { ExitVoucher, ProductLine } from '../../models/exit-voucher';
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
  standalone: true,
})
export class ExitVoucherComponent implements OnInit {
  vouchers$!: Observable<ExitVoucher[]>;
  filteredVouchers$!: Observable<ExitVoucher[]>;
  products$!: Observable<Product[]>;
  productList: Product[] = [];
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
    private router: Router,
  ) {
    const today = new Date().toISOString().split('T')[0];
    this.voucherForm = this.fb.group({
      voucherNumber: [this.vouchersService.generateVoucherNumber(), Validators.required],
      date: [today, Validators.required],
      customer: ['', Validators.required],
      destination: [''],
      products: this.fb.array([this.createProductLine()]),
      notes: [''],
    });
  }

  ngOnInit(): void {
    this.loadVouchers();
    this.products$ = this.productsService.getProducts();
    this.products$.subscribe((p) => (this.productList = p));
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
      this.sortOrder$,
    ]).pipe(
      map(
        ([vouchers, term, customer, dateFrom, dateTo, minAmount, maxAmount, sortBy, sortOrder]) => {
          let filtered = vouchers;

          if (term) {
            filtered = filtered.filter((v) =>
              v.voucherNumber.toLowerCase().includes(term.toLowerCase()),
            );
          }

          if (customer) {
            filtered = filtered.filter((v) => v.customer === customer);
          }

          if (dateFrom) {
            const fromDate = new Date(dateFrom);
            filtered = filtered.filter((v) => {
              const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);
              return vDate >= fromDate;
            });
          }

          if (dateTo) {
            const toDate = new Date(dateTo);
            toDate.setHours(23, 59, 59);
            filtered = filtered.filter((v) => {
              const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);
              return vDate <= toDate;
            });
          }

          if (minAmount !== null) {
            filtered = filtered.filter((v) => (v.totalAmount || 0) >= minAmount);
          }

          if (maxAmount !== null) {
            filtered = filtered.filter((v) => (v.totalAmount || 0) <= maxAmount);
          }

          filtered = filtered.sort((a, b) => {
            let compareValue = 0;
            if (sortBy === 'date') {
              const dateA =
                a.date instanceof Timestamp
                  ? a.date.toDate().getTime()
                  : new Date(a.date).getTime();
              const dateB =
                b.date instanceof Timestamp
                  ? b.date.toDate().getTime()
                  : new Date(b.date).getTime();
              compareValue = dateA - dateB;
            } else if (sortBy === 'customer') {
              compareValue = a.customer.localeCompare(b.customer);
            } else if (sortBy === 'amount') {
              compareValue = (a.totalAmount || 0) - (b.totalAmount || 0);
            }
            return sortOrder === 'asc' ? compareValue : -compareValue;
          });

          return filtered;
        },
      ),
    );
  }

  get productsFormArray(): FormArray {
    return this.voucherForm.get('products') as FormArray;
  }

  createProductLine(): FormGroup {
    return this.fb.group({
      productId: ['', Validators.required],
      quantity: [1, [Validators.required, Validators.min(1)]],
      unitPrice: [0, [Validators.required, Validators.min(0.01)]],
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
      return sum + (line.quantity || 0) * (line.unitPrice || 0);
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
      subtotal: p.quantity * p.unitPrice,
    }));

    const voucherData = {
      voucherNumber: formValue.voucherNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      customer: formValue.customer,
      destination: formValue.destination,
      products: productsWithNames,
      totalAmount: this.calculateTotal(),
      notes: formValue.notes,
    };

    if (this.isEditing && this.editingId) {
      this.vouchersService
        .updateExitVoucher(this.editingId, voucherData)
        .then(() => {
          this.resetForm();
          this.loadVouchers();
        })
        .catch((err: any) => {
          this.errorMessage = 'Erreur lors de la modification.';
          console.error(err);
        })
        .finally(() => (this.isLoading = false));
    } else {
      this.vouchersService
        .addExitVoucher(voucherData)
        .then(() => {
          this.resetForm();
          this.loadVouchers();
        })
        .catch((err: any) => {
          this.errorMessage = "Erreur lors de l'ajout.";
          console.error(err);
        })
        .finally(() => (this.isLoading = false));
    }
  }

  editVoucher(voucher: ExitVoucher): void {
    this.isEditing = true;
    this.editingId = voucher.id || null;
    const dateStr = (voucher.date as Timestamp).toDate().toISOString().split('T')[0];

    this.productsFormArray.clear();
    voucher.products.forEach((p) => {
      this.productsFormArray.push(
        this.fb.group({
          productId: [p.productId, Validators.required],
          quantity: [p.quantity, [Validators.required, Validators.min(1)]],
          unitPrice: [p.unitPrice, [Validators.required, Validators.min(0.01)]],
        }),
      );
    });

    this.voucherForm.patchValue({
      voucherNumber: voucher.voucherNumber,
      date: dateStr,
      customer: voucher.customer,
      destination: voucher.destination,
      notes: voucher.notes,
    });

    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteVoucher(id: string, voucherNumber: string): void {
    if (confirm(`Supprimer le bon "${voucherNumber}" ?`)) {
      this.isLoading = true;
      this.vouchersService
        .deleteExitVoucher(id)
        .then(() => {
          this.loadVouchers();
        })
        .catch((err: any) => {
          this.errorMessage = 'Erreur lors de la suppression.';
          console.error(err);
        })
        .finally(() => (this.isLoading = false));
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
      notes: '',
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
    this.products$.subscribe((products) => {
      const product = products.find((p) => p.id === productId);
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
    this.filteredVouchers$.pipe(take(1)).subscribe((vouchers) => {
      if (vouchers.length === 0) {
        alert('Aucun bon à imprimer.');
        return;
      }
      this.generatePrintHTML(vouchers);
    });
  }

  generatePrintHTML(vouchers: ExitVoucher[]): void {
    const printWindow = window.open('', '_blank', 'width=900,height=700');
    if (!printWindow) {
      alert('❌ Popup bloquée !');
      return;
    }

    const today = new Date().toLocaleDateString('fr-FR', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });

    const totalVouchers = vouchers.length;
    const totalAmount = vouchers.reduce((sum, v) => sum + (v.totalAmount || 0), 0);
    const totalProducts = vouchers.reduce((sum, v) => sum + v.products.length, 0);

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.selectedCustomer) filters.push(`Client: ${this.selectedCustomer}`);
    if (this.dateFrom)
      filters.push(`Date Début: ${new Date(this.dateFrom).toLocaleDateString('fr-FR')}`);
    if (this.dateTo) filters.push(`Date Fin: ${new Date(this.dateTo).toLocaleDateString('fr-FR')}`);
    if (this.minAmount !== null) filters.push(`Montant Min: ${this.minAmount} DT`);
    if (this.maxAmount !== null) filters.push(`Montant Max: ${this.maxAmount} DT`);
    const sortLabels: any = { date: 'Date', customer: 'Client', amount: 'Montant' };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === 'asc' ? '↑' : '↓'})`);

    const rows = vouchers
      .map(
        (v, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${v.voucherNumber}</td>
        <td>${this.formatDate(v.date)}</td>
        <td>${v.customer}</td>
        <td>${v.products.length}</td>
        <td>${(v.totalAmount || 0).toFixed(2)} DT</td>
      </tr>
    `,
      )
      .join('');

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
          <ul>${filters.map((f) => `<li>• ${f}</li>`).join('')}</ul>
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
    this.filteredVouchers$.pipe(take(1)).subscribe((vouchers) => {
      const voucher = vouchers.find((v) => v.id === item.id);
      if (!voucher) return;

      const printWindow = window.open('', '_blank', 'width=800,height=600');
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
              ${voucher.products
                .map(
                  (p) => `
                <tr>
                  <td>${p.productName}</td>
                  <td>${p.quantity}</td>
                  <td>${p.unitPrice.toFixed(2)} DT</td>
                  <td>${p.subtotal.toFixed(2)} DT</td>
                </tr>
              `,
                )
                .join('')}
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
