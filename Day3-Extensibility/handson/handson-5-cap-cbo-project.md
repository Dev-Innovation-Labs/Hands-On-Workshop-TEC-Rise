# Hands-on 5: CAP Project dengan CBO Backend (po-project-in-apps)

> **Durasi:** ~60 menit  
> **Prerequisite:** CBO sudah aktif ([Hands-on 4](handson-4-cbo-in-app.md)), Node.js ≥ 18, `@sap/cds-dk`  
> **Project:** `Day3-Extensibility/po-project-in-apps/`  
> **Database:** SAP CBO (ZZ1_WPOREQ + ZZ1_WPOREQI) — **bukan** HANA Cloud

---

## Tujuan

Membuat **CAP project kedua** yang fungsinya **identik** dengan `po-project`, tetapi:
- Data disimpan di **SAP CBO** (bukan HANA Cloud/SQLite)
- Tidak butuh **database tambahan** ($0 cost)
- CAP bertindak sebagai **proxy layer** (field mapping + business logic + Fiori UI)

---

## Perbedaan Arsitektur: po-project vs po-project-in-apps

### Architecture Comparison

```
┌─ po-project (Side-by-Side / BTP) ────────────────────────┐
│                                                           │
│  Fiori UI ──▶ CAP OData V4 ──▶ SQLite / HANA Cloud       │
│                    │                                      │
│                    │ postToSAP()                          │
│                    ▼                                      │
│              SAP OData V2 Client (sap-client.js)          │
│                    │                                      │
└────────────────────┼──────────────────────────────────────┘
                     ▼
              SAP S/4HANA (PO Create)

┌─ po-project-in-apps (In-App / CBO) ──────────────────────┐
│                                                           │
│  Fiori UI ──▶ CAP OData V4 ──▶ CBO OData V2 (cbo-client) │
│                    │              ▼                        │
│                    │         SAP CBO Table                 │
│                    │         (ZZ1_WPOREQ + ZZ1_WPOREQI)   │
│                    │                                      │
│                    │ postToSAP()                          │
│                    ▼                                      │
│              SAP OData V2 Client (sap-client.js)          │
│                    │                                      │
└────────────────────┼──────────────────────────────────────┘
                     ▼
              SAP S/4HANA (PO Create)
```

### Feature Comparison

| Aspek | po-project (BTP) | po-project-in-apps (CBO) |
|:------|:-----------------|:-------------------------|
| **Database** | SQLite (dev) / HANA Cloud (prod) | SAP CBO table (embedded) |
| **Biaya DB** | ~€693/bln (HANA paid) atau $0 (trial) | $0 (SAP license included) |
| **Dependencies** | `@sap/cds`, `@cap-js/hana`, `@cap-js/sqlite`, `dotenv` | `@sap/cds`, `dotenv` saja |
| **Persistence** | `cuid + managed` (CAP standard) | `@cds.persistence.skip` (no local DB) |
| **CRUD Handler** | BEFORE/AFTER hooks (DB auto-handle) | Custom ON handlers (semua manual) |
| **Field Mapping** | Direct (1:1 CDS → DB column) | Explicit mapping (CAP ↔ CBO property) |
| **Date Format** | ISO string (CAP native) | OData V2 `/Date(...)/` conversion |
| **NPM Scripts** | 5 commands (dev/hybrid/build/deploy) | 1 command (`cds watch`) |
| **Service Handler** | `class extends ApplicationService` | `cds.service.impl(function)` |
| **SAP Client** | ✅ Identik (`sap-client.js`) | ✅ Identik (`sap-client.js`) |
| **Fiori UI** | ✅ Identik (annotations + webapp) | ✅ Identik (annotations + webapp) |
| **postToSAP** | ✅ Same draft flow (5-step) | ✅ Same draft flow (5-step) |
| **Extra File** | — | `srv/lib/cbo-client.js` (CBO CRUD) |

### Code-Level Differences

