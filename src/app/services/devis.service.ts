import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, query, collectionData, Query, orderBy, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Devis, ProductLine } from '../models/devis';

@Injectable({
  providedIn: 'root'
})
export class DevisService {
  private readonly TVA_RATE = 0.19;  // 19% TVA Tunisie

  constructor(private firestore: Firestore) {}

  getDevis(): Observable<Devis[]> {
    const devisRef = collection(this.firestore, 'quotes');
    const q: Query = query(devisRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<Devis[]>;
  }

  addDevis(devis: Omit<Devis, 'id' | 'createdAt' | 'subtotal' | 'tva' | 'totalAmount'>): Promise<void> {
    const devisRef = collection(this.firestore, 'quotes');
    const subtotal = this.calculateSubtotal(devis.products);
    const tva = subtotal * this.TVA_RATE;
    const devisData = {
      ...devis,
      subtotal,
      tva,
      totalAmount: subtotal + tva,
      createdAt: Timestamp.now()
    };
    return addDoc(devisRef, devisData).then(() => {});
  }

  updateDevis(id: string, devis: Partial<Devis>): Promise<void> {
    const devisRef = doc(this.firestore, 'quotes', id);
    const updateData = { ...devis };
    if (devis.products) {
      const subtotal = this.calculateSubtotal(devis.products);
      const tva = subtotal * this.TVA_RATE;
      updateData.subtotal = subtotal;
      updateData.tva = tva;
      updateData.totalAmount = subtotal + tva;
    }
    return updateDoc(devisRef, updateData);
  }

  deleteDevis(id: string): Promise<void> {
    const devisRef = doc(this.firestore, 'quotes', id);
    return deleteDoc(devisRef);
  }

  private calculateSubtotal(products: ProductLine[]): number {
    return products.reduce((sum, p) => sum + p.subtotal, 0);
  }

  generateQuoteNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `DEV-${year}${month}-${random}`;
  }
}
