# ✅ Hands-on 1: Data Model Purchase Order (Pengganti Z-table) — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 7 April 2026  
> **CDS Version:** @sap/cds v9.8.4

---

## Tujuan

Membangun **5 custom entities** di CDS sebagai pengganti Z-table (ZPO_HEADER, ZPO_ITEM, Z_SUPPLIER, Z_MATERIAL, ZPO_STATUS_LOG) dengan pendekatan **Clean Core** — data disimpan di BTP, bukan di dalam S/4HANA core.

## Mapping Z-table → CDS Entity

| Z-table (ABAP) | CDS Entity (CAP) | Fungsi |
|:----------------|:------------------|:-------|
| `ZPO_HEADER` | `PurchaseOrders` | Header PO (nomor, status, supplier, total) |
| `ZPO_ITEM` | `PurchaseOrderItems` | Item baris PO (material, qty, harga) |
| `Z_SUPPLIER` | `Suppliers` | Master data supplier (nama, kota, email) |
| `Z_MATERIAL` | `Materials` | Master data material (deskripsi, UoM, harga) |
| `ZPO_STATUS_LOG` | `POStatusHistory` | Audit trail perubahan status PO |

---

## Langkah yang Dilakukan

### Langkah 1: Buat CDS Schema

**File dibuat: `db/po-schema.cds`**

```cds
namespace com.tecrise.procurement;

using { Currency, managed, cuid } from '@sap/cds/common';

// ============================================
// CUSTOM TYPES (Pengganti ABAP Domain/Data Element)
// ============================================

type POStatus : String enum {
    Draft     = 'D';
    Open      = 'O';
    Posted    = 'P';
    Approved  = 'A';
    Rejected  = 'R';
    Cancelled = 'X';
}

type UoM : String(3) enum {
    PC  = 'PC';
    KG  = 'KG';
    L   = 'L';
    M   = 'M';
    BOX = 'BOX';
    SET = 'SET';
}

// ============================================
// ENTITY: Suppliers (Pengganti Z_SUPPLIER / LFA1)
// ============================================
entity Suppliers : cuid, managed {
    supplierNo   : String(10)  @title: 'Supplier Number';
    name         : String(100) @title: 'Supplier Name'  not null;
    address      : String(200) @title: 'Address';
    city         : String(50)  @title: 'City';
    country      : String(3)   @title: 'Country';
    phone        : String(20)  @title: 'Phone';
    email        : String(100) @title: 'Email';
    isActive     : Boolean     @title: 'Active'  default true;
    purchaseOrders : Association to many PurchaseOrders on purchaseOrders.supplier = $self;
}

// ============================================
// ENTITY: Materials (Pengganti Z_MATERIAL / MARA)
// ============================================
entity Materials : cuid, managed {
    materialNo   : String(18)  @title: 'Material Number';
    description  : String(200) @title: 'Description'  not null;
    category     : String(50)  @title: 'Category';
    uom          : UoM         @title: 'Unit of Measure'  default 'PC';
    unitPrice    : Decimal(15,2) @title: 'Unit Price';
    currency     : Currency;
    isActive     : Boolean     @title: 'Active'  default true;
}

// ============================================
// ENTITY: PurchaseOrders (Pengganti ZPO_HEADER / EKKO)
// ============================================
entity PurchaseOrders : cuid, managed {
    poNumber         : String(10)    @title: 'PO Number'  @readonly;
    description      : String(200)   @title: 'Description';
    supplier         : Association to Suppliers @title: 'Supplier' @assert.target;
    status           : POStatus      @title: 'Status'  default 'D';
    orderDate        : Date          @title: 'Order Date';
    deliveryDate     : Date          @title: 'Delivery Date';
    totalAmount      : Decimal(15,2) @title: 'Total Amount'  @readonly default 0;
    currency         : Currency;
    notes            : String(1000)  @title: 'Notes';
    statusCriticality: Integer       @title: 'Status Criticality' @UI.Hidden default 0;
    items            : Composition of many PurchaseOrderItems on items.parent = $self;
}

// ============================================
// ENTITY: PurchaseOrderItems (Pengganti ZPO_ITEM / EKPO)
// ============================================
entity PurchaseOrderItems : cuid {
    parent       : Association to PurchaseOrders @title: 'PO Header';
    itemNo       : Integer       @title: 'Item Number';
    material     : Association to Materials @title: 'Material' @assert.target;
    description  : String(200)   @title: 'Item Description';
    quantity     : Decimal(13,3) @title: 'Quantity'  @assert.range: [ 0.001, 999999 ];
    uom          : UoM           @title: 'UoM'  default 'PC';
    unitPrice    : Decimal(15,2) @title: 'Unit Price';
    netAmount    : Decimal(15,2) @title: 'Net Amount'  @readonly;
    currency     : Currency;
}

// ============================================
// ENTITY: PO Status History (Audit Trail)
// ============================================
entity POStatusHistory : cuid, managed {
    purchaseOrder : Association to PurchaseOrders;
    oldStatus     : POStatus  @title: 'Old Status';
    newStatus     : POStatus  @title: 'New Status';
    changedBy     : String(100) @title: 'Changed By';
    changedAt     : Timestamp   @title: 'Changed At';
    comment       : String(500) @title: 'Comment';
}
```

