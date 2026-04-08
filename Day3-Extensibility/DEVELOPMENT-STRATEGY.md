# 🏗️ End-to-End Development Strategy: Side-by-Side Extension di SAP BTP

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Konteks:** Day 3 Workshop TEC Rise — Clean Core PO System  
> **Real System:** sap.ilmuprogram.com | Client 777 | Company 1710 (Andi Coffee)

---

## 📌 Executive Summary

Dokumen ini menjelaskan **strategi development end-to-end** untuk membangun **side-by-side extension** di SAP BTP yang menggantikan Z-table tradisional. Proyek ini proven — PO 4500000016, 4500000017, 4500000018 berhasil dibuat di SAP S/4HANA real melalui aplikasi yang dibangun 100% di BTP.

```
┌──────────────────────────────────────────────────────────────────────┐
│                    END-TO-END ARCHITECTURE                           │
│                                                                      │
│  ┌─────────┐    ┌──────────────┐    ┌───────────────┐    ┌───────┐ │
│  │  Fiori   │───▶│  CAP OData   │───▶│  SAP HANA     │    │ SAP   │ │
│  │  Elements│    │  V4 Service  │    │  Cloud DB      │    │ S/4   │ │
│  │  (UI)    │◀───│  (Node.js)   │◀───│  (Persistence) │    │ HANA  │ │
│  └─────────┘    └──────┬───────┘    └───────────────┘    └───┬───┘ │
│                         │                                     │     │
│                         └──── OData V2 + CSRF Token ─────────┘     │
│                              (Post to SAP Action)                   │
│                                                                      │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  SAP BTP Platform Services                                    │   │
│  │  • HANA Cloud (HDI Container)                                 │   │
│  │  • XSUAA (Authentication)                                     │   │
│  │  • Destination Service (SAP S/4 connection)                   │   │
│  │  • Cloud Foundry Runtime (Node.js)                            │   │
│  └──────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 🤔 PART 1: Mengapa SAP BTP? (Why BTP)

### 1.1 Masalah dengan Pendekatan Tradisional

Di ABAP klasik, custom requirement diselesaikan dengan:
```
SE11 → Buat Z-table → SE38 → Buat Z-report → SE80 → Buat Z-program → STMS → Transport
```

**Dampak yang terjadi di lapangan:**

| Masalah | Impact Nyata |
|---------|-------------|
| **Upgrade S/4HANA** | 6-12 bulan karena harus test semua Z-code (ratusan object) |
| **SAP Support** | SAP menolak support jika core sudah dimodifikasi |
| **Cloud Migration** | Mustahil pindah ke S/4HANA Cloud tanpa rewrite total |
| **Developer Onboarding** | Developer baru harus pelajari Z-code legacy yang undocumented |
| **Scalability** | Terikat sizing S/4HANA server (mahal untuk scale up) |
| **Modern Tech** | Tidak bisa pakai Node.js, React, CI/CD, Docker, dsb |

### 1.2 Mengapa BTP Menjadi Jawaban

SAP BTP (Business Technology Platform) adalah **platform extension** resmi dari SAP yang:

```
SEBELUM (Z-table di S/4HANA):
═══════════════════════════════════════════
S/4HANA Server
├── Standard Code (MM, SD, FI, CO...)
├── Z-tables (500+ custom tables)         ← MASALAH
├── Z-programs (300+ custom programs)     ← MASALAH
├── Z-enhancements (150+ BADIs)           ← MASALAH
└── Semua JADI SATU di 1 server

SESUDAH (Side-by-side di BTP):
═══════════════════════════════════════════
S/4HANA Server (BERSIH)
├── Standard Code ONLY                    ← CLEAN CORE ✅
└── Released APIs (OData, SOAP, RFC)      ← Pintu resmi

SAP BTP (TERPISAH)
├── Custom App 1 (PO Management)          ← CAP + HANA Cloud
├── Custom App 2 (Reports)                ← CAP + HANA Cloud
├── Custom Workflow                        ← SAP Build Process Auto
├── Custom Integration                     ← Integration Suite
└── Masing-masing INDEPENDEN              ← Scale, deploy, update sendiri
```

### 1.3 BTP Services yang Digunakan di Project Ini

| Service | Fungsi | Plan |
|---------|--------|------|
| **SAP HANA Cloud** | Database persistence (pengganti Z-table) | `hdi-shared` |
| **Cloud Foundry Runtime** | Hosting Node.js application (CAP) | `standard` |
| **XSUAA** | Authentication & authorization | `application` |
| **Destination Service** | Managed connection ke S/4HANA | `lite` |
| **HTML5 Application Repository** | Hosting Fiori static files | `app-host` |

---

## 🧩 PART 1B: SAP Extensibility Model — Taxonomy Lengkap

> **Referensi resmi:** SAP Clean Core Extensibility Guide (2024+)  
> **Konteks workshop:** po-project = Opsi 3a, po-project-in-apps = Opsi 1a

### 1B.1 Overview: 4 Kategori Extensibility

SAP mendefinisikan **4 kategori** extensibility berdasarkan **di mana** kode/konfigurasi dibuat dan **siapa** yang membuatnya:

```
SAP Extensibility Taxonomy (Official):
═══════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────┐
│                        SAP S/4HANA System                               │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  1. IN-APP EXTENSIBILITY (Key User)                               │  │
│  │     └── CBO, Custom Fields, Custom Logic, Custom Analytical Query │  │
│  │     └── Browser-based, no ABAP coding                             │  │
│  │     └── ★ po-project-in-apps menggunakan ini (CBO)                │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │  2. IN-APP EXTENSIBILITY (Developer / "Embedded Steampunk")       │  │
│  │     └── Custom CDS Views, BADI Implementations, RAP BO           │  │
│  │     └── ABAP Cloud (restricted syntax) via ADT (Eclipse)         │  │
│  │     └── Hanya di S/4HANA Cloud + On-Prem ≥ 2022                  │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
           │ Released APIs (OData, SOAP, Events, RFC)
           ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        SAP BTP (Cloud Platform)                         │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │  3. SIDE-BY-SIDE EXTENSIBILITY (CAP / Custom Dev)                 │  │
│  │     └── 3a. CAP Node.js + HANA Cloud / PostgreSQL                 │  │
│  │     └── 3b. CAP Java + HANA Cloud                                 │  │
│  │     └── 3c. Any framework (Spring Boot, Express, etc.)            │  │
│  │     └── ★ po-project menggunakan 3a (CAP Node.js + HANA)         │  │
│  ├───────────────────────────────────────────────────────────────────┤  │
│  │  4. SIDE-BY-SIDE EXTENSIBILITY (Steampunk / BTP ABAP Env)        │  │
│  │     └── ABAP Cloud di BTP (bukan di S/4HANA)                     │  │
│  │     └── RAP Business Objects, ABAP RESTful development            │  │
│  │     └── Untuk ABAP developers yang mau stay di ABAP ecosystem     │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1B.2 Detail per Kategori

---

#### Kategori 1: In-App Extensibility — Key User (Browser-Based)

**Persona:** Business analyst, power user, functional consultant  
**Tools:** SAP Fiori Launchpad (browser)  
**Coding:** Zero  
**Clean Core:** ✅ Full compliant

```
Fitur yang tersedia:
═══════════════════════════════════════════

┌──────────────────────────┬────────────────────────────────────────────────┐
│ Fitur                    │ Keterangan                                    │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Business Objects  │ Buat custom table + OData + basic UI          │
│ (CBO)                    │ ★ Digunakan di workshop: ZZ1_WPOREQ/WPOREQI  │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Fields            │ Tambah field ke entity SAP standard           │
│                          │ (misal: tambah field ke Purchase Order)       │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Logic             │ ABAP-like scripting (terbatas) di CBO:        │
│                          │ Determination (before save) & Validation      │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Analytical Query  │ Buat query untuk embedded analytics           │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Communication     │ Setup outbound scenario (API calls)           │
│ Arrangement              │                                               │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Catalog Extension │ Tambah tile/group di Fiori Launchpad          │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Key User Adaptation      │ UI modification tanpa coding                  │
│ (UI Flex)                │ (hide fields, change labels, rearrange)       │
└──────────────────────────┴────────────────────────────────────────────────┘

Batasan:
• CBO max ~200 fields per object
• Tidak bisa Composition (header-item = 2 CBO terpisah)
• CBO field types terbatas (Text, Number, Date, Checkbox, dll)
• Tidak bisa custom CDS view / association / value help complex
• Tidak bisa BADI implementation
• CBO OData: V2 only, no deep insert, no $expand
```

**Kapan pakai:**
- Butuh custom table kecil (< 30 fields) di SAP → **CBO**
- Tambah 1-5 custom field di standard BO (Purchase Order, Sales Order) → **Custom Fields**
- Business user ingin modify tanpa developer → **Key User Adaptation**

---

#### Kategori 2: In-App Extensibility — Developer ("Embedded Steampunk")

**Persona:** ABAP developer  
**Tools:** ABAP Development Tools (ADT) in Eclipse  
**Coding:** ABAP Cloud (restricted syntax)  
**Clean Core:** ✅ Full compliant (hanya Released API + objects)

```
Fitur yang tersedia:
═══════════════════════════════════════════

┌──────────────────────────┬────────────────────────────────────────────────┐
│ Fitur                    │ Keterangan                                    │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom CDS Views         │ Buat analytical/transactional CDS view        │
│                          │ Akses data SAP standard + CBO + custom table  │
├──────────────────────────┼────────────────────────────────────────────────┤
│ BADI Implementation      │ Implement enhancement spots yang di-released  │
│                          │ oleh SAP (bukan classic enhancement/SMOD)     │
├──────────────────────────┼────────────────────────────────────────────────┤
│ RAP Business Object      │ Buat custom BO dengan full CRUD + draft       │
│ (Unmanaged/Managed)      │ via ABAP RESTful Application Programming      │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom ABAP Classes      │ Business logic di ABAP Cloud syntax           │
│                          │ Hanya boleh pakai Released APIs               │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom OData Service     │ Expose CDS view / RAP BO sebagai OData V2/V4 │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Background Job           │ Schedule ABAP class sebagai job                │
├──────────────────────────┼────────────────────────────────────────────────┤
│ Custom Event              │ Raise / consume business events (async)       │
└──────────────────────────┴────────────────────────────────────────────────┘

Perbedaan Classic ABAP vs ABAP Cloud (Embedded Steampunk):
═══════════════════════════════════════════════════════════

Classic ABAP (BAD — modifikasi core):
  SELECT * FROM EKKO.           ← Akses langsung DB table
  CALL FUNCTION 'BAPI_PO_CREATE1'.  ← Unreleased function module
  MODIFY ekko FROM wa_ekko.    ← Direct table modification

ABAP Cloud (GOOD — clean core):
  SELECT * FROM I_PurchaseOrder. ← Released CDS View only
  cl_bapi_purchaseorder=>create( ). ← Released API wrapper
  " Direct table modification FORBIDDEN ← compiler error!
  " Hanya boleh pakai Released objects (whitelist)

Ketersediaan:
• S/4HANA Cloud (Public Edition) — ✅ native
• S/4HANA Cloud (Private Edition) — ✅ native
• S/4HANA On-Premise ≥ 2022 FPS02 — ✅ via Developer Extensibility license
• S/4HANA On-Premise < 2022 — ❌ tidak tersedia
```

