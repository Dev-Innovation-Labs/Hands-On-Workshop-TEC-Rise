# Kuesioner Migrasi SAP BW on ECC → SAP BW/4HANA on S/4HANA Rise
## Operational Data Provisioning (ODP) Migration Assessment

**Versi:** 1.0  
**Tanggal:** _______________  
**Nama Pengisi:** _______________  
**Jabatan/Role:** _______________  
**Departemen:** _______________  
**Email:** _______________

---

## Petunjuk Pengisian

- Isi setiap pertanyaan **selengkap mungkin**
- Gunakan kolom **Catatan** untuk informasi tambahan
- Jika tidak mengetahui jawaban, tulis **"N/A"** dan sebutkan PIC yang tepat
- **Prioritas:** H = High (wajib dijawab), M = Medium, L = Low

---

## Bagian A — Informasi Umum & Tujuan Migrasi

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| A1 | Apa nama perusahaan dan industri bisnis utama? | H | |
| A2 | Apa alasan utama migrasi BW ke S/4HANA Rise? (pilih semua yang sesuai) <br> ☐ End of maintenance ECC/BW <br> ☐ Konsolidasi landscape <br> ☐ Performa & real-time analytics <br> ☐ Pengurangan TCO <br> ☐ Modernisasi arsitektur <br> ☐ Regulasi/compliance <br> ☐ Lainnya: _______ | H | |
| A3 | Apakah ada target go-live / deadline migrasi? | H | |
| A4 | Apakah pendekatan migrasi yang diharapkan? <br> ☐ Greenfield (fresh implementation) <br> ☐ Brownfield (system conversion) <br> ☐ Selective data migration (hybrid) <br> ☐ Belum ditentukan | H | |
| A5 | Apakah ada constraint budget yang perlu diketahui? | M | |
| A6 | Siapa executive sponsor proyek migrasi ini? | M | |

---

## Bagian B — Landscape SAP BW Saat Ini

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| B1 | Versi SAP BW yang digunakan saat ini? (contoh: BW 7.5, BW 7.4) | H | |
| B2 | Database backend BW saat ini? <br> ☐ Oracle <br> ☐ MS SQL Server <br> ☐ DB2 <br> ☐ SAP ASE (Sybase) <br> ☐ SAP HANA <br> ☐ Lainnya: _______ | H | |
| B3 | Ukuran total database BW saat ini? (dalam TB/GB) | H | |
| B4 | Berapa jumlah **InfoProvider** yang aktif digunakan? <br> - InfoCube: _______ <br> - DSO (DataStore Object): _______ <br> - MultiProvider: _______ <br> - CompositeProvider: _______ <br> - Lainnya: _______ | H | |
| B5 | Berapa jumlah **InfoObject** (characteristic + key figure)? | M | |
| B6 | Berapa jumlah **Process Chain** yang aktif? | H | |
| B7 | Berapa rata-rata runtime Process Chain terlama? | M | |
| B8 | Berapa jumlah **BEx Query / Query View** yang aktif digunakan? | H | |
| B9 | Berapa jumlah user BW aktif per bulan? | M | |
| B10 | Apakah BW saat ini sudah menggunakan **HANA-optimized objects**? (ADSO, CompositeProvider, Open ODS View) <br> ☐ Ya, sebagian besar <br> ☐ Ya, sebagian kecil <br> ☐ Belum sama sekali | H | |
| B11 | Apakah ada **BW Add-On** atau **custom ABAP** di BW? <br> Jika ya, sebutkan: | M | |
| B12 | Apakah BW saat ini di-host **on-premise** atau **cloud**? | H | |

---

