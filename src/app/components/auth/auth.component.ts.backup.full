import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router } from '@angular/router';
import { CommonModule } from '@angular/common';  // Ajouté pour *ngIf dans template (errorMessage, isLoading, showRegister)
import { AuthService } from "../../services/auth.service";
import { User } from '@angular/fire/auth';
import { UserCredential } from '@angular/fire/auth';

@Component({
  selector: 'app-auth',
  templateUrl: './auth.component.html',
  styleUrls: ['./auth.component.scss'],
  imports: [ReactiveFormsModule, CommonModule],  // Array corrigé (imports standalone pour forms + directives)
  standalone: true  // Propriétés réorganisées (pas de CommonModule extra en dehors de l'array)
})
export class AuthComponent implements OnInit {
  loginForm: FormGroup;
  registerForm: FormGroup;
  isLoading = false;
  errorMessage = '';
  user: User | null = null;
  showRegister = false;

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
    this.registerForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]]
    });
  }

  ngOnInit(): void {
    this.authService.user$.subscribe((user: User | null) => {
      this.user = user;
      if (user) {
        this.router.navigate(['/products']);  // Redirect si logged
      }
    });
  }

  onLogin(): void {
    if (this.loginForm.invalid) {
      this.errorMessage = 'Veuillez remplir les champs correctement.';
      return;
    }
    this.isLoading = true;
    const { email, password } = this.loginForm.value;
    this.authService.login(email, password).then((response: UserCredential) => {
      console.log('Logged in:', response.user?.uid);
      this.errorMessage = '';
      this.router.navigate(['/products']);  // Success redirect
    }).catch((error: any) => {
      console.error('Login error:', error);
      this.errorMessage = error.message;
    }).finally(() => this.isLoading = false);
  }

  onRegister(): void {
    if (this.registerForm.invalid) {
      this.errorMessage = 'Veuillez remplir les champs pour l\'inscription.';
      return;
    }
    this.isLoading = true;
    const { email, password } = this.registerForm.value;
    this.authService.register(email, password).then((response: UserCredential) => {
      console.log('Registered:', response.user?.uid);
      this.errorMessage = '';
      this.router.navigate(['/products']);
    }).catch((error: any) => {
      console.error('Register error:', error);
      this.errorMessage = error.message;
    }).finally(() => this.isLoading = false);
  }

  toggleForm(): void {
    this.showRegister = !this.showRegister;
    this.errorMessage = '';
  }
}
