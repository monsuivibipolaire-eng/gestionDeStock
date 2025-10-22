import { Timestamp } from '@angular/fire/firestore';

export interface ProductLine {
  productId: string;
  productName: string;
  quantityOrdered: number;
  quantityReceived: number;  // Quantité reçue (≤ commandée)
  unitPrice: number;
  subtotal: number;
}

export interface PurchaseOrder {
  id?: string;
  orderNumber: string;  // Numéro commande (auto ou manuel, ex: "PO-2025-001")
  date: Timestamp | Date;  // Date commande
  supplier: string;  // Fournisseur
  expectedDeliveryDate: Timestamp | Date;  // Date livraison prévue
  products: ProductLine[];
  totalAmount: number;
  status: 'pending' | 'partial' | 'received' | 'cancelled';  // Statut commande
  receivedDate?: Timestamp | Date;  // Date réception réelle (si received)
  notes?: string;
  createdAt?: Timestamp | Date;
}
