import{a as de}from"./chunk-MNEFO67F.js";import"./chunk-37E4UQA3.js";import{b as W,c as E,d as Y,e as J,g as X,h as Z,i as ee,j as te,m as ie,n as re,o as ne,p as oe,r as le,s as se,t as ae}from"./chunk-JJK6J4PC.js";import"./chunk-ERIR3R6Y.js";import{A as L,Ia as s,Ib as o,Jb as q,Kb as _,O as N,Sa as V,Tb as A,Vb as O,Wa as B,Wb as z,Xb as j,_a as k,jb as h,k as P,ka as y,kb as i,la as v,lb as t,ma as F,mb as C,na as I,sc as G,tb as $,tc as H,ub as m,uc as R,wb as f,wc as Q,xc as K,yc as U,z as D}from"./chunk-JV3ZGQQZ.js";var he=(a,c,n)=>({"bg-red-100 text-red-800":a,"bg-yellow-100 text-yellow-800":c,"bg-green-100 text-green-800":n});function ge(a,c){if(a&1){let n=$();i(0,"div",31)(1,"strong"),o(2,"Erreur :"),t(),o(3),i(4,"button",32),m("click",function(){y(n);let r=f();return v(r.errorMessage="")}),o(5,"\xD7"),t()()}if(a&2){let n=f();s(3),_(" ",n.errorMessage," ")}}function xe(a,c){a&1&&(i(0,"span"),o(1,"+ Ajouter un Produit"),t())}function fe(a,c){a&1&&(i(0,"span"),o(1,"Fermer"),t())}function be(a,c){if(a&1){let n=$();i(0,"div",33)(1,"h2",34),o(2),t(),i(3,"form",35),m("ngSubmit",function(){y(n);let r=f();return v(r.onSubmit())}),i(4,"div",36)(5,"div")(6,"label",37),o(7,"Nom *"),t(),C(8,"input",38),t(),i(9,"div")(10,"label",37),o(11,"Prix (DT) *"),t(),C(12,"input",39),t(),i(13,"div")(14,"label",37),o(15,"Quantit\xE9 *"),t(),C(16,"input",40),t()(),i(17,"div")(18,"label",37),o(19,"Description"),t(),C(20,"textarea",41),t(),i(21,"div",42)(22,"button",43),o(23),t(),i(24,"button",44),m("click",function(){y(n);let r=f();return v(r.resetForm())}),o(25,"Annuler"),t()()()()}if(a&2){let n=f();s(2),_("",n.isEditing?"Modifier":"Nouveau"," Produit"),s(),h("formGroup",n.productForm),s(19),h("disabled",n.isLoading||n.productForm.invalid),s(),_(" ",n.isEditing?"Mettre \xE0 jour":"Ajouter"," ")}}function _e(a,c){if(a&1){let n=$();i(0,"tr",54)(1,"td",55),o(2),t(),i(3,"td",56),o(4),O(5,"number"),t(),i(6,"td",57)(7,"span",58),o(8),t()(),i(9,"td",56),o(10),t(),i(11,"td",59)(12,"button",60),m("click",function(){let r=y(n).$implicit,l=f(3);return v(l.editProduct(r))}),o(13,"Modifier"),t(),i(14,"button",61),m("click",function(){let r=y(n).$implicit,l=f(3);return v(l.deleteProduct(r.id,r.name))}),o(15,"Supprimer"),t(),i(16,"button",62),m("click",function(){let r=y(n).$implicit,l=f(3);return v(l.printItem(r))}),o(17,"Imprimer"),t()()()}if(a&2){let n=c.$implicit;s(2),q(n.name),s(2),_("",j(5,5,n.price,"1.2-2")," DT"),s(3),h("ngClass",A(8,he,(n.quantity||0)===0,(n.quantity||0)>0&&(n.quantity||0)<10,(n.quantity||0)>=10)),s(),_(" ",n.quantity||0," "),s(2),q(n.description||"N/A")}}function ye(a,c){a&1&&(i(0,"tr")(1,"td",63),o(2,"Aucun produit trouv\xE9."),t()())}function ve(a,c){if(a&1&&(i(0,"tbody",52),k(1,_e,18,12,"tr",53)(2,ye,3,0,"tr",10),t()),a&2){let n=c.ngIf;s(),h("ngForOf",n),s(),h("ngIf",n.length===0)}}function we(a,c){if(a&1){let n=$();i(0,"div",45)(1,"table",46)(2,"thead",47)(3,"tr")(4,"th",48),m("click",function(){y(n);let r=f();return v(r.onSortChange("name"))}),o(5),t(),i(6,"th",48),m("click",function(){y(n);let r=f();return v(r.onSortChange("price"))}),o(7),t(),i(8,"th",48),m("click",function(){y(n);let r=f();return v(r.onSortChange("quantity"))}),o(9),t(),i(10,"th",49),o(11,"Description"),t(),i(12,"th",50),o(13,"Actions"),t()()(),k(14,ve,3,2,"tbody",51),O(15,"async"),t()()}if(a&2){let n=f();s(5),_(" Nom ",n.sortBy==="name"?n.sortOrder==="asc"?"\u2191":"\u2193":""," "),s(2),_(" Prix ",n.sortBy==="price"?n.sortOrder==="asc"?"\u2191":"\u2193":""," "),s(2),_(" Quantit\xE9 ",n.sortBy==="quantity"?n.sortOrder==="asc"?"\u2191":"\u2193":""," "),s(5),h("ngIf",z(15,4,n.filteredProducts$))}}var Ie=(()=>{let c=class c{constructor(e,r){this.productsService=e,this.fb=r,this.isLoading=!1,this.isEditing=!1,this.editingId=null,this.errorMessage="",this.searchTerm="",this.searchTerm$=new P(""),this.minPrice=null,this.minPrice$=new P(null),this.maxPrice=null,this.maxPrice$=new P(null),this.stockFilter="all",this.stockFilter$=new P("all"),this.sortBy="name",this.sortBy$=new P("name"),this.sortOrder="asc",this.sortOrder$=new P("asc"),this.showForm=!1,this.productForm=this.fb.group({name:["",E.required],price:[0,[E.required,E.min(0)]],quantity:[0,[E.required,E.min(0)]],description:[""]})}ngOnInit(){this.loadProducts(),this.filteredProducts$=L([this.products$,this.searchTerm$,this.minPrice$,this.maxPrice$,this.stockFilter$,this.sortBy$,this.sortOrder$]).pipe(D(([e,r,l,x,g,S,M])=>{let u=e;return r&&(u=u.filter(p=>p.name.toLowerCase().includes(r.toLowerCase()))),l!==null&&(u=u.filter(p=>(p.price||0)>=l)),x!==null&&(u=u.filter(p=>(p.price||0)<=x)),g==="rupture"?u=u.filter(p=>(p.quantity||0)===0):g==="low"?u=u.filter(p=>(p.quantity||0)>0&&(p.quantity||0)<10):g==="ok"&&(u=u.filter(p=>(p.quantity||0)>=10)),u=u.sort((p,T)=>{let b=0;return S==="name"?b=p.name.localeCompare(T.name):S==="price"?b=(p.price||0)-(T.price||0):S==="quantity"&&(b=(p.quantity||0)-(T.quantity||0)),M==="asc"?b:-b}),u}))}loadProducts(){this.products$=this.productsService.getProducts()}onSearchChange(e){this.searchTerm=e,this.searchTerm$.next(e)}onMinPriceChange(e){this.minPrice=e,this.minPrice$.next(e)}onMaxPriceChange(e){this.maxPrice=e,this.maxPrice$.next(e)}onStockFilterChange(e){this.stockFilter=e,this.stockFilter$.next(e)}onSortChange(e){this.sortBy===e?this.sortOrder=this.sortOrder==="asc"?"desc":"asc":(this.sortBy=e,this.sortOrder="asc"),this.sortBy$.next(this.sortBy),this.sortOrder$.next(this.sortOrder)}clearFilters(){this.searchTerm="",this.searchTerm$.next(""),this.minPrice=null,this.minPrice$.next(null),this.maxPrice=null,this.maxPrice$.next(null),this.stockFilter="all",this.stockFilter$.next("all"),this.sortBy="name",this.sortBy$.next("name"),this.sortOrder="asc",this.sortOrder$.next("asc")}onSubmit(){if(this.productForm.invalid){this.errorMessage="Veuillez remplir tous les champs obligatoires.";return}this.isLoading=!0,this.errorMessage="";let e=this.productForm.value;this.isEditing&&this.editingId?this.productsService.updateProduct(this.editingId,e).then(()=>{this.resetForm(),this.loadProducts()}).catch(r=>{this.errorMessage="Erreur lors de la modification.",console.error(r)}).finally(()=>this.isLoading=!1):this.productsService.addProduct(e).then(()=>{this.resetForm(),this.loadProducts()}).catch(r=>{this.errorMessage="Erreur lors de l'ajout.",console.error(r)}).finally(()=>this.isLoading=!1)}editProduct(e){this.isEditing=!0,this.editingId=e.id||null,this.productForm.patchValue(e),this.showForm=!0,window.scrollTo({top:0,behavior:"smooth"})}deleteProduct(e,r){confirm(`Supprimer le produit "${r}" ?`)&&(this.isLoading=!0,this.productsService.deleteProduct(e).then(()=>{this.loadProducts()}).catch(l=>{this.errorMessage="Erreur lors de la suppression.",console.error(l)}).finally(()=>this.isLoading=!1))}resetForm(){this.productForm.reset({price:0,quantity:0}),this.isEditing=!1,this.editingId=null,this.errorMessage="",this.showForm=!1}toggleForm(){this.showForm=!this.showForm,this.showForm||this.resetForm()}printList(){console.log("\u{1F5A8}\uFE0F printList() appel\xE9e"),this.filteredProducts$.pipe(N(1)).subscribe(e=>{if(console.log(`\u{1F4E6} ${e.length} produits filtr\xE9s \xE0 imprimer`),e.length===0){alert("Aucun produit \xE0 imprimer (liste vide apr\xE8s filtres).");return}this.generatePrintHTML(e)})}generatePrintHTML(e){console.log("\u{1F4C4} G\xE9n\xE9ration HTML impression...");let r=window.open("","_blank","width=900,height=700");if(!r){alert("\u274C Popup bloqu\xE9e ! Autorisez les popups pour ce site.");return}let l=new Date().toLocaleDateString("fr-FR",{year:"numeric",month:"long",day:"numeric",hour:"2-digit",minute:"2-digit"}),x=e.length,g=e.reduce((d,w)=>d+(w.price||0)*(w.quantity||0),0),S=e.reduce((d,w)=>d+(w.quantity||0),0),M=x>0?e.reduce((d,w)=>d+(w.price||0),0)/x:0,u=e.filter(d=>(d.quantity||0)===0).length,p=e.filter(d=>(d.quantity||0)>0&&(d.quantity||0)<10).length,T=e.filter(d=>(d.quantity||0)>=10).length,b=[];if(this.searchTerm&&b.push(`Recherche: "${this.searchTerm}"`),this.minPrice!==null&&b.push(`Prix Min: ${this.minPrice} DT`),this.maxPrice!==null&&b.push(`Prix Max: ${this.maxPrice} DT`),this.stockFilter!=="all"){let d={rupture:"En Rupture (0)",low:"Stock Bas (< 10)",ok:"Stock OK (\u2265 10)"};b.push(`Stock: ${d[this.stockFilter]}`)}let ce={name:"Nom",price:"Prix",quantity:"Quantit\xE9"};b.push(`Tri: ${ce[this.sortBy]} (${this.sortOrder==="asc"?"\u2191":"\u2193"})`);let pe=e.map((d,w)=>{let ue=(d.quantity||0)===0?"red":(d.quantity||0)<10?"yellow":"green";return`
        <tr>
          <td>${w+1}</td>
          <td>${d.name||"N/A"}</td>
          <td>${(d.price||0).toFixed(2)} DT</td>
          <td><span class="badge badge-${ue}">${d.quantity||0}</span></td>
          <td>${((d.price||0)*(d.quantity||0)).toFixed(2)} DT</td>
          <td>${d.description||"-"}</td>
        </tr>
      `}).join(""),me=`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Liste Produits - ${l}</title>
        <style>
          @page { margin: 15mm; size: A4 portrait; }
          body { font-family: Arial, sans-serif; margin: 0; padding: 15px; font-size: 10pt; }
          .header { text-align: center; margin-bottom: 15px; border-bottom: 2px solid #2563eb; padding-bottom: 10px; }
          .header h1 { font-size: 20pt; color: #2563eb; margin: 0 0 5px 0; }
          .header p { font-size: 9pt; color: #666; margin: 0; }
          .filters { background: #f3f4f6; padding: 8px; margin-bottom: 12px; border-left: 3px solid #2563eb; }
          .filters h3 { font-size: 11pt; margin: 0 0 5px 0; }
          .filters ul { list-style: none; padding: 0; margin: 0; }
          .filters li { font-size: 9pt; margin: 2px 0; }
          .stats { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; margin-bottom: 15px; }
          .stat { background: #f9fafb; border: 1px solid #e5e7eb; padding: 8px; text-align: center; }
          .stat .label { font-size: 8pt; color: #666; }
          .stat .value { font-size: 14pt; font-weight: bold; color: #2563eb; }
          table { width: 100%; border-collapse: collapse; }
          thead { background: #2563eb; color: white; }
          th, td { padding: 6px 8px; text-align: left; border: 1px solid #ddd; font-size: 9pt; }
          tbody tr:nth-child(even) { background: #f9fafb; }
          tfoot { background: #f3f4f6; font-weight: bold; }
          .badge { padding: 2px 6px; border-radius: 3px; font-size: 8pt; font-weight: bold; }
          .badge-red { background: #fee2e2; color: #991b1b; }
          .badge-yellow { background: #fef3c7; color: #92400e; }
          .badge-green { background: #d1fae5; color: #065f46; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>\u{1F4E6} Gestion de Stock - Liste Produits</h1>
          <p>Date d'impression : ${l}</p>
        </div>
        <div class="filters">
          <h3>Filtres Appliqu\xE9s</h3>
          <ul>${b.map(d=>`<li>\u2022 ${d}</li>`).join("")}</ul>
        </div>
        <div class="stats">
          <div class="stat"><div class="label">Total Produits</div><div class="value">${x}</div></div>
          <div class="stat"><div class="label">Valeur Stock</div><div class="value">${g.toFixed(2)} DT</div></div>
          <div class="stat"><div class="label">Quantit\xE9 Totale</div><div class="value">${S}</div></div>
          <div class="stat"><div class="label">Prix Moyen</div><div class="value">${M.toFixed(2)} DT</div></div>
        </div>
        <table>
          <thead>
            <tr>
              <th style="width: 5%">#</th>
              <th style="width: 25%">Nom</th>
              <th style="width: 12%">Prix Unit.</th>
              <th style="width: 10%">Stock</th>
              <th style="width: 13%">Valeur</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>${pe}</tbody>
          <tfoot>
            <tr>
              <td colspan="2">TOTAL (${x} produits)</td>
              <td>-</td>
              <td>${S}</td>
              <td>${g.toFixed(2)} DT</td>
              <td>Rupture: ${u} | Bas: ${p} | OK: ${T}</td>
            </tr>
          </tfoot>
        </table>
      </body>
      </html>
    `;r.document.write(me),r.document.close(),r.focus(),setTimeout(()=>{r.print()},500),console.log("\u2705 HTML \xE9crit dans popup, impression lanc\xE9e")}printItem(e){let r=window.open("","_blank","width=800,height=600");if(!r)return;let l=`
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>Fiche Produit</title>
        <style>
          body { font-family: Arial, sans-serif; padding: 20px; }
          h1 { text-align: center; border-bottom: 2px solid #000; }
          table { width: 100%; border-collapse: collapse; margin: 15px 0; }
          th, td { padding: 8px; border: 1px solid #ddd; }
          th { background: #f3f4f6; }
        </style>
      </head>
      <body>
        <h1>Fiche Produit</h1>
        <table>
          <tr><th>Nom</th><td>${e.name||"N/A"}</td></tr>
          <tr><th>Prix</th><td>${e.price||0} DT</td></tr>
          <tr><th>Quantit\xE9</th><td>${e.quantity||0}</td></tr>
          <tr><th>Description</th><td>${e.description||"N/A"}</td></tr>
        </table>
      </body>
      </html>
    `;r.document.write(l),r.document.close(),setTimeout(()=>{r.print(),r.close()},250)}};c.\u0275fac=function(r){return new(r||c)(V(de),V(le))},c.\u0275cmp=B({type:c,selectors:[["app-products"]],decls:56,vars:13,consts:[[1,"container","mx-auto","px-4","py-8"],[1,"text-3xl","font-bold","text-gray-800","mb-6"],["class","bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4",4,"ngIf"],[1,"flex","flex-col","md:flex-row","justify-between","items-center","mb-4","gap-4"],["type","text","placeholder","\u{1F50D} Rechercher par nom...",1,"w-full","md:w-1/3","px-4","py-2","border","rounded-lg",3,"ngModelChange","ngModel"],[1,"flex","gap-2"],[1,"bg-purple-600","hover:bg-purple-700","text-white","font-bold","py-2","px-6","rounded-lg","flex","items-center","space-x-2","no-print",3,"click"],["fill","none","stroke","currentColor","viewBox","0 0 24 24",1,"w-5","h-5"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"],[1,"bg-green-600","hover:bg-green-700","text-white","font-bold","py-2","px-6","rounded-lg","no-print",3,"click"],[4,"ngIf"],[1,"bg-white","shadow-md","rounded-lg","p-4","mb-6","no-print"],[1,"text-lg","font-semibold","mb-3","flex","items-center"],["fill","none","stroke","currentColor","viewBox","0 0 24 24",1,"w-5","h-5","mr-2"],["stroke-linecap","round","stroke-linejoin","round","stroke-width","2","d","M3 4a1 1 0 011-1h16a1 1 0 011 1v2.586a1 1 0 01-.293.707l-6.414 6.414a1 1 0 00-.293.707V17l-4 4v-6.586a1 1 0 00-.293-.707L3.293 7.293A1 1 0 013 6.586V4z"],[1,"grid","grid-cols-1","md:grid-cols-4","gap-4"],[1,"block","text-sm","font-medium","text-gray-700","mb-1"],["type","number","placeholder","0",1,"w-full","px-3","py-2","border","rounded-lg",3,"ngModelChange","ngModel"],["type","number","placeholder","1000",1,"w-full","px-3","py-2","border","rounded-lg",3,"ngModelChange","ngModel"],[1,"w-full","px-3","py-2","border","rounded-lg",3,"ngModelChange","ngModel"],["value","all"],["value","rupture"],["value","low"],["value","ok"],["value","name"],["value","price"],["value","quantity"],[1,"mt-4"],[1,"bg-gray-500","hover:bg-gray-600","text-white","px-4","py-2","rounded-lg",3,"click"],["class","bg-white shadow-md rounded-lg p-6 mb-6 no-print",4,"ngIf"],["class","bg-white shadow-md rounded-lg overflow-hidden",4,"ngIf"],[1,"bg-red-100","border","border-red-400","text-red-700","px-4","py-3","rounded","mb-4"],[1,"float-right",3,"click"],[1,"bg-white","shadow-md","rounded-lg","p-6","mb-6","no-print"],[1,"text-2xl","font-semibold","mb-4"],[1,"space-y-4",3,"ngSubmit","formGroup"],[1,"grid","grid-cols-1","md:grid-cols-3","gap-4"],[1,"block","text-gray-700","font-medium","mb-2"],["formControlName","name","type","text",1,"w-full","px-4","py-2","border","rounded-lg"],["formControlName","price","type","number","step","0.01",1,"w-full","px-4","py-2","border","rounded-lg"],["formControlName","quantity","type","number",1,"w-full","px-4","py-2","border","rounded-lg"],["formControlName","description","rows","2",1,"w-full","px-4","py-2","border","rounded-lg"],[1,"flex","gap-4"],["type","submit",1,"bg-blue-600","hover:bg-blue-700","text-white","font-bold","py-2","px-6","rounded-lg","disabled:bg-gray-400",3,"disabled"],["type","button",1,"bg-gray-500","hover:bg-gray-600","text-white","font-bold","py-2","px-6","rounded-lg",3,"click"],[1,"bg-white","shadow-md","rounded-lg","overflow-hidden"],[1,"min-w-full","divide-y","divide-gray-200"],[1,"bg-gray-50"],[1,"px-6","py-3","text-left","text-xs","font-medium","text-gray-500","uppercase","cursor-pointer","hover:bg-gray-100",3,"click"],[1,"px-6","py-3","text-left","text-xs","font-medium","text-gray-500","uppercase"],[1,"px-6","py-3","text-right","text-xs","font-medium","text-gray-500","uppercase","no-print"],["class","bg-white divide-y divide-gray-200",4,"ngIf"],[1,"bg-white","divide-y","divide-gray-200"],["class","hover:bg-gray-50",4,"ngFor","ngForOf"],[1,"hover:bg-gray-50"],[1,"px-6","py-4","text-sm","font-medium","text-gray-900"],[1,"px-6","py-4","text-sm","text-gray-500"],[1,"px-6","py-4","text-sm"],[1,"px-2","py-1","rounded",3,"ngClass"],[1,"px-6","py-4","text-right","text-sm","font-medium","no-print"],[1,"text-indigo-600","hover:text-indigo-900","mr-4",3,"click"],[1,"text-red-600","hover:text-red-900","mr-4",3,"click"],[1,"text-purple-600","hover:text-purple-900",3,"click"],["colspan","5",1,"px-6","py-8","text-center","text-gray-500"]],template:function(r,l){r&1&&(i(0,"div",0)(1,"h1",1),o(2,"Gestion des Produits"),t(),k(3,ge,6,1,"div",2),i(4,"div",3)(5,"input",4),m("ngModelChange",function(g){return l.onSearchChange(g)}),t(),i(6,"div",5)(7,"button",6),m("click",function(){return l.printList()}),F(),i(8,"svg",7),C(9,"path",8),t(),I(),i(10,"span"),o(11,"Imprimer Liste"),t()(),i(12,"button",9),m("click",function(){return l.toggleForm()}),k(13,xe,2,0,"span",10)(14,fe,2,0,"span",10),t()()(),i(15,"div",11)(16,"h3",12),F(),i(17,"svg",13),C(18,"path",14),t(),o(19," Filtres Avanc\xE9s "),t(),I(),i(20,"div",15)(21,"div")(22,"label",16),o(23,"Prix Min (DT)"),t(),i(24,"input",17),m("ngModelChange",function(g){return l.onMinPriceChange(g)}),t()(),i(25,"div")(26,"label",16),o(27,"Prix Max (DT)"),t(),i(28,"input",18),m("ngModelChange",function(g){return l.onMaxPriceChange(g)}),t()(),i(29,"div")(30,"label",16),o(31,"\xC9tat Stock"),t(),i(32,"select",19),m("ngModelChange",function(g){return l.onStockFilterChange(g)}),i(33,"option",20),o(34,"Tous"),t(),i(35,"option",21),o(36,"En Rupture (0)"),t(),i(37,"option",22),o(38,"Stock Bas (< 10)"),t(),i(39,"option",23),o(40,"Stock OK (\u2265 10)"),t()()(),i(41,"div")(42,"label",16),o(43,"Trier par"),t(),i(44,"select",19),m("ngModelChange",function(g){return l.onSortChange(g)}),i(45,"option",24),o(46),t(),i(47,"option",25),o(48),t(),i(49,"option",26),o(50),t()()()(),i(51,"div",27)(52,"button",28),m("click",function(){return l.clearFilters()}),o(53," R\xE9initialiser Filtres "),t()()(),k(54,be,26,4,"div",29)(55,we,16,6,"div",30),t()),r&2&&(s(3),h("ngIf",l.errorMessage),s(2),h("ngModel",l.searchTerm),s(8),h("ngIf",!l.showForm),s(),h("ngIf",l.showForm),s(10),h("ngModel",l.minPrice),s(4),h("ngModel",l.maxPrice),s(4),h("ngModel",l.stockFilter),s(12),h("ngModel",l.sortBy),s(2),_("Nom ",l.sortBy==="name"?l.sortOrder==="asc"?"\u2191":"\u2193":""),s(2),_("Prix ",l.sortBy==="price"?l.sortOrder==="asc"?"\u2191":"\u2193":""),s(2),_("Quantit\xE9 ",l.sortBy==="quantity"?l.sortOrder==="asc"?"\u2191":"\u2193":""),s(4),h("ngIf",l.showForm),s(),h("ngIf",!l.isLoading))},dependencies:[ae,Z,ne,oe,W,ee,re,Y,J,te,ie,U,G,H,R,se,X,Q,K],styles:[".container[_ngcontent-%COMP%]{max-width:1200px}button[_ngcontent-%COMP%]{transition:all .2s ease-in-out}@media (max-width: 768px){table[_ngcontent-%COMP%]{display:block;overflow-x:auto;white-space:nowrap}}.animate-spin[_ngcontent-%COMP%]{animation:_ngcontent-%COMP%_spin 1s linear infinite}@keyframes _ngcontent-%COMP%_spin{0%{transform:rotate(0)}to{transform:rotate(360deg)}}"]});let a=c;return a})();export{Ie as ProductsComponent};
