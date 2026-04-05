# ⏳ Exercise 1.3: CF CLI Login — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Tanggal:** 5 April 2026  
> **Status:** ⏳ PERLU INSTALL CF CLI  
> **Catatan:** CF CLI belum terinstall di local machine. Langkah-langkah tetap didokumentasikan.

---

## Pre-requisite: Install CF CLI

### macOS (via Homebrew):
```bash
$ brew install cloudfoundry/tap/cf-cli@8

# Verifikasi
$ cf --version
cf version 8.x.x
```

### Atau download manual:
- https://github.com/cloudfoundry/cli/releases

---

## Langkah yang Harus Dilakukan

### Step 1: Login ke Cloud Foundry

```bash
$ cf login -a https://api.cf.ap21.hana.ondemand.com

# Expected output:
API endpoint: https://api.cf.ap21.hana.ondemand.com

Email: <your-sap-email>
Password: <your-password>

Authenticating...
OK

Targeted org 3220086dtrial.

Select a space:
1. dev

Space (enter to skip): 1
Targeted space dev.

API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.x.x
user:           <your-email>
org:            3220086dtrial
space:          dev
```

### Step 2: Verifikasi Target

```bash
$ cf target

# Expected output:
API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.x.x
user:           <your-email>
org:            3220086dtrial
space:          dev
```

### Step 3: List Spaces

```bash
$ cf spaces

# Expected output:
Getting spaces in org 3220086dtrial as <your-email>...

name
dev
```

### Step 4: List Apps (kosong karena belum deploy)

```bash
$ cf apps

# Expected output:
Getting apps in org 3220086dtrial / space dev as <your-email>...

No apps found.
```

### Step 5: List Services (kosong karena belum create)

```bash
$ cf services

# Expected output:
Getting service instances in org 3220086dtrial / space dev as <your-email>...

No service instances found.
```

---

## Alternative: Di BAS (Cloud)

Jika menggunakan BAS (Business Application Studio), CF CLI sudah pre-installed:

```bash
# Di terminal BAS
$ cf --version
cf version 8.x.x

$ cf login -a https://api.cf.ap21.hana.ondemand.com
# Ikuti prompt login...

$ cf target
API endpoint:   https://api.cf.ap21.hana.ondemand.com
org:            3220086dtrial
space:          dev
```

> **Tips:** Di BAS, bisa juga login via Command Palette:  
> `Ctrl+Shift+P` → "CF: Login to Cloud Foundry"

---

## Checklist

- [ ] CF CLI terinstall (`cf --version` berhasil)
- [ ] Login berhasil (`cf login -a https://api.cf.ap21.hana.ondemand.com`)
- [ ] Target terverifikasi (`cf target` menampilkan org dan space)
- [ ] `cf spaces` menampilkan space "dev"
- [ ] `cf apps` berjalan (kosong OK)
- [ ] `cf services` berjalan (kosong OK)

---

**Catatan:** Exercise ini akan sepenuhnya terverifikasi saat peserta melakukan deployment di **Hari 4**. Untuk saat ini, yang penting adalah CF CLI bisa login dan terhubung ke org/space yang benar.
