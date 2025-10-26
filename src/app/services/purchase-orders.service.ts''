import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { PurchaseOrder } from '../models/purchase-order';

@Injectable({
  providedIn: 'root'
})
export class PurchaseOrdersService {
  constructor(private firestore: Firestore) {}

  getPurchaseOrders(): Observable<PurchaseOrder[]> {
    const ordersRef = collection(this.firestore, 'purchaseOrders');
    const q: Query = query(ordersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<PurchaseOrder[]>;
  }

  addPurchaseOrder(order: Omit<PurchaseOrder, 'id' | 'createdAt'>): Promise<void> {
    const ordersRef = collection(this.firestore, 'purchaseOrders');
    return addDoc(ordersRef, { 
      ...order, 
      createdAt: Timestamp.now() 
    }).then(() => {});
  }

  updatePurchaseOrder(id: string, order: Partial<PurchaseOrder>): Promise<void> {
    const orderRef = doc(this.firestore, 'purchaseOrders', id);
    return updateDoc(orderRef, order as any);
  }

  deletePurchaseOrder(id: string): Promise<void> {
    const orderRef = doc(this.firestore, 'purchaseOrders', id);
    return deleteDoc(orderRef);
  }

  generateOrderNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `CMD-${year}${month}${day}-${random}`;
  }
}
