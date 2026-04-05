# ✅ Hands-on 1: XSUAA Configuration — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED (file dikonfigurasi)  
> **Tanggal:** 5 April 2026

---

## File yang Dibuat

### `xs-security.json`

```json
{
    "xsappname": "bookshop-tecrise",
    "tenant-mode": "dedicated",
    "description": "Security config for TEC Rise Bookshop",
    "scopes": [
        { "name": "$XSAPPNAME.read",  "description": "Can read books and orders" },
        { "name": "$XSAPPNAME.write", "description": "Can create and update books" },
        { "name": "$XSAPPNAME.admin", "description": "Full administrative access" }
    ],
    "role-templates": [
        {
            "name": "Viewer",
            "description": "Read-only access to catalog",
            "scope-references": ["$XSAPPNAME.read"]
        },
        {
            "name": "Editor",
            "description": "Can read and edit books",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write"]
        },
        {
            "name": "Administrator",
            "description": "Full access",
            "scope-references": ["$XSAPPNAME.read", "$XSAPPNAME.write", "$XSAPPNAME.admin"]
        }
    ],
    "role-collections": [
        {
            "name": "Bookshop_Viewer",
            "description": "Bookshop read-only users",
            "role-template-references": ["$XSAPPNAME.Viewer"]
        },
        {
            "name": "Bookshop_Admin",
            "description": "Bookshop administrators",
            "role-template-references": ["$XSAPPNAME.Administrator"]
        }
    ]
}
```

## Penjelasan (Analogi)

```
xs-security.json = "Daftar Izin Masuk Gedung"

Scopes (Izin)              Role Templates (Bundel)     Role Collections (Ke User)
├── read  (baca)     ─────→ Viewer (read)        ─────→ Bookshop_Viewer
├── write (tulis)    ─────→ Editor (read+write)
└── admin (semua)    ─────→ Administrator (all)   ─────→ Bookshop_Admin

User → Role Collection → Role Template → Scopes
wahyu.amaldi@kpmg.co.id → Bookshop_Admin → Administrator → read+write+admin
```

## Verifikasi

- ✅ File `xs-security.json` valid (JSON syntax benar)
- ✅ 3 scopes terdefinisi (read, write, admin)
- ✅ 3 role templates terdefinisi (Viewer, Editor, Administrator)
- ✅ 2 role collections terdefinisi (Bookshop_Viewer, Bookshop_Admin)

---

## Kesimpulan

- ✅ XSUAA configuration file siap digunakan saat deploy
- ✅ Hierarki Scope → Role → Role Collection terdefinisi dengan jelas
