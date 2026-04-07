# 📗 Hari 3: Clean Core Extensibility — End-to-End Purchase Order System

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 2 (Fiori app berjalan di atas CAP bookshop)  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 3, peserta mampu:
- Memahami paradigma **Clean Core** dan mengapa Z-table harus dihindari di S/4HANA Cloud
- Membangun **side-by-side extension** di BTP sebagai pengganti Z-table
- Mendesain data model **Purchase Order** lengkap (header, items, suppliers, materials)
- Mengekspose CDS model sebagai **OData V4 service**
- Menampilkan data PO di **Fiori Elements** (List Report + Object Page)
- Mengimplementasikan **Create & Post PO** dari Fiori UI dengan validasi bisnis
- Mengimplementasikan **status management** dan **approval workflow** sederhana

---

## 📅 Jadwal Hari 3

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 2 | 15 menit |
| 09:15 – 10:30 | **Teori: Clean Core & Side-by-Side Extensibility** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on 1: Data Model PO (Pengganti Z-table)** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on 2: OData Service & Business Logic** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on 3: Fiori UI — Display & Posting PO** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 🧠 Test Pengetahuan Hari 2 — Sebelum Lanjut ke Hari 3

> Jawab pertanyaan berikut secara lisan atau diskusi kelompok sebelum melanjutkan.

### Quick Check (5 menit)

| # | Pertanyaan | Jawaban yang Diharapkan |
|---|-----------|------------------------|
| 1 | Sebutkan 5 Fiori Design Principles | Role-based, Delightful, Coherent, Simple, Adaptive |
| 2 | Apa perbedaan Fiori Elements vs Freestyle SAPUI5? | Elements = declarative (annotations), Freestyle = imperative (XML+JS) |
| 3 | Annotation CDS apa yang mengontrol kolom di tabel List Report? | `@UI.LineItem` |
| 4 | Di file apa konfigurasi utama Fiori app berada? | `manifest.json` (app descriptor) |
| 5 | Apa 3 komponen MVC di SAPUI5? | Model (data), View (XML), Controller (JS) |
| 6 | OData query untuk filter buku harga > 20 dan urut descending? | `$filter=price gt 20&$orderby=price desc` |
| 7 | Bagaimana cara Fiori Elements men-generate UI tanpa coding? | Membaca CDS annotations → runtime auto-generate UI |
| 8 | Theme Fiori yang direkomendasikan saat ini? | `sap_horizon` |

---

## 📖 Materi Sesi 1: Clean Core Extensibility (Teori Lengkap)

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

> **🏠 Clean Core = Rumah dengan Aturan "Jangan Ubah Struktur Asli"**
>
> Bayangkan Anda menyewa apartemen premium (S/4HANA Cloud). Aturan pemilik:
> - ❌ **Dilarang** menambah kamar di dalam apartemen (Z-table di core)
> - ❌ **Dilarang** mengubah pipa air utama (modify standard code)
> - ✅ **Boleh** bangun gudang di halaman samping (side-by-side extension di BTP)
> - ✅ **Boleh** hubungkan gudang ke apartemen via lorong resmi (API/Events)
>
> | Istilah | Analogi | Penjelasan |
> |:--------|:--------|:-----------|
> | **Clean Core** | Aturan "jangan ubah apartemen" | Prinsip SAP: jangan modify S/4HANA core code |
> | **Z-table** | Kamar ilegal di dalam apartemen | Custom table di ABAP Dictionary — melanggar Clean Core |
> | **Side-by-side Extension** | Gudang di halaman samping | App custom di BTP yang terhubung ke S/4HANA via API |
> | **In-app Extension** | Rak tambahan yang diizinkan pemilik | Extension resmi via Key User Tools (custom fields, custom logic) |
> | **Custom Entity (CAP)** | Tabel di gudang samping | Pengganti Z-table — data disimpan di BTP (HANA/SQLite) |
> | **API Hub** | Lorong penghubung resmi | SAP API Business Hub — daftar API S/4HANA |
> | **Event Mesh** | Interkom antar ruangan | SAP Event Mesh — real-time events dari S/4HANA ke BTP |
> | **Destination** | Nomor telepon pemilik apartemen | Konfigurasi koneksi BTP → S/4HANA |
>
> **Alur End-to-End Hari Ini:**
> ```
> ┌─────────────────────────────────────┐
> │  STEP 1: Data Model (Z-table alt.) │
> │  CDS Entity: PurchaseOrders,       │
> │  PurchaseOrderItems, Suppliers,     │
> │  Materials                          │
> ├─────────────────────────────────────┤
> │  STEP 2: OData Service             │
> │  PurchaseOrderService expose        │
> │  entities + actions (postPO)        │
> ├─────────────────────────────────────┤
> │  STEP 3: Fiori UI                  │
> │  List Report: Daftar PO            │
> │  Object Page: Detail PO + Items    │
> │  Create Page: Buat & Posting PO    │
> └─────────────────────────────────────┘
> ```

---

### 📜 1. Apa itu Clean Core?

**Clean Core** adalah prinsip arsitektur SAP yang mewajibkan agar **core system S/4HANA tetap bersih** — tidak dimodifikasi dengan custom code langsung. Ini menjadi WAJIB di S/4HANA Cloud dan strongly recommended di S/4HANA on-premise.

```
Mengapa Clean Core?
═══════════════════════════════════════════════════════════

MASALAH LAMA (S/4HANA On-Premise + Z-code):
┌──────────────────────────────────────────────────┐
│                S/4HANA Core                       │
│  ┌──────┐  ┌──────┐  ┌──────────────────────┐   │
│  │ MM   │  │ SD   │  │ 500 Z-programs       │   │
│  │ std  │  │ std  │  │ 200 Z-tables         │   │
│  │      │  │      │  │ 150 Z-function modules│   │
│  └──────┘  └──────┘  │ 80 Z-enhancements    │   │
│                       │ 50 Z-BADIs           │   │
│                       └──────────────────────┘   │
│                                                   │
│  DAMPAK:                                          │
│  ❌ Upgrade S/4HANA → 6-12 bulan (test Z-code)   │
│  ❌ Bug sulit dilacak (standard vs custom?)       │
│  ❌ SAP Support tidak bisa membantu (modified)    │
│  ❌ Migrasi ke Cloud → mustahil tanpa rewrite     │
│  ❌ Developer baru harus pelajari Z-code legacy   │
└──────────────────────────────────────────────────┘

SOLUSI CLEAN CORE:
┌──────────────────────────────────────────────────┐
│           S/4HANA Core (BERSIH)                   │
│  ┌──────┐  ┌──────┐  ┌──────┐                   │
│  │ MM   │  │ SD   │  │ FI   │  ← Tidak diubah   │
│  │ std  │  │ std  │  │ std  │                    │
│  └──┬───┘  └──┬───┘  └──┬───┘                   │
│     │         │         │                        │
│     │    Released APIs  │                        │
│     └────────┬──────────┘                        │
└──────────────┼───────────────────────────────────┘
               │ OData / SOAP / RFC (resmi)
               ▼
┌──────────────────────────────────────────────────┐
│           SAP BTP (Extension Platform)            │
│  ┌──────────────────────────────────────────┐    │
│  │  Side-by-Side Extensions                  │    │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐    │    │
│  │  │ Custom  │ │ Custom  │ │ Custom  │    │    │
│  │  │ PO App  │ │ Report  │ │ Workflow│    │    │
│  │  │ (CAP)   │ │ (CAP)   │ │ (BPA)  │    │    │
│  │  └─────────┘ └─────────┘ └─────────┘    │    │
│  │  ┌─────────────────────────────────────┐ │    │
│  │  │ Custom Tables (HANA Cloud)          │ │    │
│  │  │  → Pengganti Z-tables!             │ │    │
│  │  └─────────────────────────────────────┘ │    │
│  └──────────────────────────────────────────┘    │
│                                                   │
│  DAMPAK:                                          │
│  ✅ Upgrade S/4HANA → hitungan hari               │
│  ✅ Core selalu supported oleh SAP                │
│  ✅ Extension bisa di-develop & deploy independen  │
│  ✅ Cloud-ready dari awal                          │
│  ✅ Bisa pakai teknologi modern (Node.js, React)   │
└──────────────────────────────────────────────────┘
```

---

### 🔄 2. Z-table vs Custom Entity di BTP: Perbandingan Detail

Di dunia ABAP klasik, kita terbiasa buat Z-table via `SE11`. Di Clean Core, pendekatan ini **tidak boleh** di S/4HANA Cloud. Alternatifnya ada beberapa:

```
Perbandingan Z-table vs CAP Entity:
═══════════════════════════════════════════════════════════

┌─────────────────────┬────────────────────┬─────────────────────────┐
│ Aspek               │ Z-table (ABAP)     │ CAP Entity (BTP)        │
├─────────────────────┼────────────────────┼─────────────────────────┤
│ Dibuat di           │ SE11 / ADT         │ CDS file (.cds)         │
│ Disimpan di         │ S/4HANA HANA DB    │ BTP HANA Cloud / SQLite │
│ Bahasa definisi     │ ABAP DDIC          │ CDS (Core Data Services)│
│ Menghasilkan        │ DB table + views   │ DB table + OData service│
│ API otomatis?       │ ❌ Harus buat RFC  │ ✅ OData V4 auto       │
│ UI otomatis?        │ ❌ Harus buat TCode│ ✅ Fiori Elements      │
│ Impact ke upgrade   │ ❌ Harus di-test   │ ✅ Independen          │
│ Deploy              │ Transport request  │ MTA / cf push          │
│ Scalability         │ Terikat sizing S/4 │ Auto-scale di BTP      │
│ Clean Core?         │ ❌ TIDAK compliant │ ✅ FULLY compliant     │
└─────────────────────┴────────────────────┴─────────────────────────┘
```

#### Kapan Pakai Pendekatan Mana?

```
Decision Tree: Di mana simpan custom data?
═══════════════════════════════════════════════════════════

Data Anda berhubungan dengan...
│
├─▶ S/4HANA standard entity (extend existing)?
│   │
│   ├─▶ Tambah field ke standard table?
│   │   └─▶ IN-APP EXTENSION (Key User Tools)
│   │       • Custom Fields & Logic app (S/4HANA)
│   │       • Contoh: tambah "Z_PLANT_GROUP" ke Material Master
│   │
│   └─▶ Business logic tambahan?
│       └─▶ IN-APP EXTENSION (Custom Logic / BAdI)
│           • Released BAdIs oleh SAP
│           • Contoh: validasi tambahan saat PO created
│
├─▶ Data baru yang TIDAK ADA di S/4HANA?
│   │
│   └─▶ SIDE-BY-SIDE EXTENSION (CAP di BTP) ← HARI INI!
│       • Custom entity di CAP = pengganti Z-table
│       • Custom OData service
│       • Custom Fiori UI
│       • Contoh: PO Tracking custom, Vendor Rating
│
└─▶ Orchestration / workflow?
    └─▶ SAP BUILD PROCESS AUTOMATION
        • Low-code workflow
        • Approval flows
```

---

### 🏗️ 3. Arsitektur End-to-End: Custom PO System

Arsitektur yang akan kita bangun hari ini:

```
End-to-End Architecture:
═══════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                     │
│                                                          │
│  ┌─────────────────────────┐  ┌────────────────────────┐│
│  │ Fiori List Report       │  │ Fiori Object Page      ││
│  │ "Purchase Orders"       │  │ "PO Detail"            ││
│  │                         │  │                         ││
│  │ ┌───────────────────┐   │  │ Header: PO#, Status    ││
│  │ │ Filter: Status,   │   │  │ Section 1: General     ││
│  │ │ Supplier, Date    │   │  │ Section 2: Items Table ││
│  │ │ ─────────────────│   │  │ Section 3: Notes       ││
│  │ │ PO-001 │ Open    │   │  │                         ││
│  │ │ PO-002 │ Posted  │   │  │ [Post PO] [Cancel PO]  ││
│  │ │ PO-003 │ Draft   │   │  │ [Add Item]             ││
│  │ └───────────────────┘   │  └────────────────────────┘│
│  │ [Create PO]             │                             │
│  └─────────────────────────┘                             │
│                         │                                │
│                    OData V4                               │
│                         │                                │
├─────────────────────────┼────────────────────────────────┤
│              SERVICE LAYER (CAP)                          │
│                         │                                │
│  ┌──────────────────────▼──────────────────────────────┐ │
│  │  PurchaseOrderService @(path: '/po')                │ │
│  │                                                      │ │
│  │  Entities:                                           │ │
│  │    PurchaseOrders, PurchaseOrderItems,               │ │
│  │    Suppliers, Materials                              │ │
│  │                                                      │ │
│  │  Actions:                                            │ │
│  │    postPO(poID)      → Status: Draft → Posted       │ │
│  │    cancelPO(poID)    → Status: → Cancelled          │ │
│  │    approvePO(poID)   → Status: Posted → Approved    │ │
│  │                                                      │ │
│  │  Handlers:                                           │ │
│  │    before CREATE → validate supplier, materials     │ │
│  │    before postPO → validate items exist, amounts    │ │
│  │    after  READ   → compute total amount             │ │
│  └──────────────────────┬──────────────────────────────┘ │
│                         │                                │
├─────────────────────────┼────────────────────────────────┤
│              DATA LAYER (Pengganti Z-table)               │
│                         │                                │
│  ┌──────────────────────▼──────────────────────────────┐ │
│  │  db/po-schema.cds                                   │ │
│  │                                                      │ │
│  │  ZPO_HEADER  → entity PurchaseOrders                │ │
│  │  ZPO_ITEM    → entity PurchaseOrderItems            │ │
│  │  ZSUPPLIER   → entity Suppliers                     │ │
│  │  ZMATERIAL   → entity Materials                     │ │
│  │                                                      │ │
│  │  Database: SQLite (dev) / HANA Cloud (prod)         │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

### 📋 4. Entity Mapping: Z-table Thinking → CAP Thinking

Jika Anda terbiasa dengan ABAP, berikut mapping mental dari Z-table ke CAP entity:

```
Z-table (ABAP SE11)              →    CAP Entity (.cds)
════════════════════                   ════════════════════

CREATE TABLE ZPO_HEADER (        →    entity PurchaseOrders : cuid, managed {
  MANDT      CHAR(3),                     poNumber    : String(10);
  PO_NUMBER  CHAR(10) KEY,                description : String(200);
  DESCRIPTION CHAR(200),                  supplier    : Association to Suppliers;
  SUPPLIER   CHAR(10),                    status      : POStatus;
  STATUS     CHAR(1),                     orderDate   : Date;
  ORDER_DATE DATS,                        totalAmount : Decimal(15,2);
  TOTAL_AMT  DEC(15,2),                   currency    : Currency;
  CURRENCY   CUKY(5),                     notes       : String(1000);
  NOTES      CHAR(1000),                  items       : Composition of many 
  ERNAM      CHAR(12),                                   PurchaseOrderItems
  ERDAT      DATS,                                       on items.parent = $self;
  AENAM      CHAR(12),                }
  AEDAT      DATS                    
);                                    // cuid → auto key UUID
                                      // managed → createdBy, createdAt,
                                      //           modifiedBy, modifiedAt

Perbedaan kunci:
┌──────────────────────────────────────────────────────────┐
│ ABAP Z-table                  │ CAP Entity              │
├───────────────────────────────┼──────────────────────────┤
│ MANDT (client) → manual       │ Multi-tenancy otomatis   │
│ ERNAM/ERDAT → manual          │ `managed` aspect = auto  │
│ KEY → manual CHAR(10)         │ `cuid` → UUID auto       │
│ Foreign key → manual          │ Association to → auto FK  │
│ No API → harus buat RFC/BAPI  │ OData V4 auto-generated  │
│ No UI → harus buat TCode/WebD │ Fiori Elements auto      │
│ Transport → request/task      │ MTA deploy               │
└───────────────────────────────┴──────────────────────────┘
```

---

### 📊 5. Status Management: PO Lifecycle

```
Purchase Order Lifecycle:
═══════════════════════════════════════════════════════════

  ┌──────┐     ┌──────┐     ┌────────┐     ┌─────────┐
  │ DRAFT│────▶│ OPEN │────▶│ POSTED │────▶│ APPROVED│
  │      │     │      │     │        │     │         │
  └──┬───┘     └──┬───┘     └───┬────┘     └─────────┘
     │            │              │
     │            │              │
     ▼            ▼              ▼
  ┌──────────┐                ┌──────────┐
  │CANCELLED │                │ REJECTED │
  └──────────┘                └──────────┘

  Transisi Status:
  ─────────────────────────────────────────
  DRAFT     → OPEN        : Save (auto saat create via UI)
  OPEN      → POSTED      : Action postPO() — validasi items
  POSTED    → APPROVED    : Action approvePO() — oleh manager
  POSTED    → REJECTED    : Action rejectPO() — oleh manager
  OPEN      → CANCELLED   : Action cancelPO()
  DRAFT     → CANCELLED   : Action cancelPO()

  Rules:
  • PO harus punya minimal 1 item untuk di-post
  • Total amount dihitung otomatis dari items
  • Setelah POSTED, items tidak boleh diubah
  • APPROVED/REJECTED/CANCELLED = final state
