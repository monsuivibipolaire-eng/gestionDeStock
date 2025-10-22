import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouterModule, Routes } from '@angular/router';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';
import { AngularFireModule } from '@angular/fire/compat';
import { AngularFireAuthModule } from '@angular/fire/compat/auth';
import { AngularFirestoreModule } from '@angular/fire/compat/firestore';

import { AppComponent } from './app.component';
import { AuthComponent } from './components/auth/auth.component';
import { ProductsComponent } from './components/products/products.component';
import { EntryVoucherComponent } from './components/entry-voucher/entry-voucher.component';
import { ExitVoucherComponent } from './components/exit-voucher/exit-voucher.component';
import { PurchaseOrderComponent } from './components/purchase-order/purchase-order.component';


const routes: Routes = [
  { path: 'auth', component: AuthComponent },
  { path: 'products', component: ProductsComponent },
  { path: 'entry', component: EntryVoucherComponent },
  { path: 'exit', component: ExitVoucherComponent },
  { path: 'commande', component: PurchaseOrderComponent },
  { path: '', redirectTo: '/auth', pathMatch: 'full' as const },  // Literal type
  { path: '**', redirectTo: '/auth' }
];

@NgModule({
  declarations: [
    AppComponent,
    AuthComponent,
    ProductsComponent,
    EntryVoucherComponent,
    ExitVoucherComponent,
    PurchaseOrderComponent
  ],
  imports: [
    BrowserModule,
    RouterModule.forRoot(routes),  // Routes directes, literal 'full'
    FormsModule,
    ReactiveFormsModule,
    AngularFireModule.initializeApp((environment as Environment).firebase),
    AngularFireAuthModule,
    AngularFirestoreModule
  ],
  providers: [],
  bootstrap: [AppComponent]
})
export class AppModule { }

import { environment } from '../environments/environment';
import { Environment } from '../environments/environment.interface';
