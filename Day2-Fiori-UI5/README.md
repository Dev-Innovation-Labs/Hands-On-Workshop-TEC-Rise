# 📒 Hari 2: SAP Fiori & SAPUI5 — Build UI dari CAP Service

> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development  
> **Durasi:** 8 Jam (09:00 – 17:00)  
> **Prasyarat:** Selesai Hari 1 (CAP project bookshop berjalan di localhost:4004)  
> **BTP Trial:** Region ap21 (Singapore-Azure) | Org: 3220086dtrial | Space: dev

---

## 🎯 Learning Objectives

Setelah menyelesaikan Hari 2, peserta mampu:
- Memahami SAP Fiori Design Principles dan 5 Fiori Principles
- Membedakan Fiori Elements vs Custom SAPUI5 (Freestyle)
- Membuat Fiori Elements List Report & Object Page dari CAP OData service
- Menggunakan Fiori Annotations (UI, Common) untuk mengkonfigurasi tampilan
- Menggunakan SAP Fiori tools dan Yeoman generator (`yo @sap/fiori`)
- Menjalankan Fiori app secara lokal di atas CAP server (`cds watch`)

---

## 📅 Jadwal Hari 2

| Waktu | Sesi | Durasi |
|-------|------|--------|
| 09:00 – 09:15 | Recap Hari 1 | 15 menit |
| 09:15 – 10:30 | **Teori: Fiori Design & Arsitektur** | 75 menit |
| 10:30 – 10:45 | Coffee Break | 15 menit |
| 10:45 – 12:00 | **Hands-on: Generate Fiori App dengan Yeoman** | 75 menit |
| 12:00 – 13:00 | Istirahat Makan Siang | 60 menit |
| 13:00 – 14:30 | **Hands-on: Fiori Annotations & Customization** | 90 menit |
| 14:30 – 14:45 | Coffee Break | 15 menit |
| 14:45 – 16:30 | **Hands-on: Fiori Launchpad & Custom Views** | 105 menit |
| 16:30 – 17:00 | Review, Q&A & Wrap-up | 30 menit |

---

## 🧠 Test Pengetahuan Hari 1 — Sebelum Lanjut ke Hari 2

> **Tujuan:** Memastikan pemahaman fundamental dari Hari 1 sudah kuat sebelum membangun UI.
> Setiap skenario adalah situasi **nyata** yang mungkin terjadi di proyek SAP.
> Diskusikan jawaban bersama sebelum melanjutkan ke materi Fiori.

---

### Skenario 1: 🏢 Migrasi Global Account Perusahaan

**Situasi:** PT Nusantara Jaya baru mendaftar SAP BTP Trial. CTO meminta Anda memetakan environment yang akan digunakan untuk development. Tim terdiri dari 5 developer, 2 basis admin, dan 1 security admin.

**Pertanyaan:**
1. Gambarkan hierarki BTP yang akan Anda buat: Global Account → Subaccount → CF Org → Space
2. Berapa **memory quota** yang tersedia di trial account? Apakah cukup untuk 5 developer sekaligus mendeploy app?
3. Jika region trial Anda adalah `ap21 (Singapore-Azure)`, apa CF API Endpoint yang digunakan?
4. Mengapa memilih region Singapore penting jika users berada di Indonesia?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. **Hierarki:**
   ```
   Global Account: 3220086dtrial (atau sesuai nomor customer)
   └── Subaccount: trial
       └── CF Org: 3220086dtrial
           └── Space: dev
   ```
   Di trial, hanya 1 subaccount, 1 org, 1 space. Di production, idealnya buat space terpisah: `dev`, `staging`, `prod`.

2. **Memory quota: 4,096 MB (4 GB)**. Untuk 5 developer, ini sangat terbatas — satu Fiori app memerlukan ~256-512 MB. Total hanya cukup untuk ~8-16 app kecil. Di production, gunakan CPEA (Cloud Platform Enterprise Agreement) dengan quota lebih besar.

3. **CF API Endpoint:** `https://api.cf.ap21.hana.ondemand.com`

4. **Latency & data residency** — Singapore memiliki latency ~20-40ms dari Indonesia vs ~200ms dari US/EU. Untuk trial ini cukup, tapi di production juga penting untuk **data sovereignty compliance** (UU PDP Indonesia).
</details>

---

### Skenario 2: 🔐 Akses Service Ditolak

**Situasi:** Anda baru saja menjalankan `cds watch` dan project bookshop berjalan di `localhost:4004`. Saat membuka `/odata/v4/catalog/Books` di browser, data muncul normal (5 buku). Tapi saat membuka `/odata/v4/admin/Authors`, browser menampilkan **401 Unauthorized**.

**Pertanyaan:**
1. Mengapa `CatalogService` bisa diakses tanpa login tapi `AdminService` tidak?
2. File CDS mana yang mengatur access control ini? Tuliskan sintaks yang membedakan keduanya.
3. Apa arti `@requires: 'authenticated-user'` dan `@requires: 'admin'`?
4. Di mode development (`cds watch`), autentikasi menggunakan strategi apa? Apa implikasinya?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. `CatalogService` dibuka sebagai read-only tanpa autentikasi, sedangkan `AdminService` memiliki anotasi `@requires` yang membatasi akses.

2. File: `srv/access-control.cds` atau di definisi service `srv/admin-service.cds`:
   ```cds
   // CatalogService — public read
   service CatalogService @(path:'/catalog') {
     @readonly entity Books as projection on bookshop.Books;
   }
   
   // AdminService — restricted
   @requires: 'authenticated-user'
   service AdminService @(path:'/admin') {
     entity Books as projection on bookshop.Books;
     entity Authors as projection on bookshop.Authors;
   }
   ```

3. `@requires: 'authenticated-user'` = user harus login (siapa saja yang terautentikasi). `@requires: 'admin'` = user harus memiliki role/scope `admin`.

4. **Strategi: `mocked`** (di `package.json` → `cds.requires.auth.strategy: "mocked"`). Artinya: tidak ada real authentication, tapi framework tetap men-enforce `@requires`. Untuk test akses admin, tambahkan header `Authorization: Basic` dengan user yang didefinisikan di `.cdsrc.json` atau default mock users.
</details>

---

### Skenario 3: 🗄️ Database Hilang Setelah Restart

**Situasi:** Anda sudah menambahkan 20 buku baru melalui OData `POST` request ke `AdminService`. Setelah makan siang, laptop Anda restart. Anda menjalankan `cds watch` kembali dan semua 20 buku baru **hilang** — hanya tersisa 5 buku sample awal.

**Pertanyaan:**
1. Mengapa data yang Anda tambahkan hilang?
2. Konfigurasi database apa yang digunakan secara default di development mode?
3. Dari mana 5 buku sample awal datang dan mengapa mereka selalu ada?
4. Bagaimana cara agar data **persist** (tidak hilang saat restart)?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. CAP di development mode menggunakan **SQLite in-memory database** (`:memory:`). Semua data disimpan di RAM — saat proses `cds watch` berhenti, database hilang.

2. Di `package.json`:
   ```json
   "cds": {
     "requires": {
       "db": {
         "kind": "sql",
         "[development]": { "kind": "sqlite", "credentials": { "database": ":memory:" } }
       }
     }
   }
   ```

3. **CSV seed data** di folder `db/data/`:
   - `sap.capire.bookshop-Books.csv`
   - `sap.capire.bookshop-Authors.csv`
   
   Setiap kali `cds watch` start, file CSV ini otomatis di-load ke in-memory database. Itulah mengapa 5 buku selalu muncul kembali.

4. Ganti ke **file-based SQLite** (persisten di disk):
   ```json
   "[development]": { "kind": "sqlite", "credentials": { "database": "db.sqlite" } }
   ```
   Atau deploy ke **SAP HANA Cloud** (Hari 4) untuk production persistence.
</details>

---

### Skenario 4: 📦 Dependency Error Saat npm install

**Situasi:** Developer baru join tim. Dia clone project bookshop dari Git, lalu menjalankan `cds watch`. Terminal menampilkan error:
```
Error: Cannot find module '@sap/cds'
```

**Pertanyaan:**
1. Apa yang lupa dilakukan developer tersebut?
2. Tuliskan urutan command yang benar dari awal setelah clone project
3. Package apa saja yang dibutuhkan di `package.json` untuk CAP project minimal?
4. Apa perbedaan `@sap/cds` (runtime) vs `@sap/cds-dk` (dev kit)?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. Lupa menjalankan **`npm install`** — folder `node_modules` tidak ada di Git (di-ignore oleh `.gitignore`).

2. Urutan yang benar:
   ```bash
   git clone <repo-url>
   cd bookshop
   npm install          # ← WAJIB sebelum cds watch
   cds watch
   ```

3. Dependencies minimal di `package.json`:
   ```json
   "dependencies": {
     "@sap/cds": "^9",        // CAP runtime
     "express": "^4"           // HTTP server
   },
   "devDependencies": {
     "@cap-js/sqlite": "^2",   // SQLite adapter
     "@sap/cds-dk": "^9"       // CDS CLI & dev tools (global atau local)
   }
   ```

4. **`@sap/cds`** = runtime library yang digunakan saat app berjalan (dipanggil oleh `server.js`). **`@sap/cds-dk`** = development kit berisi CLI tools (`cds init`, `cds watch`, `cds add`, `cds build`, dll) — biasanya diinstall global (`npm i -g @sap/cds-dk`), tidak perlu di `node_modules` project.
</details>

---

### Skenario 5: 🌐 API Endpoint Tidak Bisa Diakses dari Frontend

**Situasi:** Junior developer membuat frontend JavaScript yang memanggil:
```javascript
fetch('http://localhost:4004/odata/v4/catalog/Books')
```
Di browser standalone berjalan OK. Tapi saat dijalankan dari Fiori app di port berbeda (`localhost:3000`), muncul CORS error di console browser.

**Pertanyaan:**
1. Apa itu CORS dan mengapa error ini muncul?
2. Mengapa di `cds watch` biasanya tidak terjadi CORS error untuk Fiori app?
3. Jika melakukan development frontend di port terpisah, bagaimana solusinya?
4. Di production (BTP), bagaimana CORS ditangani?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. **CORS (Cross-Origin Resource Sharing)** — browser memblokir request dari origin (protocol+host+port) berbeda demi keamanan. `localhost:3000` → `localhost:4004` = **cross-origin** (port berbeda).

2. Saat menggunakan `cds watch`, Fiori app disajikan dari **server yang sama** (`localhost:4004/books/webapp/`). Artinya origin sama → tidak ada CORS issue. CAP otomatis serve folder `app/` sebagai static files.

3. Solusi development:
   - **Proxy** — konfigurasikan dev server frontend untuk proxy `/odata/*` ke `localhost:4004` (di `ui5.yaml` atau `vite.config.js`)
   - **`cds.env`** — tambahkan `"cors": { "allowOrigin": ["http://localhost:3000"] }` (HANYA untuk dev!)
   
