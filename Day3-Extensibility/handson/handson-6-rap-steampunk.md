# Hands-on 6: Embedded Steampunk — RAP PO Request (ABAP Cloud)

> **Durasi:** ~90 menit  
> **Prerequisite:** ADT (Eclipse) terinstall + koneksi ke `sap.ilmuprogram.com` (client 777)  
> **Kategori:** 2 — In-App Extensibility (Developer)  
> **Bahasa:** ABAP Cloud (bukan Node.js)  
> **Database:** SAP HANA embedded (di dalam S/4HANA, bukan HANA Cloud BTP)

---

## Tujuan

Membuat **PO Request system yang sama** dengan po-project dan po-project-in-apps, tetapi **100% di dalam SAP S/4HANA** menggunakan **RAP (RESTful ABAP Programming Model)** — pendekatan "Embedded Steampunk".

### Apa yang Dibangun

```
po-project-steampunk (semua di ADT/Eclipse, bukan VS Code):
═══════════════════════════════════════════════════════════

ABAP Objects:
├── ZTEC_POREQ           ← Database Table (header)
├── ZTEC_POREQI          ← Database Table (items)
├── ZR_TEC_POREQ         ← CDS Interface View (Root, header)
├── ZR_TEC_POREQI        ← CDS Interface View (Child, items)
├── ZC_TEC_POREQ         ← CDS Consumption View (projected header)
├── ZC_TEC_POREQI        ← CDS Consumption View (projected items)
├── ZR_TEC_POREQ (BDEF)  ← Behavior Definition (CRUD + postToSAP)
├── ZBP_TEC_POREQ        ← Behavior Implementation (ABAP class)
├── ZUI_TEC_POREQ_O4     ← Service Definition
└── ZUI_TEC_POREQ_BND    ← Service Binding (OData V4 UI)

Flow:
  Fiori Preview ──▶ OData V4 (RAP) ──▶ ABAP Cloud ──▶ HANA (embedded)
                                            │
                                            │ postToSAP() action
                                            ▼
                                  MM_PUR_PO_MAINT_V2_SRV
```

### Perbandingan 3 Pendekatan

| Aspek | po-project (CAP) | po-project-in-apps (CBO) | **Hands-on 6 (RAP)** |
|:------|:-----------------|:-------------------------|:---------------------|
| IDE | VS Code | VS Code | **ADT (Eclipse)** |
| Bahasa | Node.js + CDS | Node.js + CDS | **ABAP Cloud** |
| Runtime | BTP Cloud Foundry | BTP CF | **S/4HANA ABAP** |
| Framework | CAP | CAP + CBO Client | **RAP** |
| Database | HANA Cloud / SQLite | SAP CBO table | **HANA (embedded)** |
| OData | CAP auto V4 | CAP V4 → CBO V2 | **RAP auto V2/V4** |
| Fiori | annotations.cds | annotations.cds | **CDS annotations (ABAP)** |
| Draft support | CAP managed | Manual | **RAP Managed (native)** |
| Deep insert | ✅ Composition | ❌ Separate CBO | **✅ Composition** |
| BTP needed | Ya | Ya | **Tidak** |
| DB cost | $0–€693/bln | $0 | **$0** |

---

## Glosarium Keyword RAP

Sebelum mulai coding, pahami keyword dan konsep utama yang akan digunakan.

### A. Arsitektur RAP — Layer & Naming Convention

```
RAP memiliki 3 layer terpisah (bukan 1 file seperti CAP):
═══════════════════════════════════════════════════════════

Layer 1: DATA MODEL (Database Table)
  ZTEC_POREQ, ZTEC_POREQI
  → Tabel fisik di HANA, berisi definisi kolom + tipe data

Layer 2: BUSINESS OBJECT (CDS Views + Behavior)
  ZR_TEC_POREQ  = Interface View  (R_ = "Reuse/Root")
  ZC_TEC_POREQ  = Consumption View (C_ = "Consumption/Projection")
  ZR_TEC_POREQ  = Behavior Definition (BDEF, attached to R_ view)
  ZBP_TEC_POREQ = Behavior Implementation (BP_ = "Behavior Pool")
  → Business logic, validasi, kalkulasi

Layer 3: SERVICE (Exposure ke dunia luar)
  ZUI_TEC_POREQ_O4  = Service Definition (UI_ = "UI service", O4 = "OData V4")
  ZUI_TEC_POREQ_BND = Service Binding (BND = "Binding")
  → Endpoint OData untuk Fiori / external consumer
```

**Naming convention Z-prefix:**

| Prefix | Arti | Contoh |
|:-------|:-----|:-------|
| `Z` / `ZZ1_` | Customer namespace (Z = custom object) | `ZTEC_POREQ` |
| `ZR_` | Interface (Reuse) CDS View — the "truth" layer | `ZR_TEC_POREQ` |
| `ZC_` | Consumption (Projection) CDS View — what consumer sees | `ZC_TEC_POREQ` |
| `ZBP_` | Behavior Pool (ABAP Class) — business logic | `ZBP_TEC_POREQ` |
| `ZUI_` | Service Definition/Binding — OData exposure | `ZUI_TEC_POREQ_O4` |
| `ZTEC_D_` | Draft table — auto-generated oleh framework | `ZTEC_D_POREQ` |

**Kenapa 2 layer CDS (R_ dan C_)?**

```
Analogi CAP:
  db/po-schema.cds   ≈  ZR_ (Interface) — "sumber data"
  srv/po-service.cds  ≈  ZC_ (Consumption) — "apa yang di-expose"

CAP menggabungkan keduanya.
RAP memisahkan supaya satu R_ view bisa di-consume
oleh banyak C_ projection (misalnya: UI, API, analytics).
```

### B. Table Annotations & Data Types

**Annotations di table definition:**

| Annotation | Nilai | Penjelasan |
|:-----------|:------|:-----------|
| `@AbapCatalog.tableCategory` | `#TRANSPARENT` | Tabel standar ABAP — 1 tabel = 1 tabel di database HANA. Alternatif: `#STRUCTURE` (hanya structure, tidak buat tabel fisik) |
| `@AbapCatalog.deliveryClass` | `#A` | Application table — data diisi oleh user/aplikasi. Alternatif: `#C` (customizing), `#S` (system), `#L` (temporary) |
| `@AbapCatalog.dataMaintenance` | `#RESTRICTED` | Tidak bisa diedit via SM30/SE16. Hanya lewat program/OData |
| `@AbapCatalog.enhancement.category` | `#NOT_EXTENSIBLE` | Tabel tidak boleh di-extend oleh customer lain (best practice untuk Clean Core) |
| `@EndUserText.label` | `'...'` | Deskripsi tabel — tampil di ABAP Dictionary |

**Data types ABAP yang dipakai:**

| Type | Contoh | Penjelasan | Setara CAP |
|:-----|:-------|:-----------|:-----------|
| `abap.char(n)` | `abap.char(200)` | Fixed-length character string | `String(200)` |
| `abap.clnt` | `abap.clnt` | SAP Client (3 digit: 000-999). **Wajib ada di setiap tabel** — SAP multi-tenant | Tidak ada di CAP |
| `sysuuid_x16` | `sysuuid_x16` | UUID 16 bytes (RAW16 format). Key utama untuk RAP | `cuid` (UUID) |
| `abap.dats` | `abap.dats` | Date (YYYYMMDD, 8 char). Format internal SAP | `Date` |
| `abap.cuky(5)` | `abap.cuky(5)` | Currency key (ISO 4217: USD, EUR). **Wajib** dipasangkan dengan `abap.curr` | `String(3)` |
| `abap.curr(p,s)` | `abap.curr(15,2)` | Currency amount. **Harus punya** `@Semantics.amount.currencyCode` ke field `cuky` | `Decimal(15,2)` |
| `abap.quan(p,s)` | `abap.quan(10,2)` | Quantity. **Harus punya** `@Semantics.quantity.unitOfMeasure` ke field `unit` | `Decimal(10,2)` |
| `abap.unit(3)` | `abap.unit(3)` | Unit of measure (PC, KG, EA) | `String(3)` |
| `timestampl` | `timestampl` | Timestamp long (UTC, precision 7 decimal). Untuk audit trail | `Timestamp` |
| `syuname` | `syuname` | SAP username (12 char). Untuk `created_by`, `last_changed_by` | `managed` → `createdBy` |

> **client field:** Setiap tabel SAP S/4HANA **wajib** memiliki `key client : abap.clnt`. Ini memastikan data terpisah per tenant (client 777 tidak bisa lihat data client 800). CAP tidak butuh ini karena BTP menggunakan tenant isolation level yang berbeda.

### C. CDS View Keywords

**Interface View (R_):**

| Keyword | Penjelasan |
|:--------|:-----------|
| `define root view entity` | CDS View yang menjadi "root" (parent) dari Business Object. Hanya 1 root per BO. Fitur khusus: bisa punya Behavior Definition |
| `define view entity` | CDS View biasa (child). Bukan root. Digunakan untuk item/child entity |
| `as select from ztec_poreq` | Data source — ambil data dari tabel `ztec_poreq` |
| `composition [0..*] of ZR_TEC_POREQI as _Items` | **Composition** = parent "memiliki" child. Jika parent dihapus, child ikut terhapus. `[0..*]` = zero to many. `_Items` = nama association (awali dengan underscore) |
| `association to parent ZR_TEC_POREQ as _PORequest` | Asosiasi balik dari child ke parent. Kata `parent` menandakan ini composition child |
| `$projection.RequestUUID = _PORequest.RequestUUID` | ON condition: field di child (`$projection` = current view) di-join ke field di parent |
| `key request_uuid as RequestUUID` | Alias field: kolom DB `request_uuid` di-expose sebagai `RequestUUID` (CamelCase) |
| `case ... when ... then ... end as StatusCriticality` | Calculated field: CDS expression yang dihitung saat runtime (tidak disimpan di DB) |