```

---

### 🔌 6. Koneksi ke S/4HANA (Teori — untuk Production)

Di workshop ini kita membangun data mandiri di BTP. Tapi di real production, PO system biasanya terhubung ke S/4HANA:

```
Production Architecture (FYI):
═══════════════════════════════════════════════════════════

  ┌──────────────────────┐        ┌──────────────────────┐
  │    SAP BTP            │        │    S/4HANA            │
  │                       │        │                       │
  │  Custom PO App (CAP)  │◄──────▶│  Purchasing (MM-PUR)  │
  │  ┌─────────────────┐  │  API   │  ┌─────────────────┐  │
  │  │ Custom PO tables│  │        │  │ EKKO (PO Header)│  │
  │  │ (tracking, notes│  │        │  │ EKPO (PO Items) │  │
  │  │  rating, custom │  │        │  │ LFA1 (Vendors)  │  │
  │  │  workflow)      │  │        │  │ MARA (Materials)│  │
  │  └─────────────────┘  │        │  └─────────────────┘  │
  │                       │        │                       │
  │  Destination Service ─┼────────┼─▶ Released OData APIs │
  │                       │        │   • A_PurchaseOrder    │
  │                       │        │   • A_Supplier         │
  │                       │        │   • A_Product          │
  └──────────────────────┘        └──────────────────────┘

  API Hub: https://api.sap.com/
  ├── API_PURCHASEORDER_PROCESS_SRV  → Create/Read PO
  ├── API_BUSINESS_PARTNER           → Supplier data
  └── API_PRODUCT_SRV               → Material/Product data

  Di workshop ini: kita build SEMUA di BTP (standalone)
  Di production: master data (Supplier, Material) bisa di-consume
  dari S/4HANA via Destination + Remote Service
```

---

### 🔍 7. Bukti Clean Core di Sistem Real: sap.ilmuprogram.com

> **💡 Sesi ini menunjukkan data REAL dari sistem SAP S/4HANA** untuk membuktikan bahwa
> konsep yang kita pelajari align dengan sistem production sesungguhnya.

#### 🌐 Sistem Yang Digunakan

| Parameter | Nilai |
|:----------|:------|
| **Hostname** | `sap.ilmuprogram.com` |
| **Client** | `777` |
| **Company Code** | `1710` — **Andi Coffee** |
| **Plant** | `1710` — **Coffee Plant – Jakarta** |
| **Purchasing Org** | `1710` — Purch. Org. 1710 |
| **Total OData Services** | **2.178 services** aktif |

#### 📊 Data Purchase Order Real (16 PO)

```
Data yang di-query dari: C_PURCHASEORDER_FS_SRV/C_PurchaseOrderFs
═══════════════════════════════════════════════════════════════════

          PO |         Type |                                 Supplier |   Amount |  Status              | Created By
──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
  4500000000 |  Standard PO |         Wahyu Amaldi (Domestic Supplier) | $3,020   |  Follow-On Documents |  BUDILUHUR
  4500000003 |  Standard PO |         Wahyu Amaldi (Domestic Supplier) |   $500   |  Follow-On Documents |    LINTANG
  4500000007 |  Standard PO |                   Domestic US Supplier 2 |   $900   |  Follow-On Documents |    LINTANG
  4500000010 |  Standard PO |         Wahyu Amaldi (Domestic Supplier) | $30,020  |  Follow-On Documents | BUDILUHUR2
  4500000011 |  Standard PO |                            (no supplier) |     $0   |  Draft               | BUDILUHUR2
  4500000014 |  Standard PO |         Wahyu Amaldi (Domestic Supplier) |  $3,020  |  Draft               | BUDILUHUR2
  4500000015 |  Standard PO |                Domestic US JV Partner 1  |  $3,020  |  Not Yet Sent        | WAHYU.AMALDI
```

#### 🏭 Detail PO 4500000015 (Dibuat oleh WAHYU.AMALDI)

```
PO Header:
  PurchaseOrder          : 4500000015
  PurchaseOrderType      : NB (Standard PO)
  CompanyCode            : 1710 (Andi Coffee)
  Supplier               : 17258002 — Domestic US JV Partner 1
  PaymentTerms           : 0001 — Pay Immediately w/o Deduction
  PurchaseOrderNetAmount : $3,020.00
  Status                 : Not Yet Sent (03)

PO Item 00010:
  PurchaseOrderItemText  : Pembelian
  MaterialGroup          : YBFA12 — Office Equipment
  OrderQuantity          : 10 PC
  NetPriceAmount         : $302.00
  NetAmount              : $3,020.00
  Plant                  : 1710 — Coffee Plant – Jakarta
  AccountAssignment      : Asset (A)

  ⚡ ZZ1 Custom Extension Fields (Clean Core In-App Extension):
  ZZ1_RefExtIDWahyu2_PDH     → Custom field (String)
  ZZ1_ref_external_h01_PDH   → Custom field (String)
  ZZ1_RefExtIDVidetra_PDH    → Custom field (Decimal) = 0.00
```

#### 🔑 Temuan Kunci: **Dua Tipe Clean Core Extension**

```
╔══════════════════════════════════════════════════════════════════════════╗
║  BUKTI CLEAN CORE BERJALAN DI SISTEM REAL                               ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  1️⃣  IN-APP EXTENSION (di dalam S/4HANA)                                ║
║     • ZZ1_ prefix fields di PO header                                    ║
║     • Dibuat via Key User Tools / Custom Fields & Logic app              ║
║     • Contoh: ZZ1_RefExtIDWahyu2_PDH, ZZ1_ref_external_h01_PDH         ║
║     • Data tersimpan di S/4HANA (extend standard table EKKO)            ║
║     • ✅ Clean Core compliant — menggunakan extension API resmi         ║
║                                                                          ║
║  2️⃣  SIDE-BY-SIDE EXTENSION (di BTP) ← YANG KITA BANGUN HARI INI      ║
║     • Custom entities di CAP (PurchaseOrders, Items, Suppliers, dll)    ║
║     • Data tersimpan di BTP (HANA Cloud / SQLite)                       ║
║     • Terhubung ke S/4HANA via Destination + OData API                  ║
║     • Contoh: PO Tracking, Vendor Rating, Custom Approval Workflow      ║
║     • ✅ Clean Core compliant — tidak menyentuh S/4HANA core            ║
║                                                                          ║
║  KEDUANYA SALING MELENGKAPI:                                             ║
║  ┌─────────────────────────┐    ┌──────────────────────────────────┐    ║
║  │ In-App Extension        │    │ Side-by-Side Extension (BTP)     │    ║
║  │ • Tambah field ke PO    │◄──►│ • Custom tables & logic          │    ║
║  │ • ZZ1_ custom fields    │API │ • Custom Fiori UI                │    ║
║  │ • Custom BAdI logic     │    │ • Custom workflow & reporting    │    ║
║  └─────────────────────────┘    └──────────────────────────────────┘    ║
╚══════════════════════════════════════════════════════════════════════════╝
```

#### 📋 Suppliers Real di Sistem SAP

| Supplier ID | Nama | Country | Account Group |
|:------------|:-----|:--------|:-------------|
| `17300001` | **Wahyu Amaldi (Domestic Supplier)** | 🇮🇩 ID | SUPL |
| `17300002` | Domestic US Supplier 2 | 🇺🇸 US | SUPL |
| `17258001` | JV Operator US | 🇺🇸 US | SUPL |
| `17258002` | Domestic US JV Partner 1 | 🇺🇸 US | SUPL |
| `17154801` | JIT Company | 🇺🇸 US | SUPL |
| `17300003` | Domestic US Supplier 3 (with ERS) | 🇺🇸 US | SUPL |
| `17300007` | Domestic US Subcontractor A | 🇺🇸 US | SUPL |

#### 📦 Materials Real (dari C_MM_MaterialValueHelp)

| Material ID | Deskripsi | Group | Type | UoM |
|:------------|:----------|:------|:-----|:----|
| `EWMS4-50` | FIN50, Fast Moving | L004 | FERT | - |
| `FG1_CP` | Shaft with Rolling Bearings | L004 | FERT | - |
| `AVC_RBT_ROBOT` | Robot Base Unit | L004 | KMAT | - |
| `CM-FL-V00` | Forklift | L004 | KMAT | - |
| `EWMS4-01` | Small Part, Slow-Moving Item | L001 | HAWA | - |
| `CSSRV_01` | Service | P001 | SERV | - |

#### 🔗 OData Services Aktif untuk Procurement

| Service | URL | Fungsi |
|:--------|:----|:-------|
| `C_PURCHASEORDER_FS_SRV` | `/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV` | PO Fiori (List/Detail) |
| `MD_SUPPLIER_MASTER_SRV` | `/sap/opu/odata/sap/MD_SUPPLIER_MASTER_SRV` | Supplier Master |
| `MMIM_MATERIAL_DATA_SRV` | `/sap/opu/odata/sap/MMIM_MATERIAL_DATA_SRV` | Material Data |
| `C_SUPPLIER_FS_SRV` | `/sap/opu/odata/sap/C_SUPPLIER_FS_SRV` | Supplier Analytics |
| `MM_PUR_PO_HISTORY_SRV` | (registered) | PO History |
| `MM_PUR_POITEMS_MONI_SRV` | (registered) | PO Items Monitor |

> **⚠️ Catatan:** Standard API Hub services (`API_PURCHASEORDER_PROCESS_SRV`, `API_BUSINESS_PARTNER`,
> `API_PRODUCT_SRV`) **belum diaktifkan** di sistem ini. Yang aktif adalah Fiori OData services
> dengan prefix `C_` (consumption) dan `MM_PUR_` (purchasing apps). Ini umum di sistem S/4HANA
> yang fokus pada Fiori apps daripada headless API integration.

#### 📐 Mapping Validasi: CAP Workshop vs Real S/4HANA

| Aspek | Workshop (CAP Entity) | Real System (S/4HANA OData) | Alignment |
|:------|:---------------------|:---------------------------|:----------|
| PO Header | `PurchaseOrders` | `C_PurchaseOrderFs` (EKKO) | ✅ Match |
| PO Item | `PurchaseOrderItems` | `to_PurchaseOrderItem` (EKPO) | ✅ Match |
| Supplier | `Suppliers` entity | `I_Supplier` / `C_MM_SupplierValueHelp` | ✅ Match |
| Material | `Materials` entity | `I_Material` / `C_MM_MaterialValueHelp` | ✅ Match |
| Status Flow | Draft→Open→Posted→Approved | Draft→Not Yet Sent→Follow-On Docs | ✅ Similar |
| Custom Fields | CAP entity = tabel baru | ZZ1_ prefix = In-App Extension | ✅ Complementary |
| PO Number | `PO-YYXXXX` auto | `4500000000` sequential (10 digit) | ✅ Pattern sama |
| Item Number | `10, 20, 30...` | `00010, 00020...` (5 digit) | ✅ Pattern sama |
| Extension Type | **Side-by-Side** (BTP) | **In-App** (ZZ1 fields) | ✅ Both Clean Core |

> **Kesimpulan:** Data model yang kita bangun di workshop **align dengan struktur Purchase Order
> di S/4HANA real**. Peserta yang mengerjakan workshop ini akan memiliki pemahaman yang langsung
> applicable ke project S/4HANA nyata.

---

## 🛠️ Hands-on 1: Data Model Purchase Order (Pengganti Z-table)

> **💡 Inti Hands-on 1:** Kita membangun 4 entity yang menjadi **pengganti Z-table**:
> - `PurchaseOrders` → pengganti ZPO_HEADER
> - `PurchaseOrderItems` → pengganti ZPO_ITEM
> - `Suppliers` → pengganti ZSUPPLIER (atau consume dari S/4HANA di production)
> - `Materials` → pengganti ZMATERIAL (atau consume dari S/4HANA di production)

### Langkah 1: Buat CDS Schema

**File: `db/po-schema.cds`**

```cds
namespace com.tecrise.procurement;

