# ✅ Hands-on 5: Destination, S/4HANA Registration & Integration — Panduan Lengkap
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** REFERENCE — panduan langkah demi langkah untuk integrasi S/4HANA  
> **Tanggal:** 5 April 2026

---

## Bagian A: Bagaimana Cara Mengetahui & Mendaftarkan SAP S/4HANA ke BTP

> **💡 Analogi:** S/4HANA adalah **gudang utama data bisnis** Anda. 
> BTP adalah **platform pengembangan**. Agar BTP bisa "menelepon" S/4HANA,
> keduanya harus saling kenal dan punya "nomor telepon" yang terdaftar.

### Prasyarat: Apakah Anda Punya S/4HANA?

**Cek di BTP Cockpit:**
```
BTP Cockpit → System Landscape → Systems
```

Jika S/4HANA sudah ter-register, akan muncul di daftar Systems.

**Jenis S/4HANA yang bisa diintegrasikan:**

| Jenis | Deskripsi | Cara Registrasi |
|-------|-----------|-----------------|
| **S/4HANA Cloud Public Edition** | SaaS dari SAP | Auto-registered via SAP for Me |
| **S/4HANA Cloud Private Edition** | Managed private cloud | Manual registration via BTP Cockpit |
| **S/4HANA On-Premise** | Installed di datacenter sendiri | Cloud Connector + Destination |
| **SAP Business ByDesign** | SaaS ERP | Manual destination configuration |

### Langkah 1: Registrasi S/4HANA di BTP (System Landscape)

#### Untuk S/4HANA Cloud (Public Edition):

```
1. SAP for Me → https://me.sap.com
   → System & Provisioning → Systems → pilih S/4HANA tenant

2. BTP Cockpit → System Landscape → Systems
   → "Register System"
   → System Type: SAP S/4HANA Cloud
   → System Name: MY-S4HC (bebas)
   → System URL: https://my12345.s4hana.ondemand.com

3. Generate Integration Token:
   → BTP Cockpit → System Landscape → Systems → MY-S4HC
   → "Get Token" → Copy token

4. Paste token di S/4HANA:
   → S/4HANA → Communication Management → Maintain Extensions on SAP BTP
   → Paste token → Activate

5. Status berubah: "Registered" ✅
```

#### Untuk S/4HANA On-Premise:

```
1. Install SAP Cloud Connector di network lokal
   → Download dari https://tools.hana.ondemand.com/#cloud
   → Jalankan di server yang bisa akses S/4HANA

2. Konfigurasi Cloud Connector:
   → Login: https://localhost:8443
   → Add Subaccount: Region=cf-ap21, Subaccount=3220086dtrial
   → Cloud to On-Premise:
     - Backend Type: SAP Gateway / SAP System
     - Protocol: HTTPS / HTTP
     - Internal Host: s4hana.internal.company.com
     - Internal Port: 443
     - Virtual Host: s4hana-virtual
     - Virtual Port: 443

3. Di BTP Cockpit:
   → Connectivity → Cloud Connectors → Status: Connected ✅
```

### Langkah 2: Setup Communication Arrangement di S/4HANA Cloud

```
S/4HANA System → Communication Management

1. Communication Systems:
   → New → System ID: BTP_SYSTEM
   → Host Name: 3220086dtrial.authentication.ap21.hana.ondemand.com
   → Business System: BTP_3220086dtrial

2. Communication Arrangements:
   → New → Scenario: SAP_COM_0008 (Business Partner Read)
   → Communication System: BTP_SYSTEM
   → Inbound Communication:
     - User: BTPUSER
     - Authentication: OAuth 2.0
   → Outbound Communication:
     - Auth Method: OAuth 2.0 (SAML Bearer)

3. Catat credentials:
   - API URL: https://my12345-api.s4hana.ondemand.com/sap/opu/odata/sap/API_BUSINESS_PARTNER
   - Client ID: <generated>
   - Client Secret: <generated>
   - Token URL: https://my12345.s4hana.ondemand.com/sap/bc/sec/oauth2/token
```

### Langkah 3: Buat Destination di BTP

```
BTP Cockpit → Subaccount → Connectivity → Destinations → New Destination

=== Untuk S/4HANA Cloud ===
Name:               S4HANA_Cloud
Type:               HTTP
URL:                https://my12345-api.s4hana.ondemand.com
ProxyType:          Internet
Authentication:     OAuth2SAMLBearerAssertion
Audience:           https://my12345.s4hana.ondemand.com
AuthnContextClassRef: urn:oasis:names:tc:SAML:2.0:ac:classes:X509
Client Key:         <Client ID dari Communication Arrangement>
Token Service URL:  https://my12345.s4hana.ondemand.com/sap/bc/sec/oauth2/token
Token Service User: <Client ID>
Token Service Password: <Client Secret>

Additional Properties:
  sap-client:       100
  HTML5.DynamicDestination: true
  WebIDEEnabled:    true
  WebIDEUsage:      odata_gen

=== Untuk S/4HANA On-Premise (via Cloud Connector) ===
Name:               S4HANA_OnPrem
Type:               HTTP
URL:                http://s4hana-virtual:443
ProxyType:          OnPremise
Authentication:     BasicAuthentication / PrincipalPropagation
User:               <RFC user>
Password:           <password>

Additional Properties:
  sap-client:       100
  WebIDEEnabled:    true
```

