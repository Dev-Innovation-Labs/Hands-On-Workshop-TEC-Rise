# SIT-03: SAP S/4HANA Integration Testing

## Tujuan
Verifikasi integrasi end-to-end: **CAP → SAP OData V2 → PO Created di SAP S/4HANA real**.

## Prerequisite

- [ ] Server running (`cds watch` atau `cds watch --profile hybrid`)
- [ ] `.env` berisi SAP credentials:
  ```
  SAP_HOST=https://sap.ilmuprogram.com
  SAP_CLIENT=777
  SAP_USERNAME=wahyu.amaldi
  SAP_PASSWORD=Pas671_ok12345
  ```
- [ ] SAP system reachable (not maintenance)

## SAP Integration Flow

```
CAP postToSAP() → sap-client.js → SAP S/4HANA
                                    │
Step 1: Fetch CSRF Token ──────────►│ GET /$batch (X-CSRF-Token: Fetch)
Step 2: Create Draft PO Header ───►│ POST /C_PurchaseOrderTP
Step 3: Add Items (per item) ─────►│ POST /C_PurchaseOrderItemTP
Step 4: Prepare Draft ────────────►│ POST /C_PurchaseOrderTPPreparation
Step 5: Activate (Post) ─────────►│ POST /C_PurchaseOrderTPActivation
                                    │
                              ◄─────│ Returns: PurchaseOrder = "4500000xxx"
```

---

## Test Case 3.1: Test SAP Connection

**Deskripsi:** Cek koneksi ke SAP S/4HANA

```bash
curl -s http://localhost:4004/po/testSAPConnection() | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | ok = true | Koneksi berhasil | ☐ |
| 2 | status = 200 | SAP respond OK | ☐ |
| 3 | message | "Connected to SAP at https://sap.ilmuprogram.com" | ☐ |

**Jika FAIL:** Cek `.env` → SAP_HOST, SAP_USERNAME, SAP_PASSWORD

---

## Test Case 3.2: Get SAP Suppliers

**Deskripsi:** Fetch supplier master data dari SAP

```bash
curl -s http://localhost:4004/po/getSAPSuppliers() | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 200 | Array of suppliers | ☐ |
| 2 | Supplier 17300001 | Wahyu Amaldi (Domestic Supplier) | ☐ |
| 3 | Field structure | Supplier, SupplierName, Country | ☐ |

---

## Test Case 3.3: Validasi Pre-Post — Tanpa Supplier

**Deskripsi:** PO tanpa supplier harus ditolak

```bash
# Buat PO tanpa supplier
PO_ID=$(curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{"description": "SIT-03 No Supplier Test"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['ID'])")

echo "Created PO: $PO_ID"

# Coba Post — harus gagal
curl -s -X POST "http://localhost:4004/po/PORequests($PO_ID)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 400 | Rejected | ☐ |
| 2 | Error message | "belum memiliki Supplier" | ☐ |

---

## Test Case 3.4: Validasi Pre-Post — Tanpa Items

**Deskripsi:** PO dengan supplier tapi tanpa items harus ditolak

```bash
PO_ID=$(curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "SIT-03 No Items Test",
    "supplier": "17300001",
    "supplierName": "Test Supplier"
  }' | python3 -c "import sys,json; print(json.load(sys.stdin)['ID'])")

echo "Created PO: $PO_ID"

curl -s -X POST "http://localhost:4004/po/PORequests($PO_ID)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 400 | Rejected | ☐ |
| 2 | Error message | "belum memiliki items" | ☐ |

---

## Test Case 3.5: Validasi Pre-Post — Already Posted

**Deskripsi:** PO yang sudah Posted tidak boleh di-post ulang

```bash
# REQ-260003 sudah status P
curl -s -X POST "http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670003)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 400 | Rejected | ☐ |
| 2 | Error message | "sudah di-post ke SAP" | ☐ |

---

## Test Case 3.6: Post PO ke SAP — Happy Path (via curl)

> ⚠️ **Test ini membuat PO NYATA di SAP S/4HANA.** Hanya jalankan jika diizinkan.

**Deskripsi:** Post Draft PO ke SAP, verifikasi PO Number diterima.

```bash
# Gunakan REQ-260001 (status D, supplier=17300001, punya 1 item)
curl -s -X POST \
  "http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670001)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

