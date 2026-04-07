# 📂 Hasil Hands-on Hari 3: Clean Core Extensibility — End-to-End Purchase Order System
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


Folder ini berisi dokumentasi bukti bahwa setiap hands-on di Hari 3 telah dijalankan dan berhasil.

## Skenario Bisnis

Membangun **Custom Purchase Order System** di BTP sebagai **side-by-side extension** (pengganti Z-table di S/4HANA), meliputi:

1. **Data Model** — 5 custom entities (PurchaseOrders, Items, Suppliers, Materials, StatusHistory)
2. **Business Logic** — Validasi, auto-calculation, status management, audit trail
3. **Fiori UI** — List Report + Object Page + Create/Post PO flow

## Daftar Dokumen

| Dokumen | Deskripsi |
|---------|-----------|
| [Hands-on 1: PO Data Model](./handson-1-extend-cds-model.md) | CDS entities (pengganti Z-table), custom types, CSV sample data |
| [Hands-on 2: OData Service & Business Logic](./handson-2-custom-handlers.md) | Service CDS, event handlers, actions (postPO, cancelPO, approvePO), validasi |
| [Hands-on 3: Fiori UI & OData Testing](./handson-3-odata-testing.md) | Fiori annotations, manifest.json, OData CRUD & action testing |

## Cara Verifikasi

```bash
cd ~/projects/bookshop
cds watch

# OData endpoints:
# http://localhost:4004/odata/v4/po/PurchaseOrders
# http://localhost:4004/odata/v4/po/Suppliers
# http://localhost:4004/odata/v4/po/Materials

# Fiori app:
# http://localhost:4004/po/webapp/index.html
```

## Entity Relationship Diagram

```
┌──────────────┐       ┌───────────────────┐       ┌──────────────────────┐
│  Suppliers   │1    N │  PurchaseOrders   │1    N │  PurchaseOrderItems  │
│──────────────│───────│───────────────────│───────│──────────────────────│
│ supplierNo   │       │ poNumber          │       │ itemNo               │
│ name         │       │ description       │       │ description          │
│ city         │       │ status            │       │ quantity             │
│ country      │       │ orderDate         │       │ unitPrice            │
│ email        │       │ deliveryDate      │       │ netAmount            │
│ isActive     │       │ totalAmount       │       │ uom                  │
└──────────────┘       │ notes             │       │ currency             │
                       └───────────────────┘       └──────────┬───────────┘
                              │ 1                              │ N
                              │                                │
                              ▼ N                              ▼ 1
                       ┌───────────────────┐       ┌──────────────────────┐
                       │ POStatusHistory   │       │  Materials           │
                       │───────────────────│       │──────────────────────│
                       │ oldStatus         │       │ materialNo           │
                       │ newStatus         │       │ description          │
                       │ changedBy         │       │ category             │
                       │ changedAt         │       │ uom                  │
                       │ comment           │       │ unitPrice            │
                       └───────────────────┘       └──────────────────────┘
```
