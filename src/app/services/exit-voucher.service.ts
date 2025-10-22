import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query, orderBy, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { ExitVoucher, ProductLine } from '../models/exit-voucher';

@Injectable({
  providedIn: 'root'
})
export class ExitVoucherService {
  constructor(private firestore: Firestore) {}

  getExitVouchers(): Observable<ExitVoucher[]> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    const q: Query = query(vouchersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<ExitVoucher[]>;
  }

  addExitVoucher(voucher: Omit<ExitVoucher, 'id' | 'createdAt' | 'totalAmount'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    const totalAmount = this.calculateTotal(voucher.products);
    const voucherData = {
      ...voucher,
      totalAmount,
      createdAt: Timestamp.now()
    };
    return addDoc(vouchersRef, voucherData).then(() => {});
  }

  updateExitVoucher(id: string, voucher: Partial<ExitVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    const updateData = { ...voucher };
    if (voucher.products) {
      updateData.totalAmount = this.calculateTotal(voucher.products);
    }
    return updateDoc(voucherRef, updateData);
  }

  deleteExitVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    return deleteDoc(voucherRef);
  }

  private calculateTotal(products: ProductLine[]): number {
    return products.reduce((sum, p) => sum + p.subtotal, 0);
  }
}