**Kapan pakai:**
- Tim ABAP yang mau modernize tanpa belajar Node.js/Java
- Butuh BADI implementation di S/4HANA standard process
- Complex analytical CDS view dengan association chain
- Custom RAP BO dengan full draft support di S/4HANA

---

#### Kategori 3: Side-by-Side Extensibility — CAP / Custom Dev

**Persona:** Full-stack developer, Node.js/Java developer  
**Tools:** VS Code, BAS (SAP Business Application Studio)  
**Coding:** Node.js, Java, atau framework lain  
**Clean Core:** ✅ Full compliant (hanya consume Released APIs)

```
Opsi Framework di BTP:
═══════════════════════════════════════════

┌──────────────────────────┬──────────────────────────────────────────────────┐
│ Framework                │ Keterangan                                      │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ CAP Node.js              │ ★ Digunakan di workshop (po-project)            │
│                          │ CDS model → auto OData V4 → Fiori Elements     │
│                          │ Best for: rapid development, clean code         │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ CAP Java                 │ Same CDS model, Java runtime (Spring Boot)      │
│                          │ Best for: Java teams, enterprise patterns       │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ SAP Build Code           │ AI-assisted (Joule) development di BAS          │
│                          │ Generates CAP/Fiori project dari prompt         │
│                          │ Best for: accelerated development               │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ SAP Build Apps            │ No-code/low-code app builder                   │
│ (AppGyver)               │ Drag-and-drop UI + data binding                 │
│                          │ Best for: citizen developer, simple apps        │
├──────────────────────────┼──────────────────────────────────────────────────┤
│ Custom (Express, Spring, │ Bring your own framework                        │
│ Django, etc.)            │ Consume SAP APIs langsung                       │
│                          │ Best for: existing team skillset                │
└──────────────────────────┴──────────────────────────────────────────────────┘

Database Options (lihat PART 2 untuk detail):
  • HANA Cloud (full SAP native) — po-project pakai ini
  • PostgreSQL (budget-friendly)
  • SAP CBO Remote Entity (data di SAP) — po-project-in-apps pakai ini
  • MongoDB, Redis, dll (custom impl)
```

**Kapan pakai:**
- Custom app baru yang tidak ada di SAP standard (PO Request staging)
- Modern UI requirement (custom SAPUI5, React, dll)
- Integration hub (multiple SAP systems + non-SAP)
- Tim non-ABAP yang sudah proficient di Node.js/Java

---

#### Kategori 4: Side-by-Side Extensibility — Steampunk (BTP ABAP Environment)

**Persona:** ABAP developer yang mau cloud  
**Tools:** ADT (Eclipse) → BTP ABAP Environment  
**Coding:** ABAP Cloud (full — not restricted like Embedded)  
**Clean Core:** ✅ By design (isolated runtime)

```
BTP ABAP Environment ("Steampunk"):
═══════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────┐
│                    SAP BTP                                           │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ABAP Environment Instance                                    │   │
│  │                                                                │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────────────────┐  │   │
│  │  │ RAP BO     │  │ CDS Views  │  │ Custom ABAP Classes    │  │   │
│  │  │ (Z-table   │  │ (Analytics,│  │ (Business logic,       │  │   │
│  │  │  managed)  │  │  reports)  │  │  integration)          │  │   │
│  │  └────────────┘  └────────────┘  └────────────────────────┘  │   │
│  │                                                                │   │
│  │  ┌────────────────────────────────────────────────────────┐    │   │
│  │  │  HANA DB (embedded, auto-provisioned)                   │    │   │
│  │  │  → Tidak perlu manage sendiri                           │    │   │
│  │  └────────────────────────────────────────────────────────┘    │   │
│  │                                                                │   │
│  │  Communication:                                                │   │
│  │  • Consume SAP S/4HANA via Released APIs (OData, SOAP, RFC)   │   │
│  │  • Expose OData V4 services (via RAP)                          │   │
│  │  • Event Mesh integration                                      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Perbedaan Embedded Steampunk vs BTP Steampunk:
══════════════════════════════════════════════════

┌────────────────────────┬──────────────────────┬──────────────────────┐
│ Aspek                  │ Embedded Steampunk   │ BTP Steampunk        │
│                        │ (Kategori 2)         │ (Kategori 4)         │
├────────────────────────┼──────────────────────┼──────────────────────┤
│ Runtime location       │ Di dalam S/4HANA     │ Di BTP (cloud)       │
│ Database               │ Shared S/4HANA HANA  │ Own HANA (embedded)  │
│ API akses ke S/4       │ Local (fast)         │ Remote via OData/RFC │
│ Namespace              │ Customer (ZZ1_, YY1_)│ Z* / customer ns     │
│ ABAP syntax            │ Restricted           │ Full ABAP Cloud      │
│ S/4 DB table access    │ Released views only  │ No direct access     │
│ Lifecycle              │ Tied to S/4 upgrade  │ Independent          │
│ License biaya          │ Included in S/4      │ ~€2,200/bln (16GB)   │
│ Use case               │ Enhance S/4 process  │ Standalone ABAP app  │
└────────────────────────┴──────────────────────┴──────────────────────┘
```

**Kapan pakai:**
- Tim 100% ABAP, tidak mau pindah ke Node.js/Java
- Butuh ABAP-native features (AMDP, RAP draft, internal tables, BAPI wrapper)
- Standalone ABAP app terpisah dari S/4HANA (misal custom analytics platform)
- Migrasi Z-code dari on-premise ke cloud (gradual modernization)

---

### 1B.3 Mega Comparison — 4 Kategori + Classic ABAP

```
MEGA COMPARISON TABLE:
═══════════════════════════════════════════════════════════════════════════════

┌──────────────┬────────────────┬────────────────┬────────────────┬────────────────┬────────────────┐
│ Aspek        │ Classic ABAP   │ 1. In-App      │ 2. Embedded    │ 3. Side-by-Side│ 4. BTP ABAP    │
│              │ (LEGACY ❌)    │ Key User (CBO) │ Steampunk      │ CAP/Custom     │ Steampunk      │
├──────────────┼────────────────┼────────────────┼────────────────┼────────────────┼────────────────┤
│ Clean Core   │ ❌ Violation   │ ✅ Full        │ ✅ Full        │ ✅ Full        │ ✅ Full        │
│ Coding       │ ABAP (full)    │ Zero           │ ABAP Cloud     │ Node.js/Java   │ ABAP Cloud     │
│ Tools        │ SE80/SAPGUI    │ Browser/Fiori  │ ADT (Eclipse)  │ VS Code/BAS    │ ADT (Eclipse)  │
│ Runtime      │ S/4HANA        │ S/4HANA        │ S/4HANA        │ BTP CF/Kyma    │ BTP ABAP Env   │
│ Database     │ S/4 HANA embed │ S/4 HANA embed │ S/4 HANA embed │ HANA Cloud/PG  │ BTP HANA embed │
│ DB Cost      │ $0 (included)  │ $0 (included)  │ $0 (included)  │ $0–€693/bln    │ ~€2,200/bln    │
│ OData        │ SEGW (V2)      │ Auto V2        │ RAP (V2/V4)    │ CAP auto V4    │ RAP (V2/V4)    │
│ Fiori UI     │ Manual SAPUI5  │ Basic (auto)   │ Fiori Elements │ Fiori Elements │ Fiori Elements │
│ Draft support│ Custom build   │ No             │ RAP Managed    │ CAP managed    │ RAP Managed    │
│ Deep insert  │ Custom build   │ ❌ No          │ ✅ Yes (RAP)   │ ✅ Yes (CAP)   │ ✅ Yes (RAP)   │
│ Composition  │ Manual FK      │ ❌ No          │ ✅ CDS assoc   │ ✅ CDS Comp    │ ✅ CDS assoc   │
│ S/4 upgrade  │ ❌ Blocked     │ ✅ Safe        │ ✅ Safe        │ ✅ Decoupled   │ ✅ Decoupled   │
│ Skill needed │ Classic ABAP   │ None           │ ABAP Cloud     │ JS/Java + CDS  │ ABAP Cloud     │
│ Deployment   │ STMS transport │ Publish button │ STMS/gCTS      │ cf deploy MTA  │ gCTS/ABAP CI   │
│ Availability │ All versions   │ Cloud + OP≥1909│ Cloud + OP≥2022│ BTP account    │ BTP license     │
│ Workshop     │ —              │ ★ ho-4 + ho-5  │ ★ ho-6         │ ★ ho-1,2,3     │ —              │
└──────────────┴────────────────┴────────────────┴────────────────┴────────────────┴────────────────┘

Legend:
  OP = On-Premise
  PG = PostgreSQL
  ho = hands-on (dalam workshop ini)
```

### 1B.4 Decision Flow — Pilih Extensibility

```
START: "Saya butuh custom requirement di SAP"
═══════════════════════════════════════════════

                    ┌─────────────────────┐
                    │ Apakah hanya tambah │
                    │ field di standard   │
                    │ SAP BO?             │
                    └──────────┬──────────┘
                         │
                    ┌────▼────┐
                    │ Ya      │──────▶  Custom Fields (Kat. 1)
                    └────┬────┘         via Fiori Launchpad
                         │ Tidak
                    ┌────▼──────────────┐
                    │ Apakah butuh      │
                    │ custom table      │
                    │ sederhana (<30    │
                    │ fields, flat)?    │
                    └──────────┬────────┘
                         │
                    ┌────▼────┐
                    │ Ya      │──────▶  CBO (Kat. 1) + CAP proxy  ★ Workshop
                    └────┬────┘         po-project-in-apps
                         │ Tidak
                    ┌────▼──────────────┐
                    │ Data boleh di luar│
                    │ SAP (BTP)?        │
                    └──────────┬────────┘
                         │
              ┌──────────▼──────────┐
              │                     │
         ┌────▼────┐          ┌────▼────┐
         │ Ya      │          │ Tidak   │
         └────┬────┘          └────┬────┘
              │                    │
         ┌────▼──────────┐   ┌────▼──────────┐
         │ Tim ABAP?     │   │ Butuh complex │
         │               │   │ ABAP logic?   │
         └──────┬────────┘   └──────┬────────┘
           │         │          │        │
      ┌────▼──┐ ┌───▼────┐ ┌──▼───┐ ┌──▼───┐
      │ Ya    │ │ Tidak  │ │ Ya   │ │ Tidak│
      └───┬───┘ └───┬────┘ └──┬───┘ └──┬───┘
          │         │          │        │
          ▼         ▼          ▼        ▼
   BTP ABAP Env  CAP Node.js  Embedded  CBO +
   (Kat. 4)      (Kat. 3) ★   Steampunk Custom Logic
   "Steampunk"   Workshop      (Kat. 2) (Kat. 1)
                 po-project
```

### 1B.5 Workshop Coverage Map

Workshop ini mencakup **3 dari 4 kategori** extensibility:

