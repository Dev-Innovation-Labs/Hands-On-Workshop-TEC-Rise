# SIT-01: Local SQLite Testing

## Tujuan
Verifikasi semua OData endpoint dan business logic berjalan dengan **SQLite in-memory** (development mode).

## Setup

```bash
cd Day3-Extensibility/po-project
cds watch
```

**Expected:** Server running di `http://localhost:4004`, log menunjukkan `connect to db > sqlite {:memory:}`

---

## Test Case 1.1: Service Metadata

**Deskripsi:** OData service metadata accessible

```bash
curl -s http://localhost:4004/po/$metadata | head -20
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 200 | Response berisi `<edmx:Edmx>` | ☐ |
| 2 | Entity PORequests ada | `<EntityType Name="PORequests">` | ☐ |
| 3 | Entity PORequestItems ada | `<EntityType Name="PORequestItems">` | ☐ |
| 4 | Action postToSAP ada | `<Action Name="postToSAP">` | ☐ |
| 5 | Function getSAPSuppliers ada | `<Function Name="getSAPSuppliers">` | ☐ |

---

## Test Case 1.2: Read PO Requests (GET)

**Deskripsi:** Membaca semua PO Requests dari seed data CSV

```bash
curl -s http://localhost:4004/po/PORequests | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 200 | JSON response valid | ☐ |
| 2 | Jumlah record | 3 records (dari CSV seed data) | ☐ |
| 3 | REQ-260001 | Description: "Pengadaan Laptop Kantor Jakarta", Status: D | ☐ |
| 4 | REQ-260002 | Description: "Pembelian Safety Equipment", Status: D | ☐ |
| 5 | REQ-260003 | Description: "Pengadaan Office Equipment", Status: P | ☐ |
| 6 | statusCriticality | D=2 (kuning), P=3 (hijau) | ☐ |

---

## Test Case 1.3: Read PO Request Items (GET with $expand)

**Deskripsi:** Membaca PO Request beserta items-nya

```bash
# REQ-260001 (1 item)
curl -s 'http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670001)?$expand=items' | python3 -m json.tool

# REQ-260002 (2 items)
curl -s 'http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670002)?$expand=items' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | REQ-260001 items | 1 item: EWMS4-01, qty=10, netAmount=3020.00 | ☐ |
| 2 | REQ-260002 items | 2 items: EWMS4-02 (6 PC, 450) + EWMS4-01 (10 EA, 450) | ☐ |
| 3 | REQ-260003 items | 1 item: EWMS4-01, qty=20, netAmount=6040.00 | ☐ |
| 4 | totalAmount match | Sum of items netAmount = header totalAmount | ☐ |

---

## Test Case 1.4: Create PO Request (POST)

**Deskripsi:** Membuat PO Request baru — auto-generate requestNo

```bash
curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "SIT Test - PO Request Baru",
    "companyCode": "1710",
    "purchasingOrg": "1710",
    "purchasingGroup": "001",
    "supplier": "17300001",
    "supplierName": "Test Supplier SIT",
    "deliveryDate": "2026-06-15",
    "currency": "USD"
  }' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 201 Created | Response berisi data baru | ☐ |
| 2 | requestNo auto-generated | Format `REQ-26xxxx` (e.g., REQ-260004) | ☐ |
| 3 | orderDate default hari ini | Format `YYYY-MM-DD` | ☐ |
| 4 | status default | `D` (Draft) | ☐ |
| 5 | totalAmount default | `0` | ☐ |
| 6 | ID auto-generated | UUID format | ☐ |

> **Catat ID** dari response untuk test selanjutnya: `__________`

---

## Test Case 1.5: Create PO Request Item (POST)

**Deskripsi:** Menambahkan item ke PO Request yang baru dibuat

