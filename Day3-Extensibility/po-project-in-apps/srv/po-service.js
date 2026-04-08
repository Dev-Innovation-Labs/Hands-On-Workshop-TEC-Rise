/**
 * PurchaseOrderService Handler — In-App Extensibility Edition
 *
 * Semua CRUD di-proxy-kan ke CBO OData V2 di SAP S/4HANA.
 * Tidak ada local database — @cds.persistence.skip pada semua entity.
 *
 * Flow:
 *   Fiori UI → CAP OData V4 → ON Handler → CBO OData V2 → SAP Table
 *
 * Handler bertanggung jawab untuk:
 * 1. Field mapping (CAP field names ↔ CBO OData property names)
 * 2. Auto-generate requestNo (REQ-YYNNNN)
 * 3. Calculate netAmount & totalAmount
 * 4. Validate business rules
 * 5. Post ke SAP real via MM_PUR_PO_MAINT_V2_SRV (same as po-project)
 */

const cds = require('@sap/cds');
require('dotenv').config();

const CBOClient = require('./lib/cbo-client');
const SAPClient = require('./lib/sap-client');

module.exports = cds.service.impl(async function () {

    const cboClient = new CBOClient();
    const sapClient = new SAPClient();

    // ============================================================
    // Helper: Extract key ID from CQN query
    // ============================================================
    function getKeyFromReq(req) {
        if (req.data?.ID) return req.data.ID;
        const where = req.query?.SELECT?.where;
        if (!where) return null;
        for (let i = 0; i < where.length - 2; i++) {
            const ref = where[i]?.ref;
            if (ref?.length === 1 && ref[0] === 'ID' && where[i + 1] === '=' && where[i + 2]?.val !== undefined) {
                return where[i + 2].val;
            }
        }
        return null;
    }

    // Helper: Extract filter value from CQN WHERE
    function getFilterValue(req, fieldName) {
        const where = req.query?.SELECT?.where;
        if (!where) return null;
        for (let i = 0; i < where.length - 2; i++) {
            const ref = where[i]?.ref;
            if (ref?.length === 1 && ref[0] === fieldName && where[i + 1] === '=' && where[i + 2]?.val !== undefined) {
                return where[i + 2].val;
            }
        }
        return null;
    }

    // Helper: Check if $expand includes a property
    function needsExpand(req, name) {
        const columns = req.query?.SELECT?.columns;
        if (!columns) return false;
        return columns.some(c => (c.ref && c.ref[0] === name) || (c.expand && c.as === name));
    }

    // Helper: Auto-generate requestNo (REQ-YYNNNN)
    async function generateRequestNo() {
        const year = new Date().getFullYear().toString().slice(-2);
        const existing = await cboClient.readHeaders();
        const maxNo = existing.reduce((max, h) => {
            const match = h.requestNo?.match(/REQ-\d{2}(\d{4})/);
            return match ? Math.max(max, parseInt(match[1])) : max;
        }, 0);
        return `REQ-${year}${String(maxNo + 1).padStart(4, '0')}`;
    }

    // Helper: Recalculate header totalAmount from items
    async function recalcHeaderTotal(requestNo) {
        const items = await cboClient.readItemsByRequestNo(requestNo);
        const total = items.reduce((sum, it) => sum + (parseFloat(it.netAmount) || 0), 0);
        const headers = await cboClient.readHeaders(`RequestNo eq '${requestNo}'`);
        if (headers.length > 0) {
            await cboClient.updateHeader(headers[0].ID, { totalAmount: total });
        }
    }

    // ============================================================
    // PO Request Headers — CRUD
    // ============================================================

    this.on('READ', 'PORequests', async (req) => {
        const id = getKeyFromReq(req);

        if (id) {
            // === Single entity read ===
            const header = await cboClient.readHeader(id);
            if (!header) return req.reject(404, `PO Request ${id} not found`);

            // $expand=items
            if (needsExpand(req, 'items')) {
                header.items = await cboClient.readItemsByRequestNo(header.requestNo);
                header.items.forEach(item => { item.parent_ID = header.ID; });
            }
            return header;
        }

        // === List read ===
        const headers = await cboClient.readHeaders();

        if (needsExpand(req, 'items')) {
            for (const h of headers) {
                h.items = await cboClient.readItemsByRequestNo(h.requestNo);
                h.items.forEach(item => { item.parent_ID = h.ID; });
            }
        }

        headers.$count = headers.length;
        return headers;
    });

    this.on('CREATE', 'PORequests', async (req) => {
        const data = req.data;

        // Auto-generate requestNo
        data.requestNo = await generateRequestNo();

        // Set defaults
        if (!data.orderDate) data.orderDate = new Date().toISOString().split('T')[0];
        if (!data.status) data.status = 'D';
        if (!data.companyCode) data.companyCode = '1710';
        if (!data.purchasingOrg) data.purchasingOrg = '1710';
        if (!data.purchasingGroup) data.purchasingGroup = '001';
        if (!data.currency) data.currency = 'USD';

        // Validate
        if (data.deliveryDate && data.deliveryDate <= data.orderDate) {
            return req.reject(400, 'Delivery date must be after order date');
        }

        // Calculate totalAmount from items
        const items = data.items || [];
        let totalAmount = 0;
        items.forEach(item => {
            if (!item.netAmount && item.quantity && item.unitPrice) {
                item.netAmount = parseFloat(item.quantity) * parseFloat(item.unitPrice);
            }
            totalAmount += parseFloat(item.netAmount || 0);
        });
        data.totalAmount = totalAmount;

        // Create header in CBO
        const created = await cboClient.createHeader(data);
        console.log(`[Handler] Created header: ${created.requestNo} (ID: ${created.ID})`);

        // Create items in CBO
        if (items.length > 0) {
            created.items = [];
            for (let i = 0; i < items.length; i++) {
                const item = items[i];
                item.requestNo = created.requestNo;
                if (!item.itemNo) item.itemNo = String((i + 1) * 10).padStart(5, '0');
                if (!item.currency) item.currency = data.currency;
                if (!item.uom) item.uom = 'PC';
                if (!item.plant) item.plant = '1710';
                if (!item.materialGroup) item.materialGroup = 'L001';

                const createdItem = await cboClient.createItem(item);
                createdItem.parent_ID = created.ID;
                created.items.push(createdItem);
            }
        }

        return created;
    });

    this.on('UPDATE', 'PORequests', async (req) => {
        const id = req.data.ID;

        // Check if posted
        const existing = await cboClient.readHeader(id);
        if (!existing) return req.reject(404, 'PO Request not found');
        if (existing.status === 'P') return req.reject(400, 'Cannot edit a posted PO Request');

        return cboClient.updateHeader(id, req.data);
    });

    this.on('DELETE', 'PORequests', async (req) => {
        const id = req.data.ID;

        const existing = await cboClient.readHeader(id);
        if (!existing) return req.reject(404, 'PO Request not found');
        if (existing.status === 'P') return req.reject(400, 'Cannot delete a posted PO Request');

        // Cascade: delete items first
        const items = await cboClient.readItemsByRequestNo(existing.requestNo);
        for (const item of items) {
            await cboClient.deleteItem(item.ID);
        }

        await cboClient.deleteHeader(id);
    });

    // ============================================================
    // PO Request Items — CRUD
    // ============================================================

    this.on('READ', 'PORequestItems', async (req) => {
        const id = getKeyFromReq(req);

        if (id) {
            // === Single item by key ===
            const item = await cboClient.readItem(id);
            if (!item) return req.reject(404, `Item ${id} not found`);
            return item;
        }

        // === Check parent_ID filter (from /PORequests(id)/items navigation) ===
        const parentID = getFilterValue(req, 'parent_ID');
        if (parentID) {
            const header = await cboClient.readHeader(parentID);
            if (!header) return [];
            const items = await cboClient.readItemsByRequestNo(header.requestNo);
            items.forEach(item => { item.parent_ID = parentID; });
            items.$count = items.length;
            return items;
        }

        // === All items ===
        const headers = await cboClient.readHeaders();
        const allItems = [];
        for (const h of headers) {
            const items = await cboClient.readItemsByRequestNo(h.requestNo);
            items.forEach(item => {
                item.parent_ID = h.ID;
                allItems.push(item);
            });
        }
        allItems.$count = allItems.length;
        return allItems;
    });

    this.on('CREATE', 'PORequestItems', async (req) => {
        const data = req.data;

        // Resolve parent_ID → requestNo
        if (data.parent_ID && !data.requestNo) {
            const header = await cboClient.readHeader(data.parent_ID);
            if (!header) return req.reject(404, 'Parent PO Request not found');
            data.requestNo = header.requestNo;
        }
        if (!data.requestNo) return req.reject(400, 'requestNo is required');

        // Auto-generate itemNo
        if (!data.itemNo) {
            const existing = await cboClient.readItemsByRequestNo(data.requestNo);
            const maxItem = existing.reduce((max, it) => Math.max(max, parseInt(it.itemNo) || 0), 0);
            data.itemNo = String(maxItem + 10).padStart(5, '0');
        }

        // Calculate netAmount
        if (!data.netAmount && data.quantity && data.unitPrice) {
            data.netAmount = parseFloat(data.quantity) * parseFloat(data.unitPrice);
        }

        // Defaults
        if (!data.uom) data.uom = 'PC';
        if (!data.plant) data.plant = '1710';
        if (!data.materialGroup) data.materialGroup = 'L001';

        const created = await cboClient.createItem(data);

        // Recalc header totalAmount
        await recalcHeaderTotal(data.requestNo);

        return created;
    });

    this.on('UPDATE', 'PORequestItems', async (req) => {
        const id = req.data.ID;

        // Recalc netAmount if both quantity and unitPrice provided
        if (req.data.quantity !== undefined && req.data.unitPrice !== undefined) {
            req.data.netAmount = parseFloat(req.data.quantity) * parseFloat(req.data.unitPrice);
        }

        const updated = await cboClient.updateItem(id, req.data);

        // Recalc header
        if (updated?.requestNo) await recalcHeaderTotal(updated.requestNo);

        return updated;
    });

    this.on('DELETE', 'PORequestItems', async (req) => {
        const id = req.data.ID;

        // Get item first to know requestNo for recalc
        const item = await cboClient.readItem(id);
        await cboClient.deleteItem(id);

        if (item?.requestNo) await recalcHeaderTotal(item.requestNo);
    });

    // ============================================================
    // Action: Post to SAP (Draft → Prepare → Activate)
    // ============================================================

    this.on('postToSAP', async (req) => {
        const id = req.params[0]?.ID || req.params[0];

        // Read from CBO
        const po = await cboClient.readHeader(id);
        if (!po) return req.reject(404, 'PO Request not found in CBO');

        // Validasi
        if (po.status === 'P') {
            return req.reject(400, `PO sudah di-post sebagai ${po.sapPONumber}`);
        }
        if (!po.supplier) {
            return req.reject(400, 'Supplier wajib diisi sebelum post ke SAP');
        }

        const items = await cboClient.readItemsByRequestNo(po.requestNo);
        if (items.length === 0) {
            return req.reject(400, 'Minimal satu item diperlukan');
        }
        if ((po.totalAmount || 0) <= 0) {
            return req.reject(400, 'Total amount harus lebih dari 0');
        }

        // Build SAP payload (same format as po-project)
        const sapPayload = {
            companyCode: po.companyCode,
            purchasingOrg: po.purchasingOrg,
            purchasingGroup: po.purchasingGroup,
            supplier: po.supplier,
            currency: po.currency,
            items: items.map(it => ({
                description: it.description,
                quantity: it.quantity,
                uom: it.uom,
                unitPrice: it.unitPrice,
                currency: it.currency || po.currency,
                plant: it.plant,
                materialGroup: it.materialGroup,
                materialNo: it.materialNo
            }))
        };

        console.log(`[Handler] Posting ${po.requestNo} to SAP — ${items.length} items, total: ${po.totalAmount} ${po.currency}`);

        try {
            const result = await sapClient.createPurchaseOrder(sapPayload);

            if (result.success) {
                // Update CBO: status=P, sapPONumber, sapPostMessage
                await cboClient.updateHeader(id, {
                    status: 'P',
                    sapPONumber: result.sapPONumber,
                    sapPostMessage: result.message
                });

                console.log(`[Handler] SUCCESS: ${po.requestNo} → SAP PO ${result.sapPONumber}`);
                return {
                    sapPONumber: result.sapPONumber,
                    status: 'P',
                    message: result.message
                };
            } else {
                // Update CBO: status=E (can retry)
                await cboClient.updateHeader(id, {
                    status: 'E',
                    sapPostMessage: result.message
                });

                console.log(`[Handler] FAILED: ${po.requestNo} — ${result.message}`);
                return req.reject(500, result.message);
            }
        } catch (err) {
            await cboClient.updateHeader(id, {
                status: 'E',
                sapPostMessage: err.message
            });
            return req.reject(500, err.message);
        }
    });

    // ============================================================
    // Functions
    // ============================================================

    this.on('getSAPSuppliers', async () => {
        return sapClient.getSuppliers();
    });

    this.on('testSAPConnection', async () => {
        return sapClient.testConnection();
    });

    this.on('testCBOConnection', async () => {
        try {
            const headers = await cboClient.readHeaders();
            const allItems = await cboClient.readAllItems();
            return {
                ok: true,
                headerCount: headers.length,
                itemCount: allItems.length,
                message: `CBO connected — ${headers.length} headers, ${allItems.length} items`
            };
        } catch (err) {
            return {
                ok: false,
                headerCount: 0,
                itemCount: 0,
                message: `CBO connection failed: ${err.message}`
            };
        }
    });
});
