# 📘 Hari 1: SAP BTP Fundamentals & Setup Environment

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Akun SAP BTP Trial, Browser modern (Chrome/Edge)  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

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

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

Sebelum masuk ke materi teknis, pahami dulu istilah-istilah baru ini dengan analogi dunia nyata:

> **🏬 SAP BTP = Mall Teknologi Cloud**
>
> Bayangkan SAP BTP seperti **mall besar** yang menyediakan berbagai "toko" (layanan cloud).
> Anda tidak perlu membangun toko sendiri — cukup **sewa ruang** yang sudah disediakan.
>
> | Istilah BTP | Analogi Mall | Penjelasan |
> |:------------|:-------------|:-----------|
> | **Global Account** | Kontrak sewa mall | Level tertinggi, berisi semua subaccount Anda |
> | **Subaccount** | Lantai/zona di mall | Area terisolasi dengan region & budget sendiri |
> | **Entitlement** | Kartu member | Izin untuk menggunakan layanan tertentu (78 layanan di trial) |
> | **Service Instance** | Toko yang sudah buka | Layanan yang sudah aktif dan siap pakai |
> | **Cloud Foundry** | Ruang mesin di basement | Tempat app Anda berjalan (runtime engine) |
> | **Space (dev)** | Ruang workshop | Area kerja terisolasi (dev, staging, prod) |
> | **BAS** | Dapur profesional | Cloud IDE tempat Anda coding |
> | **CAP** | Buku resep masak | Framework/panduan untuk membuat app dengan best practices |
> | **CF CLI** | Remote control mesin | Alat command-line untuk mengontrol Cloud Foundry dari terminal |
> | **XSUAA** | Satpam + sistem ID card | Layanan autentikasi & otorisasi |
> | **Destination** | Buku alamat | Konfigurasi koneksi ke sistem external (S/4HANA, dll) |
>
> **Alur sederhana:**
> ```
> Anda (developer) → Login ke Mall (BTP Cockpit)
>   → Masuk lantai trial (Subaccount)
>     → Buka dapur (BAS) → Masak app (CAP)
>       → Nyalakan mesin (Cloud Foundry) → App jalan! 🚀
> ```

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
Global Account (3220086dtrial)
├── Subaccount: trial
│   ├── Region: Singapore - Azure (ap21)
│   ├── Provider: Microsoft Azure
│   ├── Environment: Multi-Environment
│   ├── Cloud Foundry
│   │   ├── API Endpoint: https://api.cf.ap21.hana.ondemand.com
│   │   ├── Org: 3220086dtrial
│   │   ├── Org Memory Limit: 4,096 MB
│   │   └── Space: dev
│   └── Kyma Runtime (opsional)
└── Entitlements: 78 services tersedia
```

> **Catatan:** Region menentukan data center tempat aplikasi dan data Anda dihosting.
> Pada trial account, region otomatis ditetapkan saat pendaftaran.
> Region **ap21 (Singapore - Azure)** berarti data center berada di Microsoft Azure, Singapore.

### BTP Trial Account — Informasi Penting

| Property | Contoh Nilai (Trial) |
|----------|----------------------|
| **Subdomain** | `3220086dtrial` |
| **Tenant ID** | `7c5b6655-7aa9-4763-acdd-41557f89b457` |
| **Subaccount ID** | `7c5b6655-7aa9-4763-acdd-41557f89b457` |
| **Provider** | Microsoft Azure |
| **Region** | Singapore - Azure (ap21) |
| **Environment** | Multi-Environment |
| **CF API Endpoint** | `https://api.cf.ap21.hana.ondemand.com` |
| **Org Name** | `3220086dtrial` |
| **Org Memory Limit** | 4,096 MB |
| **Space Default** | `dev` |
| **Entitlements** | 78 |
| **Used for Production** | No |

---

## 🛠️ Hands-on 1: Navigasi BTP Cockpit

### Langkah 1: Login ke BTP Cockpit

