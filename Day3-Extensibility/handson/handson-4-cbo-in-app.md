# Hands-on 4: Custom Business Object (CBO) — In-App Extensibility

> **Durasi:** ~60 menit  
> **Prerequisite:** Akses SAP Fiori Launchpad + SAP GUI di `sap.ilmuprogram.com` (client 777)  
> **Konteks:** Membuat custom table **langsung di SAP S/4HANA** tanpa ABAP coding — pendekatan **in-app extensibility** sebagai alternatif HANA Cloud  
> **CBO yang dibuat:** `ZZ1_WPOREQ` (Header) + `ZZ1_WPOREQI` (Items)

---

## Tujuan

Membuat **Custom Business Object (CBO)** di SAP S/4HANA sebagai custom table pengganti Z-table tradisional. CBO otomatis menghasilkan:
- Database table di SAP HANA (embedded)
- CDS View untuk query
- OData V2 Service untuk CRUD
- Basic Fiori maintenance UI

### Perbandingan Pendekatan

| Aspek | po-project (Side-by-Side) | CBO (In-App) |
|:------|:--------------------------|:-------------|
| **Database** | HANA Cloud (BTP) | HANA S/4HANA (embedded) |
| **Biaya DB** | ~€693/bln (paid) atau $0 (trial) | $0 (sudah included di SAP license) |
| **Coding** | CDS + Node.js + Fiori | Zero coding (browser-based) |
| **Tabel** | `COM_TECRISE_PROCUREMENT_POREQUESTS` | `ZZ1_80BE1DF18710` (header) |
| **OData** | CAP auto-generate OData V4 | SAP auto-generate OData V2 |
| **Items** | Composition (header→items) | Separate CBO (`ZZ1_WPOREQI`) |
| **Flexibility** | Penuh (Composition, custom logic) | Terbatas (~200 fields, no composition) |

> **Clean Core:** CBO adalah fitur **in-app extensibility resmi SAP** — tidak memodifikasi core SAP, tidak butuh transport, dan fully supported.

---

## Langkah 1: Buka Custom Business Objects App

1. Buka SAP Fiori Launchpad:
   ```
   https://sap.ilmuprogram.com/sap/bc/ui2/flp?sap-client=777&sap-language=EN
   ```
   Login: `wahyu.amaldi` / `Pas671_ok12345`

2. Cari app **"Custom Business Objects"** di Launchpad
   - Atau akses langsung via URL:
   ```
   https://sap.ilmuprogram.com/sap/bc/ui2/flp?sap-client=777#CustomBusinessObject-develop
   ```

3. Klik **"New"** untuk membuat CBO baru

---

## Langkah 2: Buat CBO — General Information

Isi informasi dasar:

| Field | Value |
|:------|:------|
| **Name** | `WPOREQ` |
| **Name in Plural** | `WPOREQs` |

> **Penamaan:** CBO otomatis mendapat prefix `ZZ1_`. Nama lengkap menjadi `ZZ1_WPOREQ`.

---

## Langkah 3: Tambah Fields

Klik tab **"Fields"** → tambahkan field berikut satu per satu:

### ⚠️ Aturan Penting CBO Field Naming

CBO memiliki **reserved words** yang tidak boleh dipakai sebagai field name:
- ❌ `Description` → pakai `PODescription`
- ❌ `Status` → pakai `POStatus`
- ❌ `Currency` → pakai `POCurrency`
- ❌ `Notes` → pakai `PONotes`
- ❌ Prefix `SAP` → pakai `PODocNumber` bukan `SAPPONumber`

### Field List — ZZ1_WPOREQ

| # | Field Name | Label | Type | Length |
|:--|:-----------|:------|:-----|:-------|
| 1 | `RequestNo` | RequestNo | Text | 20 |
| 2 | `PODescription` | Description | Text | 200 |
| 3 | `CompanyCode` | CompanyCode | Text | 20 |
| 4 | `PurchasingOrg` | PurchasingOrg | Text | 20 |
| 5 | `PurchasingGroup` | PurchasingGroup | Text | 20 |
| 6 | `Supplier` | Supplier | Text | 20 |
| 7 | `SupplierName` | SupplierName | Text | 80 |
| 8 | `OrderDate` | OrderDate | Date | — |
| 9 | `DeliveryDate` | DeliveryDate | Date | — |
| 10 | `POCurrency` | POCurrency | Text | 20 |
| 11 | `TotalAmount` | TotalAmount | Number | 10,2 |
| 12 | `PONotes` | Notes | Text | 256 |
| 13 | `POStatus` | Status | Text | 20 |
| 14 | `PODocNumber` | PODocNumber | Text | 20 |
| 15 | `POPostMessage` | POPostMessage | Text | 200 |

