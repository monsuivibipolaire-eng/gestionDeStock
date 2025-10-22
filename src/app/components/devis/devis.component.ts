import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { NgSelectModule } from '@ng-select/ng-select';import { Timestamp } from '@angular/fire/firestore';
import { Devis, ProductLine } from "../../models/devis";
import { DevisService } from '../../services/devis.service';
import { ProductsService } from '../../services/products.service';
import { CustomersService } from '../../services/customers.service';
import { Customer } from '../../models/customer';import { Product } from '../../models/product';

@Component({
  selector: 'app-devis',
  templateUrl: './devis.component.html',
  styleUrls: ['./devis.component.scss'],
  imports: [ReactiveFormsModule, NgSelectModule, CommonModule, FormsModule],
})
export class DevisComponent implements OnInit {
  devis$!: Observable<Devis[]>;
  filteredDevis$!: Observable<Devis[]>;
  products$!: Observable<Product[]>;
  customers$!: Observable<Customer[]>;  devisForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  showForm = false;
  expandedDevisId: string | null = null;

  constructor(
    private devisService: DevisService,
    private productsService: ProductsService,
    private customersService: CustomersService,    private fb: FormBuilder,
    private router: Router
  ) {
    const today = new Date().toISOString().split('T')[0];
    const validUntil = new Date();
    validUntil.setDate(validUntil.getDate() + 30);
    
    this.devisForm = this.fb.group({
      quoteNumber: [this.devisService.generateQuoteNumber(), Validators.required],
      date: [today, Validators.required],
      validUntil: [validUntil.toISOString().split('T')[0], Validators.required],
      customer: ['', Validators.required],
      customerEmail: ['', [Validators.email]],
      products: this.fb.array([this.createProductLine()]),
      status: ['draft', Validators.required],
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadDevis();
    this.products$ = this.productsService.getProducts();
    this.customers$ = this.customersService.getCustomers();    this.filteredDevis$ = combineLatest([this.devis$, this.searchTerm$]).pipe(
      map(([devis, term]) => devis.filter(d =>
        d.customer.toLowerCase().includes(term.toLowerCase()) ||
        d.quoteNumber.toLowerCase().includes(term.toLowerCase())
      ))
    );
  }

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

  calculateTVA(): number {
    return this.calculateTotal() * 0.19;
  }

  calculateTTC(): number {
    return this.calculateTotal() + this.calculateTVA();
  }

  loadDevis(): void {
    this.devis$ = this.devisService.getDevis();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onSubmit(): void {
    if (this.devisForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.devisForm.value;
    
    const productsWithNames: ProductLine[] = formValue.products.map((p: any) => ({
      ...p,
      productName: this.getProductName(p.productId),
      subtotal: p.quantity * p.unitPrice
    }));
    
    const devisData = {
      quoteNumber: formValue.quoteNumber,
      date: Timestamp.fromDate(new Date(formValue.date)),
      validUntil: Timestamp.fromDate(new Date(formValue.validUntil)),
      customer: formValue.customer,
      customerEmail: formValue.customerEmail,
      products: productsWithNames,
      status: formValue.status,
      notes: formValue.notes
    };
    
    if (this.isEditing && this.editingId) {
      this.devisService.updateDevis(this.editingId, devisData).then(() => {
        this.resetForm();
        this.loadDevis();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.devisService.addDevis(devisData).then(() => {
        this.resetForm();
        this.loadDevis();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editDevis(devis: Devis): void {
    this.isEditing = true;
    this.editingId = devis.id || null;
    const dateStr = (devis.date as Timestamp).toDate().toISOString().split('T')[0];
    const validStr = (devis.validUntil as Timestamp).toDate().toISOString().split('T')[0];
    
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
      validUntil: validStr,
      customer: devis.customer,
      customerEmail: devis.customerEmail,
      status: devis.status,
      notes: devis.notes
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteDevis(id: string, quoteNumber: string): void {
    if (confirm(`Supprimer le devis "${quoteNumber}" ?`)) {
      this.isLoading = true;
      this.devisService.deleteDevis(id).then(() => {
        this.loadDevis();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.productsFormArray.clear();
    this.productsFormArray.push(this.createProductLine());
    const today = new Date().toISOString().split('T')[0];
    const validUntil = new Date();
    validUntil.setDate(validUntil.getDate() + 30);
    this.devisForm.patchValue({
      quoteNumber: this.devisService.generateQuoteNumber(),
      date: today,
      validUntil: validUntil.toISOString().split('T')[0],
      customer: '',
      customerEmail: '',
      status: 'draft',
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

  toggleExpand(devisId: string): void {
    this.expandedDevisId = this.expandedDevisId === devisId ? null : devisId;
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
    const labels: any = { draft: 'Brouillon', sent: 'Envoyé', accepted: 'Accepté', rejected: 'Refusé' };
    return labels[status] || status;
  }

  print(): void {
    window.print();
  }
}