```
Workshop Hands-on Mapping:
═══════════════════════════════════════════

Kategori 1 (In-App Key User) — CBO:
├── Hands-on 4: Buat CBO ZZ1_WPOREQ & ZZ1_WPOREQI
│   ├── Field definition, naming rules
│   ├── Enable Back End Service
│   ├── Gateway registration (/IWFND/MAINT_SERVICE)
│   └── OData CRUD test (curl)
├── Hands-on 5: CAP project consume CBO
│   ├── @cds.persistence.skip (no local DB)
│   ├── cbo-client.js (field mapping layer)
│   ├── ON handlers (manual CRUD proxy)
│   └── Same Fiori UI + postToSAP
└── Project: po-project-in-apps/

Kategori 2 (Embedded Steampunk) — RAP:
├── Hands-on 6: RAP PO Request — ABAP Cloud
│   ├── Database tables (ZTEC_POREQ, ZTEC_POREQI)
│   ├── CDS Interface + Consumption views
│   ├── Behavior Definition (managed + draft)
│   ├── Behavior Implementation (ABAP class)
│   │   ├── setRequestNo (auto-numbering)
│   │   ├── calcNetAmount + calcHeaderTotal
│   │   ├── validateSupplier + validateDeliveryDate
│   │   └── postToSAP action
│   ├── Metadata Extensions (Fiori annotations)
│   ├── Service Definition + Binding (OData V4)
│   └── Fiori Elements Preview via ADT
└── IDE: ADT (Eclipse), bukan VS Code

Kategori 3 (Side-by-Side CAP):
├── Hands-on 1: CDS data model + cds watch
│   ├── po-schema.cds (cuid + managed)
│   ├── CSV seed data
│   └── SQLite local
├── Hands-on 2: OData service + SAP integration
│   ├── po-service.cds + po-service.js
│   ├── sap-client.js (5-step draft PO creation)
│   └── SAP connection verified
├── Hands-on 3: Fiori UI + HANA Cloud + Post to SAP
│   ├── annotations.cds (Fiori Elements)
│   ├── HANA Cloud HDI deploy
│   ├── Hybrid mode
│   └── PO 4500000016-4500000019 created in SAP real
└── Project: po-project/

Kategori 4 — Tidak di-cover di workshop ini:
└── Kategori 4 (BTP ABAP Env): Butuh license ~€2,200/bln + ABAP Cloud skill
```

### 1B.6 Evolusi SAP Extensibility — Timeline

```
SAP Extensibility Evolution:
═══════════════════════════════════════════════════════════════════════

1992-2010: CLASSIC ABAP ERA
├── SE38, SE80, SMOD, CMOD
├── Z-tables, Z-programs everywhere
├── Enhancement framework (implicit/explicit)
└── Impact: Upgrade nightmare, SAP refuses support

2011-2015: GATEWAY + FIORI ERA
├── SEGW (OData V2 service builder)
├── Fiori apps (SAPUI5)
├── Still: Z-code in backend
└── Impact: Better UI, same backend problem

2016-2019: CLOUD PLATFORM ERA
├── SAP Cloud Platform (SCP) launched
├── Neo environment → Cloud Foundry
├── CBO introduced (S/4HANA 1709+)
├── Custom Fields & Logic
└── Impact: First in-app extensibility

2020-2022: CLEAN CORE ERA
├── SAP BTP (rebranded from SCP)
├── CAP framework matures (CDS, OData V4)
├── Embedded Steampunk preview
├── ABAP Cloud syntax enforced
├── RAP (RESTful ABAP Programming) standard
└── Impact: Clean Core becomes official strategy

2023-2024: STEAMPUNK + AI ERA
├── BTP ABAP Environment GA
├── Embedded Steampunk GA (S/4HANA 2022+)
├── SAP Build Code + Joule (AI-assisted)
├── SAP Build Apps (no-code)
├── ABAP Cloud mandatory di S/4HANA Cloud
└── Impact: All 4 extensibility categories available

2025-2026: CURRENT STATE (Workshop)
├── CAP v9 + HANA Cloud + Fiori Elements
├── CBO mature (OData V2 CRUD ready)
├── Side-by-side = recommended default
├── In-app = zero-cost option
├── Steampunk = ABAP teams only
└── Workshop: Demonstrates Kat. 1 + Kat. 3
```

### 1B.7 Real-World Scenario Matrix

```
SCENARIO → RECOMMENDED APPROACH:
═══════════════════════════════════════════════════════════════════════

┌──────────────────────────────────┬────────────────────┬─────────────┐
│ Scenario                         │ Approach           │ Kategori    │
├──────────────────────────────────┼────────────────────┼─────────────┤
│ Tambah 3 custom field di SO      │ Custom Fields      │ 1 (Key User)│
│ PO approval staging table        │ CBO + CAP proxy    │ 1 + 3       │
│ Custom report (CDS + Fiori)      │ CBO Analytical Q.  │ 1 (Key User)│
│ Complex analytics dashboard      │ CAP + HANA Cloud   │ 3 (CAP)    │
│ Machine learning integration     │ CAP + BTP AI Svc   │ 3 (CAP)    │
│ BADI di PO process               │ Embedded Steampunk │ 2 (Dev)    │
│ Custom RAP BO inside S/4         │ Embedded Steampunk │ 2 (Dev)    │
│ Migrate 100 Z-programs to cloud  │ BTP ABAP Env       │ 4 (Stmpnk) │
│ Central integration middleware    │ CAP + Int. Suite   │ 3 (CAP)    │
│ Multi-system data aggregation    │ CAP + HANA Cloud   │ 3 (CAP)    │
│ Simple form app for power users  │ SAP Build Apps     │ 3 (No-code)│
│ IoT sensor → S/4HANA upload      │ CAP Node.js        │ 3 (CAP)    │
│ Vendor portal (external users)   │ CAP + XSUAA + IAS  │ 3 (CAP)    │
│ Hide fields di standard Fiori    │ Key User Adapt.    │ 1 (Key User)│
│ Data harus di SAP (compliance)   │ CBO / Embedded     │ 1 or 2     │
│ Team 100% ABAP, budget OK        │ BTP ABAP Env       │ 4 (Stmpnk) │
│ Team full-stack, budget-aware    │ CAP + PostgreSQL   │ 3 (CAP)    │
│ Greenfield S/4HANA Cloud         │ Embedded Steampunk │ 2 (Dev)    │
│ THIS WORKSHOP (PO Management)    │ CBO+CAP+RAP        │ 1+2+3 ★    │
└──────────────────────────────────┴────────────────────┴─────────────┘
```

### 1B.8 Clean Core Compliance Checklist

```
CLEAN CORE — Apa yang BOLEH dan TIDAK BOLEH:
═══════════════════════════════════════════════════════════

✅ BOLEH (Clean Core Compliant):
├── Consume Released OData API (I_PurchaseOrder, etc.)
├── Consume Released SOAP service
├── Consume Released RFC (di wrapper)
├── Buat CBO (custom table via browser)
├── Buat Custom Fields di standard BO
├── Implement Released BADIs
├── CAP side-by-side app consume API
├── BTP ABAP Env consume API
├── Key User UI adaptation
└── Custom CDS view di Released entities

❌ TIDAK BOLEH (Violates Clean Core):
├── Direct table access (SELECT * FROM EKKO)
├── Modify standard ABAP code
├── Classic enhancement (SMOD/CMOD)
├── Implicit enhancement points
├── User exits (non-released)
├── Append structure ke standard table
├── Custom index di standard table
├── Direct RFC call ke unreleased FM
├── BTP app direct DB query ke S/4HANA
└── Any modification key usage

GRAY AREA (Perlu evaluasi):
├── Wrapper BAPI (released wrapper = OK)
├── Classic BTE (Business Transaction Events)
├── Output management customization
└── Screen exit (still supported tapi deprecated)
```

### 1B.9 Clean Core Classification: Level A–D & Tier 1–3

SAP mendefinisikan **2 dimensi** untuk mengklasifikasikan extensibility:

1. **Level A–D** = Jenis pendekatan (Approach Type)
2. **Tier 1–3** = Tingkat kepatuhan Clean Core (Compliance Level)

#### Level A–D: Clean Core Extensibility Approach

```
SAP CLEAN CORE — EXTENSIBILITY LEVELS (Official):
═══════════════════════════════════════════════════════════════════════════════

Level A — CONFIGURATION ONLY
  Siapa:   SAP Functional Consultant / Admin
  Cara:    Customizing (SPRO), Fiori Launchpad settings, UI adaptation
  Coding:  Tidak ada
  Contoh:  • Aktifkan/nonaktifkan Fiori app
           • Configure number range
           • Key User UI adaptation (hide field, change label)
           • Personalisasi layout
  Clean Core: ✅ Selalu compliant — tidak menyentuh kode sama sekali

Level B — KEY USER EXTENSIBILITY (In-App, Browser-Based)
  Siapa:   Business Analyst / Power User / Functional Consultant
  Cara:    SAP Fiori Launchpad → Custom Business Objects, Custom Fields, Custom Logic
  Coding:  Zero / minimal (scripting sederhana di Custom Logic)
  Contoh:  • CBO ZZ1_WPOREQ + ZZ1_WPOREQI ★ (ho-4)
           • Custom Fields di Purchase Order standard
           • Custom Analytical Queries
           • Custom Communication Arrangement
  Clean Core: ✅ Selalu compliant — SAP menyediakan framework resmi
  Workshop:  ho-4 (CBO creation) + ho-5 (CAP consume CBO)

Level C — DEVELOPER EXTENSIBILITY (In-App atau Side-by-Side)
  Siapa:   ABAP Developer / Full-Stack Developer
  Cara:    ADT (Eclipse), VS Code, BAS — butuh IDE + coding skill
  Coding:  ABAP Cloud (RAP), Node.js (CAP), Java (CAP)
  Contoh:  • RAP Business Objects ★ (ho-6)
           • CAP Node.js + HANA Cloud ★ (ho-1,2,3)
           • CDS Views + BADI implementation
           • BTP ABAP Environment
           • Released API consumption
  Clean Core: ✅ Compliant JIKA hanya pakai Released APIs + ABAP Cloud syntax
  Workshop:  ho-1,2,3 (CAP) + ho-6 (RAP)

Level D — CLASSIC EXTENSIBILITY (Legacy / Not Recommended)
  Siapa:   Classic ABAP Developer
  Cara:    SE80, SE38, SMOD/CMOD, SE11 — SAP GUI
  Coding:  Classic ABAP (unrestricted)
  Contoh:  • Z-tables + Z-programs (SELECT * FROM EKKO)
           • Classic enhancements (SMOD/CMOD)
           • Implicit enhancement points
           • User exits / modification keys
           • Direct table access ke standard SAP tables
  Clean Core: ❌ TIDAK compliant — violates Clean Core principle
              ⚠️ Masih banyak dipakai di On-Premise, tapi blok S/4HANA Cloud migration
```

```
LEVEL MAPPING KE WORKSHOP:
═══════════════════════════════════════════════════════════

Level A (Config):
  └── Tidak di-cover di workshop (terlalu sederhana, tidak perlu coding)

Level B (Key User):
  ├── ho-4: Buat CBO ZZ1_WPOREQ + ZZ1_WPOREQI ★
  └── ho-5: CAP project consume CBO ★

Level C (Developer):
  ├── ho-1,2,3: CAP Side-by-Side (Node.js + HANA Cloud) ★
  └── ho-6: RAP Embedded Steampunk (ABAP Cloud) ★

Level D (Classic):
  └── TIDAK DI-COVER — workshop ini sepenuhnya Clean Core
```

#### Tier 1–3: Clean Core Compliance Level

