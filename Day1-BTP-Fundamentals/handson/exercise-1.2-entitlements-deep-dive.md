# ✅ Exercise 1.2: Entitlements Deep Dive — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI

---

## Tugas: Identifikasi Entitlements per Kategori

Dari halaman **Entitlements** di Subaccount, berikut identifikasi 78 entitlements:

---

### 1. Service yang Berhubungan dengan Database ✅

| Service | Plan(s) | Quota | Fungsi |
|---------|---------|-------|--------|
| **SAP HANA Cloud** | hana-free | 1 | Database utama untuk production |
| SAP HANA Cloud | relational-data-lake-free | 1 | Data lake untuk analytics |
| SAP HANA Cloud | hana-cloud-connection-free | 1 | Koneksi antar HANA instances |
| SAP HANA Cloud | tools | 1 | HANA management tools |
| **SAP HANA Schemas & HDI Containers** | hdi-shared | 10 | HDI container deployment |
| SAP HANA Schemas & HDI Containers | schema | 10 | Direct schema access |
| SAP HANA Schemas & HDI Containers | sbss | 10 | Schema-based service binding |
| SAP HANA Schemas & HDI Containers | securestore | 10 | Secure key-value store |
| **PostgreSQL, Hyperscaler Option** | trial | 1 | PostgreSQL sebagai alternatif DB |
| **Redis, Hyperscaler Option** | trial | 1 | In-memory cache/datastore |
| **Credential Store** | proxy / trial | 1 | Credential management |

> **Total Database services:** 12 entitlements  
> **Yang dipakai di workshop:** SAP HANA Cloud (hana-free), SAP HANA Schemas (hdi-shared)

---

### 2. Service yang Berhubungan dengan Security ✅

| Service | Plan(s) | Quota | Fungsi |
|---------|---------|-------|--------|
| **Authorization and Trust Management (XSUAA)** | application | 1 | OAuth2 token management |
| Authorization and Trust Management | broker | 1 | Service broker untuk multi-tenant |
| Authorization and Trust Management | space | 1 | Space-level service binding |
| Authorization and Trust Management | apiaccess | 1 | API access management |
| **Cloud Identity Services** | default | 1 | Identity Provider (IdP) |
| Cloud Identity Services | application | 1 | Application-level identity |

> **Total Security services:** 6 entitlements  
> **Yang dipakai di workshop:** XSUAA (application plan) — untuk autentikasi di Day 5

---

### 3. Service yang Berhubungan dengan Integration ✅

| Service | Plan(s) | Quota | Fungsi |
|---------|---------|-------|--------|
| **Integration Suite** | Trial | 1 | Platform integrasi all-in-one |
| **SAP Process Integration Runtime** | integration-flow | 2 | Runtime untuk integration flows |
| SAP Process Integration Runtime | api | 1 | API management untuk PI |
| **Connectivity Service** | lite | 1 | Cloud-to-cloud connectivity |
| Connectivity Service | connectivity_proxy | 1 | On-premise connectivity proxy |
| **Destination Service** | lite | 1 | URL & credential management |

> **Total Integration services:** 6 entitlements  
> **Yang dipakai di workshop:** Destination Service (lite) — untuk konfigurasi koneksi

---

### 4. Service yang Berhubungan dengan Application Runtime ✅

| Service | Plan(s) | Quota | Fungsi |
|---------|---------|-------|--------|
| **Cloud Foundry Environment** | Trial | 1 | CF environment enablement |
| **Cloud Foundry Runtime** | MEMORY | 4 GB | Runtime memory untuk apps |
| **Kyma Runtime** | Kyma Runtime Trial | 1 | Kubernetes-based runtime |
| **ABAP environment** | Shared | 1 | ABAP server di cloud |
| **Serverless Runtime** | default | 1 | Function-as-a-Service |
| Serverless Runtime | odpruntime | 1 | ODP runtime |
| **Application Autoscaler** | standard | 1 | Auto-scale CF apps |

> **Total Runtime services:** 7 entitlements  
> **Yang dipakai di workshop:** Cloud Foundry Environment + Runtime — untuk deployment di Day 5

---

### 5. Kategori Tambahan yang Ditemukan

#### UI & Frontend (7 entitlements)
- SAP Build Work Zone, standard edition (standard)
- HTML5 Application Repository Service (app-host, app-runtime)
- UI5 flexibility for key users (trial)
- UI Theme Designer (standard)
- Application Frontend Service (Developer)
- SAP Dynamic Forms Trial (Trial Plan)

#### DevOps & Management (8 entitlements)
- SAP Business Application Studio (trial)
- Continuous Integration & Delivery (Trial)
- Cloud Transport Management (Lite, standard)
- Cloud Management Service (local, central, viewer)
- Service Manager (subaccount-audit, admin, container)
- Automation Pilot (free)
- Job Scheduling Service (lite, free)

#### Monitoring & Analytics (7 entitlements)
- Feature Flags Service (dashboard, lite)
- Alert Notification (standard)
- Application Logging Service (lite)
- Audit Log Management Service (Default)
- Audit Log Viewer Service (Free)
- Usage Data Management Service (reporting-ga-admin)

---

## 📊 Ringkasan

```
Entitlements per Kategori:
━━━━━━━━━━━━━━━━━━━━━━━━━━
  🗄️  Database & Data:        12
  ☁️  Runtime & Application:   7
  🔐 Security & Identity:      6
  🔗 Integration & Connect:    6
  🖥️  UI & Frontend:           7
  🛠️  DevOps & Management:     8+
  📊 Monitoring & Analytics:   7
  🤖 Automation & Other:       7+
  ─────────────────────────────
  Total:                       78
```

---

## Entitlements yang Penting untuk Workshop Ini

| Day | Service yang Dibutuhkan | Plan |
|-----|-------------------------|------|
| Day 1 | SAP Business Application Studio | trial |
| Day 2 | (Local development, no service needed) | - |
| Day 3 | (Local development, no service needed) | - |
| Day 4 | HTML5 Application Repository | app-host, app-runtime |
| Day 5 | Authorization and Trust Management | application |
| Day 5 | SAP HANA Cloud | hana-free |
| Day 5 | Cloud Foundry Runtime | MEMORY |
| Day 5 | Destination Service | lite |

---

**Kesimpulan:** Semua 78 entitlements berhasil diidentifikasi dan dikategorikan. Trial account menyediakan semua service yang dibutuhkan untuk workshop 5 hari penuh, termasuk HANA Cloud, BAS, XSUAA, dan CF Runtime.
