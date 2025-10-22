import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Customer } from '../models/customer';

@Injectable({
  providedIn: 'root'
})
export class CustomersService {
  constructor(private firestore: Firestore) {}

  getCustomers(): Observable<Customer[]> {
    const customersRef = collection(this.firestore, 'customers');
    const q: Query = query(customersRef, orderBy('name', 'asc'));
    return collectionData(q, { idField: 'id' }) as Observable<Customer[]>;
  }

  addCustomer(customer: Omit<Customer, 'id' | 'createdAt'>): Promise<void> {
    const customersRef = collection(this.firestore, 'customers');
    return addDoc(customersRef, { ...customer, createdAt: new Date() }).then(() => {});
  }

  updateCustomer(id: string, customer: Partial<Customer>): Promise<void> {
    const customerRef = doc(this.firestore, 'customers', id);
    return updateDoc(customerRef, customer);
  }

  deleteCustomer(id: string): Promise<void> {
    const customerRef = doc(this.firestore, 'customers', id);
    return deleteDoc(customerRef);
  }
}
