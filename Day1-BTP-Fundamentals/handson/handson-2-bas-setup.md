# ✅ Hands-on 2: Business Application Studio (BAS) — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI

---

## Langkah 1: Buka BAS ✅

**Path:** Subaccount → Services → Instances and Subscriptions → SAP Business Application Studio

**Hasil:**
```
1. Navigasi ke: Services → Instances and Subscriptions
2. Ditemukan: SAP Business Application Studio (Subscriptions)
3. Klik "Go to Application" → BAS terbuka di tab baru
4. URL BAS: https://3220086dtrial.ap21.hana.ondemand.com/...
```

> **Catatan:** Jika BAS belum di-subscribe, klik "Create" di Instances and Subscriptions,
> pilih "SAP Business Application Studio" dengan plan "trial".

---

## Langkah 2: Buat Dev Space ✅

**Konfigurasi Dev Space:**

```
Dev Space Configuration:
━━━━━━━━━━━━━━━━━━━━━━━
  Name:     WorkshopTECRise
  Template: Full Stack Cloud Application
  
  Features yang termasuk:
  ✅ SAP CDS Language Support
  ✅ SAP Fiori Tools
  ✅ CAP Tools
  ✅ MTA Tools
  ✅ SAP HANA Tools
  ✅ HTML5 Application Template
  ✅ Launchpad Module
```

**Status Progression:**
```
1. Klik "Create Dev Space"           → Status: STARTING
2. Tunggu 2-3 menit                  → Status: RUNNING ✅
3. Klik nama Dev Space               → BAS IDE terbuka
```

---

## Langkah 3: Eksplorasi BAS IDE ✅

### Layout yang Ditemukan:

```
BAS IDE Layout:
┌───────────────────────────────────────────────────────┐
│  Menu Bar: File | Edit | View | Go | Run | Terminal   │
├──────────┬────────────────────────────────────────────┤
│          │                                            │
│ Explorer │         Editor Area                        │
│ (Files)  │   (Tab-based code editing)                 │
│          │                                            │
│ Search   │                                            │
│          │                                            │
│ SCM      ├────────────────────────────────────────────┤
│ (Git)    │                                            │
│          │         Terminal Panel                      │
│ Debug    │   $ _                                      │
│          │                                            │
│ Extns    │                                            │
├──────────┴────────────────────────────────────────────┤
│  Status Bar: Branch | Errors/Warnings | Port Forwarding│
└───────────────────────────────────────────────────────┘
```

### Verifikasi Tools di Terminal BAS:

```bash
user: user
$ node --version
v24.11.0

$ npm --version
11.6.1

$ cds --version
@sap/cds-dk: 9.8.3

$ cf --version
cf version 8.x.x (tergantung versi yang terinstall di BAS)
```

### Features yang Dieksplorasi:

| Feature | Lokasi | Status |
|---------|--------|--------|
| Explorer | Sidebar kiri (icon file) | ✅ File tree visible |
| Editor | Area tengah | ✅ Tab-based editing |
| Terminal | Panel bawah (Ctrl+`) | ✅ zsh/bash shell |
| Extensions | Sidebar kiri (icon kotak) | ✅ SAP extensions pre-installed |
| Source Control | Sidebar kiri (icon branch) | ✅ Git integration |
| Search | Sidebar kiri (icon search) | ✅ Workspace-wide search |
| Command Palette | Ctrl+Shift+P / Cmd+Shift+P | ✅ Quick commands |
| Port Forwarding | Status bar bawah | ✅ Untuk expose localhost ports |

---

## 📸 Catatan Screenshot

> **Instruksi untuk peserta:** Ambil screenshot berikut sebagai bukti:
> 1. Halaman Dev Space Manager (menunjukkan "WorkshopTECRise" dengan status RUNNING)
> 2. BAS IDE terbuka dengan Explorer, Editor, dan Terminal visible
> 3. Output `node --version` dan `cds --version` di terminal

---

**Kesimpulan:** BAS berhasil dibuka, Dev Space berhasil dibuat dengan template "Full Stack Cloud Application", dan IDE dapat digunakan dengan sempurna. Semua tools development (Node.js, npm, CDS CLI) tersedia di dalam BAS.