```
SAP CLEAN CORE — COMPLIANCE TIERS (Official):
═══════════════════════════════════════════════════════════════════════════════

Tier 3 — FULLY CLEAN CORE COMPLIANT ✅ (Target / Recommended)
──────────────────────────────────────────────────────────────
  Definisi: Hanya menggunakan Released APIs, Released Objects, dan
            extensibility framework resmi SAP.
  Ciri-ciri:
  • Tidak ada akses langsung ke tabel SAP standard (EKKO, MARA, etc.)
  • Hanya consume I_PurchaseOrder, I_SalesOrder (Released CDS Views)
  • Hanya implement Released BADIs
  • CBO / Custom Fields via Fiori Launchpad
  • ABAP Cloud syntax (compiler enforce whitelist)
  • Side-by-side app via Released OData/SOAP/RFC APIs
  • S/4HANA upgrade: AMAN — SAP guarantee backward compatibility

  Dampak:
  ✅ Bisa migrasi ke S/4HANA Cloud tanpa rewrite
  ✅ SAP guarantee: Released API tidak akan di-break di upgrade
  ✅ SAP support penuh (tidak ada "itu kode custom Anda")
  ✅ Upgrade S/4HANA on-premise: hitungan hari, bukan bulan

  Workshop hands-on yang masuk Tier 3:
  ├── ho-1,2,3 (CAP Side-by-Side)     ← consume Released OData API
  ├── ho-4,5 (CBO + CAP)              ← CBO = in-app framework resmi
  └── ho-6 (RAP Embedded Steampunk)    ← ABAP Cloud = Released only

  ★ SEMUA 6 HANDS-ON DI WORKSHOP INI = TIER 3 ★


Tier 2 — PARTIALLY COMPLIANT ⚠️ (Tolerated / Migratable)
──────────────────────────────────────────────────────────────
  Definisi: Menggunakan classic extensibility yang MASIH didukung SAP,
            tetapi sebaiknya di-migrasi ke Tier 3 dalam roadmap.
  Ciri-ciri:
  • Classic BADIs yang masih aktif (bukan deprecated)
  • BTE (Business Transaction Events)
  • Output management customization
  • Screen exits yang masih didukung
  • Wrapper BAPI via released wrapper (gray area)
  • Custom Z-code yang HANYA baca Released CDS Views (minimal intrusion)

  Dampak:
  ⚠️ Masih bisa upgrade, tapi perlu test regresi lebih banyak
  ⚠️ SAP mungkin deprecate di release mendatang
  ⚠️ Tidak bisa ke S/4HANA Cloud Public Edition tanpa refactor
  ⚠️ Support terbatas — SAP bisa bilang "migrate dulu"

  Contoh di dunia nyata:
  ├── Output determination via classic NACE
  ├── Pricing procedure modification via classic exits
  ├── Classic workflow (SWO1) yang belum migrasi ke SAP Build
  └── Custom screen di standard transaction (masih didukung, tapi deprecated)

  Workshop: Tidak di-cover (workshop ini skip Tier 2 langsung ke Tier 3).


Tier 1 — NOT CLEAN CORE COMPLIANT ❌ (Legacy / Harus Di-remediasi)
──────────────────────────────────────────────────────────────
  Definisi: Modifikasi langsung ke core SAP, akses unreleased API,
            atau perubahan yang melanggar integritas system.
  Ciri-ciri:
  • SELECT * FROM EKKO / EKPO / MARA (direct table access)
  • CALL FUNCTION 'BAPI_xxx' tanpa released wrapper
  • MODIFY ekko FROM wa_ekko (direct table modification)
  • Classic enhancement (SMOD/CMOD/implicit enhancement points)
  • Modification key (SSCR) — ubah standard SAP code
  • Append structure ke standard table
  • Custom index di standard table
  • Z-programs with unreleased function module calls

  Dampak:
  ❌ S/4HANA upgrade: 6–18 bulan testing, sering gagal
  ❌ S/4HANA Cloud migration: IMPOSSIBLE tanpa rewrite total
  ❌ SAP support: "Ini bukan tanggung jawab kami"
  ❌ Setiap SP/patch bisa break custom code
  ❌ Technical debt bertambah setiap tahun

  Contoh di dunia nyata (yang HARUS di-remediasi):
  ├── 500 Z-tables dengan direct FK ke EKKO
  ├── 300 Z-programs dengan SELECT * FROM standard tables
  ├── 150 classic enhancements (SMOD/CMOD)
  ├── 50 modification keys di standard programs
  └── 20 tahun technical debt → upgrade estimate: 12 bulan

  Workshop: Level D — TIDAK di-cover. Justru ini yang kita HINDARI.
```

#### Peta Lengkap: Level × Tier × Workshop

```
COMPLETE CLASSIFICATION MAP:
═══════════════════════════════════════════════════════════════════════════════

                    │ Tier 3 (✅ Compliant)    │ Tier 2 (⚠️ Tolerated)  │ Tier 1 (❌ Legacy)
════════════════════╪═════════════════════════╪═══════════════════════╪══════════════════════
Level A (Config)    │ UI adaptation           │                       │
                    │ Customizing (SPRO)      │                       │
                    │ Number range config     │                       │
────────────────────┼─────────────────────────┼───────────────────────┼──────────────────────
Level B (Key User)  │ CBO ★ ho-4             │                       │
                    │ Custom Fields           │                       │
                    │ Custom Logic            │                       │
                    │ Custom Analytical Query │                       │
────────────────────┼─────────────────────────┼───────────────────────┼──────────────────────
Level C (Developer) │ RAP (ABAP Cloud) ★ ho-6│ Classic BADI (active) │
                    │ CAP Node.js ★ ho-1,2,3 │ BTE (tolerated)       │
                    │ CAP + CBO ★ ho-5       │ Wrapper BAPI          │
                    │ BTP ABAP Env           │ Screen exit (supported)│
                    │ Released BADI impl     │                       │
────────────────────┼─────────────────────────┼───────────────────────┼──────────────────────
Level D (Classic)   │                         │                       │ Z-tables direct
                    │                         │                       │ Z-programs (SE38)
                    │                         │                       │ SMOD/CMOD
                    │                         │                       │ Modification keys
                    │                         │                       │ Direct table access
                    │                         │                       │ Unreleased FM calls
════════════════════╧═════════════════════════╧═══════════════════════╧══════════════════════

★ = Di-cover di workshop ini
Semua workshop hands-on berada di kolom Tier 3 (Fully Compliant) ✅
```

#### Hubungan Level × Tier dengan 4 Kategori Extensibility

```
MAPPING KE 4 KATEGORI (dari 1B.1):
═══════════════════════════════════════════════════════════

Kategori 1 (In-App Key User)      = Level B, Tier 3   ✅
  → ho-4: CBO creation
  → ho-5: CAP + CBO proxy

Kategori 2 (Embedded Steampunk)   = Level C, Tier 3   ✅
  → ho-6: RAP + ABAP Cloud di S/4HANA

Kategori 3 (Side-by-Side CAP)     = Level C, Tier 3   ✅
  → ho-1,2,3: CAP Node.js + HANA Cloud

Kategori 4 (BTP ABAP Env)         = Level C, Tier 3   ✅
  → Tidak di-cover (butuh license €2,200/bln)

Classic ABAP (Legacy)              = Level D, Tier 1   ❌
  → Tidak di-cover (ini yang kita HINDARI)
```

> **Takeaway:** Workshop ini 100% Tier 3 (Fully Clean Core Compliant).
> Peserta belajar **3 cara berbeda** (Level B + Level C) untuk mencapai
> hasil yang sama — semuanya tanpa menyentuh core SAP.

---

### 1B.10 Komparasi Kesulitan Development — 3 Pendekatan Workshop

Terlepas dari klasifikasi Clean Core di atas, berikut perbandingan **tingkat kesulitan development** dari ketiga pendekatan workshop.

> **Catatan:** Semua 3 pendekatan berada di **Tier 3 (Fully Compliant)** dan **Level B/C**.
> Perbedaan di bawah murni soal **difficulty teknis** — bukan soal kualitas Clean Core.

#### Skala Kesulitan (1–5 ★)

```
★☆☆☆☆ = Mudah (siapapun bisa, < 2 jam belajar)
★★☆☆☆ = Cukup mudah (perlu sedikit belajar)
★★★☆☆ = Sedang (perlu 2-8 jam belajar konsep baru)
★★★★☆ = Sulit (gabungan teknologi, error cryptic, 1-3 hari belajar)
★★★★★ = Sangat sulit (banyak moving parts, perlu project nyata)
```

#### Difficulty Radar

```
DEVELOPMENT DIFFICULTY RADAR:
═══════════════════════════════════════════════════════════

                    1. CBO+CAP    2. RAP/Steampunk   3. CAP Side-by-Side
                    (ho-4 + ho-5) (ho-6)             (ho-1,2,3)
                    ────────────  ──────────────────  ───────────────────
Setup & Tooling     ★★☆☆☆         ★★★☆☆               ★★★★☆
Data Modeling       ★☆☆☆☆         ★★★★☆               ★★☆☆☆
Business Logic      ★★★★☆         ★★★★★               ★★★☆☆
UI / Fiori          ★★☆☆☆         ★★☆☆☆               ★★★☆☆
SAP Integration     ★★☆☆☆         ★☆☆☆☆               ★★★★★
Deployment          ★☆☆☆☆         ★★☆☆☆               ★★★★★
Debugging           ★★★★☆         ★★★☆☆               ★★☆☆☆
                    ────────────  ──────────────────  ───────────────────
Total Difficulty    ★★☆☆☆         ★★★☆☆               ★★★★☆
                    (Mudah)       (Sedang)            (Sulit)
```

#### Detail Penjelasan per Aspek

| Aspek | CBO + CAP (Part B) | RAP Steampunk (Part C) | CAP Side-by-Side (Part A) |
|:------|:--------------------|:-----------------------|:--------------------------|
| **Setup & Tooling** | VS Code + `npm install` (familiar). CBO dibuat di browser Fiori Launchpad — zero install | ADT (Eclipse) perlu install + plugin + koneksi ABAP Project. Learning curve untuk IDE baru | VS Code + npm + CF CLI + BTP account + HANA Cloud instance + `cds bind`. Paling banyak komponen external |
| **Data Modeling** | CBO: klik-klik di browser (field name, type, done). CDS schema minimal (`@cds.persistence.skip`) | ABAP table definition (verbose: `abap.char`, `abap.curr`, client field). CDS Interface View + Consumption View + explicit mapping. **2x jumlah objek** vs CAP | CDS schema ringkas (`cuid`, `managed`). 1 file `po-schema.cds` ≈ 90% selesai |
| **Business Logic** | `cbo-client.js` = paling tricky. Field mapping CBO yang mismatch (CompanyCode=PODescription bug). Manual CRUD proxy via `ON` handlers. CSRF token handling | ABAP Cloud syntax baru: EML (`READ ENTITIES`, `MODIFY ENTITIES`), `%tky`, `%msg`, inline declarations. Powerful tapi learning curve tinggi jika belum pernah ABAP 7.40+ | `this.before/after` hooks — intuitif untuk JS developer. `sap-client.js` complex (5-step draft) tapi well-documented pattern |
| **UI / Fiori** | `annotations.cds` (standard CAP pattern). Webapp manifest auto-generated | Metadata Extension di CDS — syntax sedikit beda tapi konsep sama. **Bonus:** Fiori Preview langsung dari Service Binding (zero webapp config) | `annotations.cds` + `manifest.json` + `Component.js` + `index.html`. Perlu setup webapp folder structure |
| **SAP Integration** | CBO OData V2 + PO Create = 2 koneksi external. `cbo-client.js` handle field mapping + date format | **Semua di dalam ABAP stack** — `BAPI_PO_CREATE1` atau internal API call, tidak perlu koneksi HTTP external. Paling mudah untuk integrasi SAP | `sap-client.js` via HTTPS ke SAP OData. Perlu handle: authentication, CSRF, date conversion, error parsing. Paling jauh dari SAP |
| **Deployment** | `npm start` di BTP CF. CBO sudah ada di SAP — tidak perlu deploy terpisah | `Activate` per objek di ADT → `Publish` Service Binding. Tidak perlu MTA, CF, atau build step | MTA build (`mbt build`) → `cf deploy`. Perlu HANA HDI deploy, XSUAA config, Destination, xs-security.json. **Paling complex** |
| **Debugging** | `console.log` + `cds watch` hot reload. CBO error: cek Gateway log (`/IWFND/ERROR_LOG`) | ABAP Debugger di ADT (breakpoint, variable watch, call stack). Mature tooling tapi perlu kebiasaan | `console.log` + `cds watch`. HANA error: cek HDI deploy log. SAP error: HTTP response code |

