/**
 * CBO OData V2 Client — CRUD untuk ZZ1_WPOREQ & ZZ1_WPOREQI
 *
 * Handles:
 * - Field mapping: CAP field names ↔ CBO OData property names
 * - CBO Header field mismatch (CompanyCode=description, Supplier=companyCode, Supplier1=supplier)
 * - OData V2 date format (/Date(...)/)
 * - CSRF Token management
 * - Basic Authentication
 */

// Skip TLS verification for SAP self-signed cert (dev only)
process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

// ============================================================
// Field Mappings — CAP ↔ CBO
// ============================================================

// Header: CAP field → CBO OData property
// ⚠️ CBO has label mismatch for 3 fields (CompanyCode, Supplier, Supplier1)
const HEADER_CAP_TO_CBO = {
    requestNo:       'RequestNo',
    description:     'CompanyCode',      // ⚠️ CBO label "PODescription" but property = CompanyCode
    companyCode:     'Supplier',          // ⚠️ CBO label "CompanyCode"  but property = Supplier
    purchasingOrg:   'PurchasingOrg',
    purchasingGroup: 'PurchasingGroup',
    supplier:        'Supplier1',         // ⚠️ CBO label "Supplier"     but property = Supplier1
    supplierName:    'SupplierName',
    orderDate:       'OrderDate',
    deliveryDate:    'DeliveryDate',
    currency:        'POCurrency',
    totalAmount:     'TotalAmount',
    notes:           'PONotes',
    status:          'POStatus',
    sapPONumber:     'PODocNumber',
    sapPostMessage:  'POPostMessage'
};

// Header: CBO → CAP (reverse)
const HEADER_CBO_TO_CAP = {};
for (const [cap, cbo] of Object.entries(HEADER_CAP_TO_CBO)) {
    HEADER_CBO_TO_CAP[cbo] = cap;
}

// Items: CAP → CBO (clean mapping, no mismatch)
const ITEM_CAP_TO_CBO = {
    requestNo:     'RequestNo',
    itemNo:        'ItemNo',
    materialNo:    'MaterialNo',
    description:   'ItemDescription',
    quantity:       'Quantity',
    uom:           'UoM',
    unitPrice:     'UnitPrice',
    netAmount:     'NetAmount',
    currency:      'ItemCurrency',
    plant:         'Plant',
    materialGroup: 'MaterialGroup'
};

// Items: CBO → CAP (reverse)
const ITEM_CBO_TO_CAP = {};
for (const [cap, cbo] of Object.entries(ITEM_CAP_TO_CBO)) {
    ITEM_CBO_TO_CAP[cbo] = cap;
}

class CBOClient {

    constructor(config = {}) {
        this.host     = config.host     || process.env.SAP_HOST     || '';
        this.client   = config.client   || process.env.SAP_CLIENT   || '777';
        this.username = config.username || process.env.SAP_USERNAME || '';
        this.password = config.password || process.env.SAP_PASSWORD || '';

        this.authHeader = 'Basic ' + Buffer.from(`${this.username}:${this.password}`).toString('base64');

        // CBO OData V2 service paths
        this.HEADER_SERVICE = '/sap/opu/odata/sap/ZZ1_WPOREQ_CDS';
        this.ITEM_SERVICE   = '/sap/opu/odata/sap/ZZ1_WPOREQI_CDS';
    }

    get isConfigured() {
        return !!(this.username && this.password && this.host);
    }

    // ============================================================
    // CSRF Token Management
    // ============================================================

    async fetchCSRFToken(servicePath) {
        const url = `${this.host}${servicePath}/?sap-client=${this.client}`;
        console.log(`[CBO] Fetching CSRF token from: ${url}`);

        const resp = await fetch(url, {
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': 'Fetch',
                'Accept': 'application/json'
            }
        });

        if (!resp.ok) {
            throw new Error(`CBO CSRF fetch failed (${resp.status})`);
        }

        const csrfToken = resp.headers.get('x-csrf-token');
        const cookies = (resp.headers.getSetCookie?.() || [])
            .map(c => c.split(';')[0]).join('; ');