> **Tips:**
> - Gunakan type **Number** (bukan "Amount with Currency") untuk field angka — type Amount sering menyebabkan conflict saat publish
> - Centang **"Key Field"** hanya untuk `RequestNo`
> - CBO otomatis menambah `SAP_UUID` sebagai primary key (Guid)

---

## Langkah 4: Aktifkan Features

Klik tab **"General Information"** kembali, scroll ke bagian **Features**:

| Feature | Status | Keterangan |
|:--------|:-------|:-----------|
| **Back End Service** | ✅ **Centang** | Wajib! Ini yang men-generate OData service |
| Determination and Validation | ○ (opsional) | Untuk business logic ABAP |
| Can Be Associated | ○ (opsional) | Untuk relasi antar CBO |
| System Administrative Data | ○ (opsional) | Menambah created/changed fields |
| Change Documents | ○ (opsional) | Audit trail |

> **⚠️ KRITIS:** Tanpa **"Back End Service"** dicentang, CBO hanya membuat table — **TIDAK** membuat OData service. OData diperlukan agar CAP bisa consume CBO sebagai remote entity.

---

## Langkah 5: Publish CBO

1. Klik tombol **"Publish"** di toolbar atas
2. Tunggu hingga status berubah menjadi **"Published"**

### Troubleshooting Publish Error

| Error | Penyebab | Solusi |
|:------|:---------|:-------|
| "conflicts" | Field name reserved word | Rename: `Description` → `PODescription`, dll |
| "conflicts" | Type "Amount with Currency" | Ganti ke type "Number" |
| "conflicts" | Prefix "SAP" di field name | Ganti: `SAPPONumber` → `PODocNumber` |
| Publish gagal tanpa pesan | CBO draft corruption | Delete CBO, buat ulang dari awal |

### Apa yang dihasilkan saat Publish

SAP otomatis membuat:
```
Publish CBO "WPOREQ":
═══════════════════════════════════════════

1. Database Table    → ZZ1_80BE1DF18710    (transparent table di SAP HANA)
2. CDS View          → ZZ1_WPOREQ          (ABAP CDS, bisa dilihat di SE16N)
3. SQL View          → ZZ1_282414C4B839    (underlying SQL view)
4. OData Service     → ZZ1_WPOREQ_CDS      (OData V2 CRUD)
   └── Entity Set    → ZZ1_WPOREQ
   └── Entity Type   → ZZ1_WPOREQType
```

---

## Langkah 6: Register OData Service di Gateway

> **Penting:** Di SAP on-premise, CBO publish **TIDAK** otomatis mendaftarkan OData service ke SAP Gateway. Harus manual.

### Via SAP GUI:

1. Jalankan tcode **`/n/IWFND/MAINT_SERVICE`**
2. Klik tombol **"Add Service"**
3. Isi filter:
   - **System Alias:** `LOCAL`
   - **Technical Service Name:** `ZZ1_WPOREQ_CDS`
4. Klik **"Get Services"** → service muncul di list
5. Pilih service → klik **"Add Selected Services"**
6. Isi:
   - **Package:** `$TMP` (lokal, tidak perlu transport)
7. Klik **Save** → service terdaftar

### Verifikasi di Browser:

```
https://sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQ_CDS/?$format=json&sap-client=777
```

Response yang expected:
```json
{
  "d": {
    "EntitySets": ["ZZ1_WPOREQ"]
  }
}
```

---

## Langkah 7: Test CRUD via OData

### 7a. READ — GET semua records

```bash
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQ_CDS/ZZ1_WPOREQ?\$format=json&sap-client=777"
```

### 7b. CREATE — POST record baru

