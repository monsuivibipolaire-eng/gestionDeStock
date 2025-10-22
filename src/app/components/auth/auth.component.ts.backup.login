import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';  // Si besoin pour directives

@Component({
  selector: 'app-auth',
  standalone: false,
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.scss']
})
export class AuthComponent {
  // Logique (injectez services e.g., constructor(private service: ...) {})
}
