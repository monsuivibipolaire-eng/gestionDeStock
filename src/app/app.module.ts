import { NgModule } from '@angular/core';
import { SuppliersComponent } from './components/suppliers/suppliers.component';
import { CustomersComponent } from './components/customers/customers.component';import { DevisComponent } from './components/devis/devis.component';import { BrowserModule } from '@angular/platform-browser';
import { RouterModule, Routes } from '@angular/router';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';
import { environment } from '../environments/environment';

import { AppComponent } from './app.component';
import { AuthComponent } from './components/auth/auth.component';
import { ProductsComponent } from './components/products/products.component';
import { EntryVoucherComponent } from './components/entry-voucher/entry-voucher.component';
import { ExitVoucherComponent } from './components/exit-voucher/exit-voucher.component';
import { PurchaseOrderComponent } from './components/purchase-order/purchase-order.component';

const routes: Routes = [
  { path: 'suppliers', component: SuppliersComponent },
  { path: 'customers', component: CustomersComponent },  { path: 'devis', component: DevisComponent },  { path: 'auth', component: AuthComponent },
  { path: 'products', component: ProductsComponent },
  { path: 'entry-voucher', component: EntryVoucherComponent },
  { path: 'exit-voucher', component: ExitVoucherComponent },
  { path: 'purchase-order', component: PurchaseOrderComponent },
  { path: '', redirectTo: '/products', pathMatch: 'full' },
  { path: '**', redirectTo: '/products' }
];

@NgModule({
  declarations: [
    AppComponent  // Seulement AppComponent (non-standalone)
  ],
  imports: [
    BrowserModule,
    FormsModule,
    ReactiveFormsModule,
    RouterModule.forRoot(routes),
    // Standalone components ici (pas de provide*)
    AuthComponent,
    ProductsComponent,
    EntryVoucherComponent,
    ExitVoucherComponent,
    PurchaseOrderComponent
  ],
  providers: [
    // Firebase providers ici (pas dans imports)
    provideFirebaseApp(() => initializeApp(environment.firebaseConfig)),
    provideAuth(() => getAuth()),
    provideFirestore(() => getFirestore())
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