1. Buka browser → [https://account.hanatrial.ondemand.com](https://account.hanatrial.ondemand.com)
2. Login dengan S-user atau P-user SAP
3. Klik **"Go To Your Trial Account"**

### Langkah 2: Eksplorasi Global Account

```
Checklist Eksplorasi:
□ Temukan panel "Subaccounts" — klik pada subaccount "trial"
□ Lihat "Entitlements" — pastikan terlihat 78 entitlements
□ Buka "Security > Users" — verifikasi user Anda terdaftar
□ Cek "Usage Analytics" — lihat pemakaian resource saat ini
```

### Langkah 3: Masuk ke Subaccount Trial

1. Klik subaccount **"trial"**
2. Masuk ke tab **General**, amati informasi:
   - **Subdomain:** `3220086dtrial` (unik per akun)
   - **Region:** Singapore - Azure (ap21)
   - **Info:** 78 Entitlements, 2 Instances and Subscriptions
3. Masuk ke tab **Cloud Foundry Environment**, catat:
   - **API Endpoint:** `https://api.cf.ap21.hana.ondemand.com`
   - **Org Name:** `3220086dtrial`
   - **Org Memory Limit:** 4,096 MB
   - **Space:** `dev` (Applications: 0, Service Instances: 0)
4. Masuk ke tab **Entitlements**, amati layanan yang tersedia

> **Tips:** Tab **Entitlements** di Subaccount menampilkan semua service dan plan
> yang tersedia. Ini berbeda dari **Instances and Subscriptions** yang menampilkan
> service yang sudah aktif digunakan.

### Langkah 4: Aktifkan Services

Aktifkan entitlement berikut jika belum aktif:
```
Service Catalog → Search & Enable:
✅ SAP Business Application Studio  (plan: trial)
✅ SAP HANA Cloud                    (plan: hana-free)
✅ Authorization and Trust Management (plan: application)
✅ HTML5 Application Repository      (plan: app-host, app-runtime)
✅ Destination Service               (plan: lite)
```

### Langkah 5: Pahami Navigasi Menu BTP Cockpit

Di sidebar kiri Subaccount, terdapat menu-menu penting:

```
Subaccount Menu:
├── Overview              → Ringkasan subaccount (General, CF, Kyma, Entitlements)
├── Services
│   ├── Service Marketplace   → Katalog semua layanan yang bisa dipakai
│   └── Instances and Subscriptions → Layanan yang sudah aktif
├── Cloud Foundry
│   ├── Org Members           → User management di CF org
│   └── Spaces                → Manage spaces (dev, staging, prod)
├── HTML5 Applications        → List deployed HTML5/Fiori apps
├── Connectivity
│   ├── Destinations          → Konfigurasi koneksi ke sistem lain
│   └── Cloud Connectors      → Koneksi ke on-premise system
├── Security
│   ├── Users                 → User assignment & role collections
│   ├── Role Collections      → Definisi role-based access
│   └── Trust Configuration   → Identity Provider (IdP) setup
├── Entitlements              → Service plans & quota management
└── Usage Analytics           → Monitoring penggunaan resource
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
# Buka terminal: Terminal > New Terminal (atau Ctrl + `)
# Verifikasi tools tersedia
node --version     # ≥ v18 (aktual: v24.11.0)
npm --version      # ≥ 9  (aktual: 11.6.1)
cds --version      # ≥ 8  (aktual: @sap/cds-dk 9.8.3)
```

### Langkah 2: Inisialisasi Project CAP

```bash
# Buat folder project dan inisialisasi
mkdir -p ~/projects && cd ~/projects
cds init bookshop

# Masuk ke direktori project
cd bookshop

# Tentukan runtime (Node.js) dan tambahkan sample data
cds add nodejs
cds add sample

# Install dependencies
npm install

# Lihat struktur project
ls -la
```

> **Catatan CDS v9.x:** Sejak CDS v9, setelah `cds init` perlu menjalankan
> `cds add nodejs` untuk menentukan runtime, lalu `cds add sample` untuk
> menambahkan contoh data model (Books, Authors, Genres).

### Hasil Output `cds init`:

```
$ cds init bookshop
Successfully initialized CAP project
Continue with: code bookshop

$ cds add nodejs
Adding facet: nodejs
Successfully added features to your project

$ cds add sample
Adding facet: sample
Successfully added features to your project

