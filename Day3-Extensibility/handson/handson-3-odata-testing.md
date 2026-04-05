# ✅ Hands-on 3: OData Query & Testing — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED (actual output dari `cds serve`)  
> **Tanggal:** 5 April 2026  
> **Server:** CAP v9.8.4, port 4012

---

## Test 1: GET /odata/v4/catalog/Books?$top=2

**Query:** Ambil 2 buku pertama (paging)

```bash
curl "http://localhost:4004/odata/v4/catalog/Books?\$top=2"
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    {
      "ID": 201,
      "author": "Emily Brontë",
      "title": "Wuthering Heights",
      "stock": 12,
      "price": 11.11,
      "currency_code": "GBP"
    },
    {
      "ID": 207,
      "author": "Charlotte Brontë",
      "title": "Jane Eyre",
      "stock": 11,
      "price": 12.34,
      "currency_code": "GBP"
    }
  ]
}
```

---

## Test 2: GET /odata/v4/catalog/Books?$select=title,price&$filter=price lt 15

**Query:** Hanya title & price, filter harga < 15

```bash
curl "http://localhost:4004/odata/v4/catalog/Books?\$select=title,price&\$filter=price%20lt%2015"
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    { "title": "Wuthering Heights", "price": 11.11, "ID": 201 },
    { "title": "Jane Eyre",         "price": 12.34, "ID": 207 },
    { "title": "The Raven",         "price": 13.13, "ID": 251 },
    { "title": "Eleonora",          "price": 14,    "ID": 252 }
  ]
}
```

> **Perhatikan:** 4 dari 5 buku memenuhi filter `price lt 15`.
> Buku "Catweazle" (price: 150 JPY) tidak muncul.

---

## Test 3: GET /odata/v4/catalog/Books?$orderby=price desc&$top=3

**Query:** Top 3 buku termahal

```bash
curl "http://localhost:4004/odata/v4/catalog/Books?\$orderby=price%20desc&\$top=3"
```

**✅ Response (Status: 200):**

```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    {
      "ID": 271,
      "author": "Richard Carpenter",
      "title": "Catweazle",
      "stock": 22,
      "price": 150,
      "currency_code": "JPY"
    },
    {
      "ID": 252,
      "author": "Edgar Allen Poe",
      "title": "Eleonora",
      "stock": 555,
      "price": 14,
      "currency_code": "USD"
    },
    {
      "ID": 251,
      "author": "Edgar Allen Poe",
      "title": "The Raven",
      "stock": 333,
      "price": 13.13,
      "currency_code": "USD"
    }
  ]
}
```

---

## Test 4: GET /odata/v4/catalog/Books/$count

**Query:** Hitung total buku

```bash
curl "http://localhost:4004/odata/v4/catalog/Books/\$count"
```

**✅ Response (Status: 200):**

```
5
```

---

## Ringkasan Semua Test

| # | Query | Status | Hasil |
|:--|:------|:-------|:------|
| 1 | `$top=2` | ✅ 200 | 2 buku pertama (Wuthering Heights, Jane Eyre) |
| 2 | `$select=title,price&$filter=price lt 15` | ✅ 200 | 4 buku < 15 (tanpa Catweazle) |
| 3 | `$orderby=price desc&$top=3` | ✅ 200 | 3 termahal: Catweazle (150), Eleonora (14), The Raven (13.13) |
| 4 | `$count` | ✅ 200 | Total: 5 buku |

---

## Kesimpulan

- ✅ Semua OData query options berfungsi ($top, $select, $filter, $orderby, $count)
- ✅ Data response sesuai dengan seed data CSV
- ✅ Filter dan sorting bekerja dengan benar
- ✅ Server mengembalikan JSON yang valid dan well-formatted
