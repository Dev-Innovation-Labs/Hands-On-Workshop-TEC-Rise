# ✅ Hands-on 4: Build & Deploy — Hasil REAL DEPLOYMENT
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** DEPLOYED & VERIFIED on SAP HANA Cloud  
> **Tanggal:** 5 April 2026  
> **App URL:** https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com

---

## Langkah 1: Verifikasi Tools

```
$ mbt --version
Cloud MTA Build Tool version 1.2.45

$ cf --version
cf version 8.18.0+fad4bcb.2026-03-04

$ cf plugins
plugin      version   command name
multiapps   3.11.1    bg-deploy, deploy, ...
```

✅ Semua tools terinstall dan siap digunakan.

---

## Langkah 2: CF Login

```
$ cf login -a https://api.cf.ap21.hana.ondemand.com
API endpoint: https://api.cf.ap21.hana.ondemand.com

Email: wahyu.amaldi@kpmg.co.id
Authenticating... OK

API endpoint:   https://api.cf.ap21.hana.ondemand.com
API version:    3.215.0
user:           wahyu.amaldi@kpmg.co.id
org:            3220086dtrial
space:          dev
```

---

## Langkah 3: Create CAP Project + Add HANA, XSUAA, MTA

```bash
$ cds init bookshop
$ cd bookshop
$ cds add nodejs && cds add sample
$ cds add hana && cds add xsuaa && cds add mta
$ npm install
```

**package.json dependencies (production):**
```json
{
  "dependencies": {
    "@cap-js/hana": "^2",
    "@sap/cds": "^9",
    "@sap/xssec": "^4"
  }
}
```

**mta.yaml resources:**
- `bookshop-srv` — nodejs module (CAP server)
- `bookshop-db-deployer` — hdb module (HANA schema deployer)
- `bookshop-auth` — XSUAA service (authentication)
- `bookshop-db` — HDI container (HANA database)

---

## Langkah 4: MTA Build — REAL OUTPUT

```
$ mbt build -t ./

[INFO] Cloud MTA Build Tool version 1.2.45
[INFO] executing the "npm ci" command...
[INFO] executing the "npx cds build --production" command...

building project with {
  versions: { cds: '9.8.4', compiler: '6.8.0', dk: '9.8.3' },
  target: 'gen',
  tasks: [
    { src: 'db', for: 'hana', options: { model: [...] } },
    { src: 'srv', for: 'nodejs', options: { model: [...] } }
  ]
}

done > wrote output to:
   gen/db/src/gen/CatalogService.Books.hdbview
   gen/db/src/gen/AdminService.Authors.hdbview
   gen/db/src/gen/data/sap.capire.bookshop-Authors.csv
   gen/db/src/gen/data/sap.capire.bookshop-Books.csv
   ... 83+ files (HANA views, tables, draft tables, CSV data)

build completed in 1616 ms

[INFO] building the "bookshop-srv" module... (79 production packages)
[INFO] building the "bookshop-db-deployer" module... (29 packages)
[INFO] the MTA archive generated at: bookshop_1.0.0.mtar
```

✅ **Build berhasil:** `bookshop_1.0.0.mtar` (5.37 MB)

---

## Langkah 5: Deploy ke BTP — REAL OUTPUT

```
$ cf deploy bookshop_1.0.0.mtar

Deploying multi-target app archive bookshop_1.0.0.mtar
  in org 3220086dtrial / space dev as wahyu.amaldi@kpmg.co.id...

Uploading 1 files...
  bookshop_1.0.0.mtar
  5.37 MiB / 5.37 MiB [====] 100.00%
OK

Operation ID: b8ca93d6-3104-11f1-9836-eeee0a8f3716

No deployed MTA detected - this is initial deployment of MTA with ID "bookshop"

Processing service "bookshop-db"...
Creating service "bookshop-db" from MTA resource "bookshop-db"...       ← HDI Container
Processing service "bookshop-auth"...
Creating service "bookshop-auth" from MTA resource "bookshop-auth"...   ← XSUAA
1 of 1 done

Creating application "bookshop-db-deployer" from MTA module...
Binding service instance "bookshop-db" to "bookshop-db-deployer"...
Creating application "bookshop-srv" from MTA module...
Binding service instance "bookshop-auth" to "bookshop-srv"...
Binding service instance "bookshop-db" to "bookshop-srv"...

Uploading application "bookshop-db-deployer"...
Uploading application "bookshop-srv"...
Staging application "bookshop-db-deployer"...
Staging application "bookshop-srv"...

Executing task "deploy" on application "bookshop-db-deployer"...        ← Schema deployed to HANA!

Application "bookshop-srv" started and available at
  "3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com"

Process finished.
```

✅ **DEPLOY BERHASIL!**

---

