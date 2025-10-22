import { AngularFireModule } from "@angular/fire/compat";
import { AngularFirestoreModule } from "@angular/fire/compat/firestore";
import { environment } from "../environments/environment";
import { BrowserModule } from '@angular/platform-browser';
import { RouterModule, Routes } from '@angular/router';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { AuthComponent } from './components/auth/auth.component';
import { ProductsComponent } from './components/products/products.component';
import { EntryVoucherComponent } from './components/entry-voucher/entry-voucher.component';
import { ExitVoucherComponent } from './components/exit-voucher/exit-voucher.component';
import { PurchaseOrderComponent } from './components/purchase-order/purchase-order.component';


import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';
import { NgModule } from "@angular/core";

const routes: Routes = [
  { path: 'auth', component: AuthComponent },
  { path: 'products', component: ProductsComponent },
  { path: 'entry', component: EntryVoucherComponent },
  { path: 'exit', component: ExitVoucherComponent },
  { path: 'commande', component: PurchaseOrderComponent },
  { path: '', redirectTo: '/auth', pathMatch: 'full' },
  { path: '**', redirectTo: '/auth' }
];

@NgModule({
  declarations: [
    AppComponent,
    EntryVoucherComponent,
    ExitVoucherComponent,
    PurchaseOrderComponent
  ],
  imports: [
      ReactiveFormsModule,      ProductsComponent,      ProductsComponent,      AngularFireModule.initializeApp(environment.firebaseConfig),
      AngularFirestoreModule,    BrowserModule,
    RouterModule.forRoot(routes),
    FormsModule,
    ReactiveFormsModule
  ],
  providers:[
    provideFirestore(() => getFirestore()),
    provideFirebaseApp(() => initializeApp({ projectId: "gestiondestock-5eb46", appId: "1:243866845719:web:4c3549f0804a145020d252", storageBucket: "gestiondestock-5eb46.firebasestorage.app", apiKey: "AIzaSyAQVmx7uF84Gyz7WIQ229dDzTZ36GJbP5E", authDomain: "gestiondestock-5eb46.firebaseapp.com", messagingSenderId: "243866845719" })),
    provideAuth(() => getAuth())
  ],
    
  bootstrap: [AppComponent]
})
export class AppModule { }
    // Vérifiez manuellement providers si absent.
