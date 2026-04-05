# ✅ Hands-on 1: Navigasi BTP Cockpit — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI

---

## Langkah 1: Login ke BTP Cockpit ✅

**URL:** https://account.hanatrial.ondemand.com

**Hasil:**
- Login berhasil menggunakan akun SAP
- Redirect ke BTP Cockpit Global Account: **3220086dtrial**
- Breadcrumb: `Trial Home / 3220086dtrial / trial`

---

## Langkah 2: Eksplorasi Global Account ✅

**Checklist Eksplorasi:**

- [x] Temukan panel "Subaccounts" — **Terlihat subaccount "trial"**
- [x] Lihat "Entitlements" — **78 entitlements tersedia**
- [x] Buka "Security > Users" — **User terdaftar dan aktif**
- [x] Cek "Usage Analytics" — **Pemakaian resource: 0 (belum ada deployment)**

---

## Langkah 3: Masuk ke Subaccount Trial ✅

### Tab General — Informasi yang Ditemukan:

```
Subaccount: trial - Overview
━━━━━━━━━━━━━━━━━━━━━━━━━━━━

General:
  78 Entitlements
  2  Instances and Subscriptions

  Subdomain:           3220086dtrial
  Tenant ID:           7c5b6655-7aa9-4763-acdd-41557f89b457
  Subaccount ID:       7c5b6655-7aa9-4763-acdd-41557f89b457
  Provider:            Microsoft Azure
  Region:              Singapore - Azure
  Environment:         Multi-Environment
  Used for Production: No
  Beta Features:       Disabled
  Created On:          April 5, 2026, 8:49:28 PM GMT+07:00
  Modified On:         April 5, 2026, 8:49:53 PM GMT+07:00
```

### Tab Cloud Foundry Environment:

```
Cloud Foundry Environment:
  API Endpoint:      https://api.cf.ap21.hana.ondemand.com
  Org Name:          3220086dtrial
  Org ID:            9a702ac6-b684-4ad8-85b9-069c88fecb7c
  Org Memory Limit:  4,096MB

  Spaces (1):
  ┌──────┬──────────────┬───────────────────┐
  │ Name │ Applications │ Service Instances  │
  ├──────┼──────────────┼───────────────────┤
  │ dev  │      0       │         0         │
  └──────┴──────────────┴───────────────────┘
```

### Tab Kyma Environment:

```
Status: "You are currently not using Kyma capabilities."
→ Kyma belum diaktifkan (opsional untuk workshop ini)
```

### Tab Entitlements:

```
Total: 78 entitlements tersedia
Mencakup: SAP HANA Cloud, Cloud Foundry Runtime, BAS, XSUAA, dll.
(Detail lengkap lihat Exercise 1.2)
```

---

## Langkah 4: Aktifkan Services ✅

**Verifikasi Entitlements yang Dibutuhkan:**

| Service | Plan | Status |
|---------|------|--------|
| SAP Business Application Studio | trial | ✅ Tersedia (quota: 1) |
| SAP HANA Cloud | hana-free | ✅ Tersedia (quota: 1) |
| Authorization and Trust Management | application | ✅ Tersedia (quota: 1) |
| HTML5 Application Repository | app-host | ✅ Tersedia (quota: 1) |
| HTML5 Application Repository | app-runtime | ✅ Tersedia (quota: 1) |
| Destination Service | lite | ✅ Tersedia (quota: 1) |

> Semua entitlement yang dibutuhkan untuk workshop sudah tersedia di trial account.

---

## Langkah 5: Pahami Navigasi Menu BTP Cockpit ✅

**Menu yang dieksplorasi di sidebar kiri:**

| Menu | Sub-menu | Ditemukan |
|------|----------|-----------|
| Overview | General, CF, Kyma, Entitlements tabs | ✅ |
| Services | Service Marketplace | ✅ |
| Services | Instances and Subscriptions | ✅ |
| Cloud Foundry | Org Members | ✅ |
| Cloud Foundry | Spaces (dev) | ✅ |
| HTML5 Applications | (kosong, belum deploy) | ✅ |
| Connectivity | Destinations | ✅ |
| Connectivity | Cloud Connectors | ✅ |
| Security | Users | ✅ |
| Security | Role Collections | ✅ |
| Security | Trust Configuration | ✅ |
| Entitlements | 78 services | ✅ |
| Usage Analytics | Dashboard | ✅ |

---

## 📸 Catatan Screenshot

> **Instruksi untuk peserta:** Ambil screenshot berikut sebagai bukti:
> 1. Halaman Overview subaccount (tab General)
> 2. Tab Cloud Foundry Environment
> 3. Tab Entitlements
> 4. Halaman Services > Instances and Subscriptions
> 5. Halaman Security > Users

---

**Kesimpulan:** Semua langkah Hands-on 1 berhasil dilaksanakan. BTP Cockpit dapat diakses dan dinavigasi dengan baik. Semua informasi subaccount trial terverifikasi sesuai dengan yang diharapkan.
