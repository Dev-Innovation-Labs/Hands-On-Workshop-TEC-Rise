# 📒 Hari 2: SAP Fiori & SAPUI5 — Build UI dari CAP Service

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 1 (CAP project bookshop berjalan di localhost:4004)  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 2, peserta mampu:
- Memahami SAP Fiori Design Principles dan 5 Fiori Principles
- Membedakan Fiori Elements vs Custom SAPUI5 (Freestyle)
- Membuat Fiori Elements List Report & Object Page dari CAP OData service
- Menggunakan Fiori Annotations (UI, Common) untuk mengkonfigurasi tampilan
- Menggunakan SAP Fiori tools dan Yeoman generator (`yo @sap/fiori`)
- Menjalankan Fiori app secara lokal di atas CAP server (`cds watch`)

---

## 📅 Jadwal Hari 2

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 1 | 15 menit |
| 09:15 – 10:30 | **Teori: Fiori Design & Arsitektur** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: Generate Fiori App dengan Yeoman** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Fiori Annotations & Customization** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: Fiori Launchpad & Custom Views** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: SAP Fiori Design

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

Banyak istilah baru di Hari 2. Mari kita pahami dulu sebelum mulai coding:

> **🏠 SAP Fiori = Desain Interior Standar IKEA**
>
> Bayangkan Anda membangun rumah (aplikasi). Anda bisa:
> - **Beli furniture IKEA** (Fiori Elements) — tinggal rakit pakai instruksi, hasilnya rapi dan standar
> - **Buat furniture custom** (Freestyle SAPUI5) — desain sendiri, lebih fleksibel tapi butuh lebih banyak kerja
>
> | Istilah | Analogi | Penjelasan |
> |:--------|:--------|:-----------|
> | **SAP Fiori** | Standar desain IKEA | Panduan desain UI agar semua app SAP konsisten |
> | **Fiori Elements** | Furniture IKEA (pre-built) | Template UI auto-generated dari annotations — minim coding |
> | **Freestyle SAPUI5** | Furniture custom | UI ditulis manual dengan XML + JavaScript — full kontrol |
> | **List Report** | Halaman katalog toko | Halaman tabel dengan filter & search — untuk browsing data |
> | **Object Page** | Halaman detail produk | Halaman detail satu item — header, tabs, sections |
> | **Annotations** | Label & instruksi di furniture | Metadata CDS yang mengontrol tampilan UI (kolom, filter, header) |
> | **manifest.json** | Buku manual app | File config utama: data source, routing, model |
> | **MVC** | Restoran | **Model**=Dapur (data), **View**=Menu (tampilan), **Controller**=Pelayan (logic) |
> | **Yeoman Generator** | Mesin cetak furniture | Tool CLI yang generate scaffolding Fiori app otomatis |
> | **OData Binding** | Pipa air ke dapur | Koneksi otomatis antara UI dan data backend |
>
> **Alur Fiori Elements:**
> ```
> CDS Model (Hari 1)
>   → + Annotations (@UI.LineItem, @UI.HeaderInfo)
>     → Fiori Elements Runtime membaca annotations
>       → UI ter-generate otomatis! 🎨
>
> Anda TIDAK menulis HTML/XML untuk tabel, filter, form.
> Cukup tulis annotations di CDS — UI langsung jadi.
> ```

### SAP Fiori 5 Principles

```
1. ROLE-BASED     → Konten disesuaikan dengan peran pengguna
2. DELIGHTFUL     → UX yang menyenangkan & intuitif
3. COHERENT       → Konsisten di seluruh aplikasi SAP
4. SIMPLE         → Satu tugas utama per aplikasi
5. ADAPTIVE       → Responsive di semua device
```

### Jenis-jenis SAP Fiori App

```
SAP Fiori App Types:
│
├── Fiori Elements (Declarative)
│   ├── List Report / Object Page     ← Workshop ini!
│   ├── Worklist Page
│   ├── Analytical List Page (ALP)
│   ├── Overview Page (OVP)
│   └── Form Entry Object Page
│
└── Custom SAPUI5 (Freestyle)
    ├── MVC Pattern (Model-View-Controller)
    ├── Full control atas UI
    └── Lebih banyak coding
```

### Fiori Elements Architecture

```
OData Service + Annotations
        ↓
Fiori Elements Runtime
        ↓
Generated UI (auto-generated berdasarkan annotasi)

Keuntungan:
✅ Sedikit / tanpa JavaScript manual
✅ SAP best practices by default
✅ Update otomatis saat framework diupdate
✅ Konsisten dengan SAP design guidelines
```