## Bagian C — Source System ECC

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| C1 | Versi SAP ECC yang digunakan? (contoh: ECC 6.0 EHP8) | H | |
| C2 | Berapa jumlah **source system** yang terhubung ke BW? <br> - SAP ECC: _______ <br> - SAP S/4HANA: _______ <br> - Non-SAP (DB Connect, File, API): _______ <br> - SAP BPC: _______ <br> - Lainnya: _______ | H | |
| C3 | Apakah ECC sudah **migrate ke S/4HANA**, atau masih ECC? <br> ☐ Masih ECC <br> ☐ Sudah S/4HANA <br> ☐ Dalam proses migrasi <br> ☐ ECC & S/4HANA berjalan paralel | H | |
| C4 | Apakah ada rencana migrasi ECC → S/4HANA? Kapan target? | H | |
| C5 | Modul SAP ECC yang aktif digunakan: (centang semua yang relevan) <br> ☐ FI (Finance) <br> ☐ CO (Controlling) <br> ☐ MM (Materials Management) <br> ☐ SD (Sales & Distribution) <br> ☐ PP (Production Planning) <br> ☐ PM (Plant Maintenance) <br> ☐ QM (Quality Management) <br> ☐ HR/HCM <br> ☐ PS (Project Systems) <br> ☐ Lainnya: _______ | H | |

---

## Bagian D — Data Source & Extractor Inventory

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| D1 | Berapa total jumlah **DataSource (extractor)** yang aktif? | H | |
| D2 | Breakdown DataSource per tipe: <br> - Standard SAP: _______ <br> - Generic (custom table/view/function module): _______ <br> - Custom ABAP (SAPI): _______ | H | |
| D3 | Apakah ada **custom extractor** (RSO2 / CMOD exit)? Berapa jumlahnya? | H | |
| D4 | Apakah ada DataSource yang menggunakan **delta mechanism** (delta queue)? <br> ☐ Ya → Berapa jumlah: _______ <br> ☐ Tidak | H | |
| D5 | Tipe delta yang digunakan: <br> ☐ ABR (After-image via delta queue) <br> ☐ AIM (Additive image) <br> ☐ ADD (Additive delta) <br> ☐ AIMD (After-image with deletion) <br> ☐ Tidak tahu | M | |
| D6 | Apakah saat ini sudah menggunakan **ODP (Operational Data Provisioning)** di ECC/S/4HANA? <br> ☐ Ya, sepenuhnya ODP <br> ☐ Ya, sebagian (hybrid classic + ODP) <br> ☐ Belum, masih classic extractor | H | |
| D7 | ODP Provider yang sudah digunakan: <br> ☐ ODP_SAPI (classic extractor via ODP) <br> ☐ ODP_BW (BW InfoProvider as source) <br> ☐ ODP_CDS (CDS View extractor) <br> ☐ ODP_SLT (SLT replication) <br> ☐ Belum ada | H | |
| D8 | Apakah ada DataSource yang **sudah discontinue** di S/4HANA? (contoh: FI datasource LIS-based) <br> Jika ya, sebutkan: | H | |
| D9 | Apakah ada **3rd-party data** yang di-load ke BW? (file, API, database) | M | |
| D10 | Lampirkan **daftar DataSource aktif** (export dari RSA5/RSA6) jika tersedia: <br> ☐ Terlampir <br> ☐ Akan dikirim terpisah <br> ☐ Belum tersedia | H | |

---

## Bagian E — ODP Migration Readiness

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| E1 | Apakah ECC/S/4HANA sudah di-patch dengan **ODP Framework**? (SAP Note 2232584) <br> ☐ Ya <br> ☐ Tidak <br> ☐ Tidak tahu | H | |
| E2 | Apakah transaksi **ODQMON** (ODP Queue Monitor) sudah tersedia di source system? | H | |
| E3 | Apakah **RFC connection** antara BW dan ECC sudah menggunakan tipe **ODP**? <br> ☐ Ya <br> ☐ Masih classic (RFC type 3) <br> ☐ Tidak tahu | M | |
| E4 | Apakah ada DataSource yang **tidak bisa di-migrate ke ODP**? Sebutkan: | H | |
| E5 | Apakah ada requirement untuk **CDS View extraction** dari S/4HANA? <br> ☐ Ya, sudah diidentifikasi <br> ☐ Ya, belum diidentifikasi <br> ☐ Tidak diperlukan | M | |
| E6 | Apakah pernah menjalankan **SAP Readiness Check** atau **BW Migration Cockpit**? <br> ☐ Ya → Lampirkan hasil <br> ☐ Belum | H | |
| E7 | Apakah ada **SLT (SAP Landscape Transformation)** yang digunakan untuk replication? <br> ☐ Ya → Source tables: _______ <br> ☐ Tidak | M | |
| E8 | Volume data yang di-load/delta per hari ke BW? (estimasi records/GB) | M | |