4. Di production BTP, semua disajikan melalui **App Router** (`@sap/approuter`) yang bertindak sebagai reverse proxy — frontend dan backend diakses dari domain yang sama melalui App Router → tidak ada CORS.
</details>

---

### Skenario 6: 📝 CDS Model Salah, Service Tidak Mau Start

**Situasi:** Anda menambahkan entity baru di `db/schema.cds`:
```cds
entity Suppliers {
  key ID : Integer;
  name : String(100);
  email : String;
  books : Association to many Books on books.supplier = $self
}
```
Tapi saat `cds watch`, muncul error: `"books" is not a valid element of "bookshop.Books"`.

**Pertanyaan:**
1. Apa yang salah dengan kode di atas?
2. Bagaimana cara memperbaikinya? Tuliskan CDS yang benar untuk relasi bidirectional (Supplier ↔ Books)
3. Apa perbedaan `Association to` vs `Composition of` di CDS?
4. Bagaimana cara menambahkan sample data CSV untuk entity baru ini?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. Entity `Books` belum memiliki field `supplier` — Anda mendefinisikan Association di `Suppliers` yang merujuk ke `books.supplier`, tapi field `supplier` belum ada di entity `Books`.

2. CDS yang benar — tambahkan foreign key di kedua sisi:
   ```cds
   // db/schema.cds
   entity Books {
     key ID : Integer;
     title  : String(100);
     ...
     supplier : Association to Suppliers;  // ← tambahkan ini
   }
   
   entity Suppliers {
     key ID : Integer;
     name   : String(100);
     email  : String;
     books  : Association to many Books on books.supplier = $self;
   }
   ```

3. **`Association to`** = referensi loose, independent lifecycle (Books & Suppliers bisa exist sendiri-sendiri). **`Composition of`** = parent-child, lifecycle terikat (jika parent dihapus, children ikut terhapus). Contoh: `Order` composition of `OrderItems` — hapus Order = hapus semua items-nya.

4. Buat file `db/data/bookshop-Suppliers.csv`:
   ```csv
   ID;name;email
   1;SAP Press;press@sap.com
   2;O'Reilly;info@oreilly.com
   3;Manning;contact@manning.com
   ```
   Nama file harus sesuai pattern: `<namespace>-<EntityName>.csv` — sesuai namespace di `schema.cds`.
</details>

---

### Skenario 7: ☁️ CF CLI Gagal Login

**Situasi:** Anda menjalankan `cf login` di terminal dan mendapat error:
```
FAILED
Unable to authenticate. Bad credentials
```
Padahal username dan password BTP Cockpit Anda benar (bisa login ke cockpit via browser).

**Pertanyaan:**
1. Apa API Endpoint yang harus digunakan? Tuliskan command `cf login` lengkap
2. Apakah password BTP Cockpit dan CF CLI sama? Jelaskan mekanismenya
3. Apa yang harus dicek jika tetap gagal meskipun credential benar?
4. Setelah sukses login, command apa untuk memverifikasi target Anda?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. Command lengkap:
   ```bash
   cf login -a https://api.cf.ap21.hana.ondemand.com
   # Lalu masukkan email SAP (bukan S-user) & password
   ```

2. **Ya, sama** — BTP Cockpit dan CF CLI menggunakan **SAP Identity Authentication** yang sama (biasanya email address + password SAP universal ID). Jika menggunakan SSO/2FA di browser, gunakan:
   ```bash
   cf login -a https://api.cf.ap21.hana.ondemand.com --sso
   # Akan membuka browser untuk login, lalu copy passcode ke terminal
   ```

3. Yang perlu dicek:
   - **API Endpoint** benar sesuai region (ap21 untuk Singapore)
   - **Password** tidak expired (cek di accounts.sap.com)
   - **Trial account** belum expired (30-hari, harus di-extend)
   - CF environment sudah **diaktifkan** di subaccount (Cockpit → Cloud Foundry → Enable)

4. Verifikasi setelah login:
   ```bash
   cf target          # Tampilkan org, space, API endpoint
   cf spaces          # List semua spaces
   cf apps            # List app yang sudah di-deploy
   cf services        # List service instances
   ```
</details>

---

### Skenario 8: 🔨 Menambah Service Baru ke CAP Project

**Situasi:** Manager meminta Anda menambahkan `ReportService` baru yang menyediakan endpoint untuk mengambil ringkasan statistik buku: total buku, rata-rata harga, dan buku termahal. Service ini hanya boleh diakses oleh role `analyst`.

**Pertanyaan:**
1. File apa saja yang perlu dibuat?
2. Tuliskan definisi CDS service dengan function/action yang sesuai
3. Tuliskan handler JavaScript-nya
4. Bagaimana cara mengetes endpoint ini di browser/Postman saat `cds watch`?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. Dua file:
   - `srv/report-service.cds` — definisi service
   - `srv/report-service.js` — handler/logic

2. Definisi CDS:
   ```cds
   using { sap.capire.bookshop as bookshop } from '../db/schema';

   @requires: 'analyst'
   service ReportService @(path: '/report') {
     function getBookStats() returns {
       totalBooks   : Integer;
       averagePrice : Decimal(10,2);
       mostExpensive: String;
     };
   }
   ```

3. Handler JavaScript:
   ```javascript
   const cds = require('@sap/cds');
   
   module.exports = class ReportService extends cds.ApplicationService {
     async init() {
       const { Books } = cds.entities('sap.capire.bookshop');
       
       this.on('getBookStats', async () => {
         const books = await SELECT.from(Books);
         const totalBooks = books.length;
         const averagePrice = books.reduce((sum, b) => sum + b.price, 0) / totalBooks;
         const mostExpensive = books.sort((a,b) => b.price - a.price)[0]?.title;
         return { totalBooks, averagePrice, mostExpensive };
       });
       
       await super.init();
     }
   };
   ```

4. Testing saat `cds watch`:
   - Browser: `http://localhost:4004/report/getBookStats()` → akan return 401 (karena `@requires: 'analyst'`)
   - Gunakan mock user: `curl -u analyst: http://localhost:4004/report/getBookStats()` (CAP mocked auth menyediakan default users berdasarkan role name)
</details>

---

### Skenario 9: 📊 OData Query untuk Dashboard

**Situasi:** Tim frontend membutuhkan data dari CAP backend dengan requirement berikut:
- Ambil buku dengan stok > 0
- Urutkan dari harga termahal
- Hanya ambil 5 buku teratas
- Hanya perlu field: title, price, stock
- Sertakan data author (nama)

**Pertanyaan:**
1. Tuliskan URL OData lengkap yang memenuhi semua requirement di atas
2. Apa perbedaan `$filter`, `$orderby`, `$top`, `$select`, dan `$expand`?
3. Jika ada 1000 buku dan frontend perlu pagination (25 per halaman), query apa untuk halaman ke-3?
4. Bagaimana cara mendapatkan total count buku bersamaan dengan data?

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. URL OData lengkap:
   ```
   /odata/v4/catalog/Books?$filter=stock gt 0&$orderby=price desc&$top=5&$select=title,price,stock&$expand=author($select=name)
   ```

2. Penjelasan query options:
   | Option | Fungsi | SQL Equivalent |
   |--------|--------|---------------|
   | `$filter=stock gt 0` | Filter data | `WHERE stock > 0` |
   | `$orderby=price desc` | Urutan sorting | `ORDER BY price DESC` |
   | `$top=5` | Batas jumlah data | `LIMIT 5` |
   | `$select=title,price,stock` | Pilih kolom | `SELECT title, price, stock` |
   | `$expand=author` | Join relasi | `LEFT JOIN Authors` |

3. Halaman ke-3 (25 per halaman, skip 50):
   ```
   /odata/v4/catalog/Books?$top=25&$skip=50&$orderby=price desc
   ```

4. Tambahkan `$count=true`:
   ```
   /odata/v4/catalog/Books?$count=true&$top=25&$skip=50
   ```
   Response akan menyertakan `"@odata.count": 1000` di body JSON.
</details>

---

### Skenario 10: 🚀 Persiapan Production — Checklist BTP

**Situasi:** Project bookshop sudah selesai development. CTO bertanya: "Apa saja yang perlu disiapkan sebelum deploy ke production di BTP?" Buat daftar checklist berdasarkan pengetahuan Hari 1.

**Pertanyaan:**
1. Layanan BTP apa saja yang harus di-entitle (aktifkan) sebelum deploy?
2. Apa perbedaan database development (SQLite) vs production (HANA Cloud)?
3. Bagaimana autentikasi berubah dari development (`mocked`) ke production?
4. Sebutkan minimal 5 hal yang harus dicek sebelum `cf push`

<details>
<summary><b>💡 Kunci Jawaban</b></summary>

1. **Entitlements yang dibutuhkan:**
   | Service | Plan | Fungsi |
   |---------|------|--------|
   | SAP HANA Cloud | hana-free / hana | Database production |
   | SAP HANA Schemas & HDI Containers | hdi-shared | Deploy DB artifacts |
   | Cloud Foundry Runtime | MEMORY | App runtime (MB quota) |
   | Authorization & Trust (XSUAA) | application | Auth & authorization |
   | HTML5 Application Repository | app-host | Host Fiori static files |
   | Destination Service | lite | Koneksi ke backend |
   | SAP Build Work Zone / Launchpad | standard | Entry point UI |

2. **SQLite vs HANA Cloud:**
   | Aspek | SQLite (Dev) | HANA Cloud (Prod) |
   |-------|-------------|-------------------|
   | Storage | In-memory / file lokal | Cloud persistent |
   | Scale | Single user | Enterprise multi-tenant |
   | Features | Basic SQL | Column store, full-text, spatial, graph |
   | Data | Reset setiap restart (in-memory) | Persistent, backed up |
   | Cost | Gratis | Berbayar (free tier tersedia) |

3. **Auth development → production:**
   - Dev: `"strategy": "mocked"` → user palsu, tanpa login
   - Prod: `"strategy": "JWT"` → XSUAA menerbitkan JWT token, user login via SAP IDP
   - File konfigurasi: `xs-security.json` (mendefinisikan scopes, roles, role-templates)

4. **Checklist sebelum deploy:**
   - ✅ `mta.yaml` atau `manifest.yml` sudah benar (descriptor deployment)
   - ✅ `xs-security.json` mendefinisikan roles & scopes
   - ✅ Database profile switch ke `[production]` → HANA
   - ✅ Auth strategy switch ke `JWT` (bukan mocked)
   - ✅ Entitlements sudah di-assign di subaccount
   - ✅ CF target sudah ke org/space yang benar (`cf target`)
   - ✅ `npm run build` atau `cds build --production` sukses tanpa error
   - ✅ Semua environment variables & secrets dikonfigurasi (bukan hardcode)
   - ✅ Memory allocation cukup di CF space
   - ✅ Test OData endpoints di local sudah clean (tidak ada error)
