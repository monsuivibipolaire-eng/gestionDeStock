import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface EntryVoucher {
  id?: string;
  voucherNumber: string;
  date: Timestamp | Date;
  supplier: string;
  products: ProductLine[];
  totalAmount: number;
  notes?: string;
  createdAt?: Date;
}
