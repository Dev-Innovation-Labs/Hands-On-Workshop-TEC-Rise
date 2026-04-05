# ✅ Exercise 1.4: BAS Familiarization — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ✅ SELESAI

---

## Tugas 1: Install Extension "SAP CDS Language Support" ✅

```
Di BAS:
1. Klik icon Extensions di sidebar kiri (atau Ctrl+Shift+X)
2. Di search bar, ketik: "SAP CDS Language Support"
3. Klik "Install"
4. Extension berhasil terinstall

Fitur yang didapat:
  ✅ Syntax highlighting untuk file .cds
  ✅ Code completion untuk CDS keywords
  ✅ Go to definition untuk CDS entities
  ✅ Hover information untuk CDS types
  ✅ Error diagnostics untuk CDS syntax
```

> **Catatan:** Di BAS dengan template "Full Stack Cloud Application",  
> extension ini biasanya sudah pre-installed.

---

## Tugas 2: Buat File hello.txt di Explorer ✅

```
Steps:
1. Di Explorer panel (sidebar kiri), klik kanan pada root folder
2. Pilih "New File"
3. Ketik nama: hello.txt
4. Isi konten:

   Hello from TEC Rise Workshop!
   Date: April 5, 2026
   This is my first file in BAS.

5. Ctrl+S untuk save
```

**Verifikasi di terminal:**
```bash
$ cat hello.txt
Hello from TEC Rise Workshop!
Date: April 5, 2026
This is my first file in BAS.
```

---

## Tugas 3: Jalankan echo di Terminal ✅

```bash
$ echo "Hello TEC Rise!"
Hello TEC Rise!
```

**Output:** `Hello TEC Rise!` ✅

---

## Tugas 4: Verifikasi Koneksi CF ✅

```bash
$ cf target

# Expected output (setelah cf login):
API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.x.x
user:           <your-email>
org:            3220086dtrial
space:          dev
```

> **Catatan:** Jika belum login, jalankan dulu:
> ```bash
> cf login -a https://api.cf.ap21.hana.ondemand.com
> ```

---

## Eksplorasi Tambahan

### Keyboard Shortcuts yang Berguna di BAS:

| Shortcut | Fungsi |
|----------|--------|
| `Ctrl + `` ` | Toggle Terminal |
| `Ctrl + Shift + P` | Command Palette |
| `Ctrl + P` | Quick Open file |
| `Ctrl + Shift + X` | Extensions |
| `Ctrl + Shift + G` | Source Control (Git) |
| `Ctrl + Shift + E` | Explorer |
| `Ctrl + B` | Toggle Sidebar |
| `Ctrl + ,` | Settings |

### Terminal Commands yang Berguna:

```bash
# Cek versi tools
node --version     # v24.11.0
npm --version      # 11.6.1
cds --version      # @sap/cds-dk 9.8.3
git --version      # git version 2.x.x

# File operations
ls                 # List files
pwd                # Print working directory
cat <file>         # View file content
```

---

## Checklist

- [x] Extension "SAP CDS Language Support" terinstall
- [x] File `hello.txt` berhasil dibuat di Explorer
- [x] `echo "Hello TEC Rise!"` berhasil dijalankan di terminal
- [x] `cf target` dijalankan (setelah login)

---

**Kesimpulan:** BAS IDE berhasil digunakan untuk file management, terminal operations, dan extension management. Peserta sudah familiar dengan layout dan fitur dasar BAS.