**Expected response:**
```json
{
    "sapPONumber": "4500000xxx",
    "status": "Posted",
    "message": "PO 4500000xxx berhasil dibuat di SAP S/4HANA"
}
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | sapPONumber | Format `4500000xxx` (10 digit) | ☐ |
| 2 | status | "Posted" | ☐ |
| 3 | message | "berhasil dibuat di SAP S/4HANA" | ☐ |

**Catat SAP PO Number:** `__________`

---

## Test Case 3.7: Verifikasi Data Setelah Post

**Deskripsi:** Cek PO Request ter-update setelah berhasil post

```bash
curl -s 'http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670001)' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | status | `P` (Posted) | ☐ |
| 2 | statusCriticality | `3` (hijau) | ☐ |
| 3 | sapPONumber | PO Number dari SAP (e.g., 4500000016) | ☐ |
| 4 | sapPostDate | Timestamp posting | ☐ |
| 5 | sapPostMessage | "PO ... berhasil dibuat..." | ☐ |

---

## Test Case 3.8: Verifikasi PO di SAP S/4HANA

**Deskripsi:** Cek PO yang dibuat benar-benar ada di SAP 

```bash
# Ganti 4500000xxx dengan PO Number aktual
curl -sk "https://wahyu.amaldi:Pas671_ok12345@sap.ilmuprogram.com/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV/C_PurchaseOrderFs('4500000xxx')?\$format=json&sap-client=777" | python3 -m json.tool
```

Atau via **SAP GUI** → Transaction `ME23N` → masukkan PO Number.

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | PO exists di SAP | Data ditemukan | ☐ |
| 2 | CompanyCode | 1710 | ☐ |
| 3 | Supplier | 17300001 | ☐ |
| 4 | Items | Material EWMS4-01, Qty 10 | ☐ |

---

## Test Case 3.9: Post PO Kedua (REQ-260002 — Multiple Items)

> ⚠️ **Test ini membuat PO NYATA di SAP.**

**Deskripsi:** Post PO dengan 2 items ke SAP

```bash
# REQ-260002 punya 2 items (EWMS4-02 + EWMS4-01)
curl -s -X POST \
  "http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670002)/PurchaseOrderService.postToSAP" \
  -H "Content-Type: application/json" \
  -d '{}' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | sapPONumber | PO Number berbeda dari test 3.6 | ☐ |
| 2 | 2 items di SAP | Kedua material: EWMS4-02 + EWMS4-01 | ☐ |
| 3 | Status berubah ke P | Draft → Posted | ☐ |

**Catat SAP PO Number:** `__________`

---

## Test Case 3.10: Error Handling — SAP Down/Wrong Creds

**Deskripsi:** Test error handling jika SAP tidak bisa dihubungi

**Langkah:** Temporarily ubah `.env` → SAP_PASSWORD salah, restart server, coba post.

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Status berubah | `E` (Error) — bukan crash | ☐ |
| 2 | sapPostMessage | Error message tersimpan di database | ☐ |
| 3 | Bisa retry | Setelah fix `.env`, post lagi → berhasil | ☐ |

> Jangan lupa kembalikan `.env` ke credentials yang benar setelah test!

---

## Checklist Ringkasan SIT-03

| # | Test Case | Status |
|:--|:----------|:-------|
| 3.1 | Test SAP Connection | ☐ |
| 3.2 | Get SAP Suppliers | ☐ |
| 3.3 | Validasi: Tanpa Supplier | ☐ |
| 3.4 | Validasi: Tanpa Items | ☐ |
| 3.5 | Validasi: Already Posted | ☐ |
| 3.6 | Post PO Happy Path | ☐ |
| 3.7 | Data Updated Setelah Post | ☐ |
| 3.8 | Verifikasi di SAP S/4HANA | ☐ |
| 3.9 | Post PO Multiple Items | ☐ |
| 3.10 | Error Handling SAP Down | ☐ |

**Tester:** ________________  
**Tanggal:** ________________  
**SAP PO Numbers Created:** ________________  
**Hasil:** ☐ PASS ALL / ☐ PARTIAL / ☐ FAIL