$ npm install
added 109 packages, and audited 110 packages in 8s
found 0 vulnerabilities
```

### Struktur Project CAP yang Dihasilkan

```
bookshop/
├── app/                           ← SAP Fiori / UI applications
│   ├── fiori-apps.html
│   ├── common.cds
│   ├── services.cds
│   ├── browse/                    ← Fiori app: Book browsing
│   │   ├── fiori-service.cds
│   │   └── webapp/
│   ├── admin-books/               ← Fiori app: Book management
│   └── admin-authors/             ← Fiori app: Author management
├── db/                            ← Data models & seed data
│   ├── schema.cds                 ← Domain model (Books, Authors, Genres)
│   ├── currencies.cds
│   ├── sqlite/index.cds
│   ├── hana/index.cds
│   └── data/                      ← CSV seed data
│       ├── sap.capire.bookshop-Authors.csv
│       ├── sap.capire.bookshop-Books.csv
│       └── sap.capire.bookshop-Genres.csv
├── srv/                           ← OData service definitions & handlers
│   ├── cat-service.cds            ← CatalogService definition
│   ├── cat-service.js             ← CatalogService handler (JavaScript)
│   ├── admin-service.cds          ← AdminService definition
│   ├── admin-service.js           ← AdminService handler
│   └── access-control.cds         ← Role-based access control
├── _i18n/                         ← Internationalization
├── package.json                   ← NPM config & CAP settings
├── package-lock.json
└── readme.md
```

### package.json yang Dihasilkan:

```json
{
  "name": "bookshop",
  "version": "1.0.0",
  "dependencies": {
    "@sap/cds": "^9"
  },
  "devDependencies": {
    "@cap-js/sqlite": "^2"
  },
  "scripts": {
    "start": "cds-serve"
  }
}
```

### Langkah 3: Jalankan CAP Server Pertama Kali

```bash
# Jalankan server dalam mode development
cds watch
```

### Output yang Diharapkan (Actual Proven Output):

```
[cds] - loaded model from 15 file(s):

  srv/access-control.cds
  db/sqlite/index.cds
  app/services.cds
  app/genres/fiori-service.cds
  app/browse/fiori-service.cds
  app/admin-authors/fiori-service.cds
  srv/cat-service.cds
  app/genres/value-help.cds
  app/genres/tree-view.cds
  app/admin-books/fiori-service.cds
  srv/admin-service.cds
  app/common.cds
  db/schema.cds
  db/currencies.cds
  node_modules/@sap/cds/common.cds

[cds] - connect to db > sqlite { url: ':memory:' }
  > init from db/data/sap.common-Currencies.texts.csv
  > init from db/data/sap.common-Currencies.csv
  > init from db/data/sap.capire.bookshop-Genres.texts.csv
  > init from db/data/sap.capire.bookshop-Genres.csv
  > init from db/data/sap.capire.bookshop-Books.texts.csv
  > init from db/data/sap.capire.bookshop-Books.csv
  > init from db/data/sap.capire.bookshop-Authors.csv
/> successfully deployed to in-memory database.

[cds] - using auth strategy { kind: 'mocked' }
[cds] - serving AdminService {
  at: [ '/odata/v4/admin' ],
  decl: 'srv/admin-service.cds:3',
  impl: 'srv/admin-service.js'
}
[cds] - serving CatalogService {
  at: [ '/odata/v4/catalog' ],
  decl: 'srv/cat-service.cds:3',
  impl: 'srv/cat-service.js'
}
[cds] - server listening on { url: 'http://localhost:4004' }
[cds] - server v9.8.4 launched in 662 ms
```

### Langkah 4: Akses CAP Welcome Page & Test OData

1. BAS akan muncul notifikasi **"Open in New Tab"** → Klik
2. Atau klik port 4004 di status bar bawah
3. Eksplorasi **CAP Welcome Page** yang muncul

**Test OData Endpoints di browser:**

| URL | Hasil |
|-----|-------|
| `http://localhost:4004` | CAP Welcome Page (200 OK) |
| `http://localhost:4004/odata/v4/catalog/Books` | JSON dengan 5 buku (200 OK) |
| `http://localhost:4004/odata/v4/catalog/Books?$top=3` | 3 buku pertama (200 OK) |
| `http://localhost:4004/odata/v4/admin/Authors` | 401 Unauthorized (access control aktif) |

**Contoh Response GET /odata/v4/catalog/Books:**