| File | po-project | po-project-in-apps |
|:-----|:-----------|:-------------------|
| `db/po-schema.cds` | `entity PORequests : cuid, managed {}` | `@cds.persistence.skip entity PORequests {}` |
| `package.json` | `@cap-js/hana`, `@cap-js/sqlite`, 5 scripts | Hanya `@sap/cds`, `dotenv`, 1 script |
| `srv/po-service.cds` | Sama | + `testCBOConnection()` function |
| `srv/po-service.js` | `BEFORE/AFTER` hooks, DB auto-CRUD | `ON` handlers, manual CRUD via CBOClient |
| `srv/lib/sap-client.js` | Identik | Identik (copy) |
| `srv/lib/cbo-client.js` | Tidak ada | Field mapping + CBO OData V2 CRUD |
| `app/po/annotations.cds` | Identik | Identik |
| `app/po/webapp/*` | `com.tecrise.po` namespace | `com.tecrise.po.inapp` namespace |
| `db/data/*.csv` | 3 headers + 4 items seed | Tidak ada (data di SAP CBO) |
| `.cdsrc-private.json` | HANA binding (hybrid) | Tidak ada |
| `mta.yaml` | MTA descriptor (production) | Tidak ada (dev-only) |

---

## Langkah 1: Inisialisasi Project

```bash
# Buat folder project
mkdir -p Day3-Extensibility/po-project-in-apps
cd Day3-Extensibility/po-project-in-apps

# Inisialisasi package.json
cat > package.json << 'EOF'
{
  "name": "po-project-in-apps",
  "version": "1.0.0",
  "description": "PO Request Management — In-App Extensibility (CBO sebagai backend, tanpa HANA Cloud)",
  "dependencies": {
    "@sap/cds": "^9",
    "dotenv": "^16"
  },
  "devDependencies": {
    "@sap/cds-dk": "^9"
  },
  "scripts": {
    "watch": "cds watch"
  },
  "sapux": [
    "app/po"
  ]
}
EOF

# Install dependencies
npm install
```

### Perbedaan dari po-project

```diff
  // po-project/package.json
  "dependencies": {
    "@sap/cds": "^9",
+   "@cap-js/hana": "^2",    ← TIDAK ADA di in-apps
    "dotenv": "^16"
  },
  "devDependencies": {
    "@sap/cds-dk": "^9",
+   "@cap-js/sqlite": "^2"   ← TIDAK ADA di in-apps
  }
```

> **Kenapa lebih sedikit?** Karena tidak ada local database. CBO sudah menyediakan persistent storage di SAP.

---

## Langkah 2: Konfigurasi .env

```bash
cat > .env << 'EOF'
SAP_HOST=https://sap.ilmuprogram.com
SAP_CLIENT=777
SAP_USERNAME=wahyu.amaldi
SAP_PASSWORD=Pas671_ok12345
EOF
```

> **Sama persis** dengan po-project — credentials dipakai untuk CBO OData **dan** SAP PO creation.

---

## Langkah 3: CDS Schema — `@cds.persistence.skip`

```bash
mkdir -p db
```

Buat file `db/po-schema.cds`:

```cds
namespace com.tecrise.procurement;

/**
 * PO Request — In-App Extensibility (CBO)
 *
 * Data disimpan di SAP S/4HANA via Custom Business Object:
 *   Header → ZZ1_WPOREQ_CDS  (OData V2)
 *   Items  → ZZ1_WPOREQI_CDS (OData V2)
 *
 * @cds.persistence.skip — tidak ada local database.
 * CAP bertindak sebagai proxy layer (field mapping + business logic + Fiori UI).
 */

@cds.persistence.skip
entity PORequests {
    key ID              : UUID;
    requestNo           : String(20);
    description         : String(200);
    supplier            : String(20);
    supplierName        : String(80);
    companyCode         : String(20) default '1710';
    purchasingOrg       : String(20) default '1710';
    purchasingGroup     : String(20) default '001';
    orderDate           : Date;
    deliveryDate        : Date;
    currency            : String(20) default 'USD';
    totalAmount         : Decimal(10,2) @readonly;
    notes               : String(256);
    status              : String(20) default 'D';
    statusCriticality   : Integer @readonly;
    sapPONumber         : String(20) @readonly;
    sapPostMessage      : String(200) @readonly;
    items               : Composition of many PORequestItems on items.parent = $self;
}

@cds.persistence.skip
entity PORequestItems {
    key ID              : UUID;
    parent              : Association to PORequests;
    requestNo           : String(20);
    itemNo              : String(20);
    materialNo          : String(40);
    description         : String(200);
    quantity            : Decimal(10,2);
    uom                 : String(20) default 'PC';
    unitPrice           : Decimal(10,2);
    netAmount           : Decimal(10,2);
    currency            : String(20);
    plant               : String(20) default '1710';
    materialGroup       : String(20) default 'L001';
}
```

