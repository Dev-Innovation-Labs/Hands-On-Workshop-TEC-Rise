# Hands-on 1: Project Setup & CDS Data Model

> **Durasi:** ~30 menit  
> **Prerequisite:** Node.js ≥ 18, @sap/cds-dk (`npm i -g @sap/cds-dk`), VS Code + SAP CDS Extension

---

## Tujuan

Membuat **CAP project baru** dengan CDS data model sebagai **Z-table replacement** — staging table untuk PO Request yang nantinya akan di-post ke SAP S/4HANA real.

### Mapping Z-table ABAP → CDS Entity

| Z-table (ABAP) | CDS Entity (CAP) | Fungsi |
|:---|:---|:---|
| `ZPO_REQ_HEADER` | `PORequests` | Header PO request (nomor, status, supplier, total) |
| `ZPO_REQ_ITEM` | `PORequestItems` | Item baris PO (material, qty, harga, plant) |

> **Clean Core Approach:** Data disimpan di BTP (bukan di S/4HANA core). S/4HANA hanya diakses saat posting via OData API.

---

## Langkah 1: Inisialisasi CAP Project

```bash
# Buat folder project
mkdir -p Day3-Extensibility/po-project
cd Day3-Extensibility/po-project

# Inisialisasi CAP
cds init --add hana

# Install dependencies
npm install @sap/cds @cap-js/hana dotenv
npm install --save-dev @cap-js/sqlite
```

## Langkah 2: Konfigurasi package.json

Buka `package.json` dan **ganti seluruh isinya** dengan:

```json
{
  "name": "po-project",
  "version": "1.0.0",
  "description": "Day 3: Clean Core Side-by-Side Extension — PO Request Z-table → Post to SAP S/4HANA",
  "dependencies": {
    "@cap-js/hana": "^2",
    "@sap/cds": "^9",
    "dotenv": "^16"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^2"
  },
  "scripts": {
    "start": "cds-serve",
    "watch": "cds watch",
    "watch:hybrid": "cds watch --profile hybrid",
    "build": "cds build --production",
    "deploy:hana": "cds deploy --to hana"
  },
  "cds": {
    "fiori": {
      "lean_draft": true
    },
    "requires": {
      "db": {
        "kind": "sql"
      }
    },
    "[development]": {
      "requires": {
        "db": {
          "kind": "sqlite",
          "impl": "@cap-js/sqlite",
          "credentials": {
            "url": ":memory:"
          }
        }
      }
    },
    "[hybrid]": {
      "requires": {
        "db": {
          "kind": "hana",
          "impl": "@cap-js/hana",
          "deploy-format": "hdbtable"
        }
      }
    },
    "[production]": {
      "requires": {
        "db": {
          "kind": "hana",
          "impl": "@cap-js/hana",
          "deploy-format": "hdbtable"
        }
      }
    }
  },
  "sapux": [
    "app/po"
  ],
  "private": true
}
```

**Perhatikan 3 profile database:**

| Profile | Database | Kapan Dipakai |
|:---|:---|:---|
| `[development]` | SQLite in-memory | `cds watch` — lokal, cepat |
| `[hybrid]` | SAP HANA Cloud | `cds watch --profile hybrid` — Node.js lokal + HANA Cloud |
| `[production]` | SAP HANA Cloud | Deploy ke Cloud Foundry |

---

## Langkah 3: Buat CDS Schema — Z-table Replacement

Buat file `db/po-schema.cds`:

```cds
namespace com.tecrise.procurement;

using { managed, cuid } from '@sap/cds/common';

// ============================================
// Z-TABLE: PO Request Header (pengganti ZPO_REQ_HEADER)
// Staging table — data disimpan di BTP, bukan di S/4HANA
// ============================================
entity PORequests : cuid, managed {
    requestNo        : String(10)   @readonly @title: 'Request No';
    description      : String(200)  @title: 'Description';

    // SAP Organizational Data
    companyCode      : String(4)    @title: 'Company Code'     default '1710';
    purchasingOrg    : String(4)    @title: 'Purch. Org'       default '1710';
    purchasingGroup  : String(3)    @title: 'Purch. Group'     default '001';

    // Supplier (dari SAP master data)
    supplier         : String(10)   @title: 'Supplier ID';
    supplierName     : String(80)   @title: 'Supplier Name';

    // Dates & Amounts
    orderDate        : Date         @title: 'Order Date';
    deliveryDate     : Date         @title: 'Delivery Date';
    currency         : String(3)    @title: 'Currency'         default 'USD';
    totalAmount      : Decimal(15,2) @readonly @title: 'Total Amount' default 0;
    notes            : String(1000) @title: 'Notes';

    // Status: D=Draft, P=Posted to SAP, E=Error
    status           : String(1)    @title: 'Status'           default 'D';
    statusCriticality: Integer      @UI.Hidden                 default 0;

    // === SAP Integration Result ===
    sapPONumber      : String(10)   @readonly @title: 'SAP PO Number';
    sapPostDate      : DateTime     @readonly @title: 'SAP Post Date';
    sapPostMessage   : String(500)  @readonly @title: 'SAP Response';

    // Line Items
    items            : Composition of many PORequestItems on items.parent = $self;
}

// ============================================
// Z-TABLE: PO Request Items (pengganti ZPO_REQ_ITEM)
// ============================================
entity PORequestItems : cuid {
    parent           : Association to PORequests @title: 'PO Request';
    itemNo           : Integer       @title: 'Item No';
    materialNo       : String(40)    @title: 'Material';
    description      : String(200)   @title: 'Description';
    quantity         : Decimal(13,3)  @title: 'Quantity';
    uom              : String(3)     @title: 'UoM'              default 'PC';
    unitPrice        : Decimal(15,2) @title: 'Unit Price';
    netAmount        : Decimal(15,2) @readonly @title: 'Net Amount';
    currency         : String(3)     @title: 'Currency'         default 'USD';
    plant            : String(4)     @title: 'Plant'            default '1710';
    materialGroup    : String(9)     @title: 'Material Group'   default 'L001';
}
```

### Penjelasan Design CDS

| Konsep | Di CDS | Setara ABAP |
|:---|:---|:---|
| `cuid` | Auto-generate UUID ID | `SYSUUID_X16` |
| `managed` | Auto-fill `createdAt`, `createdBy`, `modifiedAt`, `modifiedBy` | `SY-UNAME`, `SY-DATUM` |
| `Composition of many` | Header → Items (dependent/cascade delete) | Foreign key relationship |
| `@readonly` | Computed field — tidak bisa diisi user | Protected field |
| `default '1710'` | Default value saat create | Default value di domain |
| `status : String(1)` | D=Draft, P=Posted, E=Error | Status DOMAIN di DDIC |

---

## Langkah 4: Buat Sample Data (CSV)

Buat folder `db/data/` kemudian buat file berikut.

**File: `db/data/com.tecrise.procurement-PORequests.csv`**

```csv
ID;requestNo;description;companyCode;purchasingOrg;purchasingGroup;supplier;supplierName;orderDate;deliveryDate;currency;totalAmount;notes;status;sapPONumber;sapPostMessage
b1c2d3e4-f5a6-7890-bcde-f12345670001;REQ-260001;Pengadaan Laptop Kantor Jakarta;1710;1710;001;17300001;Wahyu Amaldi (Domestic Supplier);2026-04-01;2026-05-01;USD;3020.00;Untuk tim operasional Coffee Plant;D;;
b1c2d3e4-f5a6-7890-bcde-f12345670002;REQ-260002;Pembelian Safety Equipment;1710;1710;001;17300002;Domestic US Supplier 2;2026-04-05;2026-05-05;USD;900.00;Untuk tim lapangan roasting plant;D;;
b1c2d3e4-f5a6-7890-bcde-f12345670003;REQ-260003;Pengadaan Office Equipment;1710;1710;001;17258002;Domestic US JV Partner 1;2026-03-15;2026-04-15;USD;6040.00;Sudah diposting ke SAP;P;4500000099;PO berhasil dibuat di SAP
```