```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    { "ID": 201, "author": "Emily Brontë", "title": "Wuthering Heights", "stock": 12, "price": 11.11, "currency_code": "GBP" },
    { "ID": 207, "author": "Charlotte Brontë", "title": "Jane Eyre", "stock": 11, "price": 12.34, "currency_code": "GBP" },
    { "ID": 251, "author": "Edgar Allen Poe", "title": "The Raven", "stock": 333, "price": 13.13, "currency_code": "USD" },
    { "ID": 252, "author": "Edgar Allen Poe", "title": "Eleonora", "stock": 555, "price": 14.00, "currency_code": "USD" },
    { "ID": 271, "author": "Richard Carpenter", "title": "Catweazle", "stock": 22, "price": 150.00, "currency_code": "JPY" }
  ]
}
```

---

## 📝 Latihan Mandiri Hari 1

### Exercise 1.1: BTP Cockpit Exploration
Temukan dan screenshot:
- Total memory quota yang tersedia di CF environment (seharusnya **4,096 MB**)
- Daftar services yang sudah di-subscribe (tab **Instances and Subscriptions**)
- Jumlah total entitlements yang tersedia (seharusnya **78**)
- Region dan API Endpoint Cloud Foundry

### Exercise 1.2: Entitlements Deep Dive
Dari halaman Entitlements di Subaccount, identifikasi:
1. Service yang berhubungan dengan **Database** (contoh: SAP HANA Cloud, SAP HANA Schemas & HDI Containers)
2. Service yang berhubungan dengan **Security** (contoh: Authorization and Trust Management, Cloud Identity Services)
3. Service yang berhubungan dengan **Integration** (contoh: Integration Suite, Connectivity Service)
4. Service yang berhubungan dengan **Application Runtime** (contoh: Cloud Foundry Runtime, Kyma Runtime)

### Exercise 1.3: CF CLI Login
Di terminal BAS atau lokal:
```bash
# Login ke Cloud Foundry (sesuaikan API endpoint dengan region akun Anda)
cf login -a https://api.cf.ap21.hana.ondemand.com

# Masukkan email dan password SAP
# Pilih org: 3220086dtrial (sesuai akun Anda)
# Pilih space: dev

# Verifikasi
cf target
cf spaces
cf apps
cf services
```

**✅ Hasil yang Diharapkan (Proven Output):**

```
$ cf login -a https://api.cf.ap21.hana.ondemand.com
API endpoint: https://api.cf.ap21.hana.ondemand.com

Email: wahyu.amaldi@kpmg.co.id
Password:

Authenticating...
OK

Targeted org 3220086dtrial.

Targeted space dev.

API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.215.0
user:           wahyu.amaldi@kpmg.co.id
org:            3220086dtrial
space:          dev
```

> **💡 Analogi:** `cf login` seperti **login ke remote control mesin**.
> Setelah login, Anda bisa mengontrol Cloud Foundry dari terminal —
> deploy app, cek log, monitoring — tanpa harus buka BTP Cockpit.

### Exercise 1.4: BAS Familiarization
Dalam BAS, coba:
1. Install extension **"SAP CDS Language Support"** dari Extension Marketplace
2. Buat file `hello.txt` di Explorer
3. Buka terminal dan jalankan `echo "Hello TEC Rise!"`
4. Jalankan `cf target` untuk memverifikasi koneksi CF

### Exercise 1.5: CAP First App
Jalankan `cds watch` dan verifikasi:
1. Server berhasil start dengan output `server listening on { url: 'http://localhost:4004' }`
2. Buka `http://localhost:4004` — CAP Welcome Page tampil
3. Buka `http://localhost:4004/odata/v4/catalog/Books` — Data 5 buku muncul dalam JSON
4. Buka `http://localhost:4004/odata/v4/catalog/Books?$top=3` — Hanya 3 buku (OData query bekerja)
5. Buka `http://localhost:4004/odata/v4/admin/Authors` — 401 Unauthorized (security bekerja)

**Bonus:** Buat service baru `srv/hello-service.cds`:
```cds
service HelloService {
    function hello (name: String) returns String;
}
```
Buat handler `srv/hello-service.js`:
```js
module.exports = function () {
    this.on('hello', (req) => {
        return `Hello, ${req.data.name}! Welcome to TEC Rise Workshop!`;
    });
};
```
Restart `cds watch` dan akses `http://localhost:4004/odata/v4/hello/hello(name='World')`.

