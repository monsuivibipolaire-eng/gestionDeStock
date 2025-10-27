#!/bin/bash

# Script pour FORCER la réinsertion des propriétés/méthodes de filtrage
# dans EntryVoucherComponent pour corriger les erreurs TS2339

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}=== Réinsertion Propriétés/Méthodes EntryVoucherComponent ===${NC}\n"

TS_FILE="./src/app/components/entry-voucher/entry-voucher.component.ts"

# --- Vérifier l'existence du fichier ---
if [ ! -f "$TS_FILE" ]; then
    echo -e "${RED}ERREUR: Fichier $TS_FILE introuvable.${NC}"
    exit 1
fi

# --- Créer backup ---
echo "  → Création backup ($TS_FILE.bak.reinsert)..."
cp "$TS_FILE" "$TS_FILE.bak.reinsert"

# --- Réparer le fichier TypeScript (.ts) ---
echo "  → Réparation de $TS_FILE..."

# Utiliser perl pour supprimer les anciennes déclarations (commentées ou non)
# Et réinsérer les déclarations correctes juste après la ligne 'expandedVoucherId: string | null = null;'
# (ou une autre ligne de déclaration de propriété similaire si celle-là a été modifiée)

perl -i -0777 -pe '
    # Supprimer les anciennes déclarations de filtre et méthodes associées
    s/^\s*\/\/ Filtres.*?sortOrder\$.*?;.*?\n//msg;
    s/^\s*onSearchChange\(.*?\n//msg;
    s/^\s*onSupplierFilterChange\(.*?\n//msg;
    s/^\s*onDateFromChange\(.*?\n//msg;
    s/^\s*onDateToChange\(.*?\n//msg;
    s/^\s*onMinAmountChange\(.*?\n//msg;
    s/^\s*onMaxAmountChange\(.*?\n//msg;
    s/^\s*onSortChange\(.*?\n//msg;
    s/^\s*clearFilters\(.*?\n//msg;
    s/^\s*toggleForm\(.*?\n//msg; # Ajout de toggleForm

    # Réinsérer les déclarations après une ligne connue (ajuster si besoin)
    s{(expandedVoucherId:\s*string\s*\|\s*null\s*=\s*null;)}
     {$1

      \n  // Filtres
      searchTerm = \x27\x27;
      searchTerm$ = new BehaviorSubject<string>(\x27\x27);
      selectedSupplier: string | null = null;
      selectedSupplier$ = new BehaviorSubject<string | null>(null);
      dateFrom: string | null = null;
      dateFrom$ = new BehaviorSubject<string | null>(null);
      dateTo: string | null = null;
      dateTo$ = new BehaviorSubject<string | null>(null);
      minAmount: number | null = null;
      minAmount$ = new BehaviorSubject<number | null>(null);
      maxAmount: number | null = null;
      maxAmount$ = new BehaviorSubject<number | null>(null);
      sortBy: \x27date\x27 | \x27supplier\x27 | \x27amount\x27 = \x27date\x27;
      sortBy$ = new BehaviorSubject<\x27date\x27 | \x27supplier\x27 | \x27amount\x27>(\x27date\x27);
      sortOrder: \x27asc\x27 | \x27desc\x27 = \x27desc\x27;
      sortOrder$ = new BehaviorSubject<\x27asc\x27 | \x27desc\x27>(\x27desc\x27);
      \n
      constructor(
    }m;

    # Réinsérer les méthodes avant la méthode onSubmit (ou une autre méthode connue)
     s{(^\s*onSubmit\(\):\s*void\s*\{)}
      {
      \n  // Méthodes filtres
      onSearchChange(term: string): void {
        this.searchTerm = term;
        this.searchTerm$.next(term);
      }

      onSupplierFilterChange(supplier: string | null): void {
        this.selectedSupplier = supplier;
        this.selectedSupplier$.next(supplier);
      }

      onDateFromChange(date: string | null): void {
        this.dateFrom = date;
        this.dateFrom$.next(date);
      }

      onDateToChange(date: string | null): void {
        this.dateTo = date;
        this.dateTo$.next(date);
      }

      onMinAmountChange(amount: number | null): void {
        this.minAmount = amount;
        this.minAmount$.next(amount);
      }

      onMaxAmountChange(amount: number | null): void {
        this.maxAmount = amount;
        this.maxAmount$.next(amount);
      }

      onSortChange(sortBy: \x27date\x27 | \x27supplier\x27 | \x27amount\x27): void {
        if (this.sortBy === sortBy) {
          this.sortOrder = this.sortOrder === \x27asc\x27 ? \x27desc\x27 : \x27asc\x27;
        } else {
          this.sortBy = sortBy;
          this.sortOrder = this.sortBy === \x27date\x27 ? \x27desc\x27 : \x27asc\x27;
        }
        this.sortBy$.next(this.sortBy);
        this.sortOrder$.next(this.sortOrder);
      }

      clearFilters(): void {
        this.searchTerm = \x27\x27;
        this.searchTerm$.next(\x27\x27);
        this.selectedSupplier = null;
        this.selectedSupplier$.next(null);
        this.dateFrom = null;
        this.dateFrom$.next(null);
        this.dateTo = null;
        this.dateTo$.next(null);
        this.minAmount = null;
        this.minAmount$.next(null);
        this.maxAmount = null;
        this.maxAmount$.next(null);
        this.sortBy = \x27date\x27;
        this.sortBy$.next(\x27date\x27);
        this.sortOrder = \x27desc\x27;
        this.sortOrder$.next(\x27desc\x27);
      }

      toggleForm(): void {
        this.showForm = !this.showForm;
        if (!this.showForm) {
          this.resetForm();
        }
      }
      \n
      $1 # Réinsère le début de onSubmit
    }m;

    # Assurer que ngOnInit existe (très important!)
    unless (/ngOnInit\(\):\s*void\s*\{/) {
      s{(constructor\(.*?\)\s*\{.*?\})\s*\n}
       {$1\n\n  ngOnInit(): void {\n    // Mettez ici le contenu original de ngOnInit si vous l aviez\n    this.loadVouchers();\n    this.products$ = this.productsService.getProducts();\n    this.products$.subscribe((products) => {\n      this.productList = products;\n    });\n    this.suppliers$ = this.suppliersService.getSuppliers();\n\n    // Initialisation filteredVouchers$ (copié depuis un état fonctionnel)\n    this.filteredVouchers$ = combineLatest([\n      this.vouchers$,\n      this.searchTerm$,\n      this.selectedSupplier$,\n      this.dateFrom$,\n      this.dateTo$,\n      this.minAmount$,\n      this.maxAmount$,\n      this.sortBy$,\n      this.sortOrder$,\n    ]).pipe(\n      map(\n        ([vouchers, term, supplier, dateFrom, dateTo, minAmount, maxAmount, sortBy, sortOrder]) => {\n          let filtered = vouchers;\n          if (term) {\n            filtered = filtered.filter((v) =>\n              v.voucherNumber.toLowerCase().includes(term.toLowerCase()),\n            );\n          }\n          if (supplier) {\n            filtered = filtered.filter((v) => v.supplier === supplier);\n          }\n          if (dateFrom) {\n            const fromDate = new Date(dateFrom);\n            filtered = filtered.filter((v) => {\n              const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);\n              return vDate >= fromDate;\n            });\n          }\n          if (dateTo) {\n            const toDate = new Date(dateTo);\n            toDate.setHours(23, 59, 59);\n            filtered = filtered.filter((v) => {\n              const vDate = v.date instanceof Timestamp ? v.date.toDate() : new Date(v.date);\n              return vDate <= toDate;\n            });\n          }\n          if (minAmount !== null) {\n            filtered = filtered.filter((v) => (v.totalAmount \|\| 0) >= minAmount);\n          }\n          if (maxAmount !== null) {\n            filtered = filtered.filter((v) => (v.totalAmount \|\| 0) <= maxAmount);\n          }\n          filtered = filtered.sort((a, b) => {\n            let compareValue = 0;\n            if (sortBy === \x27date\x27) {\n              const dateA =\n                a.date instanceof Timestamp\n                  ? a.date.toDate().getTime()\n                  : new Date(a.date).getTime();\n              const dateB =\n                b.date instanceof Timestamp\n                  ? b.date.toDate().getTime()\n                  : new Date(b.date).getTime();\n              compareValue = dateA - dateB;\n            } else if (sortBy === \x27supplier\x27) {\n              compareValue = a.supplier.localeCompare(b.supplier);\n            } else if (sortBy === \x27amount\x27) {\n              compareValue = (a.totalAmount \|\| 0) - (b.totalAmount \|\| 0);\n            }\n            return sortOrder === \x27asc\x27 ? compareValue : -compareValue;\n          });\n          return filtered;\n        },\n      ),\n    );\n\n  }\n\n}m; # Fin de l ajout de ngOnInit
    }

' "$TS_FILE"

echo -e "${GREEN}    ✓ Propriétés et méthodes de filtrage réinsérées.${NC}"
echo -e "${GREEN}    ✓ Présence de ngOnInit assurée.${NC}"


echo -e "\n${GREEN}=== Réparation Terminée ===${NC}"
echo "Le fichier '$TS_FILE' a été modifié pour réinsérer les définitions manquantes."
echo "**ACTION REQUISE :** Vérifiez attentivement le fichier '$TS_FILE' pour vous assurer qu'il n'y a pas d'erreurs de syntaxe ou de duplications."
echo "Assurez-vous que le contenu de 'ngOnInit' est correct (le script a inséré un contenu par défaut s'il manquait)."
echo "Ensuite, arrêtez et relancez 'ng serve'."