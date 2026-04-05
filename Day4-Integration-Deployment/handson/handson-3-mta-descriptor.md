# ✅ Hands-on 3: MTA Descriptor — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED (file dikonfigurasi)  
> **Tanggal:** 5 April 2026

---

## File yang Dibuat

### `mta.yaml` — Multi-Target Application Descriptor

```yaml
_schema-version: '3.1'
ID: bookshop-tecrise
version: 1.0.0
description: TEC Rise Bookshop Application

parameters:
  enable-parallel-deployments: true

build-parameters:
  before-all:
    - builder: custom
      commands:
        - npx cds build --production

modules:
  # Backend CAP Service
  - name: bookshop-srv
    type: nodejs
    path: gen/srv
    requires:
      - name: bookshop-db
      - name: bookshop-auth
    provides:
      - name: srv-api
        properties:
          srv-url: ${default-url}

  # HANA DB Deployer
  - name: bookshop-db-deployer
    type: hdb
    path: gen/db
    requires:
      - name: bookshop-db

  # Fiori Frontend (Approuter)
  - name: bookshop-app
    type: approuter.nodejs
    path: app/router
    requires:
      - name: srv-api
        group: destinations
        properties:
          name: srv-api
          url: ~{srv-url}
          forwardAuthToken: true
      - name: bookshop-auth

resources:
  # HANA Cloud Database
  - name: bookshop-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  # XSUAA Authentication
  - name: bookshop-auth
    type: org.cloudfoundry.managed-service
    parameters:
      service: xsuaa
      service-plan: application
      path: ./xs-security.json
```

## Penjelasan (Analogi Kontainer Kargo)

```
mta.yaml = "Daftar Isi Kontainer"

MODULES (barang yang dikirim):
┌─────────────────────────┐
│ bookshop-srv            │ ← Dapur (backend Node.js)
│ bookshop-db-deployer    │ ← Peralatan dapur (HANA schema)
│ bookshop-app            │ ← Meja & kursi (Fiori frontend)
└─────────────────────────┘

RESOURCES (layanan di lokasi baru):
┌─────────────────────────┐
│ bookshop-db             │ ← Listrik (HANA database)
│ bookshop-auth           │ ← Satpam (XSUAA)
└─────────────────────────┘

REQUIRES/PROVIDES (kabel penghubung):
bookshop-srv ──requires──→ bookshop-db   (perlu database)
bookshop-srv ──requires──→ bookshop-auth (perlu security)
bookshop-app ──requires──→ srv-api       (perlu backend URL)
```

## Verifikasi

- ✅ YAML syntax valid
- ✅ 3 modules terdefinisi (srv, db-deployer, app)
- ✅ 2 resources terdefinisi (db, auth)
- ✅ requires/provides dependencies terhubung

---

## Kesimpulan

- ✅ MTA descriptor siap untuk `mbt build`
- ✅ Semua modul dan resource terdefinisi dengan benar
- ✅ Dependencies antar module/resource terhubung