---

## 🔑 Key Concepts Hari 1

| Konsep | Penjelasan | Analogi |
|--------|----------|---------|
| **Global Account** | Level tertinggi dalam hierarki BTP | Kontrak sewa mall |
| **Subaccount** | Unit deployment dengan region & quota sendiri | Lantai/zona di mall |
| **Cloud Foundry Space** | Isolasi logis untuk apps (dev, staging, prod) | Ruang workshop terpisah |
| **Entitlement** | Izin + quota untuk menggunakan layanan BTP | Kartu member toko |
| **Service Plan** | Varian spesifik dari service (free, trial, standard) | Paket langganan (basic, premium) |
| **Service Instance** | Instansi aktif layanan yang siap dipakai | Toko yang sudah buka |
| **Subscription** | Layanan SaaS diakses via URL (BAS, Launchpad) | Langganan Netflix (tinggal pakai) |
| **CAP** | Cloud Application Programming — framework app dev | Buku resep masak standar |
| **Dev Space** | Instance cloud IDE di BAS | Dapur profesional Anda sendiri |
| **CF API Endpoint** | URL untuk berkomunikasi dengan Cloud Foundry | Nomor telepon ruang mesin |
| **Org** | Unit organisasi di CF, biasanya 1:1 dengan subaccount | Departemen di perusahaan |
| **CF CLI** | Command-line tool untuk kontrol Cloud Foundry | Remote control mesin |

---

## 📋 Referensi Entitlements BTP Trial

Berikut daftar lengkap **78 entitlements** yang tersedia pada akun BTP Trial (per April 2026):

### 🗄️ Database & Data Management
| Service | Plan | Quota |
|---------|------|-------|
| SAP HANA Cloud | hana-free | 1 |
| SAP HANA Cloud | relational-data-lake-free | 1 |
| SAP HANA Cloud | hana-cloud-connection-free | 1 |
| SAP HANA Cloud | tools | 1 |
| SAP HANA Schemas & HDI Containers | hdi-shared | 10 |
| SAP HANA Schemas & HDI Containers | schema | 10 |
| SAP HANA Schemas & HDI Containers | sbss | 10 |
| SAP HANA Schemas & HDI Containers | securestore | 10 |
| PostgreSQL, Hyperscaler Option | trial | 1 |
| Redis, Hyperscaler Option | trial | 1 |
| Credential Store | proxy | 1 |
| Credential Store | trial | 1 |

### ☁️ Runtime & Application
| Service | Plan | Quota |
|---------|------|-------|
| Cloud Foundry Environment | Trial | 1 |
| Cloud Foundry Runtime | MEMORY | 4 (GB) |
| Kyma Runtime | Kyma Runtime Trial | 1 |
| ABAP environment | Shared | 1 |
| Serverless Runtime | default | 1 |
| Serverless Runtime | odpruntime | 1 |
| Application Autoscaler | standard | 1 |

### 🔐 Security & Identity
| Service | Plan | Quota |
|---------|------|-------|
| Authorization and Trust Management Service | application | 1 |
| Authorization and Trust Management Service | broker | 1 |
| Authorization and Trust Management Service | space | 1 |
| Authorization and Trust Management Service | apiaccess | 1 |
| Cloud Identity Services | default | 1 |
| Cloud Identity Services | application | 1 |

### 🔗 Integration & Connectivity
| Service | Plan | Quota |
|---------|------|-------|
| Integration Suite | Trial | 1 |
| SAP Process Integration Runtime | integration-flow | 2 |
| SAP Process Integration Runtime | api | 1 |
| Connectivity Service | lite | 1 |
| Connectivity Service | connectivity_proxy | 1 |
| Destination Service | lite | 1 |

### 🖥️ UI & Frontend
| Service | Plan | Quota |
|---------|------|-------|
| SAP Build Work Zone, standard edition | standard | 100 + 1 |
| HTML5 Application Repository Service | app-host | 1 |
| HTML5 Application Repository Service | app-runtime | 1 |
| UI5 flexibility for key users | trial | 1 |
| UI Theme Designer | standard | 5 |
| Application Frontend Service | Developer | 1 |
| SAP Dynamic Forms Trial | Trial Plan | 1 |

