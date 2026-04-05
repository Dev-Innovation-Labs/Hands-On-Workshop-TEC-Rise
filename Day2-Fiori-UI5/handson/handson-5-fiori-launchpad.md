# ✅ Hands-on 5: Fiori Launchpad — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 5 April 2026

---

## File Konfigurasi FLP

### `app/appconfig/fioriSandboxConfig.json` (dari `cds add sample`)

File ini mengkonfigurasi **Fiori Launchpad sandbox** — semacam "home screen"
yang menampilkan tile/kartu untuk setiap Fiori app.

### `app/fiori-apps.html`

Entry point untuk membuka Fiori Launchpad di browser.

## Verifikasi

```bash
cds watch
# Buka http://localhost:4004/fiori-apps.html
```

### Hasil yang Diharapkan:

Fiori Launchpad menampilkan tile-tile berikut:

| Tile | Link ke | Service |
|:-----|:--------|:--------|
| Browse Books | app/browse/ | CatalogService |
| Manage Books | app/admin-books/ | AdminService |
| Manage Authors | app/admin-authors/ | AdminService |
| Genres | app/genres/ | (tree view & value help) |

### Cara Akses

```
http://localhost:4004/fiori-apps.html
    → Fiori Launchpad sandbox
        → Klik "Browse Books" → List Report (CatalogService.Books)
        → Klik "Manage Books" → admin (perlu login sebagai admin)
```

> **Catatan:** Admin apps memerlukan login. Di mode development (`cds watch`),
> auth strategy adalah `mocked`. Gunakan user `alice` (admin) atau `bob` (viewer)
> sesuai konfigurasi di `srv/access-control.cds`.

---

## Kesimpulan

- ✅ Fiori Launchpad sandbox berjalan di `http://localhost:4004/fiori-apps.html`
- ✅ Tile-tile Fiori app ter-generate otomatis dari sample
- ✅ Navigasi dari Launchpad → Fiori app berfungsi