### Langkah 4: Verifikasi Connection

```
BTP Cockpit → Destinations → S4HANA_Cloud → "Check Connection"

Expected: Response: 200 OK ✅
```

---

## Bagian B: Consume S/4HANA API di CAP Application

### 1. Import S/4HANA API Metadata

```bash
# Download EDMX dari SAP Business Hub
# https://api.sap.com/api/API_BUSINESS_PARTNER/overview

# Simpan sebagai file EDMX, lalu import:
$ cds import srv/external/API_BUSINESS_PARTNER.edmx

# Output:
# [cds] - imported API to srv/external/API_BUSINESS_PARTNER
# > using { API_BUSINESS_PARTNER } from './external/API_BUSINESS_PARTNER';
```

### 2. Definisikan di package.json

```json
{
  "cds": {
    "requires": {
      "API_BUSINESS_PARTNER": {
        "kind": "odata-v2",
        "model": "srv/external/API_BUSINESS_PARTNER",
        "[production]": {
          "credentials": {
            "destination": "S4HANA_Cloud",
            "path": "/sap/opu/odata/sap/API_BUSINESS_PARTNER"
          }
        }
      }
    }
  }
}
```

### 3. Buat CDS Service untuk Expose Data S/4HANA

```cds
// srv/external-service.cds
using { API_BUSINESS_PARTNER as S4 } from './external/API_BUSINESS_PARTNER';

service ExternalService @(path: '/api/external') {
    @readonly
    entity BusinessPartners as projection on S4.A_BusinessPartner {
        key BusinessPartner,
        BusinessPartnerFullName,
        BusinessPartnerCategory,
        CreationDate
    };
}
```

### 4. Implement Custom Handler

```javascript
// srv/external-service.js
const cds = require('@sap/cds');

module.exports = async function () {
    const S4 = await cds.connect.to('API_BUSINESS_PARTNER');

    this.on('READ', 'BusinessPartners', async (req) => {
        // Delegate query ke S/4HANA via Destination
        return S4.run(req.query);
    });
};
```

### 5. MTA Config untuk Destination Service

```yaml
# Tambahkan di mta.yaml
modules:
  - name: bookshop-srv
    requires:
      - name: bookshop-destination   # Tambah ini
      - name: bookshop-connectivity  # Tambah ini (untuk On-Premise)

resources:
  - name: bookshop-destination
    type: org.cloudfoundry.managed-service
    parameters:
      service: destination
      service-plan: lite

  - name: bookshop-connectivity
    type: org.cloudfoundry.managed-service
    parameters:
      service: connectivity
      service-plan: lite
```

---

## Bagian C: S/4HANA Extensibility dari BTP (Side-by-Side Extension)

> **💡 Analogi:** Extensibility = **tambah fitur baru di restoran tanpa renovasi besar**.
> S/4HANA = gedung utama (core system). Jangan ubah gedung utama!
> BTP = bangunan samping (side-by-side) — tambah fitur baru di sini.

### Jenis Extensibility di SAP:

```
┌────────────────────────────────────────────────────────┐
│            SAP EXTENSIBILITY TYPES                      │
├─────────────────┬──────────────────────────────────────┤
│                 │                                        │
│  IN-APP         │  ● Key User Extensibility              │
│  (di dalam      │    - Custom Fields (tambah field UI)   │
│   S/4HANA)      │    - Custom Logic (BAdI, BRF+)         │
│                 │    - Custom CDS Views                   │
│                 │    - Custom Analytical Queries           │
│                 │                                        │
├─────────────────┼──────────────────────────────────────┤
│                 │                                        │
│  SIDE-BY-SIDE   │  ● BTP Extension (yang kita pelajari) │
│  (di luar       │    - CAP Application di BTP             │
│   S/4HANA,      │    - Consume S/4HANA APIs               │
│   di BTP)       │    - Custom UI (Fiori Elements)         │
│                 │    - Custom Logic (Node.js/Java)         │
│                 │    - Mashup dengan external services     │
│                 │                                        │
├─────────────────┼──────────────────────────────────────┤
│                 │                                        │
│  CLASSIC        │  ● ABAP Extension                      │
│  (ABAP-based)   │    - Enhancement Points / BAdIs         │
│                 │    - Custom Reports (Z-programs)         │
│                 │    - RFC/BAPI                            │
│                 │                                        │
└─────────────────┴──────────────────────────────────────┘
```

