# Création manuelle du dossier environments
mkdir -p src/environments

# Génération des fichiers environment.ts par Angular CLI (recommandé, configure aussi angular.json)
ng generate environments

# Ou, si vous préférez redéfinir les fichiers avec votre config Firebase
cat > src/environments/environment.ts << EOL
export const environment = {
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
EOL

cat > src/environments/environment.prod.ts << EOL
export const environment = {
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
EOL

# Vérification : listez les fichiers
ls src/environments/