</details>

---

### 📊 Penilaian Mandiri

| Level | Skenario Terjawab | Status |
|-------|-------------------|--------|
| ⭐ Pemula | 1 – 3 skenario | Perlu review ulang materi Hari 1 |
| ⭐⭐ Menengah | 4 – 6 skenario | Pemahaman dasar sudah cukup, lanjut Hari 2 |
| ⭐⭐⭐ Mahir | 7 – 9 skenario | Pemahaman kuat, siap untuk Hari 2 |
| ⭐⭐⭐⭐ Expert | 10 skenario | Excellent! Anda bisa membantu peserta lain |

> **Catatan untuk Trainer:** Diskusikan minimal skenario 1, 2, 3, dan 9 secara interaktif
> sebelum masuk ke materi Fiori. Ini memastikan fondasi BTP, CDS, dan OData sudah solid.

---

## 📖 Materi Sesi 1: SAP Fiori Design & Arsitektur (Teori Lengkap)

### 💡 Penjelasan Sederhana & Analogi Dunia Nyata

Banyak istilah baru di Hari 2. Mari kita pahami dulu sebelum mulai coding:

> **🏠 SAP Fiori = Desain Interior Standar IKEA**
>
> Bayangkan Anda membangun rumah (aplikasi). Anda bisa:
> - **Beli furniture IKEA** (Fiori Elements) — tinggal rakit pakai instruksi, hasilnya rapi dan standar
> - **Buat furniture custom** (Freestyle SAPUI5) — desain sendiri, lebih fleksibel tapi butuh lebih banyak kerja
>
> | Istilah | Analogi | Penjelasan |
> |:--------|:--------|:-----------|
> | **SAP Fiori** | Standar desain IKEA | Panduan desain UI agar semua app SAP konsisten |
> | **Fiori Elements** | Furniture IKEA (pre-built) | Template UI auto-generated dari annotations — minim coding |
> | **Freestyle SAPUI5** | Furniture custom | UI ditulis manual dengan XML + JavaScript — full kontrol |
> | **List Report** | Halaman katalog toko | Halaman tabel dengan filter & search — untuk browsing data |
> | **Object Page** | Halaman detail produk | Halaman detail satu item — header, tabs, sections |
> | **Annotations** | Label & instruksi di furniture | Metadata CDS yang mengontrol tampilan UI (kolom, filter, header) |
> | **manifest.json** | Buku manual app | File config utama: data source, routing, model |
> | **MVC** | Restoran | **Model**=Dapur (data), **View**=Menu (tampilan), **Controller**=Pelayan (logic) |
> | **Yeoman Generator** | Mesin cetak furniture | Tool CLI yang generate scaffolding Fiori app otomatis |
> | **OData Binding** | Pipa air ke dapur | Koneksi otomatis antara UI dan data backend |
>
> **Alur Fiori Elements:**
> ```
> CDS Model (Hari 1)
>   → + Annotations (@UI.LineItem, @UI.HeaderInfo)
>     → Fiori Elements Runtime membaca annotations
>       → UI ter-generate otomatis! 🎨
>
> Anda TIDAK menulis HTML/XML untuk tabel, filter, form.
> Cukup tulis annotations di CDS — UI langsung jadi.
> ```

---

### 📜 1. Sejarah & Evolusi UI di SAP

Untuk memahami **mengapa SAP Fiori ada**, kita perlu melihat evolusi UI di ekosistem SAP:

```
Timeline Evolusi SAP UI:
═══════════════════════════════════════════════════════════════════

1992 ─── SAP GUI (R/3)
         │  • Desktop client, tampilan green-screen style
         │  • Transaction codes (T-codes): VA01, MM01, SE38
         │  • Complex, overwhelming, ratusan field per screen
         │  • Training berminggu-minggu untuk user baru
         │
2004 ─── SAP Web Dynpro (NetWeaver)
         │  • Web-based, tapi masih kompleks
         │  • Server-side rendering
         │  • Masih terasa "SAP-ish", bukan modern web
         │
2010 ─── SAPUI5 (HTML5 Toolkit)
         │  • Framework JavaScript modern (berbasis jQuery & OpenUI5)
         │  • Client-side rendering, responsive
         │  • MVC pattern, OData integration
         │  • Open source version: OpenUI5
         │
2013 ─── SAP Fiori 1.0 (25 apps pertama)
         │  • Design language baru — clean, modern, role-based
         │  • Fiori Launchpad sebagai entry point
         │  • Fokus: 1 app = 1 task (simplicity)
         │
2016 ─── SAP Fiori 2.0
         │  • Overview Page, improved navigation
         │  • Copilot (digital assistant, early version)
         │  • Notification center
         │
2019 ─── SAP Fiori 3.0
         │  • Tema baru: Quartz Light/Dark
         │  • Web Components (ui5-webcomponents)
         │  • Consistent design across all SAP products
         │
2021 ─── SAP Fiori Horizon
         │  • Visual theme terbaru — lebih fresh & modern
         │  • Rounded corners, warmer colors, improved spacing
         │  • Default theme untuk BTP & S/4HANA Cloud
         │
2023+ ── SAP Fiori + AI
           • SAP Joule integration
           • AI-assisted Fiori Elements
           • Smart controls & intelligent recommendations
```

**Mengapa Fiori?** SAP GUI sangat powerful tapi user experience-nya buruk. Bayangkan seorang warehouse staff yang hanya perlu scan barcode dan konfirmasi — tapi harus navigasi 5 T-code dan 200 field. Fiori memperbaiki ini dengan prinsip **"1 app, 1 task"**.

---

### 🏗️ 2. SAP Fiori 5 Principles (Detail)

SAP Fiori dibangun di atas 5 prinsip desain fundamental. Ini bukan sekadar slogan — setiap prinsip mempengaruhi arsitektur dan implementasi app:

#### ① ROLE-BASED — Konten Berdasarkan Peran

```
Prinsip: Setiap user hanya melihat apa yang relevan dengan perannya.

Contoh Konkret:
┌─────────────────────────────────────────────────┐
│  WAREHOUSE MANAGER                               │
│  ┌─────┐  ┌─────────┐  ┌──────────┐             │
│  │Stock│  │Delivery  │  │Inventory │             │
│  │Check│  │Schedule  │  │Count     │             │
│  └─────┘  └─────────┘  └──────────┘             │
├─────────────────────────────────────────────────┤
│  FINANCE CONTROLLER                              │
│  ┌──────┐  ┌─────────┐  ┌──────────┐            │
│  │P&L   │  │Budget   │  │Invoice   │            │
│  │Report│  │Overview │  │Approval  │            │
│  └──────┘  └─────────┘  └──────────┘            │
├─────────────────────────────────────────────────┤
│  SALES REP                                       │
│  ┌──────┐  ┌─────────┐  ┌──────────┐            │
│  │My    │  │Customer  │  │Create   │            │
│  │Leads │  │360°     │  │Quote    │            │
│  └──────┘  └─────────┘  └──────────┘            │
└─────────────────────────────────────────────────┘

Implementasi Teknis:
• Fiori Launchpad Roles & Catalogs
• PFCG roles di backend
• XSUAA scopes di BTP (workshop Hari 4)
```

#### ② DELIGHTFUL — UX yang Menyenangkan

```
Prinsip: Interaksi harus intuitif, "zero-training" jika memungkinkan.

Elemen Delightful:
• Micro-interactions    → loading indicators, smooth transitions
• Visual feedback       → success/error colors, toast messages  
• Smart defaults        → pre-filled fields berdasarkan konteks
• Undo capability       → user bisa revert aksi tanpa rasa takut
• Progressive disclosure → informasi kompleks ditampilkan bertahap

❌ SAP GUI Way:   Transaction VA01 → 6 tabs → 50+ fields → Save → "Document 123456 created"
✅ Fiori Way:      Create Order → 5 essential fields → Review → Confirm → Green toast "Order created ✓"
```

#### ③ COHERENT — Konsisten di Seluruh Aplikasi

```
Prinsip: Semua app SAP terlihat dan terasa sama.

Aspek Koherensi:
┌───────────────────────────────────────────────────┐
│ Visual Consistency                                 │
│ • Sama font (72 font family)                       │
│ • Sama color palette (Horizon theme)               │
│ • Sama icon set (SAP icons)                        │
│ • Sama spacing & layout grid                       │
├───────────────────────────────────────────────────┤
│ Interaction Consistency                            │
│ • Filter bar selalu di atas tabel                  │
│ • Navigation: List → Detail → Sub-detail           │
│ • Actions: primary button selalu di kanan          │
│ • Delete selalu minta konfirmasi                   │
├───────────────────────────────────────────────────┤
│ Data Consistency                                   │
│ • Date format mengikuti user locale                │
│ • Currency selalu dengan kode ISO                  │
│ • Status menggunakan semantic colors               │
│   (Green=Positive, Red=Negative, Orange=Critical)  │
└───────────────────────────────────────────────────┘
```

#### ④ SIMPLE — Satu Tugas Utama per Aplikasi

```
Prinsip: Setiap app fokus pada SATU use case/task utama.

Contoh Perbandingan:

SAP GUI Transaction MM01 (Material Master):
┌──────────────────────────────────────┐
│ 13 tabs, 500+ fields                 │
│ Basic Data, Sales, Purchasing,       │
│ MRP, Accounting, Costing, ...        │
│ User harus tahu T-code mana          │
│ untuk task mana                       │
└──────────────────────────────────────┘

Fiori Approach (dipecah jadi beberapa app):
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Manage     │  │ Display    │  │ Change     │
│ Product    │  │ Material   │  │ Material   │
│ Master     │  │ Documents  │  │ Group      │
│            │  │            │  │            │
│ F0842      │  │ F1597      │  │ F2708      │
└────────────┘  └────────────┘  └────────────┘

Setiap app punya App ID di SAP Fiori Apps Library:
https://fioriappslibrary.hana.ondemand.com/
```

#### ⑤ ADAPTIVE — Responsive di Semua Device