---

## Bagian F — Arsitektur Target & S/4HANA Rise

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| F1 | Apakah target landscape S/4HANA Rise sudah tersedia? <br> ☐ Ya, sudah provisioned <br> ☐ Dalam proses procurement <br> ☐ Belum | H | |
| F2 | Edisi S/4HANA Rise yang dipilih: <br> ☐ S/4HANA Cloud Private Edition (PCE) <br> ☐ S/4HANA Cloud Public Edition <br> ☐ Belum ditentukan | H | |
| F3 | Apakah BW/4HANA akan di-deploy sebagai: <br> ☐ Embedded BW di S/4HANA (side-car) <br> ☐ Standalone BW/4HANA <br> ☐ SAP Datasphere (pengganti BW/4HANA) <br> ☐ Hybrid (BW/4HANA + Datasphere) <br> ☐ Belum ditentukan | H | |
| F4 | Hyperscaler yang digunakan untuk Rise: <br> ☐ AWS <br> ☐ Azure <br> ☐ GCP <br> ☐ Belum ditentukan | M | |
| F5 | Region/Datacenter yang dipilih? | M | |
| F6 | Apakah ada kebutuhan **SAP Analytics Cloud (SAC)** sebagai frontend? <br> ☐ Ya, sebagai pengganti BEx/AO <br> ☐ Ya, sebagai tambahan <br> ☐ Tidak <br> ☐ Sedang evaluasi | M | |
| F7 | Apakah ada kebutuhan **real-time replication** (SLT / CDC)? <br> ☐ Ya → Use case: _______ <br> ☐ Tidak, batch/delta cukup | M | |
| F8 | Apakah ada system lain yang perlu diintegrasi dengan BW/4HANA target? <br> (contoh: SAC, Datasphere, SuccessFactors, Ariba, Concur) | M | |

---

## Bagian G — Reporting & Analytics

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| G1 | Frontend reporting yang digunakan saat ini: <br> ☐ BEx Analyzer (Excel) <br> ☐ BEx Web (WAD) <br> ☐ Analysis for Office (AO) <br> ☐ SAP BusinessObjects (BO) <br> ☐ SAP Lumira / Discovery <br> ☐ SAP Analytics Cloud (SAC) <br> ☐ Crystal Reports <br> ☐ 3rd-party (Power BI, Tableau, dll): _______ | H | |
| G2 | Berapa jumlah **report/dashboard** yang aktif digunakan? | H | |
| G3 | Apakah ada report yang bersifat **regulatory/compliance** (wajib)? Sebutkan: | H | |
| G4 | Top 10 report yang paling sering digunakan (by user/frequency): | M | |
| G5 | Apakah ada kebutuhan **migrasi BEx Query → SAC Story**? <br> ☐ Ya, semua <br> ☐ Ya, sebagian <br> ☐ Tidak, tetap di AO/BEx <br> ☐ Belum ditentukan | M | |
| G6 | Apakah ada report yang menggunakan **planning/input-ready query (BPC/IP)**? <br> ☐ Ya → Jumlah: _______ <br> ☐ Tidak | H | |
| G7 | Apakah ada kebutuhan **Embedded Analytics** langsung dari S/4HANA (tanpa BW)? | M | |

---

