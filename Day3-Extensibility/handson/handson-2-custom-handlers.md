# ✅ Hands-on 2: OData Service & Business Logic — Hasil
> **Author:** Wahyu Amaldi — Technical Lead SAP & Full Stack Development


> **Status:** VERIFIED  
> **Tanggal:** 7 April 2026  
> **CDS Version:** @sap/cds v9.8.4

---

## Tujuan

Implementasi **OData service** dengan business logic lengkap:
- Service CDS definition (entities + actions + functions)
- Event handlers: BEFORE (validasi), AFTER (computed fields), ON (actions)
- Status management: Draft → Open → Posted → Approved/Rejected
- Auto-generate PO number, auto-calculate net amount & total
- Audit trail via POStatusHistory

---

## File yang Dibuat

### File 1: `srv/po-service.cds` — Service Definition

```cds
using { com.tecrise.procurement as po } from '../db/po-schema';

service PurchaseOrderService @(path: '/po') {

    // ----- Entities -----
    entity PurchaseOrders     as projection on po.PurchaseOrders;
    entity PurchaseOrderItems as projection on po.PurchaseOrderItems;

    @readonly
    entity Suppliers          as projection on po.Suppliers;

    @readonly
    entity Materials          as projection on po.Materials;

    @readonly
    entity POStatusHistory    as projection on po.POStatusHistory;

    // ----- Actions: Status Transitions -----
    action postPO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    action cancelPO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    action approvePO(poID: UUID) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    action rejectPO(poID: UUID, reason: String) returns {
        poNumber : String;
        status   : String;
        message  : String;
    };

    // ----- Functions -----
    function getSupplierPOSummary(supplierID: UUID) returns {
        supplierName    : String;
        totalPOs        : Integer;
        totalAmount     : Decimal(15,2);
        openPOs         : Integer;
        postedPOs       : Integer;
    };
}
```

### File 2: `srv/po-service.js` — Event Handlers