```bash
# Ganti {PO_ID} dengan ID dari Test 1.4
curl -s -X POST 'http://localhost:4004/po/PORequests({PO_ID})/items' \
  -H "Content-Type: application/json" \
  -d '{
    "materialNo": "EWMS4-01",
    "description": "SIT Test Item 1",
    "quantity": 5,
    "uom": "PC",
    "unitPrice": 100.00,
    "plant": "1710",
    "materialGroup": "L001"
  }' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 201 Created | Item berhasil dibuat | ☐ |
| 2 | itemNo auto-generated | `10` (item pertama) | ☐ |
| 3 | netAmount auto-calc | `500.00` (5 × 100.00) | ☐ |
| 4 | currency default | `USD` | ☐ |
| 5 | Header totalAmount updated | Cek GET parent → totalAmount = 500.00 | ☐ |

---

## Test Case 1.6: Validasi — Delivery Date sebelum Order Date

**Deskripsi:** Sistem harus reject jika delivery date ≤ order date

```bash
curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "SIT Validation Test",
    "orderDate": "2026-05-01",
    "deliveryDate": "2026-04-01",
    "supplier": "17300001"
  }' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 400 | Error response | ☐ |
| 2 | Error message | "Delivery Date harus setelah Order Date" | ☐ |

---

## Test Case 1.7: Validasi — Block Edit Posted PO

**Deskripsi:** PO yang sudah Posted (status=P) tidak boleh diubah

```bash
# REQ-260003 sudah status P
curl -s -X PATCH 'http://localhost:4004/po/PORequests(b1c2d3e4-f5a6-7890-bcde-f12345670003)' \
  -H "Content-Type: application/json" \
  -d '{"description": "Coba ubah Posted PO"}' | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 400 | Error response | ☐ |
| 2 | Error message | "sudah di-post ke SAP...tidak dapat diubah" | ☐ |

---

## Test Case 1.8: OData Query Options

**Deskripsi:** Filter, sort, dan pagination berjalan

```bash
# Filter status = Draft
curl -s 'http://localhost:4004/po/PORequests?$filter=status%20eq%20%27D%27' | python3 -m json.tool

# Order by totalAmount desc
curl -s 'http://localhost:4004/po/PORequests?$orderby=totalAmount%20desc' | python3 -m json.tool

# Select specific fields
curl -s 'http://localhost:4004/po/PORequests?$select=requestNo,description,status,totalAmount' | python3 -m json.tool

# Top + Skip (pagination)
curl -s 'http://localhost:4004/po/PORequests?$top=2&$skip=1' | python3 -m json.tool

# Count
curl -s 'http://localhost:4004/po/PORequests/$count'
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | $filter status=D | 2 records (REQ-260001, REQ-260002) + PO baru dari test 1.4 | ☐ |
| 2 | $orderby totalAmount desc | Records sorted descending | ☐ |
| 3 | $select | Hanya return field yang diminta | ☐ |
| 4 | $top=2&$skip=1 | 2 records, mulai dari record ke-2 | ☐ |
| 5 | $count | Angka total records | ☐ |

---

## Test Case 1.9: Test SAP Connection Function

**Deskripsi:** Cek koneksi ke SAP S/4HANA dari CAP

```bash
curl -s http://localhost:4004/po/testSAPConnection() | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | ok = true | Koneksi berhasil | ☐ |
| 2 | status = 200 | HTTP 200 dari SAP | ☐ |
| 3 | message | "Connected to SAP..." | ☐ |

---

## Test Case 1.10: Get SAP Suppliers Function

**Deskripsi:** Fetch daftar supplier dari SAP real

```bash
curl -s http://localhost:4004/po/getSAPSuppliers() | python3 -m json.tool
```

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | HTTP 200 | Array of suppliers | ☐ |
| 2 | Data ada | Minimal 1 supplier returned | ☐ |
| 3 | Field structure | Setiap supplier punya: Supplier, SupplierName, Country | ☐ |

---

## Checklist Ringkasan SIT-01

| # | Test Case | Status |
|:--|:----------|:-------|
| 1.1 | Service Metadata | ☐ |
| 1.2 | Read PO Requests | ☐ |
| 1.3 | Read Items ($expand) | ☐ |
| 1.4 | Create PO Request | ☐ |
| 1.5 | Create Item (auto-calc) | ☐ |
| 1.6 | Validasi: Delivery Date | ☐ |
| 1.7 | Validasi: Block Edit Posted | ☐ |
| 1.8 | OData Query Options | ☐ |
| 1.9 | Test SAP Connection | ☐ |
| 1.10 | Get SAP Suppliers | ☐ |

**Tester:** ________________  
**Tanggal:** ________________  
**Hasil:** ☐ PASS ALL / ☐ PARTIAL / ☐ FAIL
