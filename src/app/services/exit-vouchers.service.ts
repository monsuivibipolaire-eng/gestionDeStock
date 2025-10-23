import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { ExitVoucher } from '../models/exit-voucher';

@Injectable({
  providedIn: 'root'
})
export class ExitVouchersService {
  constructor(private firestore: Firestore) {}

  getExitVouchers(): Observable<ExitVoucher[]> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    const q: Query = query(vouchersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<ExitVoucher[]>;
  }

  addExitVoucher(voucher: Omit<ExitVoucher, 'id' | 'createdAt'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    return addDoc(vouchersRef, { 
      ...voucher, 
      createdAt: Timestamp.now() 
    }).then(() => {});
  }

  updateExitVoucher(id: string, voucher: Partial<ExitVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    return updateDoc(voucherRef, voucher as any);
  }

  deleteExitVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    return deleteDoc(voucherRef);
  }

  generateVoucherNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `SRT-${year}${month}${day}-${random}`;
  }
}
