# Hands-on 3: Fiori UI, HANA Cloud & Post to SAP S/4HANA

> **Durasi:** ~45 menit  
> **Prerequisite:** Hands-on 2 selesai (service + SAP client berjalan, `testSAPConnection` → ok)

---

## Tujuan

1. Membuat **Fiori Elements UI** (List Report + Object Page) dengan tombol "Post to SAP"
2. **Deploy schema ke SAP HANA Cloud** — data persisten, bukan SQLite in-memory
3. **Post PO ke SAP S/4HANA real** — mendapatkan SAP PO Number nyata

---

## Bagian A: Fiori Elements UI

### Langkah 1: Buat CDS Annotations

Buat file `app/po/annotations.cds`:

```cds
using PurchaseOrderService as service from '../../srv/po-service';

// ============================================
// PO REQUESTS — List Report
// ============================================
annotate service.PORequests with @(

    UI.SelectionFields: [
        status, supplier, orderDate
    ],

    UI.LineItem: [
        { $Type: 'UI.DataField', Value: requestNo,    Label: 'Request No',     ![@UI.Importance]: #High },
        { $Type: 'UI.DataField', Value: description,   Label: 'Description',    ![@UI.Importance]: #High },
        { $Type: 'UI.DataField', Value: supplier,      Label: 'Supplier ID' },
        { $Type: 'UI.DataField', Value: supplierName,  Label: 'Supplier Name' },
        { $Type: 'UI.DataField', Value: status,        Label: 'Status',         Criticality: statusCriticality },
        { $Type: 'UI.DataField', Value: totalAmount,   Label: 'Total Amount' },
        { $Type: 'UI.DataField', Value: currency,      Label: 'Currency' },
        { $Type: 'UI.DataField', Value: sapPONumber,   Label: 'SAP PO No' },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label : '📤 Post to SAP',
            ![@UI.Importance]: #High
        }
    ],

    UI.PresentationVariant: {
        SortOrder: [{ Property: requestNo, Descending: true }]
    }
);

// ============================================
// PO REQUESTS — Object Page Header
// ============================================
annotate service.PORequests with @(

    UI.HeaderInfo: {
        TypeName       : 'PO Request',
        TypeNamePlural : 'PO Requests',
        Title          : { $Type: 'UI.DataField', Value: requestNo },
        Description    : { $Type: 'UI.DataField', Value: description }
    },

    UI.HeaderFacets: [
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#Status' },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#TotalAmount' },
        { $Type: 'UI.ReferenceFacet', Target: '@UI.DataPoint#SAPPONumber' }
    ],

    UI.DataPoint #Status:      { Value: status, Title: 'Status', Criticality: statusCriticality },
    UI.DataPoint #TotalAmount: { Value: totalAmount, Title: 'Total Amount' },
    UI.DataPoint #SAPPONumber: { Value: sapPONumber, Title: 'SAP PO Number' },

    // POST TO SAP button di Object Page
    UI.Identification: [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'PurchaseOrderService.postToSAP',
            Label : '📤 Post to SAP'
        }
    ]
);

// ============================================
// PO REQUESTS — Object Page Sections
// ============================================
annotate service.PORequests with @(

    UI.Facets: [
        {
            $Type: 'UI.ReferenceFacet', Label: 'General Information',
            ID: 'GeneralInfo', Target: '@UI.FieldGroup#GeneralInfo'
        },
        {
            $Type: 'UI.ReferenceFacet', Label: 'SAP Organization',
            ID: 'SAPOrg', Target: '@UI.FieldGroup#SAPOrg'
        },
        {
            $Type: 'UI.ReferenceFacet', Label: 'Items',
            ID: 'Items', Target: 'items/@UI.LineItem'
        },
        {
            $Type: 'UI.ReferenceFacet', Label: 'SAP Integration Status',
            ID: 'SAPStatus', Target: '@UI.FieldGroup#SAPStatus'
        }
    ],

    UI.FieldGroup #GeneralInfo: {
        Data: [
            { $Type: 'UI.DataField', Value: requestNo,    Label: 'Request No' },
            { $Type: 'UI.DataField', Value: description,   Label: 'Description' },
            { $Type: 'UI.DataField', Value: supplier,      Label: 'Supplier ID' },
            { $Type: 'UI.DataField', Value: supplierName,  Label: 'Supplier Name' },
            { $Type: 'UI.DataField', Value: orderDate,     Label: 'Order Date' },
            { $Type: 'UI.DataField', Value: deliveryDate,  Label: 'Delivery Date' },
            { $Type: 'UI.DataField', Value: currency,      Label: 'Currency' },
            { $Type: 'UI.DataField', Value: totalAmount,   Label: 'Total Amount' },
            { $Type: 'UI.DataField', Value: notes,         Label: 'Notes' }
        ]
    },

    UI.FieldGroup #SAPOrg: {
        Data: [
            { $Type: 'UI.DataField', Value: companyCode,     Label: 'Company Code' },
            { $Type: 'UI.DataField', Value: purchasingOrg,   Label: 'Purchasing Org' },
            { $Type: 'UI.DataField', Value: purchasingGroup, Label: 'Purchasing Group' }
        ]
    },

    UI.FieldGroup #SAPStatus: {
        Data: [
            { $Type: 'UI.DataField', Value: status,         Label: 'Status', Criticality: statusCriticality },
            { $Type: 'UI.DataField', Value: sapPONumber,    Label: 'SAP PO Number' },
            { $Type: 'UI.DataField', Value: sapPostDate,    Label: 'Posted at' },
            { $Type: 'UI.DataField', Value: sapPostMessage, Label: 'SAP Response' }
        ]
    }
);

// ============================================
// PO REQUEST ITEMS — Table in Object Page
// ============================================
annotate service.PORequestItems with @(
    UI.LineItem: [
        { $Type: 'UI.DataField', Value: itemNo,        Label: 'Item' },
        { $Type: 'UI.DataField', Value: materialNo,    Label: 'Material' },
        { $Type: 'UI.DataField', Value: description,    Label: 'Description' },
        { $Type: 'UI.DataField', Value: quantity,       Label: 'Qty' },
        { $Type: 'UI.DataField', Value: uom,            Label: 'UoM' },
        { $Type: 'UI.DataField', Value: unitPrice,      Label: 'Unit Price' },
        { $Type: 'UI.DataField', Value: netAmount,      Label: 'Net Amount' },
        { $Type: 'UI.DataField', Value: currency,       Label: 'Curr' },
        { $Type: 'UI.DataField', Value: plant,          Label: 'Plant' },
        { $Type: 'UI.DataField', Value: materialGroup,  Label: 'Mat. Group' }
    ],
    UI.HeaderInfo: {
        TypeName: 'Item', TypeNamePlural: 'Items'
    }
);
```

