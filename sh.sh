#!/bin/bash

# Script pour ajouter filtres avancés + Imprimer Liste dans Customers
# Usage: ./add-customers-filters-print.sh

LOG_FILE="customers-filters.log"
echo "$(date): Ajout filtres + impression Customers..." | tee "$LOG_FILE"

CUSTOMERS_TS="src/app/components/customers/customers.component.ts"
CUSTOMERS_HTML="src/app/components/customers/customers.component.html"
CUSTOMER_MODEL="src/app/models/customer.ts"

# Backups
cp "$CUSTOMERS_TS" "${CUSTOMERS_TS}.backup.filters" 2>/dev/null
cp "$CUSTOMERS_HTML" "${CUSTOMERS_HTML}.backup.filters" 2>/dev/null
cp "$CUSTOMER_MODEL" "${CUSTOMER_MODEL}.backup.filters" 2>/dev/null

# 1. Model Customer avec city
cat > "$CUSTOMER_MODEL" << 'EOFMODEL'
export interface Customer {
  id?: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  notes?: string;
}
EOFMODEL

echo "✅ Customer model mis à jour" | tee -a "$LOG_FILE"

# 2. Component TS
cat > "$CUSTOMERS_TS" << 'EOFTS'
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { CommonModule } from '@angular/common';
import { Customer } from "../../models/customer";
import { CustomersService } from '../../services/customers.service';

