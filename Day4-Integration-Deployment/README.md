# 📕 Hari 4: Security, Integration & Deployment ke SAP BTP

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 1–3, memiliki akses BTP dengan CF environment aktif  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 4, peserta mampu:
- Mengkonfigurasi XSUAA untuk authentication & authorization
- Implementasi role-based access control (RBAC) di CAP
- Membuat Multi-Target Application (MTA) descriptor
- Deploy aplikasi ke SAP BTP Cloud Foundry
- Connect ke SAP S/4HANA menggunakan Destination Service
- Monitoring dan troubleshooting aplikasi di BTP

---

## 📅 Jadwal Hari 4

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 3 | 15 menit |
| 09:15 – 10:30 | **Teori: XSUAA & Security di BTP** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: XSUAA Setup & RBAC** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: MTA Descriptor & Build** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:00 | **Hands-on: Deploy ke BTP CF** | 75 menit |
| 16:00 – 16:30 | **Demo: Destination & Integration** | 30 menit |
| 16:30 – 17:00 | Workshop Closing & Sertifikat | 30 menit |

---

## 📖 Materi Sesi 1: XSUAA & Security

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

Hari 4 adalah hari terakhir. Kita akan mengamankan dan men-deploy app ke cloud.
Banyak istilah baru — mari pahami dulu:

> **🏢 Deployment = Pindah dari Dapur Rumah ke Restoran Sungguhan**
>
> Selama 3 hari kita memasak ("develop") di dapur sendiri (localhost).
> Sekarang waktunya **buka restoran** (deploy ke BTP Cloud Foundry) — butuh:
> - **Satpam & ID card** (XSUAA) — siapa boleh masuk, siapa boleh pesan
> - **Kontainer pengiriman** (MTA) — bungkus semua (app, DB, security) jadi satu paket
> - **Truk kirim** (`cf deploy`) — kirim paket ke cloud
>
> | Istilah | Analogi | Penjelasan |
> |:--------|:--------|:-----------|
> | **XSUAA** | Satpam + mesin ID card | Layanan OAuth 2.0 yang verifikasi user & beri izin akses |
> | **Scope** | Izin akses ruangan | Granular permission: "boleh baca", "boleh tulis", "boleh admin" |
> | **Role** | Bundel kunci ruangan | Kumpulan scopes (misal: role "Editor" = scope read + write) |
> | **Role Collection** | Gantungan kunci karyawan | Kumpulan roles yang di-assign ke user tertentu |
> | **JWT Token** | Kartu akses gedung | Token digital berisi info user + izin-izinnya |
> | **MTA** | Kontainer kargo (Multi-Target App) | Satu paket berisi: backend, DB, frontend, security config |
> | **`mta.yaml`** | Daftar isi kontainer | File YAML yang mendefinisikan semua modul & resource |
> | **`mbt build`** | Packing kontainer | Compile & bundle semua modul jadi 1 file `.mtar` |
> | **`cf deploy`** | Kirim kontainer ke cloud | Upload & deploy `.mtar` ke Cloud Foundry |
> | **HDI Container** | Ruang dapur di restoran | Isolated database schema di HANA Cloud |
> | **Approuter** | Resepsionis restoran | Reverse proxy yang arahkan request ke backend yang benar |
> | **Destination** | Buku alamat pemasok | Konfigurasi koneksi ke sistem external (S/4HANA, dll) |
>
> **Alur Deploy:**
> ```
> xs-security.json (siapa boleh apa)
>   + mta.yaml (daftar isi kontainer)
>     → mbt build → bookshop.mtar (kontainer siap kirim)
>       → cf login (buka pintu gerbang cloud)
>         → cf deploy (kirim kontainer)
>           → App jalan di cloud! 🚀
> ```
>
> **Alur Security saat User Akses App:**
> ```
> User buka browser → Approuter → "Belum login!"
>   → Redirect ke XSUAA → User login (email/password)
>     → XSUAA kasih JWT token (isinya: user=wahyu, roles=[Admin])
>       → Approuter forward ke CAP backend + token
>         → CAP cek token: "Admin? OK, boleh akses AdminService"
>           → Response! ✅
> ```

