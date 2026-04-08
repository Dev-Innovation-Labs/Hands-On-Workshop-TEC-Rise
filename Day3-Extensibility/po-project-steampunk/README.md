# po-project-steampunk — Embedded Steampunk (RAP + ABAP Cloud)

> **Kategori Extensibility:** In-Stack / Embedded Steampunk  
> **Clean Core:** Level C (Developer) · Tier 3 (Fully Compliant ✅)  
> **IDE:** ADT (Eclipse + ABAP Development Tools) — **bukan VS Code**  
> **Runtime:** 100% di dalam SAP S/4HANA ABAP stack  
> **Dokumen panduan:** [handson-6-rap-steampunk.md](../handson/handson-6-rap-steampunk.md)

---

## Overview

Project ini adalah **reference source code** untuk Hands-on 6 (Part C: Embedded Steampunk).
Semua kode ABAP di-develop dan di-activate melalui ADT — folder ini hanya berisi source files
sebagai referensi, **bukan** project yang bisa di-run di VS Code.

Sistem PO Request yang identik dengan `po-project` (Part A) dan `po-project-in-apps` (Part B),
tetapi seluruhnya berjalan di dalam ABAP stack tanpa dependency external:

- **0 lines of JavaScript**
- **0 npm packages**
- **0 BTP services**
- **13 ABAP objects** → OData V4 + Fiori Elements + Draft

---

## ABAP Object List

| # | File | Object Name | Object Type | Langkah |
|:--|:-----|:------------|:------------|:--------|
| 1 | `ztec_poreq.tabl.abapcds` | `ZTEC_POREQ` | Database Table (header) | 1a |
| 2 | `ztec_poreqi.tabl.abapcds` | `ZTEC_POREQI` | Database Table (items) | 1b |
| 3 | `zr_tec_poreq.ddls.abapcds` | `ZR_TEC_POREQ` | CDS Interface View (root) | 2a |
| 4 | `zr_tec_poreqi.ddls.abapcds` | `ZR_TEC_POREQI` | CDS Interface View (child) | 2b |
| 5 | `zc_tec_poreq.ddls.abapcds` | `ZC_TEC_POREQ` | CDS Consumption View (header) | 3a |
| 6 | `zc_tec_poreqi.ddls.abapcds` | `ZC_TEC_POREQI` | CDS Consumption View (items) | 3b |
| 7 | `zc_tec_poreq.ddlx.abapcds` | `ZC_TEC_POREQ` | Metadata Extension (header UI) | 4a |
| 8 | `zc_tec_poreqi.ddlx.abapcds` | `ZC_TEC_POREQI` | Metadata Extension (items UI) | 4b |
| 9 | `zr_tec_poreq.bdef.abapcds` | `ZR_TEC_POREQ` | Behavior Definition (root + child) | 5 |
| 10 | `zbp_tec_poreq.clas.locals_imp.abap` | `ZBP_TEC_POREQ` | Behavior Implementation (local types) | 6 |
| 11 | `zc_tec_poreq.bdef.abapcds` | `ZC_TEC_POREQ` | Projection Behavior | 7 |
| 12 | `zui_tec_poreq_o4.srvd.abapcds` | `ZUI_TEC_POREQ_O4` | Service Definition | 8a |

> **Service Binding** `ZUI_TEC_POREQ_BND` (OData V4 UI) dibuat via ADT wizard — tidak ada source file.  
> **Draft Tables** `ZTEC_D_POREQ` dan `ZTEC_D_POREQI` di-generate otomatis oleh framework saat activation.

---

## File Structure

```
po-project-steampunk/
├── README.md                                ← File ini
└── src/
    ├── ztec_poreq.tabl.abapcds             ← Database table — PO Request Header
    ├── ztec_poreqi.tabl.abapcds            ← Database table — PO Request Items
    ├── zr_tec_poreq.ddls.abapcds           ← CDS Interface View (root entity)
    ├── zr_tec_poreqi.ddls.abapcds          ← CDS Interface View (child entity)
    ├── zc_tec_poreq.ddls.abapcds           ← CDS Consumption View (projected header)
    ├── zc_tec_poreqi.ddls.abapcds          ← CDS Consumption View (projected items)
    ├── zc_tec_poreq.ddlx.abapcds           ← Metadata Extension — Fiori annotations header
    ├── zc_tec_poreqi.ddlx.abapcds          ← Metadata Extension — Fiori annotations items
    ├── zr_tec_poreq.bdef.abapcds           ← Behavior Definition (managed + draft)
    ├── zbp_tec_poreq.clas.locals_imp.abap  ← Behavior Implementation (ABAP class)
    ├── zc_tec_poreq.bdef.abapcds           ← Projection Behavior Definition
    └── zui_tec_poreq_o4.srvd.abapcds       ← Service Definition
```