## Langkah 6: Verifikasi — REAL STATUS

### Apps Running
```
$ cf apps

name                   requested state   processes   routes
bookshop-db-deployer   stopped           web:0/1     
bookshop-srv           started           web:1/1     3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com
```

### Services Created
```
$ cf services

name            offering     plan          bound apps                           last operation
bookshop-auth   xsuaa        application   bookshop-srv                         create succeeded
bookshop-db     hana         hdi-shared    bookshop-db-deployer, bookshop-srv   create succeeded
Dev-hana        hana-cloud   hana-free                                          create succeeded
```

### App Detail
```
$ cf app bookshop-srv

name:              bookshop-srv
requested state:   started
isolation segment: trial
routes:            3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com
last uploaded:     Sun 05 Apr 22:34:10 WIB 2026
stack:             cflinuxfs4
buildpacks:        nodejs_buildpack 1.8.44
memory usage:      1024M
instances:         1/1

     state     since                  cpu    memory        disk
#0   running   2026-04-05T15:34:31Z   2.1%   81.2M of 1G   220M of 1G
```

---

## Langkah 7: Test OData Endpoints — REAL DATA FROM HANA CLOUD

### GET /odata/v4/catalog/Books (with OAuth token)
```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    {
      "ID": 201,
      "title": "Wuthering Heights",
      "author": "Emily Brontë",
      "stock": 12,
      "price": "11.11",
      "currency_code": "GBP"
    },
    {
      "ID": 207,
      "title": "Jane Eyre",
      "author": "Charlotte Brontë",
      "stock": 11,
      "price": "12.34",
      "currency_code": "GBP"
    },
    {
      "ID": 251,
      "title": "The Raven",
      "author": "Edgar Allen Poe",
      "stock": 333,
      "price": "13.13",
      "currency_code": "USD"
    },
    {
      "ID": 252,
      "title": "Eleonora",
      "author": "Edgar Allen Poe",
      "stock": 555,
      "price": "14.00",
      "currency_code": "USD"
    },
    {
      "ID": 271,
      "title": "Catweazle",
      "author": "Richard Carpenter",
      "stock": 22,
      "price": "150.00",
      "currency_code": "JPY"
    }
  ]
}
```

### GET /odata/v4/catalog/Books?$filter=price gt 13&$select=title,author,price
```json
{
  "@odata.context": "$metadata#Books",
  "value": [
    { "ID": 251, "title": "The Raven",   "author": "Edgar Allen Poe",    "price": "13.13"  },
    { "ID": 252, "title": "Eleonora",    "author": "Edgar Allen Poe",    "price": "14.00"  },
    { "ID": 271, "title": "Catweazle",   "author": "Richard Carpenter",  "price": "150.00" }
  ]
}
```

### GET /odata/v4/catalog/Books/$count
```
5
```

### 401 tanpa token (XSUAA protection working)
```json
{ "error": { "message": "Unauthorized", "code": "401" } }
```

---

## Kesimpulan

- ✅ **MBT BUILD:** `bookshop_1.0.0.mtar` (5.37MB) — 83+ HANA artifacts
- ✅ **CF DEPLOY:** bookshop-srv running on `3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com`
- ✅ **HANA Cloud:** HDI container `bookshop-db` created & schema deployed
- ✅ **XSUAA:** `bookshop-auth` protecting APIs — 401 tanpa token
- ✅ **OData Live:** 5 books returned dari SAP HANA Cloud dengan auth token
- ✅ **$filter, $select, $count:** Semua OData query berjalan di HANA

---

## Langkah 8: Fiori Launchpad + Approuter — REAL OUTPUT

### Setup Approuter
```bash
$ cds add approuter

Adding feature 'approuter'...
  creating app/router/xs-app.json
  
Successfully added features to the project.
```

### Custom server.js (Express static middleware)
CDS production build (`cds-serve`) doesn't auto-serve static files. Solusinya: buat custom `srv/server.js`:

```javascript
const cds = require('@sap/cds')
const path = require('path')

cds.on('bootstrap', (app) => {
    const express = require('express')
    app.use(express.static(path.join(__dirname, 'app')))
})

module.exports = cds.server
```

Dan `copy-app.sh` untuk copy Fiori static files ke `gen/srv/app/`:
```bash
#!/bin/sh
mkdir -p gen/srv/app/browse/webapp gen/srv/app/admin-books/webapp ...
cp -r app/browse/webapp/* gen/srv/app/browse/webapp/
cp app/fiori-apps.html gen/srv/app/fiori-apps.html
cp app/fiori-apps.html gen/srv/app/index.html
# + pastikan server.js ada di gen/srv/
```

### Build & Deploy
```
$ mbt build -t ./
[INFO] the MTA archive generated at: bookshop_1.0.0.mtar

$ cf deploy bookshop_1.0.0.mtar
Application "bookshop-srv" started at "3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com"
Application "bookshop" started at "3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com"
```

