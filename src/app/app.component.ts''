import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { Auth, signOut, onAuthStateChanged, User } from '@angular/fire/auth';
import { Router } from '@angular/router';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive]
})
export class AppComponent implements OnInit {
  title = 'gestion-stock';
  currentUser: User | null = null;
  isSidebarOpen = true;

  constructor(
    private auth: Auth,
    private router: Router
  ) {}

  ngOnInit(): void {
    onAuthStateChanged(this.auth, (user) => {
      this.currentUser = user;
      if (!user) {
        this.router.navigate(['/login']);
      }
    });
  }

  toggleSidebar(): void {
    this.isSidebarOpen = !this.isSidebarOpen;
  }

  getUserInitial(): string {
    if (!this.currentUser?.email) {
      return 'U';
    }
    return this.currentUser.email.charAt(0).toUpperCase();
  }

  async logout(): Promise<void> {
    try {
      await signOut(this.auth);
      this.currentUser = null;
      this.router.navigate(['/login']);
    } catch (error) {
      console.error('Erreur logout:', error);
      alert('Erreur lors de la déconnexion');
    }
  }
}
