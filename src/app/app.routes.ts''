import { Routes } from '@angular/router';

export const routes: Routes = [
  { path: '', redirectTo: '/dashboard', pathMatch: 'full' },
  { path: 'login', loadComponent: () => import('./components/auth/auth.component').then(m => m.AuthComponent) },
  { path: 'dashboard', loadComponent: () => import('./components/dashboard/dashboard.component').then(m => m.DashboardComponent) },
  { path: 'products', loadComponent: () => import('./components/products/products.component').then(m => m.ProductsComponent) },
  { path: 'suppliers', loadComponent: () => import('./components/suppliers/suppliers.component').then(m => m.SuppliersComponent) },
  { path: 'customers', loadComponent: () => import('./components/customers/customers.component').then(m => m.CustomersComponent) },
  { path: 'entry-voucher', loadComponent: () => import('./components/entry-voucher/entry-voucher.component').then(m => m.EntryVoucherComponent) },
  { path: 'exit-voucher', loadComponent: () => import('./components/exit-voucher/exit-voucher.component').then(m => m.ExitVoucherComponent) },
  { path: 'purchase-order', loadComponent: () => import('./components/purchase-order/purchase-order.component').then(m => m.PurchaseOrderComponent) },
  { path: 'devis', loadComponent: () => import('./components/devis/devis.component').then(m => m.DevisComponent) },
  { path: '**', redirectTo: '/dashboard' }
];
