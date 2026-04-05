# ✅ Hands-on 4: Custom SAPUI5 View — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** REFERENCE (dijalankan saat workshop berlangsung)  
> **Tanggal:** 5 April 2026

---

## Penjelasan

Hands-on 4 adalah latihan **Freestyle SAPUI5** — membuat custom view dengan XML + JavaScript.
Ini bertujuan agar peserta memahami **perbedaan** antara:

| Fiori Elements (Hands-on 1-3) | Freestyle SAPUI5 (Hands-on 4) |
|:-------------------------------|:------------------------------|
| UI auto-generated dari annotations | UI ditulis manual (XML + JS) |
| Minim coding | Full control tapi lebih banyak kode |
| Standar SAP design | Desain bebas |

## File yang Dibuat

### `app/custom-books/webapp/view/BooksList.view.xml`

View XML mendefinisikan layout:
- `<Page>` — container halaman
- `<SearchField>` — search bar
- `<Table>` — tabel dengan kolom Title, Author, Price, Stock, Actions
- items binding: `{/Books}` — binding langsung ke OData entity

### `app/custom-books/webapp/controller/BooksList.controller.js`

Controller mendefinisikan logic:
- `onInit()` — inisialisasi model
- `onSearch()` — filter tabel berdasarkan query
- `onBookSelect()` — navigasi ke Object Page
- `onOrder()` — panggil action submitOrder via MessageBox

## Verifikasi

```bash
cds watch
# Buka http://localhost:4004/custom-books/webapp/index.html
```

### Hasil yang Diharapkan:
- ✅ Halaman custom dengan search bar dan tabel Books
- ✅ Search berfungsi (filter by title)
- ✅ Klik baris → navigasi ke detail
- ✅ Tombol "Order" → konfirmasi dialog

---

## Kesimpulan

- ✅ Freestyle SAPUI5 memberikan full control tapi butuh lebih banyak kode
- ✅ Untuk sebagian besar use case, **Fiori Elements lebih efisien**
- ✅ Freestyle cocok untuk UI yang sangat custom / non-standar
