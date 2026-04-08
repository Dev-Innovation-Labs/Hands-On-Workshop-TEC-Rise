# Hands-on 2: OData Service, Business Logic & SAP Client

> **Durasi:** ~45 menit  
> **Prerequisite:** Hands-on 1 selesai (`cds watch` berjalan, 3 PO records tampil)

---

## Tujuan

Membuat **OData Service**, **event handlers** (auto-numbering, validasi, kalkulasi), dan **SAP OData V2 client** yang bisa membuat PO di S/4HANA real melalui draft-based API.

---

## Langkah 1: Buat Service CDS

Buat file `srv/po-service.cds`:

```cds
using { com.tecrise.procurement as po } from '../db/po-schema';

service PurchaseOrderService @(path: '/po') {

    entity PORequests as projection on po.PORequests
        actions {
            // Tombol "Post to SAP" — kirim PO request ke S/4HANA real
            @(
                cds.odata.bindingparameter.name: '_it',
                Common.SideEffects: {
                    TargetProperties: ['_it/status','_it/statusCriticality','_it/sapPONumber','_it/sapPostDate','_it/sapPostMessage']
                }
            )
            action postToSAP() returns {
                sapPONumber : String;
                status      : String;
                message     : String;
            };
        };

    entity PORequestItems as projection on po.PORequestItems;

    // Function: Fetch suppliers dari SAP real
    function getSAPSuppliers() returns array of {
        Supplier     : String;
        SupplierName : String;
        Country      : String;
    };

    // Function: Test koneksi SAP
    function testSAPConnection() returns {
        ok      : Boolean;
        status  : Integer;
        message : String;
    };
}
```

**Perhatikan:**
- `action postToSAP()` — Bound action, muncul sebagai **tombol** di Fiori UI
- `Common.SideEffects` — Setelah action selesai, Fiori auto-refresh field status, sapPONumber, dll
- `getSAPSuppliers()` — Unbound function, fetch data supplier langsung dari SAP
- `testSAPConnection()` — Utility function untuk cek koneksi SAP

---

## Langkah 2: Buat SAP OData V2 Client

SAP S/4HANA menggunakan **draft-based PO creation** via `MM_PUR_PO_MAINT_V2_SRV`. Flow-nya:

```
CSRF Token → Create Draft Header → Add Items → Prepare → Activate → Real PO Number
```

Buat file `srv/lib/sap-client.js`:

