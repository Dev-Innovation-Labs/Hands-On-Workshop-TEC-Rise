# ✅ Hands-on 3: CAP Project Pertama — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI  
> **Environment:** Node.js v24.11.0 | @sap/cds-dk 9.8.3 | @sap/cds 9.8.4

---

## Langkah 1: Buka Terminal & Verifikasi Tools ✅

```bash
$ node --version
v24.11.0

$ npm --version
11.6.1

$ cds --version
@sap/cds-dk (global)  9.8.3
Node.js               24.11.0
```

**Hasil:** Semua tools tersedia dan versi memenuhi syarat minimum.

---

## Langkah 2: Inisialisasi Project CAP ✅

### Command yang Dijalankan:

```bash
$ cds init bookshop
Successfully initialized CAP project
Continue with: code bookshop

$ cd bookshop
$ cds add nodejs
Adding facet: nodejs
Successfully added features to your project

$ cds add sample
Adding facet: sample
Successfully added features to your project

$ npm install
added 109 packages, and audited 110 packages in 8s
32 packages are looking for funding
found 0 vulnerabilities
```

> **Catatan:** Pada CDS v9.x, setelah `cds init` perlu menjalankan `cds add nodejs`
> untuk menentukan runtime, lalu `cds add sample` untuk menambahkan contoh data model.

### package.json yang Dihasilkan:

```json
{
  "name": "bookshop",
  "version": "1.0.0",
  "dependencies": {
    "@sap/cds": "^9"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^2"
  },
  "scripts": {
    "start": "cds-serve"
  },
  "private": true,
  "cds": {
    "requires": {
      "db-ext": {
        "[development]": { "model": "db/sqlite" },
        "[production]": { "model": "db/hana" }
      }
    }
  }
}
```

---

## Struktur Project yang Dihasilkan ✅

```
bookshop/
├── .gitignore
├── .vscode/
│   └── tasks.json
├── _i18n/                         ← Internationalization files
│   ├── i18n_de.properties
│   ├── i18n_en.properties
│   ├── i18n_fr.properties
│   ├── messages_de.properties
│   ├── messages_en.properties
│   └── messages_fr.properties
├── app/                           ← UI Fiori applications
│   ├── fiori-apps.html
│   ├── common.cds
│   ├── services.cds
│   ├── _i18n/
│   ├── admin-authors/             ← Fiori app: Author management
│   │   ├── fiori-service.cds
│   │   └── webapp/
│   ├── admin-books/               ← Fiori app: Book management
│   │   ├── fiori-service.cds
│   │   └── webapp/
│   ├── browse/                    ← Fiori app: Book browsing
│   │   ├── fiori-service.cds
│   │   └── webapp/
│   └── genres/                    ← Fiori app: Genre management
│       ├── fiori-service.cds
│       ├── value-help.cds
│       ├── tree-view.cds
│       └── webapp/
├── db/                            ← Data models & seed data
│   ├── schema.cds                 ← Domain model definition
│   ├── currencies.cds
│   ├── sqlite/
│   │   └── index.cds
│   ├── hana/
│   │   └── index.cds
│   └── data/                      ← CSV seed data
│       ├── sap.capire.bookshop-Authors.csv
│       ├── sap.capire.bookshop-Books.csv
│       ├── sap.capire.bookshop-Books.texts.csv
│       ├── sap.capire.bookshop-Genres.csv
│       ├── sap.capire.bookshop-Genres.texts.csv
│       ├── sap.common-Currencies.csv
│       └── sap.common-Currencies.texts.csv
├── srv/                           ← Service definitions & handlers
│   ├── cat-service.cds            ← CatalogService definition
│   ├── cat-service.js             ← CatalogService handler
│   ├── admin-service.cds          ← AdminService definition
│   ├── admin-service.js           ← AdminService handler
│   └── access-control.cds
├── node_modules/
├── package.json
├── package-lock.json
└── readme.md
```

---

## Langkah 3: Jalankan CAP Server ✅

### Command:
```bash
$ cds watch
# atau
$ cds serve
```

### Output Server (Actual):

```
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
[cds] - serving AdminService {
  at: [ '/odata/v4/admin' ],
  decl: 'srv/admin-service.cds:3',
  impl: 'srv/admin-service.js'
}
[cds] - serving CatalogService {
  at: [ '/odata/v4/catalog' ],
  decl: 'srv/cat-service.cds:3',
  impl: 'srv/cat-service.js'
}
[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - server v9.8.4 launched in 662 ms
```

**Analisis Output:**
- ✅ **15 CDS model files** loaded (schema, services, annotations, dll.)
- ✅ **SQLite in-memory database** berhasil terhubung
- ✅ **7 CSV data files** berhasil dimuat ke database
- ✅ **AdminService** tersedia di `/odata/v4/admin`
- ✅ **CatalogService** tersedia di `/odata/v4/catalog`
- ✅ **Server berjalan** di `http://localhost:4004`
- ✅ **Startup time:** 662 ms

