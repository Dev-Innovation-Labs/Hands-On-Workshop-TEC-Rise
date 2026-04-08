namespace com.tecrise.procurement;

using { managed, cuid } from '@sap/cds/common';

// ============================================
// Z-TABLE: PO Request Header (pengganti ZPO_REQ_HEADER)
// Staging table — data disimpan di BTP, bukan di S/4HANA
// ============================================
entity PORequests : cuid, managed {
    requestNo        : String(10)   @readonly @title: 'Request No';
    description      : String(200)  @title: 'Description';

    // SAP Organizational Data
    companyCode      : String(4)    @title: 'Company Code'     default '1710';
    purchasingOrg    : String(4)    @title: 'Purch. Org'       default '1710';
    purchasingGroup  : String(3)    @title: 'Purch. Group'     default '001';

    // Supplier (dari SAP master data)
    supplier         : String(10)   @title: 'Supplier ID';
    supplierName     : String(80)   @title: 'Supplier Name';

    // Dates & Amounts
    orderDate        : Date         @title: 'Order Date';
    deliveryDate     : Date         @title: 'Delivery Date';
    currency         : String(3)    @title: 'Currency'         default 'USD';
    totalAmount      : Decimal(15,2) @readonly @title: 'Total Amount' default 0;
    notes            : String(1000) @title: 'Notes';

    // Status: D=Draft, P=Posted to SAP, E=Error
    status           : String(1)    @title: 'Status'           default 'D';
    statusCriticality: Integer      @UI.Hidden                 default 0;

    // === SAP Integration Result ===
    sapPONumber      : String(10)   @readonly @title: 'SAP PO Number';
    sapPostDate      : DateTime     @readonly @title: 'SAP Post Date';
    sapPostMessage   : String(500)  @readonly @title: 'SAP Response';

    // Line Items
    items            : Composition of many PORequestItems on items.parent = $self;
}

// ============================================
// Z-TABLE: PO Request Items (pengganti ZPO_REQ_ITEM)
// ============================================
entity PORequestItems : cuid {
    parent           : Association to PORequests @title: 'PO Request';
    itemNo           : Integer       @title: 'Item No';
    materialNo       : String(40)    @title: 'Material';
    description      : String(200)   @title: 'Description';
    quantity         : Decimal(13,3)  @title: 'Quantity';
    uom              : String(3)     @title: 'UoM'              default 'PC';
    unitPrice        : Decimal(15,2) @title: 'Unit Price';
    netAmount        : Decimal(15,2) @readonly @title: 'Net Amount';
    currency         : String(3)     @title: 'Currency'         default 'USD';
    plant            : String(4)     @title: 'Plant'            default '1710';
    materialGroup    : String(9)     @title: 'Material Group'   default 'L001';
}
