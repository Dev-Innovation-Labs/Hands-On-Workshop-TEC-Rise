/**
 * SAP OData V2 Client — koneksi ke S/4HANA real (sap.ilmuprogram.com)
 *
 * Implements the full draft-based PO creation flow:
 *   1. POST C_PurchaseOrderTP           → Create draft header (WITHOUT items)
 *   2. POST C_PurchaseOrderItemTP       → Add items one-by-one
 *   3. POST C_PurchaseOrderTPPreparation → Validate draft
 *   4. POST C_PurchaseOrderTPActivation  → Activate → real PO number
 *
 * Handles:
 * - Basic Authentication + sap-client header
 * - CSRF Token management (Fetch → POST)
 * - TLS self-signed certificate
 * - OData V2 JSON format with draft lifecycle
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
            throw new Error('SAP credentials not configured. Set SAP_HOST, SAP_USERNAME, SAP_PASSWORD in .env');
        }

        // Step 1: Fetch CSRF token from MM_PUR_PO_MAINT_V2_SRV
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
        console.log(`[SAP] POST Draft: ${createUrl}`);

        const createResp = await fetch(createUrl, {
            method: 'POST',
            headers,
            body: JSON.stringify(draftPayload)
        });

        const createText = await createResp.text();
        let createData;
        try { createData = JSON.parse(createText); } catch { createData = null; }

        console.log(`[SAP] Draft response: ${createResp.status}`);
        console.log(`[SAP] Draft body: ${createText.substring(0, 500)}`);

        if (!createResp.ok || !createData?.d) {
            const errMsg = createData?.error?.message?.value
                        || createData?.error?.innererror?.errordetails?.[0]?.message
                        || `Draft creation failed (${createResp.status}): ${createText.substring(0, 300)}`;
            return { success: false, sapPONumber: '', message: errMsg };
        }

        const draft = createData.d;
        const draftUUID = draft.DraftUUID;
        const poNumber = draft.PurchaseOrder || '';
        console.log(`[SAP] Draft created — PO: "${poNumber}", DraftUUID: ${draftUUID}`);

        // Step 3: Add items to draft (one by one — same as Fiori app behavior)
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
            console.log(`[SAP] POST Item ${idx + 1}: ${item.description} (qty: ${item.quantity} ${item.uom})`);

            const itemResp = await fetch(itemUrl, {
                method: 'POST',
                headers,
                body: JSON.stringify(itemPayload)
            });

            const itemText = await itemResp.text();
            console.log(`[SAP] Item ${idx + 1} response: ${itemResp.status}`);
            if (!itemResp.ok) {
                let itemData;
                try { itemData = JSON.parse(itemText); } catch { itemData = null; }
                const errMsg = itemData?.error?.message?.value || `Item creation failed: ${itemText.substring(0, 200)}`;
                console.log(`[SAP] Item error: ${errMsg}`);
                return { success: false, sapPONumber: '', message: `Item ${idx + 1} Error: ${errMsg}` };
            }
        }

        // Step 4: Prepare (validate)
        console.log(`[SAP] === Step 4: Prepare Draft ===`);
        const prepUrl = `${this.host}${this.PO_SERVICE}/C_PurchaseOrderTPPreparation?` +
            `PurchaseOrder='${encodeURIComponent(poNumber)}'&` +
            `DraftUUID=guid'${draftUUID}'&` +
            `IsActiveEntity=false&` +
            `sap-client=${this.client}`;

        console.log(`[SAP] POST Prepare: ${prepUrl}`);
        const prepResp = await fetch(prepUrl, { method: 'POST', headers });
        const prepText = await prepResp.text();
        console.log(`[SAP] Prepare response: ${prepResp.status}`);
        console.log(`[SAP] Prepare body: ${prepText.substring(0, 300)}`);

        if (!prepResp.ok) {
            let prepData;
            try { prepData = JSON.parse(prepText); } catch { prepData = null; }
            const errMsg = prepData?.error?.message?.value
                        || `Preparation failed (${prepResp.status}): ${prepText.substring(0, 300)}`;
            return { success: false, sapPONumber: '', message: `Preparation Error: ${errMsg}` };
        }

        // Step 5: Activate (save → get real PO number)
        console.log(`[SAP] === Step 5: Activate Draft ===`);
        const actUrl = `${this.host}${this.PO_SERVICE}/C_PurchaseOrderTPActivation?` +
            `PurchaseOrder='${encodeURIComponent(poNumber)}'&` +
            `DraftUUID=guid'${draftUUID}'&` +
            `IsActiveEntity=false&` +
            `sap-client=${this.client}`;

        console.log(`[SAP] POST Activate: ${actUrl}`);
        const actResp = await fetch(actUrl, { method: 'POST', headers });
        const actText = await actResp.text();
        let actData;
        try { actData = JSON.parse(actText); } catch { actData = null; }

        console.log(`[SAP] Activate response: ${actResp.status}`);
        console.log(`[SAP] Activate body: ${actText.substring(0, 500)}`);

        if (actResp.ok && actData?.d) {
            const activePO = actData.d;
            const sapPONumber = activePO.PurchaseOrder || '';
            return {
                success: true,
                sapPONumber,
                message: `PO ${sapPONumber} berhasil dibuat di SAP S/4HANA (Draft → Prepare → Activate)`,
                rawResponse: activePO
            };
        } else {
            const errMsg = actData?.error?.message?.value
                        || actData?.error?.innererror?.errordetails?.[0]?.message
                        || `Activation failed (${actResp.status}): ${actText.substring(0, 300)}`;
            return { success: false, sapPONumber: '', message: `Activation Error: ${errMsg}` };
        }
    }

    // ====================================================
    // Fetch Suppliers dari SAP real
    // ====================================================
    async getSuppliers() {
        if (!this.isConfigured) {
            throw new Error('SAP credentials not configured');
        }

        const url = `${this.host}${this.SUPPLIER_SERVICE}/C_MM_SmplSupplierValueHelp?$top=50&$format=json&sap-client=${this.client}`;
        console.log(`[SAP] Fetching suppliers from: ${url}`);

        const resp = await fetch(url, {
            headers: {
                'Authorization': this.authHeader,
                'Accept': 'application/json'
            }
        });

        if (!resp.ok) {
            throw new Error(`Supplier fetch failed: ${resp.status}`);
        }

        const data = await resp.json();
        return (data?.d?.results || []).map(s => ({
            Supplier: s.Supplier,
            SupplierName: s.SupplierName,
            Country: s.Country
        }));
    }

    // ====================================================
    // Test koneksi ke SAP
    // ====================================================
    async testConnection() {
        const url = `${this.host}${this.PO_READ_SERVICE}/?$format=json&sap-client=${this.client}`;
        console.log(`[SAP] Testing connection to: ${url}`);

        const resp = await fetch(url, {
            headers: {
                'Authorization': this.authHeader,
                'Accept': 'application/json'
            }
        });

        return {
            ok: resp.ok,
            status: resp.status,
            message: resp.ok ? 'Connected to SAP successfully' : `Connection failed: ${resp.status}`
        };
    }
}

module.exports = SAPClient;
