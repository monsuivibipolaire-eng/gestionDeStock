import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './services/auth.service';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: [] // Ou ['./app.component.scss'] si vous en créez un
})
export class AppComponent {
  title = 'gestion-stock-app';

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  logout() {
    this.authService.logout().then(() => {
      this.router.navigate(['/auth']);
    }).catch(error => {
      console.error('Erreur de déconnexion:', error);
    });
  }
}
