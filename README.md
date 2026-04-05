# 🚀 Hands-On Workshop: TEC Rise — SAP BTP Technical Bootcamp

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC  
> **Workshop Duration:** 4 Hari (Intensive)  
> **Level:** Intermediate – Advanced  
> **Target Audience:** SAP Developer, Technical Consultant, BTP Engineer  
> **Teknologi:** SAP BTP, CAP, CDS, OData, SAP Fiori, SAPUI5  
> **BTP Region:** Singapore - Azure (ap21) | **Org:** 3220086dtrial | **Space:** dev

---

## 📋 Deskripsi Workshop

Workshop ini dirancang untuk memberikan pengalaman langsung (hands-on) dalam membangun aplikasi enterprise modern menggunakan ekosistem **SAP Business Technology Platform (BTP)**. Peserta akan mempelajari dari BTP fundamentals, membangun UI dengan Fiori Elements, melakukan extensibility pada CAP application, hingga integration & deployment ke Cloud Foundry menggunakan **SAP Cloud Application Programming Model (CAP)**.

### 💡 Analogi Keseluruhan Workshop

> Bayangkan Anda membangun **restoran dari nol**:
>
> | Hari | Kegiatan | Analogi |
> |:-----|:---------|:--------|
> | **Hari 1** | BTP Fundamentals & Setup | **Sewa lokasi & siapkan dapur** — daftar akun BTP, aktifkan layanan, buat project pertama |
> | **Hari 2** | SAP Fiori & SAPUI5 | **Desain interior & menu** — bangun tampilan app yang profesional dengan Fiori Elements |
> | **Hari 3** | Extensibility & OData | **Tambah menu baru & atur pelayan** — extend model data, custom logic, test API |
> | **Hari 4** | Security & Deployment | **Buka restoran untuk umum** — pasang satpam (XSUAA), packing (MTA), kirim ke cloud (deploy) |
>
> Setiap hari memiliki **penjelasan dengan analogi dunia nyata** di awal materi,
> sehingga istilah-istilah baru seperti XSUAA, MTA, OData, CDS mudah dipahami.

---

## 🗓️ Planning 4 Hari Workshop

| Hari | Topik | Teknologi Utama |
|------|-------|------------------|
| [Hari 1](./Day1-BTP-Fundamentals/README.md) | SAP BTP Fundamentals & Setup Environment | BTP Cockpit, BAS, CF CLI, CAP |
| [Hari 2](./Day2-Fiori-UI5/README.md) | SAP Fiori & SAPUI5 — Build UI dari CAP Service | Fiori Elements, Annotations, SAPUI5 |
| [Hari 3](./Day3-Extensibility/README.md) | Extensibility — CDS, OData & Custom Logic | CDS Extend, Custom Handlers, OData v4 |
| [Hari 4](./Day4-Integration-Deployment/README.md) | Integration, Security & Deployment ke BTP | XSUAA, MTA, CF Deploy, Destination |

### 🗺️ Alur Belajar (Learning Path)

