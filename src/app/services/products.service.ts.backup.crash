import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Product } from '../models/product';

@Injectable({
  providedIn: 'root'
})
export class ProductsService {
  constructor(private firestore: Firestore) {}

  getProducts(): Observable<Product[]> {
    const productsRef = collection(this.firestore, 'products');
    const q: Query = query(productsRef);
    return collectionData(q, { idField: 'id' }) as Observable<Product[]>;
  }

  addProduct(product: Omit<Product, 'id'>): Promise<void> {
    const productsRef = collection(this.firestore, 'products');
    return addDoc(productsRef, product).then(() => {});
  }

  updateProduct(id: string, product: Partial<Product>): Promise<void> {
    const productRef = doc(this.firestore, 'products', id);
    return updateDoc(productRef, product);
  }

  deleteProduct(id: string): Promise<void> {
    const productRef = doc(this.firestore, 'products', id);
    return deleteDoc(productRef);
  }
}