### Perbedaan Kunci dari po-project

```diff
- using { managed, cuid } from '@sap/cds/common';
  // → TIDAK import managed/cuid karena bukan local DB

- entity PORequests : cuid, managed {
+ @cds.persistence.skip
+ entity PORequests {
+     key ID  : UUID;    // mapped ke SAP_UUID (CBO auto-generate)

  // Field lengths juga berbeda:
- requestNo   : String(10);    // po-project (compact)
+ requestNo   : String(20);    // in-apps (CBO field = String 20)

- status      : String(1);     // po-project (D/P/E)
+ status      : String(20);    // in-apps (CBO field = String 20)

+ statusCriticality : Integer @readonly;  // computed di handler
```

> **`@cds.persistence.skip`** memberi tahu CAP: "Jangan buat table untuk entity ini." Semua CRUD harus di-handle oleh custom `ON` handler.

---

## Langkah 4: Service Definition

```bash
mkdir -p srv
```

Buat file `srv/po-service.cds`:

```cds
using { com.tecrise.procurement as db } from '../db/po-schema';

service PurchaseOrderService @(path: '/po') {

    entity PORequests as projection on db.PORequests {*}
        actions {
            action postToSAP() returns {
                sapPONumber : String;
                status      : String;
                message     : String;
            };
        };

    entity PORequestItems as projection on db.PORequestItems;

    function getSAPSuppliers() returns array of {
        Supplier     : String;
        SupplierName : String;
        Country      : String;
    };

    function testSAPConnection() returns {
        ok      : Boolean;
        status  : Integer;
        message : String;
    };

    function testCBOConnection() returns {
        ok           : Boolean;
        headerCount  : Integer;
        itemCount    : Integer;
        message      : String;
    };
}
```

### Perbedaan dari po-project

```diff
  // Service definition identik, PLUS:
+ function testCBOConnection() returns {
+     ok           : Boolean;
+     headerCount  : Integer;
+     itemCount    : Integer;
+     message      : String;
+ };
```

> `testCBOConnection()` — fungsi baru untuk verifikasi koneksi ke CBO OData.

---

## Langkah 5: CBO Client — Field Mapping Layer

Ini adalah file **paling penting** yang tidak ada di po-project — bridge antara CAP field names dan CBO OData property names.

```bash
mkdir -p srv/lib
```

Buat file `srv/lib/cbo-client.js`:

```javascript
/**
 * CBO OData V2 Client — CRUD untuk ZZ1_WPOREQ & ZZ1_WPOREQI
 *
 * Handles:
 * - Field mapping: CAP field names ↔ CBO OData property names
 * - CBO Header field mismatch (CompanyCode=description, Supplier=companyCode, Supplier1=supplier)
 * - OData V2 date format (/Date(...)/)
 * - CSRF Token management
 * - Basic Authentication
 */

process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// ============================================================
// Field Mappings — CAP ↔ CBO
// ============================================================

// Header: CAP field → CBO OData property
// ⚠️ CBO has label mismatch for 3 fields
const HEADER_CAP_TO_CBO = {
    requestNo:       'RequestNo',
    description:     'CompanyCode',      // ⚠️ label "PODescription" tapi property = CompanyCode
    companyCode:     'Supplier',          // ⚠️ label "CompanyCode"  tapi property = Supplier
    purchasingOrg:   'PurchasingOrg',
    purchasingGroup: 'PurchasingGroup',
    supplier:        'Supplier1',         // ⚠️ label "Supplier"     tapi property = Supplier1
    supplierName:    'SupplierName',
    orderDate:       'OrderDate',
    deliveryDate:    'DeliveryDate',
    currency:        'POCurrency',
    totalAmount:     'TotalAmount',
    notes:           'PONotes',
    status:          'POStatus',
    sapPONumber:     'PODocNumber',
    sapPostMessage:  'POPostMessage'
};

// Reverse mapping (CBO → CAP)
const HEADER_CBO_TO_CAP = {};
for (const [cap, cbo] of Object.entries(HEADER_CAP_TO_CBO)) {
    HEADER_CBO_TO_CAP[cbo] = cap;
}

// Items: CAP → CBO (clean mapping, no mismatch)
const ITEM_CAP_TO_CBO = {
    requestNo:     'RequestNo',
    itemNo:        'ItemNo',
    materialNo:    'MaterialNo',
    description:   'ItemDescription',
    quantity:       'Quantity',
    uom:           'UoM',
    unitPrice:     'UnitPrice',
    netAmount:     'NetAmount',
    currency:      'ItemCurrency',
    plant:         'Plant',
    materialGroup: 'MaterialGroup'
};

const ITEM_CBO_TO_CAP = {};
for (const [cap, cbo] of Object.entries(ITEM_CAP_TO_CBO)) {
    ITEM_CBO_TO_CAP[cbo] = cap;
}
```