## Bagian H — Security, Authorization & Governance

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| H1 | Apakah BW saat ini menggunakan **Analysis Authorization**? <br> ☐ Ya → Jumlah objek auth: _______ <br> ☐ Tidak (hanya standard role) | H | |
| H2 | Apakah ada requirement **row-level security** pada data BW? (contoh: per company code, per plant) | H | |
| H3 | Apakah ada **data masking/anonymization** requirement? (GDPR, PDP) | M | |
| H4 | Apakah ada **data retention policy**? Berapa lama data harus disimpan? <br> - Transactional: _______ tahun <br> - Master data: _______ tahun <br> - Aggregat: _______ tahun | M | |
| H5 | Apakah ada requirement **data archiving** (ILM / NLS)? | M | |
| H6 | Apakah ada audit/compliance requirement untuk akses data BW? | M | |
| H7 | Apakah menggunakan **SSO (Single Sign-On)** untuk akses BW? | L | |

---

## Bagian I — Tim, Timeline & Risiko

| No | Pertanyaan | Prioritas | Jawaban |
|----|-----------|:---------:|---------|
| I1 | Jumlah tim internal yang tersedia untuk proyek migrasi: <br> - Basis/Infrastructure: _______ orang <br> - BW/BI Developer: _______ orang <br> - Functional/Business Analyst: _______ orang <br> - Project Manager: _______ orang | H | |
| I2 | Apakah ada kebutuhan **external consultant/partner**? <br> ☐ Ya, sudah ada partner <br> ☐ Ya, belum ada partner <br> ☐ Tidak, internal saja | M | |
| I3 | Target timeline migrasi: <br> - Kick-off: _______ <br> - Development: _______ <br> - UAT: _______ <br> - Go-live: _______ | H | |
| I4 | Apakah ada **project/system lain** yang berjalan paralel dan bisa impact? (contoh: ECC → S/4HANA migration, SuccessFactors rollout) | H | |
| I5 | Apakah ada **downtime constraint**? (contoh: max downtime weekend only, month-end freeze) | M | |
| I6 | Risiko terbesar yang dikhawatirkan: (pilih max 3) <br> ☐ Data loss / inconsistency <br> ☐ Performance degradation <br> ☐ Report discrepancy (angka tidak cocok) <br> ☐ Timeline overrun <br> ☐ Budget overrun <br> ☐ Skill gap tim internal <br> ☐ Business disruption <br> ☐ Lainnya: _______ | H | |
| I7 | Apakah ada **change management / training plan** untuk end-user? <br> ☐ Ya, sudah direncanakan <br> ☐ Belum <br> ☐ Tidak diperlukan | M | |
| I8 | Apakah ada **lesson learned** dari proyek migrasi SAP sebelumnya? | L | |

---

## Bagian J — Lampiran & Dokumen Pendukung

Mohon lampirkan dokumen berikut (jika tersedia):

| No | Dokumen | Status |
|----|---------|--------|
| J1 | Export daftar DataSource aktif (RSA5/RSA6) | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J2 | Daftar InfoProvider aktif (RSDM / RSZC) | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J3 | Daftar Process Chain aktif | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J4 | Daftar BEx Query aktif (RSRT usage stats) | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J5 | SAP Readiness Check / Simplification List | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J6 | Current system landscape diagram | ☐ Terlampir ☐ Menyusul ☐ N/A |
| J7 | BW Migration Cockpit report (jika ada) | ☐ Terlampir ☐ Menyusul ☐ N/A |

---

## Tanda Tangan

| | Pengisi | Reviewer |
|---|---------|----------|
| **Nama** | | |
| **Jabatan** | | |
| **Tanggal** | | |
| **Tanda Tangan** | | |

---

*Dokumen ini bersifat **rahasia** dan hanya untuk keperluan assessment migrasi BW to S/4HANA Rise.*  
*Harap dikembalikan dalam **2 minggu kerja** ke PIC proyek.*