### Apa itu XSUAA?

**XSUAA (Extended Services for User Account and Authentication)** adalah layanan OAuth 2.0 di SAP BTP yang menyediakan:

```
XSUAA Functions:
├── Authentication   → Verify identitas user (SSO, SAML, OAuth)
├── Authorization    → Role-based access control
├── Token Issuance   → JWT token untuk service-to-service
└── Scope Management → Fine-grained permission control
```

### OAuth 2.0 Flow di SAP BTP

```
User Browser
     │
     │ 1. Login Request
     ▼
  XSUAA (IDP)
     │
     │ 2. JWT Token (with scopes & roles)
     ▼
  CAP Backend
     │
     │ 3. Validate Token
     │ 4. Check Scopes
     ▼
  Response
```

### Roles vs Scopes vs Role Collections

```
Scope          = Granular izin (com.tecrise.bookshop.read)
Role           = Kumpulan scopes (Viewer, Admin)
Role Collection = Kumpulan roles yang di-assign ke user

User → Role Collection → Roles → Scopes
```

---

## 🛠️ Hands-on 1: XSUAA Configuration

> **💡 Analogi:** `xs-security.json` seperti **daftar siapa boleh masuk ruangan apa**.
> Di dalamnya Anda mendefinisikan:
> - **Scopes** = daftar izin (baca, tulis, admin)
> - **Role templates** = bundel izin (Viewer=baca, Editor=baca+tulis)
> - **Role collections** = gantungan kunci yang di-assign ke user

### File: `xs-security.json`

```json
{
    "xsappname": "bookshop-tecrise",
    "tenant-mode": "dedicated",
    "description": "Security config for TEC Rise Bookshop",
    "scopes": [
        {
            "name": "$XSAPPNAME.read",
            "description": "Can read books and orders"
        },
        {
            "name": "$XSAPPNAME.write",
            "description": "Can create and update books"
        },
        {
            "name": "$XSAPPNAME.admin",
            "description": "Full administrative access"
        }
    ],
    "attributes": [
        {
            "name": "Region",
            "description": "User's regional access",
            "valueType": "string"
        }
    ],
    "role-templates": [
        {
            "name": "Viewer",
            "description": "Read-only access to catalog",
            "scope-references": ["$XSAPPNAME.read"],
            "attribute-references": ["Region"]
        },
        {
            "name": "Editor",
            "description": "Can read and edit books",
            "scope-references": [
                "$XSAPPNAME.read",
                "$XSAPPNAME.write"
            ]
        },
        {
            "name": "Administrator",
            "description": "Full access",
            "scope-references": [
                "$XSAPPNAME.read",
                "$XSAPPNAME.write",
                "$XSAPPNAME.admin"
            ]
        }
    ],
    "role-collections": [
        {
            "name": "Bookshop_Viewer",
            "description": "Bookshop read-only users",
            "role-template-references": [
                "$XSAPPNAME.Viewer"
            ]
        },
        {
            "name": "Bookshop_Admin",
            "description": "Bookshop administrators",
            "role-template-references": [
                "$XSAPPNAME.Administrator"
            ]
        }
    ]
}
```

### Integrasi XSUAA ke CAP (`package.json`)

```json
{
    "cds": {
        "requires": {
            "auth": {
                "kind": "xsuaa"
            },
            "db": {
                "kind": "hana",
                "[development]": {
                    "kind": "sqlite",
                    "database": "db/bookshop.db"
                }
            }
        }
    }
}
```

---

## 🛠️ Hands-on 2: Role-Based Access di Service Layer

> **💡 Analogi:** Ini seperti memasang **papan "Staff Only"** di pintu-pintu tertentu.
> - `@requires: 'authenticated-user'` = "Harus login dulu"
> - `@requires: 'admin'` = "Khusus admin"
> - `@readonly` = "Boleh lihat, tapi jangan sentuh"