---

## RAP Architecture

```
┌────────────────────────────────────────────────────────────────┐
│           SAP S/4HANA (sap.ilmuprogram.com)                    │
│           ABAP Language Version: cloudDevelopment               │
│                                                                │
│  ┌──────────────┐    ┌──────────────────┐    ┌──────────────┐ │
│  │ Service      │    │ Consumption      │    │ Metadata     │ │
│  │ Binding      │───▶│ View (ZC_)       │───▶│ Extension    │ │
│  │ (OData V4)   │    │ + Projection BDEF│    │ (DDLX)       │ │
│  └──────────────┘    └────────┬─────────┘    └──────────────┘ │
│                               │                                │
│                      ┌────────▼─────────┐                     │
│                      │ Interface View   │                     │
│                      │ (ZR_) + BDEF     │                     │
│                      │ managed + draft  │                     │
│                      └────────┬─────────┘                     │
│                               │                                │
│                      ┌────────▼─────────┐                     │
│                      │ Database Tables  │                     │
│                      │ ZTEC_POREQ(I)   │                     │
│                      └──────────────────┘                     │
│                                                                │
│  Behavior Implementation (ZBP_TEC_POREQ):                     │
│  • setRequestNo        — auto-generate REQ-YY0001             │
│  • validateSupplier    — supplier wajib diisi                  │
│  • validateDeliveryDate — delivery > order date                │
│  • calcNetAmount       — qty × unit_price                      │
│  • calcHeaderTotal     — sum of item net amounts               │
│  • postToSAP           — custom action (→ BAPI/OData)          │
└────────────────────────────────────────────────────────────────┘
```

---

## Cara Import ke ADT

Source files ini **untuk referensi / copy-paste** ke ADT. Langkah step-by-step ada di
[handson-6-rap-steampunk.md](../handson/handson-6-rap-steampunk.md).

Secara singkat:
1. Buka ADT → **ABAP Cloud Project** → connect ke `sap.ilmuprogram.com` (client 777)
2. Buat package `ZTEC_PO_REQ` (Software Component: `HOME`, Transport: local)
3. Create setiap object sesuai urutan Langkah 1–8 di handson-6
4. Copy-paste kode dari file `src/` → ADT editor → Activate (`Ctrl+F3`)
5. Service Binding → Publish → Preview

---

## Comparison dengan Project Lain

| Aspek | po-project (Part A) | po-project-in-apps (Part B) | **po-project-steampunk (Part C)** |
|:------|:--------------------|:----------------------------|:----------------------------------|
| IDE | VS Code | VS Code | **ADT (Eclipse)** |
| Bahasa | Node.js + CDS | Node.js + CDS | **ABAP Cloud** |
| Database | HANA Cloud / SQLite | SAP CBO ($0 cost) | **HANA embedded ($0)** |
| Dependencies | @sap/cds + hana + sqlite | @sap/cds + dotenv | **Tidak ada** |
| Runtime | BTP Cloud Foundry | BTP Cloud Foundry | **SAP ABAP stack** |
| CRUD | BEFORE/AFTER hooks | Custom ON handlers | **RAP managed + draft** |
| OData | V4 (CAP auto) | V4 → V2 proxy | **V4 (RAP auto)** |
| BTP Required | Ya | Ya | **Tidak** |
| Total Objects | ~12 files | ~14 files | **13 ABAP objects** |
| SAP PO Create | ✅ via sap-client.js | ✅ via sap-client.js | ✅ **via ABAP (native)** |
| Fiori UI | ✅ List + Object Page | ✅ List + Object Page | ✅ **List + Object Page** |