**Penjelasan Key Concepts:**

| CDS Feature | ABAP Equivalent | Keuntungan |
|:------------|:----------------|:-----------|
| `cuid` | `GUID_CREATE` manual | UUID auto-generated sebagai key |
| `managed` | `SY-UNAME, SY-DATUM` manual | createdBy, createdAt, modifiedBy, modifiedAt otomatis |
| `type ... enum` | Domain fixed values (SE11) | Type-safe enum values |
| `Association to` | Foreign key manual | Auto FK, OData navigation property |
| `Composition of many` | Header-Item table pair | Cascade delete, deep insert/read |
| `@assert.target` | `CHECK TABLE` | FK validation otomatis saat INSERT |
| `@assert.range` | `CHECK` constraint | Min/max validation |
| `@readonly` | Protected field | Tidak bisa diubah via OData |

---

### Langkah 2: Buat Sample Data (CSV Seed)

> Sama seperti ABAP test data di `SM30` atau `SE16`, CAP menggunakan file CSV untuk initial data.
> Nama file harus sesuai pattern: `<namespace>-<EntityName>.csv`

**File: `db/data/com.tecrise.procurement-Suppliers.csv`**

```csv
ID;supplierNo;name;address;city;country;phone;email;isActive
f47ac10b-58cc-4372-a567-0e02b2c3d479;SUP-001;PT Baja Nusantara;Jl. Industri No. 45;Cikarang;ID;+62-21-8900123;baja@nusantara.co.id;true
550e8400-e29b-41d4-a716-446655440001;SUP-002;CV Mitra Logistik;Jl. Pelabuhan Raya 12;Surabaya;ID;+62-31-5551234;info@mitralogistik.id;true
550e8400-e29b-41d4-a716-446655440002;SUP-003;PT Kimia Farma Supply;Jl. Veteran No. 10;Jakarta;ID;+62-21-3841234;supply@kimiafarma.co.id;true
550e8400-e29b-41d4-a716-446655440003;SUP-004;UD Sumber Makmur;Jl. Pasar Baru 88;Semarang;ID;+62-24-3551122;sumber@makmur.co.id;true
550e8400-e29b-41d4-a716-446655440004;SUP-005;PT Global Parts Indonesia;Jl. Gatot Subroto Kav. 21;Jakarta;ID;+62-21-5201888;order@globalparts.co.id;true
```

**File: `db/data/com.tecrise.procurement-Materials.csv`**

```csv
ID;materialNo;description;category;uom;unitPrice;currency_code;isActive
a1b2c3d4-e5f6-7890-abcd-ef1234567001;MAT-10001;Bearing SKF 6205;Spare Parts;PC;125000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567002;MAT-10002;Hydraulic Oil ISO 46 (20L);Lubricants;L;450000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567003;MAT-10003;V-Belt Type B68;Spare Parts;PC;85000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567004;MAT-10004;Safety Helmet (Yellow);Safety;PC;75000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567005;MAT-10005;Welding Rod E6013 (5Kg);Consumables;KG;95000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567006;MAT-10006;Pipa Besi 2" Sch 40 (6M);Raw Materials;M;320000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567007;MAT-10007;Kabel NYY 4x10mm² (per M);Electrical;M;185000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567008;MAT-10008;Glove Latex Industrial;Safety;BOX;45000.00;IDR;true
```

**File: `db/data/com.tecrise.procurement-PurchaseOrders.csv`**

```csv
ID;poNumber;description;supplier_ID;status;orderDate;deliveryDate;totalAmount;currency_code;notes
b1c2d3e4-f5a6-7890-bcde-f12345670001;PO-240001;Pengadaan Spare Parts Q1;f47ac10b-58cc-4372-a567-0e02b2c3d479;P;2024-01-15;2024-02-15;1295000.00;IDR;Urgent untuk maintenance shutdown
b1c2d3e4-f5a6-7890-bcde-f12345670002;PO-240002;Pembelian Safety Equipment;550e8400-e29b-41d4-a716-446655440002;A;2024-02-01;2024-02-28;570000.00;IDR;Untuk tim lapangan baru
b1c2d3e4-f5a6-7890-bcde-f12345670003;PO-240003;Restock Lubricants Pabrik 2;550e8400-e29b-41d4-a716-446655440001;O;2024-03-10;2024-04-10;1800000.00;IDR;
b1c2d3e4-f5a6-7890-bcde-f12345670004;PO-240004;Pengadaan Electrical Cable;550e8400-e29b-41d4-a716-446655440004;D;2024-03-20;2024-04-20;0.00;IDR;Draft - belum lengkap
```

