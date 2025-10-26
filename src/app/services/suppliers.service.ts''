import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Supplier } from '../models/supplier';

@Injectable({
  providedIn: 'root'
})
export class SuppliersService {
  constructor(private firestore: Firestore) {}

  getSuppliers(): Observable<Supplier[]> {
    const suppliersRef = collection(this.firestore, 'suppliers');
    const q: Query = query(suppliersRef, orderBy('name', 'asc'));
    return collectionData(q, { idField: 'id' }) as Observable<Supplier[]>;
  }

  addSupplier(supplier: Omit<Supplier, 'id' | 'createdAt'>): Promise<void> {
    const suppliersRef = collection(this.firestore, 'suppliers');
    return addDoc(suppliersRef, { ...supplier, createdAt: new Date() }).then(() => {});
  }

  updateSupplier(id: string, supplier: Partial<Supplier>): Promise<void> {
    const supplierRef = doc(this.firestore, 'suppliers', id);
    return updateDoc(supplierRef, supplier);
  }

  deleteSupplier(id: string): Promise<void> {
    const supplierRef = doc(this.firestore, 'suppliers', id);
    return deleteDoc(supplierRef);
  }
}