**Semantics Annotations di CDS:**

| Annotation | Penjelasan |
|:-----------|:-----------|
| `@Semantics.amount.currencyCode: 'Currency'` | "Field ini adalah amount, dan currency-nya ada di field `Currency`" — wajib untuk `curr` type |
| `@Semantics.quantity.unitOfMeasure: 'UoM'` | "Field ini adalah quantity, unit-nya ada di field `UoM`" — wajib untuk `quan` type |
| `@Semantics.user.createdBy: true` | RAP framework otomatis isi field ini dengan `sy-uname` saat CREATE |
| `@Semantics.systemDateTime.createdAt: true` | RAP framework otomatis isi dengan timestamp saat CREATE |
| `@Semantics.user.lastChangedBy: true` | Otomatis diupdate saat UPDATE |
| `@Semantics.systemDateTime.lastChangedAt: true` | Otomatis diupdate saat UPDATE. Digunakan untuk **optimistic locking** (ETag) |
| `@Semantics.systemDateTime.localInstanceLastChangedAt: true` | Timestamp perubahan terakhir per-instance (untuk draft sync) |

> **Perbandingan dengan CAP:**
> ```
> CAP:  entity PORequests : cuid, managed { ... }
>       // cuid → otomatis tambah ID : UUID
>       // managed → otomatis tambah createdAt, createdBy, modifiedAt, modifiedBy
>
> RAP:  Semua field ditulis manual di table + ditandai @Semantics di CDS view
>       // Lebih verbose, tapi lebih eksplisit
> ```

**Consumption View (C_):**

| Keyword | Penjelasan |
|:--------|:-----------|
| `as projection on ZR_TEC_POREQ` | "View ini adalah projection dari Interface View" — hanya bisa re-expose field yang sudah ada di R_ view |
| `provider contract transactional_query` | **Kontrak** yang menyatakan view ini akan digunakan untuk transaksi (CRUD). Alternatif: `analytical_query` (untuk reporting) |
| `redirected to composition child ZC_TEC_POREQI` | Mengarahkan ulang composition dari `ZR_TEC_POREQI` ke `ZC_TEC_POREQI` — supaya consumer melihat projection, bukan interface |
| `redirected to parent ZC_TEC_POREQ` | Sama, tapi untuk asosiasi parent dari child view |
| `@Metadata.allowExtensions: true` | Izinkan Metadata Extension (file terpisah untuk UI annotations). Best practice: annotations di extension, bukan di view |
| `@Search.searchable: true` | Enable Fiori search bar di List Report |
| `@Search.defaultSearchElement: true` | Field ini akan di-search saat user mengetik di search bar |
| `@ObjectModel.semanticKey: ['RequestNo']` | "Human-readable key untuk entity ini adalah RequestNo" — Fiori akan tampilkan ini, bukan UUID |
| `@ObjectModel.text.element: ['SupplierName']` | "Field Supplier punya text description di field SupplierName" — Fiori tampilkan keduanya |

### D. Behavior Definition Keywords

**Header keywords:**

| Keyword | Penjelasan |
|:--------|:-----------|
| `managed` | **Implementation type.** RAP framework otomatis handle CRUD ke database. Anda hanya perlu tulis business logic tambahan. Alternatif: `unmanaged` (anda handle semua sendiri, seperti `ON` handlers di CAP CBO project) |
| `implementation in class ZBP_TEC_POREQ unique` | "Business logic ada di class `ZBP_TEC_POREQ`." `unique` = hanya 1 class untuk BO ini |
| `strict ( 2 )` | Strict mode level 2 — enforce best practices. Misal: wajib punya authorization, field control eksplisit. Angka lebih tinggi = lebih ketat |
| `with draft` | Enable **Draft Handling** — user bisa save draft (belum final) dan lanjutkan nanti. Fiori "Edit" button muncul otomatis |
| `persistent table ztec_poreq` | "Data aktif (bukan draft) disimpan di tabel ini" |
| `draft table ztec_d_poreq` | "Data draft disimpan di tabel ini." **Auto-generated** oleh framework saat activate |
| `etag master LocalLastChanged` | **ETag** untuk optimistic concurrency. Jika 2 user edit bersamaan, yang save duluan menang, yang kedua dapat error. Field `LocalLastChanged` jadi "versi" |
| `lock master` | Entity ini yang mengelola lock. Child entity memakai `lock dependent` |
| `total etag LastChangedAt` | ETag untuk keseluruhan BO (termasuk semua child). Berubah jika header ATAU item berubah |
| `authorization master ( global )` | Authorization check di level root entity. `global` = check sekali untuk seluruh BO |
| `alias PORequest` | Nama pendek untuk entity ini. Dipakai di ABAP: `ENTITY PORequest` bukan `ENTITY ZR_TEC_POREQ` |

**CRUD & Draft operations:**

| Keyword | Penjelasan |
|:--------|:-----------|
| `create` / `update` / `delete` | Enable operasi CRUD standar. **Managed = framework handle SQL INSERT/UPDATE/DELETE** |
| `draft action Edit` | Tombol "Edit" di Fiori → copy data aktif ke draft table |
| `draft action Activate optimized` | Tombol "Save" di Fiori → validasi + pindahkan draft ke tabel aktif. `optimized` = hanya update field yang berubah |
| `draft action Discard` | Tombol "Cancel" → hapus draft, kembali ke data aktif |
| `draft action Resume` | Buka kembali draft yang ditinggalkan (navigasi away lalu kembali) |
| `draft determine action Prepare` | Dipanggil **sebelum Activate** — tempat menjalankan semua validasi. Fiori side-effect |

**Business logic keywords:**

| Keyword | Penjelasan | Setara CAP |
|:--------|:-----------|:-----------|
| `determination setRequestNo on modify { create; }` | **Determination** = logic yang otomatis jalan saat kondisi terpenuhi. `on modify` = saat data berubah (belum save). `{ create; }` = hanya trigger saat CREATE | `this.before('CREATE', ...)` |
| `validation validateSupplier on save { ... field Supplier; }` | **Validation** = cek aturan bisnis. `on save` = saat user klik Save/Activate. `field Supplier` = trigger saat field Supplier berubah | `this.before('SAVE', ...)` |
| `action postToSAP result [1] $self` | **Action** = operasi custom (tombol di Fiori). `result [1]` = return 1 instance. `$self` = return entity yang sama (PORequest) | `action postToSAP()` di CDS + handler di JS |
| `field ( readonly ) RequestNo` | Field ini read-only — user tidak bisa edit di Fiori | `@readonly` di CDS |
| `field ( readonly : update ) Status` | Read-only saat update, tapi bisa diset saat create. Berguna untuk: set initial value, lalu lock | Tidak ada direct equivalent |
| `association _Items { create; with draft; }` | Items bisa di-CREATE melalui parent (deep insert) + support draft | `Composition of many` di CAP |

**Child behavior keywords:**

| Keyword | Penjelasan |
|:--------|:-----------|
| `lock dependent by _PORequest` | "Saya (item) di-lock oleh parent (PORequest)." Jika parent locked, items juga locked |
| `authorization dependent by _PORequest` | "Auth check saya ikut parent." Tidak perlu auth check terpisah untuk items |

**Mapping:**

```abap
mapping for ztec_poreq {
  RequestUUID = request_uuid;   // CDS field = DB column
  RequestNo   = request_no;
}
```

Mapping menghubungkan nama CDS (CamelCase) dengan nama kolom DB (snake_case). **Wajib** jika nama berbeda. Di CAP, mapping ini otomatis karena CDS langsung generate tabel.

### E. Behavior Implementation — EML (Entity Manipulation Language)

EML adalah "SQL-nya RAP" — cara baca/tulis data di dalam behavior implementation:

| Statement | Penjelasan | Setara |
|:----------|:-----------|:-------|
| `READ ENTITIES OF ZR_TEC_POREQ` | Baca data dari Business Object | `SELECT.from(PORequests)` di CAP |
| `MODIFY ENTITIES OF ZR_TEC_POREQ` | Ubah data di Business Object | `UPDATE(PORequests)` di CAP |
| `IN LOCAL MODE` | Bypass authorization & feature control. Digunakan di dalam behavior (trust internal logic) | Tidak perlu di CAP |
| `ENTITY PORequest` | Target entity (pakai alias dari BDEF) | `.from('PORequests')` |
| `FIELDS ( RequestNo, Status )` | Hanya baca field tertentu (performance) | `.columns('requestNo', 'status')` |
| `ALL FIELDS` | Baca semua field | `.columns('*')` |
| `WITH CORRESPONDING #( keys )` | Filter berdasarkan keys yang di-pass ke method | `.where({ ID: req.data.ID })` |
| `RESULT DATA(requests)` | Simpan hasil ke variable lokal `requests` | `const requests = await ...` |
| `UPDATE FIELDS ( Status ) WITH VALUE #( ... )` | Update field tertentu dengan value baru | `await UPDATE(PORequests).set(...)` |

