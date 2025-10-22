import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { PurchaseOrder, ProductLine } from "../../models/purchase-order";
import { PurchaseOrderService } from '../../services/purchase-order.service';
import { ProductsService } from '../../services/products.service';
import { Product } from '../../models/product';

@Component({
  selector: 'app-purchase-order',
  templateUrl: './purchase-order.component.html',
  styleUrls: ['./purchase-order.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class PurchaseOrderComponent implements OnInit {
  orders$!: Observable<PurchaseOrder[]>;
  filteredOrders$!: Observable<PurchaseOrder[]>;
  products$!: Observable<Product[]>;
  orderForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  showForm = false;
  expandedOrderId: string | null = null;

  constructor(
    private orderService: PurchaseOrderService,
    private productsService: ProductsService,
    private fb: FormBuilder,
    private router: Router
  ) {
    this.orderForm = this.fb.group({
      orderNumber: [this.orderService.generateOrderNumber(), Validators.required],
      date: [new Date().toISOString().split('T')[0], Validators.required],
      supplier: ['', Validators.required],
      expectedDeliveryDate: ['', Validators.required],
      products: this.fb.array([this.createProductLine()]),
      status: ['pending', Validators.required],
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadOrders();
    this.products$ = this.productsService.getProducts();
    this.filteredOrders$ = combineLatest([
      this.orders$,
      this.searchTerm$
    ]).pipe(
      map(([orders, term]) => orders.filter(o =>
        o.supplier.toLowerCase().includes(term.toLowerCase()) ||
        o.orderNumber.toLowerCase().includes(term.toLowerCase())
      ))
    );
  }

  get productsFormArray(): FormArray {
    return this.orderForm.get('products') as FormArray;
  }

  createProductLine(): FormGroup {
    return this.fb.group({
      productId: ['', Validators.required],
      quantityOrdered: [1, [Validators.required, Validators.min(1)]],
      quantityReceived: [0, [Validators.min(0)]],
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
    return (line.quantityOrdered || 0) * (line.unitPrice || 0);
  }

  calculateTotal(): number {
    return this.productsFormArray.controls.reduce((sum, control) => {
      const line = control.value;
      return sum + ((line.quantityOrdered || 0) * (line.unitPrice || 0));
    }, 0);
  }

  loadOrders(): void {
    this.orders$ = this.orderService.getPurchaseOrders();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onSubmit(): void {
    if (this.orderForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    
    const formValue = this.orderForm.value;
    const orderDate = new Date(formValue.date);
    const deliveryDate = new Date(formValue.expectedDeliveryDate);
    if (deliveryDate < orderDate) {
      this.errorMessage = 'La date de livraison doit être postérieure à la date de commande.';
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    
    const productsWithNames: ProductLine[] = formValue.products.map((p: any) => ({
      ...p,
      productName: this.getProductName(p.productId),
      subtotal: p.quantityOrdered * p.unitPrice
    }));
    
    const orderData = {
      orderNumber: formValue.orderNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      supplier: formValue.supplier,
      expectedDeliveryDate: Timestamp.fromDate(new Date(formValue.expectedDeliveryDate)),
      products: productsWithNames,
      status: formValue.status,
      notes: formValue.notes
    };
    
    if (this.isEditing && this.editingId) {
      this.orderService.updatePurchaseOrder(this.editingId, orderData).then(() => {
        this.resetForm();
        this.loadOrders();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.orderService.addPurchaseOrder(orderData).then(() => {
        this.resetForm();
        this.loadOrders();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editOrder(order: PurchaseOrder): void {
    this.isEditing = true;
    this.editingId = order.id || null;
    const dateStr = (order.date as Timestamp).toDate().toISOString().split('T')[0];
    const deliveryStr = (order.expectedDeliveryDate as Timestamp).toDate().toISOString().split('T')[0];
    
    this.productsFormArray.clear();
    order.products.forEach(p => {
      this.productsFormArray.push(this.fb.group({
        productId: [p.productId, Validators.required],
        quantityOrdered: [p.quantityOrdered, [Validators.required, Validators.min(1)]],
        quantityReceived: [p.quantityReceived, [Validators.min(0)]],
        unitPrice: [p.unitPrice, [Validators.required, Validators.min(0.01)]]
      }));
    });
    
    this.orderForm.patchValue({
      orderNumber: order.orderNumber,
      date: dateStr,
      supplier: order.supplier,
      expectedDeliveryDate: deliveryStr,
      status: order.status,
      notes: order.notes
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteOrder(id: string, orderNumber: string): void {
    if (confirm(`Supprimer la commande "${orderNumber}" ?`)) {
      this.isLoading = true;
      this.orderService.deletePurchaseOrder(id).then(() => {
        this.loadOrders();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productsFormArray.clear();
    this.productsFormArray.push(this.createProductLine());
    this.orderForm.patchValue({
      orderNumber: this.orderService.generateOrderNumber(),
      date: new Date().toISOString().split('T')[0],
      supplier: '',
      expectedDeliveryDate: '',
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
    const labels: any = { pending: 'En attente', partial: 'Partielle', received: 'Reçue', cancelled: 'Annulée' };
    return labels[status] || status;
  }
}
