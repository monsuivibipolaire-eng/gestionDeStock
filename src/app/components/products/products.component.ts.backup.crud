import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Observable } from 'rxjs';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';  // Ajouté pour *ngIf/*ngFor dans template
import { Product } from "../../models/product";  // Espace corrigé après import
import { ProductsService } from '../../services/products.service';

@Component({
  selector: 'app-products',
  templateUrl: './products.component.html',
  styleUrls: ['./products.component.scss'],
  imports: [ReactiveFormsModule, CommonModule],  // Array corrigé (imports standalone pour forms + directives ; ReactiveFormsModule pour FormGroup, CommonModule pour *ngIf/*ngFor)
  standalone: true  // Propriétés réorganisées (pas de CommonModule, en dehors de l'array)
})
export class ProductsComponent implements OnInit {
  products$!: Observable<Product[]>;
  productForm: FormGroup;
  isLoading = false;
  isEditing = false;  // Public (fix TS2339)
  editingId: string | null = null;  // Public (fix TS2339)
  errorMessage = '';

  constructor(
    private productsService: ProductsService,
    private fb: FormBuilder,
    private router: Router
  ) {
    this.productForm = this.fb.group({
      name: ['', Validators.required],
      price: [0, [Validators.required, Validators.min(0.01)]],
      quantity: [0, [Validators.required, Validators.min(1)]],
      description: ['']
    });
  }

  ngOnInit(): void {
    this.loadProducts();
  }

  loadProducts(): void {
    this.products$ = this.productsService.getProducts();
  }

  onSubmit(): void {
    if (this.productForm.invalid) {
      this.errorMessage = 'Formulaire invalide.';
      return;
    }
    this.isLoading = true;
    const formValue: Product = this.productForm.value;
    if (this.isEditing && this.editingId) {
      this.productsService.updateProduct(this.editingId, formValue).then(() => {
        this.resetForm();
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur update.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.productsService.addProduct(formValue).then(() => {
        this.resetForm();
        this.loadProducts();
      }).catch(err => {
        this.errorMessage = 'Erreur ajout.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editProduct(product: Product): void {
    this.isEditing = true;
    this.editingId = product.id || null;
    this.productForm.patchValue(product);
  }

  deleteProduct(id: string): void {
    if (confirm('Supprimer ?')) {
      this.productsService.deleteProduct(id).then(() => this.loadProducts()).catch(err => console.error(err));
    }
  }

  resetForm(): void {
    this.productForm.reset();
    this.isEditing = false;
    this.editingId = null;
    this.errorMessage = '';
  }
}