```
Prinsip: Satu codebase, optimal di desktop, tablet, dan mobile.

Responsive Behavior:
┌────────────────────────────────────────────────────────────┐
│ DESKTOP (≥1440px)                                          │
│ ┌──────────┬─────────────────────────────────────────────┐ │
│ │ List     │ Detail (Object Page)                        │ │
│ │ Report   │ ┌─────────────────────────────────────────┐ │ │
│ │          │ │ Header                                  │ │ │
│ │ [row 1]  │ │ Section 1 | Section 2 | Section 3      │ │ │
│ │ [row 2]  │ │                                         │ │ │
│ │ [row 3]  │ │ ┌─────────────┐ ┌─────────────┐        │ │ │
│ │          │ │ │ Field Group │ │ Field Group │        │ │ │
│ │          │ │ └─────────────┘ └─────────────┘        │ │ │
│ └──────────┴─┴─────────────────────────────────────────┘ │ │
│ → Flexible Column Layout (2 atau 3 kolom)                │
└────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│ TABLET (600-1439px)  │
│ ┌──────────────────┐ │
│ │ List Report      │ │
│ │ (full width)     │ │
│ │ [row 1] →        │ │
│ │ [row 2] →        │ │
│ └──────────────────┘ │
│ → Navigate to        │
│   separate detail    │
│   page               │
└──────────────────────┘

┌────────────┐
│ MOBILE     │
│ (< 600px)  │
│ ┌────────┐ │
│ │ Card   │ │
│ │ View   │ │
│ │        │ │
│ │ [item] │ │
│ │ [item] │ │
│ │ [item] │ │
│ └────────┘ │
│ → Simplified│
│   layout   │
└────────────┘

SAPUI5 Responsive APIs:
• sap.f.FlexibleColumnLayout   → 1/2/3 column layout
• sap.m.SplitApp              → master-detail pattern
• Device API                   → sap.ui.Device.system.phone / tablet / desktop
• CSS Rem units                → scalable typography
• @media queries               → handled otomatis oleh framework
```

---

### 🖥️ 3. SAP Fiori Launchpad (FLP): Pintu Masuk ke Dunia Fiori

Fiori Launchpad adalah **single entry point** untuk semua aplikasi Fiori. Bayangkan FLP sebagai **home screen di smartphone** — semua app ada di satu tempat.

```
Arsitektur Fiori Launchpad:
═══════════════════════════════════════════════════════════

                    ┌─────────────────────────────────┐
                    │       SAP Fiori Launchpad        │
                    │  ┌─────────────────────────────┐ │
                    │  │      Shell Bar               │ │
                    │  │  🏠 Home  🔔 Notif  👤 User │ │
                    │  ├─────────────────────────────┤ │
                    │  │     Me Area / User Menu      │ │
                    │  ├─────────────────────────────┤ │
  ┌──────────┐      │  │                             │ │
  │ Catalog  │──┐   │  │  ┌─────┐ ┌─────┐ ┌─────┐  │ │
  │ Service  │  │   │  │  │Tile │ │Tile │ │Tile │  │ │
  └──────────┘  │   │  │  │App1 │ │App2 │ │App3 │  │ │
  ┌──────────┐  ├──▶│  │  └─────┘ └─────┘ └─────┘  │ │
  │ Role     │  │   │  │                             │ │
  │ Assignment│──┘   │  │  ┌─────┐ ┌─────┐ ┌─────┐  │ │
  └──────────┘      │  │  │Tile │ │Tile │ │Tile │  │ │
  ┌──────────┐      │  │  │App4 │ │App5 │ │App6 │  │ │
  │ Target   │──────│  │  └─────┘ └─────┘ └─────┘  │ │
  │ Mapping  │      │  │                             │ │
  └──────────┘      │  └─────────────────────────────┘ │
                    └─────────────────────────────────┘

Komponen Utama FLP:
┌─────────────────────────────────────────────────────────┐
│ 1. TILES (Ubin)                                         │
│    • Static Tile      → icon + label tetap              │
│    • Dynamic Tile     → menampilkan angka real-time      │
│                        (misal: "5 Purchase Orders")     │
│    • KPI Tile         → KPI dengan trend indicator       │
│    • News Tile        → feed dari RSS/news               │
├─────────────────────────────────────────────────────────┤
│ 2. GROUPS                                               │
│    • Kumpulan tiles yang dikelompokkan                   │
│    • Misal: "Purchasing", "Finance", "HR"               │
│    • User bisa personalize (add/remove/reorder)          │
├─────────────────────────────────────────────────────────┤
│ 3. CATALOGS                                             │
│    • Kumpulan app yang tersedia untuk di-assign ke role  │
│    • Admin mendefinisikan catalog → assign ke role       │
├─────────────────────────────────────────────────────────┤
│ 4. SPACES & PAGES (Fiori 3.0+)                          │
│    • Pengganti Groups di versi terbaru                   │
│    • Spaces = container (misal "My Workspace")           │
│    • Pages  = kumpulan sections & tiles di dalam Space   │
│    • Lebih terstruktur dan admin-controlled              │
└─────────────────────────────────────────────────────────┘
```

**Di Workshop ini:** Kita akan membuat **FLP Sandbox lokal** di Hands-on 5, yang mensimulasikan launchpad di localhost tanpa perlu deploy ke BTP.

---

### 🌐 4. OData Protocol: Bahasa Komunikasi Fiori ↔ Backend

OData (Open Data Protocol) adalah **REST-based protocol** standar yang digunakan Fiori untuk berkomunikasi dengan backend. Di CAP, OData service otomatis di-generate dari CDS model.

```
Komunikasi Fiori ↔ Backend:
═══════════════════════════════════════════════════

  Browser (Fiori App)              Server (CAP/S/4HANA)
  ┌──────────────────┐            ┌──────────────────┐
  │                  │  HTTP GET  │                  │
  │  UI Controls     │──────────▶│  OData Service   │
  │  (Table, Form)   │           │  /catalog/Books  │
  │                  │◀──────────│                  │
  │  OData Model     │  JSON     │  CDS Model       │
  │  (auto-binding)  │  Response │  + Handlers      │
  └──────────────────┘            └──────────────────┘
```

#### OData V2 vs V4

```
┌────────────────────────────────────────────────────────────┐
│                    OData V2 vs V4                           │
├───────────────────┬────────────────┬───────────────────────┤
│ Aspek             │ OData V2       │ OData V4              │
├───────────────────┼────────────────┼───────────────────────┤
│ Format default    │ XML (Atom)     │ JSON                  │
│ Batch requests    │ Multipart      │ JSON batch            │
│ Actions/Functions │ Function Import│ Bound/Unbound Actions │
│ Deep insert       │ Terbatas       │ Full support          │
│ $expand           │ Basic          │ Nested $expand        │
│ Type system       │ Sederhana      │ Lebih kaya            │
│ CAP default       │ V2 available   │ ✅ V4 (default)       │
│ S/4HANA on-prem   │ ✅ Kebanyakan  │ Semakin banyak        │
│ S/4HANA Cloud     │ Legacy         │ ✅ Standar            │
│ BTP/CAP           │ Optional       │ ✅ Recommended        │
└───────────────────┴────────────────┴───────────────────────┘
```

#### OData CRUD Operations

```
CRUD Operations via OData:
═══════════════════════════════════════════════════════════

CREATE (POST):
  POST /catalog/Books
  Body: { "title": "New Book", "price": 29.99 }
  → Membuat record baru

READ (GET):
  GET /catalog/Books                           → Semua buku
  GET /catalog/Books(1)                        → Buku dengan ID=1
  GET /catalog/Books?$filter=price gt 20       → Filter: harga > 20
  GET /catalog/Books?$orderby=title asc        → Sort ascending
  GET /catalog/Books?$top=10&$skip=20          → Pagination
  GET /catalog/Books?$expand=author            → Include relasi author
  GET /catalog/Books?$select=title,price       → Hanya kolom tertentu
  GET /catalog/Books/$count                    → Jumlah total

UPDATE (PATCH):
  PATCH /catalog/Books(1)
  Body: { "price": 39.99 }
  → Update sebagian field

DELETE (DELETE):
  DELETE /catalog/Books(1)
  → Hapus record

ACTIONS (POST):
  POST /catalog/submitOrder
  Body: { "book": 1, "amount": 5 }
  → Custom business action (bukan CRUD standar)
```

#### OData Query Options yang Sering Dipakai

```
Query Options:
┌──────────────┬────────────────────────────────────┬──────────────────────┐
│ Option       │ Contoh                              │ Keterangan           │
├──────────────┼────────────────────────────────────┼──────────────────────┤
│ $filter      │ $filter=price gt 20                │ WHERE clause         │
│              │ $filter=contains(title,'SAP')      │ LIKE '%SAP%'         │
│              │ $filter=stock eq 0 or stock gt 100 │ OR condition         │
│ $orderby     │ $orderby=title asc,price desc      │ ORDER BY             │
│ $top / $skip │ $top=25&$skip=50                   │ LIMIT / OFFSET       │
│ $expand      │ $expand=author($select=name)       │ JOIN / eager load    │
│ $select      │ $select=ID,title,price             │ SELECT columns       │
│ $count       │ $count=true                        │ Include total count  │
│ $search      │ $search=fantasy                    │ Full-text search     │
│ $apply       │ $apply=groupby((genre),            │ Aggregation          │
│              │  aggregate(price with average))    │                      │
└──────────────┴────────────────────────────────────┴──────────────────────┘

Di Fiori Elements, query options ini otomatis di-generate:
• Filter bar → $filter
• Table sorting → $orderby
• Pagination → $top/$skip
• Navigation → $expand
```

---

### 🔧 5. SAPUI5: Framework di Balik Fiori

SAPUI5 adalah **JavaScript UI framework** yang menjadi fondasi semua aplikasi SAP Fiori. Ini adalah framework enterprise-grade dengan library kontrol (controls) yang sangat kaya.

#### SAPUI5 vs OpenUI5

```
┌────────────────────────────────────────────────────────┐
│               SAPUI5 vs OpenUI5                         │
├────────────────────┬───────────────────────────────────┤
│ SAPUI5             │ OpenUI5                            │
├────────────────────┼───────────────────────────────────┤
│ Proprietary (SAP)  │ Open Source (Apache 2.0)           │
│ 400+ controls      │ ~200 controls (subset)             │
│ Smart Controls ✅  │ Smart Controls ❌                  │
│ Fiori Elements ✅  │ Fiori Elements ❌                  │
│ Smart Templates ✅ │ Smart Templates ❌                 │
│ Chart controls ✅  │ Limited charts                     │
│ SAP support        │ Community support                  │
│ CDN: ui5.sap.com   │ CDN: openui5.hana.ondemand.com    │
├────────────────────┴───────────────────────────────────┤
│ Keduanya berbagi core yang sama:                        │
│ • sap.m (mobile controls)                              │
│ • sap.ui.core                                          │
│ • sap.ui.layout                                        │
│ • sap.ui.table                                         │
│ • OData model                                          │
│ • Data binding engine                                  │
└────────────────────────────────────────────────────────┘

Di workshop ini kita menggunakan SAPUI5 (via ui5.sap.com CDN).
```

#### SAPUI5 Control Libraries yang Penting

