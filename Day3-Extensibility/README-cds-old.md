# 📗 Hari 2: Core Data Services (CDS) — Data Modelling

> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 1, CAP project sudah berjalan

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 2, peserta mampu:
- Memahami konsep dan filosofi SAP CDS
- Membuat entity definitions dengan berbagai tipe data
- Mendefinisikan associations dan compositions antar entity
- Menggunakan built-in types, aspects, dan mixins
- Menerapkan CDS annotations untuk dokumentasi dan behavior
- Menambahkan sample data dengan CSV files

---

## 📅 Jadwal Hari 2

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 1 | 15 menit |
| 09:15 – 10:30 | **Teori: CDS Fundamentals** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: Entity & Types** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Associations & Compositions** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: Annotations & Sample Data** | 105 menit |
| 16:30 – 17:00 | Review, Quiz & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: CDS Fundamentals

### Apa itu CDS?

**Core Data Services (CDS)** adalah bahasa definisi data declarative yang dikembangkan SAP. CDS digunakan untuk:

```
CDS digunakan untuk:
├── Data Modelling     → Mendefinisikan struktur data (entities, types)
├── Service Definitions → Expose data sebagai API (OData/REST)
├── Annotations        → Menambahkan metadata & behavior
└── Access Control     → Role-based data restriction
```

### CDS dalam Ekosistem CAP

```
CDS Files (.cds)
├── db/schema.cds        → Data models (persistent layer)
├── srv/service.cds      → Service definitions (API layer)
└── app/annotations.cds  → UI annotations (presentation layer)
        ↓
CDS Compiler
        ↓
├── SQL DDL              → Untuk database (HANA/SQLite)
├── OData EDMX           → Untuk OData services
└── JSON Metadata        → Untuk runtime
```

### Tipe-tipe Artefak CDS

| Artefak | Keyword | Keterangan |
|---------|---------|------------|
| Entity | `entity` | Tabel database / data object |
| Type | `type` | Custom type definition |
| View | `view` | Virtual / computed data |
| Service | `service` | API endpoint |
| Annotation | `annotate` | Metadata tambahan |
| Aspect | `aspect` | Reusable mixin/fragment |

---

## 🛠️ Hands-on 1: Entity Definitions

### File: `db/schema.cds`

```cds
namespace com.tecrise.bookshop;

using { Currency, managed, cuid } from '@sap/cds/common';

// ============================================
// ENTITY: Books
// ============================================
entity Books : cuid, managed {
    // Basic fields
    title        : String(150) not null;
    descr        : String(1000);
    author       : Association to Authors;
    genre        : Association to Genres;
    stock        : Integer default 0;
    price        : Decimal(10,2);
    currency     : Currency;
    image        : LargeBinary @Core.MediaType : 'image/png';
    
    // Derived: relasi ke orders
    orders       : Association to many OrderItems on orders.book = $self;
}

// ============================================
// ENTITY: Authors
// ============================================
entity Authors : cuid, managed {
    name         : String(100) not null;
    dateOfBirth  : Date;
    dateOfDeath  : Date;
    placeOfBirth : String;
    placeOfDeath : String;
    
    // Back-link ke books
    books        : Association to many Books on books.author = $self;
}

// ============================================
// ENTITY: Genres
// ============================================
entity Genres : CodeList {
    parent       : Association to Genres;
    children     : Composition of many Genres on children.parent = $self;
}

// ============================================
// ENTITY: Orders (dengan Compositions)
// ============================================
entity Orders : cuid, managed {
    OrderNo      : String @title: 'Order Number';
    buyer        : String @title: 'Buyer Name';
    currency     : Currency;
    items        : Composition of many OrderItems on items.parent = $self;
    total        : Decimal(10,2) @title: 'Total Amount';
}

entity OrderItems : cuid {
    parent       : Association to Orders;
    book         : Association to Books;
    amount       : Integer;
    netAmount    : Decimal(10,2);
}
```

### Penjelasan Built-in Aspects