using { Currency, managed, cuid } from '@sap/cds/common';

// ============================================
// CUSTOM TYPES (Pengganti ABAP Domain/Data Element)
// ============================================

// Status PO — mirip ABAP Domain dengan fixed values
type POStatus : String enum {
    Draft     = 'D';   // Baru dibuat, belum lengkap
    Open      = 'O';   // Tersubmit, menunggu posting
    Posted    = 'P';   // Sudah diposting
    Approved  = 'A';   // Disetujui manager
    Rejected  = 'R';   // Ditolak manager
    Cancelled = 'X';   // Dibatalkan
}

// Unit of Measure
type UoM : String(3) enum {
    PC  = 'PC';   // Piece
    KG  = 'KG';   // Kilogram
    L   = 'L';    // Liter
    M   = 'M';    // Meter
    BOX = 'BOX';  // Box
    SET = 'SET';  // Set
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
    poNumber     : String(10)    @title: 'PO Number'  @readonly;
    description  : String(200)   @title: 'Description';
    supplier     : Association to Suppliers @title: 'Supplier' @assert.target;
    status       : POStatus      @title: 'Status'  default 'D';
    orderDate    : Date          @title: 'Order Date';
    deliveryDate : Date          @title: 'Delivery Date';
    totalAmount  : Decimal(15,2) @title: 'Total Amount'  @readonly default 0;
    currency     : Currency;
    notes        : String(1000)  @title: 'Notes';
    items        : Composition of many PurchaseOrderItems on items.parent = $self;
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

### Langkah 2: Buat Sample Data (CSV Seed)

**File: `db/data/com.tecrise.procurement-Suppliers.csv`**

```csv
ID;supplierNo;name;address;city;country;phone;email;isActive
f47ac10b-58cc-4372-a567-0e02b2c3d479;SUP-001;PT Andi Coffee Supply;Jl. Industri No. 45;Cikarang;ID;+62-21-8900123;supply@andicoffee.co.id;true
550e8400-e29b-41d4-a716-446655440001;SUP-002;CV Mitra Logistik;Jl. Pelabuhan Raya 12;Surabaya;ID;+62-31-5551234;info@mitralogistik.id;true
550e8400-e29b-41d4-a716-446655440002;SUP-003;PT Wahyu Amaldi Trading;Jl. Raya Karawaci 88;Karawachi;ID;+62-21-3841234;wahyu@trading.co.id;true
550e8400-e29b-41d4-a716-446655440003;SUP-004;UD Sumber Makmur;Jl. Pasar Baru 88;Semarang;ID;+62-24-3551122;sumber@makmur.co.id;true
550e8400-e29b-41d4-a716-446655440004;SUP-005;PT Global Parts Indonesia;Jl. Gatot Subroto Kav. 21;Jakarta;ID;+62-21-5201888;order@globalparts.co.id;true
```

> **Referensi S/4HANA Real:** SUP-001 ↔ Company 1710 (Andi Coffee), SUP-003 ↔ Supplier 17300001 (Wahyu Amaldi, Karawachi, ID)

**File: `db/data/com.tecrise.procurement-Materials.csv`**

```csv
ID;materialNo;description;category;uom;unitPrice;currency_code;isActive
a1b2c3d4-e5f6-7890-abcd-ef1234567001;MAT-10001;Laptop Business 14 inch;Office Equipment;PC;4850000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567002;MAT-10002;Hydraulic Oil ISO 46 (20L);Lubricants;L;450000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567003;MAT-10003;Coffee Bean Arabica Toraja (1Kg);Raw Materials;KG;285000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567004;MAT-10004;Safety Helmet (Yellow);Safety;PC;75000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567005;MAT-10005;Coffee Roasting Machine Part;Spare Parts;PC;1950000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567006;MAT-10006;Pipa Besi 2" Sch 40 (6M);Raw Materials;M;320000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567007;MAT-10007;Kabel NYY 4x10mm² (per M);Electrical;M;185000.00;IDR;true
a1b2c3d4-e5f6-7890-abcd-ef1234567008;MAT-10008;Glove Latex Industrial;Safety;BOX;45000.00;IDR;true
```

> **Referensi S/4HANA Real:** MAT-10001 (Laptop) ↔ PO Item "Laptop" di PO 4500000000 ($302/PC),
> MAT Group YBFA12 = Office Equipment. Company Andi Coffee → coffee materials ditambahkan.

**File: `db/data/com.tecrise.procurement-PurchaseOrders.csv`**

```csv
ID;poNumber;description;supplier_ID;status;orderDate;deliveryDate;totalAmount;currency_code;notes
b1c2d3e4-f5a6-7890-bcde-f12345670001;PO-240001;Pengadaan Laptop Kantor Jakarta;f47ac10b-58cc-4372-a567-0e02b2c3d479;P;2024-01-15;2024-02-15;48500000.00;IDR;Untuk tim operasional Coffee Plant Jakarta
b1c2d3e4-f5a6-7890-bcde-f12345670002;PO-240002;Pembelian Safety Equipment;550e8400-e29b-41d4-a716-446655440003;A;2024-02-01;2024-02-28;570000.00;IDR;Untuk tim lapangan roasting plant
b1c2d3e4-f5a6-7890-bcde-f12345670003;PO-240003;Restock Coffee Bean Toraja;550e8400-e29b-41d4-a716-446655440001;O;2024-03-10;2024-04-10;2850000.00;IDR;Bahan baku Q2
b1c2d3e4-f5a6-7890-bcde-f12345670004;PO-240004;Pengadaan Electrical Cable;550e8400-e29b-41d4-a716-446655440004;D;2024-03-20;2024-04-20;0.00;IDR;Draft - belum lengkap
```

> **Referensi S/4HANA Real:** PO-240001 mirip PO 4500000000 (Laptop, $3,020, Follow-On Documents).
> Status mapping: Posted (P) = Follow-On Documents (05), Draft (D) = Draft status di real system.

**File: `db/data/com.tecrise.procurement-PurchaseOrderItems.csv`**

```csv
ID;parent_ID;itemNo;material_ID;description;quantity;uom;unitPrice;netAmount;currency_code
c1d2e3f4-a5b6-7890-cdef-012345670001;b1c2d3e4-f5a6-7890-bcde-f12345670001;10;a1b2c3d4-e5f6-7890-abcd-ef1234567001;Laptop Business 14 inch;10;PC;4850000.00;48500000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670005;b1c2d3e4-f5a6-7890-bcde-f12345670002;10;a1b2c3d4-e5f6-7890-abcd-ef1234567004;Safety Helmet (Yellow);4;PC;75000.00;300000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670006;b1c2d3e4-f5a6-7890-bcde-f12345670002;20;a1b2c3d4-e5f6-7890-abcd-ef1234567008;Glove Latex Industrial;6;BOX;45000.00;270000.00;IDR
c1d2e3f4-a5b6-7890-cdef-012345670007;b1c2d3e4-f5a6-7890-bcde-f12345670003;10;a1b2c3d4-e5f6-7890-abcd-ef1234567003;Coffee Bean Arabica Toraja (1Kg);10;KG;285000.00;2850000.00;IDR
```

> **Referensi S/4HANA Real:** Item 00010 di PO 4500000000 = "Laptop", Qty 10 PC, Net $3,020.
> Pattern item numbering 10, 20, 30... sama dengan S/4HANA real (00010, 00020...).

### Langkah 3: Verifikasi Model

```bash
cd ~/projects/bookshop
cds watch
```

**✅ Hasil yang Diharapkan:**

Buka `http://localhost:4004` — entity baru muncul di welcome page:
- `PurchaseOrders` (4 records)
- `PurchaseOrderItems` (4 records)
- `Suppliers` (5 records)
- `Materials` (8 records)

Verifikasi data:
```bash
# Cek PO dengan items (deep read)
curl http://localhost:4004/odata/v4/po/PurchaseOrders?\$expand=items,supplier

# Cek materials
curl http://localhost:4004/odata/v4/po/Materials

# Cek metadata
curl http://localhost:4004/odata/v4/po/\$metadata
```

> **Mapping Mental Z-table:**
> ```
> ABAP SE11: CREATE TABLE ZPO_HEADER...  →  CDS: entity PurchaseOrders : cuid, managed { ... }
> ABAP SE11: CREATE TABLE ZPO_ITEM...    →  CDS: entity PurchaseOrderItems : cuid { ... }
> ABAP SM30: Maintain Z_SUPPLIER...      →  Fiori auto-generated dari entity Suppliers
> ABAP SE16: Display ZMATERIAL data...   →  OData: GET /po/Materials
> ```

---

## 🛠️ Hands-on 2: OData Service & Business Logic

### Langkah 1: Definisi Service

**File: `srv/po-service.cds`**

```cds
using { com.tecrise.procurement as po } from '../db/po-schema';

// ============================================
// PURCHASE ORDER SERVICE (Main Service)
// ============================================
service PurchaseOrderService @(path: '/po') {

    // ----- Entities -----
    entity PurchaseOrders     as projection on po.PurchaseOrders;
    entity PurchaseOrderItems as projection on po.PurchaseOrderItems;

    @readonly
    entity Suppliers          as projection on po.Suppliers;

    @readonly
    entity Materials          as projection on po.Materials;

    @readonly
    entity POStatusHistory    as projection on po.POStatusHistory;

    // ----- Actions: Status Transitions -----

    // Post PO: Draft/Open → Posted
    action postPO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    // Cancel PO: Draft/Open → Cancelled
    action cancelPO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    // Approve PO: Posted → Approved
    action approvePO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    // Reject PO: Posted → Rejected
    action rejectPO(poID: UUID, reason: String) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    // ----- Functions -----

    // Hitung total PO per supplier
    function getSupplierPOSummary(supplierID: UUID) returns {
        supplierName    : String;
        totalPOs        : Integer;
        totalAmount     : Decimal(15,2);
        openPOs         : Integer;
        postedPOs       : Integer;
    };
}
```

### Langkah 2: Implementasi Business Logic (Handlers)

**File: `srv/po-service.js`**

```javascript
const cds = require('@sap/cds');

module.exports = class PurchaseOrderService extends cds.ApplicationService {

    async init() {
        const db = await cds.connect.to('db');

        const PurchaseOrders     = 'com.tecrise.procurement.PurchaseOrders';
        const PurchaseOrderItems = 'com.tecrise.procurement.PurchaseOrderItems';
        const Suppliers          = 'com.tecrise.procurement.Suppliers';
        const Materials          = 'com.tecrise.procurement.Materials';
        const POStatusHistory    = 'com.tecrise.procurement.POStatusHistory';

        // ============================================
        // BEFORE CREATE: Auto-generate PO Number & Validate
        // ============================================
        this.before('CREATE', 'PurchaseOrders', async (req) => {
            const { supplier_ID, orderDate, deliveryDate } = req.data;

            // Auto-generate PO Number (PO-YYXXXX)
            const year = new Date().getFullYear().toString().slice(-2);
            const lastPO = await SELECT.one(PurchaseOrders)
                .columns('poNumber')
                .orderBy('createdAt desc');

            let sequence = 1;
            if (lastPO?.poNumber) {
                const lastSeq = parseInt(lastPO.poNumber.slice(-4), 10);
                if (!isNaN(lastSeq)) sequence = lastSeq + 1;
            }
            req.data.poNumber = `PO-${year}${String(sequence).padStart(4, '0')}`;

            // Default status = Open (skip Draft for simplicity in UI)
            if (!req.data.status) req.data.status = 'O';

            // Default orderDate = today
            if (!req.data.orderDate) {
                req.data.orderDate = new Date().toISOString().split('T')[0];
            }

            // Validate: supplier harus ada dan aktif
            if (supplier_ID) {
                const supplier = await SELECT.one(Suppliers).where({ ID: supplier_ID });
                if (!supplier) req.reject(400, 'Supplier tidak ditemukan');
                if (!supplier.isActive) req.reject(400, `Supplier "${supplier.name}" sudah tidak aktif`);
            }

            // Validate: delivery date harus > order date
            if (deliveryDate && orderDate && deliveryDate <= orderDate) {
                req.reject(400, 'Delivery Date harus setelah Order Date');
            }
        });

        // ============================================
        // BEFORE CREATE ITEM: Auto-fill dari material & calculate
        // ============================================
        this.before('CREATE', 'PurchaseOrderItems', async (req) => {
            const { material_ID, quantity, unitPrice } = req.data;

            // Auto-fill dari material master
            if (material_ID) {
                const material = await SELECT.one(Materials).where({ ID: material_ID });
                if (material) {
                    if (!req.data.description) req.data.description = material.description;
                    if (!req.data.uom) req.data.uom = material.uom;
                    if (!unitPrice) req.data.unitPrice = material.unitPrice;
                    if (!req.data.currency_code) req.data.currency_code = material.currency_code;
                }
            }

            // Auto-calculate net amount
            const qty = quantity || 0;
            const price = req.data.unitPrice || unitPrice || 0;
            req.data.netAmount = qty * price;

            // Auto-assign item number
            if (!req.data.itemNo && req.data.parent_ID) {
                const lastItem = await SELECT.one(PurchaseOrderItems)
                    .where({ parent_ID: req.data.parent_ID })
                    .columns('itemNo')
                    .orderBy('itemNo desc');
                req.data.itemNo = (lastItem?.itemNo || 0) + 10;
            }
        });

        // ============================================
        // AFTER CREATE/UPDATE/DELETE ITEM: Recalculate PO Total
        // ============================================
        const recalcPOTotal = async (poID) => {
            if (!poID) return;
            const items = await SELECT.from(PurchaseOrderItems)
                .where({ parent_ID: poID });
            const total = items.reduce((sum, item) => sum + (item.netAmount || 0), 0);
            await UPDATE(PurchaseOrders)
                .set({ totalAmount: total })
                .where({ ID: poID });
        };

        this.after('CREATE', 'PurchaseOrderItems', async (data) => {
            await recalcPOTotal(data.parent_ID);
        });

        this.after('UPDATE', 'PurchaseOrderItems', async (data) => {
            await recalcPOTotal(data.parent_ID);
        });

        this.after('DELETE', 'PurchaseOrderItems', async (_, req) => {
            // req.data contains the deleted item's parent_ID
            if (req.data?.parent_ID) {
                await recalcPOTotal(req.data.parent_ID);
            }
        });

        // ============================================
        // AFTER READ PO: Add virtual fields
        // ============================================
        this.after('READ', 'PurchaseOrders', (results) => {
            const pos = Array.isArray(results) ? results : [results];
            pos.forEach(po => {
                if (po.status) {
                    const statusMap = {
                        'D': 'Draft', 'O': 'Open', 'P': 'Posted',
                        'A': 'Approved', 'R': 'Rejected', 'X': 'Cancelled'
                    };
                    po.statusText = statusMap[po.status] || po.status;
                }
            });
        });

        // ============================================
        // BEFORE UPDATE PO: Cegah edit jika sudah Posted/Approved
        // ============================================
        this.before('UPDATE', 'PurchaseOrders', async (req) => {
            const po = await SELECT.one(PurchaseOrders).where({ ID: req.data.ID });
            if (po && ['P', 'A', 'R', 'X'].includes(po.status)) {
                req.reject(400, `PO ${po.poNumber} berstatus "${po.status}" — tidak dapat diubah`);
            }
        });

        // ============================================
        // ACTION: postPO — Open → Posted
        // ============================================
        this.on('postPO', async (req) => {
            const { poID } = req.data;
            if (!poID) req.reject(400, 'poID wajib diisi');

            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');

            // Validate status
            if (!['D', 'O'].includes(po.status)) {
                req.reject(400, `PO ${po.poNumber} tidak bisa di-post (status: ${po.status})`);
            }

            // Validate: harus punya items
            const items = await SELECT.from(PurchaseOrderItems).where({ parent_ID: poID });
            if (items.length === 0) {
                req.reject(400, `PO ${po.poNumber} tidak memiliki item — tambahkan minimal 1 item`);
            }

            // Validate: harus punya supplier
            if (!po.supplier_ID) {
                req.reject(400, `PO ${po.poNumber} belum memiliki Supplier`);
            }

            // Validate: total > 0
            if (!po.totalAmount || po.totalAmount <= 0) {
                req.reject(400, `PO ${po.poNumber} total amount harus > 0`);
            }

            // Update status
            await UPDATE(PurchaseOrders)
                .set({ status: 'P' })
                .where({ ID: poID });

            // Log status change
            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(),
                purchaseOrder_ID: poID,
                oldStatus: po.status,
                newStatus: 'P',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO posted successfully'
            });

            return {
                poNumber: po.poNumber,
                status: 'Posted',
                message: `PO ${po.poNumber} berhasil di-posting (${items.length} items, total: ${po.totalAmount})`
            };
        });

        // ============================================
        // ACTION: cancelPO — Draft/Open → Cancelled
        // ============================================
        this.on('cancelPO', async (req) => {
            const { poID } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');

            if (!['D', 'O'].includes(po.status)) {
                req.reject(400, `PO ${po.poNumber} tidak bisa di-cancel (status: ${po.status})`);
            }

            await UPDATE(PurchaseOrders)
                .set({ status: 'X' })
                .where({ ID: poID });

            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(),
                purchaseOrder_ID: poID,
                oldStatus: po.status,
                newStatus: 'X',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO cancelled'
            });

            return {
                poNumber: po.poNumber,
                status: 'Cancelled',
                message: `PO ${po.poNumber} berhasil dibatalkan`
            };
        });

        // ============================================
        // ACTION: approvePO — Posted → Approved
        // ============================================
        this.on('approvePO', async (req) => {
            const { poID } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');

            if (po.status !== 'P') {
                req.reject(400, `PO ${po.poNumber} harus berstatus "Posted" untuk di-approve (current: ${po.status})`);
            }

            await UPDATE(PurchaseOrders)
                .set({ status: 'A' })
                .where({ ID: poID });

            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(),
                purchaseOrder_ID: poID,
                oldStatus: 'P',
                newStatus: 'A',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO approved by manager'
            });

            return {
                poNumber: po.poNumber,
                status: 'Approved',
                message: `PO ${po.poNumber} disetujui`
            };
        });

        // ============================================
        // ACTION: rejectPO — Posted → Rejected
        // ============================================
        this.on('rejectPO', async (req) => {
            const { poID, reason } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');

            if (po.status !== 'P') {
                req.reject(400, `PO ${po.poNumber} harus berstatus "Posted" untuk di-reject`);
            }

            if (!reason?.trim()) {
                req.reject(400, 'Alasan penolakan wajib diisi');
            }

            await UPDATE(PurchaseOrders)
                .set({ status: 'R' })
                .where({ ID: poID });

            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(),
                purchaseOrder_ID: poID,
                oldStatus: 'P',
                newStatus: 'R',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: `Rejected: ${reason}`
            });

            return {
                poNumber: po.poNumber,
                status: 'Rejected',
                message: `PO ${po.poNumber} ditolak. Alasan: ${reason}`
            };
        });

        // ============================================
        // FUNCTION: getSupplierPOSummary
        // ============================================
        this.on('getSupplierPOSummary', async (req) => {
            const { supplierID } = req.data;

            const supplier = await SELECT.one(Suppliers).where({ ID: supplierID });
            if (!supplier) req.reject(404, 'Supplier tidak ditemukan');

            const pos = await SELECT.from(PurchaseOrders).where({ supplier_ID: supplierID });

            return {
                supplierName: supplier.name,
                totalPOs: pos.length,
                totalAmount: pos.reduce((sum, p) => sum + (p.totalAmount || 0), 0),
                openPOs: pos.filter(p => ['D', 'O'].includes(p.status)).length,
                postedPOs: pos.filter(p => ['P', 'A'].includes(p.status)).length
            };
        });

        return super.init();
    }
};
```

### Langkah 3: Jalankan & Test OData

```bash
cds watch
```

**✅ Verifikasi service berjalan:**
```
[cds] - serving PurchaseOrderService { at: ['/odata/v4/po'] }
```

#### Test CRUD via curl/REST Client

**File: `tests/po-tests.http`** (untuk REST Client Extension di VS Code)

```http
@host = http://localhost:4004/odata/v4/po

### ========================================
### READ: Get semua PO
### ========================================
GET {{host}}/PurchaseOrders?$expand=supplier,items($expand=material)&$orderby=poNumber
Accept: application/json

### ========================================
### READ: Get PO dengan filter status Open
### ========================================
GET {{host}}/PurchaseOrders?$filter=status eq 'O'&$select=poNumber,description,status,totalAmount
Accept: application/json

### ========================================
### READ: Get Materials (master data)
### ========================================
GET {{host}}/Materials?$orderby=materialNo
Accept: application/json

### ========================================
### READ: Get Suppliers
### ========================================
GET {{host}}/Suppliers?$filter=isActive eq true
Accept: application/json

### ========================================
### CREATE: Buat PO baru
### ========================================
POST {{host}}/PurchaseOrders
Content-Type: application/json

{
    "description": "Pengadaan Tools Maintenance Q2",
    "supplier_ID": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "orderDate": "2024-04-01",
    "deliveryDate": "2024-05-01",
    "currency_code": "IDR",
    "notes": "Untuk kebutuhan maintenance shutdown April"
}

### ========================================
### CREATE: Tambah Item ke PO (ganti <PO_ID> dengan ID dari response di atas)
### ========================================
POST {{host}}/PurchaseOrderItems
Content-Type: application/json

{
    "parent_ID": "<PO_ID>",
    "material_ID": "a1b2c3d4-e5f6-7890-abcd-ef1234567001",
    "quantity": 10,
    "currency_code": "IDR"
}

### ========================================
### ACTION: Post PO (ganti <PO_ID>)
### ========================================
POST {{host}}/postPO
Content-Type: application/json

{
    "poID": "<PO_ID>"
}

### ========================================
### ACTION: Approve PO (ganti <PO_ID>)
### ========================================
POST {{host}}/approvePO
Content-Type: application/json

{
    "poID": "<PO_ID>"
}

### ========================================
### ACTION: Cancel PO (untuk PO status Draft/Open)
### ========================================
POST {{host}}/cancelPO
Content-Type: application/json

{
    "poID": "b1c2d3e4-f5a6-7890-bcde-f12345670004"
}

### ========================================
### ACTION: Reject PO (ganti <PO_ID>)
### ========================================
POST {{host}}/rejectPO
Content-Type: application/json

{
    "poID": "<PO_ID>",
    "reason": "Budget belum disetujui Finance"
}

### ========================================
### FUNCTION: Summary PO per Supplier
### ========================================
GET {{host}}/getSupplierPOSummary(supplierID=f47ac10b-58cc-4372-a567-0e02b2c3d479)
Accept: application/json
```

#### Contoh Response

**POST `/po/postPO`:**
```json
{
    "poNumber": "PO-240005",
    "status": "Posted",
    "message": "PO PO-240005 berhasil di-posting (1 items, total: 1250000)"
}
```

**POST `/po/PurchaseOrders` (Create PO):**
```json
{
    "ID": "...",
    "poNumber": "PO-240005",
    "description": "Pengadaan Tools Maintenance Q2",
    "status": "O",
    "orderDate": "2024-04-01",
    "supplier_ID": "f47ac10b-...",
    "totalAmount": 0
}
```

---

## 🛠️ Hands-on 3: Fiori UI — Display & Posting PO

### Langkah 1: CDS Annotations untuk Fiori Elements

**File: `app/po/annotations.cds`**

```cds
using PurchaseOrderService as service from '../../srv/po-service';

// ============================================
// PURCHASE ORDERS — List Report
// ============================================
annotate service.PurchaseOrders with @(
    UI.LineItem: [
        {
            $Type: 'UI.DataField',
            Value: poNumber,
            Label: 'PO Number',
            ![@UI.Importance]: #High
        },
        {
            $Type: 'UI.DataField',
            Value: description,
            Label: 'Description',
            ![@UI.Importance]: #High
        },
        {
            $Type: 'UI.DataField',
            Value: supplier.name,
            Label: 'Supplier'
        },
        {
            $Type: 'UI.DataField',
            Value: status,
            Label: 'Status',
            Criticality: statusCriticality
        },
        {
            $Type: 'UI.DataField',
            Value: orderDate,
            Label: 'Order Date'
        },
        {
            $Type: 'UI.DataField',
            Value: totalAmount,
            Label: 'Total Amount'
        },
        {
            $Type: 'UI.DataField',
            Value: currency_code,
            Label: 'Currency'
        }
    ],

    UI.SelectionFields: [
        status,
        supplier_ID,
        orderDate
    ],

    UI.PresentationVariant: {
        SortOrder: [{
            Property: poNumber,
            Descending: true
        }]
    }
);

// ============================================
// PURCHASE ORDERS — Object Page Header
// ============================================
annotate service.PurchaseOrders with @(
    UI.HeaderInfo: {
        TypeName       : 'Purchase Order',
        TypeNamePlural : 'Purchase Orders',
        Title          : { $Type: 'UI.DataField', Value: poNumber },
        Description    : { $Type: 'UI.DataField', Value: description }
    },

    UI.HeaderFacets: [
        {
            $Type  : 'UI.ReferenceFacet',
            Target : '@UI.FieldGroup#Status',
            Label  : 'Status'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            Target : '@UI.DataPoint#TotalAmount',
            Label  : 'Total'
        }
    ],

    UI.DataPoint #TotalAmount: {
        Value : totalAmount,
        Title : 'Total Amount'
    },

    UI.FieldGroup #Status: {
        Data: [
            { Value: status,    Label: 'Status' },
            { Value: orderDate, Label: 'Order Date' }
        ]
    }
);

// ============================================
// PURCHASE ORDERS — Object Page Sections
// ============================================
annotate service.PurchaseOrders with @(
    UI.Facets: [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'GeneralInfo',
            Label  : 'General Information',
            Target : '@UI.FieldGroup#GeneralInfo'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'POItems',
            Label  : 'Items',
            Target : 'items/@UI.LineItem'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'Notes',
            Label  : 'Notes',
            Target : '@UI.FieldGroup#Notes'
        }
    ],

    UI.FieldGroup #GeneralInfo: {
        Label: 'General Information',
        Data : [
            { Value: poNumber,     Label: 'PO Number'     },
            { Value: description,  Label: 'Description'   },
            { Value: supplier_ID,  Label: 'Supplier'      },
            { Value: status,       Label: 'Status'        },
            { Value: orderDate,    Label: 'Order Date'    },
            { Value: deliveryDate, Label: 'Delivery Date' },
            { Value: totalAmount,  Label: 'Total Amount'  },
            { Value: currency_code,Label: 'Currency'      }
        ]
    },

    UI.FieldGroup #Notes: {
        Label: 'Notes',
        Data: [
            { Value: notes }
        ]
    }
);

// Status → Criticality mapping (computed di annotations)
annotate service.PurchaseOrders with {
    status @Common.ValueListWithFixedValues;
    // Criticality virtual field — handle di after READ handler
    statusCriticality @UI.Hidden;
};

// ============================================
// PURCHASE ORDER ITEMS — Table in Object Page
// ============================================
annotate service.PurchaseOrderItems with @(
    UI.LineItem: [
        { Value: itemNo,           Label: 'Item'        },
        { Value: material.description, Label: 'Material'    },
        { Value: description,      Label: 'Description' },
        { Value: quantity,         Label: 'Quantity'    },
        { Value: uom,             Label: 'UoM'         },
        { Value: unitPrice,       Label: 'Unit Price'  },
        { Value: netAmount,       Label: 'Net Amount'  },
        { Value: currency_code,   Label: 'Currency'    }
    ]
);

annotate service.PurchaseOrderItems with @(
    UI.HeaderInfo: {
        TypeName       : 'PO Item',
        TypeNamePlural : 'PO Items'
    },

    UI.Facets: [
        {
            $Type  : 'UI.ReferenceFacet',
            Label  : 'Item Details',
            Target : '@UI.FieldGroup#ItemDetails'
        }
    ],

    UI.FieldGroup #ItemDetails: {
        Data: [
            { Value: itemNo,      Label: 'Item Number'  },
            { Value: material_ID, Label: 'Material'     },
            { Value: description, Label: 'Description'  },
            { Value: quantity,    Label: 'Quantity'     },
            { Value: uom,        Label: 'UoM'          },
            { Value: unitPrice,  Label: 'Unit Price'   },
            { Value: netAmount,  Label: 'Net Amount'   }
        ]
    }
);

// ============================================
// VALUE HELPS (Dropdown)
// ============================================
annotate service.PurchaseOrders with {
    supplier @Common.ValueList: {
        CollectionPath: 'Suppliers',
        Parameters: [
            {
                $Type            : 'Common.ValueListParameterOut',
                LocalDataProperty: supplier_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'supplierNo'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'city'
            }
        ]
    };
};

annotate service.PurchaseOrderItems with {
    material @Common.ValueList: {
        CollectionPath: 'Materials',
        Parameters: [
            {
                $Type            : 'Common.ValueListParameterOut',
                LocalDataProperty: material_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'materialNo'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'description'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'unitPrice'
            }
        ]
    };
};

// ============================================
// FIELD LABELS & MEASURES
// ============================================
annotate service.PurchaseOrders with {
    totalAmount  @Measures.ISOCurrency: currency_code;
};

annotate service.PurchaseOrderItems with {
    unitPrice  @Measures.ISOCurrency: currency_code;
    netAmount  @Measures.ISOCurrency: currency_code;
};

// ============================================
// SUPPLIERS — Labels
// ============================================
annotate service.Suppliers with @(
    UI.LineItem: [
        { Value: supplierNo, Label: 'Supplier No' },
        { Value: name,       Label: 'Name'        },
        { Value: city,       Label: 'City'        },
        { Value: country,    Label: 'Country'     },
        { Value: isActive,   Label: 'Active'      }
    ]
);

// ============================================
// MATERIALS — Labels
// ============================================
annotate service.Materials with @(
    UI.LineItem: [
        { Value: materialNo,  Label: 'Material No' },
        { Value: description, Label: 'Description' },
        { Value: category,    Label: 'Category'    },
        { Value: uom,         Label: 'UoM'         },
        { Value: unitPrice,   Label: 'Unit Price'  }
    ]
);
```

### Langkah 2: Tambah Status Criticality di Handler

Tambahkan computed field `statusCriticality` di handler agar tabel berwarna berdasarkan status. Tambahkan ini di `srv/po-service.js` pada bagian `after READ`:

```javascript
// Di AFTER READ PO handler, tambahkan:
this.after('READ', 'PurchaseOrders', (results) => {
    const pos = Array.isArray(results) ? results : [results];
    pos.forEach(po => {
        if (po.status) {
            // Criticality untuk warna di Fiori
            const criticalityMap = {
                'D': 0,  // Neutral (abu-abu)  — Draft
                'O': 2,  // Critical (orange)  — Open, perlu diproses
                'P': 0,  // Neutral            — Posted, menunggu approval
                'A': 3,  // Positive (hijau)   — Approved
                'R': 1,  // Negative (merah)   — Rejected
                'X': 1   // Negative (merah)   — Cancelled
            };
            po.statusCriticality = criticalityMap[po.status] ?? 0;
        }
    });
});
```

> **💡 Catatan:** Field `statusCriticality` perlu ditambahkan sebagai virtual/computed element di CDS:
>
> Tambahkan di `db/po-schema.cds` pada entity PurchaseOrders:
> ```cds
> entity PurchaseOrders : cuid, managed {
>     // ... field lainnya ...
>     statusCriticality : Integer @title: 'Status Criticality' @UI.Hidden default 0;
> }
> ```

### Langkah 3: Generate Fiori App (via Yeoman atau manual)

```bash
# Option A: Via Yeoman Generator
cd ~/projects/bookshop
yo @sap/fiori:elements-app

# Pilihan:
# Template: List Report Page
# Service Source: Local CAP Node.js Project
# OData Service: PurchaseOrderService
# Main Entity: PurchaseOrders
# Navigation Entity: None
# Module Name: po-list
# Namespace: com.tecrise
```

**Atau buat manual — `app/po/webapp/manifest.json`:**

```json
{
    "_version": "1.49.0",
    "sap.app": {
        "id": "com.tecrise.po",
        "type": "application",
        "title": "Purchase Orders",
        "description": "Manage Purchase Orders",
        "applicationVersion": { "version": "1.0.0" },
        "dataSources": {
            "mainService": {
                "uri": "/po/",
                "type": "OData",
                "settings": {
                    "odataVersion": "4.0"
                }
            }
        }
    },
    "sap.ui5": {
        "routing": {
            "routes": [
                {
                    "name": "POList",
                    "pattern": "",
                    "target": "POList"
                },
                {
                    "name": "PODetail",
                    "pattern": "PurchaseOrders({key})",
                    "target": "PODetail"
                }
            ],
            "targets": {
                "POList": {
                    "type": "Component",
                    "id": "POList",
                    "name": "sap.fe.templates.ListReport",
                    "options": {
                        "settings": {
                            "entitySet": "PurchaseOrders",
                            "initialLoad": "Enabled",
                            "navigation": {
                                "PurchaseOrders": {
                                    "detail": { "route": "PODetail" }
                                }
                            }
                        }
                    }
                },
                "PODetail": {
                    "type": "Component",
                    "id": "PODetail",
                    "name": "sap.fe.templates.ObjectPage",
                    "options": {
                        "settings": {
                            "entitySet": "PurchaseOrders",
                            "editableHeaderContent": false
                        }
                    }
                }
            }
        },
        "models": {
            "": {
                "dataSource": "mainService",
                "settings": { "synchronizationMode": "None" }
            }
        }
    }
}
```

### Langkah 4: Jalankan & Test

```bash
cds watch
```

Buka browser `http://localhost:4004` → klik link **po-list** (atau `/po/webapp/index.html`)

**✅ Hasil yang Diharapkan:**

1. **List Report Page:**
   - Tabel PO dengan kolom: PO Number, Description, Supplier, Status (berwarna), Order Date, Total Amount
   - Filter bar: Status, Supplier, Order Date
   - Tombol **Create** di toolbar → buat PO baru
   - Klik baris → navigasi ke Object Page

2. **Object Page:**
   - Header: PO Number, Status, Total Amount
   - Section "General Information": semua field PO
   - Section "Items": tabel items dengan inline edit
   - Section "Notes": field notes
   - Tombol **Edit** untuk ubah data PO

3. **Create PO Flow:**
   ```
   [Create] → Form muncul
     → Isi: Description, pilih Supplier (value help), Order Date, Delivery Date
     → [Save] → PO tersimpan dengan poNumber auto-generated, status = "Open"
     → Navigasi ke Object Page
     → Tambah Items: pilih Material (value help), isi Quantity
     → Net Amount auto-calculated
     → Total Amount di header auto-updated
   ```

4. **Posting PO (via Action):**
   ```
   Di Object Page PO yang status "Open":
     → Panggil action postPO via curl/REST Client:
        POST /po/postPO { "poID": "<PO_ID>" }
     → Status berubah "Posted" (warna berubah)
     → Items locked (tidak bisa diubah)
   ```

---

## 📝 Latihan Mandiri Hari 3

### Exercise 3.1: Tambah Entity Goods Receipt

Buat entity `GoodsReceipts` yang merecord penerimaan barang dari PO:

```cds
entity GoodsReceipts : cuid, managed {
    grNumber      : String(10);
    purchaseOrder : Association to PurchaseOrders;
    receiveDate   : Date;
    receivedBy    : String(100);
    items         : Composition of many GoodsReceiptItems on items.parent = $self;
}
```

### Exercise 3.2: Validasi Bisnis Tambahan

Implementasikan handler:
- Delivery Date harus minimal 3 hari setelah Order Date
- Total PO tidak boleh melebihi 500.000.000 IDR (budget limit)
- Quantity per item tidak boleh melebihi 9.999

### Exercise 3.3: Dashboard Function

Buat function `getPODashboard()` yang mengembalikan:
- Total PO bulan ini
- Total amount bulan ini
- PO terbanyak per supplier
- Breakdown per status

### Exercise 3.4: Fiori Annotations — Analytical

Tambahkan `@UI.Chart` annotation untuk menampilkan chart PO per status di List Report.

---

## 🔑 Key Concepts Hari 3

| Konsep | Penjelasan | ABAP Equivalent |
|--------|------------|-----------------|
| **Clean Core** | Prinsip tidak modify S/4HANA code | Tanpa Z-code di core |
| **Side-by-Side Ext.** | Custom app di BTP terhubung ke S/4 via API | Bukan RICEFW tradisional |
| **CAP Entity** | CDS entity = pengganti Z-table | `SE11: CREATE TABLE Z...` |
| **`cuid`** | Auto UUID sebagai key | `GUID_CREATE` di ABAP |
| **`managed`** | Auto audit fields (createdBy, modifiedAt) | `SY-UNAME, SY-DATUM` manual |
| **Composition** | Parent-child, cascade delete | Header-Item table pair |
| **Association** | Foreign key reference | `CHECK TABLE` di SE11 |
| **`type ... enum`** | Fixed values | Domain fixed values SE11 |
| **`@assert.target`** | FK validation otomatis | `FOREIGN KEY` check |
| **Actions (POST)** | Custom operations yang ubah data | `BAPI_PO_CREATE1` |
| **Before handler** | Validasi sebelum save | `EXIT`, `BAdI`, `Enhancement` |
| **After handler** | Transform setelah read | `EXIT` di BAPI |
| **OData V4** | Auto-generated REST API | RFC/BAPI/ODATA V2 manual |
| **Fiori Elements** | Auto-generated UI dari annotations | `SE80` + WebDynpro |
| **`$expand`** | Eager load relasi | `FOR ALL ENTRIES` |
| **`$filter`** | WHERE conditions | `WHERE` clause |

---

## 📂 Hasil Hands-on

Semua hasil hands-on didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|----------|
| [Hands-on 1: Extend CDS Model](./handson/handson-1-extend-cds-model.md) | PO Data Model lengkap (entities, types, CSV data) |
| [Hands-on 2: Custom Handlers](./handson/handson-2-custom-handlers.md) | Business logic: validasi, auto-calculate, status management |
| [Hands-on 3: OData Testing](./handson/handson-3-odata-testing.md) | OData queries, CRUD, actions, beserta response aktual |

---

## 📚 Referensi

- [SAP Clean Core Strategy](https://www.sap.com/products/erp/s4hana/clean-core.html)
- [CAP Side-by-Side Extensibility](https://cap.cloud.sap/docs/guides/extensibility/)
- [CDS Language Reference](https://cap.cloud.sap/docs/cds/)
- [CAP Event Handlers](https://cap.cloud.sap/docs/node.js/core-services)
- [Fiori Elements Annotations](https://cap.cloud.sap/docs/advanced/fiori)
- [SAP API Business Hub](https://api.sap.com/)
- [OData V4 Protocol](https://docs.oasis-open.org/odata/odata/v4.01/odata-v4.01-part1-protocol.html)
- [S/4HANA Purchase Order API](https://api.sap.com/api/OP_API_PURCHASEORDER_PROCESS_SRV_0001/overview)

---

⬅️ **Prev:** [Hari 2 — SAP Fiori & UI5](../Day2-Fiori-UI5/README.md)  
➡️ **Next:** [Hari 4 — Integration & Deployment](../Day4-Integration-Deployment/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
