import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;  // quantity * unitPrice
}

export interface EntryVoucher {
  id?: string;
  date: Timestamp | Date;
  supplier: string;
  products: ProductLine[];  // Lignes produits (tableau dynamique)
  totalAmount: number;  // Somme subtotals
  status: 'pending' | 'validated' | 'cancelled';
  notes?: string;
  createdAt?: Timestamp | Date;
}