### Log Confirming Custom server.js Active:
```
[APP/PROC/WEB/0] [cds] - bootstrapping from { file: 'server.js' }
```

### Test Fiori URL — BERHASIL!

**Backend langsung (Bearer token):**
```
$ curl -H "Authorization: Bearer $TOKEN" \
  https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com/fiori-apps.html

<!doctype html>
<html>
<head>
  <title>Bookshop</title>
  <script src="https://ui5.sap.com/test-resources/sap/ushell/bootstrap/sandbox.js"></script>
  <script src="https://ui5.sap.com/resources/sap-ui-core.js" ...></script>
  ...
</head>
<body class="sapUiBody" id="content"></body>
</html>
```

HTTP: **200 OK** ✅

**Approuter (browser flow):**
```
URL: https://3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com/
→ Redirect ke XSUAA login page (302)
→ User login
→ Fiori Launchpad tampil! ✅
```

### Apps Running Final:
```
$ cf apps
name                   requested state   processes   routes
bookshop               started           web:1/1     3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com
bookshop-db-deployer   stopped           web:0/1     
bookshop-srv           started           web:1/1     3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com
```

- **Fiori Launchpad URL:** `https://3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com/`
- **OData Backend:** `https://3220086dtrial-dev-bookshop-srv.cfapps.ap21.hana.ondemand.com/odata/v4/catalog/`

---

## Langkah 9: Akses HANA Cloud dari Local (Hybrid Mode) — REAL OUTPUT

### Bind ke Remote HANA & XSUAA
```
$ npx cds bind --to bookshop-db:hana-key
retrieving data from Cloud Foundry...
binding db to Cloud Foundry managed service bookshop-db:hana-key with kind hana-cloud
saving bindings to .cdsrc-private.json in profile hybrid

$ npx cds bind --to bookshop-auth
retrieving data from Cloud Foundry...
creating service key bookshop-auth-key - please be patient...
binding auth to Cloud Foundry managed service bookshop-auth:bookshop-auth-key with kind xsuaa-auth
saving bindings to .cdsrc-private.json in profile hybrid
```

### Jalankan Local Server dengan Remote HANA
```
$ npx cds watch --profile hybrid

cds serve all --with-mocks --in-memory? --profile hybrid 
resolving cloud service bindings...
bound auth to cf managed service bookshop-auth:bookshop-auth-key
bound db to cf managed service bookshop-db:hana-key

[cds] - bootstrapping from { file: 'srv/server.js' }
[cds] - loaded model from 15 file(s)

[cds] - connect to db > hana {
  database_id: '0536a7f6-2846-40e6-baf7-171fcf1ae66c',
  host: '0536a7f6-...hana.prod-ap21.hanacloud.ondemand.com',
  port: '443',
  schema: '56B54ACD585E434FB0818353CB2B0EA0'
}

[cds] - using auth strategy { kind: 'xsuaa' }
[cds] - serving AdminService { at: [ '/odata/v4/admin' ] }
[cds] - serving CatalogService { at: [ '/odata/v4/catalog' ] }
[cds] - server listening on { url: 'http://localhost:4006' }
[cds] - server v9.8.4 launched in 770 ms
```

✅ **Local server di http://localhost:4006 terhubung ke HANA Cloud di ap21!**

### Cara Kerja Hybrid Mode:
```
┌──────────────────┐        ┌──────────────────────────────┐
│   LOCAL (Mac)     │        │  SAP BTP Cloud (ap21)         │
│                   │        │                               │
│   cds watch       │───────▶│  HANA Cloud (Dev-hana)        │
│   :4006           │ HTTPS  │  0536a7f6-...ondemand.com:443 │
│                   │        │                               │
│   .cdsrc-private  │        │  XSUAA (bookshop-auth)        │
│   (credentials)   │        │                               │
└──────────────────┘        └──────────────────────────────┘
```

---

## Kesimpulan Lengkap

- ✅ **MBT BUILD:** `bookshop_1.0.0.mtar` — 83+ HANA artifacts
- ✅ **CF DEPLOY:** bookshop-srv + bookshop approuter running
- ✅ **HANA Cloud:** HDI container `bookshop-db` — schema deployed
- ✅ **XSUAA:** `bookshop-auth` — 401 tanpa token
- ✅ **OData Live:** 5 books dari SAP HANA Cloud
- ✅ **Fiori Launchpad:** `https://3220086dtrial-dev-bookshop.cfapps.ap21.hana.ondemand.com/` — served via approuter + XSUAA login
- ✅ **Hybrid Mode:** Local development terhubung ke remote HANA Cloud via `cds bind` + `cds watch --profile hybrid`
