#!/bin/bash

# --- 1. Vérification de l'environnement ---
if [ ! -f "angular.json" ]; then
    echo "ERREUR : Ce script doit être exécuté à la racine de votre projet Angular."
    exit 1
fi

# --- 2. Demande du nom du fichier de sortie ---
read -p "Entrez le nom du fichier de sortie (ex: code_complet.txt): " OUTPUT_FILE

# Si l'utilisateur n'entre rien, on utilise un nom par défaut
if [ -z "$OUTPUT_FILE" ]; then
    OUTPUT_FILE="projet_concatene.txt"
fi

echo "---"
echo "Lancement de la concaténation. Le résultat sera dans le fichier : $OUTPUT_FILE"

# --- 3. Concaténation des fichiers ---

# On supprime l'ancien fichier de sortie s'il existe
rm -f "$OUTPUT_FILE"

# On trouve tous les fichiers pertinents et on les ajoute au fichier de sortie
# On exclut les dossiers lourds ou non pertinents
find . -type f \
    -not -path "./node_modules/*" \
    -not -path "./.git/*" \
    -not -path "./.angular/*" \
    -not -path "./dist/*" \
    -not -path "./release/*" \
    -not -name "$OUTPUT_FILE" \
    -not -name "*.ico" \
    -not -name "*.png" \
    -not -name "*.jpg" \
    -not -name "*.svg" \
| while read -r file; do
    # Pour chaque fichier trouvé, on ajoute un en-tête puis son contenu
    echo "======================================================================" >> "$OUTPUT_FILE"
    echo "FICHIER : $file" >> "$OUTPUT_FILE"
    echo "======================================================================" >> "$OUTPUT_FILE"
    cat "$file" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
done

echo "---"
echo "✅ Opération terminée avec succès !"
echo "Tous les fichiers pertinents du projet ont été concaténés dans '$OUTPUT_FILE'."