#### Learning Curve per Skill Background

```
Jika background Anda adalah...
═══════════════════════════════════════════════════════════

🟢 JavaScript/Node.js Developer:
   Termudah → CAP Side-by-Side (ho-1,2,3)  ← bahasa sendiri
   Sedang   → CBO + CAP (ho-4,5)           ← masih JS, tapi field mapping tricky
   Tersulit → RAP Steampunk (ho-6)          ← harus belajar ABAP dari nol

🟡 ABAP Developer (Classic):
   Termudah → RAP Steampunk (ho-6)          ← bahasa sendiri + modern syntax
   Sedang   → CBO + CAP (ho-4,5)            ← CBO familiar, JS proxy new
   Tersulit → CAP Side-by-Side (ho-1,2,3)   ← Node.js + CDS + BTP = all new

🔵 SAP Functional / Key User:
   Termudah → CBO + CAP (ho-4,5)            ← CBO via browser, CAP copy-paste
   Sedang   → CAP Side-by-Side (ho-1,2,3)   ← guided workshop, tapi banyak tool
   Tersulit → RAP Steampunk (ho-6)          ← ABAP coding = steep learning curve

🟣 Freshgraduate / No SAP Experience:
   Termudah → CAP Side-by-Side (ho-1,2,3)   ← modern stack, banyak tutorial
   Sedang   → CBO + CAP (ho-4,5)            ← perlu akses SAP system
   Tersulit → RAP Steampunk (ho-6)          ← ABAP + SAP ecosystem = overwhelm
```

#### Effort Estimation (PO Request System)

| Metrik | CBO + CAP | RAP Steampunk | CAP Side-by-Side |
|:-------|:----------|:--------------|:-----------------|
| Jumlah file/objek | ~12 files | ~13 ABAP objects | ~10 files |
| Lines of code (logic) | ~250 JS | ~300 ABAP | ~200 JS |
| Lines of code (model) | ~50 CDS | ~200 CDS+DDL | ~80 CDS |
| Waktu workshop (guided) | ~120 min (ho-4+5) | ~90 min (ho-6) | ~120 min (ho-1,2,3) |
| Waktu real (dari nol) | ~4-6 jam | ~6-8 jam | ~8-12 jam |
| Prerequisites | VS Code, npm, SAP system | ADT, SAP system | VS Code, npm, CF CLI, BTP, HANA Cloud |
| External dependencies | 2 (CBO + PO API) | 0 (semua internal) | 3+ (HANA, XSUAA, Destination) |
| Errors paling sering | CBO field mismatch, CSRF token, Gateway registration | Syntax error ABAP, EML typo, draft table activation | HANA connection, MTA build, binding config |

#### Verdict: Kapan Pakai Yang Mana?

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  "Saya mau CEPAT jadi, data di SAP"  →  CBO + CAP (ho-4,5)        │
│                                                                     │
│  "Saya mau NATIVE SAP, tanpa BTP"    →  RAP Steampunk (ho-6)      │
│                                                                     │
│  "Saya mau FULL CONTROL, modern"     →  CAP Side-by-Side (ho-1,2,3)│
│                                                                     │
│  "Budget ketat, tim JS"              →  CBO + CAP (cheapest)       │
│                                                                     │
│  "Enterprise scale, SAP standard"    →  RAP Steampunk (best fit)   │
│                                                                     │
│  "Microservice, multi-channel"       →  CAP Side-by-Side (flexible)│
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🗄️ PART 2: Database Strategy — Mengapa HANA Cloud

### 2.1 Perbandingan Database Option di BTP

```
Database Options untuk CAP Project:
═══════════════════════════════════════════

┌────────────────────┬──────────────┬──────────────┬──────────────────┬──────────────────┐
│ Aspek              │ SQLite       │ PostgreSQL   │ SAP HANA Cloud   │ CBO Remote Entity│
├────────────────────┼──────────────┼──────────────┼──────────────────┼──────────────────┤
│ Development        │ ✅ Gratis    │ ✅ Gratis    │ ⚠️ BTP Trial    │ ✅ Gratis (SAP)  │
│ Production         │ ❌ Tidak     │ ✅ Ya        │ ✅ Ya (recommend)│ ✅ Ya (in-SAP)   │
│ SAP Fiori Support  │ ⚠️ Limited  │ ✅ Ya        │ ✅ Full          │ ✅ Full          │
│ HDI Container      │ ❌ Tidak     │ ❌ Tidak     │ ✅ Ya            │ ❌ Tidak perlu   │
│ Cloud-native       │ ❌ File-based│ ✅ Ya        │ ✅ Ya            │ ⚠️ Di SAP       │
│ CDS Native Types   │ ⚠️ Mapped   │ ⚠️ Mapped   │ ✅ Native        │ ⚠️ OData types  │
│ Full-text Search   │ ❌ Tidak     │ ✅ Ya        │ ✅ Ya (advanced)  │ ❌ Tidak         │
│ Calculation Views  │ ❌ Tidak     │ ❌ Tidak     │ ✅ Ya            │ ❌ Tidak         │
│ Spatial/Graph      │ ❌ Tidak     │ ⚠️ Plugin   │ ✅ Native        │ ❌ Tidak         │
│ MTA Deploy         │ ❌ Tidak     │ ⚠️ Plugin   │ ✅ Standard      │ ✅ Tidak perlu DB│
│ SAP Support        │ ❌ Tidak     │ ⚠️ Limited  │ ✅ Full          │ ✅ Full (in-app) │
│ Biaya DB           │ $0           │ ~$30-50/bln  │ ~€693/bln (paid) │ $0 (SAP license) │
│ Data Location      │ Lokal        │ BTP/Cloud    │ BTP HANA Cloud   │ Di SAP S/4HANA   │
└────────────────────┴──────────────┴──────────────┴──────────────────┴──────────────────┘

Rekomendasi per skenario:
• Development lokal     → SQLite (cepat, zero config)
• Hybrid testing        → HANA Cloud dari BTP Trial (via cds bind)
• Production (full)     → HANA Cloud HDI Container
• Production (budget)   → PostgreSQL via Hyperscaler DB Service
• Data harus di SAP     → CBO Remote Entity (no external DB)
```

> **💡 Catatan:** Selain SQLite/PostgreSQL/HANA, ada opsi **CBO Remote Entity** dimana
> CAP tetap menjadi logic layer, tapi data disimpan di SAP S/4HANA melalui Custom Business Object.
> Detail lengkap di bagian 2.4-2.6 di bawah.

### 2.2 Kenapa HANA Cloud — Bukan "Just Any Database"

HANA Cloud bukan sekadar database. Ia adalah **bagian integral dari ekosistem SAP**:

```
1. HDI CONTAINER (HANA Deployment Infrastructure)
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   • Setiap app mendapat "container" terisolasi
   • Schema management otomatis (no manual DDL)
   • CDS → HANA table/view → deployed via MTA
   • ROLLBACK otomatis jika deploy gagal
   
   Analogi: Seperti Docker container untuk database
   ┌─────────────────────────────────────┐
   │  HANA Cloud Instance                │
   │  ┌──────────┐  ┌──────────┐        │
   │  │ HDI: PO  │  │ HDI:     │        │
   │  │ App      │  │ Bookshop │        │
   │  │ ───────  │  │ ───────  │        │
   │  │ POReq    │  │ Books    │        │
   │  │ POItems  │  │ Authors  │        │
   │  │ (terisolasi) │ (terisolasi) │   │
   │  └──────────┘  └──────────┘        │
   └─────────────────────────────────────┘

2. CDS → HANA NATIVE TYPES
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   CDS Type          → HANA Type
   ─────────────────────────────────────────
   UUID              → NVARCHAR(36)
   String(10)        → NVARCHAR(10)
   Integer           → INTEGER
   Decimal(15,2)     → DECIMAL(15,2)
   Date              → DATE
   DateTime          → TIMESTAMP
   Boolean           → BOOLEAN
   
   CDS Aspect        → HANA Columns
   ─────────────────────────────────────────
   cuid              → ID NVARCHAR(36) PRIMARY KEY
   managed           → createdAt, createdBy, modifiedAt, modifiedBy

3. DEPLOYMENT FLOW
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   cds build --production
       ↓
   gen/db/          ← HANA artifacts (.hdbtable, .hdbview)
   gen/srv/         ← Node.js service bundle
       ↓
   cf deploy bookshop_1.0.0.mtar
       ↓
   HDI Container dibuat otomatis
   Tables di-CREATE otomatis
   CSV data di-INSERT otomatis
   Service di-bind ke container
```

### 2.3 Multi-Profile Strategy: SQLite (Dev) → HANA (Production)

CAP mendukung **profile-based configuration** — satu codebase, beda database:

```json
// package.json — cds configuration
{
  "cds": {
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
          "credentials": { "url": ":memory:" }
        }
      }
    },
    "[production]": {
      "requires": {
        "db": {
          "kind": "hana",
          "impl": "@sap/cds-hana",
          "deploy-format": "hdbtable"
        }
      }
    }
  }
}
```

```bash
# Profile switching:
cds watch                            # → [development] → SQLite in-memory
cds watch --profile hybrid           # → [hybrid] → HANA Cloud dari BTP Trial
NODE_ENV=production cds-serve        # → [production] → HANA Cloud HDI
```

### 2.4 Opsi Alternatif: CAP + PostgreSQL (Budget-Friendly)

Untuk skenario dimana HANA Cloud terlalu mahal, **PostgreSQL** bisa digunakan sebagai
database production via **SAP BTP Hyperscaler Option** atau PostgreSQL managed di cloud provider lain:

```
Architecture: CAP + PostgreSQL
═══════════════════════════════════════════

┌─────────┐    ┌──────────────┐    ┌───────────────────┐    ┌───────┐
│  Fiori   │───▶│  CAP OData   │───▶│  PostgreSQL        │    │ SAP   │
│  Elements│    │  V4 Service  │    │  (BTP Hyperscaler  │    │ S/4   │
│  (UI)    │◀───│  (Node.js)   │◀───│   atau external)   │    │ HANA  │
└─────────┘    └──────┬───────┘    └───────────────────┘    └───┬───┘
                       │                                         │
                       └──── OData V2 + CSRF Token ─────────────┘
```

**Setup PostgreSQL di CAP:**
```bash
# Install PostgreSQL driver
npm add @cap-js/postgres

# package.json profile
# "[production]": {
#   "requires": {
#     "db": {
#       "kind": "postgres",
#       "impl": "@cap-js/postgres"
#     }
#   }
# }
```

**Kelebihan PostgreSQL:**
- Biaya ~$30-50/bulan (vs HANA Cloud ~€693/bulan)
- Familiar bagi developer non-SAP
- Bisa self-hosted atau managed (AWS RDS, Azure DB, GCP Cloud SQL)
- CAP driver `@cap-js/postgres` sudah mature

