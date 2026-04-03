# 📙 Hari 3: OData Services & CAP Service Layer

> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 2, schema.cds sudah terdefinisi

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 3, peserta mampu:
- Memahami protokol OData v2 dan v4 serta perbedaannya
- Mendefinisikan CAP services dengan CDS
- Mengimplementasikan CRUD operations dengan custom handlers
- Menggunakan OData query options ($filter, $expand, $select, $orderby)
- Menerapkan actions dan functions di OData service
- Menguji API menggunakan REST client / Postman

---

## 📅 Jadwal Hari 3

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 2 | 15 menit |
| 09:15 – 10:30 | **Teori: OData Protocol v2 vs v4** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: CAP Service Definitions** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Custom Event Handlers** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: OData Query & Testing** | 105 menit |
| 16:30 – 17:00 | Review, Quiz & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: OData Protocol

### Apa itu OData?

**OData (Open Data Protocol)** adalah standar protokol REST untuk mengakses dan memanipulasi data. Dikembangkan oleh Microsoft, diadopsi luas oleh SAP.

```
OData = HTTP + JSON/XML + Query Language + Metadata
```

### OData v2 vs v4

| Fitur | OData v2 | OData v4 |
|-------|----------|----------|
| **Format** | JSON, XML (Atom) | JSON, XML |
| **Query** | `$filter`, `$top`, `$skip` | Semua v2 + `$apply`, `$count` |
| **Functions** | Function import | Bound & Unbound functions |
| **Delta** | ❌ | ✅ Delta queries |
| **Aggregation** | ❌ | ✅ `$apply=aggregate` |
| **Navigation** | Terbatas | Full navigation |
| **SAP Usage** | SAP Gateway (S/4) | CAP, SAP RAP |

### OData URL Structure

```
BASE_URL / SERVICE / ENTITY_SET ? QUERY_OPTIONS

Contoh:
https://host/odata/v4/catalog/Books
    ?$select=title,price
    &$filter=price lt 20
    &$orderby=title asc
    &$top=10
    &$skip=0
    &$expand=author($select=name)
    &$count=true
```

### OData Metadata

```xml
<!-- GET /odata/v4/catalog/$metadata -->
<EntityType Name="Books">
    <Key>
        <PropertyRef Name="ID"/>
    </Key>
    <Property Name="ID"    Type="Edm.Guid" Nullable="false"/>
    <Property Name="title" Type="Edm.String" MaxLength="150"/>
    <Property Name="price" Type="Edm.Decimal" Precision="10" Scale="2"/>
    <NavigationProperty Name="author" Type="CatalogService.Authors"/>
</EntityType>
```

---

## 🛠️ Hands-on 1: CAP Service Definitions

### File: `srv/catalog-service.cds`

```cds
using { com.tecrise.bookshop as db } from '../db/schema';

// ============================================
// PUBLIC CATALOG SERVICE (read-only untuk end users)
// ============================================
service CatalogService @(path: '/catalog') {

    // Expose Books dengan proyeksi (kolom terpilih)
    entity Books as projection on db.Books {
        *,                                // Semua fields
        author.name as authorName,        // Flatten navigation
    } excluding { image }                 // Sembunyikan binary field

    // Expose Authors (read-only)
    @readonly
    entity Authors as projection on db.Authors;

    // Expose Genres (read-only)
    @readonly
    entity Genres as projection on db.Genres;

    // ---- Actions & Functions ----
    
    // Function: Hitung total books per author
    function countBooksForAuthor(authorID: UUID) returns Integer;

    // Action: Submit order
    action submitOrder(bookID: UUID, amount: Integer) returns {
        orderID  : UUID;
        status   : String;
        message  : String;
    };
}

// ============================================
// ADMIN SERVICE (untuk administrator)
// ============================================
@requires: 'admin'
service AdminService @(path: '/admin') {

    // Full CRUD untuk Books
    entity Books        as projection on db.Books;
    entity Authors      as projection on db.Authors;
    entity Orders       as projection on db.Orders;
    entity OrderItems   as projection on db.OrderItems;
}
```

---

## 🛠️ Hands-on 2: Custom Event Handlers (JavaScript)

