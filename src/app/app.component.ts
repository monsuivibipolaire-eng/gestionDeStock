import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from './services/auth.service';
import { CommonModule } from '@angular/common';  // Pour *ngIf/async en template si besoin

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
  standalone: false  // Pour NgModule (pas d'imports ici)
})
export class AppComponent implements OnInit {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  // Getter lazy pour user$ (fix TS2729 : accès après constructor)
  get user$() {
    return this.authService.user$;
  }

  ngOnInit(): void {
    // Implémentation requise pour OnInit (fix TS2420) ; subscribe optionnel
    // this.user$.subscribe(user => {
    //   if (!user) {
    //     this.router.navigate(['/auth']);
    //   }
    // });
  }

  logout(): void {
    this.authService.logout().subscribe({
      next: () => {
        console.log('Logout réussi');
        this.router.navigate(['/auth']);
      },
      error: (error: Error) => {  // Typing pour TS7006
        console.error('Erreur logout:', error);
      }
    });
  }
}
