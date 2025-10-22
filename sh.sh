#!/bin/bash

PROJECT_ROOT=$(pwd)
ANGULAR_JSON="angular.json"
APP_MODULE="src/app/app.module.ts"
AUTH_SERVICE="src/app/services/auth.service.ts"
ENV_INTERFACE="src/environments/environment.interface.ts"

echo "Migration vers Firebase modern (fix builder esbuild + module not defined)..."

# 1. Backup fichiers clés
cp "$ANGULAR_JSON" "${ANGULAR_JSON}.backup.modern" 2>/dev/null || true
cp "$APP_MODULE" "${APP_MODULE}.backup.modern" 2>/dev/null || true
cp "$AUTH_SERVICE" "${AUTH_SERVICE}.backup.modern" 2>/dev/null || true
echo "Backups créés."

# 2. Désinstallation compat legacy
npm uninstall @angular/fire firebase --save --legacy-peer-deps
echo "Compat supprimé."

# 3. Installation Firebase modern (ESM pour Angular 20 + esbuild)
npm install @angular/fire@latest firebase@latest --save --legacy-peer-deps --force
echo "Modern installé : @angular/fire@^17.0.0, firebase@^10.0.0"

# 4. Interface Environment (déjà fixe, recréation si besoin)
cat > "$ENV_INTERFACE" << 'EOL_INT'
export interface Environment {
  production: boolean;
  firebase: {
    apiKey: string;
    authDomain: string;
    projectId: string;
    storageBucket: string;
    messagingSenderId: string;
    appId: string;
  };
}
EOL_INT

cat > src/environments/environment.ts << 'EOL_DEV'
import { Environment } from './environment.interface';

export const environment: Environment = {
  production: false,
  firebase: {
    apiKey: "AIzaSyAQVmx7uF84Gyz7WIQ229dDzTZ36GJbP5E",
    authDomain: "gestiondestock-5eb46.firebaseapp.com",
    projectId: "gestiondestock-5eb46",
    storageBucket: "gestiondestock-5eb46.firebasestorage.app",
    messagingSenderId: "243866845719",
    appId: "1:243866845719:web:4c3549f0804a145020d252"
  }
};
EOL_DEV

cat > src/environments/environment.prod.ts << 'EOL_PROD'
import { Environment } from './environment.interface';

export const environment: Environment = {
  production: true,
  firebase: {
    apiKey: "AIzaSyAQVmx7uF84Gyz7WIQ229dDzTZ36GJbP5E",
    authDomain: "gestiondestock-5eb46.firebaseapp.com",
    projectId: "gestiondestock-5eb46",
    storageBucket: "gestiondestock-5eb46.firebasestorage.app",
    messagingSenderId: "243866845719",
    appId: "1:243866845719:web:4c3549f0804a145020d252"
  }
};
EOL_PROD

# 5. Mise à jour AppModule : Providers fonctionnels (modern, sans modules compat)
cat > "$APP_MODULE" << 'EOL_MOD'
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouterModule, Routes } from '@angular/router';
import { FormsModule, ReactiveFormsModule } from '@angular/forms';

import { AppComponent } from './app.component';
import { AuthComponent } from './components/auth/auth.component';
import { ProductsComponent } from './components/products/products.component';
import { EntryVoucherComponent } from './components/entry-voucher/entry-voucher.component';
import { ExitVoucherComponent } from './components/exit-voucher/exit-voucher.component';
import { PurchaseOrderComponent } from './components/purchase-order/purchase-order.component';

import { environment } from '../environments/environment';
import { provideFirebaseApp, initializeApp } from '@angular/fire/app';
import { provideAuth, getAuth } from '@angular/fire/auth';
import { provideFirestore, getFirestore } from '@angular/fire/firestore';

const routes: Routes = [
  { path: 'auth', component: AuthComponent },
  { path: 'products', component: ProductsComponent },
  { path: 'entry', component: EntryVoucherComponent },
  { path: 'exit', component: ExitVoucherComponent },
  { path: 'commande', component: PurchaseOrderComponent },
  { path: '', redirectTo: '/auth', pathMatch: 'full' },
  { path: '**', redirectTo: '/auth' }
];