**File: `db/data/com.tecrise.procurement-PurchaseOrderItems.csv`**

```csv
ID;parent_ID;itemNo;material_ID;description;quantity;uom;unitPrice;netAmount;currency_code
c1d2e3f4-a5b6-7890-cdef-012345670001;b1c2d3e4-f5a6-7890-bcde-f12345670001;10;a1b2c3d4-e5f6-7890-abcd-ef1234567001;Bearing SKF 6205;5;PC;125000.00;625000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670002;b1c2d3e4-f5a6-7890-bcde-f12345670001;20;a1b2c3d4-e5f6-7890-abcd-ef1234567003;V-Belt Type B68;4;PC;85000.00;340000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670003;b1c2d3e4-f5a6-7890-bcde-f12345670001;30;a1b2c3d4-e5f6-7890-abcd-ef1234567005;Welding Rod E6013 (5Kg);2;KG;95000.00;190000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670004;b1c2d3e4-f5a6-7890-bcde-f12345670001;40;a1b2c3d4-e5f6-7890-abcd-ef1234567008;Glove Latex Industrial;3;BOX;45000.00;135000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670005;b1c2d3e4-f5a6-7890-bcde-f12345670002;10;a1b2c3d4-e5f6-7890-abcd-ef1234567004;Safety Helmet (Yellow);4;PC;75000.00;300000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670006;b1c2d3e4-f5a6-7890-bcde-f12345670002;20;a1b2c3d4-e5f6-7890-abcd-ef1234567008;Glove Latex Industrial;6;BOX;45000.00;270000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670007;b1c2d3e4-f5a6-7890-bcde-f12345670003;10;a1b2c3d4-e5f6-7890-abcd-ef1234567002;Hydraulic Oil ISO 46 (20L);4;L;450000.00;1800000.00;IDR
```

---

### Langkah 3: Verifikasi — cds watch

```bash
$ cds watch
```

**✅ Output terminal:**

```
[cds] - loaded model from 5 file(s):

  db/po-schema.cds
  srv/po-service.cds
  app/po/annotations.cds
  node_modules/@sap/cds/common.cds
  ...

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from db/data/com.tecrise.procurement-Suppliers.csv
  > init from db/data/com.tecrise.procurement-Materials.csv
  > init from db/data/com.tecrise.procurement-PurchaseOrders.csv
  > init from db/data/com.tecrise.procurement-PurchaseOrderItems.csv
/> successfully deployed to in-memory database.

[cds] - serving PurchaseOrderService { at: ['/odata/v4/po'] }

[cds] - server listening on { url: 'http://localhost:4004' }
```

### Verifikasi Data — Suppliers

```bash
$ curl http://localhost:4004/odata/v4/po/Suppliers?\$select=supplierNo,name,city
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#Suppliers(supplierNo,name,city)",
  "value": [
    { "supplierNo": "SUP-001", "name": "PT Baja Nusantara", "city": "Cikarang" },
    { "supplierNo": "SUP-002", "name": "CV Mitra Logistik", "city": "Surabaya" },
    { "supplierNo": "SUP-003", "name": "PT Kimia Farma Supply", "city": "Jakarta" },
    { "supplierNo": "SUP-004", "name": "UD Sumber Makmur", "city": "Semarang" },
    { "supplierNo": "SUP-005", "name": "PT Global Parts Indonesia", "city": "Jakarta" }
  ]
}
```

### Verifikasi Data — Materials

```bash
$ curl http://localhost:4004/odata/v4/po/Materials?\$select=materialNo,description,category,unitPrice
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#Materials(materialNo,description,category,unitPrice)",
  "value": [
    { "materialNo": "MAT-10001", "description": "Bearing SKF 6205", "category": "Spare Parts", "unitPrice": 125000. },
    { "materialNo": "MAT-10002", "description": "Hydraulic Oil ISO 46 (20L)", "category": "Lubricants", "unitPrice": 450000 },
    { "materialNo": "MAT-10003", "description": "V-Belt Type B68", "category": "Spare Parts", "unitPrice": 85000 },
    { "materialNo": "MAT-10004", "description": "Safety Helmet (Yellow)", "category": "Safety", "unitPrice": 75000 },
    { "materialNo": "MAT-10005", "description": "Welding Rod E6013 (5Kg)", "category": "Consumables", "unitPrice": 95000 },
    { "materialNo": "MAT-10006", "description": "Pipa Besi 2\" Sch 40 (6M)", "category": "Raw Materials", "unitPrice": 320000 },
    { "materialNo": "MAT-10007", "description": "Kabel NYY 4x10mm² (per M)", "category": "Electrical", "unitPrice": 185000 },
    { "materialNo": "MAT-10008", "description": "Glove Latex Industrial", "category": "Safety", "unitPrice": 45000 }
  ]
}
```

