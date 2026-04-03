# 🚀 Hands-On Workshop: TEC Rise — SAP BTP Technical Bootcamp

> **Workshop Duration:** 5 Hari (Intensive)  
> **Level:** Intermediate – Advanced  
> **Target Audience:** SAP Developer, Technical Consultant, BTP Engineer  
> **Teknologi:** SAP BTP, CAP, CDS, OData, SAP Fiori, SAPUI5

---

## 📋 Deskripsi Workshop

Workshop ini dirancang untuk memberikan pengalaman langsung (hands-on) dalam membangun aplikasi enterprise modern menggunakan ekosistem **SAP Business Technology Platform (BTP)**. Peserta akan mempelajari seluruh stack mulai dari data modeling, service layer, hingga user interface dengan pendekatan **SAP Cloud Application Programming Model (CAP)**.

---

## 🗓️ Planning 5 Hari Workshop

| Hari | Topik | Teknologi Utama |
|------|-------|-----------------|
| [Hari 1](./Day1-BTP-Fundamentals/README.md) | SAP BTP Fundamentals & Setup Environment | BTP Cockpit, BAS, CF CLI |
| [Hari 2](./Day2-CDS-CoreDataServices/README.md) | Core Data Services (CDS) — Data Modelling | CDS, CAP, SQLite |
| [Hari 3](./Day3-OData-Services/README.md) | OData Services & Service Layer | OData v2/v4, CAP Services |
| [Hari 4](./Day4-Fiori-UI5/README.md) | SAP Fiori & SAPUI5 | Fiori Elements, SAPUI5, Annotations |
| [Hari 5](./Day5-Integration-Deployment/README.md) | Integration, XSUAA & Deployment ke BTP | XSUAA, MTA, CF Deploy |

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

# Verifikasi instalasi
cds --version

# Install CF CLI
brew install cloudfoundry/tap/cf-cli@8   # macOS
# atau download dari: https://github.com/cloudfoundry/cli/releases

# Login ke CF (SAP BTP)
cf login -a https://api.cf.us10-001.hana.ondemand.com
```

### Skills yang Direkomendasikan
- Dasar JavaScript / Node.js
- Pemahaman dasar REST API
- Dasar SQL
- Dasar HTML/CSS (untuk Hari 4)

---

## 📁 Struktur Repository

```
Hands-On-Workshop-TEC-Rise/
├── README.md                        ← You are here
├── Day1-BTP-Fundamentals/
│   ├── README.md
│   ├── slides/
│   └── exercises/
├── Day2-CDS-CoreDataServices/
│   ├── README.md
│   ├── db/
│   │   ├── schema.cds
│   │   └── data/
│   └── exercises/
├── Day3-OData-Services/
│   ├── README.md
│   ├── srv/
│   │   └── catalog-service.cds
│   └── exercises/
├── Day4-Fiori-UI5/
│   ├── README.md
│   ├── app/
│   │   └── fiori-app/
│   └── exercises/
├── Day5-Integration-Deployment/
│   ├── README.md
│   ├── mta.yaml
│   ├── xs-security.json
│   └── exercises/
└── Final-Project/
    └── bookshop-app/
```

---

## 🎯 Learning Outcomes

Setelah menyelesaikan workshop ini, peserta mampu:

1. **Navigasi SAP BTP Cockpit** dan memahami struktur layanan BTP
2. **Membuat CDS data models** dengan entities, associations, dan annotations
3. **Expose OData services** menggunakan SAP CAP framework
4. **Membangun Fiori Elements app** dari OData service tanpa coding UI manual
5. **Mengamankan aplikasi** dengan XSUAA dan role-based access control
6. **Deploy aplikasi** ke SAP BTP Cloud Foundry

---

## 👨‍🏫 Facilitator & Support

| Role | Kontak |
|------|--------|
| Lead Trainer | TEC Rise Team |
| Technical Support | via GitHub Issues di repo ini |

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