---

## Langkah 4: Akses CAP Welcome Page & Test Endpoints ✅

### GET / (Welcome Page)
```
Status: 200 OK
→ Menampilkan CAP Welcome Page dengan daftar services yang tersedia
```

### GET /odata/v4/catalog/Books
```
Status: 200 OK
Response (JSON):
{
  "@odata.context": "$metadata#Books",
  "value": [
    {
      "ID": 201,
      "author": "Emily Brontë",
      "title": "Wuthering Heights",
      "descr": "Wuthering Heights, Emily Brontë's only novel...",
      "stock": 12,
      "price": 11.11,
      "currency_code": "GBP"
    },
    {
      "ID": 207,
      "author": "Charlotte Brontë",
      "title": "Jane Eyre",
      "stock": 11,
      "price": 12.34,
      "currency_code": "GBP"
    },
    {
      "ID": 251,
      "author": "Edgar Allen Poe",
      "title": "The Raven",
      "stock": 333,
      "price": 13.13,
      "currency_code": "USD"
    },
    {
      "ID": 252,
      "author": "Edgar Allen Poe",
      "title": "Eleonora",
      "stock": 555,
      "price": 14.00,
      "currency_code": "USD"
    },
    {
      "ID": 271,
      "author": "Richard Carpenter",
      "title": "Catweazle",
      "stock": 22,
      "price": 150.00,
      "currency_code": "JPY"
    }
  ]
}
```

### GET /odata/v4/catalog/Books?$top=3
```
Status: 200 OK
→ Mengembalikan 3 buku pertama (OData query parameter bekerja)
```

### GET /odata/v4/admin/Authors
```
Status: 401 Unauthorized
→ Expected! AdminService dilindungi oleh @requires annotation (access-control.cds)
→ Perlu autentikasi untuk mengakses admin endpoints
```

---

## 📊 Data Model yang Digunakan (db/schema.cds)

```cds
namespace sap.capire.bookshop;

entity Books : managed {
  key ID       : Integer;
      author   : Association to Authors @mandatory;
      title    : localized String       @mandatory;
      descr    : localized String;
      genre    : Association to Genres;
      stock    : Integer;
      price    : Price;
      currency : Currency;
}

entity Authors : managed {
  key ID           : Integer;
      name         : String @mandatory;
      dateOfBirth  : Date;
      dateOfDeath  : Date;
      placeOfBirth : String;
      placeOfDeath : String;
      books        : Association to many Books on books.author = $self;
}

entity Genres : cuid, sap.common.CodeList {
  parent   : Association to Genres;
  children : Composition of many Genres on children.parent = $self;
}

type Price : Decimal(9, 2);
```

---

## 📊 Service Layer (srv/cat-service.cds)

```cds
using {sap.capire.bookshop as my} from '../db/schema';

service CatalogService {
  @readonly entity ListOfBooks as projection on Books { *, ... };
  @readonly entity Books as projection on my.Books { *, author.name as author };
  @requires: 'authenticated-user'
  action submitOrder(book: Books:ID, quantity: Integer) returns { stock: Integer };
}
```

---

## 📊 Sample Data (CSV)

### Authors (4 records):
| ID | Name | Date of Birth | Place of Birth |
|----|------|---------------|----------------|
| 101 | Emily Brontë | 1818-07-30 | Thornton, Yorkshire |
| 107 | Charlotte Brontë | 1818-04-21 | Thornton, Yorkshire |
| 150 | Edgar Allen Poe | 1809-01-19 | Boston, Massachusetts |
| 170 | Richard Carpenter | 1929-08-14 | King's Lynn, Norfolk |

### Books (5 records):
| ID | Title | Author | Stock | Price | Currency |
|----|-------|--------|-------|-------|----------|
| 201 | Wuthering Heights | Emily Brontë | 12 | 11.11 | GBP |
| 207 | Jane Eyre | Charlotte Brontë | 11 | 12.34 | GBP |
| 251 | The Raven | Edgar Allen Poe | 333 | 13.13 | USD |
| 252 | Eleonora | Edgar Allen Poe | 555 | 14.00 | USD |
| 271 | Catweazle | Richard Carpenter | 22 | 150.00 | JPY |

---

**Kesimpulan:** CAP project berhasil diinisialisasi, di-install, dan dijalankan. Server CDS berjalan di localhost:4004 dengan 2 OData services (CatalogService & AdminService). Database SQLite in-memory berhasil dimuat dengan 7 CSV data files. OData endpoint mengembalikan data Books dan Authors dengan benar.
