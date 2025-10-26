import { Injectable } from '@angular/core';
import { Firestore, collection, addDoc, updateDoc, deleteDoc, doc, collectionData, query, orderBy, Query, Timestamp } from '@angular/fire/firestore';
import { Observable } from 'rxjs';
import { Devis } from '../models/devis';

@Injectable({
  providedIn: 'root'
})
export class DevisService {
  constructor(private firestore: Firestore) {}

  getDevis(): Observable<Devis[]> {
    const devisRef = collection(this.firestore, 'devis');
    const q: Query = query(devisRef, orderBy('date', 'desc'));
    return collectionData(q, { idField: 'id' }) as Observable<Devis[]>;
  }

  addDevis(devis: Omit<Devis, 'id' | 'createdAt'>): Promise<void> {
    const devisRef = collection(this.firestore, 'devis');
    return addDoc(devisRef, { 
      ...devis, 
      createdAt: Timestamp.now() 
    }).then(() => {});
  }

  updateDevis(id: string, devis: Partial<Devis>): Promise<void> {
    const devisRef = doc(this.firestore, 'devis', id);
    return updateDoc(devisRef, devis as any);
  }

  deleteDevis(id: string): Promise<void> {
    const devisRef = doc(this.firestore, 'devis', id);
    return deleteDoc(devisRef);
  }

  generateQuoteNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `DEV-${year}${month}${day}-${random}`;
  }
}
