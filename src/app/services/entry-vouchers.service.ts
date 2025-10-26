import { Injectable } from '@angular/core';
import { 
  Firestore, 
  collection, 
  addDoc, 
  updateDoc, 
  deleteDoc, 
  doc, 
  collectionData, 
  query, 
  orderBy, 
  Query, 
  Timestamp,
  getDoc,
  writeBatch
} from '@angular/fire/firestore';
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

  async addEntryVoucher(voucher: Omit<EntryVoucher, 'id' | 'createdAt'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'entryVouchers');
    const batch = writeBatch(this.firestore);
    
    // Ajouter le bon d'entrée
    const voucherDocRef = doc(vouchersRef);
    batch.set(voucherDocRef, { ...voucher, createdAt: Timestamp.now() });
    
    // Mettre à jour les quantités des produits (AJOUTER)
    for (const product of voucher.products) {
      const productRef = doc(this.firestore, 'products', product.productId);
      const productSnap = await getDoc(productRef);
      
      if (productSnap.exists()) {
        const currentQuantity = productSnap.data()['quantity'] || 0;
        batch.update(productRef, { 
          quantity: currentQuantity + product.quantity 
        });
      }
    }
    
    await batch.commit();
  }

  async updateEntryVoucher(id: string, voucher: Partial<EntryVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    const batch = writeBatch(this.firestore);
    
    // Récupérer l'ancien bon pour annuler les anciennes quantités
    const oldVoucherSnap = await getDoc(voucherRef);
    if (oldVoucherSnap.exists()) {
      const oldVoucher = oldVoucherSnap.data() as EntryVoucher;
      
      // Annuler les anciennes quantités
      if (oldVoucher.products) {
        for (const oldProduct of oldVoucher.products) {
          const productRef = doc(this.firestore, 'products', oldProduct.productId);
          const productSnap = await getDoc(productRef);
          
          if (productSnap.exists()) {
            const currentQuantity = productSnap.data()['quantity'] || 0;
            batch.update(productRef, { 
              quantity: currentQuantity - oldProduct.quantity 
            });
          }
        }
      }
      
      // Ajouter les nouvelles quantités
      if (voucher.products) {
        for (const newProduct of voucher.products) {
          const productRef = doc(this.firestore, 'products', newProduct.productId);
          const productSnap = await getDoc(productRef);
          
          if (productSnap.exists()) {
            const currentQuantity = productSnap.data()['quantity'] || 0;
            batch.update(productRef, { 
              quantity: currentQuantity + newProduct.quantity 
            });
          }
        }
      }
    }
    
    // Mettre à jour le bon
    batch.update(voucherRef, voucher as any);
    
    await batch.commit();
  }

  async deleteEntryVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'entryVouchers', id);
    const batch = writeBatch(this.firestore);
    
    // Récupérer le bon pour annuler les quantités
    const voucherSnap = await getDoc(voucherRef);
    if (voucherSnap.exists()) {
      const voucher = voucherSnap.data() as EntryVoucher;
      
      // Annuler les quantités
      if (voucher.products) {
        for (const product of voucher.products) {
          const productRef = doc(this.firestore, 'products', product.productId);
          const productSnap = await getDoc(productRef);
          
          if (productSnap.exists()) {
            const currentQuantity = productSnap.data()['quantity'] || 0;
            batch.update(productRef, { 
              quantity: Math.max(0, currentQuantity - product.quantity)
            });
          }
        }
      }
    }
    
    // Supprimer le bon
    batch.delete(voucherRef);
    
    await batch.commit();
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
