import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query, orderBy, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { PurchaseOrder, ProductLine } from '../models/purchase-order';

@Injectable({
  providedIn: 'root'
})
export class PurchaseOrderService {
  constructor(private firestore: Firestore) {}

  getPurchaseOrders(): Observable<PurchaseOrder[]> {
    const ordersRef = collection(this.firestore, 'purchaseOrders');
    const q: Query = query(ordersRef, orderBy('orderNumber', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<PurchaseOrder[]>;
  }

  addPurchaseOrder(order: Omit<PurchaseOrder, 'id' | 'createdAt' | 'totalAmount'>): Promise<void> {
    const ordersRef = collection(this.firestore, 'purchaseOrders');
    const totalAmount = this.calculateTotal(order.products);
    const orderData = {
      ...order,
      totalAmount,
      createdAt: Timestamp.now()
    };
    return addDoc(ordersRef, orderData).then(() => {});
  }

  updatePurchaseOrder(id: string, order: Partial<PurchaseOrder>): Promise<void> {
    const orderRef = doc(this.firestore, 'purchaseOrders', id);
    const updateData = { ...order };
    if (order.products) {
      updateData.totalAmount = this.calculateTotal(order.products);
      // Auto-update status si toutes quantités reçues
      const allReceived = order.products.every(p => p.quantityReceived >= p.quantityOrdered);
      const someReceived = order.products.some(p => p.quantityReceived > 0);
      if (allReceived) {
        updateData.status = 'received';
        updateData.receivedDate = Timestamp.now();
      } else if (someReceived) {
        updateData.status = 'partial';
      }
    }
    return updateDoc(orderRef, updateData);
  }

  deletePurchaseOrder(id: string): Promise<void> {
    const orderRef = doc(this.firestore, 'purchaseOrders', id);
    return deleteDoc(orderRef);
  }

  private calculateTotal(products: ProductLine[]): number {
    return products.reduce((sum, p) => sum + p.subtotal, 0);
  }

  generateOrderNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `PO-${year}${month}-${random}`;
  }
}