**Special variables (%tky, %msg, %element):**

| Variable | Penjelasan |
|:---------|:-----------|
| `%tky` | **Transactional Key** — unique identifier dalam transaksi. Berisi key fields + `%is_draft` flag. Selalu pakai `%tky` untuk identifikasi, bukan field langsung |
| `%msg` | Message — error/warning/info message yang ditampilkan ke user |
| `%element-Supplier` | Menandai field mana yang error — Fiori akan highlight field tersebut dengan merah |
| `keys` | Parameter input ke method — berisi key fields dari entity yang trigger determination/validation |
| `reported-porequest` | Table untuk mengumpulkan messages. `porequest` = lowercase alias |
| `failed-porequest` | Table untuk menandai entity mana yang gagal. RAP framework akan rollback entity ini |

**Inline declarations:**

```abap
DATA(lv_year) = sy-datum+2(2).       " Deklarasi + assign sekaligus (ABAP 7.40+)
CONV i( lv_max_no+5(4) )             " Convert substring ke integer
|REQ-{ lv_year }{ lv_seq WIDTH = 4 }|  " String template (seperti template literal JS)
COND #( WHEN x IS INITIAL THEN 'D' ELSE x )  " Conditional expression (seperti ternary)
VALUE #( ( field1 = val1 ) )          " Value constructor — buat structure/table inline
REDUCE decfloat34( INIT sum = 0 FOR item IN items NEXT sum = sum + item-NetAmount )
                                      " Reduce — seperti Array.reduce() di JavaScript
```

### F. Metadata Extension & UI Annotations

| Annotation | Penjelasan |
|:-----------|:-----------|
| `@Metadata.layer: #CUSTOMER` | Layer annotation ini. `#CUSTOMER` = bisa di-override oleh customer. Hierarchy: `#CORE` < `#PARTNER` < `#CUSTOMER` |
| `@UI.headerInfo` | Info yang tampil di header Object Page: `typeName` (singular), `typeNamePlural`, `title`, `description` |
| `@UI.facet` | Definisi section/tab di Object Page. `#IDENTIFICATION_REFERENCE` = form fields, `#LINEITEM_REFERENCE` = table (items), `#FIELDGROUP_REFERENCE` = group of fields |
| `@UI.lineItem` | Field tampil di kolom List Report (tabel). `position` = urutan kolom |
| `@UI.identification` | Field tampil di form Object Page. `position` = urutan field |
| `@UI.selectionField` | Field tampil di filter bar (di atas list report). Untuk search/filter |
| `@UI.fieldGroup: [{ qualifier: 'SAPInfo' }]` | Field dikelompokkan dalam group bernama `SAPInfo`. Ditampilkan oleh `#FIELDGROUP_REFERENCE` facet |
| `@UI.hidden: true` | Field disembunyikan dari UI (teknis field: UUID, criticality) |
| `criticality: 'StatusCriticality'` | Warna status berdasarkan field `StatusCriticality`: `0`=netral, `1`=merah, `2`=kuning, `3`=hijau |

> **Perbandingan dengan CAP annotations.cds:**
> ```
> CAP:  @UI.LineItem: [{ Value: requestNo, Label: 'Request No' }]
> RAP:  @UI.lineItem: [{ position: 10 }]
>       RequestNo;
>
> // CAP: annotations inline di annotate block
> // RAP: annotations per-field di Metadata Extension
> // Hasil Fiori: identik
> ```

### G. Service Layer Keywords

| Keyword | Penjelasan |
|:--------|:-----------|
| `define service ZUI_TEC_POREQ_O4` | Definisikan service — kumpulan entity yang di-expose ke OData |
| `expose ZC_TEC_POREQ as PORequest` | "Tampilkan entity `ZC_TEC_POREQ` sebagai `PORequest` di OData". Consumer melihat nama `PORequest`, bukan `ZC_TEC_POREQ` |
| **Service Binding** | Object terpisah (bukan CDS) — menentukan **protocol** (OData V2/V4) dan **binding type** (UI/Web API). Satu Service Definition bisa punya banyak Binding |
| `OData V4 - UI` | Binding type: OData V4 untuk Fiori UI (full draft support). Alternatif: `OData V2 - UI`, `OData V4 - Web API` (untuk external integration) |
| **Publish** | Tombol di Service Binding → register endpoint ke ICF (Internet Communication Framework). Setelah publish, OData URL aktif |
| **Preview** | Tombol di Service Binding → buka Fiori Elements preview di browser. Auto-generate UI dari CDS annotations |

### H. Projection Behavior Keywords

```abap
projection;                    // Karakter behavior: ini projection, bukan implementation
use draft;                     // Forward draft handling dari R_ ke C_
use create;                    // Forward CREATE operation
use action postToSAP;          // Forward custom action
use association _Items { create; with draft; }  // Forward composition
```

**Kenapa perlu Projection Behavior?**

Di RAP, Behavior Definition ada di 2 level:
1. **Interface BDEF (R_)** — definisi lengkap: `managed`, `determination`, `validation`, `mapping`
2. **Projection BDEF (C_)** — hanya "forward/use" operasi yang mau di-expose

Ini memungkinkan: satu BO dengan banyak projections, masing-masing expose subset operasi yang berbeda.

---

## Prerequisite: Setup ADT

### 1. Install Eclipse + ADT Plugin

Jika belum terinstall:

1. Download **Eclipse IDE for Java Developers** (2023-12+):
   ```
   https://www.eclipse.org/downloads/packages/
   ```

2. Install ADT plugin:
   - Eclipse → Help → Install New Software
   - Add: `https://tools.hana.ondemand.com/latest`
   - Centang: **ABAP Development Tools**
   - Install → Restart Eclipse

### 2. Create ABAP Project di ADT

1. **File → New → ABAP Project**
2. Connection:
   - System ID: `SBX`
   - Connection Type: **Custom Application Server**
   - Application Server: `sap.ilmuprogram.com`
   - Instance Number: `00`
   - System ID: `SBX` (atau sesuaikan)
3. Login:
   - Client: `777`
   - User: `wahyu.amaldi`
   - Password: `Pas671_ok12345`
   - Language: `EN`
4. Klik **Finish** → ABAP project terbuat di Project Explorer

> **Troubleshooting:** Jika koneksi gagal, pastikan port 443 (HTTPS) terbuka. ADT menggunakan HTTP/HTTPS, bukan SAP GUI protocol.

---

## Langkah 1: Buat Database Tables

### 1a. Table Header — `ZTEC_POREQ`

Klik kanan package `$TMP` → **New → Other ABAP Repository Object → Dictionary → Database Table**

Name: `ZTEC_POREQ`  
Description: `TEC Rise - PO Request Header`

```abap
@EndUserText.label : 'TEC Rise - PO Request Header'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztec_poreq {

  key client         : abap.clnt not null;       " Wajib! Multi-tenant SAP (client 777)
  key request_uuid   : sysuuid_x16 not null;     " UUID 16-byte (setara cuid di CAP)
  request_no         : abap.char(20);
  description        : abap.char(200);
  company_code       : abap.char(4);
  purchasing_org     : abap.char(4);
  purchasing_group   : abap.char(3);
  supplier           : abap.char(10);
  supplier_name      : abap.char(80);
  order_date         : abap.dats;                " Date format YYYYMMDD
  delivery_date      : abap.dats;
  currency           : abap.cuky(5);             " Currency key (USD, EUR)
  @Semantics.amount.currencyCode : 'ztec_poreq.currency'
  total_amount       : abap.curr(15,2);          " Harus pair dengan cuky field ↑
  notes              : abap.char(256);
  status             : abap.char(1);
  sap_po_number      : abap.char(10);
  sap_post_message   : abap.char(200);
  created_by         : syuname;                  " SAP username (setara managed.createdBy)
  created_at         : timestampl;               " Timestamp long UTC
  last_changed_by    : syuname;
  last_changed_at    : timestampl;
  local_last_changed : timestampl;               " Untuk ETag (optimistic locking)

}
```