### Langkah 2: Buat Fiori Web App Files

**File: `app/po/webapp/manifest.json`**

```json
{
    "_version": "1.59.0",
    "sap.app": {
        "id": "com.tecrise.po",
        "type": "application",
        "title": "PO Request — Post to SAP",
        "description": "Side-by-Side Extension: Z-table → SAP S/4HANA",
        "applicationVersion": { "version": "1.0.0" },
        "dataSources": {
            "mainService": {
                "uri": "/odata/v4/po/",
                "type": "OData",
                "settings": { "odataVersion": "4.0" }
            }
        }
    },
    "sap.ui5": {
        "dependencies": {
            "minUI5Version": "1.120.0",
            "libs": {
                "sap.m": {},
                "sap.ui.core": {},
                "sap.ushell": {},
                "sap.fe.templates": {}
            }
        },
        "models": {
            "": {
                "dataSource": "mainService",
                "preload": true,
                "settings": {
                    "synchronizationMode": "None",
                    "operationMode": "Server",
                    "autoExpandSelect": true,
                    "earlyRequests": true
                }
            }
        },
        "routing": {
            "routes": [
                {
                    "pattern": ":?query:",
                    "name": "PORequestsList",
                    "target": "PORequestsList"
                },
                {
                    "pattern": "PORequests({key}):?query:",
                    "name": "PORequestsObjectPage",
                    "target": "PORequestsObjectPage"
                }
            ],
            "targets": {
                "PORequestsList": {
                    "type": "Component",
                    "id": "PORequestsList",
                    "name": "sap.fe.templates.ListReport",
                    "options": {
                        "settings": {
                            "contextPath": "/PORequests",
                            "variantManagement": "Page",
                            "initialLoad": "Enabled",
                            "navigation": {
                                "PORequests": {
                                    "detail": { "route": "PORequestsObjectPage" }
                                }
                            }
                        }
                    }
                },
                "PORequestsObjectPage": {
                    "type": "Component",
                    "id": "PORequestsObjectPage",
                    "name": "sap.fe.templates.ObjectPage",
                    "options": {
                        "settings": {
                            "contextPath": "/PORequests",
                            "editableHeaderContent": false
                        }
                    }
                }
            }
        }
    }
}
```

**File: `app/po/webapp/Component.js`**

