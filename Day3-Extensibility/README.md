# 📗 Hari 3: Extensibility — CDS Extensions, OData & Custom Logic

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 2 (Fiori app berjalan di atas CAP bookshop)  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 3, peserta mampu:
- Memahami konsep extensibility di SAP CAP (extend entity, extend service)
- Extend CDS model dengan entity, associations, dan compositions baru
- Mendefinisikan custom types, aspects, dan enum types
- Mengimplementasikan custom event handlers (before, after, on)
- Memahami OData V4 query options ($filter, $expand, $select, $orderby)
- Membuat actions dan functions di OData service
- Menguji API menggunakan curl / browser

---

## 📅 Jadwal Hari 3

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 2 | 15 menit |
| 09:15 – 10:30 | **Teori: CDS Extensibility & OData Protocol** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: Extend CDS Model (Entity, Types, Aspects)** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Custom Event Handlers & Business Logic** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: OData Query, Actions & Testing** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: CDS Extensibility & OData

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

Hari 3 ini penuh istilah teknis. Mari pahami dulu dengan analogi:

> **🏗️ Extensibility = Renovasi Rumah**
>
> Di Hari 1 Anda sudah membangun rumah (CAP project). Di Hari 3, kita akan:
> - **Menambah kamar baru** (extend entity) — tanpa meruntuhkan dinding yang sudah ada
> - **Memasang modul pre-built** (aspect) — seperti kit kamar mandi standar
> - **Memasang satpam di pintu** (event handler) — validasi sebelum masuk/keluar
>
> | Istilah | Analogi | Penjelasan |
> |:--------|:--------|:-----------|
> | **`extend entity`** | Tambah kamar baru ke rumah | Tambah field/kolom ke tabel tanpa ubah file asli |
> | **`aspect`** | Kit kamar mandi standar | Kumpulan field reusable (createdBy, createdAt) — pasang ke entity manapun |
> | **`type ... enum`** | Pilihan ganda di formulir | Custom type dengan nilai terbatas (Poor, Fair, Good, Excellent) |
> | **`Association`** | Kartu referensi di perpustakaan | "Buku ini ditulis oleh Author X" — pointer ke entity lain |
> | **`Composition`** | Faktur + baris item | Parent–child: hapus faktur → semua baris item ikut terhapus |
> | **Before handler** | Satpam di pintu masuk | Validasi sebelum data disimpan (cek field wajib, format, dll) |
> | **After handler** | Quality control di pintu keluar | Transformasi data setelah di-query (tambah computed field) |
> | **On handler** | Custom logic di dalam ruangan | Override/extend logic default (logging, custom query) |
> | **Action** | Tombol "Pesan" di e-commerce | Operasi POST yang mengubah data (side-effect) |
> | **Function** | Tombol "Hitung Ongkir" | Operasi GET yang hanya membaca (tanpa ubah data) |
> | **OData** | Pelayan pintar di restoran | Protokol REST yang mengerti query canggih ($filter, $expand, dll) |
> | **`$filter`** | "Saya mau buku harga < 20rb" | Filter data di URL |
> | **`$expand`** | "Tampilkan juga info authornya" | Eager-load relasi (JOIN) di URL |
> | **`$select`** | "Saya cuma butuh title dan price" | Pilih kolom yang direturn |
>
> **Alur Extensibility:**
> ```
> schema.cds (entity Books)          ← Model asli
>   + extensions.cds (extend Books)  ← Tambah field isbn, pages
>   + extensions.cds (entity Reviews)← Entity baru
>     → catalog-service.cds          ← Expose via OData
>       → catalog-service.js         ← Custom logic (validasi, action)
>         → Browser: /catalog/Books?$expand=author  ← Test!
> ```

### CDS dalam Ekosistem CAP

```
CDS Files (.cds)
├── db/schema.cds        → Data models (persistent layer)
├── db/extensions.cds    → Extend existing models
├── srv/service.cds      → Service definitions (API layer)
└── app/annotations.cds  → UI annotations (presentation layer)
        ↓
CDS Compiler
        ↓
├── SQL DDL              → Untuk database (HANA/SQLite)
├── OData EDMX           → Untuk OData services
└── JSON Metadata        → Untuk runtime
```

### Cara Extend di CDS

```
1. extend entity     → Tambah field ke entity yang sudah ada
2. extend service    → Tambah entity baru ke service
3. annotate          → Tambah metadata tanpa ubah model
4. aspect            → Reusable mixin/fragment
5. type              → Custom type definition
```

### OData Protocol di CAP

CAP secara default menghasilkan OData V4. Semua entity di service otomatis menjadi OData EntitySet.