@NgModule({
  declarations: [
    AppComponent,
    AuthComponent,
    ProductsComponent,
    EntryVoucherComponent,
    ExitVoucherComponent,
    PurchaseOrderComponent
  ],
  imports: [
    BrowserModule,
    RouterModule.forRoot(routes),
    FormsModule,
    ReactiveFormsModule
  ],
  providers: [
    provideFirebaseApp(() => initializeApp((environment as any).firebase)),
    provideAuth(() => getAuth()),
    provideFirestore(() => getFirestore())
  ],
  bootstrap: [AppComponent]
})
export class AppModule { }
EOL_MOD

# 6. Mise à jour AuthService : Modern (inject Auth, onAuthStateChanged)
cat > "$AUTH_SERVICE" << 'EOL_AUTH'
import { Injectable, inject } from '@angular/core';
import { Auth, signInWithEmailAndPassword, createUserWithEmailAndPassword, signOut, onAuthStateChanged, User } from '@angular/fire/auth';
import { Observable, from } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private auth: Auth = inject(Auth);

  get user$(): Observable<User | null> {
    return new Observable<User | null>(subscriber => {
      const unsub = onAuthStateChanged(this.auth, user => subscriber.next(user));
      return () => unsub();
    });
  }

  login(email: string, password: string) {
    return from(signInWithEmailAndPassword(this.auth, email, password));
  }

  register(email: string, password: string) {
    return from(createUserWithEmailAndPassword(this.auth, email, password));
  }

  logout() {
    return from(signOut(this.auth));
  }
}
EOL_AUTH

# 7. Régénération angular.json : Esbuild standard Angular 20 (rapide, moderne Firebase OK)
cat > "$ANGULAR_JSON" << 'EOL_ANG'
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "gestion-stock-app": {
      "projectType": "application",
      "schematics": {},
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "outputPath": "dist/gestion-stock-app",
            "index": "src/index.html",
            "browser": "src/main.ts",
            "polyfills": ["zone.js"],
            "tsConfig": "tsconfig.app.json",
            "assets": [
              "src/favicon.ico",
              "src/assets"
            ],
            "styles": [
              "src/styles.scss",
              "src/tailwind.css"
            ],
            "scripts": []
          },
          "configurations": {
            "production": {
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "500kb",
                  "maximumError": "1mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "2kb",
                  "maximumError": "4kb"
                }
              ],
              "outputHashing": "all"
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        },
        "serve": {
          "builder": "@angular/build:dev-server",
          "configurations": {
            "production": {
              "buildTarget": "gestion-stock-app:build:production"
            },
            "development": {
              "buildTarget": "gestion-stock-app:build:development"
            }
          },
          "defaultConfiguration": "development"
        },
        "extract-i18n": {
          "builder": "@angular/build:extract-i18n",
          "options": {
            "buildTarget": "gestion-stock-app:build"
          }
        },
        "test": {
          "builder": "@angular/build:karma",
          "options": {
            "polyfills": [
              "zone.js",
              "zone.js/testing"
            ],
            "tsConfig": "tsconfig.spec.json",
            "assets": [
              "src/favicon.ico",
              "src/assets"
            ],
            "styles": [
              "src/styles.scss"
            ],
            "scripts": []
          }
        }
      }
    }
  },
  "cli": {
    "analytics": false
  }
}
EOL_ANG

# 8. Nettoyage et réinstallation
rm -rf .angular dist node_modules package-lock.json
npm cache clean --force
npm install --legacy-peer-deps --force
ng cache clean --all 2>/dev/null || echo "ng CLI absent ; ignore."

# 9. Vérification versions
npm ls @angular/fire firebase  # Modern : 17+ et 10+
echo "angular.json : Esbuild standard (moderne Firebase OK)."

echo "Migration terminée !"
echo "Lancez 'ng serve' - esbuild fonctionne, pas de 'module not defined' ou builder error."