**Kekurangan PostgreSQL:**
- Tidak ada HDI Container (schema management manual)
- Tidak ada Calculation Views, Spatial/Graph native
- MTA deploy perlu konfigurasi tambahan
- SAP support terbatas untuk issue database-level

### 2.5 Opsi Alternatif: CAP + Remote Entity → Custom Business Object (CBO)

Opsi ini **paling radikal** — tidak butuh database eksternal sama sekali. Data disimpan
**langsung di SAP S/4HANA** melalui Custom Business Object (CBO), dan CAP hanya berfungsi
sebagai **logic layer + API gateway**:

```
Architecture: CAP + Remote Entity → CBO
═══════════════════════════════════════════

┌─────────┐    ┌──────────────────────┐    ┌────────────────────────┐
│  Fiori   │───▶│  CAP OData V4        │    │  SAP S/4HANA           │
│  Elements│    │  Service (Node.js)   │───▶│                        │
│  (UI)    │◀───│                      │◀───│  CBO: ZZ1_POREQUEST    │
└─────────┘    │  ┌─────────────────┐ │    │  ┌──────────────────┐  │
                │  │ Remote Entity   │ │    │  │ Custom Table     │  │
                │  │ @cds.external   │─┼───▶│  │ (auto-generated) │  │
                │  │ PORequests      │ │    │  │ POReq Header     │  │
                │  │ PORequestItems  │ │    │  │ POReq Items      │  │
                │  └─────────────────┘ │    │  └──────────────────┘  │
                │                      │    │                        │
                │  ┌─────────────────┐ │    │  ┌──────────────────┐  │
                │  │ Custom Handlers │ │    │  │ OData V2 API     │  │
                │  │ (business logic)│─┼───▶│  │ (auto-generated  │  │
                │  │ validation,     │ │    │  │  oleh CBO)       │  │
                │  │ calculation     │ │    │  └──────────────────┘  │
                │  └─────────────────┘ │    │                        │
                └──────────────────────┘    └────────────────────────┘

Flow: Fiori → CAP → Remote Entity → CBO OData API → SAP Table
      (No external database needed!)
```

**Apa itu Custom Business Object (CBO)?**

CBO adalah fitur **in-app extensibility** di SAP S/4HANA yang memungkinkan pembuatan
custom table dan OData service **tanpa coding ABAP**, langsung dari browser:

```
Cara membuat CBO di SAP:
═══════════════════════════════════════════

1. Buka Fiori Launchpad → App "Custom Business Objects"
2. Create New → Nama: ZZ1_POREQUEST
3. Tambah field:
   ├── RequestNo (Text, 10)
   ├── Description (Text, 200)
   ├── CompanyCode (Text, 4)
   ├── Supplier (Text, 10)
   ├── Status (Text, 1)
   └── ... (mirip CDS schema kita)
4. Publish → SAP otomatis generate:
   ├── Database Table (di HANA S/4)
   ├── OData V2 Service (CRUD)
   ├── Fiori UI (basic maintenance)
   └── Authorization object

Akses CBO via transaksi:
  Fiori App: "Custom Business Objects"
  URL: /sap/bc/ui2/flp#CustomBusinessObject-develop
```

**CAP sebagai Logic Layer untuk CBO:**
```cds
// srv/external/cbo-porequest.cds
// Import CBO OData service sebagai external
@cds.external
service CBO_POREQUEST {
    entity ZZ1_POREQUEST {
        key RequestNo    : String(10);
        Description      : String(200);
        CompanyCode      : String(4);
        Supplier         : String(10);
        Status           : String(1);
        TotalAmount      : Decimal(15,2);
    }
}

// srv/po-service.cds
// Expose CBO via CAP dengan business logic tambahan
using { CBO_POREQUEST as cbo } from './external/cbo-porequest';

service POService {
    entity PORequests as projection on cbo.ZZ1_POREQUEST;
    action postToSAP(requestNo: String) returns String;
}
```

```javascript
// srv/po-service.js
// Forward CRUD ke CBO, tambah business logic di CAP
module.exports = cds.service.impl(async function() {
    const cbo = await cds.connect.to('CBO_POREQUEST');

    // Forward semua CRUD ke CBO
    this.on('READ', 'PORequests', req => cbo.run(req.query));
    this.on('CREATE', 'PORequests', async req => {
        // Validasi di CAP
        if (!req.data.Supplier) req.reject(400, 'Supplier wajib diisi');
        // Forward ke CBO
        return cbo.run(req.query);
    });
});
```

**Kelebihan CBO Remote Entity:**
- **$0 biaya database** — data disimpan di HANA S/4HANA yang sudah ada
- Tidak perlu HANA Cloud instance terpisah
- Data tetap di SAP → compliance & audit lebih mudah
- CBO sudah include OData API, authorization, dan basic UI
- Clean Core compliant (CBO = in-app extensibility resmi SAP)

**Kekurangan CBO Remote Entity:**
- CBO field terbatas (~200 fields, type sederhana)
- Tidak bisa Composition (header-item harus 2 CBO terpisah)
- Performance tergantung koneksi BTP↔S/4HANA (latency)
- CBO hanya tersedia di SAP S/4HANA Cloud & newer on-premise
- Fiori Elements annotations harus di-maintain di CAP (bukan auto dari CBO)
- Complex query (JOIN, aggregation) terbatas

### 2.6 Cost Analysis — Perbandingan Biaya Database

```
COST COMPARISON (Monthly Estimate):
═══════════════════════════════════════════════════════════════════════

┌──────────────────────┬────────────┬─────────────┬──────────────────┐
│ Opsi                 │ Biaya DB   │ Biaya BTP   │ Total / bulan    │
├──────────────────────┼────────────┼─────────────┼──────────────────┤
│ HANA Cloud           │            │             │                  │
│  • hana-free (Trial) │ $0         │ $0          │ $0 (90 hari)     │
│  • hana-free (BTPEA) │ $0         │ BTPEA fee   │ BTPEA fee only   │
│  • hana (paid 24/7)  │ ~€693/bln  │ ~€100/bln   │ ~€793/bln        │
│  • hana (40 jam/bln) │ ~€130/bln  │ ~€100/bln   │ ~€230/bln        │
├──────────────────────┼────────────┼─────────────┼──────────────────┤
│ PostgreSQL           │            │             │                  │
│  • Hyperscaler (BTP) │ ~$30-50    │ ~€100/bln   │ ~€130-150/bln    │
│  • Self-hosted       │ ~$15-30    │ ~€100/bln   │ ~€115-130/bln    │
├──────────────────────┼────────────┼─────────────┼──────────────────┤
│ CBO Remote Entity    │            │             │                  │
│  • Sudah ada SAP     │ $0         │ ~€100/bln   │ ~€100/bln        │
│  • (no extra DB)     │            │ (CF Runtime)│ (cheapest prod)  │
└──────────────────────┴────────────┴─────────────┴──────────────────┘

Catatan biaya:
• BTP ~€100/bln = CF Runtime (€50) + Destination (€20) + XSUAA (€20) + HTML5 Repo (€10)
• hana-free auto-stop setelah 60 menit idle → tidak cocok production
• hana-free di Trial = gratis 90 hari, di Free Tier (BTPEA) = gratis tanpa batas waktu
• HANA paid pricing berdasarkan Capacity Unit (CU), min 2 CU = ~€693/bulan 24/7
• Untuk workshop saja, HANA bisa di-stop saat tidak dipakai → ~€130/bln (est. 40 jam)
```

**Detail: hana-free vs hana (paid)**

| Aspek | hana-free | hana (paid) |
|-------|-----------|-------------|
| **Biaya** | $0 | ~€693/bulan (min 2 CU) |
| **Auto-stop** | Ya, 60 menit idle | Tidak (selalu on) |
| **Availability** | Trial + Free Tier (BTPEA) | Semua account |
| **Storage** | 32 GB | Scalable (64 GB+) |
| **Replicas** | 0 | Configurable |
| **SLA** | Tidak ada | 99.5%+ |
| **Use case** | Dev, workshop, PoC | Production |

### 2.7 Decision Matrix — Kapan Pakai Apa?

```
DECISION MATRIX:
═══════════════════════════════════════════════════════════

Pertanyaan:                          Rekomendasi:
─────────────────────────────────────────────────────────
Workshop / Training?                 → hana-free (BTP Trial)
  └── Gratis, cukup untuk demo

PoC / Proof of Concept?              → hana-free (BTPEA Free Tier)
  └── Gratis tanpa batas waktu, tapi auto-stop

Production, budget besar?            → HANA Cloud (paid)
  └── Full SAP support, HDI, Calculation Views

Production, budget terbatas?         → PostgreSQL (Hyperscaler)
  └── ~$30-50/bln, familiar, mature driver

Data HARUS tetap di SAP?             → CBO Remote Entity
  └── Compliance, audit, no external DB

Sudah punya SAP S/4HANA Cloud?       → CBO Remote Entity
  └── CBO sudah included, $0 extra DB

Developer team non-SAP?              → PostgreSQL
  └── Familiar tech, banyak tooling

Enterprise-grade analytics?          → HANA Cloud (paid)
  └── Calculation Views, predictive, graph
```

```
VISUAL: CAP sebagai Common Logic Layer
═══════════════════════════════════════════════════════════

Semua opsi menggunakan CAP sebagai layer tengah yang SAMA:

                    ┌──────────────────┐
                    │    Fiori UI       │
                    │   (sama persis)   │
                    └────────┬─────────┘
                             │
                    ┌────────▼─────────┐
                    │   CAP Service     │
                    │  (business logic  │
                    │   SAMA untuk      │
                    │   semua opsi)     │
                    └────────┬─────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
    ┌─────────▼──────┐ ┌────▼────────┐ ┌──▼──────────────┐
    │  HANA Cloud    │ │ PostgreSQL  │ │ CBO Remote      │
    │  HDI Container │ │ Hyperscaler │ │ Entity → SAP    │
    │  (full SAP)    │ │ (budget)    │ │ (data di SAP)   │
    └────────────────┘ └─────────────┘ └─────────────────┘

    package.json:       package.json:     package.json:
    impl: @cap-js/hana  impl: @cap-js/    requires:
    kind: hana                postgres      CBO_POREQUEST:
                         kind: postgres     kind: odata
                                            url: https://sap...
```

> **💡 Insight Workshop:** Untuk workshop ini kita menggunakan **HANA Cloud (hana-free)**
> karena mendemonstrasikan full SAP native stack. Namun dalam production, pilihan database
> harus disesuaikan dengan budget, compliance requirement, dan skill tim development.

---

## 🔨 PART 3: Step-by-Step Development Strategy

### Overview: 7 Phase Approach