```cds
// 'cuid' → Menambahkan field: ID (UUID, generated)
// 'managed' → Menambahkan fields:
//   - createdAt  : Timestamp
//   - createdBy  : String
//   - modifiedAt : Timestamp
//   - modifiedBy : String

// 'CodeList' → Menambahkan fields:
//   - code : String (key)
//   - name : localized String
//   - descr: localized String
```

---

## 🛠️ Hands-on 2: Types & Custom Definitions

### Custom Types

```cds
// File: db/types.cds
namespace com.tecrise.bookshop;

// Custom scalar type
type BookStatus : String enum {
    Available   = 'A';
    OutOfStock  = 'O';
    Discontinued = 'D';
}

// Structured type (reusable)
type Address {
    street  : String(100);
    city    : String(50);
    country : String(3);  // ISO 3166-1 alpha-3
    zipCode : String(10);
}

// Custom aspect (mixin)
aspect Auditable {
    reviewedAt : Timestamp;
    reviewedBy : String;
    comment    : String(500);
}

// Apply aspect ke entity
entity Books : cuid, managed, Auditable {
    title  : String;
    status : BookStatus default 'A';
    // ...
}
```

---

## 🛠️ Hands-on 3: Associations & Compositions

### Perbedaan Association vs Composition

```
Association  → Referensi ke entity lain (relasi loosely-coupled)
              → Separate lifecycle, dapat berdiri sendiri
              → Contoh: Book → Author

Composition  → Bagian dari entity parent (relasi strongly-coupled)
              → Lifecycle terikat ke parent
              → Contoh: Order → OrderItems
```

### Contoh Lengkap Associations

```cds
entity Books : cuid {
    title   : String;
    
    // 1. To-one association (foreign key)
    author  : Association to Authors;
    
    // 2. To-many association (back-link)
    reviews : Association to many Reviews on reviews.book = $self;
    
    // 3. Managed association (explicit FK)
    category : Association to Categories on category.ID = categoryID;
    categoryID : UUID;
}

entity Reviews : cuid {
    // 4. Association with on-condition
    book    : Association to Books;
    rating  : Integer @assert.range: [1, 5];
    text    : String(1000);
}

entity Orders : cuid {
    buyer   : String;
    
    // 5. Composition (deep insert/update/delete)
    items   : Composition of many {
        book    : Association to Books;
        qty     : Integer;
        price   : Decimal(10,2);
    }
}
```

---

## 🛠️ Hands-on 4: CDS Annotations

### Annotations untuk Validasi

```cds
entity Products : cuid {
    name      : String @mandatory;
    price     : Decimal @assert.range: [0, 99999.99];
    category  : String @assert.enum: ['BOOK','MUSIC','VIDEO'];
    email     : String @assert.format: '^[\w.]+@[\w.]+\.\w+$';
    stock     : Integer @readonly;
}
```

### Annotations untuk UI (Fiori)

```cds
annotate Books with @(
    UI: {
        // List page configuration
        LineItem: [
            { Value: title,        Label: 'Title'  },
            { Value: author.name,  Label: 'Author' },
            { Value: price,        Label: 'Price'  },
            { Value: stock,        Label: 'Stock'  }
        ],
        // Detail page header
        HeaderInfo: {
            TypeName       : 'Book',
            TypeNamePlural : 'Books',
            Title          : { Value: title },
            Description    : { Value: author.name }
        },
        // Detail page field groups
        FieldGroup #Details: {
            Label: 'Book Details',
            Data: [
                { Value: descr },
                { Value: genre.name },
                { Value: price },
                { Value: currency_code }
            ]
        }
    }
);
```

### Annotations untuk OData

```cds
annotate Books with @(
    odata.draft.enabled: true,  // Enable draft handling
    Capabilities: {
        SearchRestrictions.Searchable: true,
        FilterRestrictions.FilterExpressionRestrictions: [{
            Property: 'price',
            AllowedExpressions: 'MultiValue'
        }]
    }
);
```

---

## 🛠️ Hands-on 5: Sample Data dengan CSV

### Struktur Folder Data

```
db/
└── data/
    ├── com.tecrise.bookshop-Books.csv
    ├── com.tecrise.bookshop-Authors.csv
    └── com.tecrise.bookshop-Genres.csv
```

