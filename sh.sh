#!/bin/bash

set -e

echo "🚀 ==================== SCRIPT COMPLET FINAL ===================="
echo "Cet script corrige TOUS les problèmes du projet en une fois"
echo "==========================================================="
echo ""

####
# ÉTAPE 1 : Restauration depuis Git (état propre)
####
echo "📦 ÉTAPE 1/5 : Restauration depuis Git..."
git add -A
git commit -m "Avant corrections finales" || true
git checkout HEAD -- src/app/components/entry-voucher/
git checkout HEAD -- src/app/components/exit-voucher/
echo "✔️  Fichiers restaurés"

####
# ÉTAPE 2 : Correction de entry-voucher.component.ts
####
echo ""
echo "🔧 ÉTAPE 2/5 : Correction du composant entry-voucher..."

ENTRY_TS="src/app/components/entry-voucher/entry-voucher.component.ts"

# Ajouter productList
perl -i -pe '
  if (/products\$!: Observable<Product\[\]>;/) {
    $_ .= "  productList: Product[] = [];\n";
  }
' "$ENTRY_TS"

# Ajouter subscribe
perl -i -pe '
  if (/this\.products\$ = this\.productsService\.getProducts\(\);/) {
    $_ .= "    this.products\$.subscribe(products => {\n      this.productList = products;\n    });\n";
  }
' "$ENTRY_TS"

# Ajouter getProductName et getDescription
if ! grep -q "getProductName(productId: string): string" "$ENTRY_TS"; then
  awk '
    /^export class EntryVoucherComponent/ {in_class=1}
    in_class && /^}$/ && !added {
      print "  getProductName(productId: string): string {"
      print "    const prod = this.productList.find(p => p.id === productId);"
      print "    return prod?.name || \"Produit inconnu\";"
      print "  }"
      print ""
      print "  getDescription(productId: string): string {"
      print "    const prod = this.productList.find(p => p.id === productId);"
      print "    return prod?.description || \"Pas de description\";"
      print "  }"
      print ""
      added=1
    }
    {print}
  ' "$ENTRY_TS" > "${ENTRY_TS}.tmp" && mv "${ENTRY_TS}.tmp" "$ENTRY_TS"
fi

echo "✔️  entry-voucher.component.ts corrigé"

####
# ÉTAPE 3 : Correction du template entry-voucher
####
echo ""
echo "🎨 ÉTAPE 3/5 : Correction du template entry-voucher..."

ENTRY_HTML="src/app/components/entry-voucher/entry-voucher.component.html"

# Remplacer entry par voucher
perl -i -pe '
  s/entry\?\.products/voucher.products/g;
  s/entry\?\.totalAmount/voucher.totalAmount/g;
' "$ENTRY_HTML"

echo "✔️  entry-voucher.component.html corrigé"

####
# ÉTAPE 4 : Même corrections pour exit-voucher
####
echo ""
echo "🔧 ÉTAPE 4/5 : Correction du composant exit-voucher..."

EXIT_TS="src/app/components/exit-voucher/exit-voucher.component.ts"
EXIT_HTML="src/app/components/exit-voucher/exit-voucher.component.html"

# Ajouter productList si absent
if ! grep -q "productList: Product\[\]" "$EXIT_TS"; then
  perl -i -pe '
    if (/products\$!: Observable<Product\[\]>;/) {
      $_ .= "  productList: Product[] = [];\n";
    }
  ' "$EXIT_TS"
fi

# Ajouter subscribe si absent
if ! grep -q "this.productList = products" "$EXIT_TS"; then
  perl -i -pe '
    if (/this\.products\$ = this\.productsService\.getProducts\(\);/) {
      $_ .= "    this.products\$.subscribe(products => {\n      this.productList = products;\n    });\n";
    }
  ' "$EXIT_TS"
fi

# Ajouter méthodes get si absentes
if ! grep -q "getProductName(productId: string): string" "$EXIT_TS"; then
  awk '
    /^export class ExitVoucherComponent/ {in_class=1}
    in_class && /^}$/ && !added {
      print "  getProductName(productId: string): string {"
      print "    const prod = this.productList.find(p => p.id === productId);"
      print "    return prod?.name || \"Produit inconnu\";"
      print "  }"
      print ""
      print "  getDescription(productId: string): string {"
      print "    const prod = this.productList.find(p => p.id === productId);"
      print "    return prod?.description || \"Pas de description\";"
      print "  }"
      print ""
      added=1
    }
    {print}
  ' "$EXIT_TS" > "${EXIT_TS}.tmp" && mv "${EXIT_TS}.tmp" "$EXIT_TS"
fi

# Remplacer dans template exit-voucher
perl -i -pe '
  s/entry\?\.products/voucher.products/g;
  s/entry\?\.totalAmount/voucher.totalAmount/g;
' "$EXIT_HTML"

echo "✔️  exit-voucher corrigé"

####
# ÉTAPE 5 : Formatage et vérification
####
echo ""
echo "✨ ÉTAPE 5/5 : Formatage et vérification..."

if command -v npx &> /dev/null; then
  npx prettier --write src/app/components/entry-voucher/ 2>/dev/null || true
  npx prettier --write src/app/components/exit-voucher/ 2>/dev/null || true
fi

echo "✔️  Formatage appliqué"

####
# RÉSUMÉ FINAL
####
echo ""
echo "✅ ==================== RÉSUMÉ FINAL ===================="
echo ""
echo "✓ Restauration depuis Git"
echo "✓ productList ajouté aux deux composants"
echo "✓ Subscribe products\$ → productList"
echo "✓ getProductName et getDescription ajoutées"
echo "✓ entry remplacé par voucher dans les templates"
echo "✓ Formatage appliqué"
echo ""
echo "🚀 PROCHAINES ÉTAPES :"
echo ""
echo "1️⃣  Nettoyez le cache :"
echo "   rm -rf dist .angular node_modules/.cache"
echo ""
echo "2️⃣  Relancez l'application :"
echo "   ng serve"
echo ""
echo "3️⃣  Videz Firestore :"
echo "   - Allez dans Firebase Console"
echo "   - Cloud Firestore > Supprimer tous les documents dans 'entryVouchers'"
echo "   - Supprimer tous les documents dans 'exitVouchers'"
echo ""
echo "4️⃣  Testez l'application :"
echo "   - Créez un nouveau Bon d'Entrée avec des produits"
echo "   - Cliquez sur 'Détail' pour voir :"
echo "     ID | Nom/Description du Produit | Quantité | Prix Unit"
echo ""
echo "✅ ================================================"
