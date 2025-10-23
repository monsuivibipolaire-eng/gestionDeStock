import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { FormsModule } from '@angular/forms';
import { Observable, BehaviorSubject, combineLatest } from 'rxjs';
import { map, take } from 'rxjs/operators';
import { CommonModule } from '@angular/common';
import { Supplier } from "../../models/supplier";
import { SuppliersService } from '../../services/suppliers.service';

@Component({
  selector: 'app-suppliers',
  templateUrl: './suppliers.component.html',
  styleUrls: ['./suppliers.component.scss'],
  imports: [ReactiveFormsModule, CommonModule, FormsModule],
  standalone: true
})
export class SuppliersComponent implements OnInit {
  suppliers$!: Observable<Supplier[]>;
  filteredSuppliers$!: Observable<Supplier[]>;
  supplierForm: FormGroup;
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
    private suppliersService: SuppliersService,
    private fb: FormBuilder
  ) {
    this.supplierForm = this.fb.group({
      name: ['', Validators.required],
      email: ['', [Validators.required, Validators.email]],
      phone: ['', Validators.required],
      address: [''],
      city: [''],
      notes: ['']
    });
  }

  ngOnInit(): void {
    this.loadSuppliers();
    
    this.filteredSuppliers$ = combineLatest([
      this.suppliers$,
      this.searchTerm$,
      this.cityFilter$,
      this.sortBy$,
      this.sortOrder$
    ]).pipe(
      map(([suppliers, term, city, sortBy, sortOrder]) => {
        let filtered = suppliers;
        
        if (term) {
          filtered = filtered.filter(s =>
            s.name.toLowerCase().includes(term.toLowerCase()) ||
            s.email?.toLowerCase().includes(term.toLowerCase()) ||
            s.phone?.includes(term)
          );
        }
        
        if (city) {
          filtered = filtered.filter(s => s.city?.toLowerCase() === city.toLowerCase());
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

  loadSuppliers(): void {
    this.suppliers$ = this.suppliersService.getSuppliers();
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
    if (this.supplierForm.invalid) {
      this.errorMessage = 'Veuillez remplir tous les champs obligatoires.';
      return;
    }
    this.isLoading = true;
    this.errorMessage = '';
    const formValue = this.supplierForm.value;
    
    if (this.isEditing && this.editingId) {
      this.suppliersService.updateSupplier(this.editingId, formValue).then(() => {
        this.resetForm();
        this.loadSuppliers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la modification.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    } else {
      this.suppliersService.addSupplier(formValue).then(() => {
        this.resetForm();
        this.loadSuppliers();
      }).catch((err: any) => {
        this.errorMessage = "Erreur lors de l'ajout.";
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  editSupplier(supplier: Supplier): void {
    this.isEditing = true;
    this.editingId = supplier.id || null;
    this.supplierForm.patchValue(supplier);
    this.showForm = true;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  deleteSupplier(id: string, name: string): void {
    if (confirm(`Supprimer le fournisseur "${name}" ?`)) {
      this.isLoading = true;
      this.suppliersService.deleteSupplier(id).then(() => {
        this.loadSuppliers();
      }).catch((err: any) => {
        this.errorMessage = 'Erreur lors de la suppression.';
        console.error(err);
      }).finally(() => this.isLoading = false);
    }
  }

  resetForm(): void {
    this.supplierForm.reset();
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
    this.filteredSuppliers$.pipe(take(1)).subscribe(suppliers => {
      if (suppliers.length === 0) {
        alert('Aucun fournisseur à imprimer.');
        return;
      }
      this.generatePrintHTML(suppliers);
    });
  }

  generatePrintHTML(suppliers: Supplier[]): void {
    const printWindow = window.open("", "_blank", "width=900,height=700");
    if (!printWindow) {
      alert("❌ Popup bloquée !");
      return;
    }

    const today = new Date().toLocaleDateString("fr-FR", {
      year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit"
    });

    const totalSuppliers = suppliers.length;
    const cities = [...new Set(suppliers.map(s => s.city).filter(c => c))];
    const withEmail = suppliers.filter(s => s.email).length;
    const withPhone = suppliers.filter(s => s.phone).length;

    const filters: string[] = [];
    if (this.searchTerm) filters.push(`Recherche: "${this.searchTerm}"`);
    if (this.cityFilter) filters.push(`Ville: ${this.cityFilter}`);
    const sortLabels: any = { name: "Nom", city: "Ville", email: "Email" };
    filters.push(`Tri: ${sortLabels[this.sortBy]} (${this.sortOrder === "asc" ? "↑" : "↓"})`);

    const rows = suppliers.map((s, i) => `
      <tr>
        <td>${i + 1}</td>
        <td><strong>${s.name}</strong></td>
        <td>${s.email || '-'}</td>
        <td>${s.phone || '-'}</td>
        <td>${s.city || '-'}</td>
        <td>${s.address || '-'}</td>
      </tr>
    `).join("");

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Fournisseurs - ${today}</title>
        <style>
          @page { margin: 15mm; size: A4 landscape; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 15px; font-size: 10pt; }
          .header { text-align: center; margin-bottom: 15px; border-bottom: 2px solid #10b981; padding-bottom: 10px; }
          .header h1 { font-size: 20pt; color: #10b981; margin: 0 0 5px 0; }
          .filters { background: #f0fdf4; padding: 8px; margin-bottom: 12px; border-left: 3px solid #10b981; }
          .filters h3 { font-size: 11pt; margin: 0 0 5px 0; }
          .filters ul { list-style: none; padding: 0; margin: 0; }
          .filters li { font-size: 9pt; margin: 2px 0; }
          .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 15px; }
          .stat { background: #f9fafb; border: 1px solid #e5e7eb; padding: 8px; text-align: center; }
          .stat .label { font-size: 8pt; color: #666; }
          .stat .value { font-size: 14pt; font-weight: bold; color: #10b981; }
          table { width: 100%; border-collapse: collapse; }
          thead { background: #10b981; color: white; }
          th, td { padding: 6px 8px; text-align: left; border: 1px solid #ddd; font-size: 9pt; }
          tbody tr:nth-child(even) { background: #f9fafb; }
          tfoot { background: #f0fdf4; font-weight: bold; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>🏢 Fournisseurs - Liste</h1>
          <p>Date d'impression : ${today}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqués</h3>
          <ul>${filters.map(f => `<li>• ${f}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Fournisseurs</div><div class="value">${totalSuppliers}</div></div>
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
            <tr><td colspan="6">TOTAL : ${totalSuppliers} fournisseurs</td></tr>
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