> **Kenapa mapping manual?** CBO men-generate OData property berdasarkan urutan field saat create. Field ke-3 yang dibuat (`CompanyCode`) mendapat property `Supplier` karena CBO internal ordering. Di po-project, field mapping langsung 1:1 (CDS → HANA column). Ini trade-off CBO.

File lengkap `cbo-client.js` termasuk:
- `mapCAPtoCBO()` / `mapCBOtoCAP()` — converter
- `dateToOData()` / `oDataToDate()` — OData V2 date handling
- `fetchCSRFToken()` — CSRF management
- `createHeader()`, `readHeaders()`, `updateHeader()`, `deleteHeader()`
- `createItem()`, `readItemsByRequestNo()`, `updateItem()`, `deleteItem()`

→ Lihat source lengkap: `srv/lib/cbo-client.js` di project

---

## Langkah 6: SAP Client — Copy dari po-project

```bash
# Copy sap-client.js dari po-project (identik 100%)
cp ../po-project/srv/lib/sap-client.js srv/lib/sap-client.js
```

> **File ini 100% identik.** Kedua project menggunakan `MM_PUR_PO_MAINT_V2_SRV` dengan draft flow yang sama (Create Draft → Add Items → Prepare → Activate).

---

## Langkah 7: Service Handler — ON Handlers

Buat file `srv/po-service.js`:

```javascript
const cds = require('@sap/cds');
require('dotenv').config();

const CBOClient = require('./lib/cbo-client');
const SAPClient = require('./lib/sap-client');

module.exports = cds.service.impl(async function () {

    const cboClient = new CBOClient();
    const sapClient = new SAPClient();

    // ... helpers: getKeyFromReq, generateRequestNo, recalcHeaderTotal

    // ========================
    // READ — proxy ke CBO
    // ========================
    this.on('READ', 'PORequests', async (req) => {
        const id = getKeyFromReq(req);
        if (id) {
            const header = await cboClient.readHeader(id);
            if (needsExpand(req, 'items')) {
                header.items = await cboClient.readItemsByRequestNo(header.requestNo);
            }
            return header;
        }
        return cboClient.readHeaders();
    });

    // ========================
    // CREATE — auto requestNo + deep create items
    // ========================
    this.on('CREATE', 'PORequests', async (req) => {
        const data = req.data;
        data.requestNo = await generateRequestNo();
        // ... defaults + validation
        const created = await cboClient.createHeader(data);
        for (const item of (data.items || [])) {
            item.requestNo = created.requestNo;
            await cboClient.createItem(item);
        }
        return created;
    });

    // ... UPDATE, DELETE, Items CRUD, postToSAP
});
```

### Perbedaan Handler: po-project vs po-project-in-apps

```
po-project (BTP):
  this.before('CREATE', 'PORequests', ...)  ← BEFORE hook
  // Framework handles actual INSERT into DB automatically
  this.after('READ', 'PORequests', ...)     ← AFTER hook

po-project-in-apps (CBO):
  this.on('READ', 'PORequests', ...)   ← ON handler = REPLACE framework
  this.on('CREATE', 'PORequests', ...) ← Everything manual: CBO API call
  this.on('UPDATE', 'PORequests', ...) ← Semua event di-intercept
  this.on('DELETE', 'PORequests', ...) ← Termasuk cascade delete items
```