```
OData URL Structure:
BASE_URL / SERVICE_PATH / ENTITY_SET ? QUERY_OPTIONS

Contoh:
http://localhost:4004/odata/v4/catalog/Books
    ?$select=title,price
    &$filter=price lt 20
    &$expand=author($select=name)
    &$orderby=title asc
    &$top=10
```

| Query Option | Fungsi | Contoh |
|:-------------|:-------|:-------|
| `$select` | Pilih kolom | `$select=title,price` |
| `$filter` | Filter data | `$filter=price lt 20` |
| `$expand` | Eager-load relasi | `$expand=author` |
| `$orderby` | Urutkan | `$orderby=price desc` |
| `$top` / `$skip` | Paging | `$top=10&$skip=20` |
| `$count` | Hitung total | `$count=true` |
| `$search` | Full-text search | `$search=Bronte` |

---

## 🛠️ Hands-on 1: Extend CDS Model

Kita akan extend bookshop sample project dari Hari 1/2 dengan entity dan field baru.

> **💡 Kenapa extend, bukan edit langsung?**
> Dalam proyek enterprise, `schema.cds` bisa dimiliki tim lain.
> Dengan `extend`, Anda menambah field **tanpa mengubah file asli** —
> seperti menambah kamar ke rumah tanpa meruntuhkan dinding yang sudah ada.

### 1a. Tambah fields baru ke entity yang sudah ada

**File: `db/extensions.cds`**

```cds
using { com.tecrise.bookshop as db } from './schema';

// Tambah field baru ke Books
extend entity db.Books with {
    isbn      : String(13);
    language  : String(5);
    pages     : Integer;
    publisher : String(100);
}

// Tambah field baru ke Authors
extend entity db.Authors with {
    country   : String(3);
    biography : String(1000);
}
```

### 1b. Tambah entity baru dengan associations

**File: `db/extensions.cds`** (lanjutan)

```cds
// Custom type
type Rating : Integer enum { Poor=1; Fair=2; Good=3; VeryGood=4; Excellent=5 }

// Reusable aspect
aspect auditable {
    createdBy  : String(50);
    createdAt  : Timestamp;
}

// Entity baru: Reviews
entity db.Reviews : cuid, auditable {
    book    : Association to db.Books;
    rating  : Rating;
    comment : String(500);
}

// Entity baru: Orders & OrderItems (Composition)
entity db.Orders : cuid, managed {
    customer  : String(100);
    total     : Decimal(10,2);
    status    : String enum { New; Confirmed; Shipped; Cancelled };
    items     : Composition of many db.OrderItems on items.parent = $self;
}

entity db.OrderItems : cuid {
    parent    : Association to db.Orders;
    book      : Association to db.Books;
    amount    : Integer;
    netAmount : Decimal(10,2);
}
```

### 1c. Extend Service

**File: `srv/catalog-service.cds`**

```cds
using { com.tecrise.bookshop as db } from '../db/schema';

service CatalogService @(path: '/catalog') {

    @readonly entity Books    as projection on db.Books;
    @readonly entity Authors  as projection on db.Authors;
    @readonly entity Reviews  as projection on db.Reviews;

    // Action: Submit order
    action submitOrder(bookID: UUID, amount: Integer) returns {
        orderID : UUID;
        status  : String;
        message : String;
    };

    // Function: Hitung books per author
    function countBooksForAuthor(authorID: UUID) returns Integer;
}

@requires: 'admin'
service AdminService @(path: '/admin') {
    entity Books      as projection on db.Books;
    entity Authors    as projection on db.Authors;
    entity Orders     as projection on db.Orders;
    entity OrderItems as projection on db.OrderItems;
}
```

### Jalankan & Verifikasi

```bash
cd bookshop
cds watch
```

**✅ Hasil yang Diharapkan:**

```
[cds] - loaded model from ... file(s)

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from db/data/...
/> successfully deployed to in-memory database.

[cds] - serving CatalogService { at: ['/odata/v4/catalog'] }
[cds] - serving AdminService   { at: ['/odata/v4/admin'] }

[cds] - server listening on { url: 'http://localhost:4004' }
```

Buka http://localhost:4004 — Anda akan melihat:
- **CatalogService** dengan entity: Books, Authors, Reviews
- **AdminService** dengan entity: Books, Authors, Orders, OrderItems

Klik `Books` untuk verifikasi field baru (isbn, language, pages, publisher) muncul di metadata:
```
GET http://localhost:4004/odata/v4/catalog/$metadata
```

---

## 🛠️ Hands-on 2: Custom Event Handlers

> **💡 Analogi: Satpam di 3 Pos Jaga**
>
> ```
> BEFORE = Satpam di pintu masuk   → Cek KTP, tolak yang tidak valid
> ON     = Petugas di dalam gedung  → Proses utama (atau override default)
> AFTER  = Quality control di exit  → Tambah stempel, transformasi data
> ```
>
> Setiap request melewati ketiga pos ini secara berurutan.

