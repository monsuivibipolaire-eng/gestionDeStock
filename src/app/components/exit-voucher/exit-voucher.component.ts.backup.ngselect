import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, FormArray, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';
import { Timestamp } from '@angular/fire/firestore';
import { ExitVoucher, ProductLine } from "../../models/exit-voucher";
import { ExitVoucherService } from '../../services/exit-voucher.service';
import { ProductsService } from '../../services/products.service';
import { Product } from '../../models/product';

@Component({
  selector: 'app-exit-voucher',
  templateUrl: './exit-voucher.component.html',
  styleUrls: ['./exit-voucher.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class ExitVoucherComponent implements OnInit {
  vouchers$!: Observable<ExitVoucher[]>;
  filteredVouchers$!: Observable<ExitVoucher[]>;
  products$!: Observable<Product[]>;
  voucherForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  showForm = false;
  expandedVoucherId: string | null = null;

  constructor(
    private voucherService: ExitVoucherService,
    private productsService: ProductsService,
    private fb: FormBuilder,
    private router: Router
  ) {
    this.voucherForm = this.fb.group({
      date: [new Date().toISOString().split('T')[0], Validators.required],
      customer: ['', Validators.required],
      destination: [''],
      type: ['sale', Validators.required],
      products: this.fb.array([this.createProductLine()]),
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
        v.customer.toLowerCase().includes(term.toLowerCase())
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
    this.vouchers$ = this.voucherService.getExitVouchers();
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
      customer: formValue.customer,
      destination: formValue.destination,
      type: formValue.type,
      products: productsWithNames,
      status: formValue.status,
      notes: formValue.notes
    };
    
    if (this.isEditing && this.editingId) {
      this.voucherService.updateExitVoucher(this.editingId, voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.voucherService.addExitVoucher(voucherData).then(() => {
        this.resetForm();
        this.loadVouchers();
      }).catch(err => {
        this.errorMessage = 'Erreur lors de l\'ajout.';
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
      date: dateStr,
      customer: voucher.customer,
      destination: voucher.destination,
      type: voucher.type,
      status: voucher.status,
      notes: voucher.notes
    });
    
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteVoucher(id: string, customer: string): void {
    if (confirm(`Supprimer le bon de sortie pour "${customer}" ?`)) {
      this.isLoading = true;
      this.voucherService.deleteExitVoucher(id).then(() => {
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
      customer: '',
      destination: '',
      type: 'sale',
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

  getTypeLabel(type: string): string {
    const labels: any = { sale: 'Vente', transfer: 'Transfert', loss: 'Perte' };
    return labels[type] || type;
  }
}
