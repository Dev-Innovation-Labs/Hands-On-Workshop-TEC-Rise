# ✅ Hands-on 2: Manifest & Routing — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026

---

## File yang Diperiksa

### `app/browse/webapp/manifest.json` (actual dari `cds add sample`)

```json
{
  "_version": "1.28.0",
  "sap.app": {
    "id": "bookshop-fiori.browse",
    "type": "application",
    "title": "{{appTitle}}",
    "dataSources": {
      "CatalogService": {
        "uri": "odata/v4/catalog/",
        "type": "OData",
        "settings": { "odataVersion": "4.0" }
      }
    }
  }
}
```

### Penjelasan Routing

```
manifest.json mendefinisikan:

1. dataSources  → Dari mana data diambil (OData service path)
   └── "CatalogService" → uri: "odata/v4/catalog/"

2. routing.routes → Halaman apa saja yang ada
   └── "" (root) → BooksList (List Report)
   └── "Books({key})" → BooksObjectPage (Object Page)

3. routing.targets → Komponen Fiori Elements yang dipakai
   └── BooksList → sap.fe.templates.ListReport
   └── BooksObjectPage → sap.fe.templates.ObjectPage
```

### Verifikasi Routing Berjalan

| Route | URL | Hasil |
|:------|:----|:------|
| Root (List Report) | `http://localhost:4004/browse/webapp/index.html` | ✅ Tabel Books muncul |
| Object Page | Klik salah satu baris di tabel | ✅ Detail buku muncul |
| Fiori Launchpad | `http://localhost:4004/fiori-apps.html` | ✅ Tile "Browse Books" muncul |

---

## Kesimpulan

- ✅ `manifest.json` sudah terkonfigurasi dengan benar (dataSources, routing, targets)
- ✅ Routing dari List Report → Object Page berfungsi (klik baris → pindah halaman)
- ✅ Fiori Launchpad sandbox bisa diakses