### SAPUI5 MVC Architecture

```
View (.xml)          ← Template UI
    ↕ binding
Model (OData/JSON)   ← Data layer
    ↕ events
Controller (.js)     ← Business logic
```

---

## 🛠️ Hands-on 1: Generate Fiori App dengan SAP Fiori Tools

### Langkah 1: Install Fiori Generator

```bash
# Di terminal (tools sudah terinstall dari setup workshop)
yo --version           # 7.0.0
cds --version          # @sap/cds-dk 9.8.3
node --version         # v24.11.0
```

### Langkah 2: Generate App via Yeoman

```bash
# Di dalam folder project CAP
cd ~/projects/bookshop

# Jalankan generator
yo @sap/fiori:elements-app

# Pilihan yang dimasukkan:
# ? Choose a template: List Report Page
# ? Select OData Service Source: Local CAP Node.js Project
# ? OData service: CatalogService
# ? Main entity: Books
# ? Navigation entity: None
# ? App name (module): books
# ? App namespace: com.tecrise
# ? Add app to project: Yes
```

### Struktur yang Dihasilkan

```
app/
└── books/
    ├── webapp/
    │   ├── manifest.json          ← App descriptor
    │   ├── Component.js           ← App component
    │   ├── index.html             ← Entry point
    │   └── i18n/
    │       └── i18n.properties    ← Translations
    ├── package.json
    └── ui5.yaml                   ← UI5 tooling config
```

### Langkah 3: Jalankan Fiori App

```bash
# Jalankan CAP backend + Fiori preview
cds watch

# Atau jalankan Fiori App saja (dari folder app/books):
cd app/books
npm start
```

**✅ Hasil yang Diharapkan:**

```
[cds] - serving CatalogService { at: ['/odata/v4/catalog'] }
[cds] - server listening on { url: 'http://localhost:4004' }
```

Buka browser:  
- `http://localhost:4004` — CAP Welcome Page, klik link **"books"** untuk buka Fiori app
- Anda akan melihat **List Report** dengan tabel Books (kolom Title, Author, Price, Stock)
- Klik salah satu baris → **Object Page** terbuka dengan detail buku

> **💡 Analogi:** Bayangkan Anda baru saja **merakit furniture IKEA**.
> Tanpa menulis HTML/CSS apapun, Anda sudah punya halaman tabel dan halaman detail
> yang tampilannya profesional — karena Fiori Elements yang generate-nya otomatis.

---

## 🛠️ Hands-on 2: Konfigurasi `manifest.json`

> **💡 Analogi:** `manifest.json` adalah **buku manual** aplikasi Fiori Anda.
> Di dalamnya tertulis: "data diambil dari mana" (dataSources), "halaman apa saja" (routes),
> dan "bagaimana navigasinya" (targets). Tanpa file ini, app tidak tahu harus ngapain.

### File: `app/books/webapp/manifest.json`

```json
{
    "_version": "1.49.0",
    "sap.app": {
        "id": "com.tecrise.books",
        "type": "application",
        "title": "{{appTitle}}",
        "description": "{{appDescription}}",
        "applicationVersion": { "version": "1.0.0" },
        "dataSources": {
            "mainService": {
                "uri": "/catalog/",
                "type": "OData",
                "settings": {
                    "annotations": ["annotation"],
                    "odataVersion": "4.0"
                }
            },
            "annotation": {
                "type": "ODataAnnotation",
                "uri": "/catalog/$metadata"
            }
        }
    },
    "sap.fiori": {
        "registrationIds": ["F1234"],
        "archeType": "transactional"
    },
    "sap.ui5": {
        "resources": {
            "js": [],
            "css": [{ "uri": "css/style.css" }]
        },
        "routing": {
            "routes": [{
                "name": "BooksList",
                "pattern": "",
                "target": "BooksList"
            },{
                "name": "BooksObjectPage",
                "pattern": "Books({key})",
                "target": "BooksObjectPage"
            }],
            "targets": {
                "BooksList": {
                    "type": "Component",
                    "id": "BooksList",
                    "name": "sap.fe.templates.ListReport",
                    "options": {
                        "settings": {
                            "entitySet": "Books",
                            "navigation": {
                                "Books": { "detail": { "route": "BooksObjectPage" } }
                            }
                        }
                    }
                },
                "BooksObjectPage": {
                    "type": "Component",
                    "id": "BooksObjectPage",
                    "name": "sap.fe.templates.ObjectPage",
                    "options": {
                        "settings": {
                            "entitySet": "Books"
                        }
                    }
                }
            }
        },
        "models": {
            "": {
                "dataSource": "mainService",
                "settings": { "synchronizationMode": "None" }
            },
            "i18n": {
                "type": "sap.ui.model.resource.ResourceModel",
                "settings": { "bundleName": "com.tecrise.books.i18n.i18n" }
            }
        }
    }
}
```