### File: `srv/catalog-service.js`

```javascript
const cds = require('@sap/cds');

/**
 * Implementation of CatalogService
 */
module.exports = class CatalogService extends cds.ApplicationService {

    async init() {
        const db = await cds.connect.to('db');
        const { Books, OrderItems } = db.entities;

        // ============================================
        // BEFORE Handler: Validasi sebelum operasi
        // ============================================
        this.before('CREATE', 'Books', async (req) => {
            const { title, price } = req.data;
            
            // Validasi manual
            if (!title || title.trim() === '') {
                req.reject(400, 'Book title is required');
            }
            if (price !== undefined && price < 0) {
                req.reject(400, 'Price cannot be negative');
            }
        });

        // ============================================
        // AFTER Handler: Transformasi setelah query
        // ============================================
        this.after('READ', 'Books', (books) => {
            // Tambahkan computed field
            books = Array.isArray(books) ? books : [books];
            books.forEach(book => {
                book.stockStatus = book.stock > 0 
                    ? (book.stock > 10 ? 'High' : 'Low') 
                    : 'Out of Stock';
            });
        });

        // ============================================
        // ON Handler: Custom logic untuk operasi
        // ============================================
        this.on('READ', 'Books', async (req, next) => {
            // Tambahkan logging
            console.log(`[CatalogService] Reading Books - User: ${req.user?.id}`);
            return next(); // Lanjutkan ke default handler
        });

        // ============================================
        // FUNCTION Handler: countBooksForAuthor
        // ============================================
        this.on('countBooksForAuthor', async (req) => {
            const { authorID } = req.data;
            
            const result = await SELECT
                .from(Books)
                .where({ author_ID: authorID });
            
            return result.length;
        });

        // ============================================
        // ACTION Handler: submitOrder
        // ============================================
        this.on('submitOrder', async (req) => {
            const { bookID, amount } = req.data;
            
            // 1. Cek ketersediaan stok
            const book = await SELECT.one(Books)
                .where({ ID: bookID });
            
            if (!book) {
                req.reject(404, `Book ${bookID} not found`);
            }
            if (book.stock < amount) {
                req.reject(409, `Insufficient stock. Available: ${book.stock}`);
            }

            // 2. Kurangi stok
            await UPDATE(Books)
                .set({ stock: book.stock - amount })
                .where({ ID: bookID });

            // 3. Buat order item
            const orderID = cds.utils.uuid();
            await INSERT.into(OrderItems).entries({
                ID      : cds.utils.uuid(),
                parent_ID: orderID,
                book_ID : bookID,
                amount  : amount,
                netAmount: book.price * amount
            });

            return {
                orderID : orderID,
                status  : 'CONFIRMED',
                message : `Order for ${amount} copies of "${book.title}" confirmed.`
            };
        });

        return super.init();
    }
};
```

---

## 🛠️ Hands-on 3: OData Query Options

### Menguji Query di Browser / REST Client

```bash
BASE_URL=http://localhost:4004/catalog

# 1. GET semua books
GET ${BASE_URL}/Books

# 2. SELECT fields tertentu
GET ${BASE_URL}/Books?$select=title,price,stock

# 3. FILTER by harga < 20
GET ${BASE_URL}/Books?$filter=price lt 20

# 4. FILTER kombinasi
GET ${BASE_URL}/Books?$filter=price lt 20 and stock gt 0

# 5. EXPAND navigasi ke author
GET ${BASE_URL}/Books?$expand=author($select=name)

# 6. ORDER BY
GET ${BASE_URL}/Books?$orderby=price desc,title asc

# 7. PAGING
GET ${BASE_URL}/Books?$top=5&$skip=10

# 8. SEARCH (full-text)
GET ${BASE_URL}/Books?$search=Bronte

# 9. COUNT
GET ${BASE_URL}/Books?$count=true

# 10. Kombinasi kompleks
GET ${BASE_URL}/Books
    ?$select=title,price
    &$filter=price lt 20
    &$orderby=price
    &$expand=author($select=name)
    &$top=5
```

### OData CRUD Operations