### File: `srv/catalog-service.js`

```javascript
const cds = require('@sap/cds');

module.exports = class CatalogService extends cds.ApplicationService {

    async init() {
        const { Books, Reviews, OrderItems } = this.entities;

        // ============================================
        // BEFORE Handler: Validasi sebelum operasi
        // ============================================
        this.before('CREATE', 'Books', (req) => {
            const { title, price } = req.data;
            if (!title || title.trim() === '') {
                req.reject(400, 'Book title is required');
            }
            if (price !== undefined && price < 0) {
                req.reject(400, 'Price cannot be negative');
            }
        });

        // Validasi rating Reviews
        this.before('CREATE', 'Reviews', (req) => {
            const { rating } = req.data;
            if (rating < 1 || rating > 5) {
                req.reject(400, 'Rating must be between 1 and 5');
            }
        });

        // ============================================
        // AFTER Handler: Tambah computed field
        // ============================================
        this.after('READ', 'Books', (books) => {
            for (const book of Array.isArray(books) ? books : [books]) {
                if (book.stock !== undefined) {
                    book.stockStatus = book.stock > 10
                        ? 'High'
                        : book.stock > 0 ? 'Low' : 'Out of Stock';
                }
            }
        });

        // ============================================
        // ON Handler: Logging
        // ============================================
        this.on('READ', 'Books', async (req, next) => {
            console.log(`[CatalogService] READ Books — User: ${req.user?.id}`);
            return next();
        });

        // ============================================
        // FUNCTION: countBooksForAuthor
        // ============================================
        this.on('countBooksForAuthor', async (req) => {
            const { authorID } = req.data;
            const result = await SELECT.from(Books).where({ author_ID: authorID });
            return result.length;
        });

        // ============================================
        // ACTION: submitOrder
        // ============================================
        this.on('submitOrder', async (req) => {
            const { bookID, amount } = req.data;

            const book = await SELECT.one(Books).where({ ID: bookID });
            if (!book) req.reject(404, `Book ${bookID} not found`);
            if (book.stock < amount) {
                req.reject(409, `Insufficient stock. Available: ${book.stock}`);
            }

            await UPDATE(Books)
                .set({ stock: book.stock - amount })
                .where({ ID: bookID });

            const orderID = cds.utils.uuid();
            await INSERT.into(OrderItems).entries({
                ID: cds.utils.uuid(),
                parent_ID: orderID,
                book_ID: bookID,
                amount,
                netAmount: book.price * amount,
            });

            return {
                orderID,
                status: 'CONFIRMED',
                message: `Order for ${amount}x "${book.title}" confirmed.`,
            };
        });

        return super.init();
    }
};
```

### Lifecycle Hooks — Kapan Dipanggil?

```
Request masuk
     │
     ▼
  BEFORE handlers   ← Validasi, enrichment
     │
     ▼
  ON handlers       ← Main logic (atau default CRUD)
     │
     ▼
  AFTER handlers    ← Transformasi response
     │
     ▼
  Response keluar
```

---

## 🛠️ Hands-on 3: OData Query & Testing

> **💡 Analogi: OData = Pelayan Pintar di Restoran**
>
> Bayangkan Anda di restoran dan bilang ke pelayan:
> - "Saya mau **menu** dengan **harga < 50rb** (`$filter=price lt 50`)" 
> - "Tampilkan cuma **nama dan harga** (`$select=title,price`)"
> - "Urutkan dari **termurah** (`$orderby=price asc`)"
> - "Kasih **3 saja** (`$top=3`)"
> - "Sertakan juga **info chef-nya** (`$expand=author`)"
>
> OData mengerti semua "permintaan" ini langsung di URL!

### Query di Browser / curl

```bash
BASE=http://localhost:4004/odata/v4/catalog

# GET semua books
curl "$BASE/Books"

# SELECT fields tertentu
curl "$BASE/Books?\$select=title,price,stock"

# FILTER harga < 20
curl "$BASE/Books?\$filter=price%20lt%2020"

# EXPAND navigasi ke author
curl "$BASE/Books?\$expand=author(\$select=name)"

# ORDER BY
curl "$BASE/Books?\$orderby=price%20desc"

# PAGING
curl "$BASE/Books?\$top=3&\$skip=1"

# Kombinasi
curl "$BASE/Books?\$select=title,price&\$filter=price%20lt%2020&\$orderby=price&\$expand=author(\$select=name)&\$top=5"
```

**✅ Contoh Hasil `GET /odata/v4/catalog/Books?$top=2&$select=title,price`:**

