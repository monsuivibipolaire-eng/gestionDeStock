import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { NgSelectModule } from '@ng-select/ng-select';
import { Devis, ProductLine } from "../../models/devis";
import { DevisService } from '../../services/devis.service';
import { ProductsService } from '../../services/products.service';
import { CustomersService } from '../../services/customers.service';
import { Product } from '../../models/product';
import { Customer } from '../../models/customer';

@Component({
  selector: 'app-devis',
  templateUrl: './devis.component.html',
  styleUrls: ['./devis.component.scss'],
  imports: [ReactiveFormsModule, NgSelectModule, CommonModule, FormsModule],
  standalone: true
})
export class DevisComponent implements OnInit {
  // Observables for data
  devisList$!: Observable<Devis[]>;
  filteredDevis$!: Observable<Devis[]>;
  products$!: Observable<Product[]>;
  customers$!: Observable<Customer[]>;
  productList: Product[] = []; // Synchronous cache

  // Form and state
  devisForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  showForm = false;
  expandedDevisId: string | null = null;

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
  statusFilter: 'all' | 'draft' | 'sent' | 'accepted' | 'rejected' = 'all';
  statusFilter$ = new BehaviorSubject<'all' | 'draft' | 'sent' | 'accepted' | 'rejected'>('all');
  sortBy: 'date' | 'customer' | 'amount' = 'date';
  sortBy$ = new BehaviorSubject<'date' | 'customer' | 'amount'>('date');
  sortOrder: 'asc' | 'desc' = 'desc';
  sortOrder$ = new BehaviorSubject<'asc' | 'desc'>('desc');

  constructor(
    private devisService: DevisService,
    private productsService: ProductsService,
    private customersService: CustomersService,
    private fb: FormBuilder,
    private router: Router
  ) {
    const today = new Date().toISOString().split('T')[0];
    const validUntil = new Date();
    validUntil.setDate(validUntil.getDate() + 30); // Default validity: 30 days

    this.devisForm = this.fb.group({
      quoteNumber: [this.devisService.generateQuoteNumber(), Validators.required],
      date: [today, Validators.required],
      customer: ['', Validators.required],
      validUntil: [validUntil.toISOString().split('T')[0]],
      products: this.fb.array([this.createProductLine()]),
      notes: [''],
      status: ['draft', Validators.required]
    });
  }