---

## 🛠️ Hands-on 3: Fiori Annotations

> **💡 Analogi:** Annotations itu seperti **label dan instruksi** di furniture IKEA.
>
> - `@UI.LineItem` = "Tampilkan kolom-kolom ini di halaman tabel"
> - `@UI.HeaderInfo` = "Di halaman detail, tampilkan judul dan deskripsi ini"
> - `@UI.Facets` = "Buat tab/section ini di halaman detail"
> - `@Common.ValueList` = "Tampilkan dropdown pilihan dari data ini"
>
> Anda **tidak menulis HTML** — cukup tulis annotations di file `.cds`,
> dan Fiori Elements otomatis generate UI-nya.

### File: `app/books/annotations.cds`

```cds
using CatalogService as service from '../../srv/catalog-service';

// ============================================
// LIST REPORT PAGE
// ============================================
annotate service.Books with @(
    UI.LineItem: [
        {
            $Type : 'UI.DataField',
            Value : title,
            Label : 'Book Title'
        },
        {
            $Type : 'UI.DataField',
            Value : authorName,
            Label : 'Author'
        },
        {
            $Type : 'UI.DataField',
            Value : price,
            Label : 'Price'
        },
        {
            $Type : 'UI.DataField',
            Value : stock,
            Label : 'Stock',
            Criticality: stockCriticality    // Colorize berdasarkan nilai
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'CatalogService.submitOrder',
            Label : 'Order'
        }
    ]
);

// ============================================
// SELECTION FILTERS (Filter Bar)
// ============================================
annotate service.Books with @(
    UI.SelectionFields: [
        price,
        author_ID,
        genre_ID
    ]
);

// ============================================
// OBJECT PAGE — Header
// ============================================
annotate service.Books with @(
    UI.HeaderInfo: {
        TypeName       : 'Book',
        TypeNamePlural : 'Books',
        Title          : { $Type: 'UI.DataField', Value: title },
        Description    : { $Type: 'UI.DataField', Value: authorName },
        ImageUrl       : '/BookImages/{ID}'
    },

    // KPIs di header
    UI.HeaderFacets: [{
        $Type  : 'UI.ReferenceFacet',
        Target : '@UI.FieldGroup#KPIs'
    }],

    UI.FieldGroup #KPIs: {
        Data: [
            { Value: price,  Label: 'Price'  },
            { Value: stock,  Label: 'Stock'  }
        ]
    }
);

// ============================================
// OBJECT PAGE — Sections (Facets)
// ============================================
annotate service.Books with @(
    UI.Facets: [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'GeneralInfo',
            Label  : 'General Information',
            Target : '@UI.FieldGroup#GeneralInfo'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'Description',
            Label  : 'Description',
            Target : '@UI.FieldGroup#Description'
        }
    ],

    UI.FieldGroup #GeneralInfo: {
        Label : 'General Information',
        Data  : [
            { Value: title,        Label: 'Title'    },
            { Value: authorName,   Label: 'Author'   },
            { Value: price,        Label: 'Price'    },
            { Value: stock,        Label: 'Stock'    },
            { Value: currency_code,Label: 'Currency' }
        ]
    },

    UI.FieldGroup #Description: {
        Label : 'Description',
        Data  : [
            { Value: descr }
        ]
    }
);

// ============================================
// FIELD-LEVEL LABELS (via Common.Label)
// ============================================
annotate service.Books with {
    title        @Common.Label: 'Book Title';
    authorName   @Common.Label: 'Author';
    price        @Common.Label: 'Price'      @Measures.ISOCurrency: currency_code;
    stock        @Common.Label: 'Stock';
}

// ============================================
// VALUE HELP (Dropdown)
// ============================================
annotate service.Books with {
    author @Common.ValueList: {
        CollectionPath : 'Authors',
        Parameters     : [
            {
                $Type            : 'Common.ValueListParameterOut',
                LocalDataProperty: author_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            }
        ]
    };
}
```

