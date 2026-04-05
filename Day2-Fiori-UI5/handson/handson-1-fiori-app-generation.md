# ✅ Hands-on 1: Fiori App Generation — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026  
> **Environment:** macOS, Node.js v24.11.0, @sap/cds-dk 9.8.3

---

## Langkah yang Dilakukan

### 1. Verifikasi Tools

```
$ yo --version
7.0.0

$ cds --version
@sap/cds-dk: 9.8.3

$ node --version
v24.11.0
```

### 2. Inisialisasi CAP Project dengan Sample (termasuk Fiori apps)

```
$ cds init bookshop
Successfully initialized CAP project

$ cds add nodejs
Adding facet: nodejs
Successfully added features to your project

$ cds add sample
Adding facet: sample
Successfully added features to your project

$ npm install
added 109 packages, and audited 110 packages in 8s
found 0 vulnerabilities
```

> **Catatan Penting:** `cds add sample` di CDS v9.x sudah menyertakan **Fiori Elements apps** secara otomatis
> di folder `app/`. Tidak perlu lagi menjalankan `yo @sap/fiori` untuk bookshop sample.

### 3. Struktur Fiori Apps yang Ter-generate

```
app/
├── fiori-apps.html             ← Fiori Launchpad sandbox (entry point)
├── common.cds                  ← Shared annotations
├── services.cds                ← Service-level annotations
├── browse/                     ← 📚 Browse Books (CatalogService)
│   ├── fiori-service.cds       ← UI annotations (LineItem, HeaderInfo, Facets)
│   └── webapp/
│       ├── Component.js
│       ├── manifest.json
│       └── i18n/
├── admin-books/                ← 📖 Manage Books (AdminService)
│   ├── fiori-service.cds
│   └── webapp/
├── admin-authors/              ← ✍️ Manage Authors (AdminService)
│   ├── fiori-service.cds
│   └── webapp/
├── genres/                     ← 🏷️ Genres (tree view & value help)
│   ├── fiori-service.cds
│   ├── value-help.cds
│   ├── tree-view.cds
│   └── webapp/
└── appconfig/
    └── fioriSandboxConfig.json ← FLP sandbox configuration
```

### 4. Jalankan Server & Verifikasi

```
$ cds watch

[cds] - loaded model from 15 file(s):

  srv/access-control.cds
  db/sqlite/index.cds
  app/services.cds
  app/genres/fiori-service.cds
  app/browse/fiori-service.cds
  app/admin-authors/fiori-service.cds
  srv/cat-service.cds
  app/genres/value-help.cds
  app/genres/tree-view.cds
  app/admin-books/fiori-service.cds
  srv/admin-service.cds
  app/common.cds
  db/schema.cds
  db/currencies.cds
  node_modules/@sap/cds/common.cds

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from db/data/sap.common-Currencies.texts.csv
  > init from db/data/sap.common-Currencies.csv
  > init from db/data/sap.capire.bookshop-Genres.texts.csv
  > init from db/data/sap.capire.bookshop-Genres.csv
  > init from db/data/sap.capire.bookshop-Books.texts.csv
  > init from db/data/sap.capire.bookshop-Books.csv
  > init from db/data/sap.capire.bookshop-Authors.csv
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving AdminService { at: ['/odata/v4/admin'] }
[cds] - serving CatalogService { at: ['/odata/v4/catalog'] }

[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - server v9.8.4 launched in 652 ms
```

### 5. Akses Fiori Apps

| URL | Hasil | Status |
|:----|:------|:-------|
| `http://localhost:4004` | CAP Welcome Page | ✅ 200 OK |
| `http://localhost:4004/fiori-apps.html` | Fiori Launchpad sandbox | ✅ 200 OK |
| `http://localhost:4004/odata/v4/catalog/Books` | JSON 5 buku | ✅ 200 OK |

---

## Kesimpulan

- ✅ CAP v9 sample sudah menyertakan Fiori Elements apps (browse, admin-books, admin-authors, genres)
- ✅ Fiori Launchpad sandbox tersedia di `/fiori-apps.html`
- ✅ Annotations sudah terdefinisi di `app/*/fiori-service.cds`
- ✅ Server berjalan sukses di port 4004