> **Key Insight:** `BEFORE/AFTER` hooks **menambahkan** logic ke framework CRUD. `ON` handlers **menggantikan** framework CRUD sepenuhnya. Karena `@cds.persistence.skip` berarti tidak ada DB, kita **harus** pakai `ON`.

→ Lihat source lengkap: `srv/po-service.js` di project

---

## Langkah 8: Fiori Annotations

```bash
mkdir -p app/po/webapp
```

Buat file `app/po/annotations.cds`:

```cds
using PurchaseOrderService as service from '../../srv/po-service';

annotate service.PORequests with @(
    UI.SelectionFields: [ status, supplier, orderDate ],
    UI.LineItem: [
        { Value: requestNo, Label: 'Request No' },
        { Value: description, Label: 'Description' },
        { Value: supplier, Label: 'Supplier' },
        { Value: supplierName, Label: 'Supplier Name' },
        { Value: status, Label: 'Status', Criticality: statusCriticality },
        { Value: totalAmount, Label: 'Total Amount' },
        { Value: currency, Label: 'Currency' },
        { Value: sapPONumber, Label: 'SAP PO No.' },
        {
            $Type: 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label: '📤 Post to SAP'
        }
    ]
);
// ... HeaderInfo, HeaderFacets, Facets, FieldGroups, Items LineItem
```

> **Annotations identik** dengan po-project. Sama persis — List Report + Object Page + Items table.

→ Source lengkap: `app/po/annotations.cds`

---

## Langkah 9: Webapp Files

### `app/po/webapp/manifest.json`

```json
{
    "_version": "1.59.0",
    "sap.app": {
        "id": "com.tecrise.po.inapp",
        ...
    }
}
```

### `app/po/webapp/Component.js`

```javascript
sap.ui.define(["sap/fe/core/AppComponent"], function (Component) {
    return Component.extend("com.tecrise.po.inapp.Component", {
        metadata: { manifest: "json" }
    });
});
```

### Perbedaan manifest dari po-project

```diff
  // po-project:
- "id": "com.tecrise.po"
  // po-project-in-apps:
+ "id": "com.tecrise.po.inapp"

  // Component.js namespace juga berbeda:
- Component.extend("com.tecrise.po.Component", ...
+ Component.extend("com.tecrise.po.inapp.Component", ...
```

> Namespace berbeda agar kedua project bisa di-deploy bersamaan tanpa conflict.

---

## Langkah 10: Jalankan & Test

```bash
cd Day3-Extensibility/po-project-in-apps

# Jalankan CAP server
cds watch
```

Expected output:

```
[cds] - loaded model from 2 file(s):

  srv/po-service.cds
  db/po-schema.cds

[cds] - serving PurchaseOrderService { path: '/po' }

[cds] - server listening on { url: 'http://localhost:4004' }
```

> **Perhatikan:** Tidak ada pesan `> using sqlite` atau `> deploying to hana` — karena tidak ada database!

### Test API

```bash
# 1. Test CBO Connection
curl -s http://localhost:4004/po/testCBOConnection() | python3 -m json.tool

# Expected:
# { "ok": true, "headerCount": 1, "itemCount": 1, "message": "CBO connected..." }

# 2. GET semua PO Requests (dari CBO)
curl -s http://localhost:4004/po/PORequests | python3 -m json.tool

# 3. CREATE — Deep Create dengan items
curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Workshop CBO Test — Office Supplies",
    "supplier": "17300001",
    "supplierName": "Wahyu Amaldi",
    "companyCode": "1710",
    "purchasingOrg": "1710",
    "purchasingGroup": "001",
    "deliveryDate": "2026-04-30",
    "currency": "USD",
    "items": [
        {
            "materialNo": "TG11",
            "description": "Green Tea Premium 500g",
            "quantity": 100,
            "unitPrice": 50.00,
            "uom": "PC"
        },
        {
            "description": "Office Paper A4",
            "quantity": 200,
            "unitPrice": 15.00,
            "uom": "PC",
            "materialGroup": "L001"
        }
    ]
  }' | python3 -m json.tool

# 4. POST to SAP (gunakan ID dari response CREATE)
curl -s -X POST \
  "http://localhost:4004/po/PORequests(<ID>)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" -d '{}' | python3 -m json.tool
```