```
SAPUI5 Control Libraries:
═══════════════════════════════════════════════════════════

sap.m (Mobile & Desktop)          → Library utama, responsive
├── Table, List, Dialog            paling sering dipakai
├── Button, Input, Select
├── Page, App, Shell
├── MessageToast, MessageBox
└── SearchField, DatePicker

sap.f (Fiori-specific)            → Layout & patterns
├── FlexibleColumnLayout          untuk Fiori apps
├── DynamicPage, DynamicPageTitle
├── Avatar, Card
└── ShellBar

sap.fe (Fiori Elements)           → Template runtime
├── templates.ListReport           untuk declarative UI
├── templates.ObjectPage
├── templates.AnalyticalListPage
└── macros.* (building blocks)

sap.ui.table                      → Tabel besar/kompleks
├── Table (grid table)             dengan fixed header,
├── TreeTable                      virtual scrolling
└── AnalyticalTable

sap.ui.layout                     → Layouting
├── Grid, BlockLayout
├── form.SimpleForm
├── Splitter, ResponsiveFlowLayout
└── VerticalLayout, HorizontalLayout

sap.viz                           → Charts & Visualisasi
├── VizFrame (Bar, Line, Pie)
├── Popover
└── FlatTableDataset

sap.uxap                          → Object Page
├── ObjectPageLayout
├── ObjectPageSection
└── ObjectPageSubSection
```

#### SAPUI5 Application Lifecycle

```
SAPUI5 App Bootstrap & Lifecycle:
═══════════════════════════════════════════════════════════

1. Browser loads index.html
   └─▶ sap-ui-core.js dimuat dari CDN/local
       │
2. Core Initialization
   └─▶ data-sap-ui-* attributes dibaca
       │  • theme (sap_horizon)
       │  • libs (sap.m, sap.fe.templates)
       │  • resourceroots (namespace mapping)
       │
3. Component.js loaded
   └─▶ manifest.json dibaca (app descriptor)
       │  • Models di-instantiate (OData, i18n, JSON)
       │  • Router di-initialize
       │  • Root view di-create
       │
4. Router matches URL pattern
   └─▶ Target view di-load
       │
5. View Lifecycle:
   │
   │  onInit()              → Dipanggil sekali saat view dibuat
   │  onBeforeRendering()   → Sebelum DOM di-render
   │  onAfterRendering()    → Setelah DOM siap (bisa akses DOM)
   │  onExit()              → Cleanup saat view dihancurkan
   │
6. Data Binding aktif
   └─▶ OData requests dikirim ke backend
       └─▶ UI terupdate secara otomatis
```

---

### 🏛️ 6. SAPUI5 MVC Architecture (Detail)

MVC (Model-View-Controller) adalah pattern arsitektur utama di SAPUI5. Setiap komponen memiliki tanggung jawab yang jelas:

```
MVC Pattern Detail:
═══════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────┐
│                        VIEW (.xml)                       │
│  "Apa yang DILIHAT user"                                 │
│                                                          │
│  • Ditulis dalam XML (bisa juga JS/HTML/JSON, tapi XML  │
│    adalah best practice)                                 │
│  • Deklaratif: mendefinisikan layout & kontrol           │
│  • Data binding expressions: {modelName>propertyPath}   │
│  • Event handlers: press=".onButtonPress"               │
│                                                          │
│  Contoh:                                                 │
│  <Table items="{/Books}">                               │
│    <ColumnListItem>                                      │
│      <Text text="{title}"/>                             │
│      <ObjectNumber number="{price}" unit="{currency}"/> │
│    </ColumnListItem>                                     │
│  </Table>                                                │
├──────────────────────┬──────────────────────────────────┤
│                      │                                   │
│        ↕ Binding     │        ↕ Events                   │
│                      │                                   │
├──────────────────────┴──────────────────────────────────┤
│                     MODEL (Data Layer)                    │
│  "Data yang DITAMPILKAN"                                 │
│                                                          │
│  Tipe Model di SAPUI5:                                   │
│  ┌────────────────────────────────────────────────────┐  │
│  │ ODataModel (V4)  → koneksi ke OData backend       │  │
│  │ JSONModel        → data lokal dalam memori        │  │
│  │ ResourceModel    → file i18n (terjemahan)         │  │
│  │ XMLModel         → data dalam format XML          │  │
│  └────────────────────────────────────────────────────┘  │
│                                                          │
│  Didefinisikan di manifest.json bagian "models"         │
├─────────────────────────────────────────────────────────┤
│                  CONTROLLER (.js)                         │
│  "LOGIC di balik layar"                                  │
│                                                          │
│  • Menangani events dari view (onPress, onChange, dll)   │
│  • Membaca/menulis ke model                              │
│  • Navigation antar halaman                              │
│  • Business logic (validasi, kalkulasi)                  │
│  • TIDAK boleh manipulasi DOM langsung                   │
│                                                          │
│  Contoh:                                                 │
│  onSearch: function(oEvent) {                           │
│    const sQuery = oEvent.getParameter("query");         │
│    const oBinding = this.byId("table").getBinding();    │
│    oBinding.filter(new Filter("title","Contains",q));   │
│  }                                                       │
└─────────────────────────────────────────────────────────┘
```

#### Data Binding Types

```
Data Binding di SAPUI5:
═══════════════════════════════════════════════════════════

1. PROPERTY BINDING (one-way / two-way)
   Menghubungkan property kontrol ke data model.
   
   <Input value="{/customerName}"/>
   → Saat model berubah, input berubah
   → Saat user ketik, model berubah (two-way)

2. AGGREGATION BINDING (list binding)
   Menghubungkan repeating items ke collection di model.
   
   <List items="{/Products}">
     <StandardListItem title="{name}" description="{price}"/>
   </List>
   → Satu <StandardListItem> per item di array Products

3. ELEMENT BINDING (context binding)
   Menghubungkan seluruh kontrol ke satu object.
   
   // Di controller:
   this.getView().bindElement("/Products(1)");
   // Semua binding di view relatif ke Products(1)

4. EXPRESSION BINDING
   Logic sederhana di dalam binding expression.
   
   <Text text="{= ${price} > 100 ? 'Expensive' : 'Affordable' }"/>
   <ObjectStatus state="{= ${stock} > 10 ? 'Success' : 'Error' }"/>

Binding Modes:
┌──────────────┬────────────────────────────────────────┐
│ OneWay       │ Model → View (default untuk OData)     │
│ TwoWay       │ Model ↔ View (default untuk JSON)      │
│ OneTime      │ Model → View (sekali saat binding)     │
└──────────────┴────────────────────────────────────────┘
```

---

### 📐 7. Fiori Elements Floorplans (Template UI)

Fiori Elements menyediakan **template halaman (floorplan)** yang siap pakai. Anda hanya perlu mendeklarasikan data dan annotations — UI di-generate otomatis oleh runtime.

```
Fiori Elements Floorplans:
═══════════════════════════════════════════════════════════

1. LIST REPORT + OBJECT PAGE    ← Workshop ini!
   ┌──────────────────────────┐    ┌──────────────────────┐
   │ Filter Bar               │    │ ┌──────────────────┐ │
   │ ┌──────────────────────┐ │    │ │ Header Info      │ │
   │ │ [Filter] [Filter]    │ │    │ │ Title / Subtitle │ │
   │ └──────────────────────┘ │    │ │ KPI tiles        │ │
   │ ┌──────────────────────┐ │    │ └──────────────────┘ │
   │ │ Table                │ │    │ ┌──────────────────┐ │
   │ │ Col1 | Col2 | Col3  │ │ →  │ │ Section 1        │ │
   │ │ data | data | data  │ │    │ │ Field Group      │ │
   │ │ data | data | data  │ │    │ ├──────────────────┤ │
   │ └──────────────────────┘ │    │ │ Section 2        │ │
   │ Use case: Browse & select│    │ │ Sub-items table  │ │
   └──────────────────────────┘    └──────────────────────┘
   Use case: Data browsing,        Use case: View/edit
   filtering, search               detail of one record

2. WORKLIST
   ┌──────────────────────────┐
   │ Toolbar (no filter bar)  │
   │ ┌──────────────────────┐ │
   │ │ Table with actions   │ │
   │ │ ☐ item [Process]    │ │
   │ │ ☐ item [Process]    │ │
   │ │ ☐ item [Process]    │ │
   │ └──────────────────────┘ │
   │ Use case: Task list,     │
   │ quick processing         │
   └──────────────────────────┘

3. ANALYTICAL LIST PAGE (ALP)
   ┌──────────────────────────┐
   │ Visual Filter / KPIs     │
   │ ┌──────┐ ┌──────┐       │
   │ │Chart │ │Chart │       │
   │ └──────┘ └──────┘       │
   │ ┌──────────────────────┐ │
   │ │ Hybrid: Chart + Table│ │
   │ │ 📊 [switch] 📋      │ │
   │ └──────────────────────┘ │
   │ Use case: Analytics &    │
   │ data analysis            │
   └──────────────────────────┘

4. OVERVIEW PAGE (OVP)
   ┌──────────────────────────┐
   │ ┌──────┐ ┌──────┐       │
   │ │Card 1│ │Card 2│       │
   │ │List  │ │Chart │       │
   │ └──────┘ └──────┘       │
   │ ┌──────┐ ┌──────┐       │
   │ │Card 3│ │Card 4│       │
   │ │Table │ │Stack │       │
   │ └──────┘ └──────┘       │
   │ Use case: Dashboard      │
   │ overview, role-based     │
   └──────────────────────────┘

5. FORM ENTRY OBJECT PAGE
   ┌──────────────────────────┐
   │ ┌──────────────────────┐ │
   │ │ Form Header          │ │
   │ ├──────────────────────┤ │
   │ │ Field 1: [________]  │ │
   │ │ Field 2: [________]  │ │
   │ │ Field 3: [dropdown▼] │ │
   │ │ [Save]  [Cancel]     │ │
   │ └──────────────────────┘ │
   │ Use case: Create/Edit    │
   │ data entry                │
   └──────────────────────────┘
```

#### Decision Guide: Kapan Pakai Floorplan Mana?

```
Decision Tree - Pilih Floorplan:
═══════════════════════════════════════════════════════════

Tujuan user?
│
├─▶ Browse & search banyak data
│   └─▶ LIST REPORT + OBJECT PAGE ✅
│       (paling umum, default pilihan)
│
├─▶ Proses task satu per satu
│   └─▶ WORKLIST
│       (misal: approve PO, process invoices)
│
├─▶ Analisa data dengan chart & KPI
│   └─▶ ANALYTICAL LIST PAGE
│       (misal: sales analysis, financial reporting)
│
├─▶ Overview banyak data sekaligus
│   └─▶ OVERVIEW PAGE
│       (misal: manager dashboard, role home page)
│
├─▶ Isi/edit form data
│   └─▶ FORM ENTRY OBJECT PAGE
│       (misal: create material, edit customer)
│
└─▶ UI sangat custom / tidak standar
    └─▶ FREESTYLE SAPUI5
        (misal: custom dashboard, game-like UI)
```

---

### 🏷️ 8. CDS Annotations: Mengontrol UI dari Backend

Annotations adalah **metadata di CDS model** yang menginstruksikan Fiori Elements bagaimana menampilkan data. Ini adalah konsep paling penting di Hari 2.

