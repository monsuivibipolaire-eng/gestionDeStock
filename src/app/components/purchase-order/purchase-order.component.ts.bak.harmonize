import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { NgSelectModule } from '@ng-select/ng-select';
import { PurchaseOrder, ProductLine } from "../../models/purchase-order";
import { PurchaseOrdersService } from '../../services/purchase-orders.service';
import { ProductsService } from '../../services/products.service';
import { SuppliersService } from '../../services/suppliers.service';
import { Product } from '../../models/product';
import { Supplier } from '../../models/supplier';

@Component({
  selector: 'app-purchase-order',
  templateUrl: './purchase-order.component.html',
  styleUrls: ['./purchase-order.component.scss'],
  imports: [ReactiveFormsModule, NgSelectModule, CommonModule, FormsModule],
  standalone: true
})
export class PurchaseOrderComponent implements OnInit {
  orders$!: Observable<PurchaseOrder[]>;
  filteredOrders$!: Observable<PurchaseOrder[]>;
  products$!: Observable<Product[]>;
  suppliers$!: Observable<Supplier[]>;
  orderForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  showForm = false;
  expandedOrderId: string | null = null;
  
  // Filtres
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  selectedSupplier: string | null = null;
  selectedSupplier$ = new BehaviorSubject<string | null>(null);
  dateFrom: string | null = null;
  dateFrom$ = new BehaviorSubject<string | null>(null);
  dateTo: string | null = null;
  dateTo$ = new BehaviorSubject<string | null>(null);
  minAmount: number | null = null;
  minAmount$ = new BehaviorSubject<number | null>(null);
  maxAmount: number | null = null;
  maxAmount$ = new BehaviorSubject<number | null>(null);
  statusFilter: 'all' | 'pending' | 'confirmed' | 'delivered' | 'cancelled' = 'all';
  statusFilter$ = new BehaviorSubject<'all' | 'pending' | 'confirmed' | 'delivered' | 'cancelled'>('all');
  sortBy: 'date' | 'supplier' | 'amount' = 'date';
  sortBy$ = new BehaviorSubject<'date' | 'supplier' | 'amount'>('date');
  sortOrder: 'asc' | 'desc' = 'desc';
  sortOrder$ = new BehaviorSubject<'asc' | 'desc'>('desc');

  constructor(
    private ordersService: PurchaseOrdersService,
    private productsService: ProductsService,
    private suppliersService: SuppliersService,
    private fb: FormBuilder,
    private router: Router
  ) {
    const today = new Date().toISOString().split('T')[0];
    this.orderForm = this.fb.group({
      orderNumber: [this.ordersService.generateOrderNumber(), Validators.required],
      date: [today, Validators.required],
      supplier: ['', Validators.required],
      expectedDeliveryDate: [''],
      products: this.fb.array([this.createProductLine()]),
      notes: [''],
      status: ['pending']
    });
  }

