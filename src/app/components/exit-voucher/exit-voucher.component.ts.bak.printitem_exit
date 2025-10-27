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
  // Observables for data
  vouchers$!: Observable<ExitVoucher[]>;
  filteredVouchers$!: Observable<ExitVoucher[]>;
  products$!: Observable<Product[]>;
  customers$!: Observable<Customer[]>;
  productList: Product[] = []; // Synchronous cache

  // Form and state
  voucherForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  showForm = false;
  expandedVoucherId: string | null = null;

  // Filter Properties & BehaviorSubjects
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
    // Correctly subscribe ONCE to populate productList
    this.products$.subscribe((products) => {
       this.productList = products;
    });
    this.customers$ = this.customersService.getCustomers();

    // Setup the filtered observable pipeline
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

          // Apply filters
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

          // Apply sorting
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
        },
      ),
    );
  }

  // --- Form Array Methods ---
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

  // --- Data Loading ---
  loadVouchers(): void {
    this.vouchers$ = this.vouchersService.getExitVouchers();
  }

  // --- Filter Methods ---
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

  // --- CRUD Methods ---
  onSubmit(): void {
    if (this.voucherForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.voucherForm.value;

    const productsWithNames: ProductLine[] = formValue.products.map((p: any) => {
        const product = this.productList.find(prod => prod.id === p.productId);
        const productName = product ? product.name : 'Produit_Inconnu';
        const description = product ? (product.description || 'Pas_de_description') : 'Pas_de_description';
        const subtotal = (p.quantity || 0) * (p.unitPrice || 0);

        return {
          ...p,
          productName: productName,
          description: description,
          subtotal: subtotal,
        };
    });

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

  // --- UI Methods ---
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

  // --- Helper Methods ---
  getProductName(productId: string): string {
    const product = this.productList.find(p => p.id === productId);
    return product ? product.name : "Produit_Inconnu";
  }

  getDescription(productId: string): string {
    const prod = this.productList.find(p => p.id === productId);
    return prod?.description || "Pas_de_description";
  }

   getSubtotal(line: any): number {
     const quantity = line && typeof line.quantity === 'number' ? line.quantity : 0;
     const unitPrice = line && typeof line.unitPrice === 'number' ? line.unitPrice : 0;
     return quantity * unitPrice;
   }

  formatDate(timestamp: Timestamp | Date): string {
    if (timestamp instanceof Timestamp) {
      return timestamp.toDate().toLocaleDateString('fr-FR');
    }
    return new Date(timestamp).toLocaleDateString('fr-FR');
  }

  // --- Print Methods ---
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
    if (!printWindow) { alert('❌ Popup bloquée !'); return; }

    const today = new Date().toLocaleDateString('fr-FR', { /* options */ });
    const totalVouchers = vouchers.length;
    const totalAmount = vouchers.reduce((sum, v) => sum + (v.totalAmount || 0), 0);
    const totalProducts = vouchers.reduce((sum, v) => sum + v.products.length, 0);
    const filters: string[] = [];
    // ... Build filters array ...
     if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
     if (this.selectedCustomer) filters.push(`Client: ${this.selectedCustomer}`);
     if (this.dateFrom) filters.push(`Date Début: ${new Date(this.dateFrom).toLocaleDateString('fr-FR')}`);
     if (this.dateTo) filters.push(`Date Fin: ${new Date(this.dateTo).toLocaleDateString('fr-FR')}`);
     if (this.minAmount !== null) filters.push(`Montant Min: ${this.minAmount} DT`);
     if (this.maxAmount !== null) filters.push(`Montant Max: ${this.maxAmount} DT`);
     const sortLabels: any = { date: 'Date', customer: 'Client', amount: 'Montant' };
     filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === 'asc' ? '↑' : '↓'})`);

    const rows = vouchers.map((v, i) => `<tr>...</tr>` ).join(''); // Simplified for brevity

    const html = `<!DOCTYPE html><html><head>...</head><body>...<table>...<tbody>${rows}</tbody>...</table></body></html>`; // Simplified

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

      // Ensure description is included here when generating product rows
      const productRows = voucher.products.map(p => `
        <tr>
          <td>${p.productName}</td>
          <td class="description">${this.getDescription(p.productId)}</td> {/* Added call */}
          <td>${p.quantity}</td>
          <td>${p.unitPrice.toFixed(2)} DT</td>
          <td>${p.subtotal.toFixed(2)} DT</td>
        </tr>
      `).join('');

      const html = `<!DOCTYPE html><html><head>...<style>... .description { font-size: 10px; color: #666; font-style: italic; max-width: 150px; word-wrap: break-word; } ...</style></head><body>
          <h1>Bon de Sortie N° ${voucher.voucherNumber}</h1>
          <table>...</table>
          <h3>Produits</h3>
          <table><thead><tr><th>Produit</th><th>Description</th><th>Quantité</th><th>Prix Unit.</th><th>Sous-total</th></tr></thead>
            <tbody>${productRows}</tbody>
            <tfoot><tr><th colspan="4">Total</th><th>${(voucher.totalAmount || 0).toFixed(2)} DT</th></tr></tfoot>
          </table>
        </body></html>`; // Simplified headers and structure

      printWindow.document.write(html);
      printWindow.document.close();
      setTimeout(() => {
        printWindow.print();
        printWindow.close();
      }, 250);
    });
  }
onProductSelected(event: Event, index: number): void {
    const selectElement = event.target as HTMLSelectElement;
    const productId = selectElement.value;
    const productLine = this.productsFormArray.at(index);

    if (!productId || !productLine) {
      productLine?.patchValue({ unitPrice: 0 }); // Reset price if no selection
      return;
    }

    // Find the product in the synchronous list productList
    const selectedProduct = this.productList.find(p => p.id === productId);

    if (selectedProduct) {
      // Update the unit price in the form for this line
      productLine.patchValue({ unitPrice: selectedProduct.price });
      // You could optionally add quantity validation here too
      // const quantityControl = productLine.get('quantity');
      // quantityControl?.setValidators([... existing validators ..., Validators.max(selectedProduct.quantity)]);
      // quantityControl?.updateValueAndValidity();
    } else {
      // If product not found (shouldn't happen if productList is up-to-date)
      productLine.patchValue({ unitPrice: 0 });
      console.warn(`Product not found in productList: ${productId}`);
    }
  }
} // End of class ExitVoucherComponent