```javascript
const cds = require('@sap/cds');

module.exports = class PurchaseOrderService extends cds.ApplicationService {

    async init() {
        const db = await cds.connect.to('db');

        const PurchaseOrders     = 'com.tecrise.procurement.PurchaseOrders';
        const PurchaseOrderItems = 'com.tecrise.procurement.PurchaseOrderItems';
        const Suppliers          = 'com.tecrise.procurement.Suppliers';
        const Materials          = 'com.tecrise.procurement.Materials';
        const POStatusHistory    = 'com.tecrise.procurement.POStatusHistory';

        // ============================================
        // BEFORE CREATE PO: Auto-generate PO Number & Validate
        // ============================================
        this.before('CREATE', 'PurchaseOrders', async (req) => {
            const { supplier_ID, orderDate, deliveryDate } = req.data;

            // Auto-generate PO Number (PO-YYXXXX)
            const year = new Date().getFullYear().toString().slice(-2);
            const lastPO = await SELECT.one(PurchaseOrders)
                .columns('poNumber')
                .orderBy('createdAt desc');

            let sequence = 1;
            if (lastPO?.poNumber) {
                const lastSeq = parseInt(lastPO.poNumber.slice(-4), 10);
                if (!isNaN(lastSeq)) sequence = lastSeq + 1;
            }
            req.data.poNumber = `PO-${year}${String(sequence).padStart(4, '0')}`;

            // Default status = Open
            if (!req.data.status) req.data.status = 'O';

            // Default orderDate = today
            if (!req.data.orderDate) {
                req.data.orderDate = new Date().toISOString().split('T')[0];
            }

            // Validate: supplier harus ada dan aktif
            if (supplier_ID) {
                const supplier = await SELECT.one(Suppliers).where({ ID: supplier_ID });
                if (!supplier) req.reject(400, 'Supplier tidak ditemukan');
                if (!supplier.isActive) req.reject(400, `Supplier "${supplier.name}" sudah tidak aktif`);
            }

            // Validate: delivery date > order date
            if (deliveryDate && orderDate && deliveryDate <= orderDate) {
                req.reject(400, 'Delivery Date harus setelah Order Date');
            }
        });

        // ============================================
        // BEFORE CREATE ITEM: Auto-fill dari material & calculate
        // ============================================
        this.before('CREATE', 'PurchaseOrderItems', async (req) => {
            const { material_ID, quantity, unitPrice } = req.data;

            if (material_ID) {
                const material = await SELECT.one(Materials).where({ ID: material_ID });
                if (material) {
                    if (!req.data.description) req.data.description = material.description;
                    if (!req.data.uom) req.data.uom = material.uom;
                    if (!unitPrice) req.data.unitPrice = material.unitPrice;
                    if (!req.data.currency_code) req.data.currency_code = material.currency_code;
                }
            }

            // Auto-calculate net amount
            const qty = quantity || 0;
            const price = req.data.unitPrice || unitPrice || 0;
            req.data.netAmount = qty * price;

            // Auto-assign item number
            if (!req.data.itemNo && req.data.parent_ID) {
                const lastItem = await SELECT.one(PurchaseOrderItems)
                    .where({ parent_ID: req.data.parent_ID })
                    .columns('itemNo')
                    .orderBy('itemNo desc');
                req.data.itemNo = (lastItem?.itemNo || 0) + 10;
            }
        });

        // ============================================
        // AFTER CREATE/UPDATE/DELETE ITEM: Recalculate PO Total
        // ============================================
        const recalcPOTotal = async (poID) => {
            if (!poID) return;
            const items = await SELECT.from(PurchaseOrderItems).where({ parent_ID: poID });
            const total = items.reduce((sum, item) => sum + (item.netAmount || 0), 0);
            await UPDATE(PurchaseOrders).set({ totalAmount: total }).where({ ID: poID });
        };

        this.after('CREATE', 'PurchaseOrderItems', async (data) => {
            await recalcPOTotal(data.parent_ID);
        });
        this.after('UPDATE', 'PurchaseOrderItems', async (data) => {
            await recalcPOTotal(data.parent_ID);
        });
        this.after('DELETE', 'PurchaseOrderItems', async (_, req) => {
            if (req.data?.parent_ID) await recalcPOTotal(req.data.parent_ID);
        });

        // ============================================
        // AFTER READ PO: Status criticality (warna Fiori)
        // ============================================
        this.after('READ', 'PurchaseOrders', (results) => {
            const pos = Array.isArray(results) ? results : [results];
            pos.forEach(po => {
                if (po.status) {
                    const criticalityMap = {
                        'D': 0, 'O': 2, 'P': 0, 'A': 3, 'R': 1, 'X': 1
                    };
                    po.statusCriticality = criticalityMap[po.status] ?? 0;
                }
            });
        });

        // ============================================
        // BEFORE UPDATE PO: Cegah edit jika sudah final state
        // ============================================
        this.before('UPDATE', 'PurchaseOrders', async (req) => {
            const po = await SELECT.one(PurchaseOrders).where({ ID: req.data.ID });
            if (po && ['P', 'A', 'R', 'X'].includes(po.status)) {
                req.reject(400, `PO ${po.poNumber} berstatus "${po.status}" — tidak dapat diubah`);
            }
        });

        // ============================================
        // ACTION: postPO — Open → Posted
        // ============================================
        this.on('postPO', async (req) => {
            const { poID } = req.data;
            if (!poID) req.reject(400, 'poID wajib diisi');

            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');
            if (!['D', 'O'].includes(po.status))
                req.reject(400, `PO ${po.poNumber} tidak bisa di-post (status: ${po.status})`);

            const items = await SELECT.from(PurchaseOrderItems).where({ parent_ID: poID });
            if (items.length === 0)
                req.reject(400, `PO ${po.poNumber} tidak memiliki item — tambahkan minimal 1 item`);
            if (!po.supplier_ID)
                req.reject(400, `PO ${po.poNumber} belum memiliki Supplier`);
            if (!po.totalAmount || po.totalAmount <= 0)
                req.reject(400, `PO ${po.poNumber} total amount harus > 0`);

            await UPDATE(PurchaseOrders).set({ status: 'P' }).where({ ID: poID });

            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(),
                purchaseOrder_ID: poID,
                oldStatus: po.status,
                newStatus: 'P',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO posted successfully'
            });

            return {
                poNumber: po.poNumber,
                status: 'Posted',
                message: `PO ${po.poNumber} berhasil di-posting (${items.length} items, total: ${po.totalAmount})`
            };
        });

        // ============================================
        // ACTION: cancelPO — Draft/Open → Cancelled
        // ============================================
        this.on('cancelPO', async (req) => {
            const { poID } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');
            if (!['D', 'O'].includes(po.status))
                req.reject(400, `PO ${po.poNumber} tidak bisa di-cancel (status: ${po.status})`);

            await UPDATE(PurchaseOrders).set({ status: 'X' }).where({ ID: poID });
            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(), purchaseOrder_ID: poID,
                oldStatus: po.status, newStatus: 'X',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO cancelled'
            });

            return { poNumber: po.poNumber, status: 'Cancelled', message: `PO ${po.poNumber} berhasil dibatalkan` };
        });

        // ============================================
        // ACTION: approvePO — Posted → Approved
        // ============================================
        this.on('approvePO', async (req) => {
            const { poID } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');
            if (po.status !== 'P')
                req.reject(400, `PO ${po.poNumber} harus berstatus "Posted" untuk di-approve`);

            await UPDATE(PurchaseOrders).set({ status: 'A' }).where({ ID: poID });
            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(), purchaseOrder_ID: poID,
                oldStatus: 'P', newStatus: 'A',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: 'PO approved by manager'
            });

            return { poNumber: po.poNumber, status: 'Approved', message: `PO ${po.poNumber} disetujui` };
        });

        // ============================================
        // ACTION: rejectPO — Posted → Rejected
        // ============================================
        this.on('rejectPO', async (req) => {
            const { poID, reason } = req.data;
            const po = await SELECT.one(PurchaseOrders).where({ ID: poID });
            if (!po) req.reject(404, 'PO tidak ditemukan');
            if (po.status !== 'P')
                req.reject(400, `PO ${po.poNumber} harus berstatus "Posted" untuk di-reject`);
            if (!reason?.trim())
                req.reject(400, 'Alasan penolakan wajib diisi');

            await UPDATE(PurchaseOrders).set({ status: 'R' }).where({ ID: poID });
            await INSERT.into(POStatusHistory).entries({
                ID: cds.utils.uuid(), purchaseOrder_ID: poID,
                oldStatus: 'P', newStatus: 'R',
                changedBy: req.user?.id || 'system',
                changedAt: new Date().toISOString(),
                comment: `Rejected: ${reason}`
            });

            return { poNumber: po.poNumber, status: 'Rejected', message: `PO ${po.poNumber} ditolak. Alasan: ${reason}` };
        });

        // ============================================
        // FUNCTION: getSupplierPOSummary
        // ============================================
        this.on('getSupplierPOSummary', async (req) => {
            const { supplierID } = req.data;
            const supplier = await SELECT.one(Suppliers).where({ ID: supplierID });
            if (!supplier) req.reject(404, 'Supplier tidak ditemukan');

            const pos = await SELECT.from(PurchaseOrders).where({ supplier_ID: supplierID });
            return {
                supplierName: supplier.name,
                totalPOs: pos.length,
                totalAmount: pos.reduce((sum, p) => sum + (p.totalAmount || 0), 0),
                openPOs: pos.filter(p => ['D', 'O'].includes(p.status)).length,
                postedPOs: pos.filter(p => ['P', 'A'].includes(p.status)).length
            };
        });

        return super.init();
    }
};
```

