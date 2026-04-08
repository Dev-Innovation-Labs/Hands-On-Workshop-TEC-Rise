# SIT-04: Fiori Elements UI Testing

## Tujuan
Verifikasi **Fiori Elements List Report + Object Page** menampilkan data dengan benar dan semua interaksi UI berfungsi.

## Setup

```bash
cd Day3-Extensibility/po-project
cds watch     # atau cds watch --profile hybrid
```

**URL Fiori UI:** http://localhost:4004/po/webapp/index.html

---

## Test Case 4.1: Halaman Loading

**Deskripsi:** Fiori UI bisa diakses dan data tampil

**Langkah:** Buka `http://localhost:4004/po/webapp/index.html` di browser

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Halaman load | Tidak blank, tidak error | ☐ |
| 2 | Title | "PO Requests" (atau sesuai annotations) | ☐ |
| 3 | Table tampil | List Report dengan rows | ☐ |
| 4 | Row count | 3 records (dari seed data) | ☐ |
| 5 | No console error | F12 → Console → tidak ada error merah | ☐ |

---

## Test Case 4.2: List Report — Kolom & Data

**Deskripsi:** Kolom yang ditampilkan sesuai annotations

| # | Kolom | Expected Data (row 1) | Status |
|:--|:------|:----------------------|:-------|
| 1 | Request No | REQ-260001 | ☐ |
| 2 | Description | Pengadaan Laptop Kantor Jakarta | ☐ |
| 3 | Status | D (dengan warna kuning/warning) | ☐ |
| 4 | Supplier | 17300001 | ☐ |
| 5 | Total Amount | 3,020.00 | ☐ |
| 6 | SAP PO Number | *(kosong untuk Draft)* | ☐ |

---

## Test Case 4.3: Status Criticality (Warna)

**Deskripsi:** Status menampilkan warna yang benar

| Status | Kode | Warna Expected | Status |
|:-------|:-----|:---------------|:-------|
| Draft | D | Kuning/Warning (criticality=2) | ☐ |
| Posted | P | Hijau/Positive (criticality=3) | ☐ |
| Error | E | Merah/Negative (criticality=1) | ☐ |

---

## Test Case 4.4: Navigasi ke Object Page

**Deskripsi:** Klik row → navigasi ke detail page

**Langkah:** Klik baris **REQ-260001**

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Navigasi sukses | Object Page tampil | ☐ |
| 2 | Header info | REQ-260001, Draft, Laptop Kantor Jakarta | ☐ |
| 3 | General Info section | Company Code 1710, Purch Org 1710 | ☐ |
| 4 | Supplier section | 17300001, Wahyu Amaldi (Domestic Supplier) | ☐ |
| 5 | Dates section | Order Date, Delivery Date | ☐ |
| 6 | Items table section | 1 item terdaftar | ☐ |

---

## Test Case 4.5: Object Page — Items Table

**Deskripsi:** Tabel items di Object Page menampilkan line items

**Langkah:** Scroll ke section **Items** di Object Page REQ-260001

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Item count | 1 item | ☐ |
| 2 | Item No | 10 | ☐ |
| 3 | Material | EWMS4-01 | ☐ |
| 4 | Description | Small Part for Jakarta Office | ☐ |
| 5 | Quantity | 10 PC | ☐ |
| 6 | Unit Price | 302.00 | ☐ |
| 7 | Net Amount | 3,020.00 | ☐ |

**Langkah:** Navigasi ke REQ-260002 (punya 2 items)

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 8 | Item count | 2 items | ☐ |
| 9 | Item 10 | EWMS4-02, qty=6, netAmount=450.00 | ☐ |
| 10 | Item 20 | EWMS4-01, qty=10, netAmount=450.00 | ☐ |

---

## Test Case 4.6: Tombol "Post to SAP"

**Deskripsi:** Tombol action postToSAP muncul dan bisa diklik

**Langkah:** Buka Object Page PO Request dengan status **Draft**

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Tombol visible | "📤 Post to SAP" muncul di header/toolbar | ☐ |
| 2 | Klik tombol | Confirm dialog atau langsung execute | ☐ |
| 3 | Loading indicator | Muncul saat proses | ☐ |
| 4 | Success response | Status berubah D → P, SAP PO Number terisi | ☐ |
| 5 | UI auto-refresh | Data ter-update tanpa manual refresh | ☐ |

> ⚠️ Klik tombol ini akan membuat PO nyata di SAP S/4HANA!

---

## Test Case 4.7: Filter & Search di List Report

**Deskripsi:** Filter bar berfungsi

| # | Cek | Langkah | Expected | Status |
|:--|:----|:--------|:---------|:-------|
| 1 | Filter Status | Pilih Status = D | Hanya Draft PO tampil | ☐ |
| 2 | Filter Status | Pilih Status = P | Hanya Posted PO tampil | ☐ |
| 3 | Search | Ketik "Laptop" | REQ-260001 muncul | ☐ |
| 4 | Clear filter | Hapus filter | Semua records tampil | ☐ |

---

## Test Case 4.8: Create PO via UI

**Deskripsi:** Membuat PO Request baru dari Fiori UI

**Langkah:**
1. Klik tombol **"Create"** / **"+"** di List Report
2. Isi form:
   - Description: `SIT-04 UI Create Test`
   - Supplier: `17300001`
   - Supplier Name: `Test Supplier UI`
   - Delivery Date: pilih tanggal future
3. Save

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Create form tampil | Form entry muncul | ☐ |
| 2 | Request No | Auto-generated (readonly) | ☐ |
| 3 | Save berhasil | Data tersimpan, kembali ke list | ☐ |
| 4 | Record muncul di list | Row baru ada di table | ☐ |

---

## Test Case 4.9: SAP Integration Info di Object Page

**Deskripsi:** Section SAP Integration menampilkan hasil posting

**Langkah:** Buka Object Page PO yang sudah Posted (REQ-260003 atau PO yang baru di-post)

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | SAP PO Number | Terisi (e.g., 4500000099) | ☐ |
| 2 | SAP Post Date | Timestamp posting | ☐ |
| 3 | SAP Response | Message sukses/error | ☐ |
| 4 | Status badge | Hijau (P = Posted) | ☐ |

---

## Test Case 4.10: Error State di UI

**Deskripsi:** PO dengan status Error (E) ditampilkan dengan benar

**Langkah:** Jika ada PO status E (dari failed post), buka Object Page-nya

| # | Cek | Expected | Status |
|:--|:----|:---------|:-------|
| 1 | Status badge | Merah (E = Error) | ☐ |
| 2 | SAP Response | Error message tersimpan | ☐ |
| 3 | Post to SAP button | Masih available (bisa retry) | ☐ |

---

## Checklist Ringkasan SIT-04

| # | Test Case | Status |
|:--|:----------|:-------|
| 4.1 | Halaman Loading | ☐ |
| 4.2 | List Report Kolom & Data | ☐ |
| 4.3 | Status Criticality (Warna) | ☐ |
| 4.4 | Navigasi ke Object Page | ☐ |
| 4.5 | Items Table di Object Page | ☐ |
| 4.6 | Tombol Post to SAP | ☐ |
| 4.7 | Filter & Search | ☐ |
| 4.8 | Create PO via UI | ☐ |
| 4.9 | SAP Integration Info | ☐ |
| 4.10 | Error State di UI | ☐ |

**Browser:** ________________  
**Tester:** ________________  
**Tanggal:** ________________  
**Hasil:** ☐ PASS ALL / ☐ PARTIAL / ☐ FAIL
