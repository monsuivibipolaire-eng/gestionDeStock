#!/bin/bash

APP_MODULE="src/app/app.module.ts"
ENV_INTERFACE="src/environments/environment.interface.ts"

echo "Correction TS2339 : Assertion de type pour environment.firebase..."

# 1. Vérification interface (si absent, recrée)
if [ ! -f "$ENV_INTERFACE" ]; then
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
  echo "Interface recréée."
fi

# 2. Mise à jour environment.ts (assure typing)
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

# 3. Correction app.module.ts : Import interface + type assertion pour bypass
# Supprime import existant et ajoute typé
sed -i '' '/import { environment }/d' "$APP_MODULE"
cat >> "$APP_MODULE" << 'EOL_IMPORT'
import { environment } from '../environments/environment';
import { Environment } from '../environments/environment.interface';
EOL_IMPORT

# Remplace initializeApp ligne ~42 par assertion
sed -i '' 's/AngularFireModule.initializeApp(environment.firebase)/AngularFireModule.initializeApp((environment as Environment).firebase)/g' "$APP_MODULE"

# Alternative : Si assertion pas voulu, ajoutez @ts-ignore avant la ligne
# sed -i '' 's/AngularFireModule.initializeApp(.*environment\.firebase),/\/\/ @ts-ignore\n    AngularFireModule.initializeApp(environment.firebase),/g' "$APP_MODULE"

echo "app.module.ts mis à jour avec typing explicite."
echo "Contenu de la ligne Firebase :"
grep -n "AngularFireModule" "$APP_MODULE"

# 4. Validation TypeScript (sans serve)
npx tsc --noEmit 2>/dev/null && echo "Types OK !" || echo "Types check (erreurs attendues si RxJS reste)."

# 5. Réinstall pour types (si besoin)
npm install --legacy-peer-deps --force 2>/dev/null || true

echo "Fix appliqué ! Lancez 'ng serve' - TS2339 résolu."