  ngOnInit(): void {
    this.loadOrders();
    this.products$ = this.productsService.getProducts();
    this.suppliers$ = this.suppliersService.getSuppliers();
    
    this.filteredOrders$ = combineLatest([
      this.orders$,
      this.searchTerm$,
      this.selectedSupplier$,
      this.dateFrom$,
      this.dateTo$,
      this.minAmount$,
      this.maxAmount$,
      this.statusFilter$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([orders, term, supplier, dateFrom, dateTo, minAmount, maxAmount, status, sortBy, sortOrder]) => {
        let filtered = orders;
        
        if (term) {
          filtered = filtered.filter(o =>
            o.orderNumber.toLowerCase().includes(term.toLowerCase())
          );
        }
        
        if (supplier) {
          filtered = filtered.filter(o => o.supplier === supplier);
        }
        
        if (dateFrom) {
          const fromDate = new Date(dateFrom);
          filtered = filtered.filter(o => {
            const oDate = o.date instanceof Timestamp ? o.date.toDate() : new Date(o.date);
            return oDate >= fromDate;
          });
        }
        
        if (dateTo) {
          const toDate = new Date(dateTo);
          toDate.setHours(23, 59, 59);
          filtered = filtered.filter(o => {
            const oDate = o.date instanceof Timestamp ? o.date.toDate() : new Date(o.date);
            return oDate <= toDate;
          });
        }
        
        if (minAmount !== null) {
          filtered = filtered.filter(o => (o.totalAmount || 0) >= minAmount);
        }
        
        if (maxAmount !== null) {
          filtered = filtered.filter(o => (o.totalAmount || 0) <= maxAmount);
        }
        
        if (status !== 'all') {
          filtered = filtered.filter(o => o.status === status);
        }
        
        filtered = filtered.sort((a, b) => {
          let compareValue = 0;
          if (sortBy === 'date') {
            const dateA = a.date instanceof Timestamp ? a.date.toDate().getTime() : new Date(a.date).getTime();
            const dateB = b.date instanceof Timestamp ? b.date.toDate().getTime() : new Date(b.date).getTime();
            compareValue = dateA - dateB;
          } else if (sortBy === 'supplier') {
            compareValue = a.supplier.localeCompare(b.supplier);
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
    return this.orderForm.get('products') as FormArray;
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

  loadOrders(): void {
    this.orders$ = this.ordersService.getPurchaseOrders();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onSupplierFilterChange(supplier: string | null): void {
    this.selectedSupplier = supplier;
    this.selectedSupplier$.next(supplier);
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

  onStatusFilterChange(status: 'all' | 'pending' | 'confirmed' | 'delivered' | 'cancelled'): void {
    this.statusFilter = status;
    this.statusFilter$.next(status);
  }

  onSortChange(sortBy: 'date' | 'supplier' | 'amount'): void {
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
    this.selectedSupplier = null;
    this.selectedSupplier$.next(null);
    this.dateFrom = null;
    this.dateFrom$.next(null);
    this.dateTo = null;
    this.dateTo$.next(null);
    this.minAmount = null;
    this.minAmount$.next(null);
    this.maxAmount = null;
    this.maxAmount$.next(null);
    this.statusFilter = 'all';
    this.statusFilter$.next('all');
    this.sortBy = 'date';
    this.sortBy$.next('date');
    this.sortOrder = 'desc';
    this.sortOrder$.next('desc');
  }

  onSubmit(): void {
    if (this.orderForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.orderForm.value;
    
    const productsWithNames: ProductLine[] = formValue.products.map((p: any) => ({
      ...p,
      productName: this.getProductName(p.productId),
      subtotal: p.quantity * p.unitPrice
    }));
    
    const orderData: any = {
      orderNumber: formValue.orderNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      supplier: formValue.supplier,
      products: productsWithNames,
      totalAmount: this.calculateTotal(),
      notes: formValue.notes,
      status: formValue.status || 'pending'
    };
    
    if (formValue.expectedDeliveryDate) {
      orderData.expectedDeliveryDate = Timestamp.fromDate(new Date(formValue.expectedDeliveryDate));
    }
    
    if (this.isEditing && this.editingId) {
      this.ordersService.updatePurchaseOrder(this.editingId, orderData).then(() => {
        this.resetForm();
        this.loadOrders();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.ordersService.addPurchaseOrder(orderData).then(() => {
        this.resetForm();
        this.loadOrders();
      }).catch((err: any) => {
        this.errorMessage = "Erreur lors de l'ajout.";
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editOrder(order: PurchaseOrder): void {
    this.isEditing = true;
    this.editingId = order.id || null;
    const dateStr = (order.date as Timestamp).toDate().toISOString().split('T')[0];
    const deliveryStr = order.expectedDeliveryDate ? 
      (order.expectedDeliveryDate as Timestamp).toDate().toISOString().split('T')[0] : '';
    
    this.productsFormArray.clear();
    order.products.forEach(p => {
      this.productsFormArray.push(this.fb.group({
        productId: [p.productId, Validators.required],
        quantity: [p.quantity, [Validators.required, Validators.min(1)]],
        unitPrice: [p.unitPrice, [Validators.required, Validators.min(0.01)]]
      }));
    });
    
    this.orderForm.patchValue({
      orderNumber: order.orderNumber,
      date: dateStr,
      supplier: order.supplier,
      expectedDeliveryDate: deliveryStr,
      notes: order.notes,
      status: order.status || 'pending'
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteOrder(id: string, orderNumber: string): void {
    if (confirm(`Supprimer la commande "${orderNumber}" ?`)) {
      this.isLoading = true;
      this.ordersService.deletePurchaseOrder(id).then(() => {
        this.loadOrders();
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
    this.orderForm.patchValue({
      orderNumber: this.ordersService.generateOrderNumber(),
      date: today,
      supplier: '',
      expectedDeliveryDate: '',
      notes: '',
      status: 'pending'
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

  toggleExpand(orderId: string): void {
    this.expandedOrderId = this.expandedOrderId === orderId ? null : orderId;
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

  getStatusLabel(status: string): string {
    const labels: any = {
      pending: 'En Attente',
      confirmed: 'Confirmée',
      delivered: 'Livrée',
      cancelled: 'Annulée'
    };
    return labels[status] || status;
  }

  getStatusClass(status: string): string {
    const classes: any = {
      pending: 'bg-yellow-100 text-yellow-800',
      confirmed: 'bg-blue-100 text-blue-800',
      delivered: 'bg-green-100 text-green-800',
      cancelled: 'bg-red-100 text-red-800'
    };
    return classes[status] || 'bg-gray-100 text-gray-800';
  }

  printList(): void {
    this.filteredOrders$.pipe(take(1)).subscribe(orders => {
      if (orders.length === 0) {
        alert('Aucune commande à imprimer.');
        return;
      }
      this.generatePrintHTML(orders);
    });
  }

  generatePrintHTML(orders: PurchaseOrder[]): void {
    const printWindow = window.open("", "_blank", "width=900,height=700");
    if (!printWindow) {
      alert("❌ Popup bloquée !");
      return;
    }

    const today = new Date().toLocaleDateString("fr-FR", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });

    const totalOrders = orders.length;
    const totalAmount = orders.reduce((sum, o) => sum + (o.totalAmount || 0), 0);
    const totalProducts = orders.reduce((sum, o) => sum + o.products.length, 0);
    const statusCounts = {
      pending: orders.filter(o => o.status === 'pending').length,
      confirmed: orders.filter(o => o.status === 'confirmed').length,
      delivered: orders.filter(o => o.status === 'delivered').length,
      cancelled: orders.filter(o => o.status === 'cancelled').length
    };

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.selectedSupplier) filters.push(`Fournisseur: ${this.selectedSupplier}`);
    if (this.dateFrom) filters.push(`Date Début: ${new Date(this.dateFrom).toLocaleDateString('fr-FR')}`);
    if (this.dateTo) filters.push(`Date Fin: ${new Date(this.dateTo).toLocaleDateString('fr-FR')}`);
    if (this.minAmount !== null) filters.push(`Montant Min: ${this.minAmount} DT`);
    if (this.maxAmount !== null) filters.push(`Montant Max: ${this.maxAmount} DT`);
    if (this.statusFilter !== 'all') filters.push(`Statut: ${this.getStatusLabel(this.statusFilter)}`);
    const sortLabels: any = { date: "Date", supplier: "Fournisseur", amount: "Montant" };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === "asc" ? "↑" : "↓"})`);

    const rows = orders.map((o, i) => `
      <tr>
        <td>${i + 1}</td>
        <td>${o.orderNumber}</td>
        <td>${this.formatDate(o.date)}</td>
        <td>${o.supplier}</td>
        <td>${o.products.length}</td>
        <td><span class="badge-${o.status}">${this.getStatusLabel(o.status || 'pending')}</span></td>
        <td>${(o.totalAmount || 0).toFixed(2)} DT</td>
      </tr>
    `).join("");

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Bons de Commande - ${today}</title>
        <style>
          @page { margin: 15mm; size: A4 landscape; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 15px; font-size: 10pt; }
          .header { text-align: center; margin-bottom: 15px; border-bottom: 2px solid #f59e0b; padding-bottom: 10px; }
          .header h1 { font-size: 20pt; color: #f59e0b; margin: 0 0 5px 0; }
          .filters { background: #fef3c7; padding: 8px; margin-bottom: 12px; border-left: 3px solid #f59e0b; }
          .filters h3 { font-size: 11pt; margin: 0 0 5px 0; }
          .filters ul { list-style: none; padding: 0; margin: 0; }
          .filters li { font-size: 9pt; margin: 2px 0; }
          .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 15px; }
          .stat { background: #f9fafb; border: 1px solid #e5e7eb; padding: 8px; text-align: center; }
          .stat .label { font-size: 8pt; color: #666; }
          .stat .value { font-size: 14pt; font-weight: bold; color: #f59e0b; }
          table { width: 100%; border-collapse: collapse; }
          thead { background: #f59e0b; color: white; }
          th, td { padding: 6px 8px; text-align: left; border: 1px solid #ddd; font-size: 9pt; }
          tbody tr:nth-child(even) { background: #f9fafb; }
          tfoot { background: #fef3c7; font-weight: bold; }
          .badge-pending { background: #fef3c7; color: #92400e; padding: 2px 6px; border-radius: 3px; }
          .badge-confirmed { background: #dbeafe; color: #1e40af; padding: 2px 6px; border-radius: 3px; }
          .badge-delivered { background: #d1fae5; color: #065f46; padding: 2px 6px; border-radius: 3px; }
          .badge-cancelled { background: #fee2e2; color: #991b1b; padding: 2px 6px; border-radius: 3px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>📋 Bons de Commande - Liste</h1>
          <p>Date d'impression : ${today}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqués</h3>
          <ul>${filters.map(f => `<li>• ${f}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Commandes</div><div class="value">${totalOrders}</div></div>
          <div class="stat"><div class="label">Total Produits</div><div class="value">${totalProducts}</div></div>
          <div class="stat"><div class="label">Montant Total</div><div class="value">${totalAmount.toFixed(2)} DT</div></div>
          <div class="stat"><div class="label">En Attente</div><div class="value">${statusCounts.pending}</div></div>
        </div>
        <table>
          <thead>
            <tr><th>#</th><th>N° Commande</th><th>Date</th><th>Fournisseur</th><th>Produits</th><th>Statut</th><th>Montant</th></tr>
          </thead>
          <tbody>${rows}</tbody>
          <tfoot>
            <tr><td colspan="4">TOTAL (${totalOrders} commandes)</td><td>${totalProducts}</td><td>-</td><td>${totalAmount.toFixed(2)} DT</td></tr>
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
    this.filteredOrders$.pipe(take(1)).subscribe(orders => {
      const order = orders.find(o => o.id === item.id);
      if (!order) return;
      
      const printWindow = window.open("", "_blank", "width=800,height=600");
      if (!printWindow) return;

      const html = `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="UTF-8">
          <title>Bon de Commande ${order.orderNumber}</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { text-align: center; border-bottom: 2px solid #000; }
            table { width: 100%; border-collapse: collapse; margin: 15px 0; }
            th, td { padding: 8px; border: 1px solid #ddd; }
            th { background: #f3f4f6; }
          </style>
        </head>
        <body>
          <h1>Bon de Commande N° ${order.orderNumber}</h1>
          <table>
            <tr><th>Date</th><td>${this.formatDate(order.date)}</td></tr>
            <tr><th>Fournisseur</th><td>${order.supplier}</td></tr>
            ${order.expectedDeliveryDate ? `<tr><th>Livraison Prévue</th><td>${this.formatDate(order.expectedDeliveryDate)}</td></tr>` : ''}
            <tr><th>Statut</th><td>${this.getStatusLabel(order.status || 'pending')}</td></tr>
          </table>
          <h3>Produits</h3>
          <table>
            <thead>
              <tr><th>Produit</th><th>Quantité</th><th>Prix Unit.</th><th>Sous-total</th></tr>
            </thead>
            <tbody>
              ${order.products.map(p => `
                <tr>
                  <td>${p.productName}</td>
                  <td>${p.quantity}</td>
                  <td>${p.unitPrice.toFixed(2)} DT</td>
                  <td>${p.subtotal.toFixed(2)} DT</td>
                </tr>
              `).join("")}
            </tbody>
            <tfoot>
              <tr><th colspan="3">Total</th><th>${(order.totalAmount || 0).toFixed(2)} DT</th></tr>
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
