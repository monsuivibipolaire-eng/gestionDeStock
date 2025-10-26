#!/bin/bash

set -e

echo "🚨 RESET COMPLET DU PROJET"
echo ""

####
# ÉTAPE 1 : Restauration depuis Git
####
echo "📦 ÉTAPE 1/5 : Restauration depuis Git..."
git add -A
git commit -m "Avant reset urgent" || true
git checkout HEAD -- src/app/components/entry-voucher/
git checkout HEAD -- src/app/components/exit-voucher/
echo "✔️  Restauré"

####
# ÉTAPE 2 : Nettoyage du cache
####
echo ""
echo "🧹 ÉTAPE 2/5 : Nettoyage du cache..."
rm -rf dist .angular node_modules/.cache
echo "✔️  Cache nettoyé"

####
# ÉTAPE 3 : Ajouter les propriétés/méthodes MINIMALES
####
echo ""
echo "🔧 ÉTAPE 3/5 : Ajout minimal des fonctionnalités..."

ENTRY_TS="src/app/components/entry-voucher/entry-voucher.component.ts"

# Ajouter productList (une fois)
if ! grep -q "productList: Product\[\]" "$ENTRY_TS"; then
  perl -i -pe 's/(products\$!: Observable<Product\[\]>;)/$1\n  productList: Product[] = [];/' "$ENTRY_TS"
fi

# Ajouter subscribe (une fois)
if ! grep -q "this\.productList = products" "$ENTRY_TS"; then
  perl -i -pe 's/(this\.products\$ = this\.productsService\.getProducts\(\);)/$1\n    this.products$.subscribe(p => this.productList = p);/' "$ENTRY_TS"
fi

# Ajouter les 3 méthodes (une fois)
if ! grep -q "getProductName(productId: string): string" "$ENTRY_TS"; then
  awk '
    /^export class EntryVoucherComponent/ { in_class = 1 }
    in_class && /^}$/ && !added {
      print "  getProductName(productId: string): string { const p = this.productList?.find(x => x.id === productId); return p?.name || \"\"; }"
      print "  getDescription(productId: string): string { const p = this.productList?.find(x => x.id === productId); return p?.description || \"\"; }"
      print "  getSubtotal(line: any): number { return (line?.quantity || 0) * (line?.unitPrice || 0); }"
      added = 1
    }
    { print }
  ' "$ENTRY_TS" > "${ENTRY_TS}.tmp" && mv "${ENTRY_TS}.tmp" "$ENTRY_TS"
fi

echo "✔️  Propriétés/méthodes ajoutées"

####
# ÉTAPE 4 : Remplacer les variables entry par voucher
####
echo ""
echo "🎨 ÉTAPE 4/5 : Correction des templates..."

perl -i -pe 's/entry\?\.products/voucher?.products/g; s/entry\?\.totalAmount/voucher?.totalAmount/g;' \
  src/app/components/entry-voucher/entry-voucher.component.html \
  src/app/components/exit-voucher/exit-voucher.component.html

echo "✔️  Templates corrigés"

####
# ÉTAPE 5 : Relancer ng serve (optional)
####
echo ""
echo "✨ ÉTAPE 5/5 : Formatage..."
if command -v npx &> /dev/null; then
  npx prettier --write src/app/components/entry-voucher/*.ts \
    src/app/components/entry-voucher/*.html \
    src/app/components/exit-voucher/*.ts \
    src/app/components/exit-voucher/*.html 2>/dev/null || true
fi

echo ""
echo "✅ ==================== RESET TERMINÉ ===================="
echo ""
echo "🚀 Maintenant :"
echo "  1. npm install"
echo "  2. ng serve"
echo "  3. F5 pour rafraîchir le navigateur"
echo "  4. Ouvre F12 > Console"
echo "  5. Clique sur un bon d'entrée"
echo "  6. Copie le MESSAGE D'ERREUR ROUGE EXACT"
echo "  7. Envoie-le moi"
echo ""
echo "✅ ================================================"