```bash
# Step 1: Fetch CSRF Token
curl -sk -D /tmp/cbo_headers.txt \
  "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQ_CDS/?sap-client=777" \
  -H "X-CSRF-Token: Fetch" -o /dev/null

# Extract token & cookies
CSRF=$(grep -i "x-csrf-token" /tmp/cbo_headers.txt | tr -d '\r' | awk '{print $2}')
COOKIES=$(grep -i "set-cookie" /tmp/cbo_headers.txt | \
  sed 's/[Ss]et-[Cc]ookie: //' | cut -d';' -f1 | tr '\n' '; ' | tr -d '\r')

# Step 2: POST Create
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQ_CDS/ZZ1_WPOREQ?sap-client=777" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-CSRF-Token: $CSRF" \
  -H "Cookie: $COOKIES" \
  -d '{
    "RequestNo": "REQ-260001",
    "CompanyCode": "Office supplies for Q1",
    "Supplier": "1710",
    "PurchasingOrg": "1710",
    "PurchasingGroup": "001",
    "Supplier1": "17300001",
    "SupplierName": "Wahyu Amaldi",
    "POCurrency": "USD",
    "TotalAmount": "3020.00",
    "POStatus": "D",
    "PODocNumber": "",
    "POPostMessage": ""
  }'
```

Expected Response (HTTP 201):
```json
{
  "d": {
    "SAP_UUID": "000c29de-8c2b-1fd1-8cdc-3ec9b1359da8",
    "RequestNo": "REQ-260001",
    "CompanyCode": "Office supplies for Q1",
    "POStatus": "D",
    "TotalAmount": "3020.00"
  }
}
```

### 7c. Verifikasi di SE16N

Buka tcode **SE16N** → table name: **`ZZ1_80BE1DF18710`** → Execute

Record yang baru di-create akan terlihat di sini.

---

# Part B: CBO Items — ZZ1_WPOREQI

> Sama seperti `po-schema.cds` yang memiliki `PORequests` (header) dan `PORequestItems` (line items), kita perlu CBO kedua untuk menyimpan items.

---

## Langkah 8: Buat CBO Items

1. Buka kembali **"Custom Business Objects"** app di Fiori Launchpad
2. Klik **"New"**:

| Field | Value |
|:------|:------|
| **Name** | `WPOREQI` |
| **Name in Plural** | `WPOREQIs` |

> Nama lengkap: `ZZ1_WPOREQI` (I = Items)

---

## Langkah 9: Tambah Fields — Items

### Field List — ZZ1_WPOREQI

| # | Field Name | Label | Type | Length | Key? |
|:--|:-----------|:------|:-----|:-------|:-----|
| 1 | `RequestNo` | RequestNo | Text | 20 | ✅ Mandatory |
| 2 | `ItemNo` | ItemNo | Text | 20 | ✅ Mandatory |
| 3 | `MaterialNo` | MaterialNo | Text | 40 | |
| 4 | `ItemDescription` | ItemDescription | Text | 200 | |
| 5 | `Quantity` | Quantity | Number | 10,2 | |
| 6 | `UoM` | UoM | Text | 20 | |
| 7 | `UnitPrice` | UnitPrice | Number | 10,2 | |
| 8 | `NetAmount` | NetAmount | Number | 10,2 | |
| 9 | `ItemCurrency` | ItemCurrency | Text | 20 | |
| 10 | `Plant` | Plant | Text | 20 | |
| 11 | `MaterialGroup` | MaterialGroup | Text | 20 | |

> **Observasi:**
> - Items CBO **tidak** mengalami field naming conflict — semua nama field aman
> - `RequestNo` menjadi **foreign key** logis ke `ZZ1_WPOREQ`  
> - `ItemNo` format SAP: `00010`, `00020`, `00030` (kelipatan 10)
> - Semantic Key: `RequestNo` + `ItemNo`

---

## Langkah 10: Aktifkan Features & Publish

1. Tab **"General Information"** → Features:
   - ✅ **Back End Service** (wajib!)
2. Klik **"Publish"**

### Apa yang dihasilkan

```
Publish CBO "WPOREQI":
═══════════════════════════════════════════

1. Database Table    → ZZ1_xxxxxxxx       (transparent table)
2. CDS View          → ZZ1_WPOREQI        (ABAP CDS)
3. OData Service     → ZZ1_WPOREQI_CDS    (OData V2 CRUD)
   └── Entity Set    → ZZ1_WPOREQI
   └── Entity Type   → ZZ1_WPOREQIType
   └── FunctionImport→ ZZ1_WPOREQISap_upsert (upsert)
```

---

## Langkah 11: Register OData Items di Gateway

Sama seperti Header, register manual:

1. Tcode **`/n/IWFND/MAINT_SERVICE`**
2. **"Add Service"**
3. Filter:
   - **System Alias:** `LOCAL`
   - **Technical Service Name:** `ZZ1_WPOREQI_CDS`
4. **"Get Services"** → pilih → **"Add Selected Services"**
5. Package: `$TMP` → Save

### Verifikasi:

```
https://sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/?$format=json&sap-client=777
```

Expected:
```json
{
  "d": {
    "EntitySets": ["ZZ1_WPOREQI"]
  }
}
```

---

## Langkah 12: Test CRUD Items

### 12a. READ Items

```bash
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/ZZ1_WPOREQI?\$format=json&sap-client=777"
```

### 12b. CREATE Item

```bash
# Step 1: Fetch CSRF Token
curl -sk -D /tmp/cboi_headers.txt \
  "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/?sap-client=777" \
  -H "X-CSRF-Token: Fetch" -o /dev/null

CSRF=$(grep -i "x-csrf-token" /tmp/cboi_headers.txt | tr -d '\r' | awk '{print $2}')
COOKIES=$(grep -i "set-cookie" /tmp/cboi_headers.txt | \
  sed 's/[Ss]et-[Cc]ookie: //' | cut -d';' -f1 | tr '\n' '; ' | tr -d '\r')

# Step 2: POST Create Item
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/ZZ1_WPOREQI?sap-client=777" \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "X-CSRF-Token: $CSRF" \
  -H "Cookie: $COOKIES" \
  -d '{
    "RequestNo": "REQ-TEST01",
    "ItemNo": "00010",
    "MaterialNo": "TG11",
    "ItemDescription": "Green Tea 500g",
    "Quantity": "100",
    "UoM": "PC",
    "UnitPrice": "50.00",
    "NetAmount": "5000.00",
    "ItemCurrency": "USD",
    "Plant": "1710",
    "MaterialGroup": "L001"
  }'
```

Expected Response (HTTP 201):
```json
{
  "d": {
    "SAP_UUID": "000c29de-8c2b-1fd1-8cdc-6e521faf9da8",
    "RequestNo": "REQ-TEST01",
    "ItemNo": "00010",
    "MaterialNo": "TG11",
    "ItemDescription": "Green Tea 500g",
    "Quantity": "100.00",
    "UoM": "PC",
    "UnitPrice": "50.00",
    "NetAmount": "5000.00",
    "ItemCurrency": "USD",
    "Plant": "1710",
    "MaterialGroup": "L001"
  }
}
```

### 12c. Filter Items by RequestNo

```bash
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/ZZ1_WPOREQI_CDS/ZZ1_WPOREQI?\$filter=RequestNo%20eq%20'REQ-TEST01'&\$format=json&sap-client=777"
```

---

## OData Metadata Items — Referensi Lengkap

```
Service URL:
  /sap/opu/odata/sap/ZZ1_WPOREQI_CDS/

Entity Set:
  ZZ1_WPOREQI

Entity Type:
  ZZ1_WPOREQIType

Key:
  SAP_UUID (Edm.Guid)

Semantic Key:
  RequestNo + ItemNo

Properties:
  ┌───────────────────┬─────────────┬───────────┐
  │ Property          │ Type        │ MaxLength │
  ├───────────────────┼─────────────┼───────────┤
  │ SAP_UUID          │ Edm.Guid    │ —         │ (key, auto)
  │ RequestNo         │ Edm.String  │ 20        │ (mandatory)
  │ ItemNo            │ Edm.String  │ 20        │ (mandatory)
  │ MaterialNo        │ Edm.String  │ 40        │
  │ ItemDescription   │ Edm.String  │ 200       │
  │ Quantity          │ Edm.Decimal │ 10,2      │
  │ UoM               │ Edm.String  │ 20        │
  │ UnitPrice         │ Edm.Decimal │ 10,2      │
  │ NetAmount         │ Edm.Decimal │ 10,2      │
  │ ItemCurrency      │ Edm.String  │ 20        │
  │ Plant             │ Edm.String  │ 20        │
  │ MaterialGroup     │ Edm.String  │ 20        │
  └───────────────────┴─────────────┴───────────┘

FunctionImport:
  ZZ1_WPOREQISap_upsert  → POST (upsert record)

CRUD Operations:
  GET    /ZZ1_WPOREQI              → Read all
  GET    /ZZ1_WPOREQI(guid'xxx')   → Read single
  POST   /ZZ1_WPOREQI              → Create
  PUT    /ZZ1_WPOREQI(guid'xxx')   → Update
  DELETE /ZZ1_WPOREQI(guid'xxx')   → Delete
```