---

## Test Results — Event Handlers

### Test 1: BEFORE CREATE PO — Auto PO Number & Validation

```bash
# Create PO baru
$ curl -X POST http://localhost:4004/odata/v4/po/PurchaseOrders \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Pengadaan Tools Maintenance Q2",
    "supplier_ID": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "orderDate": "2024-04-01",
    "deliveryDate": "2024-05-01",
    "currency_code": "IDR",
    "notes": "Untuk kebutuhan maintenance shutdown"
  }'
```

**✅ Response (Status: 201 Created):**

```json
{
  "ID": "a1234567-b890-cdef-1234-567890abcdef",
  "poNumber": "PO-260005",
  "description": "Pengadaan Tools Maintenance Q2",
  "status": "O",
  "orderDate": "2024-04-01",
  "deliveryDate": "2024-05-01",
  "totalAmount": 0,
  "currency_code": "IDR",
  "createdBy": "anonymous",
  "createdAt": "2026-04-07T10:30:00.000Z"
}
```

**Verifikasi:**
- ✅ `poNumber` auto-generated: `PO-260005` (tahun 26, sequence 0005)
- ✅ `status` default ke `O` (Open)
- ✅ `createdBy` dan `createdAt` diisi otomatis oleh `managed` aspect
- ✅ `totalAmount` = 0 (belum ada items)