> **Lihat [Glosarium B](#b-table-annotations--data-types)** untuk penjelasan lengkap setiap annotation dan data type.

Tekan **Ctrl+F3** → Activate

### 1b. Table Items — `ZTEC_POREQI`

Name: `ZTEC_POREQI`  
Description: `TEC Rise - PO Request Item`

```abap
@EndUserText.label : 'TEC Rise - PO Request Item'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztec_poreqi {

  key client         : abap.clnt not null;
  key item_uuid      : sysuuid_x16 not null;
  request_uuid       : sysuuid_x16 not null;
  request_no         : abap.char(20);
  item_no            : abap.char(5);
  material_no        : abap.char(40);
  description        : abap.char(200);
  @Semantics.quantity.unitOfMeasure : 'ztec_poreqi.uom'
  quantity           : abap.quan(10,2);
  uom                : abap.unit(3);
  @Semantics.amount.currencyCode : 'ztec_poreqi.currency'
  unit_price         : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'ztec_poreqi.currency'
  net_amount         : abap.curr(15,2);
  currency           : abap.cuky(5);
  plant              : abap.char(4);
  material_group     : abap.char(9);
  created_by         : syuname;
  created_at         : timestampl;
  last_changed_by    : syuname;
  last_changed_at    : timestampl;
  local_last_changed : timestampl;

}
```

Activate **Ctrl+F3**

### Perbandingan dengan po-project

```
po-project (CDS CAP):                    RAP (ABAP CDS):
═════════════════════                     ═══════════════

entity PORequests : cuid, managed {       define table ztec_poreq {
  requestNo    : String(10);                key request_uuid : sysuuid_x16;
  description  : String(200);              request_no       : abap.char(20);
  supplier     : String(10);               supplier         : abap.char(10);
  ...                                      ...
  items : Composition of many              " Composition di CDS view, bukan di table
          PORequestItems;
}                                         }
```

> **Perbedaan utama:** Di CAP, `cuid` + `managed` otomatis menambah UUID + audit fields. Di RAP, semua field harus didefinisikan manual di table.

---

## Langkah 2: CDS Interface Views (R_)

> **⚠️ Circular Dependency:** Root punya `composition of ZR_TEC_POREQI`, child punya `association to parent ZR_TEC_POREQ`.  
> Keduanya saling referensi — **tidak bisa di-activate satu-satu**.  
> **Solusi:** Buat kedua views (2a + 2b), lalu select keduanya di Project Explorer → klik kanan → **Activate** bersamaan.

### 2a. Child View — `ZR_TEC_POREQI`

Klik kanan `$TMP` → **New → Core Data Services → Data Definition**

Name: `ZR_TEC_POREQI`  
Description: `TEC Rise - PO Request Item (Interface)`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TEC Rise - PO Request (Interface)'
define root view entity ZR_TEC_POREQ
  as select from ztec_poreq
  composition [0..*] of ZR_TEC_POREQI as _Items
{
  key request_uuid      as RequestUUID,
      request_no        as RequestNo,
      description       as Description,
      company_code      as CompanyCode,
      purchasing_org    as PurchasingOrg,
      purchasing_group  as PurchasingGroup,
      supplier          as Supplier,
      supplier_name     as SupplierName,
      order_date        as OrderDate,
      delivery_date     as DeliveryDate,
      @Semantics.amount.currencyCode: 'Currency'
      total_amount      as TotalAmount,
      currency          as Currency,
      notes             as Notes,
      status            as Status,
      sap_po_number     as SAPPONumber,
      sap_post_message  as SAPPostMessage,

      // Criticality for status (like statusCriticality in CAP)
      case status
        when 'D' then 0  // Draft = neutral
        when 'P' then 3  // Posted = positive (green)
        when 'E' then 1  // Error = negative (red)
        else 0
      end                 as StatusCriticality,

      // Admin fields
      @Semantics.user.createdBy: true
      created_by        as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at        as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by   as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at   as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed as LocalLastChanged,

      // Composition
      _Items
}
```

Activate

### 2b. Child View — `ZR_TEC_POREQI`

Name: `ZR_TEC_POREQI`  
Description: `TEC Rise - PO Request Item (Interface)`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TEC Rise - PO Request Item (Interface)'
define view entity ZR_TEC_POREQI
  as select from ztec_poreqi
  association to parent ZR_TEC_POREQ as _PORequest
    on $projection.RequestUUID = _PORequest.RequestUUID
{
  key item_uuid        as ItemUUID,
      request_uuid     as RequestUUID,
      request_no       as RequestNo,
      item_no          as ItemNo,
      material_no      as MaterialNo,
      description      as Description,
      @Semantics.quantity.unitOfMeasure: 'UoM'
      quantity          as Quantity,
      uom              as UoM,
      @Semantics.amount.currencyCode: 'Currency'
      unit_price       as UnitPrice,
      @Semantics.amount.currencyCode: 'Currency'
      net_amount       as NetAmount,
      currency         as Currency,
      plant            as Plant,
      material_group   as MaterialGroup,

      @Semantics.user.createdBy: true
      created_by       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at       as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by  as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at  as LastChangedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed as LocalLastChanged,

      // Association back to parent
      _PORequest
}
```

Activate

### Perbandingan CDS: CAP vs RAP

```
CAP CDS (db/po-schema.cds):             RAP CDS (ADT):
════════════════════════                 ═══════════════

entity PORequests : cuid, managed {     define root view entity ZR_TEC_POREQ
  requestNo : String(10);                as select from ztec_poreq
  items : Composition of many           composition [0..*] of ZR_TEC_POREQI
    PORequestItems on items.parent =    {
    $self;                                key request_uuid  as RequestUUID,
}                                         request_no       as RequestNo,
                                          _Items
                                        }

// CAP: Composition di entity definition
// RAP: Composition di CDS view → tabel terpisah
// CAP: cuid otomatis generate UUID
// RAP: sysuuid_x16 + manual numbering di behavior
```

---

## Langkah 3: CDS Consumption Views (C_)

### 3a. Consumption Header — `ZC_TEC_POREQ`

Name: `ZC_TEC_POREQ`  
Description: `TEC Rise - PO Request (Consumption)`  
Template: **Define Projection View**

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TEC Rise - PO Request (Consumption)'
@Metadata.allowExtensions: true
@Search.searchable: true
@ObjectModel.semanticKey: ['RequestNo']
define root view entity ZC_TEC_POREQ
  provider contract transactional_query
  as projection on ZR_TEC_POREQ
{
  key RequestUUID,

      @Search.defaultSearchElement: true
      RequestNo,

      @Search.defaultSearchElement: true
      Description,

      CompanyCode,
      PurchasingOrg,
      PurchasingGroup,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['SupplierName']
      Supplier,
      SupplierName,

      OrderDate,
      DeliveryDate,
      TotalAmount,
      Currency,
      Notes,

      @Search.defaultSearchElement: true
      Status,
      StatusCriticality,

      SAPPONumber,
      SAPPostMessage,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChanged,

      // Composition redirect
      _Items : redirected to composition child ZC_TEC_POREQI
}
```

### 3b. Consumption Items — `ZC_TEC_POREQI`

```abap
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'TEC Rise - PO Request Item (Consumption)'
@Metadata.allowExtensions: true
define view entity ZC_TEC_POREQI
  as projection on ZR_TEC_POREQI
{
  key ItemUUID,
      RequestUUID,
      RequestNo,
      ItemNo,
      MaterialNo,
      Description,
      Quantity,
      UoM,
      UnitPrice,
      NetAmount,
      Currency,
      Plant,
      MaterialGroup,

      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      LocalLastChanged,

      _PORequest : redirected to parent ZC_TEC_POREQ
}
```

Activate both

---

## Langkah 4: Metadata Extension (Fiori Annotations)

### 4a. Header Annotations — `ZC_TEC_POREQ`

Klik kanan `ZC_TEC_POREQ` → **New Metadata Extension**  
Name: `ZC_TEC_POREQ` (sama)

```abap
@Metadata.layer: #CUSTOMER
@UI.headerInfo: {
  typeName: 'Purchase Order Request',
  typeNamePlural: 'Purchase Order Requests',
  title: { type: #STANDARD, value: 'RequestNo' },
  description: { type: #STANDARD, value: 'Description' }
}
annotate entity ZC_TEC_POREQ with
{

  @UI.facet: [
    { id: 'General', purpose: #STANDARD, type: #IDENTIFICATION_REFERENCE, label: 'General', position: 10 },
    { id: 'Items', purpose: #STANDARD, type: #LINEITEM_REFERENCE, label: 'Items', position: 20, targetElement: '_Items' },
    { id: 'SAPIntegration', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE, label: 'SAP Integration', position: 30, targetQualifier: 'SAPInfo' }
  ]

  @UI: {
    selectionField: [{ position: 10 }],
    lineItem: [{ position: 10 }],
    identification: [{ position: 10 }]
  }
  RequestNo;

  @UI: {
    lineItem: [{ position: 20 }],
    identification: [{ position: 20 }]
  }
  Description;

  @UI: {
    selectionField: [{ position: 20 }],
    lineItem: [{ position: 30 }],
    identification: [{ position: 30 }]
  }
  Supplier;

  @UI.lineItem: [{ position: 35 }]
  @UI.identification: [{ position: 35 }]
  SupplierName;

  @UI: {
    lineItem: [{ position: 40, criticality: 'StatusCriticality' }],
    selectionField: [{ position: 30 }],
    identification: [{ position: 40, criticality: 'StatusCriticality' }]
  }
  Status;

  @UI.lineItem: [{ position: 50 }]
  @UI.identification: [{ position: 50 }]
  TotalAmount;

  @UI.identification: [{ position: 55 }]
  Currency;

  @UI.identification: [{ position: 60 }]
  OrderDate;

  @UI.identification: [{ position: 70 }]
  DeliveryDate;

  @UI.identification: [{ position: 80 }]
  CompanyCode;

  @UI.identification: [{ position: 85 }]
  PurchasingOrg;

  @UI.identification: [{ position: 86 }]
  PurchasingGroup;

  @UI.identification: [{ position: 90 }]
  Notes;

  @UI.lineItem: [{ position: 60 }]
  @UI.fieldGroup: [{ qualifier: 'SAPInfo', position: 10 }]
  SAPPONumber;

  @UI.fieldGroup: [{ qualifier: 'SAPInfo', position: 20, criticality: 'StatusCriticality' }]
  SAPPostMessage;

  @UI.hidden: true
  RequestUUID;

  @UI.hidden: true
  StatusCriticality;

}
```

### 4b. Items Annotations — `ZC_TEC_POREQI`

```abap
@Metadata.layer: #CUSTOMER
@UI.headerInfo: {
  typeName: 'Item',
  typeNamePlural: 'Items',
  title: { type: #STANDARD, value: 'ItemNo' },
  description: { type: #STANDARD, value: 'Description' }
}
annotate entity ZC_TEC_POREQI with
{

  @UI.lineItem: [{ position: 10 }]
  ItemNo;

  @UI.lineItem: [{ position: 20 }]
  MaterialNo;

  @UI.lineItem: [{ position: 30 }]
  Description;

  @UI.lineItem: [{ position: 40 }]
  Quantity;

  @UI.lineItem: [{ position: 45 }]
  UoM;

  @UI.lineItem: [{ position: 50 }]
  UnitPrice;

  @UI.lineItem: [{ position: 60 }]
  NetAmount;

  @UI.lineItem: [{ position: 65 }]
  Currency;

  @UI.lineItem: [{ position: 70 }]
  Plant;

  @UI.lineItem: [{ position: 80 }]
  MaterialGroup;

  @UI.hidden: true
  ItemUUID;

  @UI.hidden: true
  RequestUUID;

}
```

Activate both

### Perbandingan Annotations: CAP vs RAP

```
CAP annotations.cds:                     RAP Metadata Extension:
═══════════════════                      ═══════════════════════

annotate service.PORequests with @(      @Metadata.layer: #CUSTOMER
  UI.LineItem: [                         annotate entity ZC_TEC_POREQ with {
    { Value: requestNo,                    @UI.lineItem: [{ position: 10 }]
      Label: 'Request No' },               RequestNo;
    { Value: description,                  @UI.lineItem: [{ position: 20 }]
      Label: 'Description' },              Description;
  ]                                      }
);

// CAP: annotations di file .cds terpisah
// RAP: annotations di Metadata Extension CDS
// Hasilnya SAMA: Fiori Elements UI identik
```

---

## Langkah 5: Behavior Definition

Klik kanan `ZR_TEC_POREQ` (Interface View) → **New Behavior Definition**  
Implementation Type: **Managed**

> **⚠️ Aktivasi BDEF dilakukan 2 FASE untuk menghindari error cascading.**
> Fase 1 → basic managed (tanpa draft) → Fase 2 → tambah draft + additional save.

---

### FASE 1: Basic Managed (tanpa draft)

#### 5a-1. Paste kode FASE 1 ini:

```abap
managed implementation in class ZBP_TEC_POREQ unique;

define behavior for ZR_TEC_POREQ alias PORequest
persistent table ztec_poreq
lock master
authorization master ( global )
etag master LocalLastChanged

{
  create;
  update;
  delete;

  action postToSAP result [1] $self;

  determination setRequestNo on modify { create; }

  validation validateSupplier on save { create; update; field Supplier; }
  validation validateDeliveryDate on save { create; update; field DeliveryDate; }

  field ( numbering : managed ) RequestUUID;
  field ( readonly ) RequestNo, TotalAmount, StatusCriticality,
                     SAPPONumber, SAPPostMessage, CreatedBy, CreatedAt,
                     LastChangedBy, LastChangedAt, LocalLastChanged;
  field ( readonly : update ) Status;

  mapping for ztec_poreq
  {
    RequestUUID    = request_uuid;
    RequestNo      = request_no;
    Description    = description;
    CompanyCode    = company_code;
    PurchasingOrg  = purchasing_org;
    PurchasingGroup = purchasing_group;
    Supplier       = supplier;
    SupplierName   = supplier_name;
    OrderDate      = order_date;
    DeliveryDate   = delivery_date;
    TotalAmount    = total_amount;
    Currency       = currency;
    Notes          = notes;
    Status         = status;
    SAPPONumber    = sap_po_number;
    SAPPostMessage = sap_post_message;
    CreatedBy      = created_by;
    CreatedAt      = created_at;
    LastChangedBy  = last_changed_by;
    LastChangedAt  = last_changed_at;
    LocalLastChanged = local_last_changed;
  }

  association _Items { create; }
}

define behavior for ZR_TEC_POREQI alias PORequestItem
persistent table ztec_poreqi
lock dependent by _PORequest
authorization dependent by _PORequest
etag master LocalLastChanged

{
  update;
  delete;

  determination calcNetAmount on modify { create; update; field Quantity, UnitPrice; }
  determination calcHeaderTotal on modify { create; update; delete; }

  field ( numbering : managed ) ItemUUID;
  field ( readonly ) RequestUUID, RequestNo,
                     CreatedBy, CreatedAt, LastChangedBy, LastChangedAt, LocalLastChanged;

  mapping for ztec_poreqi
  {
    ItemUUID       = item_uuid;
    RequestUUID    = request_uuid;
    RequestNo      = request_no;
    ItemNo         = item_no;
    MaterialNo     = material_no;
    Description    = description;
    Quantity       = quantity;
    UoM            = uom;
    UnitPrice      = unit_price;
    NetAmount      = net_amount;
    Currency       = currency;
    Plant          = plant;
    MaterialGroup  = material_group;
    CreatedBy      = created_by;
    CreatedAt      = created_at;
    LastChangedBy  = last_changed_by;
    LastChangedAt  = last_changed_at;
    LocalLastChanged = local_last_changed;
  }

  association _PORequest;
}
```

#### 5a-2. Buat Class + Activate FASE 1

1. **Save** BDEF (Cmd+S) — mungkin ada warning, abaikan
2. Letakkan cursor di `ZBP_TEC_POREQ` (baris 1) → **Cmd+1** (Quick Fix) → **Create behavior implementation class**
3. Buka class → tab **Local Types** → Paste kode dari **Langkah 6** di bawah → **Save** (Cmd+S)
4. Select **BDEF + Class** bersamaan (tahan Cmd) → **Activate** (Fn+F3)

> **⚠️ PENTING: JANGAN buat class via "New → ABAP Class"!**
>
> Class **HARUS** dibuat via **Quick Fix dari BDEF** (Cmd+1) agar otomatis punya:
> ```abap
> CLASS zbp_tec_poreq DEFINITION PUBLIC ABSTRACT FINAL
>   FOR BEHAVIOR OF zr_tec_poreq.
> ```
> Jika class dibuat manual via "New → ABAP Class", dia jadi **regular class** tanpa
> `FOR BEHAVIOR OF` dan akan error:
> *"Local classes of CL_ABAP_BEHAVIOR_HANDLER can only be derived in the
> Local Definitions/Implementations of a global BEHAVIOR class."*
>
> **Fix jika sudah terlanjur:** Delete class → buat ulang via Quick Fix dari BDEF.

```
✅ Jika sukses → lanjut ke FASE 2
❌ Jika error "class does not exist" → class belum ter-save, save dulu
❌ Jika error lain → pastikan Tables (ZTEC_POREQ, ZTEC_POREQI) dan
   CDS Views (ZR_TEC_POREQ, ZR_TEC_POREQI) sudah aktif
```

---

### FASE 1.5: Buat Draft Tables Manual

> **Kenapa manual?** Draft tables TIDAK auto-generated di sistem ini. Harus dibuat manual sebelum FASE 2.
>
> **⚠️ Field names harus CamelCase** (sesuai CDS alias), bukan snake_case (DB column).
> Contoh: `requestuuid` bukan `request_uuid`, `companycode` bukan `company_code`.
> Draft table = mirror dari CDS view, bukan dari persistent table.

#### Draft Table Header — `ZTEC_D_POREQ`

Klik kanan `$TMP` → New → Database Table  
Name: `ZTEC_D_POREQ` | Description: `Draft: PO Request Header`

```abap
@EndUserText.label : 'Draft: PO Request Header'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztec_d_poreq {

  key client             : abap.clnt not null;
  key requestuuid        : sysuuid_x16 not null;
  requestno              : abap.char(20);
  description            : abap.char(200);
  companycode            : abap.char(4);
  purchasingorg          : abap.char(4);
  purchasinggroup        : abap.char(3);
  supplier               : abap.char(10);
  suppliername           : abap.char(80);
  orderdate              : abap.dats;
  deliverydate           : abap.dats;
  currency               : abap.cuky(5);
  @Semantics.amount.currencyCode : 'ztec_d_poreq.currency'
  totalamount            : abap.curr(15,2);
  notes                  : abap.char(256);
  status                 : abap.char(1);
  sapponumber            : abap.char(10);
  sappostmessage         : abap.char(200);
  statuscriticality      : abap.int1;
  createdby              : syuname;
  createdat              : timestampl;
  lastchangedby          : syuname;
  lastchangedat          : timestampl;
  locallastchanged       : timestampl;
  "%admin"               : include sych_bdl_draft_admin_inc;

}
```

Activate → lanjut items:

#### Draft Table Items — `ZTEC_D_POREQI`

Name: `ZTEC_D_POREQI` | Description: `Draft: PO Request Item`

```abap
@EndUserText.label : 'Draft: PO Request Item'
@AbapCatalog.enhancement.category : #NOT_EXTENSIBLE
@AbapCatalog.tableCategory : #TRANSPARENT
@AbapCatalog.deliveryClass : #A
@AbapCatalog.dataMaintenance : #RESTRICTED
define table ztec_d_poreqi {

  key client             : abap.clnt not null;
  key itemuuid           : sysuuid_x16 not null;
  requestuuid            : sysuuid_x16 not null;
  requestno              : abap.char(20);
  itemno                 : abap.char(5);
  materialno             : abap.char(40);
  description            : abap.char(200);
  @Semantics.quantity.unitOfMeasure : 'ztec_d_poreqi.uom'
  quantity               : abap.quan(10,2);
  uom                    : abap.unit(3);
  @Semantics.amount.currencyCode : 'ztec_d_poreqi.currency'
  unitprice              : abap.curr(15,2);
  @Semantics.amount.currencyCode : 'ztec_d_poreqi.currency'
  netamount              : abap.curr(15,2);
  currency               : abap.cuky(5);
  plant                  : abap.char(4);
  materialgroup          : abap.char(9);
  createdby              : syuname;
  createdat              : timestampl;
  lastchangedby          : syuname;
  lastchangedat          : timestampl;
  locallastchanged       : timestampl;
  "%admin"               : include sych_bdl_draft_admin_inc;

}
```

Activate → kedua draft tables harus aktif sebelum FASE 2.

#### Perbandingan: Persistent Table vs Draft Table

```
Persistent Table (ztec_poreq):       Draft Table (ztec_d_poreq):
══════════════════════════           ══════════════════════════
key request_uuid  (snake_case)       key requestuuid  (CamelCase lowercase)
company_code                         companycode
supplier_name                        suppliername
total_amount                         totalamount
                                     statuscriticality  ← calculated field juga masuk!
                                     "%admin" : include  ← wajib! draft admin fields
```

> **Aturan:** Draft table field names = **CDS alias lowercase** (tanpa underscore).
> Karena `mapping` di BDEF translate CDS alias ↔ DB column. Draft table pakai CDS alias.

---

### FASE 2: Tambah Draft + Additional Save + Strict

Setelah FASE 1 sukses, **ganti SELURUH kode BDEF** dengan versi lengkap ini:

#### 5b-1. Paste kode FASE 2 (replace seluruh isi BDEF):

```abap
managed with additional save
  implementation in class ZBP_TEC_POREQ unique;
strict ( 2 );
with draft;

define behavior for ZR_TEC_POREQ alias PORequest
persistent table ztec_poreq
draft table ztec_d_poreq
etag master LocalLastChanged
lock master total etag LastChangedAt
authorization master ( global )

{
  create;
  update;
  delete;

  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft action Resume;
  draft determine action Prepare {
    validation validateSupplier;
    validation validateDeliveryDate;
  }

  action postToSAP result [1] $self;

  determination setRequestNo on modify { create; }

  validation validateSupplier on save { create; update; field Supplier; }
  validation validateDeliveryDate on save { create; update; field DeliveryDate; }

  field ( numbering : managed ) RequestUUID;
  field ( readonly ) RequestNo, TotalAmount, StatusCriticality,
                     SAPPONumber, SAPPostMessage, CreatedBy, CreatedAt,
                     LastChangedBy, LastChangedAt, LocalLastChanged;
  field ( readonly : update ) Status;

  mapping for ztec_poreq
  {
    RequestUUID    = request_uuid;
    RequestNo      = request_no;
    Description    = description;
    CompanyCode    = company_code;
    PurchasingOrg  = purchasing_org;
    PurchasingGroup = purchasing_group;
    Supplier       = supplier;
    SupplierName   = supplier_name;
    OrderDate      = order_date;
    DeliveryDate   = delivery_date;
    TotalAmount    = total_amount;
    Currency       = currency;
    Notes          = notes;
    Status         = status;
    SAPPONumber    = sap_po_number;
    SAPPostMessage = sap_post_message;
    CreatedBy      = created_by;
    CreatedAt      = created_at;
    LastChangedBy  = last_changed_by;
    LastChangedAt  = last_changed_at;
    LocalLastChanged = local_last_changed;
  }

  association _Items { create; with draft; }
}

define behavior for ZR_TEC_POREQI alias PORequestItem
persistent table ztec_poreqi
draft table ztec_d_poreqi
etag master LocalLastChanged
lock dependent by _PORequest
authorization dependent by _PORequest

{
  update;
  delete;

  determination calcNetAmount on modify { create; update; field Quantity, UnitPrice; }
  determination calcHeaderTotal on modify { create; update; delete; }

  field ( numbering : managed ) ItemUUID;
  field ( readonly ) RequestUUID, RequestNo,
                     CreatedBy, CreatedAt, LastChangedBy, LastChangedAt, LocalLastChanged;

  mapping for ztec_poreqi
  {
    ItemUUID       = item_uuid;
    RequestUUID    = request_uuid;
    RequestNo      = request_no;
    ItemNo         = item_no;
    MaterialNo     = material_no;
    Description    = description;
    Quantity       = quantity;
    UoM            = uom;
    UnitPrice      = unit_price;
    NetAmount      = net_amount;
    Currency       = currency;
    Plant          = plant;
    MaterialGroup  = material_group;
    CreatedBy      = created_by;
    CreatedAt      = created_at;
    LastChangedBy  = last_changed_by;
    LastChangedAt  = last_changed_at;
    LocalLastChanged = local_last_changed;
  }

  association _PORequest { with draft; }
}
```

#### 5b-2. Activate FASE 2

1. **Cmd+A** (Select All) di editor BDEF → **Delete** → Paste kode FASE 2 di atas
2. **Save** (Cmd+S)
3. **Activate** BDEF (klik kanan → Activate)

```
✅ BDEF sekarang full-featured: draft + strict(2) + additional save
✅ Draft tables sudah ada (dibuat di FASE 1.5)
```

> **Jika error `strict ( 2 )`:** Ganti ke `strict ( 1 );` atau hapus baris `strict` sama sekali.
> `strict ( 2 )` butuh SAP_BASIS ≥ 757. Jika sistem lebih lama, pakai `strict ( 1 )` saja.
>
> **Jika error type mismatch `STATUSCRITICALITY`:** Pastikan di draft table `ztec_d_poreq` field
> `statuscriticality` bertipe `abap.int1` (bukan `abap.int4`). CASE expression di CDS return `int1`.

---

### Kenapa 2 Fase + Draft Table Manual?

```
Masalah 1: "Chicken and Egg"
═════════════════════════════
BDEF butuh draft table → tapi draft table di-generate saat BDEF aktif
Solusi: Activate TANPA draft dulu (FASE 1) → baru tambah draft (FASE 2)

Masalah 2: Draft tables tidak auto-generated
═════════════════════════════════════════════
Beberapa sistem SAP tidak auto-generate draft tables.
Solusi: Buat manual (FASE 1.5) sebelum FASE 2.

Masalah 3: Field name convention
════════════════════════════════
Persistent table: snake_case (request_uuid, company_code)
Draft table:      CDS alias lowercase (requestuuid, companycode)
Kenapa? Draft table = mirror CDS view, bukan mirror DB table.

Alur lengkap:
  FASE 1   → Basic managed (tanpa draft) → Activate ✅
  FASE 1.5 → Buat draft tables manual → Activate ✅
  FASE 2   → Full BDEF (draft + strict + additional save) → Activate ✅
```

> **Lihat [Glosarium D](#d-behavior-definition-keywords)** untuk penjelasan lengkap setiap keyword di Behavior Definition. Dan **[Glosarium E](#e-behavior-implementation--eml-entity-manipulation-language)** untuk EML statements di Langkah 6.

### Perbandingan CRUD: CAP vs RAP

```
CAP po-service.js:                       RAP Behavior Definition:
═════════════════                        ═════════════════════════

// CAP: BEFORE/AFTER hooks              // RAP: determination/validation
this.before('CREATE', 'PORequests',     determination setRequestNo
  async req => {                           on modify { create; }
    req.data.requestNo = ...
  })

// CAP: action                          // RAP: action
actions {                                action postToSAP result [1] $self;
  action postToSAP() returns {...}
}

// CAP: framework handles CRUD          // RAP: managed = framework handles CRUD
// + you add hooks                      // + you add determinations/validations

// Konsepnya SAMA — syntax berbeda
```

---

## Langkah 6: Behavior Implementation (ABAP Class)

Klik kanan Behavior Definition → **New Behavior Implementation**  
Name: `ZBP_TEC_POREQ`

### 6a. Local Types (lhc_PORequest)

Buka **Local Types** tab:

```abap
CLASS lhc_PORequest DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PUBLIC SECTION.
    " Buffer untuk saver class — UUID request yang perlu di-post ke SAP
    CLASS-DATA gt_post_keys TYPE TABLE OF sysuuid_x16.

  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR PORequest
        RESULT result,

      setRequestNo FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequest~setRequestNo,

      validateSupplier FOR VALIDATE ON SAVE
        IMPORTING keys FOR PORequest~validateSupplier,

      validateDeliveryDate FOR VALIDATE ON SAVE
        IMPORTING keys FOR PORequest~validateDeliveryDate,

      postToSAP FOR MODIFY
        IMPORTING keys FOR ACTION PORequest~postToSAP
        RESULT result.

ENDCLASS.

CLASS lhc_PORequest IMPLEMENTATION.

  METHOD get_global_authorizations.
    " No auth check for workshop — allow all operations
    result-%create = if_abap_behv=>auth-allowed.
    result-%update = if_abap_behv=>auth-allowed.
    result-%delete = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD setRequestNo.
    " Auto-generate Request Number (REQ-YYNNNN)
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( RequestNo )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    " Find max existing number
    SELECT MAX( request_no ) FROM ztec_poreq INTO @DATA(lv_max_no).

    DATA(lv_year) = sy-datum+2(2).
    DATA(lv_seq) = 1.

    IF lv_max_no IS NOT INITIAL.
      DATA(lv_last_seq) = CONV i( lv_max_no+5(4) ).
      lv_seq = lv_last_seq + 1.
    ENDIF.

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>)
      WHERE RequestNo IS INITIAL.
      DATA(lv_request_no) = |REQ-{ lv_year }{ lv_seq WIDTH = 4 ALIGN = RIGHT PAD = '0' }|.

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( RequestNo Status OrderDate CompanyCode PurchasingOrg PurchasingGroup Currency )
          WITH VALUE #( (
            %tky         = <req>-%tky
            RequestNo    = lv_request_no
            Status       = COND #( WHEN <req>-Status IS INITIAL THEN 'D' ELSE <req>-Status )
            OrderDate    = COND #( WHEN <req>-OrderDate IS INITIAL THEN sy-datum ELSE <req>-OrderDate )
            CompanyCode  = COND #( WHEN <req>-CompanyCode IS INITIAL THEN '1710' ELSE <req>-CompanyCode )
            PurchasingOrg  = COND #( WHEN <req>-PurchasingOrg IS INITIAL THEN '1710' ELSE <req>-PurchasingOrg )
            PurchasingGroup = COND #( WHEN <req>-PurchasingGroup IS INITIAL THEN '001' ELSE <req>-PurchasingGroup )
            Currency       = COND #( WHEN <req>-Currency IS INITIAL THEN 'USD' ELSE <req>-Currency )
          ) ).

      lv_seq = lv_seq + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateSupplier.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( Supplier )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      IF <req>-Supplier IS INITIAL.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Supplier wajib diisi' )
          %element-Supplier = if_abap_behv=>mk-on
        ) TO reported-porequest.

        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDeliveryDate.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        FIELDS ( OrderDate DeliveryDate )
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      IF <req>-DeliveryDate IS NOT INITIAL AND <req>-DeliveryDate <= <req>-OrderDate.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = 'Delivery Date harus setelah Order Date' )
          %element-DeliveryDate = if_abap_behv=>mk-on
        ) TO reported-porequest.

        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD postToSAP.
    " Read PO Request data
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequest
        ALL FIELDS
        WITH CORRESPONDING #( keys )
      RESULT DATA(requests).

    LOOP AT requests ASSIGNING FIELD-SYMBOL(<req>).
      " Check status
      IF <req>-Status = 'P'.
        APPEND VALUE #(
          %tky = <req>-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text     = |PO sudah di-post sebagai { <req>-SAPPONumber }| )
        ) TO reported-porequest.
        APPEND VALUE #( %tky = <req>-%tky ) TO failed-porequest.
        CONTINUE.
      ENDIF.

      " TODO: Call MM_PUR_PO_MAINT_V2_SRV or BAPI_PO_CREATE1
      " BAPI call dilakukan di saver class (additional save) → lihat lsc_ZR_TEC_POREQ
      " Action ini hanya buffer key + set status pending
      APPEND <req>-%tky-RequestUUID TO gt_post_keys.

      " Set status 'X' (pending post) — final status di-update oleh saver
      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( Status SAPPostMessage )
          WITH VALUE #( (
            %tky           = <req>-%tky
            Status         = 'X'
            SAPPostMessage = 'Posting ke SAP...'
          ) ).

      " Read back for result
      READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(updated).

      result = VALUE #( FOR upd IN updated (
        %tky   = upd-%tky
        %param = upd
      ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