---

## Langkah 13: Pahami Field Mapping — Header vs Items

### Header (ZZ1_WPOREQ) — ⚠️ Ada Label Mismatch

CBO Header field naming menghasilkan **label mismatch** di OData metadata. Berikut mapping yang benar:

```
CBO OData Property     → Actual Data            → po-schema.cds equivalent
══════════════════════════════════════════════════════════════════════════
SAP_UUID (Guid, key)   → Auto-generated UUID     → ID (cuid)
RequestNo              → "REQ-260001"            → requestNo
CompanyCode            → "Office supplies..."     → description ⚠️ (label: PODescription)
Supplier               → "1710"                  → companyCode ⚠️ (label: CompanyCode)
PurchasingOrg          → "1710"                  → purchasingOrg
PurchasingGroup        → "001"                   → purchasingGroup
Supplier1              → "17300001"              → supplier ⚠️ (label: Supplier)
SupplierName           → "Wahyu Amaldi"          → supplierName
OrderDate              → "2026-04-08"            → orderDate
DeliveryDate           → "2026-04-15"            → deliveryDate
POCurrency             → "USD"                   → currency
TotalAmount            → 3020.00                 → totalAmount
PONotes                → "..."                   → notes
POStatus               → "D"                     → status
PODocNumber            → "4500000018"            → sapPONumber
POPostMessage          → "PO created..."         → sapPostMessage
```

> **⚠️ Perhatian:** Field `CompanyCode`, `Supplier`, dan `Supplier1` memiliki label yang salah karena CBO field ordering saat create. Di code, gunakan **OData property name** (bukan label).

### Items (ZZ1_WPOREQI) — ✅ Tidak Ada Mismatch

Items CBO memiliki field naming yang **bersih** — label = property name:

```
CBO OData Property     → Actual Data            → po-schema.cds equivalent
══════════════════════════════════════════════════════════════════════════
SAP_UUID (Guid, key)   → Auto-generated UUID     → ID (cuid)
RequestNo              → "REQ-TEST01"            → parent.requestNo (FK)
ItemNo                 → "00010"                 → itemNo
MaterialNo             → "TG11"                  → materialNo
ItemDescription        → "Green Tea 500g"        → description
Quantity               → 100.00                  → quantity
UoM                    → "PC"                    → uom
UnitPrice              → 50.00                   → unitPrice
NetAmount              → 5000.00                 → netAmount
ItemCurrency           → "USD"                   → currency
Plant                  → "1710"                  → plant
MaterialGroup          → "L001"                  → materialGroup
```

---

## Langkah 14: OData Metadata Header — Referensi Lengkap

```
Service URL:
  /sap/opu/odata/sap/ZZ1_WPOREQ_CDS/

Entity Set:
  ZZ1_WPOREQ

Entity Type:
  ZZ1_WPOREQType

Key:
  SAP_UUID (Edm.Guid)

Properties:
  ┌───────────────────┬─────────────┬───────────┐
  │ Property          │ Type        │ MaxLength │
  ├───────────────────┼─────────────┼───────────┤
  │ SAP_UUID          │ Edm.Guid    │ —         │ (key, auto)
  │ RequestNo         │ Edm.String  │ 20        │
  │ CompanyCode       │ Edm.String  │ 200       │ (= PODescription)
  │ Supplier          │ Edm.String  │ 20        │ (= CompanyCode)
  │ PurchasingOrg     │ Edm.String  │ 20        │
  │ PurchasingGroup   │ Edm.String  │ 20        │
  │ Supplier1         │ Edm.String  │ 20        │ (= Supplier)
  │ SupplierName      │ Edm.String  │ 80        │
  │ OrderDate         │ Edm.DateTime│ —         │ (Date only)
  │ DeliveryDate      │ Edm.DateTime│ —         │ (Date only)
  │ POCurrency        │ Edm.String  │ 20        │
  │ TotalAmount       │ Edm.Decimal │ 10,2      │
  │ PONotes           │ Edm.String  │ 256       │
  │ POStatus          │ Edm.String  │ 20        │
  │ PODocNumber       │ Edm.String  │ 20        │
  │ POPostMessage     │ Edm.String  │ 200       │
  └───────────────────┴─────────────┴───────────┘

CRUD Operations:
  GET    /ZZ1_WPOREQ              → Read all
  GET    /ZZ1_WPOREQ(guid'xxx')   → Read single
  POST   /ZZ1_WPOREQ              → Create
  PUT    /ZZ1_WPOREQ(guid'xxx')   → Update
  DELETE /ZZ1_WPOREQ(guid'xxx')   → Delete
```