---

## 🛠️ Hands-on 4: Custom SAPUI5 View

> **💡 Kapan pakai Freestyle vs Fiori Elements?**
>
> | Fiori Elements | Freestyle SAPUI5 |
> |:---------------|:------------------|
> | Butuh standar SAP (list, detail, form) | Butuh UI kustom yang unik |
> | Minim coding, cepat development | Full kontrol, tapi butuh lebih banyak kode |
> | Otomatis mengikuti SAP design guidelines | Desain bebas, harus maintain sendiri |
>
> Pada hands-on ini kita coba pendekatan **Freestyle** untuk memahami perbedaannya.

### File: `app/custom-books/webapp/view/BooksList.view.xml`

```xml
<mvc:View
    controllerName="com.tecrise.books.controller.BooksList"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    displayBlock="true">

    <Page title="Books Catalog" showNavButton="false">
        <!-- Search Bar -->
        <subHeader>
            <Bar>
                <contentLeft>
                    <SearchField
                        width="300px"
                        search=".onSearch"
                        placeholder="Search books..."/>
                </contentLeft>
            </Bar>
        </subHeader>

        <!-- Table Content -->
        <content>
            <Table
                id="booksTable"
                items="{/Books}"
                growing="true"
                growingThreshold="10"
                mode="SingleSelectMaster"
                selectionChange=".onBookSelect">

                <headerToolbar>
                    <Toolbar>
                        <Title text="Books ({= ${/Books/$count} })"/>
                        <ToolbarSpacer/>
                        <Button text="Add Book" press=".onAdd" type="Emphasized"/>
                    </Toolbar>
                </headerToolbar>

                <columns>
                    <Column><Text text="Title"/></Column>
                    <Column><Text text="Author"/></Column>
                    <Column hAlign="End"><Text text="Price"/></Column>
                    <Column hAlign="End"><Text text="Stock"/></Column>
                    <Column><Text text="Actions"/></Column>
                </columns>

                <items>
                    <ColumnListItem>
                        <Text text="{title}"/>
                        <Text text="{authorName}"/>
                        <ObjectNumber
                            number="{price}"
                            unit="{currency_code}"/>
                        <ObjectStatus
                            text="{stock}"
                            state="{= ${stock} > 10 ? 'Success' : ${stock} > 0 ? 'Warning' : 'Error' }"/>
                        <Button text="Order" press=".onOrder" type="Accept"/>
                    </ColumnListItem>
                </items>
            </Table>
        </content>
    </Page>
</mvc:View>
```

### File: `app/custom-books/webapp/controller/BooksList.controller.js`

```javascript
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/odata/v4/ODataModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function(Controller, ODataModel, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("com.tecrise.books.controller.BooksList", {

        onInit: function() {
            // Model sudah di-set di manifest.json
            const oModel = this.getOwnerComponent().getModel();
            this.oModel = oModel;
        },

        onSearch: function(oEvent) {
            const sQuery = oEvent.getParameter("query");
            const oBinding = this.byId("booksTable").getBinding("items");
            
            if (sQuery) {
                oBinding.filter([
                    new sap.ui.model.Filter("title", "Contains", sQuery)
                ]);
            } else {
                oBinding.filter([]);
            }
        },

        onBookSelect: function(oEvent) {
            const oItem = oEvent.getParameter("listItem");
            const sPath = oItem.getBindingContext().getPath();
            const oBook = this.oModel.getObject(sPath);
            
            // Navigate to Object Page
            this.getOwnerComponent().getRouter().navTo("BooksObjectPage", {
                key: `ID='${oBook.ID}'`
            });
        },

        onAdd: function() {
            // Navigate ke create page
            this.getOwnerComponent().getRouter().navTo("BooksCreate");
        },

        onOrder: function(oEvent) {
            const oContext = oEvent.getSource().getBindingContext();
            const oBook = oContext.getObject();
            
            MessageBox.confirm(`Order 1 copy of "${oBook.title}"?`, {
                onClose: async (sAction) => {
                    if (sAction === "OK") {
                        try {
                            await this.oModel.bindContext("/submitOrder(...)").invoke({
                                bookID: oBook.ID,
                                amount: 1
                            });
                            MessageToast.show("Order submitted successfully!");
                        } catch (err) {
                            MessageBox.error(err.message);
                        }
                    }
                }
            });
        }
    });
});
```

---

