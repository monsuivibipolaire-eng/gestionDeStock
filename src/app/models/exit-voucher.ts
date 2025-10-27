import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface ExitVoucher {
  id?: string;
  voucherNumber: string;
  date: Timestamp | Date;
  customer: string;
  destination?: string;
  products: ProductLine[];
  totalAmount: number;
  notes?: string;
  createdAt?: Date;
}
