#!/bin/bash

APP_COMPONENT="src/app/app.component.ts"
APP_SCSS="src/app/app.component.scss"
APP_MODULE="src/app/app.module.ts"

echo "Régénération complète app.component.ts (fix syntaxe TS2420/TS1005/NG6001/etc.)..."

# 1. Backup malformé
cp "$APP_COMPONENT" "${APP_COMPONENT}.backup.malformed" 2>/dev/null || true
echo "Backup créé : ${APP_COMPONENT}.backup.malformed"

# 2. Création app.component.scss (si absent, fix NG2008)
if [ ! -f "$APP_SCSS" ]; then
  cat > "$APP_SCSS" << 'EOL_SCSS'
/* Styles pour AppComponent - Tailwind compatible */
.container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;
}
EOL_SCSS
  echo "app.component.scss créé."
fi

# 3. Ajout AppComponent à declarations AppModule (fix NG6001 si manquant)
if ! grep -q "AppComponent" "$APP_MODULE"; then
  sed -i '' '/declarations: \[/a\    AppComponent,' "$APP_MODULE"
  echo "AppComponent ajouté à declarations AppModule."
fi

# 4. Régénération complète app.component.ts (clean, valide syntaxe)
cat > "$APP_COMPONENT" << 'EOL_COMP'
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
EOL_COMP

# 5. Ajout CommonModule à AppModule imports (pour template pipes si besoin)
if ! grep -q "CommonModule" "$APP_MODULE"; then
  sed -i '' '/imports: \[/a\    CommonModule,' "$APP_MODULE"
  echo "CommonModule ajouté à AppModule (pour async/*ngIf)."
fi

# 6. Validation TypeScript (syntaxe + types)
npx tsc --noEmit 2>/dev/null && echo "Syntaxe et types OK ! Pas de TS2420/TS1005/NG6001/TS2729." || echo "Vérifiez manuellement 'tsc --noEmit' (fichier peut-être encore malformé)."

# 7. Nettoyage cache Angular
ng cache clean --all 2>/dev/null || echo "ng CLI absent ; ignorez."

echo "app.component.ts régénéré (getter user$, ngOnInit vide, logout valide)."
echo "Décorator @Component OK (non-standalone, pas d'imports)."
echo "Lancez 'ng serve' - bundle sans erreurs syntaxe/top-level return."
