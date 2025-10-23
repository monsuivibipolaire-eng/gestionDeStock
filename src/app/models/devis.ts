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
  quoteNumber: string;
  date: Timestamp | Date;
  customer: string;
  validUntil?: Timestamp | Date;
  products: ProductLine[];
  totalAmount: number;
  notes?: string;
  status?: 'draft' | 'sent' | 'accepted' | 'rejected';
  createdAt?: Date;
}
