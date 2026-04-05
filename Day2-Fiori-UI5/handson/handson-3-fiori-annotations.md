# ✅ Hands-on 3: Fiori Annotations — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026

---

## File Annotations yang Diperiksa

### `app/browse/fiori-service.cds` (actual dari `cds add sample`)

```cds
using CatalogService from '../../srv/cat-service';

// Books Object Page
annotate CatalogService.Books with @(UI : {
  HeaderInfo : {
    TypeName       : '{i18n>Book}',
    TypeNamePlural : '{i18n>Books}',
    Description    : {Value : author}
  },
  HeaderFacets : [{
    $Type  : 'UI.ReferenceFacet',
    Label  : '{i18n>Description}',
    Target : '@UI.FieldGroup#Descr'
  }],
  Facets : [{
    $Type  : 'UI.ReferenceFacet',
    Label  : '{i18n>Details}',
    Target : '@UI.FieldGroup#Price'
  }],
  FieldGroup #Descr : {Data : [{Value : descr}]},
  FieldGroup #Price : {Data : [
    {Value : price},
    {Value : currency.symbol, Label : '{i18n>Currency}'},
  ]},
});

// Books List Page
annotate CatalogService.Books with @(UI : {
  SelectionFields : [ID, price, currency_code],
  LineItem : [
    {Value : ID,              Label : '{i18n>Title}'},
    {Value : author,          Label : '{i18n>Author}'},
    {Value : genre.name},
    {Value : price},
    {Value : currency.symbol},
  ]
});
```

### Penjelasan Annotations (Analogi)

```
@UI.LineItem = "Kolom apa saja yang tampil di tabel"
├── ID (Title)
├── author (Author)
├── genre.name
├── price
└── currency.symbol

@UI.SelectionFields = "Filter apa saja di atas tabel"
├── ID
├── price
└── currency_code

@UI.HeaderInfo = "Header di halaman detail"
├── TypeName: 'Book'
├── TypeNamePlural: 'Books'
└── Description: author name

@UI.Facets = "Tab/section di halaman detail"
└── Details → FieldGroup#Price (price + currency)

@UI.HeaderFacets = "KPI di header halaman detail"
└── Description → FieldGroup#Descr (book description)
```

### Hasil di Browser

**List Report Page:**
- ✅ Tabel menampilkan kolom: Title, Author, Genre, Price, Currency
- ✅ Filter bar menampilkan: ID, Price, Currency
- ✅ Klik baris → navigasi ke Object Page

**Object Page:**
- ✅ Header menunjukkan judul buku dan nama author
- ✅ Section "Description" menampilkan deskripsi buku
- ✅ Section "Details" menampilkan harga dan currency

---

## Kesimpulan

- ✅ Annotations CDS mengontrol seluruh tampilan Fiori Elements UI
- ✅ Tidak ada HTML/XML/JavaScript yang ditulis manual untuk UI ini
- ✅ List Report dan Object Page berfungsi sesuai annotations
