import { Injectable } from '@angular/core';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { Observable } from 'rxjs';
import { DocumentChangeAction } from '@angular/fire/compat/firestore';

export interface Product {
  id?: string;
  name: string;
  quantity: number;
  price: number;
}

@Injectable({
  providedIn: 'root'
})
export class ProductsService {
  private productsCollection: any;

  constructor(private firestore: AngularFirestore) {
    this.productsCollection = this.firestore.collection<Product>('products');
  }

  getProducts(): Observable<any[]> {  // Any pour éviter types stricts ; étendez plus tard
    return this.productsCollection.snapshotChanges();
  }

  addProduct(product: Product) {
    return this.productsCollection.add(product);
  }

  updateProduct(id: string, product: Product) {
    return this.productsCollection.doc(id).update(product);
  }

  deleteProduct(id: string) {
    return this.productsCollection.doc(id).delete();
  }
}
