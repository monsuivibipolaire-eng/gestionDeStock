import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { NgSelectModule } from '@ng-select/ng-select';import { Timestamp } from '@angular/fire/firestore';
import { EntryVoucher, ProductLine } from "../../models/entry-voucher";
import { EntryVoucherService } from '../../services/entry-voucher.service';
import { ProductsService } from '../../services/products.service';
import { SuppliersService } from '../../services/suppliers.service';
import { Supplier } from '../../models/supplier';import { Product } from '../../models/product';

@Component({
  selector: 'app-entry-voucher',
  templateUrl: './entry-voucher.component.html',
  styleUrls: ['./entry-voucher.component.scss'],
  imports: [ReactiveFormsModule, NgSelectModule, CommonModule, FormsModule],
})
export class EntryVoucherComponent implements OnInit {
  vouchers$!: Observable<EntryVoucher[]>;
  filteredVouchers$!: Observable<EntryVoucher[]>;
  products$!: Observable<Product[]>;
  suppliers$!: Observable<Supplier[]>;  voucherForm: FormGroup;
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
    private suppliersService: SuppliersService,    private fb: FormBuilder,
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
    this.suppliers$ = this.suppliersService.getSuppliers();    this.filteredVouchers$ = combineLatest([
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
