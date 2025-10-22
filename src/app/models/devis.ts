import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface Devis {
  id?: string;
  quoteNumber: string;  // Ex: "DEV-2025-001"
  date: Timestamp | Date;
  validUntil: Timestamp | Date;  // Date validité devis
  customer: string;  // Nom client
  customerEmail?: string;
  products: ProductLine[];
  subtotal: number;  // Somme subtotals (HT)
  tva: number;  // TVA (19% en Tunisie)
  totalAmount: number;  // TTC (subtotal + tva)
  status: 'draft' | 'sent' | 'accepted' | 'rejected';  // Statut devis
  notes?: string;
  createdAt?: Timestamp | Date;
}