```

### 6b. Local Types (lhc_PORequestItem)

Tambahkan di file yang sama:

```abap
CLASS lhc_PORequestItem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    METHODS:
      calcNetAmount FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequestItem~calcNetAmount,

      calcHeaderTotal FOR DETERMINE ON MODIFY
        IMPORTING keys FOR PORequestItem~calcHeaderTotal.

ENDCLASS.

CLASS lhc_PORequestItem IMPLEMENTATION.

  METHOD calcNetAmount.
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequestItem
        FIELDS ( Quantity UnitPrice )
        WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items ASSIGNING FIELD-SYMBOL(<item>).
      DATA(lv_net) = <item>-Quantity * <item>-UnitPrice.

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequestItem
          UPDATE FIELDS ( NetAmount )
          WITH VALUE #( (
            %tky      = <item>-%tky
            NetAmount = lv_net
          ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD calcHeaderTotal.
    " Get parent keys
    READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
      ENTITY PORequestItem
        BY \_PORequest
        FIELDS ( RequestUUID )
        WITH CORRESPONDING #( keys )
      RESULT DATA(parents).

    " For each parent, recalculate total
    LOOP AT parents ASSIGNING FIELD-SYMBOL(<parent>).
      READ ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest BY \_Items
          FIELDS ( NetAmount )
          WITH VALUE #( ( %tky = <parent>-%tky ) )
        RESULT DATA(all_items).

      DATA(lv_total) = REDUCE decfloat34(
        INIT sum = CONV decfloat34( 0 )
        FOR item IN all_items
        NEXT sum = sum + item-NetAmount ).

      MODIFY ENTITIES OF ZR_TEC_POREQ IN LOCAL MODE
        ENTITY PORequest
          UPDATE FIELDS ( TotalAmount )
          WITH VALUE #( (
            %tky        = <parent>-%tky
            TotalAmount = lv_total
          ) ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
