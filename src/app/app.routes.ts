import { Routes } from '@angular/router';
import { AuthComponent } from './components/auth/auth.component';
import { ProductsComponent } from './components/products/products.component';
import { EntryVoucherComponent } from './components/entry-voucher/entry-voucher.component';
import { ExitVoucherComponent } from './components/exit-voucher/exit-voucher.component';
import { PurchaseOrderComponent } from './components/purchase-order/purchase-order.component';

export const routes: Routes = [
  { path: 'auth', component: AuthComponent },
  { path: 'products', component: ProductsComponent },
  { path: 'entry', component: EntryVoucherComponent },
  { path: 'exit', component: ExitVoucherComponent },
  { path: 'commande', component: PurchaseOrderComponent },
  { path: '', redirectTo: '/auth', pathMatch: 'full' }
];
