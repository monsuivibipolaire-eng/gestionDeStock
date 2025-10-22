import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface ExitVoucher {
  id?: string;
  date: Timestamp | Date;
  customer: string;  // Nom client (ou destination si transfert)
  destination?: string;  // Destination transfert/perte
  type: 'sale' | 'transfer' | 'loss';  // Type sortie (vente, transfert, perte)
  products: ProductLine[];
  totalAmount: number;
  status: 'pending' | 'validated' | 'cancelled';
  notes?: string;
  createdAt?: Timestamp | Date;
}