#### Annotation Vocabularies

```
SAP CDS Annotation Vocabularies:
═══════════════════════════════════════════════════════════

@UI.*  (UI Vocabulary)
├── @UI.LineItem          → Kolom-kolom di tabel list report
├── @UI.HeaderInfo        → Judul & deskripsi di object page header
├── @UI.HeaderFacets      → KPI tiles di object page header
├── @UI.Facets            → Sections/tabs di object page body
├── @UI.FieldGroup        → Kumpulan field dalam satu group
├── @UI.SelectionFields   → Filter fields di filter bar
├── @UI.Chart             → Chart visualization
├── @UI.DataPoint         → Single value display (progres, rating)
├── @UI.Identification    → Actions yang tersedia
├── @UI.PresentationVariant → Default sort & group
├── @UI.SelectionVariant   → Default filter values
└── @UI.Hidden             → Sembunyikan field dari UI

@Common.*  (Common Vocabulary)
├── @Common.Label          → Label field
├── @Common.ValueList      → Value help / dropdown
├── @Common.ValueListWithFixedValues → Fixed dropdown
├── @Common.Text           → Display text untuk kode
├── @Common.TextArrangement → TextFirst / TextOnly / TextLast
├── @Common.FieldControl   → ReadOnly / Mandatory / Optional
└── @Common.SemanticKey    → Unique identifier fields

@Communication.*  (Contact Info)
├── @Communication.Contact → Contact card
└── @Communication.Address → Address display

@Measures.*  (Units)
├── @Measures.ISOCurrency  → Currency code (EUR, USD)
└── @Measures.Unit         → Unit of measure (KG, PC)

@Capabilities.*  (Service Capabilities)
├── @Capabilities.InsertRestrictions  → Boleh create?
├── @Capabilities.UpdateRestrictions  → Boleh update?
├── @Capabilities.DeleteRestrictions  → Boleh delete?
├── @Capabilities.FilterRestrictions  → Filter apa yang boleh?
└── @Capabilities.SortRestrictions    → Sort apa yang boleh?

@Validation.*  (Input Validation)
├── @assert.range          → Min/max value
├── @assert.format         → Regex pattern
└── @mandatory             → Required field
```

#### Contoh Lengkap Annotations & Efeknya di UI

```
Mapping Annotation → UI:
═══════════════════════════════════════════════════════════

CDS Annotation                          Hasil di UI
──────────────────                      ─────────────────

@UI.LineItem: [                         ┌────────────────────────────┐
  { Value: title },                     │ Title  │ Price │ Stock    │
  { Value: price },          →          ├────────┼───────┼──────────┤
  { Value: stock,                       │ Book A │ $25   │ 🟢 50   │
    Criticality: stockLevel }           │ Book B │ $40   │ 🔴 0    │
]                                       └────────────────────────────┘

@UI.SelectionFields: [                  ┌──────────────────────────────┐
  title, price, author_ID   →          │ [Title     ▼] [Price    ▼]  │
]                                       │ [Author    ▼]   [Go] [Adapt]│
                                        └──────────────────────────────┘

@UI.HeaderInfo: {                       ┌──────────────────────────────┐
  Title: { Value: title },              │ 📖 Clean Code                │
  Description:                →         │ Robert C. Martin              │
    { Value: authorName },              │ Type: Book                    │
  TypeName: 'Book'                      └──────────────────────────────┘
}

@UI.FieldGroup #Details: {             ┌──────────────────────────────┐
  Data: [                               │ General Information           │
    { Value: title },                   │ ┌────────────┬─────────────┐ │
    { Value: price },          →        │ │ Title:     │ Clean Code  │ │
    { Value: stock }                    │ │ Price:     │ $29.99      │ │
  ]                                     │ │ Stock:     │ 42          │ │
}                                       │ └────────────┴─────────────┘ │
                                        └──────────────────────────────┘

@UI.DataPoint #Rating: {               ┌──────────────────────────────┐
  Value: rating,                        │ Rating: ★★★★☆ (4/5)         │
  Visualization:               →        │                              │
    #Rating,                            └──────────────────────────────┘
  TargetValue: 5
}

Criticality Values:                     
  0 = Neutral (abu-abu)               ⚪ Neutral
  1 = Negative (merah)                🔴 Out of Stock
  2 = Critical (orange)               🟠 Low Stock  
  3 = Positive (hijau)                🟢 In Stock
```

---

### 🎨 9. SAP Fiori Theming & Visual Design

SAP menyediakan beberapa tema visual untuk Fiori apps. Theme mengontrol warna, font, spacing, dan overall feel.

```
SAP Themes:
═══════════════════════════════════════════════════════════

sap_horizon (2021+) ← DEFAULT & RECOMMENDED
├── Modern, warm colors
├── Rounded corners (8px border-radius)
├── Warmer color palette
├── Better contrast & accessibility
├── Variasi: Morning Horizon (light), Evening Horizon (dark)
│
sap_fiori_3 (2019)
├── Previous default
├── Clean & professional
├── Variasi: Light, Dark, High Contrast Black/White  
│
sap_belize (2016, legacy)
├── Bright blue headers
├── Masih dipakai di beberapa system lama
│
sap_bluecrystal (deprecated)
└── Sangat lama, jangan pakai

Mengganti Theme:
• Di index.html:  data-sap-ui-theme="sap_horizon"
• Di FLP:         User Settings → Appearance → Theme
• Via URL:        ?sap-ui-theme=sap_horizon_dark
• Custom Theme:   SAP UI Theme Designer (tool khusus)

SAP 72 Font Family:
• SAP menggunakan font "72" sebagai typography standar
• Tersedia: 72 Light, 72 Regular, 72 Bold, 72 Black
• Monospace: 72 Mono
• Di-load otomatis oleh SAPUI5 framework

Color Semantics (Horizon):
┌────────────────┬──────────────┬──────────────────────┐
│ Color          │ Hex          │ Penggunaan            │
├────────────────┼──────────────┼──────────────────────┤
│ Brand Color    │ #0070F2      │ Buttons, links, focus │
│ Positive       │ #30914C      │ Success, available    │
│ Negative       │ #E90B0B      │ Error, critical       │
│ Critical       │ #E76500      │ Warning, attention    │
│ Information    │ #0070F2      │ Info messages         │
│ Neutral        │ #788FA6      │ Inactive, neutral     │
└────────────────┴──────────────┴──────────────────────┘
```

---

### 🌍 10. Internationalization (i18n) di Fiori

Fiori apps mendukung multi-bahasa melalui **resource bundles** (file `.properties`).

```
i18n Architecture:
═══════════════════════════════════════════════════════════

webapp/i18n/
├── i18n.properties          ← Default (English)
├── i18n_de.properties       ← German
├── i18n_fr.properties       ← French
├── i18n_id.properties       ← Indonesian
└── i18n_ja.properties       ← Japanese

File format (key=value):
───────────────────────
# i18n.properties (English)
appTitle=Bookshop
bookTitle=Book Title
orderButton=Place Order
stockWarning=Stock is running low ({0} remaining)

# i18n_id.properties (Indonesian)  
appTitle=Toko Buku
bookTitle=Judul Buku
orderButton=Pesan Sekarang
stockWarning=Stok hampir habis ({0} tersisa)

Penggunaan di View:
  <Button text="{i18n>orderButton}"/>
  
Penggunaan di Controller:
  const oBundle = this.getView().getModel("i18n").getResourceBundle();
  const sText = oBundle.getText("stockWarning", [remaining]);

Bahasa dipilih berdasarkan:
1. URL parameter: ?sap-language=de
2. Browser language setting
3. User profile di Fiori Launchpad
4. Default fallback ke i18n.properties
```

---

### 🔧 11. SAP Fiori Tools & Developer Experience

SAP menyediakan berbagai tools untuk mempercepat development Fiori:

```
SAP Fiori Tools:
═══════════════════════════════════════════════════════════

1. SAP FIORI TOOLS (VS Code Extension Pack)
   ┌─────────────────────────────────────────────────────┐
   │ Fiori Application Generator                         │
   │ • Generate Fiori Elements & Freestyle apps          │
   │ • Wizard-based, pilih template → isi parameter      │
   │ • Command: yo @sap/fiori                            │
   │                                                     │
   │ Fiori Application Modeler                           │
   │ • Visual Page Map → lihat & edit halaman app        │
   │ • Drag-drop column, filter, section                 │
   │                                                     │
   │ Guided Development                                  │
   │ • Step-by-step guide untuk fitur tertentu            │
   │ • Misal: "Add filter bar" → kode digenerate         │
   │                                                     │
   │ Service Modeler                                     │
   │ • Visualisasi OData service                         │
   │ • Browse entities, properties, associations          │
   │                                                     │
   │ XML Annotation Language Server                      │
   │ • Autocomplete untuk annotations                    │
   │ • Validasi saat typing                              │
   └─────────────────────────────────────────────────────┘

2. SAP BUSINESS APPLICATION STUDIO (BAS)
   ┌─────────────────────────────────────────────────────┐
   │ • Cloud-based IDE (based on Eclipse Theia/VS Code)  │
   │ • Pre-configured untuk SAP development              │
   │ • Sudah terinstall semua Fiori tools                │
   │ • Integrated dengan BTP services                    │
   │ • Storyboard / Page Map visual editor               │
   └─────────────────────────────────────────────────────┘

3. UI5 TOOLING (CLI)
   ┌─────────────────────────────────────────────────────┐
   │ ui5 serve    → local dev server dengan livereload   │
   │ ui5 build    → production build (minify, bundle)    │
   │ ui5 init     → initialize ui5.yaml                  │
   │ ui5 add      → add SAPUI5 library dependency        │
   └─────────────────────────────────────────────────────┘

4. CAP + FIORI INTEGRATION
   ┌─────────────────────────────────────────────────────┐
   │ cds watch    → Run CAP server + serve Fiori apps    │
   │ cds add fiori → Add Fiori Elements app to CAP proj  │
   │                                                     │
   │ File structure:                                     │
   │ bookshop/                                           │
   │ ├── db/    (CDS models)                             │
   │ ├── srv/   (CDS services)                           │
   │ └── app/   (Fiori UI apps) ← Fiori lives here      │
   │     ├── books/webapp/                               │
   │     └── orders/webapp/                              │
   └─────────────────────────────────────────────────────┘
```

---

### ⚖️ 12. Fiori Elements vs Freestyle SAPUI5: Deep Comparison