> **Cara baca:** Mulai dari Hari 1, ikuti panah ke Hari 4. Setiap hari menghasilkan output
> yang menjadi input hari berikutnya. **Jangan lompat** — materi saling bergantung.

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                        🗺️ ALUR WORKSHOP TEC RISE                           │
├──────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  📘 HARI 1: BTP Fundamentals                                                │
│  ┌────────────────────────────────────────────────────┐                      │
│  │ • Daftar akun BTP Trial                            │                      │
│  │ • Jelajahi BTP Cockpit (78 entitlements)            │                      │
│  │ • Setup BAS (cloud IDE)                             │                      │
│  │ • cds init bookshop → cds watch → OData jalan!     │                      │
│  │ • cf login → terhubung ke Cloud Foundry             │                      │
│  │                                                     │                      │
│  │ OUTPUT: CAP project bookshop + CF CLI connected     │                      │
│  └────────────────────┬───────────────────────────────┘                      │
│                       │                                                      │
│                       ▼                                                      │
│  📒 HARI 2: SAP Fiori & UI5                                                 │
│  ┌────────────────────────────────────────────────────┐                      │
│  │ • Pahami Fiori Elements (auto-generated UI)         │                      │
│  │ • Jalankan cds watch → Fiori app sudah ada!         │                      │
│  │ • Pelajari annotations (@UI.LineItem, etc)          │                      │
│  │ • Buka List Report & Object Page di browser         │                      │
│  │ • Custom SAPUI5 view (freestyle)                    │                      │
│  │                                                     │                      │
│  │ OUTPUT: Fiori app berjalan di atas CAP backend      │                      │
│  └────────────────────┬───────────────────────────────┘                      │
│                       │                                                      │
│                       ▼                                                      │
│  📗 HARI 3: Extensibility & OData                                            │
│  ┌────────────────────────────────────────────────────┐                      │
│  │ • extend entity Books (tambah field isbn, pages)    │                      │
│  │ • Buat entity baru: Reviews, Orders, OrderItems     │                      │
│  │ • Custom handlers (before/after/on)                 │                      │
│  │ • Test OData queries ($filter, $expand, $select)    │                      │
│  │ • Buat action submitOrder & function countBooks     │                      │
│  │                                                     │                      │
│  │ OUTPUT: Extended CAP app + custom logic + tested    │                      │
│  └────────────────────┬───────────────────────────────┘                      │
│                       │                                                      │
│                       ▼                                                      │
│  📕 HARI 4: Security & Deployment                                            │
│  ┌────────────────────────────────────────────────────┐                      │
│  │ • Konfigurasi XSUAA (roles & scopes)                │                      │
│  │ • Role-based access di CDS service                  │                      │
│  │ • Buat mta.yaml (deployment descriptor)             │                      │
│  │ • mbt build → .mtar file                            │                      │
│  │ • cf deploy → App jalan di cloud!                   │                      │
│  │ • Fiori Launchpad via Approuter + XSUAA login       │                      │
│  │ • S/4HANA integration & extensibility guide         │                      │
│  │                                                     │                      │
│  │ OUTPUT: App ter-deploy di SAP BTP Cloud Foundry 🚀  │                      │
│  └────────────────────────────────────────────────────┘                      │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### ✅ Setiap Hari Memiliki:

| Komponen | Deskripsi |
|:---------|:----------|
| **📖 Teori + Analogi** | Penjelasan setiap istilah baru dengan analogi dunia nyata |
| **🛠️ Hands-on** | Langkah demi langkah yang bisa diikuti (copy-paste command) |
| **✅ Hasil/Proof** | Output terminal & JSON response nyata (sudah dibuktikan berjalan) |
| **📝 Latihan Mandiri** | Exercise yang bisa dikerjakan sendiri |
| **📂 Folder handson/** | Dokumentasi lengkap bukti setiap hands-on berjalan |

---

## 🏗️ Arsitektur Aplikasi Workshop

```
┌─────────────────────────────────────────────────────────┐
│                  SAP BTP Cloud Foundry                  │
│                                                         │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────┐  │
│  │  SAP Fiori  │───▶│  CAP Server  │───▶│  HANA DB  │  │
│  │  (Frontend) │    │  (OData/REST)│    │  (Persist)│  │
│  └─────────────┘    └──────────────┘    └───────────┘  │
│         │                  │                            │
│         │           ┌──────────────┐                   │
│         └──────────▶│    XSUAA     │                   │
│                      │  (Auth/Authz)│                   │
│                      └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
```

---

## ⚙️ Pre-requisites

Sebelum mengikuti workshop, pastikan sudah memiliki:

### Akun & Tools
- [ ] SAP BTP Trial Account → [https://account.hanatrial.ondemand.com](https://account.hanatrial.ondemand.com)
- [ ] SAP Business Application Studio (BAS) aktif
- [ ] Node.js v18+ terinstall di local machine
- [ ] Git terinstall
- [ ] VS Code (opsional, untuk local development)

### Package yang Harus Diinstall
```bash
# Install SAP CAP CLI
npm install -g @sap/cds-dk
cds --version      # v9.8.3

# Install CF CLI
brew install cloudfoundry/tap/cf-cli@8   # macOS
cf --version       # v8.18.0

# Install MTA Build Tool
npm install -g mbt
mbt --version      # v1.2.45

# Install Yeoman & SAP Fiori Generator
npm install -g yo @sap/generator-fiori

# Install CF MultiApps Plugin
cf install-plugin multiapps -f

# Login ke CF (SAP BTP — sesuaikan dengan region Anda)
cf login -a https://api.cf.ap21.hana.ondemand.com
```

**✅ CF Login Terverifikasi:**
```
API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.215.0
user:           wahyu.amaldi@kpmg.co.id
org:            3220086dtrial
space:          dev
```

### Skills yang Direkomendasikan
- Dasar JavaScript / Node.js
- Pemahaman dasar REST API
- Dasar SQL
- Dasar HTML/CSS (untuk Hari 2 & 3)

---

## 📁 Struktur Repository

```
Hands-On-Workshop-TEC-Rise/
├── README.md                         ← 🏠 Anda di sini — mulai dari sini!
├── CHEATSHEET.md                     ← Quick reference commands
│
├── Day1-BTP-Fundamentals/            ← 📘 Hari 1: BTP Setup & CAP Init
│   ├── README.md                     ←    Materi + langkah-langkah
│   └── handson/                      ←    ✅ Bukti hands-on (9 dokumen)
│
├── Day2-Fiori-UI5/                   ← 📒 Hari 2: Fiori & SAPUI5
│   ├── README.md                     ←    Materi + langkah-langkah
│   └── handson/                      ←    ✅ Bukti hands-on (5 dokumen)
│
├── Day3-Extensibility/               ← 📗 Hari 3: CDS Extend & Custom Logic
│   ├── README.md                     ←    Materi + langkah-langkah
│   └── handson/                      ←    ✅ Bukti hands-on (3 dokumen)
│
├── Day4-Integration-Deployment/      ← 📕 Hari 4: XSUAA, MTA, Deploy
│   ├── README.md                     ←    Materi + langkah-langkah
│   └── handson/                      ←    ✅ Bukti hands-on (7 dokumen)
│
└── Final-Project/
    └── bookshop-app/                 ← 🏗️ Aplikasi bookshop lengkap
```

> **Cara navigasi:** Baca README.md di setiap folder Day secara berurutan (1 → 2 → 3 → 4).
> Setiap folder `handson/` berisi bukti bahwa setiap langkah sudah dijalankan dan berhasil.

---

## 🎯 Learning Outcomes

Setelah menyelesaikan workshop ini, peserta mampu:

1. **Navigasi SAP BTP Cockpit** dan memahami struktur layanan BTP (78 entitlements, CF environment)
2. **Membangun Fiori Elements app** dari CAP OData service (List Report, Object Page, Annotations)
3. **Extend aplikasi CAP** dengan CDS extensions, custom handlers, dan OData query
4. **Mengamankan aplikasi** dengan XSUAA dan role-based access control
5. **Build & Deploy MTA** ke SAP BTP Cloud Foundry (region ap21, Singapore-Azure)
6. **Integrasi** dengan external services via Destination Service

---

## 👨‍🏫 Facilitator & Author

| | |
|------|--------|
| **Nama** | **Wahyu Amaldi** |
| **Posisi** | Technical Lead SAP & Full Stack Development |
| **Sertifikasi** | SAP Certified — BTP, ABAP, Fiori, BDC |
| **Telepon** | 0881 0805 34116 |
| **Email** | wahyu.amaldi@kpmg.co.id |

---

## 📚 Referensi Utama

- [SAP CAP Documentation](https://cap.cloud.sap/docs/)
- [SAP Fiori Design Guidelines](https://experience.sap.com/fiori-design-web/)
- [SAPUI5 SDK](https://ui5.sap.com/)
- [SAP BTP Discovery Center](https://discovery-center.cloud.sap/)
- [OData.org Specification](https://www.odata.org/)
- [SAP Learning Journey - BTP](https://learning.sap.com/learning-journeys/deliver-side-by-side-extensibility-based-on-sap-btp)

---

> **Note:** Semua materi workshop ini bersifat hands-on. Ikuti setiap latihan secara berurutan untuk hasil belajar optimal.

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
