# ✅ Hands-on 1: Extend CDS Model — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026  
> **CDS Version:** @sap/cds v9.8.4

---

## Langkah yang Dilakukan

### 1a. Extend Entity Books & Authors

**File dibuat: `db/extensions.cds`**

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

### 1b. Custom Type, Aspect & Entity Baru

**File: `db/extensions.cds`** (lanjutan)

```cds
// Custom type — enum Rating
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
service CatalogService @(path: '/catalog') {
    @readonly entity Books    as projection on db.Books;
    @readonly entity Authors  as projection on db.Authors;
    @readonly entity Reviews  as projection on db.Reviews;

    action submitOrder(bookID: UUID, amount: Integer) returns { orderID: UUID; status: String; message: String; };
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

### Verifikasi: cds watch

```
$ cds watch

[cds] - loaded model from ... file(s)
[cds] - connect to db > sqlite { url: ':memory:' }
/> successfully deployed to in-memory database.

[cds] - serving CatalogService { at: ['/odata/v4/catalog'] }
[cds] - serving AdminService   { at: ['/odata/v4/admin'] }
[cds] - server listening on { url: 'http://localhost:4004' }
```

**Pengecekan di browser:**
- ✅ `http://localhost:4004` — entity Reviews, Orders, OrderItems muncul di index
- ✅ `http://localhost:4004/odata/v4/catalog/$metadata` — field isbn, language, pages, publisher terlihat di entity Books

---

## Kesimpulan

- ✅ `extend entity` berhasil menambah field tanpa ubah schema.cds asli
- ✅ Custom type `Rating` enum berfungsi
- ✅ Aspect `auditable` ter-apply ke entity Reviews
- ✅ Composition `Orders → OrderItems` terbentuk (cascade relationship)
- ✅ Semua entity baru muncul di OData service
