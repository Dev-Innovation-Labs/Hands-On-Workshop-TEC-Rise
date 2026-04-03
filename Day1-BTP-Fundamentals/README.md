# 📘 Hari 1: SAP BTP Fundamentals & Setup Environment

> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Akun SAP BTP Trial, Browser modern (Chrome/Edge)

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 1, peserta mampu:
- Memahami arsitektur dan layanan utama SAP BTP
- Navigasi SAP BTP Cockpit dengan percaya diri
- Mengaktifkan dan mengkonfigurasi SAP Business Application Studio (BAS)
- Membuat project CAP pertama dan menjalankannya secara lokal
- Memahami konsep Cloud Foundry dalam konteks SAP BTP

---

## 📅 Jadwal Hari 1

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:30 | Opening & Perkenalan Workshop | 30 menit |
| 09:30 – 10:30 | **Teori: SAP BTP Overview** | 60 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: BTP Cockpit Navigation** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Teori + Demo: Business Application Studio** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: Setup CAP Project Pertama** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 📖 Materi Sesi 1: SAP BTP Overview

### Apa itu SAP Business Technology Platform?

SAP BTP adalah **platform cloud terpadu** yang menggabungkan:

```
SAP BTP
├── Database & Data Management    → SAP HANA Cloud, Data Intelligence
├── Analytics                     → SAP Analytics Cloud, Data Warehouse Cloud
├── Application Development       → CAP, BAS, Kyma
├── Automation                    → SAP Build Process Automation
├── Integration                   → SAP Integration Suite
└── AI & Machine Learning         → SAP AI Core, AI Launchpad
```

### Layanan Utama yang Digunakan dalam Workshop

| Layanan | Fungsi | Icon |
|---------|--------|------|
| **SAP BAS** | Cloud IDE untuk development | 💻 |
| **SAP HANA Cloud** | Database cloud enterprise | 🗄️ |
| **Cloud Foundry** | Runtime environment untuk app | ☁️ |
| **XSUAA** | Authentication & Authorization | 🔐 |
| **Destination Service** | Koneksi ke sistem external | 🔗 |
| **SAP Fiori Launchpad** | Portal UI enterprise | 🖥️ |

### Model Environment SAP BTP

```
Global Account
├── Sub Account (Region: US10)
│   ├── Space: Development
│   │   ├── App: bookshop-srv
│   │   ├── Service: HANA Cloud
│   │   └── Service: XSUAA
│   └── Space: Production
└── Sub Account (Region: EU10)
```

---

## 🛠️ Hands-on 1: Navigasi BTP Cockpit

### Langkah 1: Login ke BTP Cockpit