@Component({
  selector: 'app-customers',
  templateUrl: './customers.component.html',
  styleUrls: ['./customers.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class CustomersComponent implements OnInit {
  customers$!: Observable<Customer[]>;
  filteredCustomers$!: Observable<Customer[]>;
  customerForm: FormGroup;
  isLoading = false;
  isEditing = false;
  editingId: string | null = null;
  errorMessage = '';
  showForm = false;

  // Filtres
  searchTerm = '';
  searchTerm$ = new BehaviorSubject<string>('');
  cityFilter: string | null = null;
  cityFilter$ = new BehaviorSubject<string | null>(null);
  sortBy: 'name' | 'city' | 'email' = 'name';
  sortBy$ = new BehaviorSubject<'name' | 'city' | 'email'>('name');
  sortOrder: 'asc' | 'desc' = 'asc';
  sortOrder$ = new BehaviorSubject<'asc' | 'desc'>('asc');

  constructor(
    private customersService: CustomersService,
    private fb: FormBuilder
  ) {
    this.customerForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', Validators.required],
      address: [''],
      city: [''],
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadCustomers();
    
    this.filteredCustomers$ = combineLatest([
      this.customers$,
      this.searchTerm$,
      this.cityFilter$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([customers, term, city, sortBy, sortOrder]) => {
        let filtered = customers;
        
        if (term) {
          filtered = filtered.filter(c =>
            c.name.toLowerCase().includes(term.toLowerCase()) ||
            c.email?.toLowerCase().includes(term.toLowerCase()) ||
            c.phone?.includes(term)
          );
        }
        
        if (city) {
          filtered = filtered.filter(c => c.city?.toLowerCase() === city.toLowerCase());
        }
        
        filtered = filtered.sort((a, b) => {
          let compareValue = 0;
          if (sortBy === 'name') {
            compareValue = a.name.localeCompare(b.name);
          } else if (sortBy === 'city') {
            compareValue = (a.city || '').localeCompare(b.city || '');
          } else if (sortBy === 'email') {
            compareValue = (a.email || '').localeCompare(b.email || '');
          }
          return sortOrder === 'asc' ? compareValue : -compareValue;
        });
        
        return filtered;
      })
    );
  }

  loadCustomers(): void {
    this.customers$ = this.customersService.getCustomers();
  }

  onSearchChange(term: string): void {
    this.searchTerm = term;
    this.searchTerm$.next(term);
  }

  onCityFilterChange(city: string | null): void {
    this.cityFilter = city;
    this.cityFilter$.next(city);
  }

  onSortChange(sortBy: 'name' | 'city' | 'email'): void {
    if (this.sortBy === sortBy) {
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      this.sortBy = sortBy;
      this.sortOrder = 'asc';
    }
    this.sortBy$.next(this.sortBy);
    this.sortOrder$.next(this.sortOrder);
  }

  clearFilters(): void {
    this.searchTerm = '';
    this.searchTerm$.next('');
    this.cityFilter = null;
    this.cityFilter$.next(null);
    this.sortBy = 'name';
    this.sortBy$.next('name');
    this.sortOrder = 'asc';
    this.sortOrder$.next('asc');
  }

  onSubmit(): void {
    if (this.customerForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.customerForm.value;
    
    if (this.isEditing && this.editingId) {
      this.customersService.updateCustomer(this.editingId, formValue).then(() => {
        this.resetForm();
        this.loadCustomers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.customersService.addCustomer(formValue).then(() => {
        this.resetForm();
        this.loadCustomers();
      }).catch((err: any) => {
        this.errorMessage = "Erreur lors de l'ajout.";
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editCustomer(customer: Customer): void {
    this.isEditing = true;
    this.editingId = customer.id || null;
    this.customerForm.patchValue(customer);
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteCustomer(id: string, name: string): void {
    if (confirm(`Supprimer le client "${name}" ?`)) {
      this.isLoading = true;
      this.customersService.deleteCustomer(id).then(() => {
        this.loadCustomers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.customerForm.reset();
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

  printList(): void {
    this.filteredCustomers$.pipe(take(1)).subscribe(customers => {
      if (customers.length === 0) {
        alert('Aucun client à imprimer.');
        return;
      }
      this.generatePrintHTML(customers);
    });
  }

  generatePrintHTML(customers: Customer[]): void {
    const printWindow = window.open("", "_blank", "width=900,height=700");
    if (!printWindow) {
      alert("❌ Popup bloquée !");
      return;
    }

    const today = new Date().toLocaleDateString("fr-FR", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });

    const totalCustomers = customers.length;
    const cities = [...new Set(customers.map(c => c.city).filter(c => c))];
    const withEmail = customers.filter(c => c.email).length;
    const withPhone = customers.filter(c => c.phone).length;

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.cityFilter) filters.push(`Ville: ${this.cityFilter}`);
    const sortLabels: any = { name: "Nom", city: "Ville", email: "Email" };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === "asc" ? "↑" : "↓"})`);

    const rows = customers.map((c, i) => `
      <tr>
        <td>${i + 1}</td>
        <td><strong>${c.name}</strong></td>
        <td>${c.email || '-'}</td>
        <td>${c.phone || '-'}</td>
        <td>${c.city || '-'}</td>
        <td>${c.address || '-'}</td>
      </tr>
    `).join("");

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Clients - ${today}</title>
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
        </style>
      </head>
      <body>
        <div class="header">
          <h1>👥 Clients - Liste</h1>
          <p>Date d'impression : ${today}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqués</h3>
          <ul>${filters.map(f => `<li>• ${f}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Clients</div><div class="value">${totalCustomers}</div></div>
          <div class="stat"><div class="label">Villes</div><div class="value">${cities.length}</div></div>
          <div class="stat"><div class="label">Avec Email</div><div class="value">${withEmail}</div></div>
          <div class="stat"><div class="label">Avec Téléphone</div><div class="value">${withPhone}</div></div>
        </div>
        <table>
          <thead>
            <tr><th>#</th><th>Nom</th><th>Email</th><th>Téléphone</th><th>Ville</th><th>Adresse</th></tr>
          </thead>
          <tbody>${rows}</tbody>
          <tfoot>
            <tr><td colspan="6">TOTAL : ${totalCustomers} clients</td></tr>
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
}
EOFTS

echo "✅ customers.component.ts généré" | tee -a "$LOG_FILE"

# 3. Component HTML
cat > "$CUSTOMERS_HTML" << 'EOFHTML'
<div class="container mx-auto px-4 py-8">
  <h1 class="text-3xl font-bold text-gray-800 mb-6">Clients</h1>

  <div *ngIf="errorMessage" class="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
    <strong>Erreur :</strong> {{ errorMessage }}
    <button (click)="errorMessage = ''" class="float-right">&times;</button>
  </div>

  <div class="flex flex-col md:flex-row justify-between items-center mb-4 gap-4">
    <input type="text" [ngModel]="searchTerm" (ngModelChange)="onSearchChange($event)"
           placeholder="🔍 Rechercher (nom, email, téléphone)..." class="w-full md:w-1/2 px-4 py-2 border rounded-lg" />
    <div class="flex gap-2">
      <button (click)="printList()" class="bg-purple-600 hover:bg-purple-700 text-white font-bold py-2 px-6 rounded-lg flex items-center space-x-2">
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path>
        </svg>
        <span>Imprimer Liste</span>
      </button>
      <button (click)="toggleForm()" class="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-lg">
        <span *ngIf="!showForm">+ Ajouter</span>
        <span *ngIf="showForm">Fermer</span>
      </button>
    </div>
  </div>

  <!-- Filtres Avancés -->
  <div class="bg-white shadow-md rounded-lg p-4 mb-6">
    <h3 class="text-lg font-semibold mb-3 flex items-center">
      <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"></path>
      </svg>
      Filtres Avancés
    </h3>
    
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Ville</label>
        <input type="text" [ngModel]="cityFilter" (ngModelChange)="onCityFilterChange($event)"
               placeholder="Filtrer par ville" class="w-full px-3 py-2 border rounded-lg" />
      </div>
      
      <div>
        <label class="block text-sm font-medium text-gray-700 mb-1">Trier par</label>
        <select [ngModel]="sortBy" (ngModelChange)="onSortChange($event)" class="w-full px-3 py-2 border rounded-lg">
          <option value="name">Nom {{ sortBy === 'name' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="city">Ville {{ sortBy === 'city' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
          <option value="email">Email {{ sortBy === 'email' ? (sortOrder === 'asc' ? '↑' : '↓') : '' }}</option>
        </select>
      </div>
    </div>
    
    <div class="mt-4">
      <button (click)="clearFilters()" class="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded-lg">
        Réinitialiser Filtres
      </button>
    </div>
  </div>

  <!-- Formulaire -->
  <div *ngIf="showForm" class="bg-white shadow-md rounded-lg p-6 mb-6">
    <h2 class="text-2xl font-semibold mb-4">{{ isEditing ? 'Modifier' : 'Nouveau' }} Client</h2>
    <form [formGroup]="customerForm" (ngSubmit)="onSubmit()" class="space-y-4">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div>
          <label class="block text-gray-700 font-medium mb-2">Nom *</label>
          <input formControlName="name" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Email *</label>
          <input formControlName="email" type="email" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Téléphone *</label>
          <input formControlName="phone" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
        <div>
          <label class="block text-gray-700 font-medium mb-2">Ville</label>
          <input formControlName="city" type="text" class="w-full px-4 py-2 border rounded-lg" />
        </div>
      </div>
      <div>
        <label class="block text-gray-700 font-medium mb-2">Adresse</label>
        <textarea formControlName="address" rows="2" class="w-full px-4 py-2 border rounded-lg"></textarea>
      </div>
      <div>
        <label class="block text-gray-700 font-medium mb-2">Notes</label>
        <textarea formControlName="notes" rows="2" class="w-full px-4 py-2 border rounded-lg"></textarea>
      </div>
      <div class="flex gap-4">
        <button type="submit" [disabled]="isLoading || customerForm.invalid"
                class="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-6 rounded-lg disabled:bg-gray-400">
          <span *ngIf="isLoading">Enregistrement...</span>
          <span *ngIf="!isLoading">{{ isEditing ? 'Mettre à jour' : 'Ajouter' }}</span>
        </button>
        <button type="button" (click)="resetForm()" class="bg-gray-500 hover:bg-gray-600 text-white font-bold py-2 px-6 rounded-lg">Annuler</button>
      </div>
    </form>
  </div>

  <!-- Liste -->
  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
    <div *ngFor="let customer of filteredCustomers$ | async" class="bg-white shadow-lg rounded-lg p-6 hover:shadow-xl transition">
      <div class="flex justify-between items-start mb-4">
        <div>
          <h3 class="text-xl font-bold text-gray-800">{{ customer.name }}</h3>
          <p class="text-sm text-gray-500">{{ customer.city || 'Ville non spécifiée' }}</p>
        </div>
      </div>
      <div class="space-y-2 mb-4">
        <p class="text-sm"><strong>Email :</strong> {{ customer.email || 'N/A' }}</p>
        <p class="text-sm"><strong>Téléphone :</strong> {{ customer.phone || 'N/A' }}</p>
        <p class="text-sm" *ngIf="customer.address"><strong>Adresse :</strong> {{ customer.address }}</p>
      </div>
      <div class="flex gap-2">
        <button (click)="editCustomer(customer)" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded text-sm">Modifier</button>
        <button (click)="deleteCustomer(customer.id!, customer.name)" class="bg-red-600 hover:bg-red-700 text-white px-4 py-2 rounded text-sm">Supprimer</button>
      </div>
    </div>
    <div *ngIf="(filteredCustomers$ | async)?.length === 0" class="col-span-full text-center py-8 text-gray-500">
      Aucun client trouvé.
    </div>
  </div>
</div>
EOFHTML

echo "✅ customers.component.html généré" | tee -a "$LOG_FILE"

echo ""
echo "=========================================="
echo "  ✅ Filtres + Imprimer Liste (Customers)"
echo "=========================================="
echo "Fonctionnalités :"
echo "  - Recherche (nom, email, téléphone)"
echo "  - Filtre ville"
echo "  - Tri (nom, ville, email)"
echo "  - Bouton 'Imprimer Liste' → PDF clients filtrés"
echo "  - Stats : Total, Villes, Avec Email/Téléphone"
echo "  - Couleur thème violet/purple"
echo ""
echo "Test :"
echo "  1. ng serve"
echo "  2. /customers → Filtres + Imprimer Liste"
echo ""
echo "Logs : $LOG_FILE"