## 🛠️ Hands-on 5: Fiori Launchpad Configuration

### File: `app/fiori.html` (Local FLP Sandbox)

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TEC Rise Bookshop — Fiori Launchpad</title>
    <script>
        window["sap-ushell-config"] = {
            defaultRenderer: "fiori2",
            applications: {
                "books-display": {
                    title: "Books Catalog",
                    description: "Browse and manage books",
                    additionalInformation: "SAPUI5.Component=com.tecrise.books",
                    applicationType: "URL",
                    url: "/books/webapp",
                    navigationMode: "embedded"
                }
            }
        };
    </script>
    <script id="sap-ushell-bootstrap"
        src="https://ui5.sap.com/test-resources/sap/ushell/bootstrap/sandbox.js">
    </script>
    <script
        src="https://ui5.sap.com/resources/sap-ui-core.js"
        data-sap-ui-libs="sap.m, sap.ushell, sap.fe.templates"
        data-sap-ui-theme="sap_horizon"
        data-sap-ui-compatVersion="edge"
        data-sap-ui-frameOptions="allow">
    </script>
    <script>
        sap.ui.getCore().attachInit(function() {
            sap.ushell.Container.createRenderer().placeAt("content");
        });
    </script>
</head>
<body class="sapUiBody" id="content"></body>
</html>
```

---

## 📝 Latihan Mandiri Hari 2

### Exercise 2.1: Tambah Column di List Report
Tambahkan kolom `genre` dan `currency_code` di `UI.LineItem` annotation.

### Exercise 2.2: Custom Filter
Tambahkan filter bar untuk `stock` dan `price` menggunakan `UI.SelectionFields`.

### Exercise 2.3: Object Page Tab Baru
Tambahkan tab "Pricing" di Object Page yang menampilkan price, currency, stock.

### Exercise 2.4: Value Help
Implementasikan Value Help dropdown untuk field `author` menggunakan `@Common.ValueList`.

---

## 🔑 Key Concepts Hari 2

| Konsep | Penjelasan | Analogi |
|--------|------------|--------|
| **Fiori Elements** | Framework UI declarative berbasis annotations | Furniture IKEA pre-built |
| **List Report** | Template halaman tabel + filter + search | Halaman katalog toko online |
| **Object Page** | Template halaman detail dengan header & sections | Halaman detail produk |
| **`UI.LineItem`** | Mendefinisikan kolom di tabel | Memilih kolom di spreadsheet |
| **`UI.HeaderInfo`** | Mendefinisikan header di object page | Judul & subtitle di kartu nama |
| **`UI.Facets`** | Mendefinisikan tab/section di object page | Tab di browser |
| **Value Help** | Dropdown suggestion dari entity lain | Autocomplete di Google search |
| **SAPUI5 MVC** | Model-View-Controller pattern | Restoran: Dapur-Menu-Pelayan |
| **manifest.json** | App descriptor / konfigurasi utama | Buku manual elektronik |

---

## 📂 Hasil Hands-on

Semua hasil hands-on dan exercise didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|----------|
| [Hands-on 1: Fiori App Generation](./handson/handson-1-fiori-app-generation.md) | Generate & jalankan Fiori Elements app dari CAP |
| [Hands-on 2: Manifest & Routing](./handson/handson-2-manifest-routing.md) | Konfigurasi manifest.json dan verifikasi routing |
| [Hands-on 3: Fiori Annotations](./handson/handson-3-fiori-annotations.md) | CDS annotations dan hasil UI yang ter-generate |
| [Hands-on 4: Custom SAPUI5 View](./handson/handson-4-custom-sapui5.md) | Freestyle SAPUI5 view dengan MVC pattern |
| [Hands-on 5: Fiori Launchpad](./handson/handson-5-fiori-launchpad.md) | Konfigurasi FLP sandbox lokal |

---

## 📚 Referensi
- [Fiori Elements Documentation](https://ui5.sap.com/#/topic/03265b0408e2432c9571d6b3feb6b1fd)
- [SAPUI5 SDK](https://ui5.sap.com/)
- [Fiori Annotations Reference](https://cap.cloud.sap/docs/advanced/fiori)
- [SAP Fiori Tools](https://help.sap.com/docs/SAP_FIORI_tools)

---

⬅️ **Prev:** [Hari 1 — BTP Fundamentals](../Day1-BTP-Fundamentals/README.md)  
➡️ **Next:** [Hari 3 — Extensibility](../Day3-Extensibility/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
