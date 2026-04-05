# 📂 Hasil Hands-on Hari 4: Security, Integration & Deployment
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


Folder ini berisi dokumentasi bukti bahwa setiap hands-on di Hari 4 telah dijalankan dan berhasil.

## Daftar Dokumen

| Dokumen | Deskripsi |
|---------|-----------|
| [Hands-on 1: XSUAA Configuration](./handson-1-xsuaa-config.md) | Setup xs-security.json (scopes, roles, role collections) |
| [Hands-on 2: RBAC di Service Layer](./handson-2-rbac-service.md) | Role-based access control di CDS service |
| [Hands-on 3: MTA Descriptor](./handson-3-mta-descriptor.md) | Konfigurasi mta.yaml (modules, resources) |
| [Hands-on 4: Build & Deploy](./handson-4-build-deploy.md) | CF CLI login, mbt build, cf deploy |
| [Hands-on 5: Destination & Integration](./handson-5-destination.md) | Destination service & S/4HANA integration |

## Cara Verifikasi

```bash
# CF Login
cf login -a https://api.cf.ap21.hana.ondemand.com
cf target   # → org: 3220086dtrial, space: dev

# Build MTA
mbt build -t ./

# Deploy
cf deploy bookshop-tecrise_1.0.0.mtar
```
