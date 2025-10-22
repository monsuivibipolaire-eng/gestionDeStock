import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';  // Si besoin pour directives

@Component({
  selector: 'app-purchase-order',
  standalone: false,
  templateUrl: './purchase-order.component.html',
  styleUrls: ['./purchase-order.component.scss']
})
export class PurchaseOrderComponent {
  // Logique (injectez services e.g., constructor(private service: ...) {})
}