### Update `srv/catalog-service.cds`

```cds
using { com.tecrise.bookshop as db } from '../db/schema';

// Require authentication untuk semua service
@requires: 'authenticated-user'
service CatalogService @(path:'/catalog') {

    // Semua user authenticated bisa baca
    @readonly
    entity Books as projection on db.Books;

    @readonly
    entity Authors as projection on db.Authors;

    // Hanya user dengan scope 'write' bisa submit order
    @(requires: 'write')
    action submitOrder(bookID: UUID, amount: Integer) returns {
        orderID: UUID;
        status : String;
    };
}

// Admin service - hanya user dengan scope 'admin'
@requires: 'admin'
service AdminService @(path:'/admin') {
    entity Books   as projection on db.Books;
    entity Authors as projection on db.Authors;
    entity Orders  as projection on db.Orders;
}
```

### Mengakses User Info di Handler

```javascript
// srv/catalog-service.js
this.on('submitOrder', async (req) => {
    // Cek user info dari token
    const user = req.user;
    
    console.log('User ID:', user.id);
    console.log('User Tenant:', user.tenant);
    console.log('Has admin scope:', user.is('admin'));
    console.log('Has write scope:', user.is('write'));
    
    // Attribute-based access control
    const userRegion = user.attr?.Region;
    if (userRegion && userRegion !== 'APAC') {
        req.reject(403, 'Access restricted to APAC region only');
    }
    
    // ...rest of implementation
});
```

---

## 🛠️ Hands-on 3: MTA Descriptor

> **💡 Analogi:** `mta.yaml` seperti **daftar isi kontainer kargo**.
> Bayangkan Anda mengirim seluruh restoran ke lokasi baru:
> - **Modules** = barang yang dikirim (dapur/backend, meja/frontend, alat keamanan/db-deployer)
> - **Resources** = layanan yang dibutuhkan di lokasi baru (listrik/HANA, satpam/XSUAA)
> - **Requires/Provides** = kabel yang menghubungkan semuanya

### File: `mta.yaml`

```yaml
_schema-version: '3.1'
ID: bookshop-tecrise
version: 1.0.0
description: TEC Rise Bookshop Application
parameters:
  enable-parallel-deployments: true

# ============================================
# BUILD PARAMETERS
# ============================================
build-parameters:
  before-all:
    - builder: custom
      commands:
        - npx cds build --production

# ============================================
# MODULES (Deployable units)
# ============================================
modules:

  # --- 1. CAP Backend Service ---
  - name: bookshop-srv
    type: nodejs
    path: gen/srv
    parameters:
      buildpack: nodejs_buildpack
      readiness-health-check-type: http
      readiness-health-check-http-endpoint: /health
    build-parameters:
      builder: npm
    properties:
      EXIT: 1
    requires:
      - name: bookshop-db
      - name: bookshop-auth
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  # --- 2. HANA DB Deployer ---
  - name: bookshop-db-deployer
    type: hdb
    path: gen/db
    parameters:
      buildpack: nodejs_buildpack
    requires:
      - name: bookshop-db

  # --- 3. Fiori Frontend App ---
  - name: bookshop-app
    type: approuter.nodejs
    path: app/router
    parameters:
      keep-existing-routes: true
      disk-quota: 256M
      memory: 256M
    requires:
      - name: srv-api
        group: destinations
        properties:
          name: srv-api
          url: ~{srv-url}
          forwardAuthToken: true
      - name: bookshop-auth

# ============================================
# RESOURCES (BTP Services)
# ============================================
resources:

  # --- HANA Cloud Database ---
  - name: bookshop-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # --- XSUAA Authentication ---
  - name: bookshop-auth
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
      config:
        xsappname: bookshop-tecrise-${org}-${space}
        tenant-mode: dedicated
        oauth2-configuration:
          redirect-uris:
            - https://*.${default-domain}/login/callback

  # --- Connectivity & Destination (untuk S/4 integration) ---
  - name: bookshop-connectivity
    type: org.cloudfoundry.managed-service
    parameters:
      service: connectivity
      service-plan: lite

  - name: bookshop-destination
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite
      config:
        init_data:
          instance:
            existing_destinations_policy: update
            destinations:
              - Name: S4HANA_Backend
                Type: HTTP
                URL: https://my-s4hana-tenant.s4hana.ondemand.com
                Authentication: OAuth2SAMLBearerAssertion
                ProxyType: Internet
```

