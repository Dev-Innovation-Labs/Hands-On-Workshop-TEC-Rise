# 📒 Hari 4: SAP Fiori & SAPUI5

> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 3, OData service berjalan di localhost:4004

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 4, peserta mampu:
- Memahami SAP Fiori Design Principles dan 5 Fiori Principles
- Membedakan Fiori Elements vs Custom SAPUI5
- Membuat Fiori Elements List Report & Object Page dari OData service
- Menggunakan Fiori Annotations (UI, Common) untuk mengkonfigurasi tampilan
- Menggunakan SAP Fiori tools di BAS
- Menjalankan Fiori app di Fiori Launchpad (lokal)

---

## 📅 Jadwal Hari 4

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 3 | 15 menit |
| 09:15 – 10:30 | **Teori: Fiori Design & Arsitektur** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: Generate Fiori App dengan Yeoman** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Fiori Annotations & Customization** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: Fiori Launchpad & Navigation** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: SAP Fiori Design

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
# Di terminal BAS atau lokal
npm install -g @sap/generator-fiori

# Verifikasi
yo @sap/fiori --version
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

---

## 🛠️ Hands-on 2: Konfigurasi `manifest.json`

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

## 📝 Latihan Mandiri Hari 4

### Exercise 4.1: Tambah Column di List Report
Tambahkan kolom `genre` di `UI.LineItem` annotation

### Exercise 4.2: Custom Filter
Tambahkan filter bar untuk `price range` menggunakan `UI.SelectionFields`

### Exercise 4.3: Object Page Tab Baru
Tambahkan tab "Reviews" di Object Page yang menampilkan related reviews menggunakan `UI.Facets`

### Exercise 4.4: Value Help
Implementasikan Value Help dropdown untuk field `genre` saat membuat/edit buku

---

## 🔑 Key Concepts Hari 4

| Konsep | Penjelasan |
|--------|------------|
| **Fiori Elements** | Framework UI declarative berbasis annotations |
| **List Report** | Template halaman daftar dengan filter & table |
| **Object Page** | Template halaman detail dengan header & sections |
| **`UI.LineItem`** | Mendefinisikan kolom di tabel list |
| **`UI.HeaderInfo`** | Mendefinisikan header di object page |
| **`UI.Facets`** | Mendefinisikan tab/section di object page |
| **Value Help** | Dropdown suggestion dari VH entity |
| **SAPUI5 MVC** | Model-View-Controller pattern |

---

## 📚 Referensi

- [SAP Fiori Design Guidelines](https://experience.sap.com/fiori-design-web/)
- [Fiori Elements Documentation](https://ui5.sap.com/#/topic/03265b0408e2432c9571d6b3feb6b1fd)
- [SAPUI5 SDK](https://ui5.sap.com/)
- [Fiori Annotations Reference](https://cap.cloud.sap/docs/advanced/fiori)
- [SAP Fiori Tools](https://help.sap.com/docs/SAP_FIORI_tools)

---

⬅️ **Prev:** [Hari 3 — OData Services](../Day3-OData-Services/README.md)  
➡️ **Next:** [Hari 5 — Integration & Deployment](../Day5-Integration-Deployment/README.md)
