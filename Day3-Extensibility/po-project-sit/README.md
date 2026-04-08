# SIT — System Integration Testing

## PO Request Management (Day 3: Clean Core Extensibility)

Dokumen ini berisi panduan **System Integration Testing (SIT)** untuk memverifikasi seluruh flow aplikasi PO Request Management dari end-to-end.

---

## Arsitektur yang Ditest

```
┌──────────────────────────────────────────────────────────────────┐
│                    BTP (Side-by-Side Extension)                   │
│                                                                  │
│  [1] Fiori UI ──▶ [2] CAP Service ──▶ [3] HANA Cloud            │
│  (List Report)      (po-service.js)     (PORequests + Items)     │
│                         │                                        │
│                         │ postToSAP()                            │
│                         ▼                                        │
│                   [4] SAP OData V2 Client                        │
│                   (sap-client.js)                                │
│                         │                                        │
└─────────────────────────┼────────────────────────────────────────┘
                          │ HTTPS (OData V2)
                          ▼
┌──────────────────────────────────────────────────────────────────┐
│  [5] SAP S/4HANA (sap.ilmuprogram.com)                           │
│      MM_PUR_PO_MAINT_V2_SRV → PO 4500000xxx                     │
└──────────────────────────────────────────────────────────────────┘
```

## Komponen yang Ditest

| # | Komponen | Teknologi | File / Layer |
|:--|:---------|:----------|:-------------|
| 1 | OData Service Endpoint | CAP OData V4 | `srv/po-service.cds` |
| 2 | Business Logic & Validasi | Node.js | `srv/po-service.js` |
| 3 | SAP Integration (Post PO) | OData V2 Client | `srv/lib/sap-client.js` |
| 4 | Database (SQLite / HANA) | CDS → HDI | `db/po-schema.cds` |
| 5 | Fiori Elements UI | SAPUI5 | `app/po/` |
| 6 | HANA Cloud Connectivity | @cap-js/hana | `package.json` profiles |

## File SIT

| File | Deskripsi |
|:-----|:----------|
| [01-sit-local-sqlite.md](01-sit-local-sqlite.md) | Test lokal dengan SQLite (cds watch) |
| [02-sit-hybrid-hana.md](02-sit-hybrid-hana.md) | Test hybrid mode dengan HANA Cloud |
| [03-sit-sap-integration.md](03-sit-sap-integration.md) | Test Post PO ke SAP S/4HANA real |
| [04-sit-fiori-ui.md](04-sit-fiori-ui.md) | Test Fiori Elements UI end-to-end |
| [sit-test-curl.sh](sit-test-curl.sh) | Script curl otomatis untuk API testing |

## Prerequisite

- [ ] `po-project` sudah di-setup (npm install selesai)
- [ ] `.env` berisi SAP credentials
- [ ] CF CLI logged in (`cf login`)
- [ ] HANA Cloud instance running (untuk test hybrid)
- [ ] HDI container `po-project-db` sudah dibuat (`cds deploy --to hana`)

## Quick Start

```bash
# 1. Jalankan server lokal
cd Day3-Extensibility/po-project
cds watch

# 2. Run SIT script (terminal baru)
cd Day3-Extensibility/po-project-sit
chmod +x sit-test-curl.sh
./sit-test-curl.sh

# 3. Cek hasil di terminal
```

---

## Status Legend

| Icon | Status |
|:-----|:-------|
| ✅ | PASS |
| ❌ | FAIL |
| ⏭️ | SKIP (opsional) |
| ☐ | Belum ditest |