```

### 6c. Local Types (lsc_ZR_TEC_POREQ — Saver Class)

> **Why additional save?** Di RAP strict mode 2, `COMMIT WORK` dilarang di handler methods.
> BAPI butuh `BAPI_TRANSACTION_COMMIT` (yang internally call `COMMIT WORK`).
> Solusi: panggil BAPI di **save phase** via saver class — satu-satunya tempat yang boleh `COMMIT WORK`.

Tambahkan di file **Local Types** yang sama:

```abap
CLASS lsc_ZR_TEC_POREQ DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_ZR_TEC_POREQ IMPLEMENTATION.

  METHOD save_modified.
    " ═══════════════════════════════════════════════════════════════
    " Additional Save: Process pending postToSAP requests
    " Dipanggil SETELAH managed framework save data ke DB.
    " Di sini boleh CALL FUNCTION + BAPI_TRANSACTION_COMMIT.
    " ═══════════════════════════════════════════════════════════════
    LOOP AT lhc_PORequest=>gt_post_keys INTO DATA(lv_uuid).

      " Read request header dari DB (sudah di-save oleh managed framework)
      SELECT SINGLE * FROM ztec_poreq
        WHERE request_uuid = @lv_uuid
        INTO @DATA(ls_req).
      IF sy-subrc <> 0. CONTINUE. ENDIF.

      " Read items
      SELECT * FROM ztec_poreqi
        WHERE request_uuid = @lv_uuid
        INTO TABLE @DATA(lt_items).

      " ──── Build BAPI Header ────
      DATA(ls_header) = VALUE bapimepoheader(
        comp_code  = ls_req-company_code
        doc_type   = 'NB'                    " Standard PO
        vendor     = ls_req-supplier
        purch_org  = ls_req-purchasing_org
        pur_group  = ls_req-purchasing_group
        currency   = ls_req-currency
        doc_date   = ls_req-order_date
      ).
      DATA(ls_headerx) = VALUE bapimepoheaderx(
        comp_code  = abap_true
        doc_type   = abap_true
        vendor     = abap_true
        purch_org  = abap_true
        pur_group  = abap_true
        currency   = abap_true
        doc_date   = abap_true
      ).

      " ──── Build BAPI Items ────
      DATA lt_po_items TYPE TABLE OF bapimepoitem.
      DATA lt_po_itemsx TYPE TABLE OF bapimepoitemx.
      DATA lv_item_no TYPE n LENGTH 5 VALUE '00000'.

      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<item>).
        lv_item_no += 10.
        APPEND VALUE bapimepoitem(
          po_item    = lv_item_no
          material   = <item>-material_no
          short_text = <item>-description
          quantity   = <item>-quantity
          po_unit    = <item>-uom
          net_price  = <item>-unit_price
          plant      = <item>-plant
          matl_group = <item>-material_group
        ) TO lt_po_items.
        APPEND VALUE bapimepoitemx(
          po_item    = lv_item_no
          po_itemx   = abap_true
          material   = abap_true
          short_text = abap_true
          quantity   = abap_true
          po_unit    = abap_true
          net_price  = abap_true
          plant      = abap_true
          matl_group = abap_true
        ) TO lt_po_itemsx.
      ENDLOOP.

      " ──── Call BAPI_PO_CREATE1 ────
      DATA lv_po_number TYPE bapimepoheader-po_number.
      DATA lt_return TYPE TABLE OF bapiret2.

      CALL FUNCTION 'BAPI_PO_CREATE1'
        EXPORTING
          poheader         = ls_header
          poheaderx        = ls_headerx
        IMPORTING
          exppurchaseorder = lv_po_number
        TABLES
          poitem           = lt_po_items
          poitemx          = lt_po_itemsx
          return           = lt_return.

      " ──── Check Result ────
      DATA lv_has_error TYPE abap_bool VALUE abap_false.
      DATA lv_messages TYPE string.
      LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<ret>) WHERE type = 'E' OR type = 'A'.
        lv_has_error = abap_true.
        lv_messages = |{ lv_messages } { <ret>-message }|.
      ENDLOOP.

      IF lv_has_error = abap_true.
        " ✘ BAPI gagal → status Error
        UPDATE ztec_poreq SET
          status           = 'E',
          sap_post_message = @lv_messages
          WHERE request_uuid = @lv_uuid.
      ELSE.
        " ✔ BAPI sukses → commit + status Posted
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING wait = abap_true.

        UPDATE ztec_poreq SET
          status           = 'P',
          sap_po_number    = @lv_po_number,
          sap_post_message = @( |PO { lv_po_number } berhasil dibuat via BAPI (Embedded Steampunk)| )
          WHERE request_uuid = @lv_uuid.
      ENDIF.

    ENDLOOP.

    " Clear buffer
    CLEAR lhc_PORequest=>gt_post_keys.
  ENDMETHOD.

