# Hands-on Hari 3: Clean Core Extensibility — End-to-End PO System

> **Project A:** `Day3-Extensibility/po-project/` — Side-by-Side (BTP + HANA Cloud)  
> **Project B:** `Day3-Extensibility/po-project-in-apps/` — In-App (CBO di SAP S/4HANA)  
> **Project C:** `Day3-Extensibility/po-project-steampunk/` — Embedded Steampunk (RAP di ADT)  
> **System:** SAP S/4HANA 2023 `sap.ilmuprogram.com` (Client 777, Company 1710 — Andi Coffee)

---

## Overview

Tiga pendekatan **Clean Core Extensibility** untuk sistem PO Request yang sama:

- **Hands-on 1–3 (Side-by-Side):** Z-table staging di HANA Cloud → Fiori Elements UI → Post ke SAP
- **Hands-on 4–5 (In-App CBO):** Data langsung di SAP CBO → CAP sebagai proxy → Post ke SAP
- **Hands-on 6 (Embedded Steampunk):** RAP + ABAP Cloud di S/4HANA → Fiori Preview → Post ke SAP

## Daftar Hands-on

### Part A: Side-by-Side Extension (po-project)

| # | Hands-on | Durasi | Output |
|:--|:---------|:-------|:-------|
| 1 | [Project Setup & CDS Data Model](./handson-1-extend-cds-model.md) | ~30 min | CAP project + CDS schema + sample data + `cds watch` berjalan |
| 2 | [OData Service & SAP Integration](./handson-2-custom-handlers.md) | ~45 min | Service CDS + handlers + SAP client + koneksi SAP verified |
| 3 | [Fiori UI, HANA Cloud & Post to SAP](./handson-3-odata-testing.md) | ~45 min | Fiori app + HANA deploy + PO berhasil dipost ke SAP |

### Part B: In-App Extensibility (po-project-in-apps)

| # | Hands-on | Durasi | Output |
|:--|:---------|:-------|:-------|
| 4 | [Custom Business Object (CBO)](./handson-4-cbo-in-app.md) | ~60 min | CBO Header + Items di SAP, OData registered, CRUD verified |
| 5 | [CAP Project dengan CBO Backend](./handson-5-cap-cbo-project.md) | ~60 min | CAP proxy → CBO, Fiori UI identik, postToSAP working |

### Part C: Embedded Steampunk (RAP di ADT)

| # | Hands-on | Durasi | Output |
|:--|:---------|:-------|:-------|
| 6 | [RAP PO Request — ABAP Cloud](./handson-6-rap-steampunk.md) | ~90 min | 13 ABAP objects: tables, CDS views, behavior, service binding, Fiori preview |

## System Integration Testing

Setelah selesai semua hands-on, jalankan SIT untuk verifikasi end-to-end:

→ **[po-project-sit/](../po-project-sit/README.md)** — 37 test cases (API + HANA + SAP + Fiori UI)

---

## Prerequisite

- Node.js ≥ 18
- `npm i -g @sap/cds-dk` (CDS CLI)
- VS Code + SAP CDS Language Support extension
- SAP BTP Trial account (untuk HANA Cloud)
- CF CLI (`cf login`) — untuk hybrid mode & HANA deploy
- ADT (Eclipse + ABAP Development Tools) — untuk Hands-on 6
- Akses ke SAP S/4HANA system (credentials di `.env`)

## Quick Start (Jika Sudah Ada Project)

```bash
cd Day3-Extensibility/po-project
npm install

# Mode 1: SQLite lokal (cepat, data hilang saat restart)
cds watch

# Mode 2: HANA Cloud (data persisten)
cds watch --profile hybrid

# Fiori UI
# http://localhost:4004/po/webapp/index.html

# Post PO ke SAP
curl -s -X POST \
  "http://localhost:4004/po/PORequests(ID)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" -d '{}'
```

## Architecture

### Part A: Side-by-Side (po-project)

```
┌────────────────────────────────────────────────────────┐
│                BTP (Side-by-Side Extension)             │
│                                                        │
│  Fiori Elements ──▶ CAP Node.js ──▶ HANA Cloud        │
│  (List Report +     (OData V4)      (HDI Container)    │
│   Object Page)           │                             │
│                          │ postToSAP()                 │
│                          ▼                             │
│                   SAP OData V2 Client                  │
└──────────────────────────┼─────────────────────────────┘
                           │ HTTPS
                           ▼
┌────────────────────────────────────────────────────────┐
│           SAP S/4HANA (sap.ilmuprogram.com)            │
│  MM_PUR_PO_MAINT_V2_SRV — Draft-based PO Creation     │
│  Result: PO 4500000016, 4500000017, 4500000018        │
└────────────────────────────────────────────────────────┘
```

### Part B: In-App CBO (po-project-in-apps)

```
┌────────────────────────────────────────────────────────┐
│                CAP (Proxy Layer — No Local DB)          │
│                                                        │
│  Fiori Elements ──▶ CAP Node.js ──▶ CBO OData V2      │
│  (List Report +     (OData V4)      (ZZ1_WPOREQ_CDS   │
│   Object Page)           │           ZZ1_WPOREQI_CDS)  │
│                          │ postToSAP()                 │
│                          ▼                             │
│                   SAP OData V2 Client                  │
└──────────────────────────┼─────────────────────────────┘
                           │ HTTPS (CBO + PO Create)
                           ▼
┌────────────────────────────────────────────────────────┐
│           SAP S/4HANA (sap.ilmuprogram.com)            │
│  CBO: ZZ1_WPOREQ + ZZ1_WPOREQI (data storage)        │
│  MM_PUR_PO_MAINT_V2_SRV — Draft-based PO Creation     │
└────────────────────────────────────────────────────────┘
```

