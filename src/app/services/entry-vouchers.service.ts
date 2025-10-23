import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { EntryVoucher } from '../models/entry-voucher';

@Injectable({
  providedIn: 'root'
})
export class EntryVouchersService {
  constructor(private firestore: Firestore) {}

  getEntryVouchers(): Observable<EntryVoucher[]> {
    const vouchersRef = collection(this.firestore, 'entryVouchers');
    const q: Query = query(vouchersRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<EntryVoucher[]>;
  }

  addEntryVoucher(voucher: Omit<EntryVoucher, 'id' | 'createdAt'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'entryVouchers');
    return addDoc(vouchersRef, { 
      ...voucher, 
      createdAt: Timestamp.now() 
    }).then(() => {});
  }

  updateEntryVoucher(id: string, voucher: Partial<EntryVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    return updateDoc(voucherRef, voucher as any);
  }

  deleteEntryVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    return deleteDoc(voucherRef);
  }

  generateVoucherNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `ENT-${year}${month}${day}-${random}`;
  }
}