---

## 🛠️ Hands-on 4: Build & Deploy

> **💡 Alur lengkap:**
> ```
> 1. Install tools (mbt, cf plugin)   → Siapkan alat-alat
> 2. mbt build                        → Pack kontainer (.mtar)
> 3. cf login                         → Buka pintu gerbang cloud
> 4. cf deploy                        → Kirim kontainer ke cloud
> 5. Assign role collections          → Kasih kunci ke user
> ```

### Langkah 1: Install Build Tools

```bash
# Install MTA Build Tool (mbt)
npm install -g mbt

# Install CF MultiApps Plugin
cf install-plugin multiapps

# Verifikasi
mbt --version
cf multiapps
```

**✅ Hasil yang Diharapkan:**

```
$ mbt --version
v1.2.45

$ cf plugins
plugin   version   command name
multiapps   3.11.1   ...
```

> **💡 Catatan:** Tools ini sudah diinstall di Hari 1.
> Jika belum, jalankan perintah di atas.

### Langkah 2: Build MTA Archive

```bash
# Dari root project
cd ~/projects/bookshop

# Build MTA (menghasilkan .mtar file)
mbt build -t ./

# Output:
# [INFO] Building MTA project "bookshop-tecrise"
# [INFO] Copying source files...
# [INFO] Running build steps for module "bookshop-srv"...
# [INFO] MTA archive generated at: bookshop-tecrise_1.0.0.mtar
```

### Langkah 3: Login ke CF

> **💡 Analogi:** Ini seperti memasukkan kartu kunci ke pintu gerbang data center.
> Setelah login, terminal Anda terhubung langsung ke Cloud Foundry di Singapore.

```bash
# Login ke SAP BTP Cloud Foundry
cf login -a https://api.cf.ap21.hana.ondemand.com \
          -u your-email@company.com \
          -o 3220086dtrial \
          -s dev

# Verifikasi
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

> **Perhatikan:** `API version: 3.215.0` menunjukkan versi Cloud Foundry API.
> `Targeted org` dan `Targeted space` menunjukkan Anda sudah terhubung ke org dan space yang benar.

### Langkah 4: Deploy ke BTP

```bash
# Deploy aplikasi
cf deploy bookshop-tecrise_1.0.0.mtar

# Monitor progress (di terminal lain)
cf deploy --no-start    # Deploy tanpa start
cf start bookshop-srv   # Start manual

# Cek status
cf apps
cf app bookshop-srv
cf logs bookshop-srv --recent
```

### Langkah 5: Assign Role Collections ke Users

```
BTP Cockpit → Subaccount → Security → Users
→ Pilih user → Assign Role Collections
→ Assign: "Bookshop_Admin" atau "Bookshop_Viewer"
```

---

## 🛠️ Hands-on 5: Destination & S/4HANA Integration

> **💡 Analogi:** Destination Service seperti **buku alamat pemasok**.
> App Anda butuh data dari sistem lain (S/4HANA)? Cukup daftarkan alamatnya
> di Destination, lalu CAP bisa "menelepon" sistem itu secara aman.

### Consume External API dari CAP

```javascript
// srv/s4-integration.js
const cds = require('@sap/cds');