```
Perbandingan Detail:
═══════════════════════════════════════════════════════════

┌────────────────────┬──────────────────────┬─────────────────────────┐
│ Aspek              │ Fiori Elements        │ Freestyle SAPUI5        │
├────────────────────┼──────────────────────┼─────────────────────────┤
│ Development effort │ ★☆☆☆☆ (sangat rendah)│ ★★★★☆ (tinggi)          │
│ Flexibility        │ ★★☆☆☆ (terbatas)     │ ★★★★★ (tak terbatas)    │
│ Maintenance        │ ★☆☆☆☆ (hampir nol)   │ ★★★☆☆ (manual)          │
│ SAP UX compliance  │ ★★★★★ (otomatis)      │ ★★★☆☆ (harus manual)    │
│ Learning curve     │ ★★☆☆☆ (annotations)   │ ★★★★☆ (JS+XML+MVC)     │
│ Upgrade safety     │ ★★★★★ (auto-upgrade)   │ ★★☆☆☆ (bisa breaking)   │
│ Customization      │ Extension points      │ Full control             │
│ Use case coverage  │ 80% business apps     │ 100% (any UI)           │
├────────────────────┴──────────────────────┴─────────────────────────┤
│                                                                      │
│  SAP Recommendation:                                                 │
│  "Use Fiori Elements whenever possible.                              │
│   Use Freestyle only when Fiori Elements cannot fulfill              │
│   the requirements."                                                 │
│                                                                      │
│  Alasan: Fiori Elements mendapat maintenance & upgrade gratis        │
│  dari SAP. Freestyle app harus di-maintain manual oleh developer.    │
└──────────────────────────────────────────────────────────────────────┘

Hybrid Approach (Best of Both Worlds):
┌──────────────────────────────────────────────────────────┐
│ Fiori Elements + Custom Extensions                       │
│                                                          │
│ Mulai dengan Fiori Elements, lalu extend dengan:         │
│ • Custom Columns    → tambah kolom custom di tabel       │
│ • Custom Sections   → tambah section di object page      │
│ • Custom Actions    → tambah button dengan custom logic  │
│ • Custom Fragments  → sisipkan UI custom di template     │
│ • Controller Ext.   → override lifecycle hooks           │
│                                                          │
│ Ini cara yang direkomendasikan SAP untuk kasus yang      │
│ butuh sedikit customization di atas template standar.    │
└──────────────────────────────────────────────────────────┘
```

---

### 📊 Ringkasan Teori — Peta Konsep

```
SAP Fiori Ecosystem — Mind Map:
═══════════════════════════════════════════════════════════

                        SAP Fiori
                           │
           ┌───────────────┼───────────────────┐
           │               │                   │
     Design System    Technology Stack     Delivery
     ┌─────────┐     ┌──────────────┐    ┌──────────┐
     │5 Princip│     │   SAPUI5      │    │   FLP    │
     │les      │     │   Framework   │    │(Launchpad│
     │Role-base│     │              │    │ )        │
     │Delightfl│     │ ┌──────────┐ │    │ Tiles    │
     │Coherent │     │ │ Controls │ │    │ Groups   │
     │Simple   │     │ │ sap.m    │ │    │ Catalogs │
     │Adaptive │     │ │ sap.f    │ │    │ Spaces   │
     └─────────┘     │ │ sap.fe   │ │    └──────────┘
                     │ └──────────┘ │
           ┌─────────┤              ├──────────┐
           │         │   OData V4   │          │
           │         │   Protocol   │          │
           │         └──────────────┘          │
    Fiori Elements              Freestyle SAPUI5
    (Declarative)                (Imperative)
    ┌──────────────┐          ┌──────────────┐
    │ Annotations  │          │ XML Views    │
    │ @UI.*        │          │ JS Controller│
    │ @Common.*    │          │ JSON/OData   │
    │              │          │ Model        │
    │ Floorplans:  │          │              │
    │ •List Report │          │ Full MVC     │
    │ •Object Page │          │ Pattern      │
    │ •ALP         │          │              │
    │ •OVP         │          │ Custom UI    │
    │ •Worklist    │          │ anything     │
    └──────────────┘          └──────────────┘

    Themes: sap_horizon (default) | sap_horizon_dark
    i18n:   .properties files per language
    Tools:  Fiori Tools + BAS + UI5 CLI + CAP
```

---

## 🛠️ Hands-on 1: Generate Fiori App dengan SAP Fiori Tools

### Langkah 1: Install Fiori Generator

```bash
# Di terminal (tools sudah terinstall dari setup workshop)
yo --version           # 7.0.0
cds --version          # @sap/cds-dk 9.8.3
node --version         # v24.11.0
```

### Langkah 2: Generate App via Yeoman

```bash
# Di dalam folder project CAP
cd ~/projects/bookshop

# Jalankan generator
yo @sap/fiori:elements-app

# Pilihan yang dimasukkan:
# ? Choose a template: List Report Page
# ? Select OData Service Source: Local CAP Node.js Project
# ? OData service: CatalogService
# ? Main entity: Books
# ? Navigation entity: None
# ? App name (module): books
# ? App namespace: com.tecrise
# ? Add app to project: Yes
```

### Struktur yang Dihasilkan

```
app/
└── books/
    ├── webapp/
    │   ├── manifest.json          ← App descriptor
    │   ├── Component.js           ← App component
    │   ├── index.html             ← Entry point
    │   └── i18n/
    │       └── i18n.properties    ← Translations
    ├── package.json
    └── ui5.yaml                   ← UI5 tooling config
```

### Langkah 3: Jalankan Fiori App

```bash
# Jalankan CAP backend + Fiori preview
cds watch

# Atau jalankan Fiori App saja (dari folder app/books):
cd app/books
npm start
```

**✅ Hasil yang Diharapkan:**

```
[cds] - serving CatalogService { at: ['/odata/v4/catalog'] }
[cds] - server listening on { url: 'http://localhost:4004' }
```

Buka browser:  
- `http://localhost:4004` — CAP Welcome Page, klik link **"books"** untuk buka Fiori app
- Anda akan melihat **List Report** dengan tabel Books (kolom Title, Author, Price, Stock)
- Klik salah satu baris → **Object Page** terbuka dengan detail buku

> **💡 Analogi:** Bayangkan Anda baru saja **merakit furniture IKEA**.
> Tanpa menulis HTML/CSS apapun, Anda sudah punya halaman tabel dan halaman detail
> yang tampilannya profesional — karena Fiori Elements yang generate-nya otomatis.

---

## 🛠️ Hands-on 2: Konfigurasi `manifest.json`

> **💡 Analogi:** `manifest.json` adalah **buku manual** aplikasi Fiori Anda.
> Di dalamnya tertulis: "data diambil dari mana" (dataSources), "halaman apa saja" (routes),
> dan "bagaimana navigasinya" (targets). Tanpa file ini, app tidak tahu harus ngapain.

### File: `app/books/webapp/manifest.json`

```json
{
    "_version": "1.49.0",
    "sap.app": {
        "id": "com.tecrise.books",
        "type": "application",
        "title": "{{appTitle}}",
        "description": "{{appDescription}}",
        "applicationVersion": { "version": "1.0.0" },
        "dataSources": {
            "mainService": {
                "uri": "/catalog/",
                "type": "OData",
                "settings": {
                    "annotations": ["annotation"],
                    "odataVersion": "4.0"
                }
            },
            "annotation": {
                "type": "ODataAnnotation",
                "uri": "/catalog/$metadata"
            }
        }
    },
    "sap.fiori": {
        "registrationIds": ["F1234"],
        "archeType": "transactional"
    },
    "sap.ui5": {
        "resources": {
            "js": [],
            "css": [{ "uri": "css/style.css" }]
        },
        "routing": {
            "routes": [{
                "name": "BooksList",
                "pattern": "",
                "target": "BooksList"
            },{
                "name": "BooksObjectPage",
                "pattern": "Books({key})",
                "target": "BooksObjectPage"
            }],
            "targets": {
                "BooksList": {
                    "type": "Component",
                    "id": "BooksList",
                    "name": "sap.fe.templates.ListReport",
                    "options": {
                        "settings": {
                            "entitySet": "Books",
                            "navigation": {
                                "Books": { "detail": { "route": "BooksObjectPage" } }
                            }
                        }
                    }
                },
                "BooksObjectPage": {
                    "type": "Component",
                    "id": "BooksObjectPage",
                    "name": "sap.fe.templates.ObjectPage",
                    "options": {
                        "settings": {
                            "entitySet": "Books"
                        }
                    }
                }
            }
        },
        "models": {
            "": {
                "dataSource": "mainService",
                "settings": { "synchronizationMode": "None" }
            },
            "i18n": {
                "type": "sap.ui.model.resource.ResourceModel",
                "settings": { "bundleName": "com.tecrise.books.i18n.i18n" }
            }
        }
    }
}
```

---

## 🛠️ Hands-on 3: Fiori Annotations

> **💡 Analogi:** Annotations itu seperti **label dan instruksi** di furniture IKEA.
>
> - `@UI.LineItem` = "Tampilkan kolom-kolom ini di halaman tabel"
> - `@UI.HeaderInfo` = "Di halaman detail, tampilkan judul dan deskripsi ini"
> - `@UI.Facets` = "Buat tab/section ini di halaman detail"
> - `@Common.ValueList` = "Tampilkan dropdown pilihan dari data ini"
>
> Anda **tidak menulis HTML** — cukup tulis annotations di file `.cds`,
> dan Fiori Elements otomatis generate UI-nya.

### File: `app/books/annotations.cds`

```cds
using CatalogService as service from '../../srv/catalog-service';

// ============================================
// LIST REPORT PAGE
// ============================================
annotate service.Books with @(
    UI.LineItem: [
        {
            $Type : 'UI.DataField',
            Value : title,
            Label : 'Book Title'
        },
        {
            $Type : 'UI.DataField',
            Value : authorName,
            Label : 'Author'
        },
        {
            $Type : 'UI.DataField',
            Value : price,
            Label : 'Price'
        },
        {
            $Type : 'UI.DataField',
            Value : stock,
            Label : 'Stock',
            Criticality: stockCriticality    // Colorize berdasarkan nilai
        },
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'CatalogService.submitOrder',
            Label : 'Order'
        }
    ]
);

// ============================================
// SELECTION FILTERS (Filter Bar)
// ============================================
annotate service.Books with @(
    UI.SelectionFields: [
        price,
        author_ID,
        genre_ID
    ]
);

// ============================================
// OBJECT PAGE — Header
// ============================================
annotate service.Books with @(
    UI.HeaderInfo: {
        TypeName       : 'Book',
        TypeNamePlural : 'Books',
        Title          : { $Type: 'UI.DataField', Value: title },
        Description    : { $Type: 'UI.DataField', Value: authorName },
        ImageUrl       : '/BookImages/{ID}'
    },

    // KPIs di header
    UI.HeaderFacets: [{
        $Type  : 'UI.ReferenceFacet',
        Target : '@UI.FieldGroup#KPIs'
    }],

    UI.FieldGroup #KPIs: {
        Data: [
            { Value: price,  Label: 'Price'  },
            { Value: stock,  Label: 'Stock'  }
        ]
    }
);

// ============================================
// OBJECT PAGE — Sections (Facets)
// ============================================
annotate service.Books with @(
    UI.Facets: [
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'GeneralInfo',
            Label  : 'General Information',
            Target : '@UI.FieldGroup#GeneralInfo'
        },
        {
            $Type  : 'UI.ReferenceFacet',
            ID     : 'Description',
            Label  : 'Description',
            Target : '@UI.FieldGroup#Description'
        }
    ],

    UI.FieldGroup #GeneralInfo: {
        Label : 'General Information',
        Data  : [
            { Value: title,        Label: 'Title'    },
            { Value: authorName,   Label: 'Author'   },
            { Value: price,        Label: 'Price'    },
            { Value: stock,        Label: 'Stock'    },
            { Value: currency_code,Label: 'Currency' }
        ]
    },

    UI.FieldGroup #Description: {
        Label : 'Description',
        Data  : [
            { Value: descr }
        ]
    }
);

// ============================================
// FIELD-LEVEL LABELS (via Common.Label)
// ============================================
annotate service.Books with {
    title        @Common.Label: 'Book Title';
    authorName   @Common.Label: 'Author';
    price        @Common.Label: 'Price'      @Measures.ISOCurrency: currency_code;
    stock        @Common.Label: 'Stock';
}

// ============================================
// VALUE HELP (Dropdown)
// ============================================
annotate service.Books with {
    author @Common.ValueList: {
        CollectionPath : 'Authors',
        Parameters     : [
            {
                $Type            : 'Common.ValueListParameterOut',
                LocalDataProperty: author_ID,
                ValueListProperty: 'ID'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            }
        ]
    };
}
```