### File: `db/data/com.tecrise.bookshop-Authors.csv`

```csv
ID,name,dateOfBirth,placeOfBirth
8d4d1e9b-bb20-4d9a-b4ce-c362d8b12f51,Emily Brontë,1818-07-30,Thornton
df0d2ad5-f3a1-4c2d-86c6-e7f97e8e27c1,Charlotte Brontë,1816-04-21,Thornton
7c8de503-4879-4e2e-b68e-efe0a0b9484c,Edgar Allan Poe,1809-01-19,Boston
b1c5d8f9-3a2e-4f7d-91b6-e0a9c7d8e5f2,Mark Twain,1835-11-30,Florida
```

### File: `db/data/com.tecrise.bookshop-Books.csv`

```csv
ID,title,author_ID,stock,price,currency_code
421fc377-b1f0-485c-b3b9-7bb3c1c16a58,Wuthering Heights,8d4d1e9b-bb20-4d9a-b4ce-c362d8b12f51,100,14.95,USD
ad0f73e9-5cb0-4f35-b2a0-5b21c7d3e4b8,Jane Eyre,df0d2ad5-f3a1-4c2d-86c6-e7f97e8e27c1,75,12.50,USD
fdf91c00-e13a-4b71-bd67-a7c14ef29b20,The Raven,7c8de503-4879-4e2e-b68e-efe0a0b9484c,150,9.99,USD
b3d79f50-a9c8-4b6a-90d2-e1f3b5c7d9e1,The Adventures of Tom Sawyer,b1c5d8f9-3a2e-4f7d-91b6-e0a9c7d8e5f2,200,11.25,USD
```

### Load Data di Runtime

```bash
# CAP otomatis load CSV saat startup
cds watch

# Verifikasi data tersedia
# Buka: http://localhost:4004/catalog/Books
```

---

## 📝 Latihan Mandiri Hari 2

### Exercise 2.1: Tambah Entity Baru
Buat entity `Publishers` dengan fields:
- `name`, `country`, `foundedYear`, `website`
- Tambahkan association dari `Books` ke `Publishers`

### Exercise 2.2: Custom Type
Buat custom type `Rating` (Integer, range 1-5) dan gunakan di entity `Reviews`

### Exercise 2.3: Sample Data
Tambahkan minimal 5 baris data di CSV untuk entity `Books` dan `Authors`

### Exercise 2.4: Annotations
Tambahkan UI annotations untuk entity `Authors` agar tampil di list view dengan columns: `name`, `dateOfBirth`, `placeOfBirth`

---

## 🔑 Key Concepts Hari 2

| Konsep | Penjelasan |
|--------|------------|
| **Entity** | Representasi tabel database dalam CDS |
| **Aspect** | Reusable fragment yang bisa di-mix ke entity |
| **Association** | Relasi referensial antar entity (loose coupling) |
| **Composition** | Relasi kepemilikan (tight coupling, cascading) |
| **Annotation** | Metadata yang mengubah behavior runtime/UI |
| **CodeList** | Built-in aspect untuk master data/lookup tables |
| **managed** | Auto-fill audit fields (createdAt, modifiedAt, dll) |

---

## 🧪 Quick Quiz

1. Apa perbedaan `Association` dan `Composition`?
2. Field apa saja yang ditambahkan oleh aspect `managed`?
3. Bagaimana cara menambahkan sample data di CAP?
4. Apa fungsi `@mandatory` annotation?

---

## 📚 Referensi

- [CAP CDS Reference](https://cap.cloud.sap/docs/cds/cdl)
- [CDS Built-in Types](https://cap.cloud.sap/docs/cds/types)
- [CDS Annotations](https://cap.cloud.sap/docs/cds/annotations)
- [CAP Samples GitHub](https://github.com/SAP-samples/cloud-cap-samples)

---

⬅️ **Prev:** [Hari 1 — BTP Fundamentals](../Day1-BTP-Fundamentals/README.md)  
➡️ **Next:** [Hari 3 — OData Services](../Day3-OData-Services/README.md)