module.exports = async function() {
    // Connect ke S/4HANA via Destination
    const S4 = await cds.connect.to('S4HANA_Backend');
    
    // Fetch data dari S/4HANA BusinessPartner API
    this.on('getBusinessPartners', async (req) => {
        const BusinessPartner = S4.entities.A_BusinessPartner;
        
        const partners = await S4.run(
            SELECT.from(BusinessPartner)
                  .columns('BusinessPartner', 'BusinessPartnerFullName')
                  .limit(10)
        );
        
        return partners;
    });
};
```

### Konfigurasi di `package.json`

```json
{
    "cds": {
        "requires": {
            "S4HANA_Backend": {
                "kind": "odata-v2",
                "model": "srv/external/API_BUSINESS_PARTNER"
            }
        }
    }
}
```

### Import S/4HANA EDMX

```bash
# Download metadata dari S/4HANA API
cds import srv/external/API_BUSINESS_PARTNER.edmx

# Ini akan generate CDS model dari EDMX
# File dibuat di: srv/external/API_BUSINESS_PARTNER.cds
```

---

## 🔍 Monitoring & Troubleshooting

### CF Logs

```bash
# Live logs
cf logs bookshop-srv

# Recent logs
cf logs bookshop-srv --recent

# Event logs
cf events bookshop-srv
```

### Health Check Endpoint

```javascript
// srv/health.js
module.exports = (app) => {
    app.get('/health', (req, res) => {
        res.json({
            status: 'UP',
            timestamp: new Date().toISOString(),
            version: process.env.npm_package_version
        });
    });
};
```

### Common Issues & Solutions

| Error | Penyebab | Solusi |
|-------|----------|--------|
| `401 Unauthorized` | Token tidak valid | Cek XSUAA binding & logout-login ulang |
| `403 Forbidden` | Scope tidak cukup | Assign role collection ke user |
| `503 Service Unavailable` | App crashed | Cek `cf logs` untuk error |
| `HANA connection failed` | HDI container belum ready | Tunggu db-deployer selesai |
| `Destination not found` | Nama destination salah | Cek spelling di `mta.yaml` & BTP Cockpit |

---

## 📝 Latihan Mandiri Hari 4 (Final Project)

### Exercise 4.1: Full Security Setup
Tambahkan scope baru `bookshop.reviewer` yang hanya bisa READ Reviews dan CREATE Reviews

### Exercise 4.2: MTA Tuning
Tambahkan environment variable `LOG_LEVEL=info` ke modul `bookshop-srv` di mta.yaml

### Exercise 4.3: Health Monitoring
Buat endpoint `/health` yang mengembalikan status database connection

### Exercise 4.4: Deploy & Verify
Deploy aplikasi ke BTP trial, assign role ke user Anda sendiri, dan akses via Fiori Launchpad

---

## 🏁 Final Project: Bookshop End-to-End

Kombinasikan semua yang dipelajari:

```
Final Project Requirements:
☑ CDS schema dengan: Books, Authors, Orders, Reviews
☑ CatalogService: READ Books & Authors, POST submitOrder
☑ AdminService: Full CRUD (protected dengan XSUAA)
☑ Fiori List Report: Books dengan filter & search
☑ Fiori Object Page: Book detail dengan Reviews section
☑ XSUAA: 3 roles (Viewer, Editor, Admin)
☑ Deploy: ke BTP Cloud Foundry dengan HANA
```

---

## 🎓 Workshop Completion

Selamat! Anda telah menyelesaikan **Hands-On Workshop TEC Rise** dan mempelajari:

| Hari | Topik | ✅ |
|------|-------|---|
| 1 | SAP BTP Fundamentals & BAS Setup | ✅ |
| 2 | SAP Fiori & SAPUI5 | ✅ |
| 3 | Extensibility — CDS Extensions, OData & Custom Logic | ✅ |
| 4 | Security, Integration & BTP Deployment | ✅ |

---

## 🔑 Key Concepts Hari 4

| Konsep | Penjelasan | Analogi |
|--------|------------|--------|
| **XSUAA** | OAuth 2.0 / OIDC service untuk auth | Satpam + mesin ID card |
| **Scope** | Granular izin akses | Kunci ruangan tertentu |
| **Role Collection** | Kumpulan roles di-assign ke user | Gantungan kunci karyawan |
| **MTA** | Multi-Target Application deployment unit | Kontainer kargo |
| **HDI Container** | HANA Deployment Infrastructure untuk DB | Ruang dapur di restoran |
| **Destination** | Koneksi ke external systems | Buku alamat pemasok |
| **Approuter** | Reverse proxy SAP untuk Fiori apps | Resepsionis restoran |
| **JWT** | JSON Web Token — carrier untuk user claims | Kartu akses digital |

---

## 🚀 REAL DEPLOYMENT — Bukti Live di BTP Cloud Foundry

> **App URL:** `https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com`  
> **Database:** SAP HANA Cloud (hana-free plan)  
> **Deployed:** 5 April 2026, 22:34 WIB

### Architecture yang ter-deploy:
```
┌──────────────────────────────────────────────────────────────┐
│              SAP BTP Cloud Foundry                            │
│              Org: 3220086dtrial / Space: dev                  │
│                                                               │
│   ┌──────────┐    ┌─────────────┐    ┌──────────────┐        │
│   │ bookshop │───▶│ bookshop-srv│◄──►│ bookshop-auth│(XSUAA)│
│   │(approuter│    │  (nodejs)   │    │  application │        │
│   │ Fiori LP)│    │  1/1 running│    └──────────────┘        │
│   └──────────┘    └──────┬──────┘                            │
│                          │                                    │
│                   ┌──────▼──────┐    ┌──────────────┐        │
│                   │ bookshop-db │◄──►│  Dev-hana    │(HANA)  │
│                   │ (hdi-shared)│    │  hana-free   │        │
│                   └─────────────┘    └──────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

