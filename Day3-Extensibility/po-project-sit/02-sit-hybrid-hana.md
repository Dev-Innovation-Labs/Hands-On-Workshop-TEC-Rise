# SIT-02: Hybrid Mode — HANA Cloud Testing

## Tujuan
Verifikasi aplikasi berjalan dengan **HANA Cloud** sebagai database (hybrid mode). Data persisten dan bisa diakses via DBeaver.

## Prerequisite

- [ ] HANA Cloud instance **running** (bukan stopped)
- [ ] HDI container `po-project-db` sudah dibuat
- [ ] `cds deploy --to hana` sudah berhasil
- [ ] `.cdsrc-private.json` ada (auto-generated)
- [ ] CF CLI logged in

## Setup

```bash
cd Day3-Extensibility/po-project

# Pastikan HANA Cloud running
cf update-service Dev-hana -c '{"data":{"serviceStopped":false}}'

# Jalankan hybrid mode
cds watch --profile hybrid
```

**Expected log:**
```
resolving cloud service bindings...
bound db to cf managed service po-project-db:po-project-db-key
[cds] - connect to db > hana { ... }
[cds] - server listening on { url: 'http://localhost:4004' }
```

> ⚠️ Log HARUS menunjukkan `connect to db > hana`, BUKAN `sqlite`. Jika masih sqlite, cek `package.json` → `[hybrid]` → `"impl": "@cap-js/hana"`.

---

## Test Case 2.1: Koneksi HANA Cloud

**Deskripsi:** Server berhasil connect ke HANA Cloud

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Log output | `connect to db > hana` | ☐ |
| 2 | Host di log | `...hana.prod-ap21.hanacloud.ondemand.com` | ☐ |
| 3 | Port | `443` | ☐ |
| 4 | Schema | Hash string (e.g., `F6AC7A7E...`) | ☐ |

---

## Test Case 2.2: Read Data dari HANA

**Deskripsi:** Data seed dari CSV tersedia di HANA Cloud

```bash
curl -s http://localhost:4004/po/PORequests | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 200 | JSON response valid | ☐ |
| 2 | Jumlah record | 3 records (sama dengan CSV) | ☐ |
| 3 | REQ-260001 ada | Draft, Laptop Kantor Jakarta | ☐ |
| 4 | REQ-260002 ada | Draft, Safety Equipment | ☐ |
| 5 | REQ-260003 ada | Posted, Office Equipment, sapPONumber=4500000099 | ☐ |

---

## Test Case 2.3: Data Persistence (Restart Test)

**Deskripsi:** Data TIDAK hilang setelah restart server (beda dengan SQLite :memory:)

**Langkah:**
1. Create record baru:
```bash
curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "SIT-02 Persistence Test",
    "supplier": "17300001",
    "supplierName": "Test Persistence",
    "deliveryDate": "2026-07-01"
  }' | python3 -m json.tool
```

2. **Stop server** (Ctrl+C)

3. **Start ulang:** `cds watch --profile hybrid`

4. **Cek data masih ada:**
```bash
curl -s 'http://localhost:4004/po/PORequests?$filter=description%20eq%20%27SIT-02%20Persistence%20Test%27' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Record dibuat | HTTP 201, requestNo auto-generated | ☐ |
| 2 | Server restarted | `connect to db > hana` lagi | ☐ |
| 3 | Data masih ada | Record "SIT-02 Persistence Test" masih muncul | ☐ |

---

## Test Case 2.4: DBeaver Connection

**Deskripsi:** HANA Cloud bisa diakses dari DBeaver (desktop client)

**Ambil credentials:**
```bash
cf service-key po-project-db po-project-db-key
```

**DBeaver settings:**

| Field | Nilai |
|:------|:------|
| Edition | HANA Cloud |
| Host | *(dari output `host`)* |
| Port | 443 |
| Username | *(dari output `user` — bukan BTP email!)* |
| Password | *(dari output `password`)* |

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Test Connection | "Connected" berhasil | ☐ |
| 2 | Tabel visible | 3 tabel: PORequests, PORequestItems, CDS_OUTBOX_MESSAGES | ☐ |
| 3 | Data PORequests | 3+ rows (termasuk SIT test data) | ☐ |
| 4 | Data PORequestItems | 4 rows dari seed data | ☐ |