### 🛠️ DevOps & Management
| Service | Plan | Quota |
|---------|------|-------|
| SAP Business Application Studio | trial | 1 |
| Continuous Integration & Delivery | Trial | 1 |
| Cloud Transport Management | Lite | 1 |
| Cloud Transport Management | standard | 1 |
| Cloud Management Service | local / central / viewer | Multiple |
| Service Manager | subaccount-audit / admin / container | Multiple |
| Automation Pilot | free | 1 |
| Job Scheduling Service | lite / free | 1 |

### 📊 Monitoring & Analytics
| Service | Plan | Quota |
|---------|------|-------|
| Feature Flags Service | dashboard | 1 |
| Feature Flags Service | lite | 1 |
| Alert Notification | standard | 1 |
| Application Logging Service | lite | 1 |
| Audit Log Management Service | Default | 1 |
| Audit Log Viewer Service | Free | 1 |
| Usage Data Management Service | reporting-ga-admin | 10 |

### 🤖 Automation & Other
| Service | Plan | Quota |
|---------|------|-------|
| SAP Build Process Automation | free / standard | 1 |
| Mobile Services | lite | 1 |
| Content Agent Service | free / application / standard | 1 |
| SaaS Provisioning Service | application | 1 |
| API Management, API portal | Multiple plans | 1 |
| API Management, developer portal | devportal-apiaccess | 1 |
| SAP Omnichannel Promotion Pricing | trial | 1 |

> **Tips:** Entitlements pada Trial account sudah otomatis di-assign. Pada account produktif,
> admin harus secara manual meng-assign entitlements ke setiap subaccount.

---

## ❓ Q&A Topics Hari 1

1. Apa perbedaan BTP vs traditional SAP on-premise?
2. Kapan harus menggunakan Cloud Foundry vs Kyma?
3. Bagaimana model pricing SAP BTP? Apa bedanya Trial vs Free Tier vs CPEA?
4. Apa keuntungan BAS dibanding VS Code lokal?
5. Mengapa Region penting dan apa dampaknya terhadap latency?
6. Apa perbedaan **Entitlements** vs **Instances and Subscriptions**?
7. Apa itu Multi-Environment dan kapan kita butuh Kyma?
8. Bagaimana cara menambahkan Entitlements baru ke subaccount?

---

## 📂 Hasil Hands-on

Semua hasil hands-on dan exercise didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|-----------|
| [Hands-on 1: BTP Cockpit](./handson/handson-1-btp-cockpit.md) | Navigasi BTP Cockpit & eksplorasi subaccount |
| [Hands-on 2: BAS Setup](./handson/handson-2-bas-setup.md) | Setup Business Application Studio |
| [Hands-on 3: CAP Project](./handson/handson-3-cap-project.md) | Inisialisasi & jalankan CAP project pertama |
| [Exercise 1.1](./handson/exercise-1.1-cockpit-exploration.md) | BTP Cockpit Exploration |
| [Exercise 1.2](./handson/exercise-1.2-entitlements-deep-dive.md) | Entitlements Deep Dive (78 services) |
| [Exercise 1.3](./handson/exercise-1.3-cf-cli-login.md) | CF CLI Login |
| [Exercise 1.4](./handson/exercise-1.4-bas-familiarization.md) | BAS Familiarization |
| [Exercise 1.5](./handson/exercise-1.5-cap-first-app.md) | CAP First App (OData proof) |

---

## 📚 Referensi

- [SAP BTP Architecture](https://help.sap.com/docs/btp/sap-business-technology-platform/sap-business-technology-platform)
- [SAP BAS Getting Started](https://help.sap.com/docs/bas)
- [CAP Getting Started](https://cap.cloud.sap/docs/get-started/hello-world)
- [Cloud Foundry Concepts](https://docs.cloudfoundry.org/concepts/)
- [BTP Trial Account Signup](https://account.hanatrial.ondemand.com)
- [SAP BTP Regions & Endpoints](https://help.sap.com/docs/btp/sap-business-technology-platform/regions)
- [CF CLI Reference](https://docs.cloudfoundry.org/cf-cli/cf-help.html)
- [SAP BTP Service Plans](https://discovery-center.cloud.sap/serviceCatalog)

---

➡️ **Next:** [Hari 2 — SAP Fiori & UI5](../Day2-Fiori-UI5/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