```javascript
sap.ui.define(["sap/fe/core/AppComponent"], function (AppComponent) {
    "use strict";
    return AppComponent.extend("com.tecrise.po.Component", {
        metadata: { manifest: "json" }
    });
});
```

**File: `app/po/webapp/index.html`**

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PO Request — Post to SAP</title>
    <script id="sap-ui-bootstrap"
        src="https://sapui5.hana.ondemand.com/resources/sap-ui-core.js"
        data-sap-ui-theme="sap_horizon"
        data-sap-ui-resourceroots='{"com.tecrise.po": "./"}'
        data-sap-ui-compatVersion="edge"
        data-sap-ui-async="true"
        data-sap-ui-frameOptions="allow"
    ></script>
    <script>
        sap.ui.require(["sap/fe/core/ComponentContainer"], function (ComponentContainer) {
            new ComponentContainer({
                name: "com.tecrise.po",
                settings: {},
                async: true,
                height: "100%"
            }).placeAt("content");
        });
    </script>
</head>
<body class="sapUiBody" id="content"></body>
</html>
```

### Langkah 3: Verifikasi Fiori UI

```bash
cds watch
```

Buka browser: **http://localhost:4004/po/webapp/index.html**

**Yang harus terlihat:**
1. **List Report** — Tabel dengan 3 PO Requests dari sample data
2. **Filter bar** — Filter by Status, Supplier, Order Date
3. **Tombol "📤 Post to SAP"** — Di kolom tabel (per baris)
4. **Klik baris** → **Object Page** dengan:
   - Header: Request No, Status (warna), Total Amount, SAP PO Number
   - Section: General Info, SAP Organization, Items table, SAP Integration Status
   - Tombol "📤 Post to SAP" di header Object Page

---

## Bagian B: Deploy ke SAP HANA Cloud

### Prerequisite HANA Cloud

- SAP BTP Trial account dengan HANA Cloud instance (hana-free)
- CF CLI logged in: `cf login -a https://api.cf.ap21.hana.ondemand.com`
- HANA Cloud instance harus **Running** (BTP Trial auto-stop setelah idle)

### Langkah 4: Pastikan HANA Cloud Running

```bash
# Cek status
cf service Dev-hana

# Jika stopped, start:
cf update-service Dev-hana -c '{"data":{"serviceStopped":false}}'

# Tunggu sampai "update succeeded" (5-15 menit)
cf service Dev-hana | grep status
```

### Langkah 5: Buat HDI Container

```bash
cf create-service hana hdi-shared po-project-db

# Tunggu sampai "create succeeded"
cf service po-project-db
```

### Langkah 6: Allow External IP (untuk deploy dari lokal)

```bash
# Agar laptop bisa connect ke HANA Cloud
cf update-service Dev-hana -c '{"data":{"whitelistIPs":["0.0.0.0/0"]}}'

# Tunggu sampai "update succeeded"
cf service Dev-hana | grep status
```

### Langkah 7: Deploy Schema ke HANA

```bash
cd Day3-Extensibility/po-project

# Deploy — ini akan: build HANA artifacts → create service key → deploy tables + CSV data
cds deploy --to hana
```

**Expected output:**
```
building project...
done > wrote output to:
   gen/db/src/gen/com.tecrise.procurement.PORequests.hdbtable
   gen/db/src/gen/com.tecrise.procurement.PORequestItems.hdbtable
   ...

using container po-project-db
starting deployment to SAP HANA ...

Inserted 3 records ... into COM_TECRISE_PROCUREMENT_POREQUESTS
Inserted 4 records ... into COM_TECRISE_PROCUREMENT_POREQUESTITEMS

Make succeeded: 11 files deployed

binding db to Cloud Foundry managed service po-project-db
saving bindings to .cdsrc-private.json in profile hybrid

successfully finished deployment
```

> `cds deploy --to hana` otomatis membuat `.cdsrc-private.json` dengan binding credentials untuk hybrid profile.

### Langkah 8: Jalankan Hybrid Mode

```bash
cds watch --profile hybrid
```

**Expected output:**
```
resolving cloud service bindings...
bound db to cf managed service po-project-db:po-project-db-key

[cds] - connect to db > hana {
  host: '...hana.prod-ap21.hanacloud.ondemand.com',
  port: '443',
  schema: 'F6AC7A7E...'
}
[SAP] Client configured → https://sap.ilmuprogram.com (client 777)

[cds] - server listening on { url: 'http://localhost:4004' }
```

Node.js jalan **lokal**, tapi database sudah **HANA Cloud**. Data persisten — restart server tidak hilang.

### Langkah 9: Verifikasi Data dari HANA

```bash
curl -s http://localhost:4004/po/PORequests | python3 -m json.tool
```