### URLs yang Sudah Berjalan:
| URL | Deskripsi |
|-----|-----------|
| `https://3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com/` | **Fiori Launchpad** (via Approuter + XSUAA login) |
| `https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com/odata/v4/catalog/` | OData API backend |

### OData Response dari HANA Cloud:
```json
GET /odata/v4/catalog/Books → 5 books (Wuthering Heights, Jane Eyre, The Raven, Eleonora, Catweazle)
GET /odata/v4/catalog/Books?$filter=price gt 13 → 3 books filtered
GET /odata/v4/catalog/Books/$count → 5
GET tanpa token → 401 Unauthorized (XSUAA working!)
```

Lihat bukti lengkap: **[handson-4-build-deploy.md](./handson/handson-4-build-deploy.md)**

---

## 📂 Hasil Hands-on

Semua hasil hands-on didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|----------|
| [Hands-on 1: XSUAA Config](./handson/handson-1-xsuaa-config.md) | Setup xs-security.json (scopes, roles) |
| [Hands-on 2: RBAC Service](./handson/handson-2-rbac-service.md) | Role-based access control di CDS |
| [Hands-on 3: MTA Descriptor](./handson/handson-3-mta-descriptor.md) | Konfigurasi mta.yaml (modules, resources) |
| [**Hands-on 4: Build & Deploy**](./handson/handson-4-build-deploy.md) | **REAL DEPLOY** — HANA Cloud, XSUAA, Fiori Launchpad, Hybrid Mode |
| [**Hands-on 5: S/4HANA Integration**](./handson/handson-5-destination.md) | Destination, S/4HANA registration, extensibility (side-by-side & in-app) |
| [Test Script (Python)](./handson/test_odata_api.py) | Automated OData API test — 18/18 assertions PASSED |

---

## 📚 Referensi

- [CAP Security Guide](https://cap.cloud.sap/docs/guides/security/)
- [XSUAA Documentation](https://help.sap.com/docs/cp-uaa)
- [MTA Specification](https://www.sap.com/documents/2016/06/e2f618e4-757c-0010-82c7-eda71af511fa.html)
- [CF Deploy Plugin](https://help.sap.com/docs/btp/sap-business-technology-platform/multitarget-applications-in-cloud-foundry-environment)
- [SAP BTP Security Recommendations](https://help.sap.com/docs/btp/sap-btp-security-recommendations-c8a9bb59fe624f0981efa0eff2497d7d/sap-btp-security-recommendations)

---

⬅️ **Prev:** [Hari 3 — Extensibility](../Day3-Extensibility/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