### Verifikasi Data — PO dengan Items & Supplier ($expand)

```bash
$ curl "http://localhost:4004/odata/v4/po/PurchaseOrders?\$expand=supplier(\$select=name),items(\$select=itemNo,description,quantity,netAmount)&\$orderby=poNumber"
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#PurchaseOrders(supplier(name),items(itemNo,description,quantity,netAmount))",
  "value": [
    {
      "poNumber": "PO-240001",
      "description": "Pengadaan Spare Parts Q1",
      "status": "P",
      "totalAmount": 1295000,
      "supplier": { "name": "PT Baja Nusantara" },
      "items": [
        { "itemNo": 10, "description": "Bearing SKF 6205", "quantity": 5, "netAmount": 625000 },
        { "itemNo": 20, "description": "V-Belt Type B68", "quantity": 4, "netAmount": 340000 },
        { "itemNo": 30, "description": "Welding Rod E6013 (5Kg)", "quantity": 2, "netAmount": 190000 },
        { "itemNo": 40, "description": "Glove Latex Industrial", "quantity": 3, "netAmount": 135000 }
      ]
    },
    {
      "poNumber": "PO-240002",
      "description": "Pembelian Safety Equipment",
      "status": "A",
      "totalAmount": 570000,
      "supplier": { "name": "PT Kimia Farma Supply" },
      "items": [
        { "itemNo": 10, "description": "Safety Helmet (Yellow)", "quantity": 4, "netAmount": 300000 },
        { "itemNo": 20, "description": "Glove Latex Industrial", "quantity": 6, "netAmount": 270000 }
      ]
    },
    {
      "poNumber": "PO-240003",
      "description": "Restock Lubricants Pabrik 2",
      "status": "O",
      "totalAmount": 1800000,
      "supplier": { "name": "CV Mitra Logistik" },
      "items": [
        { "itemNo": 10, "description": "Hydraulic Oil ISO 46 (20L)", "quantity": 4, "netAmount": 1800000 }
      ]
    },
    {
      "poNumber": "PO-240004",
      "description": "Pengadaan Electrical Cable",
      "status": "D",
      "totalAmount": 0,
      "supplier": { "name": "PT Global Parts Indonesia" },
      "items": []
    }
  ]
}
```

### Verifikasi Metadata ($metadata)

```bash
$ curl http://localhost:4004/odata/v4/po/\$metadata | head -50
```

**✅ Metadata menunjukkan:**
- EntityType: `PurchaseOrders` dengan NavigationProperty `items` dan `supplier`
- EntityType: `PurchaseOrderItems` dengan NavigationProperty `material`
- EnumType: `POStatus` (D, O, P, A, R, X)
- EnumType: `UoM` (PC, KG, L, M, BOX, SET)
- Action: `postPO`, `cancelPO`, `approvePO`, `rejectPO`
- Function: `getSupplierPOSummary`

---

## Ringkasan Verifikasi

| Item | Status | Detail |
|:-----|:-------|:-------|
| CDS compile | ✅ | Model loaded dari `db/po-schema.cds` |
| DB deploy | ✅ | 4 CSV files loaded ke in-memory SQLite |
| Suppliers | ✅ | 5 records — PT Baja, CV Mitra, Kimia Farma, UD Sumber, Global Parts |
| Materials | ✅ | 8 records — Bearing, Oil, V-Belt, Helmet, Welding Rod, Pipa, Kabel, Glove |
| PurchaseOrders | ✅ | 4 records — PO-240001 s/d PO-240004 |
| PurchaseOrderItems | ✅ | 7 records — tersebar di 3 PO (PO-240004 belum punya items) |
| $expand | ✅ | Deep read PO + supplier + items berfungsi |
| Custom types | ✅ | POStatus enum (D/O/P/A/R/X) dan UoM enum (PC/KG/L/M/BOX/SET) |
| Composition | ✅ | Items terikat ke PO via Composition (cascade) |
| Association | ✅ | Supplier dan Material sebagai referensi |

---

## Kesimpulan

- ✅ **5 entities berhasil dibuat** sebagai pengganti Z-table
- ✅ **Custom types** (POStatus, UoM) berfungsi sebagai Domain equivalent
- ✅ **`cuid` + `managed`** menggantikan ABAP manual GUID dan audit fields
- ✅ **Composition** (PO → Items) dan **Association** (PO → Supplier) berjalan
- ✅ **CSV seed data** dengan konteks bisnis Indonesia dimuat otomatis
- ✅ **OData V4 service** auto-generated dari CDS model
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