```
╔════════════════════════════════════════════════════════════════════╗
║  DEVELOPMENT LIFECYCLE — Side-by-Side Extension                   ║
╠════════════════════════════════════════════════════════════════════╣
║                                                                    ║
║  Phase 1: DESIGN                                                   ║
║  ├── Identifikasi use case (PO Request → Post ke SAP)              ║
║  ├── Mapping Z-table → CDS Entity                                  ║
║  └── Tentukan integrasi point ke S/4HANA                           ║
║                                                                    ║
║  Phase 2: DATA MODEL (db/)                                         ║
║  ├── Buat CDS entities (po-schema.cds)                             ║
║  ├── Definisi types, enums, compositions                           ║
║  ├── Siapkan CSV test data                                         ║
║  └── Test: cds watch → SQLite in-memory                            ║
║                                                                    ║
║  Phase 3: SERVICE LAYER (srv/)                                     ║
║  ├── Buat service definition (po-service.cds)                      ║
║  ├── Implementasi event handlers (po-service.js)                   ║
║  ├── Business logic: validation, auto-calc, status                 ║
║  └── Test: REST Client / curl → CRUD + Actions                     ║
║                                                                    ║
║  Phase 4: SAP INTEGRATION (srv/lib/)                               ║
║  ├── Build SAP OData V2 client (sap-client.js)                     ║
║  ├── CSRF token + Basic Auth                                       ║
║  ├── Draft-based PO creation (5-step flow)                         ║
║  └── Test: postToSAP action → real PO number                      ║
║                                                                    ║
║  Phase 5: FIORI UI (app/)                                          ║
║  ├── Fiori annotations (annotations.cds)                           ║
║  ├── App descriptor (manifest.json + Component.js)                 ║
║  ├── List Report → Object Page routing                             ║
║  └── Test: Browser → Fiori Elements UI                             ║
║                                                                    ║
║  Phase 6: HANA CLOUD DATABASE                                      ║
║  ├── Setup HANA Cloud di BTP                                       ║
║  ├── Add @sap/cds-hana dependency                                  ║
║  ├── Configure [hybrid] profile                                    ║
║  ├── cds deploy --to hana → HDI Container                          ║
║  └── Test: cds watch --profile hybrid                              ║
║                                                                    ║
║  Phase 7: PRODUCTION DEPLOYMENT                                    ║
║  ├── Buat mta.yaml (Multi-Target Application)                      ║
║  ├── XSUAA security configuration                                  ║
║  ├── cds build --production                                        ║
║  ├── cf deploy *.mtar                                              ║
║  └── Test: Production URL → End-to-end                             ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
```

---

### Phase 1: DESIGN — Analisis & Mapping

**Proses:**
1. Identifikasi business process yang butuh custom data
2. Mapping field dari Z-table ABAP ke CDS Entity
3. Tentukan mana data yang disimpan di BTP, mana yang tetap di S/4HANA

```
MAPPING TABEL ABAP → CDS ENTITY:
═══════════════════════════════════════════════════════════

Z-table ABAP (SE11)          →  CDS Entity (CAP)
────────────────────────────────────────────────────
ZPO_REQ_HEADER               →  PORequests : cuid, managed
  MANDT                       →  (di-handle oleh HANA Cloud)
  ZREQ_ID    CHAR 10          →  requestNo : String(10)
  ZBUKRS     CHAR 4           →  companyCode : String(4)
  ZEKORG     CHAR 4           →  purchasingOrg : String(4)
  ZEKGRP     CHAR 3           →  purchasingGroup : String(3)
  ZLIFNR     CHAR 10          →  supplier : String(10)
  ZLIFNR_TXT CHAR 80          →  supplierName : String(80)
  ZDESC      CHAR 200         →  description : String(200)
  ZDAT_ORD   DATS             →  orderDate : Date
  ZDAT_DEL   DATS             →  deliveryDate : Date
  ZWAERS     CUKY 3           →  currency : String(3)
  ZNETWR     CURR(15,2)       →  totalAmount : Decimal(15,2)
  ZSTATUS    CHAR 1           →  status : String(1)
  ZSAP_PO    CHAR 10          →  sapPONumber : String(10)
  ZSAP_DATE  TIMS             →  sapPostDate : DateTime
  ZSAP_MSG   CHAR 500         →  sapPostMessage : String(500)
  ZERDAT     DATS             →  (managed → createdAt)
  ZERNAM     CHAR 12          →  (managed → createdBy)
  ZAEDAT     DATS             →  (managed → modifiedAt)
  ZAENAM     CHAR 12          →  (managed → modifiedBy)

ZPO_REQ_ITEM                  →  PORequestItems : cuid
  MANDT                       →  (di-handle oleh HANA Cloud)
  ZREQ_ID    CHAR 10          →  parent : Association to PORequests
  ZPOSNR     NUMC 5           →  itemNo : Integer
  ZMATNR     CHAR 40          →  materialNo : String(40)
  ZTXZ01     CHAR 200         →  description : String(200)
  ZMENGE     QUAN(13,3)       →  quantity : Decimal(13,3)
  ZMEINS     UNIT 3           →  uom : String(3)
  ZNETPR     CURR(15,2)       →  unitPrice : Decimal(15,2)
  ZNETWR     CURR(15,2)       →  netAmount : Decimal(15,2) @readonly
  ZWERKS     CHAR 4           →  plant : String(4)
  ZMATKL     CHAR 9           →  materialGroup : String(9)
```

**Decision: Apa yang disimpan di mana?**

```
Data yang DISIMPAN DI BTP (HANA Cloud):      Data yang TETAP DI S/4HANA:
─────────────────────────────────────         ──────────────────────────────
✅ PO Request Header (draft staging)          • Supplier Master (LFA1)
✅ PO Request Items (draft staging)           • Material Master (MARA/MARC)
✅ Status & Audit Trail                       • PO Document Final (EKKO/EKPO)
✅ SAP Response (PO number, message)          • Company Code (T001)
✅ Notes & User Data                          • Accounting Documents
                                               • Pricing Conditions
```

---

### Phase 2: DATA MODEL — CDS Entities

**File:** `db/po-schema.cds`

```cds
namespace com.tecrise.procurement;

using { managed, cuid } from '@sap/cds/common';

// Z-TABLE REPLACEMENT: PO Request Header
entity PORequests : cuid, managed {
    requestNo        : String(10)    @readonly;
    description      : String(200);
    companyCode      : String(4)     default '1710';
    purchasingOrg    : String(4)     default '1710';
    purchasingGroup  : String(3)     default '001';
    supplier         : String(10);
    supplierName     : String(80);
    orderDate        : Date;
    deliveryDate     : Date;
    currency         : String(3)     default 'USD';
    totalAmount      : Decimal(15,2) @readonly default 0;
    status           : String(1)     default 'D';
    sapPONumber      : String(10)    @readonly;
    sapPostDate      : DateTime      @readonly;
    sapPostMessage   : String(500)   @readonly;
    items            : Composition of many PORequestItems on items.parent = $self;
}

// Z-TABLE REPLACEMENT: PO Request Item
entity PORequestItems : cuid {
    parent           : Association to PORequests;
    itemNo           : Integer;
    materialNo       : String(40);
    description      : String(200);
    quantity         : Decimal(13,3);
    uom              : String(3)     default 'PC';
    unitPrice        : Decimal(15,2);
    netAmount        : Decimal(15,2) @readonly;
    currency         : String(3)     default 'USD';
    plant            : String(4)     default '1710';
    materialGroup    : String(9)     default 'L001';
}
```

**Test Phase 2:**
```bash
cd po-project
cds watch
# → "loaded model from 4 file(s)"
# → "init from CSV" 
# → http://localhost:4004/po/PORequests
```

---

### Phase 3: SERVICE LAYER — OData + Business Logic

**File:** `srv/po-service.cds` + `srv/po-service.js`

```
Service Layer Architecture:
═══════════════════════════════════════════

HTTP Request
    │
    ▼
┌─────────────────────────────────────┐
│  CDS Service (po-service.cds)       │
│  ├── Entity projections             │
│  ├── Bound actions (postToSAP)      │
│  └── Functions (getSAPSuppliers)    │
├─────────────────────────────────────┤
│  Event Handlers (po-service.js)     │
│  ├── BEFORE CREATE → validate       │
│  ├── BEFORE CREATE ITEM → calc      │
│  ├── AFTER CRUD ITEM → recalc total │
│  ├── AFTER READ → statusCriticality │
│  ├── BEFORE UPDATE → block posted   │
│  ├── ON postToSAP → SAP client      │
│  └── ON getSAPSuppliers → SAP read  │
├─────────────────────────────────────┤
│  SAP Client (srv/lib/sap-client.js) │
│  ├── CSRF Token management          │
│  ├── Draft → Prepare → Activate     │
│  └── Basic Auth + TLS               │
└─────────────────────────────────────┘
    │
    ▼
Database (SQLite dev / HANA prod)
```

**Business Rules yang diimplementasikan:**

| Rule | Implementasi | Kapan Trigger |
|------|-------------|---------------|
| Auto-generate Request No | `REQ-YYXXXX` format, sequential | BEFORE CREATE PORequests |
| Auto-calculate Net Amount | `netAmount = quantity × unitPrice` | BEFORE CREATE PORequestItems |
| Auto-recalculate Total | Sum of all items netAmount | AFTER CREATE/UPDATE/DELETE Items |
| Date Validation | `deliveryDate > orderDate` | BEFORE CREATE PORequests |
| Block Posted PO | Cannot edit after status = 'P' | BEFORE UPDATE PORequests |
| Status Criticality | D→orange(2), P→green(3), E→red(1) | AFTER READ PORequests |
| Post to SAP | 5-step draft flow via OData V2 | ON postToSAP action |

---

### Phase 4: SAP S/4HANA INTEGRATION

**Flow Detail: Draft-Based PO Creation**

```
POST to SAP — 5 Step Flow via MM_PUR_PO_MAINT_V2_SRV:
═══════════════════════════════════════════════════════════

Step 1: CSRF Token
  GET /MM_PUR_PO_MAINT_V2_SRV/?sap-client=777
  Header: X-CSRF-Token: Fetch
  Response: x-csrf-token + Set-Cookie → simpan untuk session

Step 2: Create Draft Header
  POST /MM_PUR_PO_MAINT_V2_SRV/C_PurchaseOrderTP
  Body: { PurchaseOrderType: 'NB', CompanyCode: '1710', Supplier: '17300001', ... }
  Response: { PurchaseOrder: '', DraftUUID: 'guid-xxx', IsActiveEntity: false }
  
Step 3: Add Items to Draft (per item)
  POST .../C_PurchaseOrderTP(PurchaseOrder='',DraftUUID=guid'xxx',IsActiveEntity=false)
       /to_PurchaseOrderItemTP
  Body: { Material: 'EWMS4-01', OrderQuantity: '10', NetPriceAmount: '302', ... }
  Response: Item created in draft

Step 4: Prepare (Validate)
  POST /MM_PUR_PO_MAINT_V2_SRV/C_PurchaseOrderTPPreparation
       ?PurchaseOrder=''&DraftUUID=guid'xxx'&IsActiveEntity=false
  Response: Validation passed (or error details)

Step 5: Activate (Save → Get PO Number)
  POST /MM_PUR_PO_MAINT_V2_SRV/C_PurchaseOrderTPActivation
       ?PurchaseOrder=''&DraftUUID=guid'xxx'&IsActiveEntity=false
  Response: { PurchaseOrder: '4500000016', IsActiveEntity: true }
  
Result: PO 4500000016 dibuat di SAP S/4HANA! ✅
```

**Bukti Real (Tested):**
```
REQ-260001 → PO 4500000018 ✅ (Supplier: Wahyu Amaldi, 1 item)
REQ-260002 → PO 4500000017 ✅ (Supplier: Domestic US 2, 2 items)
```

---

### Phase 5: FIORI UI — Declarative Annotations

**File:** `app/po/annotations.cds`

