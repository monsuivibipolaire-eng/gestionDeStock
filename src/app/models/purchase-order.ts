import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  description?: string;
  quantity: number;
  unitPrice: number;
  subtotal: number;
}

export interface PurchaseOrder {
  id?: string;
  orderNumber: string;
  date: Timestamp | Date;
  supplier: string;
  expectedDeliveryDate?: Timestamp | Date;
  products: ProductLine[];
  totalAmount: number;
  notes?: string;
  status?: 'pending' | 'confirmed' | 'delivered' | 'cancelled';
  createdAt?: Date;
}