---

## 🛠️ Hands-on 4: Custom SAPUI5 View

> **💡 Kapan pakai Freestyle vs Fiori Elements?**
>
> | Fiori Elements | Freestyle SAPUI5 |
> |:---------------|:------------------|
> | Butuh standar SAP (list, detail, form) | Butuh UI kustom yang unik |
> | Minim coding, cepat development | Full kontrol, tapi butuh lebih banyak kode |
> | Otomatis mengikuti SAP design guidelines | Desain bebas, harus maintain sendiri |
>
> Pada hands-on ini kita coba pendekatan **Freestyle** untuk memahami perbedaannya.

### File: `app/custom-books/webapp/view/BooksList.view.xml`

```xml
<mvc:View
    controllerName="com.tecrise.books.controller.BooksList"
    xmlns:mvc="sap.ui.core.mvc"
    xmlns="sap.m"
    xmlns:core="sap.ui.core"
    displayBlock="true">

    <Page title="Books Catalog" showNavButton="false">
        <!-- Search Bar -->
        <subHeader>
            <Bar>
                <contentLeft>
                    <SearchField
                        width="300px"
                        search=".onSearch"
                        placeholder="Search books..."/>
                </contentLeft>
            </Bar>
        </subHeader>

        <!-- Table Content -->
        <content>
            <Table
                id="booksTable"
                items="{/Books}"
                growing="true"
                growingThreshold="10"
                mode="SingleSelectMaster"
                selectionChange=".onBookSelect">

                <headerToolbar>
                    <Toolbar>
                        <Title text="Books ({= ${/Books/$count} })"/>
                        <ToolbarSpacer/>
                        <Button text="Add Book" press=".onAdd" type="Emphasized"/>
                    </Toolbar>
                </headerToolbar>

                <columns>
                    <Column><Text text="Title"/></Column>
                    <Column><Text text="Author"/></Column>
                    <Column hAlign="End"><Text text="Price"/></Column>
                    <Column hAlign="End"><Text text="Stock"/></Column>
                    <Column><Text text="Actions"/></Column>
                </columns>

                <items>
                    <ColumnListItem>
                        <Text text="{title}"/>
                        <Text text="{authorName}"/>
                        <ObjectNumber
                            number="{price}"
                            unit="{currency_code}"/>
                        <ObjectStatus
                            text="{stock}"
                            state="{= ${stock} > 10 ? 'Success' : ${stock} > 0 ? 'Warning' : 'Error' }"/>
                        <Button text="Order" press=".onOrder" type="Accept"/>
                    </ColumnListItem>
                </items>
            </Table>
        </content>
    </Page>
</mvc:View>
```

### File: `app/custom-books/webapp/controller/BooksList.controller.js`

```javascript
sap.ui.define([
    "sap/ui/core/mvc/Controller",
    "sap/ui/model/odata/v4/ODataModel",
    "sap/m/MessageToast",
    "sap/m/MessageBox"
], function(Controller, ODataModel, MessageToast, MessageBox) {
    "use strict";

    return Controller.extend("com.tecrise.books.controller.BooksList", {

        onInit: function() {
            // Model sudah di-set di manifest.json
            const oModel = this.getOwnerComponent().getModel();
            this.oModel = oModel;
        },

        onSearch: function(oEvent) {
            const sQuery = oEvent.getParameter("query");
            const oBinding = this.byId("booksTable").getBinding("items");
            
            if (sQuery) {
                oBinding.filter([
                    new sap.ui.model.Filter("title", "Contains", sQuery)
                ]);
            } else {
                oBinding.filter([]);
            }
        },

        onBookSelect: function(oEvent) {
            const oItem = oEvent.getParameter("listItem");
            const sPath = oItem.getBindingContext().getPath();
            const oBook = this.oModel.getObject(sPath);
            
            // Navigate to Object Page
            this.getOwnerComponent().getRouter().navTo("BooksObjectPage", {
                key: `ID='${oBook.ID}'`
            });
        },

        onAdd: function() {
            // Navigate ke create page
            this.getOwnerComponent().getRouter().navTo("BooksCreate");
        },

        onOrder: function(oEvent) {
            const oContext = oEvent.getSource().getBindingContext();
            const oBook = oContext.getObject();
            
            MessageBox.confirm(`Order 1 copy of "${oBook.title}"?`, {
                onClose: async (sAction) => {
                    if (sAction === "OK") {
                        try {
                            await this.oModel.bindContext("/submitOrder(...)").invoke({
                                bookID: oBook.ID,
                                amount: 1
                            });
                            MessageToast.show("Order submitted successfully!");
                        } catch (err) {
                            MessageBox.error(err.message);
                        }
                    }
                }
            });
        }
    });
});
```

---

## 🛠️ Hands-on 5: Fiori Launchpad Configuration

### File: `app/fiori.html` (Local FLP Sandbox)

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TEC Rise Bookshop — Fiori Launchpad</title>
    <script>
        window["sap-ushell-config"] = {
            defaultRenderer: "fiori2",
            applications: {
                "books-display": {
                    title: "Books Catalog",
                    description: "Browse and manage books",
                    additionalInformation: "SAPUI5.Component=com.tecrise.books",
                    applicationType: "URL",
                    url: "/books/webapp",
                    navigationMode: "embedded"
                }
            }
        };
    </script>
    <script id="sap-ushell-bootstrap"
        src="https://ui5.sap.com/test-resources/sap/ushell/bootstrap/sandbox.js">
    </script>
    <script
        src="https://ui5.sap.com/resources/sap-ui-core.js"
        data-sap-ui-libs="sap.m, sap.ushell, sap.fe.templates"
        data-sap-ui-theme="sap_horizon"
        data-sap-ui-compatVersion="edge"
        data-sap-ui-frameOptions="allow">
    </script>
    <script>
        sap.ui.getCore().attachInit(function() {
            sap.ushell.Container.createRenderer().placeAt("content");
        });
    </script>
</head>
<body class="sapUiBody" id="content"></body>
</html>
```

---

## 📝 Latihan Mandiri Hari 2

### Exercise 2.1: Tambah Column di List Report
Tambahkan kolom `genre` dan `currency_code` di `UI.LineItem` annotation.

### Exercise 2.2: Custom Filter
Tambahkan filter bar untuk `stock` dan `price` menggunakan `UI.SelectionFields`.

### Exercise 2.3: Object Page Tab Baru
Tambahkan tab "Pricing" di Object Page yang menampilkan price, currency, stock.

### Exercise 2.4: Value Help
Implementasikan Value Help dropdown untuk field `author` menggunakan `@Common.ValueList`.

---

## 🔑 Key Concepts Hari 2

| Konsep | Penjelasan | Analogi |
|--------|------------|--------|
| **Fiori Elements** | Framework UI declarative berbasis annotations | Furniture IKEA pre-built |
| **List Report** | Template halaman tabel + filter + search | Halaman katalog toko online |
| **Object Page** | Template halaman detail dengan header & sections | Halaman detail produk |
| **`UI.LineItem`** | Mendefinisikan kolom di tabel | Memilih kolom di spreadsheet |
| **`UI.HeaderInfo`** | Mendefinisikan header di object page | Judul & subtitle di kartu nama |
| **`UI.Facets`** | Mendefinisikan tab/section di object page | Tab di browser |
| **Value Help** | Dropdown suggestion dari entity lain | Autocomplete di Google search |
| **SAPUI5 MVC** | Model-View-Controller pattern | Restoran: Dapur-Menu-Pelayan |
| **manifest.json** | App descriptor / konfigurasi utama | Buku manual elektronik |

---

## 📂 Hasil Hands-on

Semua hasil hands-on dan exercise didokumentasikan di folder **[handson/](./handson/)**:

| Dokumen | Deskripsi |
|---------|----------|
| [Hands-on 1: Fiori App Generation](./handson/handson-1-fiori-app-generation.md) | Generate & jalankan Fiori Elements app dari CAP |
| [Hands-on 2: Manifest & Routing](./handson/handson-2-manifest-routing.md) | Konfigurasi manifest.json dan verifikasi routing |
| [Hands-on 3: Fiori Annotations](./handson/handson-3-fiori-annotations.md) | CDS annotations dan hasil UI yang ter-generate |
| [Hands-on 4: Custom SAPUI5 View](./handson/handson-4-custom-sapui5.md) | Freestyle SAPUI5 view dengan MVC pattern |
| [Hands-on 5: Fiori Launchpad](./handson/handson-5-fiori-launchpad.md) | Konfigurasi FLP sandbox lokal |

---

## 📚 Referensi
- [Fiori Elements Documentation](https://ui5.sap.com/#/topic/03265b0408e2432c9571d6b3feb6b1fd)
- [SAPUI5 SDK](https://ui5.sap.com/)
- [Fiori Annotations Reference](https://cap.cloud.sap/docs/advanced/fiori)
- [SAP Fiori Tools](https://help.sap.com/docs/SAP_FIORI_tools)

---

⬅️ **Prev:** [Hari 1 — BTP Fundamentals](../Day1-BTP-Fundamentals/README.md)  
➡️ **Next:** [Hari 3 — Extensibility](../Day3-Extensibility/README.md)  
🏠 **Home:** [Workshop Overview](../README.md)

---

<sub>**Workshop Material by Wahyu Amaldi** — Technical Lead SAP & Full Stack Development | SAP Certified — BTP, ABAP, Fiori, BDC</sub>