```
Fiori Elements Architecture (NO XML coding!):
═══════════════════════════════════════════

CDS Annotations              →  Fiori Elements Runtime
─────────────────────────────────────────────────
@UI.LineItem                 →  List Report table columns
@UI.SelectionFields          →  Filter bar
@UI.HeaderInfo               →  Object Page title
@UI.Facets                   →  Object Page sections
@UI.FieldGroup               →  Group of fields
@UI.DataPoint                →  KPI in header
@UI.Identification           →  Action buttons
@Common.ValueList            →  Dropdown/F4 help
Criticality                  →  Color coding (green/orange/red)
DataFieldForAction           →  "Post to SAP" button
```

---

### Phase 6: HANA CLOUD DATABASE

#### 6.1 Setup HANA Cloud di BTP Trial

```bash
# Prasyarat: BTP Trial account sudah ada
# Region: ap21 (Singapore-Azure)

# Step 1: Buka SAP BTP Cockpit
# → Subaccount → Cloud Foundry → Spaces → dev

# Step 2: Di BTP Cockpit → Service Marketplace
# → Cari "SAP HANA Cloud"
# → Create Instance (hdi-shared plan)
# → Nama: po-project-db

# Step 3: Atau via CF CLI
cf login -a https://api.cf.ap21.hana.ondemand.com
cf create-service hana hdi-shared po-project-db
```

#### 6.2 Tambah HANA Support ke Project

```bash
cd po-project

# Install HANA Cloud driver (CDS v9+)
npm add @cap-js/hana

# Install build tools (optional, sudah ada di global @sap/cds-dk)
npm add -D @sap/cds-dk
```

#### 6.3 Configure package.json

```json
{
  "cds": {
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
          "credentials": { "url": ":memory:" }
        }
      }
    },
    "[hybrid]": {
      "requires": {
        "db": {
          "kind": "hana",
          "deploy-format": "hdbtable"
        }
      }
    },
    "[production]": {
      "requires": {
        "db": {
          "kind": "hana",
          "deploy-format": "hdbtable"
        }
      }
    }
  }
}
```

#### 6.4 Deploy Schema ke HANA Cloud

```bash
# Build HANA artifacts
cds build --production

# Hasilnya:
# gen/db/
# ├── src/gen/
# │   ├── com.tecrise.procurement-PORequests.hdbtable
# │   ├── com.tecrise.procurement-PORequestItems.hdbtable
# │   └── ...
# ├── src/gen/data/
# │   ├── com.tecrise.procurement-PORequests.csv
# │   └── com.tecrise.procurement-PORequestItems.csv
# └── package.json

# Deploy ke HDI Container
cds deploy --to hana

# Atau bind & run lokal (hybrid)
cds bind -2 po-project-db
cds watch --profile hybrid
```

#### 6.5 Apa yang Terjadi di HANA Cloud

Hasil `cds build --production` menghasilkan file `.hdbtable` yang saat deploy ke
HDI Container akan membuat tabel HANA secara otomatis:

```sql
-- File: gen/db/src/gen/com.tecrise.procurement.PORequests.hdbtable
-- Dihasilkan otomatis dari db/po-schema.cds

COLUMN TABLE com_tecrise_procurement_PORequests (
    ID                 NVARCHAR(36) NOT NULL,
    createdAt          TIMESTAMP,
    createdBy          NVARCHAR(255),
    modifiedAt         TIMESTAMP,
    modifiedBy         NVARCHAR(255),
    requestNo          NVARCHAR(10),
    description        NVARCHAR(200),
    companyCode        NVARCHAR(4) DEFAULT '1710',
    purchasingOrg      NVARCHAR(4) DEFAULT '1710',
    purchasingGroup    NVARCHAR(3) DEFAULT '001',
    supplier           NVARCHAR(10),
    supplierName       NVARCHAR(80),
    orderDate          DATE,
    deliveryDate       DATE,
    currency           NVARCHAR(3) DEFAULT 'USD',
    totalAmount        DECIMAL(15,2) DEFAULT 0,
    notes              NVARCHAR(1000),
    status             NVARCHAR(1) DEFAULT 'D',
    statusCriticality  INTEGER DEFAULT 0,
    sapPONumber        NVARCHAR(10),
    sapPostDate        SECONDDATE,
    sapPostMessage     NVARCHAR(500),
    PRIMARY KEY(ID)
);

-- CSV data otomatis di-INSERT saat deploy via .hdbtabledata:
-- File: gen/db/src/gen/data/com.tecrise.procurement-PORequests.hdbtabledata
-- Referensi: gen/db/src/gen/data/com.tecrise.procurement-PORequests.csv
```

---

### Phase 7: PRODUCTION DEPLOYMENT

#### 7.1 MTA Descriptor (mta.yaml)

```yaml
_schema-version: '3.1'
ID: po-project
version: 1.0.0
description: PO Request Side-by-Side Extension

parameters:
  enable-parallel-deployments: true

build-parameters:
  before-all:
    - builder: custom
      commands:
        - npx cds build --production

modules:
  # --- Server Module (Node.js CAP) ---
  - name: po-project-srv
    type: nodejs
    path: gen/srv
    parameters:
      buildpack: nodejs_buildpack
    requires:
      - name: po-project-db
      - name: po-project-auth
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  # --- DB Deployer (HANA artifacts) ---
  - name: po-project-db-deployer
    type: hdb
    path: gen/db
    parameters:
      buildpack: nodejs_buildpack
    requires:
      - name: po-project-db

  # --- App Router (Fiori hosting) ---
  - name: po-project-app
    type: approuter.nodejs
    path: app/router
    requires:
      - name: srv-api
        group: destinations
        properties:
          name: srv-api
          url: ~{srv-url}
          forwardAuthToken: true
      - name: po-project-auth

resources:
  # --- HANA Cloud HDI Container ---
  - name: po-project-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # --- XSUAA (Authentication) ---
  - name: po-project-auth
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
```

#### 7.2 Build & Deploy

```bash
# Step 1: Build
mbt build

# Step 2: Deploy ke Cloud Foundry
cf deploy mta_archives/po-project_1.0.0.mtar

# Step 3: Verify
cf apps
# NAME                    STATE    INSTANCES
# po-project-srv          started  1/1
# po-project-db-deployer  stopped  0/1 (one-time deployer)
# po-project-app          started  1/1

cf services
# NAME               SERVICE  PLAN        STATE
# po-project-db      hana     hdi-shared  created
# po-project-auth    xsuaa    application created
```

---

## 📊 PART 4: Development Workflow Diagram

```
DEVELOPER WORKFLOWS:
═══════════════════════════════════════════════════════════

1. DAILY DEVELOPMENT (lokal):
   ───────────────────────────────────
   cds watch                    ← SQLite in-memory (instant)
   ├── Edit .cds files          ← Auto-reload
   ├── Edit .js handlers        ← Auto-reload
   ├── Add CSV data             ← Auto-reload
   └── Browser test             ← http://localhost:4004

2. INTEGRATION TESTING (hybrid):
   ───────────────────────────────────
   cds watch --profile hybrid   ← HANA Cloud + local Node.js
   ├── Data persisted di HANA
   ├── Test HANA-specific features
   └── Test SAP integration

3. PRODUCTION DEPLOY:
   ───────────────────────────────────
   mbt build                    ← Build MTA archive
   cf deploy *.mtar             ← Deploy ke Cloud Foundry
   ├── HDI Container dibuat
   ├── Tables di-deploy
   ├── CSV data di-load
   ├── Node.js server started
   └── App Router configured

4. CI/CD (optional, advanced):
   ───────────────────────────────────
   git push → GitHub Actions / SAP CICD
   ├── npm test
   ├── mbt build
   ├── cf deploy
   └── Automated E2E test
```

---

## 📋 PART 5: File Structure — Complete Project

```
po-project/
├── .env                          ← SAP credentials (GITIGNORED!)
├── .gitignore                    ← Exclude node_modules, .env, *.sqlite
├── package.json                  ← Dependencies, CDS config, profiles
├── mta.yaml                      ← MTA descriptor (production deploy)
├── xs-security.json              ← XSUAA config (roles & scopes)
│
├── db/                           ← DATA LAYER (Phase 2)
│   ├── po-schema.cds             ← Entity definitions (Z-table replacement)
│   └── data/
│       ├── ...PORequests.csv     ← Seed data: 3 PO Requests
│       └── ...PORequestItems.csv ← Seed data: 4 line items
│
├── srv/                          ← SERVICE LAYER (Phase 3-4)
│   ├── po-service.cds            ← Service definition + actions
│   ├── po-service.js             ← Event handlers + business logic
│   └── lib/
│       └── sap-client.js         ← SAP OData V2 client (S/4HANA)
│
├── app/                          ← PRESENTATION LAYER (Phase 5)
│   └── po/
│       ├── annotations.cds       ← Fiori UI annotations
│       └── webapp/
│           ├── manifest.json     ← App descriptor
│           ├── Component.js      ← UI5 component
│           └── index.html        ← Bootstrap page
│
├── gen/                          ← BUILD OUTPUT (auto-generated)
│   ├── db/                       ← HANA artifacts (.hdbtable, .hdbview)
│   └── srv/                      ← Node.js bundle + static files
│
└── tests/
    └── po-tests.http             ← REST Client test file
```

---

## 🎯 PART 6: Ringkasan — Kenapa Semua Ini?

```
MINDSET SHIFT:
═══════════════════════════════════════════

ABAP Developer mindset:
  SE11 → SE38 → SE80 → STMS → Production
  "Semua di 1 server, semua di ABAP"

BTP Developer mindset:
  CDS Model → OData Service → Fiori UI → Deploy ke Cloud
  "Pisahkan concerns, leverage platform services"

═══════════════════════════════════════════

Yang BERUBAH:
┌──────────────────────┬──────────────────────┐
│ ABAP Way             │ BTP Way              │
├──────────────────────┼──────────────────────┤
│ SE11 (Z-table)       │ db/schema.cds        │
│ SE38 (Z-program)     │ srv/service.js       │
│ SE80 (Z-transaction) │ app/annotations.cds  │
│ SE16 (test data)     │ db/data/*.csv         │
│ ST05 (SQL trace)     │ cds watch (console)  │
│ STMS (transport)     │ cf deploy (MTA)      │
│ SU01 (user)          │ XSUAA + Destination  │
│ SM30 (maintain)      │ Fiori Elements CRUD  │
│ HANA DB (same box)   │ HANA Cloud (HDI)     │
└──────────────────────┴──────────────────────┘

Yang TIDAK BERUBAH:
• Business logic tetap sama (validasi, kalkulasi, status)
• Data structure tetap mirip (header → items → master data)
• User flow tetap sama (create → edit → post → approve)
• Integration tetap via OData/RFC/SOAP
```

---

## ✅ Checklist — Apakah Project Anda Siap Production?

- [x] CDS data model berjalan di `cds watch` (SQLite)
- [x] OData V4 service menghasilkan response yang benar
- [x] Business logic ter-test (auto-number, validation, calculation)
- [x] SAP integration proven (PO 4500000016-4500000018 created)
- [x] Fiori UI menampilkan data dengan benar
- [x] Credentials di `.env` (tidak di source code)
- [x] `.gitignore` mengamankan `.env` dan `node_modules`
- [ ] HANA Cloud instance dibuat di BTP
- [ ] `cds deploy --to hana` berhasil
- [ ] `cds watch --profile hybrid` berjalan
- [ ] `mta.yaml` dikonfigurasi
- [ ] `xs-security.json` dengan roles
- [ ] `mbt build` → `cf deploy` berhasil
- [ ] End-to-end test di production URL
