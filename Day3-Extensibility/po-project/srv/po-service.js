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

            // Default order date = today
            if (!req.data.orderDate) {
                req.data.orderDate = new Date().toISOString().split('T')[0];
            }

            // Default status = Draft
            if (!req.data.status) req.data.status = 'D';

            // Validate delivery date
            if (req.data.deliveryDate && req.data.orderDate && req.data.deliveryDate <= req.data.orderDate) {
                req.reject(400, 'Delivery Date harus setelah Order Date');
            }
        });

        // ============================================
        // BEFORE CREATE ITEM: Auto-calculate
        // ============================================
        this.before('CREATE', 'PORequestItems', async (req) => {
            const qty = req.data.quantity || 0;
            const price = req.data.unitPrice || 0;
            req.data.netAmount = qty * price;

            // Auto item number
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

            // Read PO Request + Items
            const po = await SELECT.one(PORequests).where({ ID });
            if (!po) req.reject(404, 'PO Request tidak ditemukan');

            // Validate: harus Draft atau Error (bisa retry)
            if (po.status === 'P') {
                req.reject(400, `Request ${po.requestNo} sudah di-post ke SAP (PO: ${po.sapPONumber})`);
            }

            // Validate: harus punya supplier
            if (!po.supplier) {
                req.reject(400, `Request ${po.requestNo} belum memiliki Supplier`);
            }

            // Validate: harus punya items
            const items = await SELECT.from(PORequestItems).where({ parent_ID: ID });
            if (items.length === 0) {
                req.reject(400, `Request ${po.requestNo} belum memiliki items — tambahkan minimal 1 item`);
            }

            // Validate: total > 0
            if (!po.totalAmount || po.totalAmount <= 0) {
                req.reject(400, `Request ${po.requestNo} total amount harus > 0`);
            }

            // Check SAP client configuration
            if (!sapClient.isConfigured) {
                req.reject(500, 'SAP connection not configured. Set SAP_HOST, SAP_USERNAME, SAP_PASSWORD in .env');
            }

            console.log(`[SAP] Posting ${po.requestNo} to SAP...`);
            console.log(`[SAP] Supplier: ${po.supplier} (${po.supplierName})`);
            console.log(`[SAP] Items: ${items.length}, Total: ${po.totalAmount} ${po.currency}`);

            try {
                // === CALL SAP S/4HANA ===
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
                    // SUCCESS — Update Z-table dengan SAP PO number
                    await UPDATE(PORequests).set({
                        status: 'P',
                        sapPONumber: result.sapPONumber,
                        sapPostDate: now,
                        sapPostMessage: result.message
                    }).where({ ID });

                    console.log(`[SAP] ✅ Success! SAP PO: ${result.sapPONumber}`);
                    return {
                        sapPONumber: result.sapPONumber,
                        status: 'Posted',
                        message: result.message
                    };
                } else {
                    // ERROR — simpan error message, bisa retry
                    await UPDATE(PORequests).set({
                        status: 'E',
                        sapPostDate: now,
                        sapPostMessage: `Error: ${result.message}`
                    }).where({ ID });

                    console.log(`[SAP] ❌ Error: ${result.message}`);
                    return {
                        sapPONumber: '',
                        status: 'Error',
                        message: `SAP Error: ${result.message}`
                    };
                }
            } catch (err) {
                // Network/unexpected error
                const errMsg = err.message || String(err);
                await UPDATE(PORequests).set({
                    status: 'E',
                    sapPostDate: new Date().toISOString(),
                    sapPostMessage: `Connection Error: ${errMsg}`
                }).where({ ID });

                console.log(`[SAP] ❌ Exception: ${errMsg}`);
                return {
                    sapPONumber: '',
                    status: 'Error',
                    message: `Connection Error: ${errMsg}`
                };
            }
        });

        // ============================================
        // FUNCTION: getSAPSuppliers — Fetch dari SAP real
        // ============================================
        this.on('getSAPSuppliers', async (req) => {
            if (!sapClient.isConfigured) {
                req.reject(500, 'SAP connection not configured');
            }
            try {
                return await sapClient.getSuppliers();
            } catch (err) {
                req.reject(500, `Failed to fetch suppliers from SAP: ${err.message}`);
            }
        });

        // ============================================
        // FUNCTION: testSAPConnection
        // ============================================
        this.on('testSAPConnection', async (req) => {
            if (!sapClient.isConfigured) {
                return { ok: false, status: 0, message: 'SAP credentials not configured in .env' };
            }
            try {
                return await sapClient.testConnection();
            } catch (err) {
                return { ok: false, status: 0, message: `Connection error: ${err.message}` };
            }
        });

        return super.init();
    }
};