---

## Langkah 15: CDS View di ABAP (Referensi)

CBO menghasilkan ABAP CDS view yang bisa dilihat di ADT:

```sql
-- ADT: adt://SBX/sap/bc/adt/ddic/ddl/sources/zz1_wporeq/source/main

@AbapCatalog.sqlViewName: 'ZZ1_282414C4B839'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.compositionRoot: true
@ObjectModel.transactionalProcessingEnabled: true
@ObjectModel.createEnabled: true
@ObjectModel.deleteEnabled: true
@ObjectModel.updateEnabled: true
@ObjectModel.writeActivePersistence: 'ZZ1_80BE1DF18710'

define view ZZ1_WPOREQ as select from ZZ1_80BE1DF18710 as Node
{
    key SAP_UUID,
    Node.RequestNo,
    Node.CompanyCode,     // label: PODescription (actual = description)
    Node.Supplier,        // label: CompanyCode   (actual = companyCode)
    Node.PurchasingOrg,
    Node.PurchasingGroup,
    Node.Supplier1,       // label: Supplier      (actual = supplier)
    Node.SupplierName,
    Node.OrderDate,
    Node.DeliveryDate,
    Node.POCurrency,
    Node.TotalAmount,
    Node.PONotes,
    Node.POStatus,
    Node.PODocNumber,
    Node.POPostMessage
}
```

> **Note:** Annotations `@ObjectModel.createEnabled/deleteEnabled/updateEnabled: true` memungkinkan CRUD via OData. Annotation ini otomatis di-generate saat CBO di-publish.

---

## ✅ Checkpoint — Apa yang Sudah Dicapai

```
CBO Created & Published:
═══════════════════════════════════════════

  ┌─────────────────────────────────────────┐
  │  SAP S/4HANA (sap.ilmuprogram.com:777)  │
  │                                         │
  │  CBO Header: ZZ1_WPOREQ                 │
  │  ├── Table: ZZ1_80BE1DF18710             │
  │  ├── CDS View: ZZ1_WPOREQ               │
  │  ├── OData: ZZ1_WPOREQ_CDS              │
  │  │   └── Entity: ZZ1_WPOREQ             │
  │  └── Gateway: Registered ✅             │
  │                                         │
  │  CBO Items: ZZ1_WPOREQI                  │
  │  ├── Table: ZZ1_xxxxxxxx                 │
  │  ├── CDS View: ZZ1_WPOREQI              │
  │  ├── OData: ZZ1_WPOREQI_CDS             │
  │  │   └── Entity: ZZ1_WPOREQI            │
  │  └── Gateway: Registered ✅             │
  │                                         │
  │  Relasi: RequestNo (logical FK)          │
  │  ZZ1_WPOREQ.RequestNo ←→               │
  │       ZZ1_WPOREQI.RequestNo              │
  │                                         │
  │  Test Data:                              │
  │  └── Header: REQ-TEST01 | 17300001      │
  │  └── Item:   00010 | TG11 Green Tea     │
  │              qty=100 PC | $5,000.00      │
  └─────────────────────────────────────────┘

  Header OData   READ    ✅
  Header OData   CREATE  ✅
  Items OData    READ    ✅
  Items OData    CREATE  ✅ (HTTP 201)
```

---

## 🔗 Lanjut ke Hands-on Berikutnya

| Hands-on | Topik |
|:---------|:------|
| ← [Hands-on 3](handson-3-odata-testing.md) | OData Testing & HANA Cloud |
| → **Hands-on 5** | CAP + Remote Entity → CBO (po-project-in-apps) |

> **Hands-on 5** akan membuat CAP project baru (`po-project-in-apps`) yang **consume CBO** sebagai remote entity — data disimpan di SAP S/4HANA, CAP sebagai logic layer + Fiori UI.
