import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.scss'],
  standalone: true,
  imports: [CommonModule]
})
export class DashboardComponent implements OnInit {
  stats = {
    products: 0,
    suppliers: 0,
    customers: 0,
    entries: 0,
    exits: 0,
    orders: 0
  };

  constructor(private router: Router) {}

  ngOnInit(): void {
    // TODO: Charger statistiques depuis services
  }

  navigateTo(path: string): void {
    this.router.navigate([path]);
  }
}