```javascript
/**
 * SAP OData V2 Client — koneksi ke S/4HANA real (sap.ilmuprogram.com)
 *
 * Implements the full draft-based PO creation flow:
 *   1. POST C_PurchaseOrderTP          → Create draft (header only)
 *   2. POST ...to_PurchaseOrderItemTP  → Add items one by one
 *   3. POST C_PurchaseOrderTPPreparation → Validate draft
 *   4. POST C_PurchaseOrderTPActivation  → Activate → real PO number
 */

// Skip TLS verification for SAP self-signed cert (dev only)
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

class SAPClient {

    constructor(config = {}) {
        this.host     = config.host     || process.env.SAP_HOST     || 'https://sap.ilmuprogram.com';
        this.client   = config.client   || process.env.SAP_CLIENT   || '777';
        this.username = config.username || process.env.SAP_USERNAME || '';
        this.password = config.password || process.env.SAP_PASSWORD || '';

        this.authHeader = 'Basic ' + Buffer.from(`${this.username}:${this.password}`).toString('base64');

        // OData V2 service paths
        this.PO_SERVICE       = '/sap/opu/odata/sap/MM_PUR_PO_MAINT_V2_SRV';
        this.SUPPLIER_SERVICE = '/sap/opu/odata/sap/C_SUPPLIER_FS_SRV';
        this.PO_READ_SERVICE  = '/sap/opu/odata/sap/C_PURCHASEORDER_FS_SRV';
    }

    get isConfigured() {
        return !!(this.username && this.password && this.host);
    }

    // ====================================================
    // CSRF Token Management
    // ====================================================
    async fetchCSRFToken(servicePath) {
        const url = `${this.host}${servicePath}/?sap-client=${this.client}`;
        console.log(`[SAP] Fetching CSRF token from: ${url}`);

        const resp = await fetch(url, {
            method: 'GET',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': 'Fetch',
                'Accept': 'application/json'
            }
        });

        if (!resp.ok) {
            const text = await resp.text();
            throw new Error(`CSRF fetch failed (${resp.status}): ${text.substring(0, 300)}`);
        }

        const csrfToken = resp.headers.get('x-csrf-token');
        const cookies = resp.headers.getSetCookie?.() || [];
        const cookieString = cookies.map(c => c.split(';')[0]).join('; ');

        console.log(`[SAP] CSRF token obtained: ${csrfToken ? csrfToken.substring(0, 20) + '...' : 'NONE'}`);
        return { csrfToken, cookies: cookieString };
    }

    // ====================================================
    // Main: Create Purchase Order (Draft → Prepare → Activate)
    // ====================================================
    async createPurchaseOrder(poData) {
        if (!this.isConfigured) {
            throw new Error('SAP credentials not configured');
        }

        // Step 1: Fetch CSRF token
        console.log(`[SAP] === Step 1: Fetch CSRF Token ===`);
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.PO_SERVICE);

        const headers = {
            'Authorization': this.authHeader,
            'X-CSRF-Token': csrfToken,
            'Cookie': cookies,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'sap-client': this.client
        };

        // Step 2: Create Draft PO header (WITHOUT items)
        console.log(`[SAP] === Step 2: Create Draft PO Header ===`);
        const draftPayload = {
            PurchaseOrderType: 'NB',
            CompanyCode: poData.companyCode || '1710',
            PurchasingOrganization: poData.purchasingOrg || '1710',
            PurchasingGroup: poData.purchasingGroup || '001',
            Supplier: poData.supplier,
            DocumentCurrency: poData.currency || 'USD'
        };

        const createUrl = `${this.host}${this.PO_SERVICE}/C_PurchaseOrderTP?sap-client=${this.client}`;
        const createResp = await fetch(createUrl, {
            method: 'POST', headers,
            body: JSON.stringify(draftPayload)
        });

        const createText = await createResp.text();
        let createData;
        try { createData = JSON.parse(createText); } catch { createData = null; }

        if (!createResp.ok || !createData?.d) {
            const errMsg = createData?.error?.message?.value
                        || `Draft creation failed (${createResp.status})`;
            return { success: false, sapPONumber: '', message: errMsg };
        }

        const draft = createData.d;
        const draftUUID = draft.DraftUUID;
        const poNumber = draft.PurchaseOrder || '';
        console.log(`[SAP] Draft created — PO: "${poNumber}", DraftUUID: ${draftUUID}`);

        // Step 3: Add items one by one (same behavior as Fiori standard app)
        console.log(`[SAP] === Step 3: Add Items to Draft ===`);
        const draftKey = `C_PurchaseOrderTP(PurchaseOrder='${encodeURIComponent(poNumber)}',DraftUUID=guid'${draftUUID}',IsActiveEntity=false)`;

        for (let idx = 0; idx < (poData.items || []).length; idx++) {
            const item = poData.items[idx];
            const itemPayload = {
                PurchaseOrderItem: String((idx + 1) * 10).padStart(5, '0'),
                PurchaseOrderItemText: item.description || '',
                OrderQuantity: String(item.quantity || 0),
                PurchaseOrderQuantityUnit: item.uom || 'PC',
                NetPriceAmount: String(item.unitPrice || 0),
                DocumentCurrency: item.currency || poData.currency || 'USD',
                Plant: item.plant || '1710',
                MaterialGroup: item.materialGroup || 'L001'
            };
            if (item.materialNo) {
                itemPayload.Material = item.materialNo;
            } else {
                itemPayload.AccountAssignmentCategory = 'K';
            }

            const itemUrl = `${this.host}${this.PO_SERVICE}/${draftKey}/to_PurchaseOrderItemTP?sap-client=${this.client}`;
            console.log(`[SAP] POST Item ${idx + 1}: ${item.description}`);

            const itemResp = await fetch(itemUrl, {
                method: 'POST', headers,
                body: JSON.stringify(itemPayload)
            });

            if (!itemResp.ok) {
                const itemText = await itemResp.text();
                let itemData;
                try { itemData = JSON.parse(itemText); } catch { itemData = null; }
                const errMsg = itemData?.error?.message?.value || `Item creation failed`;
                return { success: false, sapPONumber: '', message: `Item ${idx + 1} Error: ${errMsg}` };
            }
        }

        // Step 4: Prepare (validate)
        console.log(`[SAP] === Step 4: Prepare Draft ===`);
        const prepUrl = `${this.host}${this.PO_SERVICE}/C_PurchaseOrderTPPreparation?` +
            `PurchaseOrder='${encodeURIComponent(poNumber)}'&DraftUUID=guid'${draftUUID}'&` +
            `IsActiveEntity=false&sap-client=${this.client}`;

        const prepResp = await fetch(prepUrl, { method: 'POST', headers });
        if (!prepResp.ok) {
            const prepText = await prepResp.text();
            let prepData;
            try { prepData = JSON.parse(prepText); } catch { prepData = null; }
            const errMsg = prepData?.error?.message?.value || `Preparation failed`;
            return { success: false, sapPONumber: '', message: `Preparation Error: ${errMsg}` };
        }

        // Step 5: Activate (save → get real PO number)
        console.log(`[SAP] === Step 5: Activate Draft ===`);
        const actUrl = `${this.host}${this.PO_SERVICE}/C_PurchaseOrderTPActivation?` +
            `PurchaseOrder='${encodeURIComponent(poNumber)}'&DraftUUID=guid'${draftUUID}'&` +
            `IsActiveEntity=false&sap-client=${this.client}`;

        const actResp = await fetch(actUrl, { method: 'POST', headers });
        const actText = await actResp.text();
        let actData;
        try { actData = JSON.parse(actText); } catch { actData = null; }

        if (actResp.ok && actData?.d) {
            const sapPONumber = actData.d.PurchaseOrder || '';
            return {
                success: true,
                sapPONumber,
                message: `PO ${sapPONumber} berhasil dibuat di SAP S/4HANA`
            };
        } else {
            const errMsg = actData?.error?.message?.value || `Activation failed`;
            return { success: false, sapPONumber: '', message: `Activation Error: ${errMsg}` };
        }
    }

    // ====================================================
    // Fetch Suppliers dari SAP
    // ====================================================
    async getSuppliers() {
        const url = `${this.host}${this.SUPPLIER_SERVICE}/C_MM_SmplSupplierValueHelp?$top=50&$format=json&sap-client=${this.client}`;
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });
        if (!resp.ok) throw new Error(`Supplier fetch failed: ${resp.status}`);
        const data = await resp.json();
        return (data?.d?.results || []).map(s => ({
            Supplier: s.Supplier, SupplierName: s.SupplierName, Country: s.Country
        }));
    }

    // ====================================================
    // Test Connection
    // ====================================================
    async testConnection() {
        const url = `${this.host}${this.PO_READ_SERVICE}/?$format=json&sap-client=${this.client}`;
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });
        return {
            ok: resp.ok, status: resp.status,
            message: resp.ok ? 'Connected to SAP successfully' : `Connection failed: ${resp.status}`
        };
    }
}

module.exports = SAPClient;
```