**Harus mengembalikan 3 records** yang sama — sekarang datanya dari HANA Cloud, bukan SQLite!

### Langkah 9b: Browse HANA Cloud via DBeaver (Optional)

Selain verifikasi via OData/curl, kita bisa melihat tabel HANA Cloud langsung menggunakan **DBeaver** — database tool gratis yang mendukung SAP HANA.

#### 1. Install DBeaver

Download dari [https://dbeaver.io/download/](https://dbeaver.io/download/) → pilih **Community Edition** (gratis).

#### 2. Ambil Credentials HANA

Jalankan di terminal (pastikan sudah `cf login`):

```bash
cf service-key po-project-db po-project-db-key
```

Catat nilai berikut dari output JSON:

| Field | Contoh Nilai |
|:------|:-------------|
| `host` | `0536a7f6-2846-40e6-baf7-171fcf1ae66c.hana.prod-ap21.hanacloud.ondemand.com` |
| `port` | `443` |
| `schema` | `F6AC7A7E7DCE4998A28129271B5F644F` |
| `user` | `F6AC7A7E7DCE4998A28129271B5F644F_CHVKIVRAD04MPQUPWMY9NF2MK_RT` |
| `password` | *(dari field `password` di output JSON)* |

#### 3. Buat Connection di DBeaver

1. Buka DBeaver → **Database** → **New Database Connection** (atau klik icon colokan `+`)
2. Cari **SAP HANA** → pilih → klik **Next**
3. Jika DBeaver meminta download HANA JDBC driver, klik **Download** → tunggu selesai
4. Isi connection details:

| Field | Nilai |
|:------|:------|
| **Host** | `0536a7f6-2846-40e6-baf7-171fcf1ae66c.hana.prod-ap21.hanacloud.ondemand.com` |
| **Port** | `443` |
| **Database/Schema** | `F6AC7A7E7DCE4998A28129271B5F644F` |
| **User** | *(dari `cf service-key` — field `user`)* |
| **Password** | *(dari `cf service-key` — field `password`)* |

5. Klik tab **Driver properties** → pastikan:

| Property | Value |
|:---------|:------|
| `encrypt` | `true` |
| `validateCertificate` | `true` |

6. Klik **Test Connection** → harus muncul **"Connected"**
7. Klik **Finish**

#### 4. Browse Tabel

Setelah connected, navigasi di panel kiri:

```
po-project-db
 └── Schemas
      └── F6AC7A7E7DCE4998A28129271B5F644F
           └── Tables
                ├── COM_TECRISE_PROCUREMENT_POREQUESTS        (3 rows)
                ├── COM_TECRISE_PROCUREMENT_POREQUESTITEMS     (4 rows)
                └── CDS_OUTBOX_MESSAGES                        (0 rows)
```

- **Double-click** tabel → buka tab **Data** untuk lihat isi rows
- Atau klik kanan tabel → **View Data** → melihat data langsung

#### 5. Jalankan SQL Query (Optional)

Buka **SQL Editor** (klik kanan connection → **SQL Editor** → **New SQL Script**):

```sql
-- Lihat semua PO Requests
SELECT * FROM "COM_TECRISE_PROCUREMENT_POREQUESTS";

-- Lihat items beserta header-nya
SELECT r."REQUESTNO", r."DESCRIPTION", r."STATUS",
       i."MATERIALNO", i."DESCRIPTION" AS "ITEM_DESC", i."QUANTITY", i."NETAMOUNT"
FROM "COM_TECRISE_PROCUREMENT_POREQUESTS" r
JOIN "COM_TECRISE_PROCUREMENT_POREQUESTITEMS" i
  ON r."ID" = i."PARENT_ID";

-- Cek PO yang sudah di-post ke SAP
SELECT "REQUESTNO", "SAPPONUMBER", "SAPPOSTDATE"
FROM "COM_TECRISE_PROCUREMENT_POREQUESTS"
WHERE "STATUS" = 'P';
```

> **Tips:** DBeaver juga bisa digunakan untuk memonitor data setelah Post to SAP — refresh tabel untuk melihat status berubah dari `D` ke `P` dan kolom `SAP_PO_NUMBER` terisi.

---

## Bagian C: Post PO ke SAP S/4HANA Real

### Langkah 10: Post via curl

```bash
# Post REQ-260001 ke SAP (pastikan server hybrid masih jalan)
curl -s -X POST \
  "http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670001)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

**Expected result:**
```json
{
    "sapPONumber": "4500000016",
    "status": "Posted",
    "message": "PO 4500000016 berhasil dibuat di SAP S/4HANA"
}
```

### Langkah 11: Post via Fiori UI

1. Buka **http://localhost:4004/po/webapp/index.html**
2. Pilih PO Request dengan status **Draft** (D)
3. Klik tombol **"📤 Post to SAP"**
4. Tunggu — UI akan auto-refresh
5. Kolom **SAP PO No** akan terisi (e.g., `4500000017`)
6. Status berubah menjadi **P** (hijau)

### Langkah 12: Verifikasi di SAP S/4HANA

PO yang dibuat bisa dicek langsung di SAP:

```bash
# Cek PO di SAP via OData
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV/C_PurchaseOrderFs('4500000016')?\$format=json&sap-client=777" | python3 -m json.tool
```

Atau login ke SAP GUI → Transaction `ME23N` → Masukkan PO Number.

---

## Struktur Project Final

```
po-project/
├── package.json              ← Multi-profile DB config
├── .env                      ← SAP credentials
├── .cdsrc-private.json       ← HANA binding (auto-generated)
├── db/
│   ├── po-schema.cds         ← CDS data model (Z-table)
│   └── data/                 ← CSV seed data
├── srv/
│   ├── po-service.cds        ← Service + postToSAP action
│   ├── po-service.js         ← Handlers + business logic
│   └── lib/
│       └── sap-client.js     ← SAP OData V2 client (draft flow)
├── app/
│   └── po/
│       ├── annotations.cds   ← Fiori Elements annotations
│       └── webapp/
│           ├── manifest.json  ← App routing config
│           ├── Component.js   ← UI5 component
│           └── index.html     ← Entry point
├── gen/                       ← Build output (HANA artifacts)
├── mta.yaml                  ← MTA descriptor (production deploy)
└── xs-security.json          ← XSUAA roles (POManager, POViewer)
```

---

## End-to-End Flow Summary

```
┌──────────────────────────────────────────────────────────────────┐
│                    BTP (Side-by-Side Extension)                   │
│                                                                  │
│  Fiori UI ──▶ CAP Service ──▶ HANA Cloud (Z-table)              │
│  (List Report)  (po-service.js)  (PORequests + Items)            │
│                      │                                           │
│                      │ postToSAP()                               │
│                      ▼                                           │
│               SAP OData V2 Client                                │
│               (sap-client.js)                                    │
│                      │                                           │
└──────────────────────┼───────────────────────────────────────────┘
                       │ HTTPS (OData V2)
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│              SAP S/4HANA (sap.ilmuprogram.com)                   │
│                                                                  │
│  MM_PUR_PO_MAINT_V2_SRV                                         │
│  Draft → Items → Prepare → Activate → PO 4500000016             │
│                                                                  │
│  Company Code 1710 (Andi Coffee) | Plant 1710                    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Checkpoint Final

| # | Cek | Status |
|:--|:----|:-------|
| 1 | Fiori UI tampil di `http://localhost:4004/po/webapp/index.html` | ☐ |
| 2 | List Report menampilkan 3 PO Requests | ☐ |
| 3 | Object Page menampilkan header + 4 sections + items table | ☐ |
| 4 | HANA Cloud: `cds watch --profile hybrid` → `connect to db > hana` | ☐ |
| 5 | Data persisten di HANA (restart server → data masih ada) | ☐ |
| 6 | Post to SAP → mendapat SAP PO Number nyata (e.g., 4500000016) | ☐ |
| 7 | Status berubah dari D (kuning) → P (hijau) setelah posting | ☐ |
| 8 | PO bisa diverifikasi di SAP S/4HANA (ME23N atau OData) | ☐ |

---

## Troubleshooting

| Problem | Solution |
|:--------|:---------|
| HANA Cloud stopped | `cf update-service Dev-hana -c '{"data":{"serviceStopped":false}}'` |
| HDI create failed | Delete & recreate: `cf delete-service po-project-db -f && cf create-service hana hdi-shared po-project-db` |
| `cds deploy` connection refused | Allowlist IP: `cf update-service Dev-hana -c '{"data":{"whitelistIPs":["0.0.0.0/0"]}}'` |
| `impl: '@cap-js/sqlite'` in hybrid | Pastikan `"impl": "@cap-js/hana"` ada di `[hybrid]` profile di package.json |
| SAP: "Material number required" | Gunakan material real: `EWMS4-01`, `EWMS4-02` |
| SAP: "CSRF token validation failed" | CSRF token expired — retry (token otomatis di-fetch ulang) |
| Fiori UI blank | Cek browser console → pastikan `/odata/v4/po/` accessible |

---

**Selesai! Workshop Day 3 — Clean Core Extensibility: End-to-End.**
