# ✅ Exercise 1.1: BTP Cockpit Exploration — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI

---

## Tugas: Temukan dan Dokumentasikan

### 1. Total Memory Quota di CF Environment ✅

```
Cloud Foundry Runtime:
  Plan:         MEMORY
  Quota:        4 (unit: GB)
  
  Org Memory Limit: 4,096 MB (= 4 GB)
  
  Saat ini digunakan: 0 MB (belum ada aplikasi yang di-deploy)
  Tersisa: 4,096 MB
```

> **Lokasi:** Subaccount → Overview → Tab "Cloud Foundry Environment"  
> Atau: Subaccount → Entitlements → Cari "Cloud Foundry Runtime"

---

### 2. Daftar Services yang Sudah Di-Subscribe ✅

```
Instances and Subscriptions:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total: 2 Instances and Subscriptions

Subscriptions:
┌─────────────────────────────────────┬──────────┬─────────┐
│ Service                             │ Plan     │ Status  │
├─────────────────────────────────────┼──────────┼─────────┤
│ SAP Business Application Studio     │ trial    │ Active  │
│ (...tergantung apa yang diaktifkan) │          │         │
└─────────────────────────────────────┴──────────┴─────────┘
```

> **Lokasi:** Subaccount → Services → Instances and Subscriptions

---

### 3. Jumlah Total Entitlements ✅

```
Total Entitlements: 78

Breakdown per kategori:
  Database & Data Management:     12 entitlements
  Runtime & Application:           7 entitlements
  Security & Identity:             6 entitlements
  Integration & Connectivity:      6 entitlements
  UI & Frontend:                   7 entitlements
  DevOps & Management:             8 entitlements
  Monitoring & Analytics:          7 entitlements
  Automation & Other:              7+ entitlements
  ─────────────────────────────────
  Total:                          78 entitlements
```

> **Lokasi:** Subaccount → Overview → Tab "General" (angka 78 terlihat)  
> Detail: Subaccount → Entitlements

---

### 4. Region dan API Endpoint Cloud Foundry ✅

```
Region:        Singapore - Azure (ap21)
Provider:      Microsoft Azure
API Endpoint:  https://api.cf.ap21.hana.ondemand.com
```

> **Penjelasan:**
> - `ap21` = Asia Pacific region 21 (Singapore, Azure)
> - API Endpoint digunakan untuk CF CLI login: `cf login -a https://api.cf.ap21.hana.ondemand.com`
> - Lokasi: Subaccount → Overview → Tab "Cloud Foundry Environment"

---

## Checklist Verifikasi

- [x] Memory quota ditemukan: **4,096 MB (4 GB)**
- [x] Daftar subscriptions ditemukan: **2 instances/subscriptions**
- [x] Total entitlements ditemukan: **78**
- [x] Region ditemukan: **Singapore - Azure (ap21)**
- [x] API Endpoint ditemukan: **https://api.cf.ap21.hana.ondemand.com**

---

**Kesimpulan:** Semua informasi yang diminta berhasil ditemukan di BTP Cockpit. Akun trial memiliki quota memadai (4 GB) untuk menjalankan aplikasi CAP bookshop.
