# Kuesioner Migrasi BW on ECC → SAP BW/4HANA on S/4HANA Rise (ODP)

Dokumen kuesioner ini digunakan untuk assessment awal proyek migrasi **SAP BW on ECC** ke **SAP BW/4HANA** dengan pendekatan **ODP (Operational Data Provisioning)** pada landscape **SAP S/4HANA Rise**.

## Daftar Dokumen

| No | Dokumen | Deskripsi |
|----|---------|-----------|
| 1 | [01-executive-summary.md](01-executive-summary.md) | Ringkasan eksekutif & tujuan migrasi |
| 2 | [02-current-landscape.md](02-current-landscape.md) | Assessment landscape BW & ECC saat ini |
| 3 | [03-data-source-inventory.md](03-data-source-inventory.md) | Inventarisasi data source, extractor & ODP |
| 4 | [04-odp-migration-readiness.md](04-odp-migration-readiness.md) | Kesiapan migrasi ODP & data flow |
| 5 | [05-target-architecture.md](05-target-architecture.md) | Arsitektur target S/4HANA Rise |
| 6 | [06-reporting-analytics.md](06-reporting-analytics.md) | Kebutuhan reporting & analytics |
| 7 | [07-security-governance.md](07-security-governance.md) | Security, authorization & data governance |
| 8 | [08-timeline-resources.md](08-timeline-resources.md) | Timeline, resource & risk assessment |

## Cara Penggunaan

1. Distribusikan setiap dokumen ke stakeholder terkait (Basis, BI/BW, Functional, Management)
2. Isi kolom **Jawaban** pada setiap pertanyaan
3. Kolom **Prioritas** menandakan urgensi informasi (H=High, M=Medium, L=Low)
4. Kumpulkan kembali dalam **2 minggu kerja** untuk dikonsolidasi
5. Hasil kuesioner menjadi input untuk **Migration Assessment Report**

## Stakeholder Matrix

| Dokumen | Basis/Infra | BW/BI Team | Functional | Management |
|---------|:-----------:|:----------:|:----------:|:----------:|
| 01 Executive Summary | | | | ✅ |
| 02 Current Landscape | ✅ | ✅ | | |
| 03 Data Source Inventory | | ✅ | ✅ | |
| 04 ODP Migration Readiness | ✅ | ✅ | | |
| 05 Target Architecture | ✅ | ✅ | | ✅ |
| 06 Reporting & Analytics | | ✅ | ✅ | |
| 07 Security & Governance | ✅ | | ✅ | ✅ |
| 08 Timeline & Resources | ✅ | ✅ | | ✅ |