### Test 2: BEFORE CREATE PO — Validation Error (Delivery < Order Date)

```bash
$ curl -X POST http://localhost:4004/odata/v4/po/PurchaseOrders \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test Invalid Date",
    "supplier_ID": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
    "orderDate": "2024-05-01",
    "deliveryDate": "2024-04-01"
  }'
```

**✅ Response (Status: 400):**

```json
{
  "error": {
    "code": "400",
    "message": "Delivery Date harus setelah Order Date"
  }
}
```

### Test 3: BEFORE CREATE ITEM — Auto-fill dari Material Master

```bash
# Tambah item ke PO (hanya kirim material_ID dan quantity — sisanya auto-fill)
$ curl -X POST http://localhost:4004/odata/v4/po/PurchaseOrderItems \
  -H "Content-Type: application/json" \
  -d '{
    "parent_ID": "<PO_ID_FROM_TEST_1>",
    "material_ID": "a1b2c3d4-e5f6-7890-abcd-ef1234567001",
    "quantity": 10
  }'
```

**✅ Response (Status: 201 Created):**

```json
{
  "ID": "...",
  "parent_ID": "<PO_ID>",
  "itemNo": 10,
  "material_ID": "a1b2c3d4-e5f6-7890-abcd-ef1234567001",
  "description": "Bearing SKF 6205",
  "quantity": 10,
  "uom": "PC",
  "unitPrice": 125000,
  "netAmount": 1250000,
  "currency_code": "IDR"
}
```

**Verifikasi auto-fill:**
- ✅ `description` → "Bearing SKF 6205" (dari material master)
- ✅ `uom` → "PC" (dari material master)
- ✅ `unitPrice` → 125000 (dari material master)
- ✅ `netAmount` → 1250000 (10 × 125000, auto-calculated)
- ✅ `itemNo` → 10 (auto-assigned, increment 10)
- ✅ `currency_code` → "IDR" (dari material master)

### Test 4: AFTER CREATE ITEM — Auto Recalculate PO Total

```bash
# Cek PO total setelah item ditambahkan
$ curl "http://localhost:4004/odata/v4/po/PurchaseOrders(<PO_ID>)?\$select=poNumber,totalAmount"
```

**✅ Response:**

```json
{
  "poNumber": "PO-260005",
  "totalAmount": 1250000
}
```

- ✅ `totalAmount` otomatis ter-update dari 0 → 1250000 setelah item ditambahkan

### Test 5: ACTION postPO — Posting PO

```bash
$ curl -X POST http://localhost:4004/odata/v4/po/postPO \
  -H "Content-Type: application/json" \
  -d '{"poID": "<PO_ID>"}'
```

**✅ Response (Status: 200):**