---

## Test Case 2.5: SQL Query via DBeaver

**Deskripsi:** Jalankan SQL query langsung di DBeaver

```sql
-- Query 1: Semua PO Requests
SELECT "REQUESTNO", "DESCRIPTION", "STATUS", "TOTALAMOUNT", "SAPPONUMBER"
FROM "COM_TECRISE_PROCUREMENT_POREQUESTS"
ORDER BY "REQUESTNO";

-- Query 2: Join header + items
SELECT r."REQUESTNO", r."DESCRIPTION", r."STATUS",
       i."MATERIALNO", i."DESCRIPTION" AS "ITEM_DESC", i."QUANTITY", i."NETAMOUNT"
FROM "COM_TECRISE_PROCUREMENT_POREQUESTS" r
JOIN "COM_TECRISE_PROCUREMENT_POREQUESTITEMS" i
  ON r."ID" = i."PARENT_ID"
ORDER BY r."REQUESTNO", i."ITEMNO";

-- Query 3: PO yang sudah Posted
SELECT "REQUESTNO", "SAPPONUMBER", "SAPPOSTDATE"
FROM "COM_TECRISE_PROCUREMENT_POREQUESTS"
WHERE "STATUS" = 'P';
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Query 1 execute | 3+ rows, column names UPPERCASE flat | ☐ |
| 2 | Query 2 join works | Items matched ke header via PARENT_ID | ☐ |
| 3 | Query 3 filter | REQ-260003 dengan sapPONumber 4500000099 | ☐ |

---

## Test Case 2.6: CDS → HANA Column Mapping

**Deskripsi:** Verifikasi naming convention CDS → HANA

| CDS Field (po-schema.cds) | HANA Column (DBeaver) | Status |
|:---------------------------|:----------------------|:-------|
| `requestNo` | `REQUESTNO` | ☐ |
| `companyCode` | `COMPANYCODE` | ☐ |
| `purchasingOrg` | `PURCHASINGORG` | ☐ |
| `supplierName` | `SUPPLIERNAME` | ☐ |
| `totalAmount` | `TOTALAMOUNT` | ☐ |
| `sapPONumber` | `SAPPONUMBER` | ☐ |
| `sapPostDate` | `SAPPOSTDATE` | ☐ |
| `items.parent` (Association) | `PARENT_ID` | ☐ |
| `unitPrice` | `UNITPRICE` | ☐ |
| `materialGroup` | `MATERIALGROUP` | ☐ |

> **Aturan:** CDS camelCase → HANA UPPERCASE flat (tanpa underscore). Exception: Association → tambah `_ID`.

---

## Test Case 2.7: HANA vs SQLite Comparison

**Deskripsi:** Data harus identik antara SQLite (cds watch) dan HANA (cds watch --profile hybrid)

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Jumlah PORequests | Sama (3 dari seed) | ☐ |
| 2 | Jumlah PORequestItems | Sama (4 dari seed) | ☐ |
| 3 | totalAmount values | Identik | ☐ |
| 4 | Business logic (auto-calc) | Sama behavior | ☐ |

---

## Checklist Ringkasan SIT-02

| # | Test Case | Status |
|:--|:----------|:-------|
| 2.1 | Koneksi HANA Cloud | ☐ |
| 2.2 | Read Data dari HANA | ☐ |
| 2.3 | Data Persistence (Restart) | ☐ |
| 2.4 | DBeaver Connection | ☐ |
| 2.5 | SQL Query via DBeaver | ☐ |
| 2.6 | Column Mapping CDS→HANA | ☐ |
| 2.7 | HANA vs SQLite Comparison | ☐ |

**Tester:** ________________  
**Tanggal:** ________________  
**Hasil:** ☐ PASS ALL / ☐ PARTIAL / ☐ FAIL