  ngOnInit(): void {
    this.loadDevis();
    this.products$ = this.productsService.getProducts();
    // Subscribe to products$ to populate productList
    this.products$.subscribe((products) => {
      this.productList = products;
    });
    this.customers$ = this.customersService.getCustomers();

    // Setup the filtered observable pipeline
    this.filteredDevis$ = combineLatest([
      this.devisList$,
      this.searchTerm$,
      this.selectedCustomer$,
      this.dateFrom$,
      this.dateTo$,
      this.minAmount$,
      this.maxAmount$,
      this.statusFilter$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([devisList, term, customer, dateFrom, dateTo, minAmount, maxAmount, status, sortBy, sortOrder]) => {
        let filtered = devisList;

        // Apply filters
        if (term) {
          filtered = filtered.filter(d =>
            d.quoteNumber.toLowerCase().includes(term.toLowerCase())
          );
        }
        if (customer) {
          filtered = filtered.filter(d => d.customer === customer);
        }
        if (dateFrom) {
          const fromDate = new Date(dateFrom);
          filtered = filtered.filter(d => {
            const dDate = d.date instanceof Timestamp ? d.date.toDate() : new Date(d.date);
            return dDate >= fromDate;
          });
        }
        if (dateTo) {
          const toDate = new Date(dateTo);
          toDate.setHours(23, 59, 59);
          filtered = filtered.filter(d => {
            const dDate = d.date instanceof Timestamp ? d.date.toDate() : new Date(d.date);
            return dDate <= toDate;
          });
        }
        if (minAmount !== null) {
          filtered = filtered.filter(d => (d.totalAmount || 0) >= minAmount);
        }
        if (maxAmount !== null) {
          filtered = filtered.filter(d => (d.totalAmount || 0) <= maxAmount);
        }
        if (status !== 'all') {
          filtered = filtered.filter(d => (d.status || 'draft') === status);
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
      })
    );
  }

  // --- Form Array Methods ---
  get productsFormArray(): FormArray {
    return this.devisForm.get('products') as FormArray;
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

  onProductSelected(event: Event, index: number): void {
    const selectElement = event.target as HTMLSelectElement;
    const productId = selectElement.value;
    const productLine = this.productsFormArray.at(index);

    if (!productId || !productLine) {
      productLine?.patchValue({ unitPrice: 0 });
      return;
    }
    const selectedProduct = this.productList.find(p => p.id === productId);
    if (selectedProduct) {
      productLine.patchValue({ unitPrice: selectedProduct.price });
    } else {
      productLine.patchValue({ unitPrice: 0 });
      console.warn(`Produit non trouvé dans productList: ${productId}`);
    }
  }

  calculateSubtotal(index: number): number {
    const line = this.productsFormArray.at(index)?.value;
    return (line?.quantity || 0) * (line?.unitPrice || 0);
  }

  calculateTotal(): number {
    return this.productsFormArray.controls.reduce((sum, control) => {
      const line = control.value;
      return sum + ((line.quantity || 0) * (line.unitPrice || 0));
    }, 0);
  }

  // --- Data Loading ---
  loadDevis(): void {
    this.devisList$ = this.devisService.getDevis();
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

  onStatusFilterChange(status: 'all' | 'draft' | 'sent' | 'accepted' | 'rejected'): void {
    this.statusFilter = status;
    this.statusFilter$.next(status);
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
    this.searchTerm = ''; this.searchTerm$.next('');
    this.selectedCustomer = null; this.selectedCustomer$.next(null);
    this.dateFrom = null; this.dateFrom$.next(null);
    this.dateTo = null; this.dateTo$.next(null);
    this.minAmount = null; this.minAmount$.next(null);
    this.maxAmount = null; this.maxAmount$.next(null);
    this.statusFilter = 'all'; this.statusFilter$.next('all');
    this.sortBy = 'date'; this.sortBy$.next('date');
    this.sortOrder = 'desc'; this.sortOrder$.next('desc');
  }

  // --- CRUD Methods ---
  onSubmit(): void {
    if (this.devisForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.devisForm.value;

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

    const devisData: any = {
      quoteNumber: formValue.quoteNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      customer: formValue.customer,
      products: productsWithNames,
      totalAmount: this.calculateTotal(),
      notes: formValue.notes,
      status: formValue.status || 'draft'
    };

    if (formValue.validUntil) {
      try {
        devisData.validUntil = Timestamp.fromDate(new Date(formValue.validUntil));
      } catch (e) {
        console.warn("Invalid date format for validUntil:", formValue.validUntil);
      }
    }

    if (this.isEditing && this.editingId) {
      this.devisService.updateDevis(this.editingId, devisData).then(() => {
        this.resetForm();
        this.loadDevis();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.devisService.addDevis(devisData).then(() => {
        this.resetForm();
        this.loadDevis();
      }).catch((err: any) => {
        this.errorMessage = "Erreur lors de l'ajout.";
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editDevis(devis: Devis): void {
    this.isEditing = true;
    this.editingId = devis.id || null;
    const dateStr = devis.date instanceof Timestamp ? devis.date.toDate().toISOString().split('T')[0] : '';
    const validStr = devis.validUntil instanceof Timestamp ? devis.validUntil.toDate().toISOString().split('T')[0] : '';

    this.productsFormArray.clear();
    devis.products.forEach(p => {
      this.productsFormArray.push(this.fb.group({
        productId: [p.productId, Validators.required],
        quantity: [p.quantity, [Validators.required, Validators.min(1)]],
        unitPrice: [p.unitPrice, [Validators.required, Validators.min(0.01)]]
      }));
    });

    this.devisForm.patchValue({
      quoteNumber: devis.quoteNumber,
      date: dateStr,
      customer: devis.customer,
      validUntil: validStr,
      notes: devis.notes,
      status: devis.status || 'draft'
    });

    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteDevis(id: string, quoteNumber: string): void {
    if (confirm(`Supprimer le devis "${quoteNumber}" ?`)) {
      this.isLoading = true;
      this.devisService.deleteDevis(id).then(() => {
        this.loadDevis();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  // --- UI Methods ---
  resetForm(): void {
    this.productsFormArray.clear();
    this.productsFormArray.push(this.createProductLine());
    const today = new Date().toISOString().split('T')[0];
    const validUntil = new Date();
    validUntil.setDate(validUntil.getDate() + 30);

    this.devisForm.patchValue({
      quoteNumber: this.devisService.generateQuoteNumber(),
      date: today,
      customer: '',
      validUntil: validUntil.toISOString().split('T')[0],
      notes: '',
      status: 'draft'
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

  toggleExpand(devisId: string): void {
    this.expandedDevisId = this.expandedDevisId === devisId ? null : devisId;
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

  formatDate(timestamp: Timestamp | Date | undefined | null): string { // Handle undefined/null
    if (!timestamp) return '-';
    let date: Date;
    if (timestamp instanceof Timestamp) {
      date = timestamp.toDate();
    } else {
      date = new Date(timestamp);
    }
    return !isNaN(date.getTime()) ? date.toLocaleDateString('fr-FR') : '-';
  }

  getStatusLabel(status?: string): string {
    const effectiveStatus = status || 'draft';
    const labels: any = {
      draft: 'Brouillon',
      sent: 'Envoyé',
      accepted: 'Accepté',
      rejected: 'Rejeté'
    };
    return labels[effectiveStatus] || effectiveStatus;
  }

  getStatusClass(status?: string): string {
    const effectiveStatus = status || 'draft';
    const classes: any = {
      draft: 'bg-gray-100 text-gray-800',
      sent: 'bg-blue-100 text-blue-800',
      accepted: 'bg-green-100 text-green-800',
      rejected: 'bg-red-100 text-red-800'
    };
    return classes[effectiveStatus] || 'bg-gray-100 text-gray-800';
  }


  // --- Print Methods ---
  printList(): void {
    this.filteredDevis$.pipe(take(1)).subscribe(devisList => {
      if (!devisList || devisList.length === 0) {
        alert('Aucun devis à imprimer.');
        return;
      }
      this.generatePrintHTML(devisList);
    });
  }

  // **** CORRECTED generatePrintHTML METHOD ****
  generatePrintHTML(devisList: Devis[]): void {
    const printWindow = window.open("", "_blank", "width=900,height=700");
    if (!printWindow) {
      alert("❌ Popup bloquée !");
      return;
    }

    const today = new Date().toLocaleDateString("fr-FR", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });

    const totalDevis = devisList.length;
    const totalAmount = devisList.reduce((sum, d) => sum + (d.totalAmount || 0), 0);
    const totalProducts = devisList.reduce((sum, d) => sum + d.products.length, 0);
    const statusCounts = {
      draft: devisList.filter(d => (d.status || 'draft') === 'draft').length,
      sent: devisList.filter(d => d.status === 'sent').length,
      accepted: devisList.filter(d => d.status === 'accepted').length,
      rejected: devisList.filter(d => d.status === 'rejected').length
    };

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.selectedCustomer) filters.push(`Client: ${this.selectedCustomer}`);
    if (this.dateFrom) filters.push(`Date Début: ${new Date(this.dateFrom).toLocaleDateString('fr-FR')}`);
    if (this.dateTo) filters.push(`Date Fin: ${new Date(this.dateTo).toLocaleDateString('fr-FR')}`);
    if (this.minAmount !== null) filters.push(`Montant Min: ${this.minAmount} DT`);
    if (this.maxAmount !== null) filters.push(`Montant Max: ${this.maxAmount} DT`);
    if (this.statusFilter !== 'all') filters.push(`Statut: ${this.getStatusLabel(this.statusFilter)}`);
    const sortLabels: any = { date: "Date", customer: "Client", amount: "Montant" };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === "asc" ? "↑" : "↓"})`);

    const rows = devisList.map((d, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${d.quoteNumber}</td>
        <td>${this.formatDate(d.date)}</td>
        <td>${d.customer}</td>
        <td>${d.products.length}</td>
        <td><span class="badge badge-${d.status || 'draft'}">${this.getStatusLabel(d.status)}</span></td>
        <td>${(d.totalAmount || 0).toFixed(2)} DT</td>
      </tr>
    `).join("");

    // ** CORRECTED HTML STRING (No backslashes before ${...}) **
    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Devis - ${today}</title>
        <style>
          @page { margin: 15mm; size: A4 landscape; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 15px; font-size: 10pt; }
          .header { text-align: center; margin-bottom: 15px; border-bottom: 2px solid #8b5cf6; padding-bottom: 10px; }
          .header h1 { font-size: 20pt; color: #8b5cf6; margin: 0 0 5px 0; }
          .filters { background: #f5f3ff; padding: 8px; margin-bottom: 12px; border-left: 3px solid #8b5cf6; }
          .filters h3 { font-size: 11pt; margin: 0 0 5px 0; }
          .filters ul { list-style: none; padding: 0; margin: 0; }
          .filters li { font-size: 9pt; margin: 2px 0; }
          .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 15px; }
          .stat { background: #f9fafb; border: 1px solid #e5e7eb; padding: 8px; text-align: center; }
          .stat .label { font-size: 8pt; color: #666; }
          .stat .value { font-size: 14pt; font-weight: bold; color: #8b5cf6; }
          table { width: 100%; border-collapse: collapse; }
          thead { background: #8b5cf6; color: white; }
          th, td { padding: 6px 8px; text-align: left; border: 1px solid #ddd; font-size: 9pt; }
          tbody tr:nth-child(even) { background: #f9fafb; }
          tfoot { background: #f5f3ff; font-weight: bold; }
          /* Badge styles for print */
          .badge { display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 8pt; font-weight: bold; border: 1px solid #ccc; background: #fff; color: #000;}
          .badge-draft { border-color: #9ca3af; }
          .badge-sent { border-color: #3b82f6; }
          .badge-accepted { border-color: #10b981; }
          .badge-rejected { border-color: #ef4444; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>📄 Devis - Liste</h1>
          <p>Date d'impression : ${today}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqués</h3>
          <ul>${filters.map(f => `<li>• ${f}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Devis</div><div class="value">${totalDevis}</div></div>
          <div class="stat"><div class="label">Total Produits</div><div class="value">${totalProducts}</div></div>
          <div class="stat"><div class="label">Montant Total</div><div class="value">${totalAmount.toFixed(2)} DT</div></div>
          <div class="stat"><div class="label">Acceptés</div><div class="value">${statusCounts.accepted}</div></div>
        </div>
        <table>
          <thead>
            <tr><th>#</th><th>N° Devis</th><th>Date</th><th>Client</th><th>Produits</th><th>Statut</th><th>Montant</th></tr>
          </thead>
          <tbody>${rows}</tbody>
          <tfoot>
            <tr><td colspan="4">TOTAL (${totalDevis} devis)</td><td>${totalProducts}</td><td>-</td><td>${totalAmount.toFixed(2)} DT</td></tr>
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

  // **** CORRECTED printItem METHOD ****
  printItem(item: any): void {
    this.filteredDevis$.pipe(take(1)).subscribe(devisList => {
      const devis = devisList.find(d => d.id === item.id);
      if (!devis) {
        console.error('Devis non trouvé pour impression:', item.id);
        alert('Erreur : Devis non trouvé.');
        return;
      }

      const printWindow = window.open("", "_blank", "width=800,height=600");
      if (!printWindow) {
        alert('❌ Popup bloquée ! Veuillez autoriser les popups pour ce site.');
        return;
      }

      // Generate HTML for the single devis
      const productRows = devis.products.map(p => `
        <tr>
          <td>${p.productName || 'N/A'}</td>
          <td class="description">${this.getDescription(p.productId)}</td>
          <td>${p.quantity || 0}</td>
          <td>${(p.unitPrice || 0).toFixed(2)} DT</td>
          <td>${(p.subtotal || 0).toFixed(2)} DT</td>
        </tr>
      `).join("");

      // ** CORRECTED HTML STRING (No backslashes before ${...}) **
      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Devis ${devis.quoteNumber}</title>
          <style>
            /* Basic print styles - adapt colors if needed */
            body { font-family: Arial, sans-serif; padding: 20px; font-size: 10pt; }
            h1 { text-align: center; border-bottom: 2px solid #000; margin-bottom: 20px; padding-bottom: 10px; }
            .details-table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
            .details-table th, .details-table td { padding: 8px; border: 1px solid #ddd; text-align: left; }
            .details-table th { background: #f3f4f6; width: 30%; }
            .products-table { width: 100%; border-collapse: collapse; margin-top: 15px; }
            .products-table th, .products-table td { padding: 8px; border: 1px solid #ddd; text-align: left; }
            .products-table th { background: #f3f4f6; }
            .products-table tfoot th, .products-table tfoot td { font-weight: bold; background: #f5f3ff; } /* Light violet footer */
            .description { font-size: 9pt; color: #555; font-style: italic; max-width: 200px; word-wrap: break-word; }
            .total-amount { color: #8b5cf6; } /* Violet total */
            /* Status badge styles for print */
            .badge { display: inline-block; padding: 2px 6px; border-radius: 3px; font-size: 8pt; font-weight: bold; border: 1px solid #ccc; background: #fff; color: #000;}
            .badge-draft { border-color: #9ca3af; }
            .badge-sent { border-color: #3b82f6; }
            .badge-accepted { border-color: #10b981; }
            .badge-rejected { border-color: #ef4444; }
          </style>
        </head>
        <body>
          <h1>Devis N° ${devis.quoteNumber}</h1>
          <table class="details-table">
            <tr><th>Date</th><td>${this.formatDate(devis.date)}</td></tr>
            <tr><th>Client</th><td>${devis.customer}</td></tr>
            ${devis.validUntil ? `<tr><th>Valide jusqu'au</th><td>${this.formatDate(devis.validUntil)}</td></tr>` : ''}
            <tr><th>Statut</th><td><span class="badge badge-${devis.status || 'draft'}">${this.getStatusLabel(devis.status)}</span></td></tr>
            ${devis.notes ? `<tr><th>Notes</th><td>${devis.notes}</td></tr>` : ''}
          </table>
          <h3>Produits</h3>
          <table class="products-table">
            <thead>
              <tr>
                <th>Produit</th>
                <th>Description</th>
                <th>Quantité</th>
                <th>Prix Unit.</th>
                <th>Sous-total</th>
              </tr>
            </thead>
            <tbody>
              ${productRows}
            </tbody>
            <tfoot>
              <tr>
                <th colspan="4" style="text-align: right;">Total</th>
                <td class="total-amount">${(devis.totalAmount || 0).toFixed(2)} DT</td>
              </tr>
            </tfoot>
          </table>
        </body>
        </html>
      `;

      printWindow.document.write(html);
      printWindow.document.close();
      setTimeout(() => {
        printWindow.focus();
        printWindow.print();
        // printWindow.close();
      }, 250);
    });
  }

} // End of class DevisComponent