ENDCLASS.
```

> **Perbandingan PO Posting: 3 Pendekatan**
>
> | | po-project (CAP) | po-project-in-apps (CAP+CBO) | po-project-steampunk (RAP) |
> |:---|:---|:---|:---|
> | **File** | `sap-client.js` | `sap-client.js` | `ZBP_TEC_POREQ` (saver) |
> | **Bahasa** | JavaScript | JavaScript | ABAP Cloud |
> | **API** | OData V2 (5-step draft) | OData V2 (5-step draft) | `BAPI_PO_CREATE1` (direct) |
> | **Commit** | HTTP stateless | HTTP stateless | `BAPI_TRANSACTION_COMMIT` |
> | **Dimana** | BTP → HTTP → SAP | BTP → HTTP → SAP | ABAP stack (lokal) |

Activate

---

## Langkah 7: Projection Behavior

Create behavior definition for projection `ZC_TEC_POREQ`:

```abap
projection;
strict ( 2 );
use draft;

define behavior for ZC_TEC_POREQ alias PORequest
{
  use create;
  use update;
  use delete;

  use action Edit;
  use action Activate;
  use action Discard;
  use action Resume;
  use action Prepare;

  use action postToSAP;

  use association _Items { create; with draft; }
}

define behavior for ZC_TEC_POREQI alias PORequestItem
{
  use update;
  use delete;

  use association _PORequest { with draft; }
}
```

Activate

---

## Langkah 8: Service Definition & Binding

### 8a. Service Definition

Klik kanan `$TMP` → **New → Business Services → Service Definition**

Name: `ZUI_TEC_POREQ_O4`  
Description: `TEC Rise - PO Request Service`

```abap
@EndUserText.label: 'TEC Rise - PO Request Service'
define service ZUI_TEC_POREQ_O4 {
  expose ZC_TEC_POREQ  as PORequest;
  expose ZC_TEC_POREQI as PORequestItem;
}
```

Activate

### 8b. Service Binding

Klik kanan `ZUI_TEC_POREQ_O4` → **New → Business Services → Service Binding**

Name: `ZUI_TEC_POREQ_BND`  
Description: `TEC Rise - PO Request Binding (OData V4 UI)`  
Binding Type: **OData V4 - UI**

Activate → Klik **Publish**

> **Penting:** Setelah Publish, tombol **Preview** akan muncul. Klik untuk membuka Fiori Elements preview di browser.

---

## Langkah 9: Test — Fiori Elements Preview

1. Di Service Binding `ZUI_TEC_POREQ_BND`, klik entity **PORequest**
2. Klik tombol **Preview**
3. Browser terbuka: Fiori Elements List Report + Object Page

### Test Flow:

```
1. Klik "Create" → Isi:
   - Description: "RAP Test - Office Supplies"
   - Supplier: 17300001
   - Supplier Name: Wahyu Amaldi
   - Delivery Date: 2026-04-30