```json
{
  "@odata.context": "$metadata#Books(title,price)",
  "value": [
    { "title": "Wuthering Heights", "price": 11.11 },
    { "title": "Jane Eyre", "price": 12.34 }
  ]
}
```

### CRUD Operations

```bash
# CREATE book
curl -X POST "$BASE/Books" \
  -H "Content-Type: application/json" \
  -d '{"title":"New Book","price":19.99,"stock":50}'

# UPDATE (PATCH)
curl -X PATCH "$BASE/Books(<ID>)" \
  -H "Content-Type: application/json" \
  -d '{"price":21.00}'

# DELETE
curl -X DELETE "$BASE/Books(<ID>)"

# Call ACTION submitOrder
curl -X POST "$BASE/submitOrder" \
  -H "Content-Type: application/json" \
  -d '{"bookID":"<ID>","amount":2}'

# Call FUNCTION
curl "$BASE/countBooksForAuthor(authorID=<AUTHOR_ID>)"
```

### File `.http` untuk REST Client (VS Code)

**File: `tests/catalog.http`**

```http
@host = http://localhost:4004/odata/v4

### GET All Books
GET {{host}}/catalog/Books
Accept: application/json

### GET Books with Expand
GET {{host}}/catalog/Books?$expand=author&$select=title,price
Accept: application/json

### Filter Books
GET {{host}}/catalog/Books?$filter=price lt 15&$orderby=title
Accept: application/json

### Submit Order
POST {{host}}/catalog/submitOrder
Content-Type: application/json

{
    "bookID": "421fc377-b1f0-485c-b3b9-7bb3c1c16a58",
    "amount": 2
}
```

---

## 📝 Latihan Mandiri Hari 3

### Exercise 3.1: Extend & New Entity
Extend entity `Books` dengan field `genre : String(50)`. Buat entity `Genres` dan buat association dari `Books` ke `Genres`.

### Exercise 3.2: Custom Handler — Review Validation
Implementasikan handler `before CREATE Reviews` yang:
- Memastikan `rating` antara 1–5
- Memastikan `comment` minimal 10 karakter

### Exercise 3.3: Custom Function
Buat function `getAverageRating(bookID: UUID) returns Decimal` di `CatalogService` yang menghitung rata-rata rating sebuah buku.

### Exercise 3.4: OData Query Challenge
Tulis query OData untuk:
1. Semua buku harga 10–20, urut mahal ke murah
2. 3 author pertama beserta buku mereka (`$expand`)
3. Buku stok < 50H, tampilkan title & stock saja

---

## 🔑 Key Concepts Hari 3

| Konsep | Penjelasan | Analogi |
|--------|------------|--------|
| **`extend entity`** | Tambah field tanpa ubah file asli | Tambah kamar ke rumah |
| **`aspect`** | Reusable fragment (mixin) | Kit kamar mandi standar |
| **`type ... enum`** | Custom type dengan nilai terbatas | Pilihan ganda di formulir |
| **`Composition`** | Parent–child (cascade delete) | Faktur + baris item |
| **`Association`** | Referensi ke entity lain (FK) | Kartu referensi perpustakaan |
| **Before / After / On** | Lifecycle hooks untuk custom logic | 3 pos jaga satpam |
| **Action** | Operasi POST yang ubah data | Tombol "Pesan" di e-commerce |
| **Function** | Operasi GET tanpa side-effect | Tombol "Hitung Ongkir" |
| **`$expand`** | Eager loading relasi via OData | "Tampilkan juga info chef-nya" |
| **`$filter` / `$select`** | Filter & proyeksi data | Permintaan spesifik ke pelayan |

---

## 📂 Hasil Hands-on

Semua hasil hands-on didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|----------|
| [Hands-on 1: Extend CDS Model](./handson/handson-1-extend-cds-model.md) | Extend entity, buat entity baru, custom types & aspects |
| [Hands-on 2: Custom Handlers](./handson/handson-2-custom-handlers.md) | Before/After/On handlers, action & function |
| [Hands-on 3: OData Testing](./handson/handson-3-odata-testing.md) | OData queries dengan JSON response aktual |

---

## 📚 Referensi

- [CDS Language Reference](https://cap.cloud.sap/docs/cds/)
- [CAP Event Handlers](https://cap.cloud.sap/docs/node.js/core-services)
- [OData v4 Specification](https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html)
- [CAP Extensibility Guide](https://cap.cloud.sap/docs/guides/extensibility/)
- [OData Query Cheat Sheet](https://www.odata.org/getting-started/basic-tutorial/)

---

⬅️ **Prev:** [Hari 2 — SAP Fiori & UI5](../Day2-Fiori-UI5/README.md)  
➡️ **Next:** [Hari 4 — Integration & Deployment](../Day4-Integration-Deployment/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