```bash
# CREATE
POST ${BASE_URL}/Books
Content-Type: application/json

{
    "title": "New Book",
    "author_ID": "8d4d1e9b-bb20-4d9a-b4ce-c362d8b12f51",
    "price": 19.99,
    "stock": 50,
    "currency_code": "USD"
}

# UPDATE (PUT - full replacement)
PUT ${BASE_URL}/Books(421fc377-b1f0-485c-b3b9-7bb3c1c16a58)
Content-Type: application/json

{ "title": "Updated Title", "price": 21.00 }

# PATCH (partial update)
PATCH ${BASE_URL}/Books(421fc377-b1f0-485c-b3b9-7bb3c1c16a58)
Content-Type: application/json

{ "price": 21.00 }

# DELETE
DELETE ${BASE_URL}/Books(421fc377-b1f0-485c-b3b9-7bb3c1c16a58)

# Call ACTION
POST ${BASE_URL}/submitOrder
Content-Type: application/json

{ "bookID": "421fc377-...", "amount": 2 }

# Call FUNCTION
GET ${BASE_URL}/countBooksForAuthor(authorID=8d4d1e9b-...)
```

---

## 🛠️ Hands-on 4: File `.http` untuk Testing

### File: `tests/catalog.http`

```http
### Variables
@host = http://localhost:4004
@booksPath = /catalog/Books

### 1. Get All Books
GET {{host}}{{booksPath}}
Accept: application/json

###

### 2. Get Books with Expand Author
GET {{host}}{{booksPath}}?$expand=author&$select=title,price
Accept: application/json

###

### 3. Filter Books by Price
GET {{host}}{{booksPath}}?$filter=price lt 15&$orderby=title
Accept: application/json

###

### 4. Create New Book
POST {{host}}{{booksPath}}
Content-Type: application/json

{
    "title": "The Great Gatsby",
    "price": 13.99,
    "stock": 80,
    "currency_code": "USD"
}

###

### 5. Submit Order Action
POST {{host}}/catalog/submitOrder
Content-Type: application/json

{
    "bookID": "421fc377-b1f0-485c-b3b9-7bb3c1c16a58",
    "amount": 2
}
```

---

## 📝 Latihan Mandiri Hari 3

### Exercise 3.1: Service Baru
Buat service `ReviewService` yang expose entity `Reviews` dengan:
- Hanya bisa dibaca oleh semua user
- Hanya bisa dibuat/diupdate oleh `authenticated` user

### Exercise 3.2: Custom Handler
Implementasikan `before CREATE Reviews` yang memvalidasi `rating` harus antara 1-5

### Exercise 3.3: Aggregation
Buat function `getAverageRating(bookID: UUID) returns Decimal` yang menghitung rata-rata rating sebuah buku

### Exercise 3.4: OData Query
Tulis query OData untuk:
1. Semua buku dengan harga antara 10-20, diurutkan mahal ke murah
2. 3 author pertama beserta jumlah buku mereka
3. Buku yang stoknya kurang dari 50

---

## 🔑 Key Concepts Hari 3

| Konsep | Penjelasan |
|--------|------------|
| **OData EntitySet** | Kumpulan entitas yang bisa di-query |
| **Navigation Property** | Link antar entity untuk `$expand` |
| **Action** | Operasi yang mengubah data (side-effects) |
| **Function** | Operasi baca tanpa side-effects |
| **Before/After/On** | Lifecycle hooks untuk custom logic |
| **`$expand`** | Eager loading relasi/navigation |
| **`$apply`** | Aggregation dan transformation (OData v4) |

---

## 📚 Referensi

- [CAP Services Documentation](https://cap.cloud.sap/docs/guides/providing-services)
- [OData v4 Specification](https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html)
- [CAP Event Handlers](https://cap.cloud.sap/docs/node.js/core-services)
- [OData Query Cheat Sheet](https://www.odata.org/getting-started/basic-tutorial/)

---

⬅️ **Prev:** [Hari 2 — Core Data Services](../Day2-CDS-CoreDataServices/README.md)  
➡️ **Next:** [Hari 4 — SAP Fiori & UI5](../Day4-Fiori-UI5/README.md)