        return { csrfToken, cookies };
    }

    // ============================================================
    // Date Helpers: ISO ↔ OData V2 format
    // ============================================================

    _odata2date(val) {
        if (!val) return null;
        const match = val.match(/\/Date\((\d+)\)\//);
        if (match) return new Date(parseInt(match[1])).toISOString().split('T')[0];
        return val;
    }

    _date2odata(val) {
        if (!val) return null;
        return `/Date(${new Date(val).getTime()})/`;
    }

    // ============================================================
    // Field Mapping: CBO response → CAP format
    // ============================================================

    _mapHeaderFromCBO(cboRec) {
        const rec = { ID: cboRec.SAP_UUID };
        for (const [cboField, capField] of Object.entries(HEADER_CBO_TO_CAP)) {
            rec[capField] = cboRec[cboField];
        }
        rec.orderDate    = this._odata2date(rec.orderDate);
        rec.deliveryDate = this._odata2date(rec.deliveryDate);
        if (rec.totalAmount != null) rec.totalAmount = parseFloat(rec.totalAmount);
        // Compute statusCriticality for Fiori UI
        rec.statusCriticality = rec.status === 'P' ? 3 : rec.status === 'E' ? 1 : 2;
        return rec;
    }

    _mapHeaderToCBO(capData) {
        const cbo = {};
        for (const [capField, cboField] of Object.entries(HEADER_CAP_TO_CBO)) {
            if (capData[capField] !== undefined) {
                cbo[cboField] = capData[capField];
            }
        }
        if (cbo.OrderDate)    cbo.OrderDate    = this._date2odata(cbo.OrderDate);
        if (cbo.DeliveryDate) cbo.DeliveryDate = this._date2odata(cbo.DeliveryDate);
        if (cbo.TotalAmount !== undefined) cbo.TotalAmount = String(cbo.TotalAmount);
        return cbo;
    }

    _mapItemFromCBO(cboRec) {
        const rec = { ID: cboRec.SAP_UUID };
        for (const [cboField, capField] of Object.entries(ITEM_CBO_TO_CAP)) {
            rec[capField] = cboRec[cboField];
        }
        if (rec.quantity  != null) rec.quantity  = parseFloat(rec.quantity);
        if (rec.unitPrice != null) rec.unitPrice = parseFloat(rec.unitPrice);
        if (rec.netAmount != null) rec.netAmount = parseFloat(rec.netAmount);
        return rec;
    }

    _mapItemToCBO(capData) {
        const cbo = {};
        for (const [capField, cboField] of Object.entries(ITEM_CAP_TO_CBO)) {
            if (capData[capField] !== undefined) {
                cbo[cboField] = String(capData[capField]);
            }
        }
        return cbo;
    }

    // ============================================================
    // HEADER CRUD — ZZ1_WPOREQ_CDS
    // ============================================================

    async readHeaders(filter) {
        let url = `${this.host}${this.HEADER_SERVICE}/ZZ1_WPOREQ?$format=json&sap-client=${this.client}`;
        if (filter) url += `&$filter=${encodeURIComponent(filter)}`;

        console.log(`[CBO] GET Headers: ${url}`);
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });

        if (!resp.ok) throw new Error(`CBO Header read failed: ${resp.status}`);
        const data = await resp.json();
        return (data.d?.results || []).map(r => this._mapHeaderFromCBO(r));
    }

    async readHeader(id) {
        const url = `${this.host}${this.HEADER_SERVICE}/ZZ1_WPOREQ(guid'${id}')?$format=json&sap-client=${this.client}`;

        console.log(`[CBO] GET Header: ${id}`);
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });

        if (!resp.ok) {
            if (resp.status === 404) return null;
            throw new Error(`CBO Header read(${id}) failed: ${resp.status}`);
        }
        const data = await resp.json();
        return this._mapHeaderFromCBO(data.d);
    }

    async createHeader(capData) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.HEADER_SERVICE);
        const payload = this._mapHeaderToCBO(capData);

        const url = `${this.host}${this.HEADER_SERVICE}/ZZ1_WPOREQ?sap-client=${this.client}`;
        console.log(`[CBO] POST Header:`, JSON.stringify(payload).substring(0, 200));

        const resp = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        const text = await resp.text();
        let result;
        try { result = JSON.parse(text); } catch { result = null; }

        if (!resp.ok || !result?.d) {
            const errMsg = result?.error?.message?.value || `CBO Header create failed (${resp.status})`;
            throw new Error(errMsg);
        }
        return this._mapHeaderFromCBO(result.d);
    }

    async updateHeader(id, capData) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.HEADER_SERVICE);
        const payload = this._mapHeaderToCBO(capData);

        const url = `${this.host}${this.HEADER_SERVICE}/ZZ1_WPOREQ(guid'${id}')?sap-client=${this.client}`;
        console.log(`[CBO] MERGE Header ${id}:`, JSON.stringify(payload).substring(0, 200));

        const resp = await fetch(url, {
            method: 'MERGE',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!resp.ok) {
            const text = await resp.text();
            let err;
            try { err = JSON.parse(text); } catch { /* ignore */ }
            throw new Error(err?.error?.message?.value || `CBO Header update failed (${resp.status})`);
        }

        // MERGE returns 204 No Content — re-read to get updated data
        return this.readHeader(id);
    }

    async deleteHeader(id) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.HEADER_SERVICE);
        const url = `${this.host}${this.HEADER_SERVICE}/ZZ1_WPOREQ(guid'${id}')?sap-client=${this.client}`;

        console.log(`[CBO] DELETE Header: ${id}`);
        const resp = await fetch(url, {
            method: 'DELETE',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies
            }
        });

        if (!resp.ok) throw new Error(`CBO Header delete failed: ${resp.status}`);
    }

    // ============================================================
    // ITEMS CRUD — ZZ1_WPOREQI_CDS
    // ============================================================

    async readItemsByRequestNo(requestNo) {
        const filter = `RequestNo eq '${requestNo}'`;
        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI?$format=json&sap-client=${this.client}&$filter=${encodeURIComponent(filter)}&$orderby=ItemNo`;

        console.log(`[CBO] GET Items for ${requestNo}`);
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });

        if (!resp.ok) throw new Error(`CBO Items read failed: ${resp.status}`);
        const data = await resp.json();
        return (data.d?.results || []).map(r => this._mapItemFromCBO(r));
    }

    async readAllItems() {
        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI?$format=json&sap-client=${this.client}&$orderby=RequestNo,ItemNo`;

        console.log(`[CBO] GET All Items`);
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });

        if (!resp.ok) throw new Error(`CBO Items read failed: ${resp.status}`);
        const data = await resp.json();
        return (data.d?.results || []).map(r => this._mapItemFromCBO(r));
    }

    async readItem(id) {
        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI(guid'${id}')?$format=json&sap-client=${this.client}`;

        console.log(`[CBO] GET Item: ${id}`);
        const resp = await fetch(url, {
            headers: { 'Authorization': this.authHeader, 'Accept': 'application/json' }
        });

        if (!resp.ok) {
            if (resp.status === 404) return null;
            throw new Error(`CBO Item read(${id}) failed: ${resp.status}`);
        }
        const data = await resp.json();
        return this._mapItemFromCBO(data.d);
    }

    async createItem(capData) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.ITEM_SERVICE);
        const payload = this._mapItemToCBO(capData);

        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI?sap-client=${this.client}`;
        console.log(`[CBO] POST Item:`, JSON.stringify(payload).substring(0, 200));

        const resp = await fetch(url, {
            method: 'POST',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        const text = await resp.text();
        let result;
        try { result = JSON.parse(text); } catch { result = null; }

        if (!resp.ok || !result?.d) {
            const errMsg = result?.error?.message?.value || `CBO Item create failed (${resp.status})`;
            throw new Error(errMsg);
        }
        return this._mapItemFromCBO(result.d);
    }

    async updateItem(id, capData) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.ITEM_SERVICE);
        const payload = this._mapItemToCBO(capData);

        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI(guid'${id}')?sap-client=${this.client}`;
        console.log(`[CBO] MERGE Item ${id}:`, JSON.stringify(payload).substring(0, 200));

        const resp = await fetch(url, {
            method: 'MERGE',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies,
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            body: JSON.stringify(payload)
        });

        if (!resp.ok) throw new Error(`CBO Item update failed: ${resp.status}`);
        return this.readItem(id);
    }

    async deleteItem(id) {
        const { csrfToken, cookies } = await this.fetchCSRFToken(this.ITEM_SERVICE);
        const url = `${this.host}${this.ITEM_SERVICE}/ZZ1_WPOREQI(guid'${id}')?sap-client=${this.client}`;

        console.log(`[CBO] DELETE Item: ${id}`);
        const resp = await fetch(url, {
            method: 'DELETE',
            headers: {
                'Authorization': this.authHeader,
                'X-CSRF-Token': csrfToken,
                'Cookie': cookies
            }
        });

        if (!resp.ok) throw new Error(`CBO Item delete failed: ${resp.status}`);
    }
}

module.exports = CBOClient;