2. Klik "Create" pada Items section → Isi:
   - Item No: 00010
   - Material No: TG11
   - Description: Green Tea Premium 500g
   - Quantity: 100
   - UoM: PC
   - Unit Price: 50.00
   - Currency: USD
   - Plant: 1710
   - Material Group: L001

3. Klik "Save" (Activate draft)
   → Request No auto-generated: REQ-260001
   → Net Amount auto-calculated: 5000.00
   → Total Amount auto-calculated: 5000.00
   → Status: D (Draft)

4. Klik tombol "postToSAP"
   → Status berubah: P (Posted)
   → SAP PO Number: 45000xxxx
```

---

## Langkah 10: Test via OData API (curl)

Setelah Service Binding di-publish, OData endpoint aktif di:

```
https://sap.ilmuprogram.com/sap/opu/odata4/sap/zui_tec_poreq_o4/srvd_a2x/sap/zui_tec_poreq_o4/0001/
```

```bash
# GET all PO Requests
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata4/sap/zui_tec_poreq_o4/srvd_a2x/sap/zui_tec_poreq_o4/0001/PORequest?\$format=json&sap-client=777"

# GET with $expand items
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata4/sap/zui_tec_poreq_o4/srvd_a2x/sap/zui_tec_poreq_o4/0001/PORequest?\$expand=_Items&\$format=json&sap-client=777"
```

> **OData V4!** RAP menghasilkan OData V4 (bukan V2 seperti CBO). Ini sama dengan CAP.

---

## ✅ Checkpoint

```
RAP PO Request (Embedded Steampunk):
═══════════════════════════════════════════

  ┌────────────────────────────────────────┐
  │  SAP S/4HANA (sap.ilmuprogram.com)     │
  │  ABAP Language: cloudDevelopment ✅     │
  │                                        │
  │  Tables:                               │
  │  ├── ZTEC_POREQ    (header)            │
  │  ├── ZTEC_POREQI   (items)             │
  │  ├── ZTEC_D_POREQ  (draft header)      │
  │  └── ZTEC_D_POREQI (draft items)       │
  │                                        │
  │  CDS Views:                            │
  │  ├── ZR_TEC_POREQ  (interface)         │
  │  ├── ZR_TEC_POREQI (interface items)   │
  │  ├── ZC_TEC_POREQ  (consumption)       │
  │  └── ZC_TEC_POREQI (consumption items) │
  │                                        │
  │  Behavior:                             │
  │  ├── Managed CRUD + Draft ✅           │
  │  ├── Composition (header→items) ✅     │
  │  ├── Auto RequestNo ✅                 │
  │  ├── Validations ✅                    │
  │  ├── Determinations (calc) ✅          │
  │  └── Action postToSAP ✅              │
  │                                        │
  │  Service: ZUI_TEC_POREQ_O4             │
  │  Binding: ZUI_TEC_POREQ_BND (V4 UI)   │
  │  Fiori Preview ✅                      │
  └────────────────────────────────────────┘

  12 ABAP objects created
  0 lines of Node.js
  0 BTP services needed
  Native draft + deep insert
```

---

## ABAP Object Summary

| # | Object | Type | Description |
|:--|:-------|:-----|:------------|
| 1 | `ZTEC_POREQ` | Database Table | PO Request Header |
| 2 | `ZTEC_POREQI` | Database Table | PO Request Item |
| 3 | `ZTEC_D_POREQ` | Draft Table | Auto-generated |
| 4 | `ZTEC_D_POREQI` | Draft Table | Auto-generated |
| 5 | `ZR_TEC_POREQ` | CDS Interface View | Root entity |
| 6 | `ZR_TEC_POREQI` | CDS Interface View | Child entity |
| 7 | `ZC_TEC_POREQ` | CDS Consumption View | Projection |
| 8 | `ZC_TEC_POREQI` | CDS Consumption View | Projection |
| 9 | `ZC_TEC_POREQ` | Metadata Extension | Fiori annotations |
| 10 | `ZC_TEC_POREQI` | Metadata Extension | Item annotations |
| 11 | `ZBP_TEC_POREQ` | ABAP Class | Behavior Implementation |
| 12 | `ZUI_TEC_POREQ_O4` | Service Definition | OData exposure |
| 13 | `ZUI_TEC_POREQ_BND` | Service Binding | OData V4 UI |

---

## Ringkasan: 3 Approaches Compared

```
Side-by-Side (CAP):             In-App (CBO):               Embedded Steampunk (RAP):
═══════════════════             ═════════════                ═════════════════════════

VS Code                         VS Code                      ADT (Eclipse)
db/po-schema.cds                db/po-schema.cds             ZTEC_POREQ (table)
                                (@cds.persistence.skip)      ZR_TEC_POREQ (CDS view)
                                                             ZC_TEC_POREQ (projection)
srv/po-service.cds              srv/po-service.cds           ZUI_TEC_POREQ_O4 (srvd)
srv/po-service.js               srv/po-service.js            ZBP_TEC_POREQ (class)
                                srv/lib/cbo-client.js
app/po/annotations.cds          app/po/annotations.cds       ZC_TEC_POREQ (metadata ext)
app/po/webapp/*                 app/po/webapp/*              (auto dari Service Binding)

npm install + cds watch          npm install + cds watch      Activate + Publish
HANA Cloud / SQLite             SAP CBO table                SAP HANA (embedded)
OData V4 (CAP)                  OData V4 → V2 proxy         OData V4 (RAP)
Draft: CAP managed              Draft: manual                Draft: RAP managed (native)
BTP: required                   BTP: required                BTP: NOT required ★

Total files: ~10                Total files: ~12             Total ABAP objects: ~13
Node.js skill                   Node.js skill                ABAP Cloud skill ★
```

---

## 🔗 Navigasi

| Hands-on | Topik |
|:---------|:------|
| ← [Hands-on 5](handson-5-cap-cbo-project.md) | CAP + CBO Backend |
| ← [Hands-on 1–3](handson-1-extend-cds-model.md) | CAP Side-by-Side (BTP) |
| ← [Hands-on 4](handson-4-cbo-in-app.md) | CBO Creation |