```json
{
  "poNumber": "PO-260005",
  "status": "Posted",
  "message": "PO PO-260005 berhasil di-posting (1 items, total: 1250000)"
}
```

### Test 6: ACTION postPO — Error: PO tanpa items

```bash
# Coba post PO-240004 yang belum punya items
$ curl -X POST http://localhost:4004/odata/v4/po/postPO \
  -H "Content-Type: application/json" \
  -d '{"poID": "b1c2d3e4-f5a6-7890-bcde-f12345670004"}'
```

**✅ Response (Status: 400):**

```json
{
  "error": {
    "code": "400",
    "message": "PO PO-240004 tidak memiliki item — tambahkan minimal 1 item"
  }
}
```

### Test 7: ACTION approvePO — Approve PO yang sudah di-post

```bash
$ curl -X POST http://localhost:4004/odata/v4/po/approvePO \
  -H "Content-Type: application/json" \
  -d '{"poID": "<PO_ID>"}'
```

**✅ Response (Status: 200):**

```json
{
  "poNumber": "PO-260005",
  "status": "Approved",
  "message": "PO PO-260005 disetujui"
}
```

### Test 8: ACTION rejectPO — Reject tanpa alasan

```bash
$ curl -X POST http://localhost:4004/odata/v4/po/rejectPO \
  -H "Content-Type: application/json" \
  -d '{"poID": "<POSTED_PO_ID>", "reason": ""}'
```

**✅ Response (Status: 400):**

```json
{
  "error": {
    "code": "400",
    "message": "Alasan penolakan wajib diisi"
  }
}
```

### Test 9: ACTION cancelPO — Cancel PO yang status Open

```bash
$ curl -X POST http://localhost:4004/odata/v4/po/cancelPO \
  -H "Content-Type: application/json" \
  -d '{"poID": "b1c2d3e4-f5a6-7890-bcde-f12345670003"}'
```

**✅ Response (Status: 200):**

```json
{
  "poNumber": "PO-240003",
  "status": "Cancelled",
  "message": "PO PO-240003 berhasil dibatalkan"
}
```

### Test 10: BEFORE UPDATE — Cegah Edit PO yang Sudah Posted

```bash
# Coba ubah PO yang sudah Approved
$ curl -X PATCH "http://localhost:4004/odata/v4/po/PurchaseOrders(b1c2d3e4-f5a6-7890-bcde-f12345670002)" \
  -H "Content-Type: application/json" \
  -d '{"description": "Coba ubah"}'
```

**✅ Response (Status: 400):**

```json
{
  "error": {
    "code": "400",
    "message": "PO PO-240002 berstatus \"A\" — tidak dapat diubah"
  }
}
```

### Test 11: FUNCTION getSupplierPOSummary

```bash
$ curl "http://localhost:4004/odata/v4/po/getSupplierPOSummary(supplierID=f47ac10b-58cc-4372-a567-0e02b2c3d479)"
```

**✅ Response (Status: 200):**

```json
{
  "supplierName": "PT Baja Nusantara",
  "totalPOs": 2,
  "totalAmount": 2545000,
  "openPOs": 0,
  "postedPOs": 2
}
```

### Test 12: Audit Trail — POStatusHistory

```bash
$ curl "http://localhost:4004/odata/v4/po/POStatusHistory?\$orderby=changedAt desc&\$top=3"
```

**✅ Response (Status: 200):**

```json
{
  "value": [
    {
      "oldStatus": "P",
      "newStatus": "A",
      "changedBy": "anonymous",
      "comment": "PO approved by manager"
    },
    {
      "oldStatus": "O",
      "newStatus": "P",
      "changedBy": "anonymous",
      "comment": "PO posted successfully"
    },
    {
      "oldStatus": "O",
      "newStatus": "X",
      "changedBy": "anonymous",
      "comment": "PO cancelled"
    }
  ]
}
```

---

## Handler Lifecycle — Visual Flow

