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

  async addExitVoucher(voucher: Omit<ExitVoucher, 'id' | 'createdAt'>): Promise<void> {
    const vouchersRef = collection(this.firestore, 'exitVouchers');
    const batch = writeBatch(this.firestore);
    
    // Ajouter le bon de sortie
    const voucherDocRef = doc(vouchersRef);
    batch.set(voucherDocRef, { ...voucher, createdAt: Timestamp.now() });
    
    // Mettre à jour les quantités des produits (SOUSTRAIRE)
    for (const product of voucher.products) {
      const productRef = doc(this.firestore, 'products', product.productId);
      const productSnap = await getDoc(productRef);
      
      if (productSnap.exists()) {
        const currentQuantity = productSnap.data()['quantity'] || 0;
        const newQuantity = Math.max(0, currentQuantity - product.quantity);
        batch.update(productRef, { quantity: newQuantity });
      }
    }
    
    await batch.commit();
  }

  async updateExitVoucher(id: string, voucher: Partial<ExitVoucher>): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    const batch = writeBatch(this.firestore);
    
    // Récupérer l'ancien bon pour annuler les anciennes quantités
    const oldVoucherSnap = await getDoc(voucherRef);
    if (oldVoucherSnap.exists()) {
      const oldVoucher = oldVoucherSnap.data() as ExitVoucher;
      
      // Annuler les anciennes quantités (ré-ajouter)
      if (oldVoucher.products) {
        for (const oldProduct of oldVoucher.products) {
          const productRef = doc(this.firestore, 'products', oldProduct.productId);
          const productSnap = await getDoc(productRef);
          
          if (productSnap.exists()) {
            const currentQuantity = productSnap.data()['quantity'] || 0;
            batch.update(productRef, { 
              quantity: currentQuantity + oldProduct.quantity 
            });
          }
        }
      }
      
      // Appliquer les nouvelles quantités (soustraire)
      if (voucher.products) {
        for (const newProduct of voucher.products) {
          const productRef = doc(this.firestore, 'products', newProduct.productId);
          const productSnap = await getDoc(productRef);
          
          if (productSnap.exists()) {
            const currentQuantity = productSnap.data()['quantity'] || 0;
            const newQuantity = Math.max(0, currentQuantity - newProduct.quantity);
            batch.update(productRef, { quantity: newQuantity });
          }
        }
      }
    }
    
    // Mettre à jour le bon
    batch.update(voucherRef, voucher as any);
    
    await batch.commit();
  }

  async deleteExitVoucher(id: string): Promise<void> {
    const voucherRef = doc(this.firestore, 'exitVouchers', id);
    const batch = writeBatch(this.firestore);
    
    // Récupérer le bon pour annuler les quantités
    const voucherSnap = await getDoc(voucherRef);
    if (voucherSnap.exists()) {
      const voucher = voucherSnap.data() as ExitVoucher;
      
      // Annuler les quantités (ré-ajouter)
      if (voucher.products) {
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
    return `SRT-${year}${month}${day}-${random}`;
  }
}