### SAP OData V2 Draft Flow — Visualisasi

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ GET CSRF     │────▶│ POST Draft Header│────▶│ POST Items (x N)│
│ Token        │     │ C_PurchaseOrderTP│     │ to_PurchaseOrder │
│              │     │                  │     │ ItemTP           │
└─────────────┘     └──────────────────┘     └────────┬────────┘
                                                       │
                    ┌──────────────────┐     ┌─────────▼────────┐
                    │ Activate         │◀────│ Prepare (Validate)│
                    │ → Real PO Number │     │ TPPreparation     │
                    │ e.g. 4500000016  │     │                   │
                    └──────────────────┘     └───────────────────┘
```

> **Kenapa tidak deep-insert?** SAP MM_PUR_PO_MAINT_V2_SRV **tidak mendukung** deep-insert items bersamaan dengan header. Items harus ditambahkan satu per satu ke draft — sama seperti behavior Fiori standard app `Manage Purchase Orders`.

---

## Langkah 3: Buat Service Handler

Buat file `srv/po-service.js`:

```javascript
const cds = require('@sap/cds');
require('dotenv').config();
const SAPClient = require('./lib/sap-client');

module.exports = class PurchaseOrderService extends cds.ApplicationService {

    async init() {

        const { PORequests, PORequestItems } = this.entities;

        // Initialize SAP Client
        const sapClient = new SAPClient();
        if (sapClient.isConfigured) {
            console.log(`[SAP] Client configured → ${sapClient.host} (client ${sapClient.client})`);
        } else {
            console.log('[SAP] ⚠️  SAP credentials not set. Set SAP_HOST, SAP_USERNAME, SAP_PASSWORD in .env');
        }

        // ============================================
        // BEFORE CREATE: Auto-generate Request Number
        // ============================================
        this.before('CREATE', 'PORequests', async (req) => {
            const year = new Date().getFullYear().toString().slice(-2);
            const last = await SELECT.one(PORequests)
                .columns('requestNo')
                .orderBy('createdAt desc');

            let seq = 1;
            if (last?.requestNo) {
                const lastSeq = parseInt(last.requestNo.slice(-4), 10);
                if (!isNaN(lastSeq)) seq = lastSeq + 1;
            }
            req.data.requestNo = `REQ-${year}${String(seq).padStart(4, '0')}`;

            if (!req.data.orderDate) {
                req.data.orderDate = new Date().toISOString().split('T')[0];
            }
            if (!req.data.status) req.data.status = 'D';

            if (req.data.deliveryDate && req.data.orderDate && req.data.deliveryDate <= req.data.orderDate) {
                req.reject(400, 'Delivery Date harus setelah Order Date');
            }
        });

        // ============================================
        // BEFORE CREATE ITEM: Auto-calculate netAmount
        // ============================================
        this.before('CREATE', 'PORequestItems', async (req) => {
            const qty = req.data.quantity || 0;
            const price = req.data.unitPrice || 0;
            req.data.netAmount = qty * price;

            if (!req.data.itemNo && req.data.parent_ID) {
                const lastItem = await SELECT.one(PORequestItems)
                    .where({ parent_ID: req.data.parent_ID })
                    .columns('itemNo')
                    .orderBy('itemNo desc');
                req.data.itemNo = (lastItem?.itemNo || 0) + 10;
            }
        });

        // ============================================
        // AFTER CREATE/UPDATE/DELETE ITEM: Recalc total
        // ============================================
        const recalcTotal = async (poID) => {
            if (!poID) return;
            const items = await SELECT.from(PORequestItems).where({ parent_ID: poID });
            const total = items.reduce((sum, i) => sum + (i.netAmount || 0), 0);
            await UPDATE(PORequests).set({ totalAmount: total }).where({ ID: poID });
        };

        this.after('CREATE', 'PORequestItems', async (data) => await recalcTotal(data.parent_ID));
        this.after('UPDATE', 'PORequestItems', async (data) => await recalcTotal(data.parent_ID));
        this.after('DELETE', 'PORequestItems', async (_, req) => {
            if (req.data?.parent_ID) await recalcTotal(req.data.parent_ID);
        });

        // ============================================
        // AFTER READ: Compute statusCriticality
        // ============================================
        this.after('READ', 'PORequests', (results) => {
            for (const po of Array.isArray(results) ? results : [results]) {
                if (!po) continue;
                po.statusCriticality = { 'D': 2, 'P': 3, 'E': 1 }[po.status] ?? 0;
            }
        });

        // ============================================
        // BEFORE UPDATE: Block edit jika sudah Posted
        // ============================================
        this.before('UPDATE', 'PORequests', async (req) => {
            const po = await SELECT.one(PORequests).where({ ID: req.data.ID });
            if (po?.status === 'P') {
                req.reject(400, `Request ${po.requestNo} sudah di-post ke SAP (PO: ${po.sapPONumber}) — tidak dapat diubah`);
            }
        });

        // ============================================
        // ACTION: postToSAP — Kirim PO ke S/4HANA real
        // ============================================
        this.on('postToSAP', 'PORequests', async (req) => {
            const ID = req.params[0]?.ID || req.params[0];

            const po = await SELECT.one(PORequests).where({ ID });
            if (!po) req.reject(404, 'PO Request tidak ditemukan');
            if (po.status === 'P') req.reject(400, `Sudah di-post (PO: ${po.sapPONumber})`);
            if (!po.supplier) req.reject(400, 'Supplier belum diisi');

            const items = await SELECT.from(PORequestItems).where({ parent_ID: ID });
            if (items.length === 0) req.reject(400, 'Belum ada items');
            if (!po.totalAmount || po.totalAmount <= 0) req.reject(400, 'Total amount harus > 0');
            if (!sapClient.isConfigured) req.reject(500, 'SAP connection not configured');

            console.log(`[SAP] Posting ${po.requestNo} → Supplier: ${po.supplier}, Items: ${items.length}`);

            try {
                const result = await sapClient.createPurchaseOrder({
                    companyCode: po.companyCode,
                    purchasingOrg: po.purchasingOrg,
                    purchasingGroup: po.purchasingGroup,
                    supplier: po.supplier,
                    currency: po.currency,
                    orderDate: po.orderDate,
                    items: items
                });

                const now = new Date().toISOString();

                if (result.success) {
                    await UPDATE(PORequests).set({
                        status: 'P', sapPONumber: result.sapPONumber,
                        sapPostDate: now, sapPostMessage: result.message
                    }).where({ ID });

                    console.log(`[SAP] ✅ Success! SAP PO: ${result.sapPONumber}`);
                    return { sapPONumber: result.sapPONumber, status: 'Posted', message: result.message };
                } else {
                    await UPDATE(PORequests).set({
                        status: 'E', sapPostDate: now, sapPostMessage: `Error: ${result.message}`
                    }).where({ ID });

                    return { sapPONumber: '', status: 'Error', message: result.message };
                }
            } catch (err) {
                await UPDATE(PORequests).set({
                    status: 'E', sapPostDate: new Date().toISOString(),
                    sapPostMessage: `Connection Error: ${err.message}`
                }).where({ ID });
                return { sapPONumber: '', status: 'Error', message: err.message };
            }
        });

        // ============================================
        // FUNCTION: getSAPSuppliers
        // ============================================
        this.on('getSAPSuppliers', async (req) => {
            if (!sapClient.isConfigured) req.reject(500, 'SAP connection not configured');
            try {
                return await sapClient.getSuppliers();
            } catch (err) {
                req.reject(500, `Failed to fetch suppliers: ${err.message}`);
            }
        });

        // ============================================
        // FUNCTION: testSAPConnection
        // ============================================
        this.on('testSAPConnection', async () => {
            if (!sapClient.isConfigured) {
                return { ok: false, status: 0, message: 'SAP credentials not configured' };
            }
            try {
                return await sapClient.testConnection();
            } catch (err) {
                return { ok: false, status: 0, message: err.message };
            }
        });

        return super.init();
    }
};
```

---

## Langkah 4: Konfigurasi SAP Connection

Buat file `.env` di root project:

```ini
# SAP S/4HANA Connection
SAP_HOST=https://sap.ilmuprogram.com
SAP_CLIENT=777
SAP_USERNAME=wahyu.amaldi
SAP_PASSWORD=Pas671_ok12345
```

> **Penting:** Tambahkan `.env` ke `.gitignore` agar credentials tidak ter-push.

---

## Langkah 5: Verifikasi

Jalankan server dan test:

```bash
cds watch
```

### Test 1: Service Metadata

```bash
curl http://localhost:4004/po/$metadata
```

Pastikan ada entity `PORequests` dengan action `postToSAP`.

### Test 2: Test SAP Connection

```bash
curl -s http://localhost:4004/po/testSAPConnection() | python3 -m json.tool
```

**Expected:**
```json
{
  "@odata.context": "$metadata#Edm.Untyped",
  "ok": true,
  "status": 200,
  "message": "Connected to SAP successfully"
}
```

### Test 3: Fetch Suppliers dari SAP Real

```bash
curl -s http://localhost:4004/po/getSAPSuppliers() | python3 -m json.tool
```

**Expected:** List supplier dari S/4HANA (`17300001`, `17300002`, dll).

### Test 4: Create PO Request via API

```bash
curl -s -X POST http://localhost:4004/po/PORequests \
  -H "Content-Type: application/json" \
  -d '{
    "description": "Test PO dari Hands-on",
    "supplier": "17300001",
    "supplierName": "Domestic Supplier",
    "deliveryDate": "2026-05-01",
    "currency": "USD"
  }' | python3 -m json.tool
```

**Expected:** Record baru dengan `requestNo` auto-generated (e.g., `REQ-260004`).

---

## Struktur Project Saat Ini

```
po-project/
├── package.json
├── .env                       ← SAP credentials (gitignored)
├── db/
│   ├── po-schema.cds
│   └── data/
│       ├── ...PORequests.csv
│       └── ...PORequestItems.csv
├── srv/
│   ├── po-service.cds         ← Service definition + action
│   ├── po-service.js          ← Event handlers + postToSAP logic
│   └── lib/
│       └── sap-client.js      ← SAP OData V2 client (5-step draft flow)
└── node_modules/
```

---

## Checkpoint

| # | Cek | Status |
|:--|:----|:-------|
| 1 | `cds watch` tanpa error, `[SAP] Client configured` muncul di log | ☐ |
| 2 | `testSAPConnection()` → `ok: true` | ☐ |
| 3 | `getSAPSuppliers()` → list suppliers dari SAP real | ☐ |
| 4 | POST `/po/PORequests` → auto-generate `requestNo` | ☐ |
| 5 | POST item → `netAmount` auto-calculated | ☐ |

---

**Lanjut ke → [Hands-on 3: Fiori UI, HANA Cloud & Post to SAP](./handson-3-odata-testing.md)**