1. Buka browser → [https://account.hanatrial.ondemand.com](https://account.hanatrial.ondemand.com)
2. Login dengan S-user atau P-user SAP
3. Klik **"Go To Your Trial Account"**

### Langkah 2: Eksplorasi Global Account

```
Checklist Eksplorasi:
□ Temukan panel "Subaccounts"
□ Lihat "Entitlements" yang tersedia
□ Eksplorasi "Resource Providers"
□ Buka "Security > Users"
```

### Langkah 3: Masuk ke Subaccount Trial

1. Klik subaccount **"trial"**
2. Amati informasi:
   - Cloud Foundry Environment
   - Region yang digunakan
   - Quota yang tersedia

### Langkah 4: Aktifkan Services

Aktifkan entitlement berikut jika belum aktif:
```
Service Catalog → Search & Enable:
✅ SAP Business Application Studio  (plan: trial)
✅ SAP HANA Cloud                    (plan: trial)
✅ Authorization and Trust Management (plan: application)
```

---

## 🛠️ Hands-on 2: Business Application Studio (BAS)

### Langkah 1: Buka BAS

1. Di Subaccount → **Services → Instances and Subscriptions**
2. Klik **"SAP Business Application Studio"**
3. Klik **"Go to Application"**

### Langkah 2: Buat Dev Space

1. Klik **"Create Dev Space"**
2. Isi nama: `WorkshopTECRise`
3. Pilih template: **"Full Stack Cloud Application"**
4. Klik **"Create Dev Space"**
5. Tunggu hingga status **"RUNNING"** (2-3 menit)

### Langkah 3: Eksplorasi BAS IDE

```
BAS Layout:
├── Explorer (kiri)          → File tree
├── Editor (tengah)          → Code editor
├── Terminal (bawah)         → Command line
├── Extensions (kiri bawah)  → Plugin management
└── Source Control (kiri)    → Git integration
```

---

## 🛠️ Hands-on 3: CAP Project Pertama

### Langkah 1: Buka Terminal BAS

```bash
# Buka terminal: Terminal > New Terminal
# Verifikasi tools tersedia
node --version     # ≥ v18
npm --version      # ≥ 9
cds --version      # ≥ 7
```

### Langkah 2: Inisialisasi Project CAP

```bash
# Buat folder project
mkdir ~/projects/bookshop && cd ~/projects/bookshop

# Inisialisasi CAP project
cds init bookshop

# Masuk ke direktori project
cd bookshop

# Install dependencies
npm install

# Lihat struktur project
ls -la
```

### Struktur Project CAP yang Dihasilkan

```
bookshop/
├── app/                  ← SAP Fiori / UI apps
├── db/                   ← CDS data models & database
│   └── data-model.cds
├── srv/                  ← OData service definitions
│   └── cat-service.cds
├── package.json          ← NPM config & CAP settings
├── .cdsrc.json           ← CAP configuration
└── README.md
```

### Langkah 3: Jalankan CAP Server Pertama Kali

```bash
# Jalankan server dalam mode development
cds watch

# Output yang diharapkan:
# [cds] - model loaded from 1 file(s):
# [cds] - connect to db > sqlite { database: ':memory:' }
# [cds] - serving CatalogService { path: '/catalog' }
# [cds] - server listening on { url: 'http://localhost:4004' }
```

### Langkah 4: Akses CAP Welcome Page

1. BAS akan muncul notifikasi **"Open in New Tab"** → Klik
2. Atau klik port 4004 di status bar bawah
3. Eksplorasi **CAP Welcome Page** yang muncul

---

## 📝 Latihan Mandiri Hari 1

### Exercise 1.1: BTP Cockpit Exploration
Temukan dan screenshot:
- Total memory quota yang tersedia di CF environment
- Daftar services yang sudah di-subscribe

### Exercise 1.2: BAS Familiarization
Dalam BAS, coba:
1. Install extension **"SAP CDS Language Support"** dari Extension Marketplace
2. Buat file `hello.txt` di Explorer
3. Buka terminal dan jalankan `echo "Hello TEC Rise!"`

### Exercise 1.3: CAP First App
Modifikasi file `srv/cat-service.cds`:
```cds
service HelloService {
    function hello (name: String) returns String;
}
```
Lalu jalankan `cds watch` dan akses service di browser.

---

## 🔑 Key Concepts Hari 1

| Konsep | Definisi |
|--------|----------|
| **Global Account** | Satu level tertinggi dalam hierarki BTP |
| **Subaccount** | Unit deployment dengan environment sendiri |
| **Cloud Foundry Space** | Logical isolation untuk apps dan services |
| **Entitlement** | Izin untuk menggunakan suatu layanan |
| **CAP** | Framework opinionated untuk app development di BTP |
| **Dev Space** | Instance cloud IDE yang isolated di BAS |

---

## ❓ Q&A Topics Hari 1

1. Apa perbedaan BTP vs traditional SAP on-premise?
2. Kapan harus menggunakan Cloud Foundry vs Kyma?
3. Bagaimana model pricing SAP BTP?
4. Apa keuntungan BAS dibanding VS Code lokal?

---

## 📚 Referensi

- [SAP BTP Architecture](https://help.sap.com/docs/btp/sap-business-technology-platform/sap-business-technology-platform)
- [SAP BAS Getting Started](https://help.sap.com/docs/bas)
- [CAP Getting Started](https://cap.cloud.sap/docs/get-started/hello-world)
- [Cloud Foundry Concepts](https://docs.cloudfoundry.org/concepts/)

---

➡️ **Next:** [Hari 2 — Core Data Services (CDS)](../Day2-CDS-CoreDataServices/README.md)
