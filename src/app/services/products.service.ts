import { Injectable } from '@angular/core';
import { AngularFirestore } from '@angular/fire/compat/firestore';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

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
    this.productsCollection = this.firestore.collection('products');
  }

  getProducts(): Observable<Product[]> {
    return this.productsCollection.snapshotChanges().pipe(
      map(actions => actions.map(a => {
        const data = a.payload.doc.data() as Product;
        const id = a.payload.doc.id;
        return { id, ...data };
      }))
    );
  }

  addProduct(product: Product) {
    return this.productsCollection.add(product);
  }

  updateProduct(id: string, product: Product) {
    return this.productsCollection.doc(id).update({ ...product });
  }

  deleteProduct(id: string) {
    return this.productsCollection.doc(id).delete();
  }
}
