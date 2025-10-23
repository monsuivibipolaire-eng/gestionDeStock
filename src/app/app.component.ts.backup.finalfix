import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './services/auth.service';
import { User } from '@angular/fire/auth';

@Component({
  selector: 'app-root',
  standalone: false,
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'gestion-stock-app';
  isSidebarOpen = false;
  currentUser: User | null = null;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    // Subscribe à user$ (Observable de AuthService) pour état connexion
    this.authService.user$.subscribe((user: User | null) => {
      this.currentUser = user;
    });
  }

  toggleSidebar(): void {
    this.isSidebarOpen = !this.isSidebarOpen;
  }

  logout(): void {
    if (confirm('Êtes-vous sûr de vouloir vous déconnecter ?')) {
      this.authService.logout().then(() => {
        this.currentUser = null;
        this.router.navigate(['/auth']);  // Redirect vers page connexion
      }).catch(err => {
        console.error('Logout error:', err);
      });
    }
  }

  getUserInitial(): string {
    if (this.currentUser?.email) {
      return this.currentUser.email.charAt(0).toUpperCase();
    }
    return 'U';
  }
}