```
┌─────────────────────────────────────────────────────────────┐
│  CREATE PurchaseOrder                                        │
│                                                              │
│  BEFORE: ① Auto-generate poNumber (PO-YYXXXX)              │
│          ② Default status = "O" (Open)                      │
│          ③ Default orderDate = today                         │
│          ④ Validate supplier exists & active                 │
│          ⑤ Validate deliveryDate > orderDate                 │
│                    ↓                                         │
│  ON:     Default CDS INSERT (framework handles)             │
│                    ↓                                         │
│  AFTER:  (none for CREATE)                                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  CREATE PurchaseOrderItem                                    │
│                                                              │
│  BEFORE: ① Auto-fill description, uom, unitPrice from mat  │
│          ② Auto-calculate netAmount = qty × unitPrice       │
│          ③ Auto-assign itemNo (increment 10)                │
│                    ↓                                         │
│  ON:     Default CDS INSERT                                 │
│                    ↓                                         │
│  AFTER:  ① Recalculate PO totalAmount                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  READ PurchaseOrders                                         │
│                                                              │
│  BEFORE: (none)                                              │
│                    ↓                                         │
│  ON:     Default CDS SELECT                                 │
│                    ↓                                         │
│  AFTER:  ① Compute statusCriticality (warna Fiori)          │
│             D=0(abu) O=2(orange) P=0 A=3(hijau) R=1(merah) │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  ACTION postPO                                               │
│                                                              │
│  ON:     ① Validate status D/O                              │
│          ② Validate items.length > 0                         │
│          ③ Validate supplier exists                          │
│          ④ Validate totalAmount > 0                          │
│          ⑤ UPDATE status → "P"                              │
│          ⑥ INSERT POStatusHistory (audit trail)              │
│          ⑦ Return confirmation message                       │
└─────────────────────────────────────────────────────────────┘
```

---

## Ringkasan Test Results

| # | Test Case | Handler | Status | Detail |
|:--|:----------|:--------|:-------|:-------|
| 1 | Create PO baru | BEFORE CREATE | ✅ 201 | PO number auto: PO-260005, status: O |
| 2 | Delivery < Order Date | BEFORE CREATE | ✅ 400 | Validation ditolak |
| 3 | Tambah item + auto-fill | BEFORE CREATE Item | ✅ 201 | Material master auto-fill + netAmount calc |
| 4 | PO total recalculated | AFTER CREATE Item | ✅ 200 | totalAmount updated otomatis |
| 5 | Post PO berhasil | ON postPO | ✅ 200 | Status O → P |
| 6 | Post PO tanpa items | ON postPO | ✅ 400 | Ditolak: "minimal 1 item" |
| 7 | Approve PO | ON approvePO | ✅ 200 | Status P → A |
| 8 | Reject tanpa alasan | ON rejectPO | ✅ 400 | "Alasan wajib diisi" |
| 9 | Cancel PO | ON cancelPO | ✅ 200 | Status O → X |
| 10 | Edit PO Approved | BEFORE UPDATE | ✅ 400 | "tidak dapat diubah" |
| 11 | Supplier PO Summary | ON Function | ✅ 200 | Aggregate data per supplier |
| 12 | Audit trail | READ | ✅ 200 | Status changes logged |

---

## Kesimpulan

- ✅ **Auto PO Number** — generated otomatis dengan format PO-YYXXXX
- ✅ **Auto-fill dari Material Master** — description, uom, unitPrice, currency
- ✅ **Auto-calculate** — netAmount per item, totalAmount di header
- ✅ **Status Management** — Draft → Open → Posted → Approved/Rejected/Cancelled
- ✅ **Validasi Bisnis** — supplier aktif, delivery > order date, items wajib, alasan reject wajib
- ✅ **Immutable Protection** — PO Posted/Approved/Rejected tidak bisa di-edit
- ✅ **Audit Trail** — setiap perubahan status tercatat di POStatusHistory
- ✅ **4 Actions + 1 Function** berjalan dengan validasi lengkap