### Contoh: Side-by-Side Extension — Approval Workflow

**Skenario:** Menambahkan approval workflow untuk purchase order dari S/4HANA.

#### Arsitektur:
```
┌──────────────┐     Events      ┌──────────────────────┐
│  S/4HANA     │ ──────────────▶ │  BTP Extension App   │
│  (PO Created)│                 │  (CAP + Approval)    │
│              │ ◀────────────── │                      │
│  (PO Updated)│     API Call    │  ┌─────────────────┐ │
└──────────────┘                 │  │ Fiori Approval  │ │
                                 │  │ Inbox           │ │
                                 │  └─────────────────┘ │
                                 └──────────────────────┘
```

#### Step 1: Enable S/4HANA Events

```
S/4HANA → Enterprise Event Enablement
→ Maintain Channel Binding → SAP_COM_0092
→ Topic: sap/s4/beh/purchaseorder/v1/PurchaseOrder/Created/v1
→ Active: Yes
```

#### Step 2: Setup SAP Event Mesh di BTP

```
BTP Cockpit → Service Marketplace → Event Mesh
→ Create instance (default plan)
→ Service Keys → webhook URL

$ cf create-service enterprise-messaging default bookshop-events
```

#### Step 3: CAP Subscribe to Events

```cds
// srv/po-approval.cds
using { API_PURCHASEORDER as PO } from './external/API_PURCHASEORDER';

service ApprovalService {
    entity PendingApprovals {
        key ID         : UUID;
        poNumber       : String;
        supplier       : String;
        amount         : Decimal(15,2);
        status         : String enum { Pending; Approved; Rejected };
        requestedAt    : DateTime;
    }

    action approve(ID: UUID) returns PendingApprovals;
    action reject(ID: UUID, reason: String) returns PendingApprovals;
}
```

```javascript
// srv/po-approval.js
const cds = require('@sap/cds');

module.exports = async function () {
    const S4 = await cds.connect.to('API_PURCHASEORDER');
    const messaging = await cds.connect.to('messaging');

    // Listen for PO Created events from S/4HANA
    messaging.on('sap/s4/beh/purchaseorder/v1/PurchaseOrder/Created/v1',
        async (msg) => {
            const poNumber = msg.data.PurchaseOrder;
            // Fetch PO details from S/4HANA
            const po = await S4.run(
                SELECT.one.from('A_PurchaseOrder')
                    .where({ PurchaseOrder: poNumber })
            );
            // Create approval request
            await INSERT.into('ApprovalService.PendingApprovals').entries({
                poNumber: poNumber,
                supplier: po.Supplier,
                amount: po.PurchaseOrderNetAmount,
                status: 'Pending',
                requestedAt: new Date()
            });
        }
    );

    this.on('approve', async (req) => {
        const { ID } = req.data;
        // Update S/4HANA PO status via API
        // ... implementation
        return UPDATE('PendingApprovals').set({ status: 'Approved' }).where({ ID });
    });
};
```

### Contoh: Key User Extensibility (In-App)

**Skenario:** Menambahkan custom field di Business Partner.

```
S/4HANA → Custom Fields → Business Context: Business Partner
→ New Field:
  - Field Label: Sustainability Rating
  - Field Type: Number (1–5)
  - Used In: Business Partner, API

→ Publish → Field tersedia di:
  - Fiori app Business Partner
  - OData API: API_BUSINESS_PARTNER (sebagai custom field)
  - CDS Views: I_BusinessPartner
```

Setelah custom field dibuat di S/4HANA, data bisa diakses dari BTP:

```javascript
// Di CAP handler
const bp = await S4.run(
    SELECT.from('A_BusinessPartner')
        .columns('BusinessPartner', 'BusinessPartnerFullName', 'YY1_SustainabilityRating_bus')
        .where({ YY1_SustainabilityRating_bus: { '>': 3 } })
);
```

---

## Catatan Penting

- ⚠️ S/4HANA Cloud access memerlukan **lisensi SAP aktif** dan Communication Arrangement
- ⚠️ S/4HANA On-Premise memerlukan **SAP Cloud Connector** di network lokal
- ⚠️ Pada **BTP Trial account**, Destination bisa dikonfigurasi tapi memerlukan target system
- ✅ Konsep destination berlaku untuk API external (non-SAP) juga
- ✅ **SAP Business Accelerator Hub** (api.sap.com) untuk melihat semua available S/4HANA APIs
- ✅ Side-by-side extension adalah **recommended approach** oleh SAP (clean core strategy)
- ✅ Langkah-langkah akan didemonstrasikan oleh instructor saat workshop

---

## Kesimpulan

- ✅ Arsitektur Destination-based integration dipahami
- ✅ `cds import` bisa generate CDS model dari EDMX
- ✅ CAP handler bisa consume external OData via `cds.connect.to()`