### Fiori UI

Buka browser:
```
http://localhost:4004/po/webapp/index.html
```

Fiori Elements **identik** — List Report dengan data dari CBO, Object Page dengan items, Post to SAP button.

---

## Langkah 11: Verifikasi Data di SAP

Setelah CREATE via API/Fiori:

```bash
# Verifikasi header di CBO
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQ_CDS/ZZ1_WPOREQ?\$format=json&sap-client=777"

# Verifikasi items di CBO
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/ZZ1_WPOREQI?\$format=json&sap-client=777"

# Verifikasi di SAP SE16N (setelah postToSAP)
# Table: ZZ1_80BE1DF18710 (header)
# Atau: ME23N → search PO number dari response
```

---

## ✅ Checkpoint

```
po-project-in-apps Running:
═══════════════════════════════════════════

  ┌──────────────────────────────────────────────────┐
  │  CAP Server (http://localhost:4004)               │
  │                                                  │
  │  Fiori UI ──▶ CAP OData V4                       │
  │                    │                             │
  │         ┌──────────┼──────────┐                  │
  │         ▼                     ▼                  │
  │  CBO Client              SAP Client              │
  │  (cbo-client.js)         (sap-client.js)         │
  │         │                     │                  │
  └─────────┼─────────────────────┼──────────────────┘
            │ CRUD                │ postToSAP
            ▼                     ▼
  ┌────────────────────────────────────────────┐
  │  SAP S/4HANA (sap.ilmuprogram.com:777)     │
  │                                            │
  │  ZZ1_WPOREQ  → PO Request Headers          │
  │  ZZ1_WPOREQI → PO Request Items            │
  │  MM_PUR_PO_MAINT_V2_SRV → Real PO Create   │
  └────────────────────────────────────────────┘

  CBO Connection    ✅ (header + items)
  OData V4 API      ✅ (CRUD proxied to CBO)
  Fiori Elements    ✅ (List Report + Object Page)
  postToSAP         ✅ (Same 5-step draft flow)
  Deep Create       ✅ (Header + Items in one call)
```

---

## File Structure — Final

```
po-project-in-apps/
├── package.json              ← Minimal: @sap/cds + dotenv
├── .env                      ← SAP credentials
├── db/
│   └── po-schema.cds         ← @cds.persistence.skip entities
├── srv/
│   ├── po-service.cds        ← Service + postToSAP + testCBOConnection
│   ├── po-service.js         ← ON handlers (semua CRUD manual)
│   └── lib/
│       ├── cbo-client.js     ← CBO OData V2 CRUD + field mapping ★
│       └── sap-client.js     ← SAP PO creation (identik dgn po-project)
├── app/po/
│   ├── annotations.cds       ← Fiori annotations (identik dgn po-project)
│   └── webapp/
│       ├── manifest.json     ← com.tecrise.po.inapp namespace
│       ├── Component.js
│       └── index.html
└── tests/
    └── po-tests.http         ← REST Client test scenarios
```

---

## Summary: Kapan Pakai Pendekatan Mana?

| Skenario | Pilih |
|:---------|:------|
| Tim sudah punya BTP license + HANA Cloud | **po-project** (side-by-side) |
| Ingin hemat biaya database | **po-project-in-apps** (CBO) |
| Butuh complex composition (deep insert native) | **po-project** |
| Data harus tetap di SAP (compliance) | **po-project-in-apps** |
| Produksi, butuh MTA deploy ke CF | **po-project** (sudah ada mta.yaml) |
| Quick prototype tanpa setup DB | **po-project-in-apps** |
| S/4HANA Cloud (public edition) | **po-project-in-apps** (CBO native) |
| S/4HANA On-Premise | Keduanya bisa (CBO perlu Gateway manual) |

---

## 🔗 Navigasi

| Hands-on | Topik |
|:---------|:------|
| ← [Hands-on 4](handson-4-cbo-in-app.md) | Custom Business Object (CBO) Creation |
| ← [Hands-on 1–3](handson-1-extend-cds-model.md) | po-project (Side-by-Side BTP) |