**File: `db/data/com.tecrise.procurement-PORequestItems.csv`**

```csv
ID;parent_ID;itemNo;materialNo;description;quantity;uom;unitPrice;netAmount;currency;plant;materialGroup
c1d2e3f4-a5b6-7890-cdef-012345670001;b1c2d3e4-f5a6-7890-bcde-f12345670001;10;EWMS4-01;Small Part for Jakarta Office;10;PC;302.00;3020.00;USD;1710;L001
c1d2e3f4-a5b6-7890-cdef-012345670002;b1c2d3e4-f5a6-7890-bcde-f12345670002;10;EWMS4-02;Safety Equipment Fast-Moving;6;PC;75.00;450.00;USD;1710;L001
c1d2e3f4-a5b6-7890-cdef-012345670003;b1c2d3e4-f5a6-7890-bcde-f12345670002;20;EWMS4-01;Glove Latex Industrial;10;EA;45.00;450.00;USD;1710;L001
c1d2e3f4-a5b6-7890-cdef-012345670004;b1c2d3e4-f5a6-7890-bcde-f12345670003;10;EWMS4-01;Small Part for Office Equipment;20;PC;302.00;6040.00;USD;1710;L001
```

> **Data real SAP:** Material `EWMS4-01`, `EWMS4-02` dan Supplier `17300001`, `17300002`, `17258002` adalah data yang ada di S/4HANA system `sap.ilmuprogram.com` (Company Code 1710 — Andi Coffee).

---

## Langkah 5: Verifikasi — Jalankan Server

```bash
# Install semua dependencies
npm install

# Jalankan server lokal (SQLite in-memory)
cds watch
```

**Expected output:**

```
[cds] - loaded model from 1 file(s):
  db/po-schema.cds

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from db/data/com.tecrise.procurement-PORequests.csv
  > init from db/data/com.tecrise.procurement-PORequestItems.csv

[cds] - server listening on { url: 'http://localhost:4004' }
```

### Test Endpoint

Buka browser atau curl:

```bash
# Cek service metadata
curl http://localhost:4004/po/$metadata

# Cek data PORequests — harus ada 3 record dari CSV
curl -s http://localhost:4004/po/PORequests | python3 -m json.tool
```

**Expected result (3 records):**
```json
{
  "@odata.context": "$metadata#PORequests",
  "value": [
    {
      "requestNo": "REQ-260001",
      "description": "Pengadaan Laptop Kantor Jakarta",
      "status": "D",
      "totalAmount": 3020.00
    },
    {
      "requestNo": "REQ-260002",
      "description": "Pembelian Safety Equipment",
      "status": "D",
      "totalAmount": 900.00
    },
    {
      "requestNo": "REQ-260003",
      "description": "Pengadaan Office Equipment",
      "status": "P",
      "sapPONumber": "4500000099",
      "totalAmount": 6040.00
    }
  ]
}
```

---

## Struktur Project Saat Ini

```
po-project/
├── package.json              ← 3 database profiles
├── db/
│   ├── po-schema.cds         ← Z-table CDS model
│   └── data/
│       ├── ...PORequests.csv  ← 3 sample PO headers
│       └── ...PORequestItems.csv  ← 4 sample items
└── node_modules/
```

---

## Checkpoint

| # | Cek | Status |
|:--|:----|:-------|
| 1 | `cds watch` berjalan tanpa error | ☐ |
| 2 | `http://localhost:4004` menampilkan service index | ☐ |
| 3 | `/po/PORequests` mengembalikan 3 record | ☐ |
| 4 | `/po/PORequestItems` mengembalikan 4 record | ☐ |
| 5 | `/po/PORequests?$expand=items` menampilkan items per header | ☐ |

---

**Lanjut ke → [Hands-on 2: OData Service & SAP Integration](./handson-2-custom-handlers.md)**
