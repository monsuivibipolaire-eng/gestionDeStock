import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';  // Ajustez path si besoin

@Component({
  selector: 'app-auth',
  standalone: false,  // NgModule setup
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.scss']  // Ou .css si pas SCSS
})
export class AuthComponent implements OnInit {
  loginForm: FormGroup;
  isLoading = false;
  errorMessage = '';  // Pour affichage erreurs (e.g., 'Email ou mot de passe incorrect')

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  ngOnInit(): void {
    // Vérifiez si déjà logué (optionnel)
    this.authService.user$.subscribe(user => {
      if (user) {
        this.router.navigate(['/products']);  // Redirige si logué
      }
    });
  }

  onLogin(): void {
    if (this.loginForm.invalid) {
      this.errorMessage = 'Veuillez remplir les champs correctement.';  // Multilingual : {{ 'form.invalid' | translate }}
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    const { email, password } = this.loginForm.value;

    this.authService.login(email, password).subscribe({
      next: (response) => {
        console.log('Login réussi', response);  // Ou user
        this.isLoading = false;
        this.router.navigate(['/products']);  // Redirige vers dashboard/stock
      },
      error: (error: Error) => {
        this.isLoading = false;
        // Gérez erreurs Firebase (e.g., error.code === 'auth/user-not-found')
        this.errorMessage = 'Email ou mot de passe incorrect.';  // Multilingual : {{ 'auth.invalid' | translate }}
        console.error('Erreur login:', error);
      }
    });
  }

  // Méthode pour register si besoin (ajoutez bouton)
  onRegister(): void {
    // Implémentez similaire à login, mais authService.register(email, password)
    console.log('Register clicked');
  }
}