### Part C: Embedded Steampunk (RAP di ADT)

```
┌────────────────────────────────────────────────────────┐
│           SAP S/4HANA (sap.ilmuprogram.com)            │
│           ABAP Language: cloudDevelopment               │
│                                                        │
│  Fiori Preview ──▶ OData V4 (RAP) ──▶ HANA (embedded) │
│  (Service Binding)  ZUI_TEC_POREQ_BND                 │
│                          │                             │
│  Tables: ZTEC_POREQ + ZTEC_POREQI                     │
│  CDS: ZR_/ZC_TEC_POREQ + ZR_/ZC_TEC_POREQI           │
│  Behavior: Managed CRUD + Draft + postToSAP action     │
│                          │                             │
│                          │ postToSAP()                 │
│                          ▼                             │
│  MM_PUR_PO_MAINT_V2_SRV / BAPI_PO_CREATE1             │
│  (semua di dalam ABAP stack yang sama)                 │
└────────────────────────────────────────────────────────┘

  ★ Tidak butuh BTP, Node.js, atau koneksi external
  ★ 13 ABAP objects, 0 lines of JavaScript
```

### Comparison

| Aspek | po-project (Part A) | po-project-in-apps (Part B) | RAP Steampunk (Part C) |
|:------|:--------------------|:----------------------------|:-----------------------|
| IDE | VS Code | VS Code | ADT (Eclipse) |
| Bahasa | Node.js + CDS | Node.js + CDS | ABAP Cloud |
| Database | HANA Cloud / SQLite | SAP CBO ($0 cost) | HANA embedded ($0) |
| Dependencies | @sap/cds + @cap-js/hana + sqlite | @sap/cds + dotenv saja | Tidak ada (native) |
| Persistence | `cuid + managed` | `@cds.persistence.skip` | RAP managed + draft |
| CRUD Handler | BEFORE/AFTER hooks | Custom ON handlers | Determinations/Validations |
| Extra File | — | `cbo-client.js` (field mapping) | — |
| OData | V4 (CAP auto) | V4 → V2 proxy | V4 (RAP auto) |
| BTP Required | Ya | Ya | Tidak |
| SAP PO Create | ✅ Identik | ✅ Identik | ✅ Identik |
| Fiori UI | ✅ Identik | ✅ Identik | ✅ Identik |

## File Structure

### po-project/ (Part A — Side-by-Side)

```
po-project/
├── package.json              ← 3 DB profiles (dev/hybrid/prod)
├── .env                      ← SAP credentials (gitignored)
├── .cdsrc-private.json       ← HANA binding (auto-generated)
├── db/
│   ├── po-schema.cds         ← Z-table: PORequests + PORequestItems
│   └── data/                 ← CSV seed data (3 headers, 4 items)
├── srv/
│   ├── po-service.cds        ← Service + postToSAP action
│   ├── po-service.js         ← Event handlers + business logic
│   └── lib/
│       └── sap-client.js     ← SAP OData V2 client (5-step draft flow)
├── app/po/
│   ├── annotations.cds       ← Fiori Elements annotations
│   └── webapp/               ← manifest.json, Component.js, index.html
├── mta.yaml                  ← MTA descriptor (production deploy)
└── xs-security.json          ← XSUAA roles
```

### po-project-in-apps/ (Part B — In-App CBO)

```
po-project-in-apps/
├── package.json              ← Minimal: @sap/cds + dotenv
├── .env                      ← SAP credentials (sama)
├── db/
│   └── po-schema.cds         ← @cds.persistence.skip entities
├── srv/
│   ├── po-service.cds        ← Service + testCBOConnection
│   ├── po-service.js         ← ON handlers (CRUD → CBO)
│   └── lib/
│       ├── cbo-client.js     ← CBO OData V2 + field mapping ★
│       └── sap-client.js     ← SAP PO creation (identik)
├── app/po/
│   ├── annotations.cds       ← Fiori annotations (identik)
│   └── webapp/               ← manifest.json (namespace: inapp)
└── tests/
    └── po-tests.http         ← REST Client tests
```

### po-project-steampunk/ (Part C — Embedded Steampunk)

```
po-project-steampunk/
├── README.md                                ← Overview + import guide
└── src/
    ├── ztec_poreq.tabl.abapcds             ← Database table — PO Request Header
    ├── ztec_poreqi.tabl.abapcds            ← Database table — PO Request Items
    ├── zr_tec_poreq.ddls.abapcds           ← CDS Interface View (root)
    ├── zr_tec_poreqi.ddls.abapcds          ← CDS Interface View (child)
    ├── zc_tec_poreq.ddls.abapcds           ← CDS Consumption View (header)
    ├── zc_tec_poreqi.ddls.abapcds          ← CDS Consumption View (items)
    ├── zc_tec_poreq.ddlx.abapcds           ← Metadata Extension — Fiori UI header
    ├── zc_tec_poreqi.ddlx.abapcds          ← Metadata Extension — Fiori UI items
    ├── zr_tec_poreq.bdef.abapcds           ← Behavior Definition (managed + draft)
    ├── zbp_tec_poreq.clas.locals_imp.abap  ← Behavior Implementation (ABAP class)
    ├── zc_tec_poreq.bdef.abapcds           ← Projection Behavior Definition
    └── zui_tec_poreq_o4.srvd.abapcds       ← Service Definition

★ 13 ABAP objects, 0 lines of JavaScript, 0 npm packages
★ Service Binding (ZUI_TEC_POREQ_BND) dibuat via ADT wizard
★ Draft tables (ZTEC_D_POREQ, ZTEC_D_POREQI) auto-generated
```
