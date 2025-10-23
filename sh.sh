#!/bin/bash

# Fix Supplier model - Ajouter city
# Usage: ./fix-supplier-model.sh

echo "Fix Supplier model..."

SUPPLIER_MODEL="src/app/models/supplier.ts"

# Backup
cp "$SUPPLIER_MODEL" "${SUPPLIER_MODEL}.backup"

# Régénérer model avec city
cat > "$SUPPLIER_MODEL" << 'EOF'
export interface Supplier {
  id?: string;
  name: string;
  email?: string;
  phone?: string;
  address?: string;
  city?: string;
  notes?: string;
}
EOF

echo "✅ Supplier model mis à jour (city ajouté)"

# Validation
if command -v ng &> /dev/null; then
    ng cache clean
    npx tsc --noEmit 2>&1 | head -20
fi

echo ""
echo "Changement :"
echo "  - Propriété 'city?: string' ajoutée au model Supplier"
echo ""
echo "Test : ng serve"
