# 📕 Hari 5: Security, Integration & Deployment ke SAP BTP

> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 1–4, memiliki akses BTP dengan CF environment aktif

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 5, peserta mampu:
- Mengkonfigurasi XSUAA untuk authentication & authorization
- Implementasi role-based access control (RBAC) di CAP
- Membuat Multi-Target Application (MTA) descriptor
- Deploy aplikasi ke SAP BTP Cloud Foundry
- Connect ke SAP S/4HANA menggunakan Destination Service
- Monitoring dan troubleshooting aplikasi di BTP

---

## 📅 Jadwal Hari 5

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 4 | 15 menit |
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

```bash
# Login ke SAP BTP Cloud Foundry
cf login -a https://api.cf.us10-001.hana.ondemand.com \
          -u your-email@company.com \
          -o your-org \
          -s your-space

# Verifikasi
cf apps
cf services
```

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

## 📝 Latihan Mandiri Hari 5 (Final Project)

### Exercise 5.1: Full Security Setup
Tambahkan scope baru `bookshop.reviewer` yang hanya bisa READ Reviews dan CREATE Reviews

### Exercise 5.2: MTA Tuning
Tambahkan environment variable `LOG_LEVEL=info` ke modul `bookshop-srv` di mta.yaml

### Exercise 5.3: Health Monitoring
Buat endpoint `/health` yang mengembalikan status database connection

### Exercise 5.4: Deploy & Verify
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
| 2 | Core Data Services (CDS) Data Modelling | ✅ |
| 3 | OData Services & CAP Service Layer | ✅ |
| 4 | SAP Fiori & SAPUI5 | ✅ |
| 5 | Security, Integration & BTP Deployment | ✅ |

---

## 🔑 Key Concepts Hari 5

| Konsep | Penjelasan |
|--------|------------|
| **XSUAA** | OAuth 2.0 / OIDC service untuk auth di BTP |
| **Scope** | Granular izin akses |
| **Role Collection** | Kumpulan roles yang di-assign ke user |
| **MTA** | Multi-Target Application — deployment unit |
| **HDI Container** | HANA Deployment Infrastructure untuk DB objects |
| **Destination** | Konfigurasi koneksi ke external systems |
| **Approuter** | Reverse proxy SAP untuk Fiori apps |
| **JWT** | JSON Web Token — carrier untuk user claims |

---

## 📚 Referensi

- [CAP Security Guide](https://cap.cloud.sap/docs/guides/security/)
- [XSUAA Documentation](https://help.sap.com/docs/cp-uaa)
- [MTA Specification](https://www.sap.com/documents/2016/06/e2f618e4-757c-0010-82c7-eda71af511fa.html)
- [CF Deploy Plugin](https://help.sap.com/docs/btp/sap-business-technology-platform/multitarget-applications-in-cloud-foundry-environment)
- [SAP BTP Security Recommendations](https://help.sap.com/docs/btp/sap-btp-security-recommendations-c8a9bb59fe624f0981efa0eff2497d7d/sap-btp-security-recommendations)

---

⬅️ **Prev:** [Hari 4 — SAP Fiori & UI5](../Day4-Fiori-UI5/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)
